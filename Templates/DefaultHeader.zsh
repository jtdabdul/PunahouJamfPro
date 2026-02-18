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
### Start logMessage 20260204
logMessage() {
    local message="$1"
    if [[ "$LOCAL_LOG_FILE" == "" ]]; then
	    echo "$(date +"$LogDateFormat") - $message"
	else
		echo "$(date +"$LogDateFormat") - $message" | tee -a "$LOCAL_LOG_FILE"
	fi
}
### End logMessage
### Start runAsUser 20240419
runAsUser() {
  if [[ $currentUser != "loginwindow" ]]; then
    uid=$(id -u "$currentUser")
    launchctl asuser $uid sudo -u $currentUser "$@"
  fi
}
### End runAsUser
#MARK: End Default Header
