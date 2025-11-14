#!/bin/bash
####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#   
#	Run policy trigger if publicIP found.sh
#
# SYNOPSIS - How to use
#   
#	This script will accept parameters:
#	4-match TRUE|FALSE - Match or Do Not Match 
#	5-publicIP (single value or list of IPv4 addresses) 
# 	6-policyTrigger (single value or list of values).  
#	Script will query the computer it is running on for it's public IP address and then compare it 
#	to the values(s) passed in on publicIP.  
#	TRUE|FALSE to match the return value of the onNetwork function, indicating the condition to be 
#	matched in order to run policy trigger(s)
# 
# DESCRIPTION
#	Computer is tested for myPublicIP and compared to the publicIP(s) of the parameter.
#	onNetwork function output compared to desired match parameter (TRUE|FALSE) on|off provided list
#	if value is matched, call the policyTrigger(s) in order.
#	No user logged in, on|off network not matched ot no internet connection will result in failure
#	This will allow us to use optionally policy retry on failure setting in the case of policy
#	trigger recurring check in.  This allows the policy to run a number of times and then stop running on success
# 
####################################################################################################
#
# HISTORY
#
#	Modified on 2025/11/13 by Jason Abdul to add parameter handling for match (TRUE|FALSE), both 
#	publicIP and policyTrigger to handle a single value or an array.  onCampus function to be 
#	generalized to onNetwork and return true or false indicating if the device is currently 
#	on or off the specifed network.
#
####################################################################################################

###############################################
###  Handle Parameters
###############################################

if [[ "$4" != "" ]] && [[ $match == "" ]]; then
    match=$4
fi
if [[ "$match" == "" ]]; then
	echo "Input parameter not found: match"
	exit 1
fi
if [[ "$5" != "" ]] && [[ $publicIP == "" ]]; then
	publicIP=$5
fi
if [[ "$publicIP" == "" ]]; then
	echo "Input parameter not found: publicIP"
	exit 1
fi
if [[ "$6" != "" ]] && [[ $policyTrigger == "" ]]; then
	policyTrigger=$6
fi
if [[ "$policyTrigger" == "" ]]; then
	echo "Input parameter not found: policyTrigger"
	exit 1
fi
#debug only
echo "match: $match"
echo "publicIP: $publicIP"
echo "policyTrigger: $policyTrigger"
###############################################
###  Functions
###############################################
function onNetwork() {
	myPublicIP=$(curl ifconfig.me)
	#check exit code of previous command
	if [ $? -ne 0 ]; then
		echo "Error: no internet connection"
		#no internet connection should not return false - we are using false to indicate that the computer is off campus.  Function should behave take no action in case of not connected
        exit 1
	fi
	#echo "$myPublicIP"
    #this is a list of the public IP addresses used by Punahou, if I am on campus my public IP should be in this list
	#items=("204.107.82.3" "204.107.82.240" "204.107.82.241" "204.107.82.242" "204.107.82.243" "204.107.82.244" "204.107.82.245" "204.107.82.246" "204.107.82.253" "204.107.82.250")
	for item in $publicIP; do
		if [[ $item == $myPublicIP ]]; then
			echo "TRUE"
			exit 0
		fi
	done
	#if IP not found in the list, return FALSE
	echo "FALSE"
}
function isUserLoggedIn {
	
	## Check to see if we're in a user context or not. Wait if not.
	dockStatus=$( /usr/bin/pgrep -x Dock )
	if [[ "$dockStatus" == "" ]]; then
		echo "FALSE"
    else
    	echo "TRUE"
    fi
}
###############################################
###  Main
###############################################
if [[ isUserLoggedIn == "FALSE" ]]; then
	#if no user is found then exit with failure
	echo "No user logged in"
    exit 1
    fi
foo=$(onNetwork)
echo "My Public IP is in publicIP: $foo"

if [[ $(onNetwork) == $match ]]; then
	echo "Network status test success: $match"
	for item in $policyTrigger; do
		echo "running policyTrigger $item"
		sudo /usr/local/bin/jamf policy -event $item
#	jamf policy -event AddToExcludeFromOldWifiProfile
	done
	exit 0
else
	echo "Network status not matched, exiting"
	exit 1
fi