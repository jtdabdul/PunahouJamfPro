#!/bin/bash
####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#   
#	Configuration Profile exists success failure.sh
#
# SYNOPSIS - How to use
#   
#	This script will wait for a config profile $4 to be found a maximum of $5 times (sleep 2)
#	If the profile is found to exist then call a policy trigger(s) $6
#	Else profile is not found, call policy trigger(s) $7
# 
# DESCRIPTION
#	Computer will check for existence of a configuration profile a number of times (default 20) sleep 2
#	If the profile is found policy trigger(s) for success are run, if not the policy trigger(s) for fail
#	are run.
#	example use case:  wifi profile is being swapped on a computer, and we want to perform some action
#	like ading or removing from a static group, and then notify the user.  On failure we want to notify 
#	the user of failure
#	Computer is tested for myPublicIP and compared to the publicIP(s) of the parameter.
#	onNetwork function output compared to desired match parameter (TRUE|FALSE) on|off provided list
#	if value is matched, call the policyTrigger(s) in order.
#	No user logged in, configuration profile not found will result in failure
#	This will allow us to use optionally policy retry on failure setting in the case of policy
#	trigger recurring check in.  This allows the policy to run a number of times and then stop running on success
# 
####################################################################################################
#
# HISTORY
#
#	Created on 2025/11/14 by Jason Abdul 
#
####################################################################################################
if [[ "$4" != "" ]] && [[ $profileID == "" ]]; then
    profileID=$4
fi
if [[ "$profileID" == "" ]]; then
	echo "Input parameter not found: profileID"
	exit 1
fi
if [[ "$5" != "" ]] && [[ $maxTries == "" ]]; then
	maxTries=$5
fi
if [[ "$maxTries" == "" ]]; then
	echo "Input parameter not found: maxTries, using default value 20"
	maxTries=20
fi
if [[ "$6" != "" ]] && [[ $policyTriggerSuccess == "" ]]; then
	policyTriggerSuccess=$6
fi
if [[ "$policyTriggerSuccess" == "" ]]; then
	echo "Input parameter not found: policyTriggerSuccess"
	# exit 1
fi
if [[ "$7" != "" ]] && [[ $policyTriggersFail == "" ]]; then
	policyTriggersFail=$7
fi
if [[ "$policyTriggersFail" == "" ]]; then
	echo "Input parameter not found: policyTriggersFail"
	# exit 1
fi
#debug only
echo "Profile ID: $profileID"
echo "max Tries: $maxTries"
echo "Policy Trigger Success: $policyTriggerSuccess"
echo "Policy Trigger Fail: $policyTriggersFail"
###############################################
###  Functions
###############################################
function waitForProfileToExist() {
	# $1 - profile name
	# $2 - maximum number of tries
	if [[ "$1" != "" ]] && [[ $profileID == "" ]]; then
	    profileID=$1
	fi
	if [[ "$profileID" == "" ]]; then
		echo "Input parameter not found: profileID"
		exit 1
	fi
	if [[ "$2" != "" ]] && [[ $maxTries == "" ]]; then
	    maxTries=$2
	fi
	if [[ "$maxTries" == "" ]]; then
		maxTries=20
	fi
	tries=0
	# echo "In waitForProfileToExist" >> /Users/Shared/testing.log
	# echo "profileID: $profileID" >> /Users/Shared/testing.log
	# echo "profiles -P" >> /Users/Shared/testing.log
	# echo $(profiles -P) >> /Users/Shared/testing.log
	# echo "profiles -P | grep" >> /Users/Shared/testing.log
	# echo $(profiles -P | grep "$profileID") >> /Users/Shared/testing.log
	# Loop until the profile is found
	while [ $tries -lt $maxTries ]; do
	    # Check if the profile exists using the profiles command
	    # The 'profiles -P -o' command lists installed profiles and their details.
	    # We grep for the profile name and check if a match is found.
	    if [[ $(sudo profiles -P | grep "$profileID") != "" ]]; then
	        # echo "Configuration profile '$profileID' found. Continuing script." >> /Users/Shared/testing.log
	        echo "TRUE"
	        #break # Exit the loop if the profile is found
	        exit 0
	    else
	        # echo "Configuration profile '$profileID' not yet found. Waiting..." >> /Users/Shared/testing.log
	        sleep 2 # Wait for 2 seconds before checking again
	        tries=$((tries + 1))
	    fi
	done
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
runPolicyTriggers() {
	echo "Number of arguments: $#"
	echo "All arguments (one per line):"
	for arg in "$@"; do
		echo "- $arg"
		echo "running policyTrigger $arg"
		sudo /usr/local/bin/jamf policy -event $arg
	done
	echo "First argument: $1"
	echo "Second argument: $2"
}

###############################################
###  Main
###############################################
if [[ isUserLoggedIn == "FALSE" ]]; then
	#if no user is found then exit with failure
	echo "No user logged in"
    exit 1
    fi

foo=$(waitForProfileToExist $profileID $maxTries)
# echo "waitForProfileToExist output: $foo"
if [[ $foo == TRUE ]]; then
	echo "Configuration profile found, run Success Policy $policyTriggerSuccess"
	# for item in $policyTriggerSuccess; do
	# 	echo "running policyTrigger $item"
	# 	sudo /usr/local/bin/jamf policy -event $item
	# done
	runPolicyTriggers $policyTriggerSuccess
	exit 0
else
	echo "Configuration Profile not found, run fail policy $policyTriggersFail"
	# for item in $policyTriggersFail; do
	# 	echo "running policyTrigger $item"
	# 	sudo /usr/local/bin/jamf policy -event $item
	# done
	runPolicyTriggers $policyTriggersFail
	exit 1
fi