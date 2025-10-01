#!/usr/bin/env python3

###### Requirements
#	Python 3.11 or greater
#	jps-api-wrapper library (pip3 install jps-api-wrapper
#	Environment
#		You need to set up the CLIENT_ID and CLIENT_SECRET into environment variables in your terminal
#		export CLIENT_ID="<client ID>
#		export CLIENT_SECRET="<client secret>

### Usage
#	python3 <filename> <serialNumber> <Lock Code (6 digits)> -m <Quoted Message (optional)>
#	ex python3 APILock.py fvfj2ftlq6l7 123456 --message "Your computer has violated a security policy, please come to helpdesk for assistance"


import argparse
import os
import re
import sys
from os import environ
from typing import Optional, Tuple
from jps_api_wrapper.pro import Pro

### functions
def send_device_lock(
	pro: Pro,
	management_id: str,
	pin: str,
	message: Optional[str] = None,
	client_type: str = "COMPUTER",
) -> Tuple[int, dict]:
	"""
	POST /api/v2/mdm/commands with commandType DEVICE_LOCK
	Returns (status_code, response_json)
	"""
	payload = {
		"commandData": {
			"commandType": "DEVICE_LOCK",
			"pin": pin,
		},
		"clientData": [
			{
				"managementId": management_id,
				"clientType": client_type,
			}
		],
	}
	if message is not None:
		payload["commandData"]["message"] = message
		
	r = pro.session.post(
		f"{pro.base_url}/api/v2/mdm/commands",
		json=payload,
		headers={"Accept": "application/json", "Content-Type": "application/json"},
	)
	# Jamf typically returns 202 Accepted on success
	try:
		j = r.json()
	except requests.exceptions.JSONDecodeError:
		j = {"raw": r.text}
	return r.status_code, j

### Main ###
JPS_URL = os.environ.get("JPS_URL", "https://punahou.jamfcloud.com")
CLIENT_ID = os.environ.get("CLIENT_ID")
CLIENT_SECRET = os.environ.get("CLIENT_SECRET")

if not CLIENT_ID or not CLIENT_SECRET:
	print("ERROR: Set CLIENT_ID and CLIENT_SECRET environment variables.", file=sys.stderr)
	sys.exit(2)

parser = argparse.ArgumentParser(
	description="Jamf: Lookup managementId by serial and send DEVICE_LOCK."
)
parser.add_argument("serial", help="Device serial number")
parser.add_argument("pin", help="6-digit lock PIN")
parser.add_argument("-m", "--message", help="Optional lock message", default=None)
parser.add_argument("--debug", action="store_true", help="Print inventory JSON to stderr")
args = parser.parse_args()
	
serial = args.serial.strip().upper()
pin = args.pin.strip()
	
print (serial)
		
with Pro(JPS_URL, CLIENT_ID, CLIENT_SECRET, client=True) as pro:
	# sections as a list, RSQL filter on hardware.serialNumber
	data = pro.get_computer_inventories(
		page=0,
		page_size=1,
		section=["GENERAL", "HARDWARE"],
		filter=f'hardware.serialNumber=="{serial}"'
	)
	#print(data)               # entire response dict
	# e.g. first computer record/id:
	managementId = data["results"][0]["general"]["managementId"]
	print("management ID:", managementId)
	status, resp = send_device_lock(pro, managementId, pin, args.message, client_type="COMPUTER")
	#print(f"HTTP {status}")
	#print(resp)
	if status == 403:
		print("HINT: Check API Role privileges: 'Send Computer Remote Lock Command', "
										"'Read Computers', 'Read Computer Inventory Collection', and (often needed) "
										"'View MDM command information in Jamf Pro API'. Also ensure site access.", file=sys.stderr)
	elif status >= 400:
		print("HINT: Verify managementId (device vs user), clientType, and JSON shape.", file=sys.stderr)
	elif status == 201:
		print("Success!  MDM lock command sent to serial:", serial)