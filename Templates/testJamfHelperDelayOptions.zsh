#!/bin/zsh
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
LOCAL_LOG_FILE="/var/log/testingJamfhelperDelay.log"
icon="/Library/Punahou/256x256PunahouSeal-transparent.png"	# Path to icon to use in jamfHelper windows  
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
LogDateFormat="%Y-%m-%d %H:%M:%S"
starttime=$(strftime "$LogDateFormat")

RESPONSE=$($jamfHelper -windowType utility -icon $icon -title "Punahou School" -heading "Super Important" -description "Please make a selection" -button1 "Restart Now" -button2 "Defer" -defaultButton 2 -showDelayOptions "900, 3600, 14400, 86400" -timeout "60" -countdown)
#jamfhelper defer options return the delay time followed by 1 (for clicking the OK button/button 1) ex: 0 returns 1, 900 returns 9001, 3600 returns 36001, etc. Button 2 appends a 2 on the DelayOptions selected value
#in order to have the timeout behavior default to the shorted delay, and ensure timeout does not result in restart now, defaultButton set to button 2

log "User chose $RESPONSE"
log "get rightmost digit from RESPONSE - JamfHelper stores which button was used in the rightmost digit if delayOptions are used"
BUTTON=$(( $RESPONSE % 10 ))
log "button $BUTTON was pressed, 1:button 1 (restart now); 2:button 2 (Defer/Delay)"

### working here
if [[ $BUTTON == 1 ]]; then
	log "User chose to restart now, ignore delayOptions value and restart now"
	#do I have to put the daily launchdaemon back here?  put back if not found? 
	#shutdown -r now
else #BUTTON 2 was used or timeout was reached
	log "User clicked button 2 (Defer/Delay), or timeout has occurred"
	SECONDS_TO_WAIT=$(echo "$RESPONSE" | /usr/bin/sed 's/.$//')
	log "Get SECONDS_TO_WAIT from RESPONSE: $SECONDS_TO_WAIT"
	log "user chose to defer for $SECONDS_TO_WAIT seconds, set up launchdaemon to wake up after $SECONDS_TO_WAIT"
	# Disable the daily check so it doesn't fire while we are in a deferral loop
	log "disable Daily launchdaemon $DAILY_LABEL"
	#launchctl unload "$DAILY_PLIST" 2>/dev/null
	#remove_daemon "$DAILY_LABEL" "$DAILY_PLIST"
	# Write the deferral daemon to fire once the time expires
	log "write launchdaemon $DEFER_LABEL to launch in $SECONDS_TO_WAIT and exit"
	#write_daemon "$DEFER_LABEL" "$DEFER_PLIST" "$SECONDS_TO_WAIT"
	exit 0
fi