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
# It will install a launchdaemon so that the script is called daily
# test uptime against UPTIME_THRESHOLD, if UPDATE_THRESHOLD not reached, log it and go to sleep
# UPTIME_THRESHOLD reached - put a DEADLINE in epoch seconds in the local DEADLINE_FILE (plist) file
# if DEADLINE is reached - prompt the user to warn with 1 minute timeout and force reboot
# else prompt user to reboot now or defer
# if defer, set a launchdaemon to ask again after deferral time has elapsed
#
# if computer is rebooted independedntly between execution, uptime should be below threshold and script will set daily launchdaemon and sleep



# --- Functions ---

write_daemon() {
    local label=$1
    local plist_path=$2
    local seconds_from_now=$3
    
    # Calculate trigger time for the plist
    # If seconds_from_now is 86400 (daily), use StartInterval
    # Otherwise, use StartAtLaunch/StartInterval for the one-off deferral
    
    cat <<EOF > "$plist_path"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$label</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_PATH</string>
    </array>
    <key>StartInterval</key>
    <integer>$seconds_from_now</integer>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF
    chown root:wheel "$plist_path"
    chmod 644 "$plist_path"
    launchctl load -w "$plist_path" 2>/dev/null
}
remove_daemon() {
	#this function was expected to delete the plist file as well as unload the daemon, it is currently only unloading the daemon
	local label=$1
	local plist_path=$2
	launchctl bootout "system/${label}" >/dev/null 2>&1
	#replace with this:?
	#launchctl unload "$plist_path" 2>/dev/null 
	rm -f "plist_path" 2>/dev/null
}
#super 3600
workflow_installation() {
	# --- Self-Installation Logic ---
	# 1. Get the absolute path of the currently running script
	current_file=${(%):-%x}
	CURRENT_SOURCE=${current_file:A}

	# 2. Check if the current location matches the intended install path
	if [ "$CURRENT_SOURCE" != "$SCRIPT_PATH" ]; then
	    log "Current location: $CURRENT_SOURCE"
	    log "Installing to:    $SCRIPT_PATH"

	    # Create the directory if it doesn't exist
	    [[ ! -d "${SCRIPT_FOLDER}" ]] && mkdir -p "$SCRIPT_FOLDER"

	    # Copy the script to the destination
	    cp "$CURRENT_SOURCE" "$SCRIPT_PATH"
	    chmod +x "$SCRIPT_PATH"

			### HANDLE LAUNCHDAEMON
			if [[ -f $DAILY_PLIST ]]; then
				log "Installation: Removing previous LaunchDaemon: $DAILY_PLIST"
				launchctl bootout "system/${DAILY_LABEL}" >/dev/null 2>&1
				#replace with this:?
				#launchctl unload "$DAILY_PLIST" 2>/dev/null 
				rm -f "DAILY_PLIST" 2>/dev/null
			fi
			#write the daily launchdaemon, set to run in one day
			log "write the daily launchdaemon"
			write_daemon "$DAILY_LABEL" "$DAILY_PLIST" 86400
			### END HANDLE LAUNCHDAEMON
	    
	    log "Installation complete. Running from new location..."
	    
	    # 3. Execute the installed version and exit the current process
	    exec "$SCRIPT_PATH" "$@"
	fi
	
}
###################### MAIN #############################

# --- Configuration ---
############ Local Files ###############
###### Script configuration ############
SCRIPT_FOLDER="/Library/Punahou/Scripts"
readonly SCRIPT_FOLDER
SCRIPT_NAME="rebootRequiredwithLaunchDaemon.sh"
readonly SCRIPT_NAME
SCRIPT_PATH="$SCRIPT_FOLDER/$SCRIPT_NAME"
###### launchDaemon ###############
DAILY_LABEL="com.punahou.rebootRequired.daily"
DEFER_LABEL="com.punahou.rebootRequired.defer"
DAILY_PLIST="/Library/LaunchDaemons/$DAILY_LABEL.plist"
DEFER_PLIST="/Library/LaunchDaemons/$DEFER_LABEL.plist"
##### Log Configuration ###############
LOCAL_LOG_FILE="/var/log/rebootRequiredwithLaunchDaemon.log"
##### Local Config file ###############
DEADLINE_FILE="/Library/Punahou/reboot_deadline.plist"
############/Local Files ###############
############ Environment Variables ###############
#testing use 1 day uptime threshold.
UPTIME_THRESHOLD=1 # Days
#UPTIME_THRESHOLD=30 # Days
DEFER_THRESHOLD=1      # Days to comply
############ JamfHelper Variables ################
JAMFHELPER_TITLE="Punahou School"
JAMFHELPER_HEADING="Reboot is required."
JAMFHELPER_HEADING_FORCE="Reboot deadline expired."
JAMFHELPER_TIMEOUT=60
############/Environment Variables ###############

# --- Main Logic ---
#set_defaults
workflow_installation

