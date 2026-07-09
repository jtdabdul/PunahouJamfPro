#!/bin/bash


# ==============================================================================
# ENVIRONMENT VARIABLES & CONFIGURATION
# ==============================================================================
# Identifiers
IDENTIFIER="com.punahou.jamfHealthCheck"
JAMF_DAEMON_TO_CHECK="com.jamfsoftware.task.Every 15 Minutes"

# Paths
SCRIPT_PATH="/Library/Scripts/jamfHealthCheck.sh"
PLIST_PATH="/Library/LaunchDaemons/${IDENTIFIER}.plist"
LOG_DIR="/Library/Punahou/logs"
LOG_FILE="${LOG_DIR}/jamfHealthCheck.log"
ERR_LOG="${LOG_DIR}/jamfHealthCheck_err.log"
LAST_RUN_FILE="${LOG_DIR}/JamfHealthCheck.last_run_time"

# Timing (in seconds)
DAEMON_START_INTERVAL=900 # 4 Hours (How often the LaunchDaemon wakes up)
RUN_INTERVAL=3600   #86400          # 24 Hours (Minimum time between execution of logic)

workflow_installation() {
	#create folders if missing
	[[ ! -d "${WORKING_FOLDER}" ]] && mkdir -p "${WORKING_FOLDER}"
	### copied from super - modify for our purposes
	log_super_audit "Installation: Copying super ${SUPER_VERSION} to ${SUPER_FOLDER}/super."
	cp "$0" "${WORKING_FOLDER}/super" >/dev/null 2>&1
	if [[ ! -d "/usr/local/bin" ]]; then
		log_super "Installation: Creating local search path folder: /usr/local/bin"
		mkdir -p "/usr/local/bin"
		chmod -R a+rx "/usr/local/bin"
	fi
}

createLaunchDaemon() {
# ==============================================================================
# LAUNCHDAEMON GENERATION
# ==============================================================================
	echo "Generating LaunchDaemon at $PLIST_PATH..."

	# Unload if exists
	if [[ -f "$PLIST_PATH" ]]; then
	    sudo launchctl bootout system "$PLIST_PATH" 2>/dev/null
	    rm -f "$PLIST_PATH"
	fi

	cat > "$PLIST_PATH" << SWAMP
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>$IDENTIFIER</string>
		<key>ProgramArguments</key>
		<array>
			<string>time</string>
			<string>/bin/bash</string>
			<string>$SCRIPT_PATH</string>
		</array>
		<key>RunAtLoad</key>
		<true/>
		<key>StartInterval</key>
		<integer>$DAEMON_START_INTERVAL</integer>
		<key>StandardErrorPath</key>
		<string>$ERR_LOG</string>
		<key>StandardOutPath</key>
		<string>$LOG_FILE</string>
	</dict>
	</plist>
	SWAMP

	chmod 644 "$PLIST_PATH"
	chown root:wheel "$PLIST_PATH"

	# Load the new Daemon
	sudo launchctl bootstrap system "$PLIST_PATH"
}