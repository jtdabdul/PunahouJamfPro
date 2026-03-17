#!/bin/bash
##Jamf Script General
#Display NameDisplay name for the script
#  Check for minimum Major (and optional minor) version and call a policy (optional) on requirements not met, call another (optional) policy on requirements met
#CategoryCategory to add the script to
#  Maintenance
#InformationInformation to display to the administrator when the script is run
#NotesNotes to display about the script (e.g., who created it and when it was created)
#Created 2025/02/25 by JA
#v1:hard coded application path, version major and minor.  hard coded action
#v2:accept parameters for application, major and optional minor version.  Accept optional parameters to run policy custom triggers for requirements met and requirements not met.
# 4: App Name (ex. Webex or Webex.app) for messaging only
# 5: App Path to Info.plist (ex. /Applications/Webex.app/Contents/Info.plist)
# 6: Major Version Required (ex. 45)
# 7: (optional) Minor Version Required (ex. 5, no value interpreted as 0)
# 8: (optional) Requirements Not Met Trigger (ex. InstallWebex)
# 9: (optional) Requirements Met Trigger (ex. StaticGroupRemoveXXX)
#############
pathToScript=$0
pathToPackage=$1
targetLocation=$2
targetVolume=$3

############################
###  Environment variables
############################
#app="Webex"
#appPath="/Applications/Webex.app/Contents/Info.plist"
#versionRequiredMajor=45
#versionRequiredMinor=5
#requirementsMetTrigger="InstallWebex"
#requirementsNotMetTrigger=""

############################
###  Handle Parameters
############################

#required App Name
[[ -n $4 ]] && [[ -z $app ]] && app=$4
[[ -z $app ]] && echo "Input parameter not found: App Name" && exit 1
#required App Path
[[ -n $5 ]] && [[ -z $appPath ]] && appPath=$5
[[ -z $appPath ]] && echo "Input parameter not found: App Path" && exit 1
#required Version Required Major
[[ -n $6 ]] && [[ -z $versionRequiredMajor ]] && versionRequiredMajor=$6
[[ -z $versionRequiredMajor ]] && echo "Input parameter not found: Version Required Major" && exit 1
#optional Version required Minor.  Default: 0
[[ -n $7 ]] && [[ -z $versionRequiredMinor ]] && versionRequiredMinor=$7
[[ -z $versionRequiredMinor ]] && versionRequiredMinor=0
#optional Requirements Not Met Trigger
[[ -n $8 ]] && [[ -z $requirementsNotMetTrigger ]] && requirementsNotMetTrigger=$8
#optional Requirements Met Trigger
[[ -n $9 ]] && [[ -z $requirementsMetTrigger ]] && requirementsMetTrigger=$9

############################
###  Main
############################
echo "App Name: $app"
echo "App Path: $appPath"
echo "Version Required Major: $versionRequiredMajor"
echo "Version Required Minor (optional default 0): $versionRequiredMinor"
echo "Requirement Not Met Trigger (optional): $requirementsNotMetTrigger"
echo "Requirement Met Trigger (optional): $requirementsMetTrigger"

if [ ! -f $appPath ]; then
	echo "$app not found. exiting"
	echo "Contents of /Applications directory:"
	ls /Applications/
	exit 1
fi
version=$(defaults read $appPath CFBundleShortVersionString)
echo "Current version: $version"
#parse version and compare to minimum
IFS='.' read -ra parts <<< "$version"
major=${parts[0]}
minor=${parts[1]}

echo "Installed Version Major: $major"
echo "Installed Version Minor: $minor"

# 1. Determine if Requirements are Met

if [[ $major -lt $versionRequiredMajor ]] || [[ $major -eq $versionRequiredMajor && $minor -lt $versionRequiredMinor ]]; then
	status="NotMet"
	trigger=$requirementsNotMetTrigger
	echo "Status: Version $versionRequiredMajor.${versionRequiredMinor:-0} or below detected. Requirements Not Met."
else
	status="Met"
	trigger=$requirementsMetTrigger
	echo "Status: Requirements Met."
fi

# 2. Execute Jamf Policy (Run once for either outcome)
if [[ -n $trigger ]]; then
	echo "Running policy trigger: $trigger"
	jamf policy -event "$trigger"
else
	echo "Requirements $status: No trigger provided, no action taken."
fi

exit 0