# --- Your Actual Script Starts Here ---
log "Hello! I am running successfully from $SCRIPT_PATH"
# 1. Check Uptime
UPTIME_SECONDS=$(sysctl -n kern.boottime | awk -F'[ ,]' '{print $4}')
CURRENT_TIME=$(date +%s)
UPTIME_DAYS=$(( (CURRENT_TIME - UPTIME_SECONDS) / 86400 ))
log "UPTIME $UPTIME_DAYS found"

if [ "$UPTIME_DAYS" -lt "$UPTIME_THRESHOLD" ]; then
    log "System is fresh ($UPTIME_DAYS is < $UPTIME_THRESHOLD); ensure only daily daemon exists"
    log "unload defer launchdaemon and delete files"
    launchctl unload "$DEFER_PLIST" 2>/dev/null
    rm -f "$DEFER_PLIST" "$DEADLINE_FILE"
    log "go back to sleep.  Relaunch scheduled for $(strftime "%Y-%m-%d %H:%M:%S" $(( EPOCHSECONDS + 86400 )))"
    #do I have to put the daily launchdaemon back here?  put back if not found?
    exit 0
fi

# 2. Manage Deadline - if we didn't exit after checking uptime, then we are past the uptime threshold
log "uptime threshold $UPTIME_THRESHOLD days reached"
if [ ! -f "$DEADLINE_FILE" ]; then
    DEADLINE_DATE=$(( CURRENT_TIME + (DEFER_THRESHOLD * 86400) ))
		log "no deadline file found, write a deadline for $DEADLINE_DATE to $DEADLINE_FILE"
    defaults write "$DEADLINE_FILE" deadline -int $DEADLINE_DATE
fi

DEADLINE=$(defaults read "$DEADLINE_FILE" deadline)
REMAINING=$(( DEADLINE - CURRENT_TIME ))
log "deadline file found, $REMAINING second until deadline"

# 3. Check Enforcement
if [ "$REMAINING" -le 0 ]; then
	log "Enforcement deadline reached, prompt user briefly and restart"
	$jamfHelper -windowType utility -icon $icon -title $JAMFHELPER_TITLE -heading "$JAMFHELPER_HEADING_FORCE" -description "Your computer will reboot in 60 seconds" -button1 OK -timeout "$JAMFHELPER_TIMEOUT" -countdown
	shutdown -r now
	exit 0
fi

# 4. Prompt User
# Note: In a LaunchDaemon, we must target the user session for GUI
#USER_ID=$(stat -f%u /dev/console) - Jamfhelper apparently knows how to access the user's gui
RESPONSE=$($jamfHelper -windowType utility -icon $icon -title $JAMFHELPER_TITLE -heading "$JAMFHELPER_HEADING" -description "You may choose to reboot now, or you can defer.  Please make a selection" -button1 "Restart Now" -button2 "Defer" -defaultButton 2 -showDelayOptions "900, 3600, 14400, 86400" -timeout "$JAMFHELPER_TIMEOUT" -countdown)
#jamfhelper defer options return the delay time followed by 1 (for clicking the OK button/button 1) ex: 0 returns 1, 900 returns 9001, 3600 returns 36001, etc. Button 2 appends a 2 on the DelayOptions selected value
#in order to have the timeout behavior default to the shorted delay, and ensure timeout does not result in restart now, defaultButton set to button 2

log "User chose $RESPONSE"
log "get rightmost digit from RESPONSE - JamfHelper stores which button was used in the rightmost digit if delayOptions are used"
BUTTON=$(( $RESPONSE % 10 ))
log "button $BUTTON was pressed, 1:button 1 (restart now); 2:button 2 (Defer/Delay) - button2 can also be \"pressed\" by timeout"

### working here
if [[ $BUTTON == 1 ]]; then
	log "User chose to restart now, ignore delayOptions value and restart now"
	#do I have to put the daily launchdaemon back here?  put back if not found? 
	shutdown -r now
else #BUTTON 2 was used or timeout was reached
	log "User clicked button 2 (Defer/Delay), or timeout has occurred"
	SECONDS_TO_WAIT=$(echo "$RESPONSE" | /usr/bin/sed 's/.$//')
	log "Get SECONDS_TO_WAIT from RESPONSE: $SECONDS_TO_WAIT"
	log "user chose to defer for $SECONDS_TO_WAIT seconds, set up launchdaemon to wake up after $SECONDS_TO_WAIT"
	# Disable the daily check so it doesn't fire while we are in a deferral loop
	log "disable Daily launchdaemon $DAILY_LABEL"
	launchctl unload "$DAILY_PLIST" 2>/dev/null
	remove_daemon "$DAILY_LABEL" "$DAILY_PLIST"
	# Write the deferral daemon to fire once the time expires
	log "write launchdaemon $DEFER_LABEL to launch in $SECONDS_TO_WAIT and exit. Relaunch scheduled for $(strftime "%Y-%m-%d %H:%M:%S" $(( EPOCHSECONDS + SECONDS_TO_WAIT )))"
	write_daemon "$DEFER_LABEL" "$DEFER_PLIST" "$SECONDS_TO_WAIT"
	exit 0
fi