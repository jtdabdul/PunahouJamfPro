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
# This script is designed to install itself to the SCRIPT_FOLDER if it is run from any other location (ex: as a jamf policy, or from USB)
######## Option 1 - working here 2026/05/08 JA
# It will create a LaunchDaemon that will call itself daily and exit unless uptime is greater than MAX_UPTIME
# If uptime > MAX_UPTIME then create a secondary launchDaemon that will call this script with an argument ($1)
#	Workflow with arg
#	1. If flag file does not exist, a flag file will be created to establish FILE_INTERVAL
#	2. If the FILE_INTERVAL > UPTIME, clean up flag file and exit
#	3. User will be prompted to restart within DEADLINE_DAYS, user is allowed to defer until FILE_INTERVAL > DEADLINE DAYS
#	4. If user defers, a launchdaemon will be generated to run the script again at NOW+DEFER_SECONDS
#	5. 
set_defaults() {
# Path to the script working folder
SCRIPT_FOLDER="/Library/Punahou/Scripts"
readonly SCRIPT_FOLDER
SCRIPT_NAME="restartRequiredwithLaunchDaemon.sh"
readonly SCRIPT_NAME
LAUNCH_DAEMON_LABEL="com.punahou.restartRequired"	#no trailing ".plist"
readonly LAUNCH_DAEMON_LABEL
INSTALL_PATH="$SCRIPT_FOLDER/$SCRIPT_NAME"
}
#super 3600
workflow_installation() {
	# --- Self-Installation Logic ---
	# 1. Get the absolute path of the currently running script
	CURRENT_SOURCE=$(realpath "$0")

	# 2. Check if the current location matches the intended install path
	if [ "$CURRENT_SOURCE" != "$INSTALL_PATH" ]; then
	    echo "Current location: $CURRENT_SOURCE"
	    echo "Installing to:    $INSTALL_PATH"

	    # Create the directory if it doesn't exist
	    [[ ! -d "${SCRIPT_FOLDER}" ]] && mkdir -p "$SCRIPT_FOLDER"

	    # Copy the script to the destination
	    cp "$CURRENT_SOURCE" "$INSTALL_PATH"
	    chmod +x "$INSTALL_PATH"

	    echo "Installation complete. Running from new location..."
	    
	    # 3. Execute the installed version and exit the current process
	    exec "$INSTALL_PATH" "$@"
	fi
	### HANDLE LAUNCHDAEMON
    if [[ -f "/Library/LaunchDaemons/${LAUNCH_DAEMON_LABEL}.plist" ]]; then
        log_super "Installation: Removing previous super LaunchDaemon: /Library/LaunchDaemons/${LAUNCH_DAEMON_LABEL}.plist"
        launchctl bootout "system/${LAUNCH_DAEMON_LABEL}" >/dev/null 2>&1
        rm -f "/Library/LaunchDaemons/${LAUNCH_DAEMON_LABEL}.plist" 2>/dev/null
    fi
    ### use HEREDOC to construct main launchdaemon here
}
###################### MAIN #############################
set_defaults
workflow_installation

# --- Your Actual Script Starts Here ---
echo "Hello! I am running successfully from $INSTALL_PATH"

#if secondary launchdaemon has called the script, it will pass an argument to indicate threshold days reached.
if [[ -z $1 ]]; then 