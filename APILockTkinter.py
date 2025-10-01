#!/usr/bin/env python3

import os, re, sys
from typing import Optional, Tuple

# GUI
import tkinter as tk
from tkinter import ttk, messagebox

# HTTP / Jamf
import requests
from jps_api_wrapper.pro import Pro


def send_device_lock(pro: Pro, management_id: str, pin: str,
					message: Optional[str] = None, client_type: str = "COMPUTER") -> Tuple[int, dict]:
	payload = {
		"commandData": {"commandType": "DEVICE_LOCK", "pin": pin},
		"clientData": [{"managementId": management_id, "clientType": client_type}],
	}
	if message:
		payload["commandData"]["message"] = message
		
	r = pro.session.post(
		f"{pro.base_url}/api/v2/mdm/commands",
		json=payload,
		headers={"Accept": "application/json", "Content-Type": "application/json"},
	)
	try:
		j = r.json()
	except requests.exceptions.JSONDecodeError:
		j = {"raw": r.text}
	return r.status_code, j


def get_inventory_by_serial(pro: Pro, serial_upper: str) -> dict:
	params = {
		"section": "GENERAL,HARDWARE",
		"page": 0,
		"page-size": 1,
		"filter": f'hardware.serialNumber=="{serial_upper}"',
	}
	if hasattr(pro, "get_computer_inventories"):
		return pro.get_computer_inventories(
			page=0, page_size=1, section=["GENERAL", "HARDWARE"], filter=params["filter"]
		)
	r = pro.session.get(f"{pro.base_url}/api/v1/computers-inventory", params=params)
	r.raise_for_status()
	return r.json()


class LockDialog(tk.Tk):
	def __init__(self, default_url="https://punahou.jamfcloud.com"):
		super().__init__()
		self.title("Jamf Device Lock")
		self.resizable(False, False)
		self.inputs = {}
		
		pad = {"padx": 8, "pady": 6}
		
		main = ttk.Frame(self)
		main.grid(row=0, column=0, sticky="nsew", **pad)
		
		# Row builder
		def add_row(label, key, show=None, width=44, default=""):
			r = len(self.inputs)
			ttk.Label(main, text=label).grid(row=r, column=0, sticky="e", **pad)
			var = tk.StringVar(value=default)
			ent = ttk.Entry(main, textvariable=var, width=width, show=show)
			ent.grid(row=r, column=1, sticky="w", **pad)
			self.inputs[key] = var
			return ent
		
		# Fields
		self.url_entry = add_row("Jamf URL", "url", default=os.environ.get("JPS_URL", default_url))
		self.client_id_entry = add_row("CLIENT_ID", "client_id", default=os.environ.get("CLIENT_ID", ""))
		self.client_secret_entry = add_row("CLIENT_SECRET", "client_secret", show="•", default=os.environ.get("CLIENT_SECRET", ""))
		self.serial_entry = add_row("Serial Number", "serial")
		self.pin_entry = add_row("PIN (6 digits)", "pin")
		self.msg_entry = add_row("Message (optional)", "message")
		
		# Buttons
		btns = ttk.Frame(main)
		btns.grid(row=len(self.inputs), column=0, columnspan=2, sticky="e", **pad)
		ttk.Button(btns, text="Cancel", command=self.destroy).grid(row=0, column=0, **pad)
		self.run_btn = ttk.Button(btns, text="Send Device Lock", command=self.on_submit)
		self.run_btn.grid(row=0, column=1, **pad)
		
		# Focus
		self.serial_entry.focus_set()
		
		# Bind Enter
		self.bind("<Return>", lambda e: self.on_submit())
		
	def on_submit(self):
		url = self.inputs["url"].get().strip().rstrip("/")
		client_id = self.inputs["client_id"].get().strip()
		client_secret = self.inputs["client_secret"].get().strip()
		serial = self.inputs["serial"].get().strip().upper()
		pin = self.inputs["pin"].get().strip()
		message = self.inputs["message"].get()
		
		# Validate
		if not url.startswith("http"):
			messagebox.showerror("Invalid URL", "Please enter a valid Jamf URL (e.g., https://yourorg.jamfcloud.com).")
			return
		if not client_id or not client_secret:
			messagebox.showerror("Missing Credentials", "CLIENT_ID and CLIENT_SECRET are required.")
			return
		if not serial:
			messagebox.showerror("Missing Serial", "Please enter a device serial number.")
			return
		if not re.fullmatch(r"\d{6}", pin):
			messagebox.showerror("Invalid PIN", "PIN must be exactly 6 digits.")
			return
		
		# Disable button during work
		self.run_btn.state(["disabled"])
		self.update_idletasks()
		
		try:
			with Pro(url, client_id, client_secret, client=True) as pro:
				inv = get_inventory_by_serial(pro, serial)
				try:
					mgmt_id = inv["results"][0]["general"]["managementId"]
				except (KeyError, IndexError, TypeError):
					messagebox.showerror("Not Found", f"No device found for serial {serial} (or managementId missing).")
					self.run_btn.state(["!disabled"])
					return
				
				if not re.fullmatch(r"[0-9a-fA-F-]{36}", mgmt_id):
					messagebox.showerror("Invalid managementId", f"managementId isn't a 36-char UUID:\n{mgmt_id}")
					self.run_btn.state(["!disabled"])
					return
				
				status, resp = send_device_lock(pro, mgmt_id, pin, message or None, client_type="COMPUTER")
		except Exception as e:
			# Network/auth/etc
			messagebox.showerror("Error", f"{type(e).__name__}: {e}")
			self.run_btn.state(["!disabled"])
			return
		
		# Re-enable button
		self.run_btn.state(["!disabled"])
		
		# Result
		if status == 201:
#			messagebox.showinfo("Success", f"Command queued (HTTP {status}).")
			messagebox.showinfo("Success", f"Lock sent to serial: {serial}.")
		elif status == 403:
			messagebox.showerror(
				"Forbidden (403)",
				"The token lacks privileges for DEVICE_LOCK.\n\n"
				"Check API Role:\n"
				"• Send Computer Remote Lock Command\n"
				"• Read Computers\n"
				"• Read Computer Inventory Collection\n"
				"• (Often needed) View MDM command information in Jamf Pro API\n"
				"Also ensure site access to the device."
			)
		else:
			messagebox.showerror("API Error", f"HTTP {status}\n\nResponse:\n{resp}")
			
			
def main():
	app = LockDialog()
	app.mainloop()
	
	
if __name__ == "__main__":
	main()
	