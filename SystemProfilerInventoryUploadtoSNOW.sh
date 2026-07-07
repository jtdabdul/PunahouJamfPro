#!/bin/bash

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

set_defaults() {
# Path to the script working folder
SCRIPT_FOLDER="/Library/Punahou/Scripts"
readonly SCRIPT_FOLDER
SCRIPT_NAME="SystemProfilerInventoryUploadToSNOW.sh"
readonly SCRIPT_NAME
LAUNCH_DAEMON_LABEL="com.punahou.inventorySNOW"	#no trailing ".plist"
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
#	cp "$0" "${SCRIPT_FOLDER}/${SCRIPT_NAME}" >/dev/null 2>&1
}
###################### MAIN #############################
set_defaults
workflow_installation

# --- Your Actual Script Starts Here ---
echo "Hello! I am running successfully from $INSTALL_PATH"

scriptfile="/Library/Scripts/SystemProfilerInventoryUploadToSNOW.sh"
### Handle Script
echo "Handle script first"
echo "Remove script $scriptPath if found"
rm -f $scriptfile	#remove the script if it exists
cat << 'EOF' > $scriptfile
#!/bin/bash
logfile="/Library/Punahou/ApplicationsCheck.log"
exec 1>> "$logfile"
exec 2>&1
function inventoryUploadToSNOW() {
	echo ""
	echo `date +%Y-%m-%d\ %H:%M:%S`
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
	curl "https://punahou.service-now.com/api/now/import/x_punsc_device_dat_computer_software_instance_import_set/insertMultiple" \
	--request POST \
	--header "Accept:application/json" \
	--header "Content-Type:application/json" \
	--data "@$file" \
	--user 'device_collector_software':'3hQX8}[$],jq^4PWY}hURLBT1raoqw*%94;Fc^a%Sh}D]1ko}sfskua{Q2BS_%%cM9n]NdD?zH--BQJ@k-JZ8m3yrqm{ZN=^zmn$'
}
###Template for launchDaemon to run script at shorter interval - execute the function only if 24 hours have passed since last run
# File to store the last execution time
LAST_RUN_FILE="/Library/Punahou/InventorySNOW.last_run_time"

# Get the current time in seconds since epoch
CURRENT_TIME=$(date +%s)

# Check if the file exists
if [[ -f "$LAST_RUN_FILE" ]]; then
    # Read the last run time from the file
    LAST_RUN_TIME=$(cat "$LAST_RUN_FILE")
else
    # If the file doesn't exist, set last run time to 0
    LAST_RUN_TIME=0
fi

# Calculate the time difference
TIME_DIFF=$((CURRENT_TIME - LAST_RUN_TIME))

# Check if more than 24 hours (86400 seconds) have passed
if ((TIME_DIFF >= 86400)); then
    #echo "Executing task..."
    
    # Place your task commands here
    inventoryUploadToSNOW

    # Update the last run time
    echo "$CURRENT_TIME" > "$LAST_RUN_FILE"
else
	echo ""
    echo "`date +%Y-%m-%d\ %H:%M:%S` Task was already executed within the last 24 hours."
fi

exit 0
EOF

chmod 644 $scriptfile
chown root:wheel $scriptfile
#chmod +x $scriptfile
echo "Script created at $scriptfile"
ls -l $scriptfile
###Handle Plist
plistPath="/Library/LaunchDaemons/com.punahou.inventorySNOW.plist"
####Unload the PLIST
if [[ -f "$plistPath" ]]; then
	echo "Plist File Found: Bootout"
	sudo launchctl bootout system "$plistPath"
	rm -rf $plistPath
else
	echo "Plist File not found"
fi

cat << EOF > $plistPath
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.punahou.inventorySNOW</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/bash</string>
		<string>/Library/Scripts/SystemProfilerInventoryUploadToSNOW.sh</string>
	</array>
	<key>RunAtLoad</key>
	<false/>
	<key>StartInterval</key>
	<integer>14400</integer>
    <key>StandardErrorPath</key>
    <string>/Library/Punahou/ApplicationsCheck.log</string>
</dict>
</plist>
EOF

chmod 644 $plistPath
chown root:wheel $plistPath
echo "LaunchDaemon created at $plistPath"
ls -l $plistPath
plutil -lint $plistPath

echo "Load LaunchDaemon"
/bin/launchctl load -w $plistPath
#tail -f /var/log/system.log