#!/bin/bash

###################
#Adapted from:
#https://www.jamf.com/jamf-nation/discussions/38046/webex-teams-package-for-self-service
#Posted: 2/9/2021 at 3:43 AM CST by mcrispin

#Modified on 2021/06/07 by JA - use parameters for values
#file="Webex.dmg"
#volname="Webex"
#appname="Webex.app"
#url='https://binaries.webex.com/WebexDesktop-MACOS-Apple-Silicon-Gold/Webex.dmg'

##### Parameters ######
file=$4
url=$5
appname=$6
volname=$7

##### functions #####################
handle_dmg () {
	### 2024/03/22 JA - add logic to detect volume name
	# Some vendors update the volume name with the version of their software, this enhancement would remove the need for the policy to be updated with volume name in script args as versions release
	# Step 1 - take the current objects in /Volumes into an array
	# Step 2 - Mount dmg
	# Step 3 - take the new objects in /Volumes into an array
	# Step 4 - compare arrays and find the target volume (exists in volumeNew and not in volumeInitial)
	# Step 5 - ditto the app in the new volume into /Applications
	
	#Step 1 - take the current objects in /Volumes into an array
	volumesInitial=(/Volumes/*)
	# Check if volumesInitial is empty
	if [ ${#volumesInitial[@]} -eq 0 ]; then
		echo "Error: volumesInitial is empty. ls -d /Volumes/* may not be returning any results."
		exit 1
	fi
	
	# Echo elements of array2
	echo "Elements of volumesInitial:"
	for element in "${volumesInitial[@]}"; do
		echo "$element"
	done
	#Step 2 - Mount dmg
	echo "Mounting installer disk image."
	/usr/bin/hdiutil attach /tmp/${file} -nobrowse -quiet
	if [ $? -eq 0 ]; then
		echo "Mount command successful"
	else
		echo "Mount command failed - download did not complete"
		exit 1
	fi
	# Step 3 - take the new objects in /Volumes into an array
	volumesNew=(/Volumes/*)
	if [ ${#volumesNew[@]} -eq 0 ]; then
		echo "Error: volumesNew is empty. ls -d /Volumes/* may not be returning any results."
		exit 1
	fi
	# Echo elements of volumesNew
	echo "Elements of volumesNew:"
	for element in "${volumesNew[@]}"; do
		echo "$element"
	done
	# Step 4 - compare arrays and find the target volume (exists in volumeNew and not in volumeInitial)
	echo "look for difference"
	element_in_array() {
		local e match=$1
		shift 
		for e; do [[ "$e" == "$match" ]] && return 0; done
		return 1
	}
	#iterate through Array
	for element in "${volumesNew[@]}"; do
		#check if element is not in array2
		if ! element_in_array "$element" "${volumesInitial[@]}"; then
			targetVolume=$element
		fi
	done
	echo "$targetVolume found"
	# Step 5 - ditto the app in the new volume into /Applications
	echo "Installing..."	
	/usr/bin/ditto -rsrc "$targetVolume/$appname" "/Applications/$appname"
	#added 3/22/24 by JA - exit with failure if ditto failed
	if [ $? -eq 0 ]; then
		echo "App copied successful"
	else
		echo "App copied failed - download did not complete, or volume name has changed"
		exit 1
	fi
	/bin/sleep 5
	
	echo "Unmounting installer disk image. ${targetVolume}"
#	/usr/bin/hdiutil detach "$(/bin/df | /usr/bin/grep "${targetVolume}" | awk '{print $1}')" -quiet
    device=$(/bin/df | /usr/bin/grep "${targetVolume}" | awk '{print $1}')
    if [ -n "$device" ]; then
      sudo /usr/bin/hdiutil detach "$device" || echo "Failed to detach $device"
    else
      echo "Volume not found"
    fi
    /bin/sleep 5	
}
#Modified on 2023/12/20 by JA - Include logic to handle pkg files as CURL target filetype
handle_pkg () {
	echo "Running installer package"
	/usr/sbin/installer -pkg /tmp/${file} -target /
	if [ $? -eq 0 ]; then
		echo "Install command successful"
	else
		echo "Install command failed - download did not complete"
		exit 1
	fi
}
removeQuarantineFlag() {
	#added as function on 2025/09/19 by JA
	#test for a value in $appname parameter, and only attempt to remove quarantine flag if $appname is provided
	echo "entered Remove Quarantine Flag function"
	if [ ! -z "$appname" ]; then
		echo "App name $appname provided, Remove Quarantine Flag"
		xattr -rc "/Applications/$appname"
		###
		/bin/sleep 5
	else
		echo "No App name parameter found, skip Remove Quarantine Flag"
	fi
}
cleanup () {
	echo "entered cleanup function"
	echo "Deleting downloaded file $file."
	/bin/rm /tmp/"${file}"
}
####### Main  ###############

## Get logged in user: Do I need this?
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

if [ -z "$loggedInUser" ] && [  "$loggedInUser" = "root" ] && [ "$loggedInUser" = "loginwindow" ]; then
	echo "Failed to gather loggedInUser correctly"
	exit 1
else
	echo "loggedInUser is $loggedInUser"
fi

### Curl $url to /tmp/$file
echo "--"
echo "Downloading latest version."
/usr/bin/curl -s -o /tmp/${file} ${url}
#detect file type for $file, handle dmg and pkg files differently
ext=${file##*.}
if [ $ext = "dmg" ]; then {
	echo "CURL target is dmg file"
	handle_dmg
} elif [ $ext = "pkg" ]; then {
	echo "CURL target is pkg file"
	handle_pkg
} else {
	echo "CURL target is not dmg or pkg"
	exit 1
}
fi
#added by JA on 2021/06/08 - try to get rid of the "App is downloaded from the internet" Warning
#modified by JA on 2025/09/19 - convert Remove Quarantine Flag steps into function, call function
removeQuarantineFlag
#modified by JA on 2025/09/19 - call cleanup function instead
cleanup
exit 0