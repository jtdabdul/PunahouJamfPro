#!/bin/bash
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
#         Modified 2026/07/10 by JA - update logging - implement log levels, add caller functions named to imply the second parameter
########################################################################################################################
### Global Variables
VERSIONDATE='20260710'        # Format YYYYMMDD - used for version control
APPLICATION="ApplicationName" # Change to your application name for logging
LOCKED_THRESHOLD=604800       # If the computer is locked for this long (7 days) then exit to prevent issues with Jamf policies blocking other policies.
SHUTDOWN_THRESHOLD=2592000    # If the computer is locked for this long (30 days) then prompt for shutdown.
MINSWVERSION=13               # Minimum macOS version required to run this script
#No Datadog implementation for our organization so far.
DATADOGAPI=""                 # Add your Datadog API key here to enable Datadog logging, otherwise leave blank. NOTE: Mann recommends encryping your API keys.
icon="/Library/Punahou/256x256PunahouSeal-transparent.png"	# Path to icon to use in jamfHelper windows  

#MARK: Start Default Header
##### Start Default Header 20260707
PATH="/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin"
scriptPath=${0}

# Get current console user details safely in Bash
consoleUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
currentUser=${consoleUser:-UnknownUserName}

currentUserID=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/kCGSSessionUserIDKey :/ { print $3 }')
currentUserHome=$(dscl . -read Users/${currentUser} 2>/dev/null | grep ^NFSHomeDirectory | awk '{print $2}')
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
LogDateFormat="%Y-%m-%d %H:%M:%S"
starttime=$(date +"$LogDateFormat")
LOCAL_LOG_FILE=""			# Add file path to enable local logging, otherwise leave blank
#declare -rA levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
LOGGING="INFO"  #default log level set at info, in main this can be overwritten

### Start Logging 20250728
readonly jamfVarJSSID=$(defaults read "/Library/Managed Preferences/com.mann.jamfuserdata.plist" JSSID 2>/dev/null || echo 0)
readonly JSSURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url 2>/dev/null) \
         hostname=${hostname:-$(hostname)} \
         computername=${computername:-$(scutil --get ComputerName 2>/dev/null)} \
         serialnumber=${serialnumber:-$(ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')} \
         SESSIONID=${jamfVarJSSID}-$RANDOM
### Start logMessage 20260204
getPriorityLevel() {
  case "$1" in
    DEBUG)  echo 0 ;;
    INFO)   echo 1 ;;
    WARN)   echo 2 ;;
    ERROR)  echo 3 ;;
    *)      echo 1 ;; #default fallback
  esac
}
logMessage() {
  [[ -z "$1" ]] && return   #do nothing and exit function if no arguments are passed
  local message="$1"
  local logPriority=${2:-INFO}  #Default to INFO if no second argument is passed
  
  #get numeric priorities using the getPriorityLevel helper function
  local currentPriority=$(getPriorityLevel "$logPriority")
  local minPriority=$(getPriorityLevel "$LOGGING")
  
  if [[ $currentPriority -ge $minPriority ]]; then
      if [[ -z "$LOCAL_LOG_FILE" ]]; then
        echo "$(date +"$LogDateFormat") [$logPriority] - $message"
      else
        echo "$(date +"$LogDateFormat") [$logPriority] - $message" | tee -a "$LOCAL_LOG_FILE"
      fi
  fi
}
log() { #instead of renaming the function, add a caller function for backwards compatibility
  logMessage "$1" "$2"
}
#Add some additional logging functions to allow for single parameter logs with log priority identified in the function name
logINFO() {
  logMessage "$1" INFO
}
logDEBUG() {
  logMessage "$1" DEBUG
}
logWARN() {
  logMessage "$1" WARN
}
logERROR() {
  logMessage "$1" ERROR
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

#LOGGING="WARN"
##LOCAL_LOG_FILE="$currentUserHome/test.log"
#echo "logging level = $LOGGING"
#logMessage "this is a test log message using default priority"
#logMessage "this is a debug level log entry" DEBUG
#logMessage "this is an explicitly INFO level log message" INFO
#logMessage "this is a WARN level" WARN
#logMessage "this is an ERROR level" ERROR
#logMessage "test log"
#
#logMessage "test additional log functions"
#log "test log"
#logWARN "test log WARN"
#logERROR "test log Error"
#logDEBUG "this should not output, unless I set to debug"
