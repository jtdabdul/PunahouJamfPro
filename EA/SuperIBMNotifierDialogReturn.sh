#!/bin/bash
logfile="/Library/Management/super/logs/super.log"
#logfile="/Users/jabdul/Documents/sampleSuper.log"
#logfile="/Users/jabdul/Documents/Super.log"

getLargest() {
	#if the log contains multiple dialog_return values, keep only the largest value
	echo "$(printf '%s\n' "$1" | awk '$1 > max {max = $1} END {print max}')"
}
getFirst() {
	echo "$1" | head -n 1
}
getLast() {
	echo "$1" | tail -n 1
}
#if no log file is found, return empty result
if [ ! -f $logfile ]; then
	echo "<result></result>"
	exit 0
fi
#get all return codes by matching the dialog_result string, then filter out known non-error codes with grep
result=$(tail -n 300 $logfile | awk -F'dialog_return is: ' '/dialog_return is:/ {print $2}' | grep -Ev '^(0|2|3|4|200)$')

#if there is more than one hit on the 'dialog return is:' string - we will get multiple values back from awk.
#we only want one integer for the result

#largest=$(getLargest "$result") #return largest value?
#echo "largest $largest"
#first=$(getFirst "$result") #return first
#echo "first $first"
#last=$(getLast "$result") #return last
#echo "last $last"

result=$(getLast "$result") #if there is more than one, return the last

[[ -z $result ]] && result=0 #if the function returns nothing, then result set to 0, a non-error state.
echo "<result>$result</result>"
exit 0