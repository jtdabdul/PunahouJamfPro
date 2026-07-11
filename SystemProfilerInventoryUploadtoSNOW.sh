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

# Display NameDisplay name for the script
# System Profiler Inventory Upload to SNOW launchagent and script
# CategoryCategory to add the script to
# Maintenance
# InformationInformation to display to the administrator when the script is run
# NotesNotes to display about the script (e.g., who created it and when it was created)
# Adapted from script collaborated on by Ben Anderson and Jason A, script will create /Library/Scripts/SystemProfilerInventoryUploadToSNOW.sh update file permissions and ownership, and /Library/LaunchDaemons/com.punahou.inventorySNOW.plist modify file permissions and ownership, then load the launchDaemon plist 
# designed to call the script once a day.
# Modified 2024/10/21 by JA - add newline to beginning of log output for log file formatting.  Rm files if they exists before writing out files to support updating script and launchdaemon on clients for future edits
# Modified 2024/10/28 by JA - Jamf400 class template applied and modified to include logging from previous version
# Modified 2025/03/04 by JA - update SNOW user/pass and upload URL to put reporting into production
# Modified 2026/07/07 by JA - update script to use self installing template instead of HEREDOC to install the script on the client.
# Modified 2026/07/10 by JA - update logging
set_defaults() {
# Path to the script working folder
	SCRIPT_FOLDER="/Library/Scripts"
	readonly SCRIPT_FOLDER
	SCRIPT_NAME="SystemProfilerInventoryUploadToSNOW.sh"
	readonly SCRIPT_NAME
	LAUNCH_DAEMON_LABEL="com.punahou.inventorySNOW"	#no trailing ".plist"
	readonly LAUNCH_DAEMON_LABEL
	INSTALL_PATH="$SCRIPT_FOLDER/$SCRIPT_NAME"
	LOCAL_LOG_FILE="/Library/Punahou/ApplicationsCheck.log"
}
#super 3600
workflow_installation() {
	# --- Self-Installation Logic ---
	# 1. Get the absolute path of the currently running script
	CURRENT_SOURCE=$(realpath "$0")

	# 2. Check if the current location matches the intended install path
	if [ "$CURRENT_SOURCE" != "$INSTALL_PATH" ]; then
	    logDEBUG "Current location: $CURRENT_SOURCE"
	    logDEBUG "Installing to:    $INSTALL_PATH"

	    # Create the directory if it doesn't exist
	    [[ ! -d "${SCRIPT_FOLDER}" ]] && mkdir -p "$SCRIPT_FOLDER"

	    # Copy the script to the destination
	    cp "$CURRENT_SOURCE" "$INSTALL_PATH"
	    chmod +x "$INSTALL_PATH"

	    log "Installation complete. Running from new location..."
	    
	    # 3. Execute the installed version and exit the current process
	    exec "$INSTALL_PATH" "$@"
	fi
#	cp "$0" "${SCRIPT_FOLDER}/${SCRIPT_NAME}" >/dev/null 2>&1
}
handle_plist() {
	local plistPath="/Library/LaunchDaemons/$LAUNCH_DAEMON_LABEL.plist"
	#define the Heredoc once as a variable
	local PLIST_CONTENT
	PLIST_CONTENT=$(	cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$LAUNCH_DAEMON_LABEL</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/bash</string>
		<string>$INSTALL_PATH</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StartCalendarInterval</key>
	<array>
		<dict>
			<key>Hour</key>
			<integer>0</integer>
			<key>Minute</key>
			<integer>0</integer>
		</dict>
	</array>
	<key>StandardErrorPath</key>
	<string>/Library/Punahou/ApplicationsCheck.log</string>
</dict>
</plist>
EOF
)
	#compare the heredoc with the existing plist
	if [  -f "$plistPath" ] && diff -q <(plutil -convert json -o - - <<< "$PLIST_CONTENT") \
		<(plutil -convert json -o - "$plistPath") > /dev/null; then
			logDEBUG "Success: the plist matches the heredoc exactly"
			logDEBUG "validate launchdaemon is running"
			
			if sudo launchctl print system/"$LAUNCH_DAEMON_LABEL" > /dev/null 2>&1; then
				logDEBUG "launchdaemon is running"
			else
				logDEBUG "launchdaemon is not running.  loading plist"
				sudo launchctl bootstrap system "$plistPath"
			fi
			return 0
		else
			log "heredoc does not match the existing plist file, or file doesn't exist"
		fi
	
	####Unload the PLIST
	if [[ -f "$plistPath" ]]; then
		logDEBUG "Plist File Found: Bootout"
		sudo launchctl bootout system "$plistPath"
		rm -rf $plistPath
	else
		log "Plist File not found"
	fi
	#write the PLIST_CONTENT to the plistPath
	echo "$PLIST_CONTENT" > $plistPath
	
	chmod 644 $plistPath
	chown root:wheel $plistPath
	echo "LaunchDaemon created at $plistPath"
	ls -l $plistPath
	plutil -lint $plistPath
	defaults read $plistPath
	
	logDEBUG "Load LaunchDaemon"
	#	/bin/launchctl load -w $plistPath
	sudo /bin/launchctl bootstrap system "$plistPath"
}
function inventoryUploadToSNOW() {
	log "Upload to SNow"
	file="/Library/Punahou/applicationOutput.json"	#provide file path for applicationOutput.json
	temp="/Library/Punahou/temp.json"	#provide file path for temp.json
	# Get the serial number
	serial_number=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
	# Generate JSON output from system_profiler and save it to a file
	system_profiler SPApplicationsDataType -json > $file
	# Define the regex pattern (note that we're using extended regex for more flexibility)
	regex='"_name"'
	# Perform the find and replace using sed
	sed -E "s|($regex)|\"serial\": \"$serial_number\",\n\\1|g" $file > $temp
	# Replace the original file with the modified one
	mv $temp $file
	# Replace SPApplicationsDataType with records
	sed "s/SPApplicationsDataType/records/g" $file > $temp
	mv $temp $file
	#push file to SNOW
	log $(curl "https://punahou.service-now.com/api/now/import/x_punsc_device_dat_computer_software_instance_import_set/insertMultiple" \
	--request POST \
	--header "Accept:application/json" \
	--header "Content-Type:application/json" \
	--data "@$file" \
	--user 'device_collector_software':'3hQX8}[$],jq^4PWY}hURLBT1raoqw*%94;Fc^a%Sh}D]1ko}sfskua{Q2BS_%%cM9n]NdD?zH--BQJ@k-JZ8m3yrqm{ZN=^zmn$' 2>> $LOCAL_LOG_FILE)
}
check_interval() {
	#For use if the launchdaemon is set to run more often then execution is desired.  Pass in an interval in seconds, and if the interval has passed since the last run (stored in a LAST_RUN_FILE, or LAST_RUN_FILE not found) then the function returns TRUE and updates LAST_RUN_FILE.  Otherwise it returns FASLE
	#Usage: check_interval <interval in seconds> <tracking file path>
	
	local INTERVAL_SECONDS="$1"
#	local LAST_RUN_FILE="$2"		using global LAST_RUN_FILE
	local LAST_RUN_FILE="/Library/Punahou/InventorySNOW.last_run_time"
	local CURRENT_TIME
	local LAST_RUN_TIME
	
	# Get the current time in seconds since epoch
	CURRENT_TIME=$(date +%s)
	
	# If the LAST_RUN_FILE doesn't exist, create it and return TRUE
	if [ ! -f "$LAST_RUN_FILE" ]; then
		echo "$CURRENT_TIME" > "$LAST_RUN_FILE"
		return 0
	fi
	
	#read the last run time
	LAST_RUN_TIME=$(cat "$LAST_RUN_FILE")
	
	#calculate Time elapsed
	TIME_DIFF=$((CURRENT_TIME - LAST_RUN_TIME))
	
	# check if interval has elapsed
	if [ "$TIME_DIFF" -ge "$INTERVAL_SECONDS" ]; then
		#update the LAST_RUN_FILE with the current time
		echo "Time difference: $TIME_DIFF >$ threshold interval: $INTERVAL_SECONDS, return true"
		return 0
	else
		echo "Threshold interval:$INTERVAL_SECONDS > Time difference: $TIME_DIFF, return false"
		return 1
	fi
}
###################### MAIN #############################
#LOGGING="DEBUG"
APPLICATION="SystemProfilerInventoryUploadToSNow"
log "start $APPLICATION"
set_defaults
workflow_installation

# --- Your Actual Script Starts Here ---
logDEBUG "Hello! I am running successfully from $INSTALL_PATH"
handle_plist 
# 2026-07-08 Current approach will not consider a 24 hour run interval.  Instead whenever the script is called we will attempt to upload inventory to SNow
#if check_interval 86400; then
#	echo "Interval passed, running the scheduled task"
#	inventoryUploadToSNOW 
#else
#	logMessage "Too soon. Skipping task"
#fi
inventoryUploadToSNOW
log "end $APPLICATION"
exit 0

#tail -f /var/log/system.log