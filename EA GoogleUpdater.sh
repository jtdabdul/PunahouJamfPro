#!/bin/bash
if [ pgrep -fi "GoogleUpdater" > /dev/null ]; then
	echo "<result>Google Updater Process running</result>"
elif [ /bin/launchctl list | grep google.GoogleUpdater ]; then
	echo "<result>GoogleUpdater LaunchDaemon running</result>"
elif [ -f /Library/LaunchDaemons/com.google.GoogleUpdater.wake.system.plist ]; then
	echo "<result>GoogleUpdater LaunchDaemon file found</result>"
else
	echo "<result>Google Updater Not Found</result>"
fi
	
