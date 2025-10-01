#!/bin/bash

storage_available_gigabytes=$(osascript -l 'JavaScript' -e "ObjC.import('Foundation'); var freeSpaceBytesRef=Ref(); $.NSURL.fileURLWithPath('/').getResourceValueForKeyError(freeSpaceBytesRef, 'NSURLVolumeAvailableCapacityForImportantUsageKey', null); Math.round(ObjC.unwrap(freeSpaceBytesRef[0]) / 1000000000)")

if [[ $storage_available_gigabytes =~ ^[0-9]+$ ]] ; then
	echo "<result>$storage_available_gigabytes</result>"
fi