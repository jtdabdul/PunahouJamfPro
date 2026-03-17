#!/bin/bash

plistPath="/Library/LaunchDaemons/com.punahou.jamfHealthCheck.plist"
scriptPath="/Library/Scripts/jamfHealthCheck.sh"

### Handle Script
echo "Removing old script if found..."
rm -f "$scriptPath"

### Create the script
cat > "$scriptPath" << "GATOR"
#!/bin/bash

# Log file setup
logLocation="/Library/Punahou/jamfHealthCheck.log"
mkdir -p "/Library/Punahou" # Ensure directory exists

log(){
	DATE=$(date '+%Y-%m-%d %H:%M:%S')
	echo "$DATE $1" >> "$logLocation"
}

validateJamfDaemon() {
	# Check if the Jamf LaunchDaemon is actually loaded in the system domain
	if launchctl list | grep -q "com.jamfsoftware.task.1"; then
		log "SUCCESS: Jamf LaunchDaemon (task.1) is loaded."
	else
		log "WARNING: Jamf LaunchDaemon is NOT loaded. Attempting to force check-in..."
		# Optional: try to kickstart jamf if the daemon is missing
		/usr/local/bin/jamf manage
	fi
}

waitForJamfLaunch() {
	log "Waiting for Jamf binary to relaunch..."
	local timeout=0
	# Wait up to 5 minutes (30 * 10 seconds)
	while ! pgrep -f "jamf policy" > /dev/null; do
		sleep 10
		((timeout++))
		if [ $timeout -gt 30 ]; then
			log "TIMEOUT: Jamf binary did not relaunch within 5 minutes."
			return 1
		fi
	done
	newPID=$(pgrep -f "jamf policy")
	log "SUCCESS: Jamf binary is running again (PID: $newPID)."
}

killJamfIfRunningMoreThan1Day() {
	# Get runtime in days and the PID
	processRuntime=$(ps -ax -o etime,args | grep "jamf policy" | grep -v grep | awk '{print $1}' | grep -o '.*[-]' | tr -d '-')
	processCheck=$(pgrep -f "jamf policy")

	if [ -z "${processRuntime}" ]; then
		log "Jamf binary has not been running for more than 24 hours."
	else
		log "CRITICAL: Jamf binary has run for ${processRuntime} days. PID: ${processCheck}"
		log "Action: Killing Jamf process..."
		kill -9 "${processCheck}"
		
		# New Requirement: Wait for relaunch
		waitForJamfLaunch
	fi
}

# Main Execution
validateJamfDaemon

LAST_RUN_FILE="/Library/Punahou/JamfHealthCheck.last_run_time"
CURRENT_TIME=$(date +%s)
LAST_RUN_TIME=$(cat "$LAST_RUN_FILE" 2>/dev/null || echo 0)
TIME_DIFF=$((CURRENT_TIME - LAST_RUN_TIME))

if ((TIME_DIFF >= 86400)); then
	killJamfIfRunningMoreThan1Day
	echo "$CURRENT_TIME" > "$LAST_RUN_FILE"
else
	log "Interval check: Less than 24 hours since last run. Skipping kill check."
fi

exit 0
GATOR

# Set file permissions
chmod 755 "$scriptPath"
chown root:wheel "$scriptPath"

### Handle Plist
if [[ -f "$plistPath" ]]; then
	sudo launchctl bootout system "$plistPath" 2>/dev/null
	rm -f "$plistPath"
fi

cat > "$plistPath" << SWAMP
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.punahou.jamfHealthCheck</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/bash</string>
		<string>$scriptPath</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StartInterval</key>
	<integer>14400</integer>
	<key>StandardErrorPath</key>
	<string>/Library/Punahou/jamfHealthCheck_err.log</string>
</dict>
</plist>
SWAMP

chmod 644 "$plistPath"
chown root:wheel "$plistPath"
sudo launchctl bootstrap system "$plistPath"

echo "Process Complete. Monitoring script installed."
exit 0