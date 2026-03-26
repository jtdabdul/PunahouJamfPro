#!/bin/bash

# ==============================================================================
# ENVIRONMENT VARIABLES & CONFIGURATION
# ==============================================================================
# Identifiers
IDENTIFIER="com.punahou.jamfHealthCheck"
JAMF_DAEMON_TO_CHECK="com.jamfsoftware.task.1"

# Paths
SCRIPT_PATH="/Library/Scripts/jamfHealthCheck.sh"
PLIST_PATH="/Library/LaunchDaemons/${IDENTIFIER}.plist"
LOG_DIR="/Library/Punahou/logs"
LOG_FILE="${LOG_DIR}/jamfHealthCheck.log"
ERR_LOG="${LOG_DIR}/jamfHealthCheck_err.log"
LAST_RUN_FILE="${LOG_DIR}/JamfHealthCheck.last_run_time"

# Timing (in seconds)
DAEMON_START_INTERVAL=900 # 4 Hours (How often the LaunchDaemon wakes up)
RUN_INTERVAL=86400          # 24 Hours (Minimum time between execution of logic)

# ==============================================================================
# SCRIPT GENERATION
# ==============================================================================

### ToDo:
# Validate that the launchDaemon accurately launches the script on the specified interval before committing the code to github. - Done 3/17/2026
# fn killJamfIfRunningMoreThan1Day has internal logic that hardcodes 1 day threshold, which appears to be unneccessary since the main block doesn't call the function unless the KILL_THRESHOLD has been met.  Should the function duplicate the logic?  Or should it be simplified to simply kill the binary, and call the waitForJamfLaunch fn?  Should it continue to calculate the run time for logging purposes?  Or is that logic unneccessary?
# fn validateJamfDaemon - should it be generalized to check jamf health?  Are there other things I would like to validate?
# fn validateJamfDaemon - contains the remediation, should there be anothoer function for remediation - remediateJamf?  Should there be multiple validation functions that each contain a remediation, and run them in serial?  Should ther be a consolidated validation fn and a complete repair function instead? - fundamentally is there a benefit to surgical validation/repair or should validation fn check everything it is aware of, and should any repair run all repair steps we can think of?
# fn validateJamfDaemon looks for JAMF_DAEMON_TO_CHECK , which is currently "com.jamfsoftware.task.1".  Test run indicated that the task was not running, but the com.jamfsoftware.task.Every 15 Minutes task is.  Should this function handle an array and consider validation any one of the list of tasks?  Every15 Minutes is only the current configuration for our environmant.  If at any time in the future we set the check in interval to another value, then that will not be the task name.  is com.jamfsoftware.task.1 just the task running to ask the server what the interval is in the first place, and the interval named task runs after that?  Is there any way for us to ask Jamf what the check in interval is so that we can check for the correct task name?  Or should the validator read for any jamfsoftware task and check that an interval exists within the available Jamf server side check in interval options?  Only one plist seems ot exist - com.jamfsoftware.task.1, but the launchctl list shouws com.jamfsoftware.Every 15 Minutes.  Do some research into how this process is implemented.echo "Ensuring directory exists at $LOG_DIR..."
echo "Creating support directory at $LOG_DIR..."
mkdir -p "$LOG_DIR"

### Handle Script
echo "Removing old script if found..."
rm -f "$SCRIPT_PATH"

echo "Generating executable script at $SCRIPT_PATH..."

# Note: We do NOT quote "GATOR" so variables from this top-level script 
# (like $LOG_FILE) are "baked into" the heredoc. 
# Internal script variables (like \$DATE) are escaped with a backslash.
cat > "$SCRIPT_PATH" << GATOR
#!/bin/bash

# --- Paths & Config (Injected from Installer) ---
LOG_FILE="$LOG_FILE"
LAST_RUN_FILE="$LAST_RUN_FILE"
DAEMON_ID="$JAMF_DAEMON_TO_CHECK"
RUN_INTERVAL=$RUN_INTERVAL

log(){
    DATE=\$(date '+%Y-%m-%d %H:%M:%S')
    echo "\$DATE \$1" >> "\$LOG_FILE"
}

validateJamfDaemon() {
    if /bin/launchctl list | grep -q "\$DAEMON_ID"; then
        log "VALIDATE: Jamf LaunchDaemon (\$DAEMON_ID) is loaded."
    else
        log "WARNING: Jamf LaunchDaemon is NOT loaded. Running jamf manage..."
        /usr/local/bin/jamf manage
    fi
}

waitForJamfLaunch() {
    log "WAIT: Waiting for Jamf binary to relaunch..."
    local timeout=0
    # Wait up to 5 minutes (30 * 10s)
    while ! pgrep -f "jamf policy" > /dev/null; do
        sleep 10
        ((timeout++))
        if [ \$timeout -gt 30 ]; then
            log "ERROR: Jamf binary failed to relaunch after kill."
            return 1
        fi
    done
    log "SUCCESS: Jamf binary is back online (PID: \$(pgrep -f 'jamf policy'))."
}

killJamfIfRunningMoreThan1Day() {
    # Extract days from etime (format is [[dd-]hh:]mm:ss)
    processRuntime=\$(ps -ax -o etime,args | grep "jamf policy" | grep -v grep | awk '{print \$1}' | grep -o '.*[-]' | tr -d '-')
    processPID=\$(pgrep -f "jamf policy")

    if [ -z "\$processRuntime" ]; then
        log "STATUS: Jamf binary has not been running for more than 24 hours. No action taken."
    else
        log "CRITICAL: Jamf binary active for \$processRuntime days. PID: \$processPID"
        log "ACTION: Terminating hung Jamf process..."
        kill -9 "\$processPID"
        waitForJamfLaunch
    fi
}

# --- Execution Logic ---
CURRENT_TIME=\$(date +%s)
LAST_RUN_TIME=\$(cat "\$LAST_RUN_FILE" 2>/dev/null || echo 0)
TIME_DIFF=\$((CURRENT_TIME - LAST_RUN_TIME))

if (( TIME_DIFF < RUN_INTERVAL )); then
    log "INTERVAL: RUN_INTERVAL not met (\$TIME_DIFF/\$RUN_INTERVAL sec). Exiting."
    exit 0
else
    # Interval met, proceed with checks
    validateJamfDaemon
    killJamfIfRunningMoreThan1Day
    
    # Update the last run file
    echo "\$CURRENT_TIME" > "\$LAST_RUN_FILE"
fi

exit 0
GATOR

# Set Permissions
chmod 755 "$SCRIPT_PATH"
chown root:wheel "$SCRIPT_PATH"

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

echo "--------------------------------------------------"
echo "Setup Complete."
echo "Script Path:      $SCRIPT_PATH"
echo "LaunchDaemon:     $PLIST_PATH"
echo "Log Location:     $LOG_FILE"
echo "Run Interval:     $RUN_INTERVAL seconds"
echo "Check Interval:   $DAEMON_START_INTERVAL seconds"
echo "--------------------------------------------------"

exit 0