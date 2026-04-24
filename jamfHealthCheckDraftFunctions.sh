#!/bin/zsh

# find last Update Inventory string in the jamf log
#lastInventory=$(grep "Executing Policy Update Inventory" /var/log/jamf.log | tail -n 1)
#get date/time (everything to the left of the second :)
function getJamfLogTimestamp() {
	#pass in the log line we want the time stamp from
	# jamf log file format starts each line with Date Time formatted "%a %b %d %H:%M:%S"
	#therefore cut everything left of the 4th <space> to get timestamp
	echo $(echo "$1" | cut -d' ' -f1,2,3,4)
}
function timestampEpochSeconds() {
	echo $(date -j -f "%a %b %d %H:%M:%S" "$1" "+%s")
}
function getLastTimeStampStringFromFile() {
	# jamf log file format starts each line with Date Time formatted "%a %b %d %H:%M:%S"
	#therefore cut everything left of the 4th <space> to get timestamp from last line matched by grep
	#return the date time in epoch seconds
	string=$1
	file=$2
	dateTimeFormatted=$(grep "$string" $file | tail -n 1 | cut -d' ' -f1,2,3,4)
#	echo "date time: $dateTimeFormatted"
	logLine=$(grep "$string" $file | tail -n 1)
	dateTimeFormatted=$(getJamfLogTimestamp "$logLine")
	
#	epochSeconds=$(date -j -f "%a %b %d %H:%M:%S" "$dateTimeFormatted" "+%s")
	epochSeconds=$(timestampEpochSeconds "$dateTimeFormatted")
	echo $epochSeconds
}
##Inventory test
echo "Inventory Test"
lastTimeStamp=$(getLastTimeStampStringFromFile "Executing Policy Update Inventory" /var/log/jamf.log)
nowSeconds=$(date +%s)
difference=$(($nowSeconds - $lastTimeStamp))
echo "difference seconds between found timestamp and now: $difference"
thresholdSeconds=$((60*60*24*7))	#1 week - 60 seconds *60 minutes * 24 hours *7 days

# testing: lower throeshold to 1 hour
#thresholdSeconds=$((60*60))	#1 week - 60 seconds *60 minutes * 24 hours *7 days

#echo "threshold seconds: $threshold"
if (( $difference > $thresholdSeconds )); then
	echo "too long"
else
	echo "last inventory less than $thresholdSeconds seconds ago: $difference"
fi
echo "-------------------------"
#Check in Test
echo "Check in test"
lastTimeStamp=$(getLastTimeStampStringFromFile "Checking for policies triggered by \"recurring check-in\"" /var/log/jamf.log)
difference=$(( $(date +%s) - $lastTimeStamp ))
thresholdSeconds=$((60*15))
if (( $difference > $thresholdSeconds )); then
	echo "too long: $difference > $thresholdSeconds"
else
	echo "last check-in less than $thresholdSeconds seconds ago: $difference"
fi
echo "--------------------------"
function lastInventoryOld() {
	findString="Executing Policy Update Inventory"
	logFile="/var/log/jamf.log"
	thresholdSeconds=$((60*60*24*7))	#1 week: 60 seconds * 60 minutes * 24 hours * 7 days
#	thresholdSeconds=$((60*60))	#1 week: 60 seconds * 60 minutes * 24 hours * 7 days
	lastTimeStamp=$(getLastTimeStampStringFromFile "$findString" $logFile)
	difference=$(( $(date +%s) - $lastTimeStamp ))
	if (( $difference > $thresholdSeconds )); then
		return 0	# true/Success - inventory is old
	else
		return 1	# false/Fail - inventory is current
	fi
}
	
#	findString="Executing Policy Update Inventory"
#	logFile="/var/log/jamf.log"
#	thresholdSeconds=$((60*60*24*7))	#1 week: 60 seconds * 60 minutes * 24 hours * 7 days
##	thresholdSeconds=$((60*60))	#1 week: 60 seconds * 60 minutes * 24 hours * 7 days
#	lastTimeStamp=$(getLastTimeStampStringFromFile "$findString" $logFile)
#	difference=$(( $(date +%s) - $lastTimeStamp ))
#	echo " is $difference > $thresholdSeconds?"
#	if (( $difference > $thresholdSeconds )); then
#		echo "true, $difference > $thresholdSeconds.  too old, run inventory"
#	else
#		echo "false, $difference not > $thresholdSeconds.  current, do nothing"
#	fi

	echo "test inventory function"
	if lastInventoryOld; then
		echo "last inventory old, run inventory"
	else
		echo "last inventory is current, do nothing"
	fi
