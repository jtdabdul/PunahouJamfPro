#!/bin/zsh
########################################################################################################################
# Default Header
# Created by:	Jason Abdul (jabdul@punahou.edu)
# Summary:		This is a default header intended to be included in shell scripts in jamf.  
#				Commonly used Global variables, and functions are included.
# Documentation: (#URL)
#
# Note:			This is a starter header, to be updated in the future.  
#				Used Mann Consulting JNUC2025 header for reference. https://mann.com/jnuc2025
# History:		Created on 2026/02/04 by JA
########################################################################################################################
### Global Variables
VERSIONDATE='20260204'        # Format YYYYMMDD - used for version control
APPLICATION="ApplicationName" # Change to your application name for logging
LOCKED_THRESHOLD=604800       # If the computer is locked for this long (7 days) then exit to prevent issues with Jamf policies blocking other policies.
SHUTDOWN_THRESHOLD=2592000    # If the computer is locked for this long (30 days) then prompt for shutdown.
MINSWVERSION=13               # Minimum macOS version required to run this script
#No Datadog implementation for our organization so far.
DATADOGAPI=""                 # Add your Datadog API key here to enable Datadog logging, otherwise leave blank. NOTE: Mann recommends encryping your API keys.
icon="/Library/Punahou/256x256PunahouSeal-transparent.png"	# Path to icon to use in jamfHelper windows  

#MARK: Start Default Header
##### Start Default Header 20260204
zmodload zsh/datetime
PATH="/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin"
scriptPath=${0}
currentUser=${$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }'):-UnknownUserName}
currentUserID=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/kCGSSessionUserIDKey :/ { print $3 }')
currentUserHome=$(dscl . -read Users/${currentUser} | grep ^NFSHomeDirectory | awk '{print $2}')
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
LogDateFormat="%Y-%m-%d %H:%M:%S"
starttime=$(strftime "$LogDateFormat")
LOCAL_LOG_FILE=""			# Add file path to enable local logging, otherwise leave blank


