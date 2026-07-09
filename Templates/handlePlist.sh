#!/bin/bash
# test script to try to introduce logic to handle_plist function
# we should only unload and delete the existing plist file if it does not match the heredoc or it doesn't exist
# if it matches the heredoc, we should ensure that the launchdaemon is running

LAUNCH_DAEMON_LABEL="com.punahou.inventorySNOW"	#no trailing ".plist"
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
			echo "Success: the plist matches the heredoc exactly"
			echo "validate launchdaemon is running"
			
			if sudo launchctl print system/"$LAUNCH_DAEMON_LABEL" > /dev/null 2>&1; then
				echo "launchdaemon is running"
			else
				echo "launchdaemon is not running.  loading plist"
				sudo launchctl bootstrap system "$plistPath"
			fi
			return 0
	else
		echo "heredoc does not match the existing plist file, or file doesn't exist"
	fi

	####Unload the PLIST
	if [[ -f "$plistPath" ]]; then
		echo "Plist File Found: Bootout"
		sudo launchctl bootout system "$plistPath"
		rm -rf $plistPath
	else
		echo "Plist File not found"
	fi
	#write the PLIST_CONTENT to the plistPath
	echo "$PLIST_CONTENT" > $plistPath
	
	chmod 644 $plistPath
	chown root:wheel $plistPath
	echo "LaunchDaemon created at $plistPath"
	ls -l $plistPath
	plutil -lint $plistPath
	
	echo "Load LaunchDaemon"
#	/bin/launchctl load -w $plistPath
	sudo /bin/launchctl bootstrap system "$plistPath"
}
handle_plist