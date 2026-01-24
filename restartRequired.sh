#!/bin/bash

##################################################################
# About this script
# This script requires several other objects in jamf to support it's workflow

# Static group - Restart Required to scope the policy running this script
# Policy - Static Group remove Restart Required - remove the computer from the static group once reboot is executed, by the script or by the user
# Policy - Clear Cache - remove computer from static group 689 (Restart Required), clear cache and restart, it will also clear the flag file
# Policy - Punahou Branded prompt - prompt user allow deferral (button2), on restart (button1) call clearcache

# Script is designed to run in policy set to recurring check in ongoing, scoped to static group Restart Required
# check for flag file existence and touch(create) if not found
# check if user has rebooted on their own - if flag file age is > boot time interval - remove from static group and exit, preventing further execution
# If computer has not yet rebooted, check to see if the threshold deadline is reached (days parameter passed in to script)
# deadline not reached, call the branded prompt
# deadline reached - prompt restart imminent, call clearCache policy

##################################################################
# To Do
# 1. Clearcache policy could be more reusable if we decouple the static group remove and remove flag file steps - validate that these can be handled by callign the existing static group remove, then calling clearCache.  remove flag file may be redundant, as it is explicitly removed in the script
# 2. Can the Branded prompt be implemented within this script, to eliminate an eternal dependency?
#	if we do this, should we create a restart function which can be called from either the deadline or the user's choice at the prompt?
# Try this after the current deployment is completed so that the reconfiguration can be tested



##################################################################
# History
# Version 1.0 by Jason Abdul on 2026/01/22
# Modified by JA 2026/01/23 to reduce external dependency - implement brandedRestartPrompt in script
#	create functions for cleanup (rm flag file and call static group remove), branded restart prompt and branded restart notification
#	include jamf prompts in script to remove dependency on external policy.  Implement policy call to static group remove in function to remove requirement for these tasks to be bundled to the clearCache policy
##################################################################


##################################################################
# Handle Parameters
if [[  "$4" != "" ]] && [[ $THRESHOLD_DAYS == "" ]]; then
	THRESHOLD_DAYS=$4
else
	#if value not passed in, default to threshold value of 3 days
	THRESHOLD_DAYS=3
fi
##################################################################
# Environent variables
THRESHOLD_SECONDS=$(($THRESHOLD_DAYS * 24 * 60 * 60));
FLAG_FILE="/Library/Punahou/.restartRequired"
DEBUG=1
##################################################################

##################################################################
# Functions
function getBootInterval() {
	#find uptime in seconds
	bootTime=$(sysctl kern.boottime | awk '{print $5}' | tr -d ,)
	CURRENT_TIMESTAMP=$(date "+%s"); 
	BOOT_INTERVAL=$(($CURRENT_TIMESTAMP-$bootTime))
	echo $BOOT_INTERVAL
}
function getFileInterval() {
	#Find interval since file was last touched in seconds
	flagFileAge=$(date -r $FLAG_FILE +%s)
	CURRENT_TIMESTAMP=$(date "+%s"); 
	FILE_INTERVAL=$((CURRENT_TIMESTAMP-$flagFileAge))
	echo $FILE_INTERVAL
}
function cleanUp() {
	rm -f $FLAG_FILE
	jamf policy -event staticGroupRemoveRestartRequired
}
function brandedRestartPrompt() {
	#this function should return 0 - button1 (restart) or 2 - button2 defer/timeout 
	local RESULT=$("/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" -windowType utility -icon /Library/Punahou/256x256PunahouSeal-transparent.png -title "System Restart Required" -description "Your computer needs to be restarted within $THRESHOLD_DAYS days.  You may restart now by clicking Restart, or be prompted again in 15 minutes by clicking Defer" -button1 "Restart" -button2 "Defer" -defaultButton 2 -timeout 120 -countdown)
	echo $RESULT
}
function brandedRestartNotification() {
	"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" -windowType utility -icon /Library/Punahou/256x256PunahouSeal-transparent.png -title "System Restart Required" -description "Your computer has not been restarted within the $THRESHOLD_DAYS day deadline.  Restart is imminent" -button1 "OK" -defaultButton 1 -timeout 30 -countdown
}
##################################################################

##################################################################
# Main
##################################################################
#If the flag file does not exist (new/first run) then touch the file
if [ ! -f $FLAG_FILE ]; then
	touch $FLAG_FILE
fi

#NOW=$(date +%s)
#flagFileAge=$(date -r /Library/Punahou/.restartRequired +%s)
#echo "file age: $flagFileAge"
#$DIFF_SECONDS=$((NOW - $flagFileAge))
#echo "interval $DIFF_SECONDS"
#
[ $DEBUG ] && echo "boot interval= $(getBootInterval)"

if [ "$(getBootInterval)" -lt "$(getFileInterval)" ]; then
	#Computer has independently rebooted since being required to do so
	if [ $DEBUG ]; then
		echo "Boot Interval= $(getBootInterval)"
		echo "File Interval= $(getFileInterval)"
		echo "Computer rebooted already, clean up (remove from static group, remove flag file)"
	fi
	cleanUp
	exit 0
fi
#####  DO NOT UNCOMMENT unless you are explicitly testing for old file interval (deadline passed).  This will always fail and execute the else
#testFileInterval=(("$(getFileInterval)"+"$THRESHOLD_SECONDS"))
#if [ "$THRESHOLD_SECONDS" -lt "$THRESHOLD_SECONDS" ]; then

if [ "$(getFileInterval)" -lt "$THRESHOLD_SECONDS" ]; then
	if [ $DEBUG ]; then
		echo "File Interval= $(getFileInterval)"
		echo "Threshold Days= $THRESHOLD_DAYS"
		echo "Threshold Seconds= $THRESHOLD_SECONDS"
		echo "Deadline not met.  Prompt user for restart or defer"
	fi
	userChoice=$(brandedRestartPrompt)
	[ $DEBUG ] && echo "User Choice: $userChoice"
	if [ $userChoice == 0 ]; then
		echo "User chose Restart.  Clean up and clear cache restart"
		cleanUp
		jamf policy -event clearCache
	else
		echo "User chose defer, or prompt timed out"
	fi
else
	echo "Deadline passed.  Clean up and clear cache restart"
	cleanUp
	brandedRestartNotification
	jamf policy -event clearCache
fi
exit 0