### Start Logging 20250728
readonly jamfVarJSSID=$(defaults read "/Library/Managed Preferences/com.mann.jamfuserdata.plist" JSSID 2>/dev/null || echo 0)
readonly JSSURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url 2>/dev/null) \
         hostname=${hostname:-$(hostname)} \
         computername=${computername:-$(scutil --get ComputerName 2>/dev/null)} \
         serialnumber=${serialnumber:-$(ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')} \
         SESSIONID=${jamfVarJSSID}-$RANDOM
### Start log 20260204
log() {
#    local message="$1"
#    local timestamp=$(strftime '%Y-%m-%d %H:%M:%S')
# include the script name in the log entries:
# echo "$(strftime '%Y-%m-%d %H:%M:%S') $(hostname -s) $(basename "$ZSH_ARGZERO"): $*"
  if [[ "$LOCAL_LOG_FILE" == "" ]]; then
		echo "$(strftime '%Y-%m-%d %H:%M:%S') $(hostname -s): $*"
	else
		[ -d ${LOCAL_LOG_FILE:h} ] || mkdir ${LOCAL_LOG_FILE:h}
		echo "$(strftime '%Y-%m-%d %H:%M:%S') $(hostname -s): $*" | tee -a "$LOCAL_LOG_FILE"
	fi
}
### End log
### Start runAsUser 20240419
runAsUser() {
  if [[ $currentUser != "loginwindow" ]]; then
    uid=$(id -u "$currentUser")
    launchctl asuser $uid sudo -u $currentUser "$@"
  fi
}
### End runAsUser
#MARK: End Default Header

##################################################################
# About this script
# This script requires several other objects in jamf to support it's workflow

# Static group - Restart Required to scope the policy running this script
# Policy - Static Group remove Restart Required - remove the computer from the static group once reboot is executed, by the script or by the user
# Policy - Clear Cache - clear cache and restart

# Script is designed to run in policy set to recurring check in ongoing, scoped to static group Restart Required
# check for flag file existence and touch(create) if not found
# check if user has rebooted on their own - if flag file age is > boot time interval - remove from static group and exit, preventing further execution
# If computer has not yet rebooted, check to see if the threshold deadline is reached (days parameter passed in to script)
# deadline not reached, prompt user - button 2 (defer) do nothing and wait for next run.  button 1 (restart) clean up flag file and static group, then call clearcache
# deadline reached - prompt restart imminent, call clearCache policy

##################################################################
# To Do
# 1. Clearcache policy could be more reusable if we decouple the static group remove and remove flag file steps - validate that these can be handled by callign the existing static group remove, then calling clearCache.  remove flag file may be redundant, as it is explicitly removed in the script
# 2. Can the Branded prompt be implemented within this script, to eliminate an eternal dependency?
#	if we do this, should we create a restart function which can be called from either the deadline or the user's choice at the prompt? - completed 2026/01/23
# Try this after the current deployment is completed so that the reconfiguration can be tested



##################################################################
# History
# Version 1.0 by Jason Abdul on 2026/01/22
# Modified by JA 2026/01/23 to reduce external dependency - implement brandedRestartPrompt in script
#	create functions for cleanup (rm flag file and call static group remove), branded restart prompt and branded restart notification
#	include jamf prompts in script to remove dependency on external policy.  Implement policy call to static group remove in function to remove requirement for these tasks to be bundled to the clearCache policy
# Modified by JA 2026/02/04 to add proposed default header.  Improves logging and includes optional logging to local file.
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
APPLICATION="RestartRequired"
THRESHOLD_SECONDS=$(($THRESHOLD_DAYS * 24 * 60 * 60));
FLAG_FILE="/Library/Punahou/.restartRequired"
LOCAL_LOG_FILE="/var/log/RestartRequired.log"
DEBUG="TRUE"	#DEBUG="TRUE" put script in debug logging mode, any other value is debug off "FALSE", 0, etc
#DEBUG="FALSE"
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
	local RESULT=$(runAsUser $jamfHelper -windowType utility -icon $icon -title "System Restart Required" -description "Your computer needs to be restarted within $THRESHOLD_DAYS days.  You may restart now by clicking Restart, or be prompted again in 15 minutes by clicking Defer" -button1 "Restart" -button2 "Defer" -defaultButton 2 -timeout 120 -countdown)
	echo $RESULT
}
function brandedRestartNotification() {
	runAsUser $jamfHelper -windowType utility -icon $icon -title "System Restart Required" -description "Your computer has not been restarted within the $THRESHOLD_DAYS day deadline.  Restart is imminent" -button1 "OK" -defaultButton 1 -timeout 30 -countdown
}
##################################################################

##################################################################
# Main
##################################################################
#If the flag file does not exist (new/first run) then touch the file
log "################## Start $APPLICATION $VERSIONDATE "
if [ ! -f $FLAG_FILE ]; then
	touch $FLAG_FILE
    log "Flag file not found, new start time recorded"
fi

#NOW=$(date +%s)
#flagFileAge=$(date -r /Library/Punahou/.restartRequired +%s)
#echo "file age: $flagFileAge"
#$DIFF_SECONDS=$((NOW - $flagFileAge))
#echo "interval $DIFF_SECONDS"
#
[[ $DEBUG == "TRUE" ]] && log "boot interval= $(getBootInterval)"

if [ "$(getBootInterval)" -lt "$(getFileInterval)" ]; then
	#Computer has independently rebooted since being required to do so
	if [[ $DEBUG == TRUE ]]; then
		log "Boot Interval= $(getBootInterval)"
		log "File Interval= $(getFileInterval)"
		log "Computer rebooted already, clean up (remove from static group, remove flag file)"
	fi
	cleanUp
	exit 0
fi
#####  DO NOT UNCOMMENT unless you are explicitly testing for old file interval (deadline passed).  This will always fail and execute the else
#testFileInterval=(("$(getFileInterval)"+"$THRESHOLD_SECONDS"))
#if [ "$THRESHOLD_SECONDS" -lt "$THRESHOLD_SECONDS" ]; then

if [ "$(getFileInterval)" -lt "$THRESHOLD_SECONDS" ]; then
	if [[ $DEBUG == "TRUE" ]]; then
		log "File Interval= $(getFileInterval)"
		log "Threshold Days= $THRESHOLD_DAYS"
		log "Threshold Seconds= $THRESHOLD_SECONDS"
	fi
	log "Deadline not met.  Prompt user for restart or defer"
	userChoice=$(brandedRestartPrompt)
	[[ $DEBUG == "TRUE" ]] && log "User Choice: $userChoice"
	if [[ "$userChoice" == "0" ]]; then
		log "User chose Restart.  Clean up and clear cache restart"
		cleanUp
		jamf policy -event clearCache &
	else
		log "User chose defer, or prompt timed out"
	fi
else
	log "Deadline passed.  Clean up and clear cache restart"
	cleanUp
	brandedRestartNotification
	jamf policy -event clearCache &
fi
log "################## End $APPLICATION (took $((( (`strftime %s` - `date -jf $LogDateFormat $starttime +%s`) ))) seconds)"
exit 0