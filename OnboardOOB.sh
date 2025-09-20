#!/bin/bash
### Jamf Script General
# Display NameDisplay name for the script
# Onboard
# CategoryCategory to add the script to
# None
# InformationInformation to display to the administrator when the script is run
# NotesNotes to display about the script (e.g., who created it and when it was created)
# Created on 2020/10/4 by JA
# Adapted from JNUC Rocketman-Tech https://github.com/Rocketman-Tech/Onboarding-With-DEPNotify/blob/master/onboarding.sh
# Modified on 2024/07/15 by JA - Add custom event trigger for Sophos to add it to the end of the workflow
# Modified on 2024/08/08 by JA - Add custom event trigger for Arctic Wolf to install after Sophos

####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#	onboarding.sh -- Configure computer to Company Standards
#
# SYNOPSIS
#	sudo onboarding.sh
#	sudo onboarding.sh <mountPoint> <computerName> <currentUsername>
#
# DESCRIPTION
#	
#	This script drives the onboarding workflow, utilizing DEPNotify and pre-configured polices
#	to create a zero-touch deployment solution.
#
# USAGE
#
#	1. Upload this script into your Jamf Pro Server
#	2. Edit the "Configuration" section below
#	3. Add your own specific updates and policy calls in the section marked
#		"YOUR STUFF GOES HERE"
#	4. Call this script with a policy using the "Enrollment Complete" trigger
#
####################################################################################################
#
# HISTORY
#
#
#	Version 2.0
#	- Updated by Chad Lawson on 7/1/2020
#	- Broke blocks out into functions and stripped on non-universal work into other scripts
#
#	Version: 1.0
#
#	- Created by Chad Lawson on January 4th, 2019
#	- Based on work by 'franton' on MacAdmins Slack.
#		Posted on #depnotify on 12/31/18 @ 11:23am
#
#
#
####################################################################################################
#
# TODO
#
# LOTS more error checking is required!
#
####################################################################################################


##               ###
## Configuration ###
##               ###
LOGOFILE="/Library/Punahou/512x512PunahouSeal.png"
WINDOWTITLE="Punahou School Provisioning"
MAINTITLE="Welcome to Punahou School"

function coffee {
	
	## Disable sleep for duration of run
	/usr/bin/caffeinate -d -i -m -u &
	caffeinatepid=$!	
}

function pauseJamfFramework {
	
	## Update Jamf frameworks
	/usr/local/bin/jamf manage

	## Disable Jamf Check-Ins
	jamftasks=($( find /Library/LaunchDaemons -iname "*task*" -type f -maxdepth 1 ))
	for ((i=0;i<${#jamftasks[@]};i++))
	do
		/bin/launchctl unload -w "${jamftasks[$i]}"
	done

	## Kill any check-in in progress
	jamfpid=$( ps -ax | grep "jamf policy -randomDelaySeconds" | grep -v "grep" | awk '{ print $1 }' )
	if [ "$jamfpid" != "" ];
	then
		kill -9 "$jamfpid"
	fi	
}

function waitForUser {
	
	## Check to see if we're in a user context or not. Wait if not.
	dockStatus=$( /usr/bin/pgrep -x Dock )
	while [[ "$dockStatus" == "" ]]; do
		sleep 1
		dockStatus=$( /usr/bin/pgrep -x Dock )
	done

	## Get the current user?
	currentuser=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )
	userid=$( /usr/bin/id -u $currentuser )	
}

function startDEPNotify {	
	
	## Create the depnotify log file
	/usr/bin/touch /var/tmp/depnotify.log
	/bin/chmod 777 /var/tmp/depnotify.log

	## Set up the initial DEP Notify window
	/bin/echo "Command: Image: ${LOGOFILE}" >> /var/tmp/depnotify.log
	/bin/echo "Command: WindowTitle: ${WINDOWTITLE}" >> /var/tmp/depnotify.log
	/bin/echo "Command: MainTitle: ${MAINTITLE}" >> /var/tmp/depnotify.log

	## Load DEP Notify
	deploc=$( /usr/bin/find /Applications -maxdepth 2 -type d -iname "*DEP*.app" )
	/bin/launchctl asuser $userid "$deploc/Contents/MacOS/DEPNotify" 2>/dev/null &
	deppid=$!	
}

function cleanUp {
	
	## Re-enable Jamf management
	for ((i=0;i<${#jamftasks[@]};i++))
	do
		/bin/launchctl load -w "${jamftasks[$i]}"
	done
	
	## Quit DEPNotify
	/bin/echo "Command: Quit" >> /var/tmp/depnotify.log
	/bin/rm -rf "$deploc" ## Deletes the DEPNotify.app

	## Delete temp files
	/bin/rm /var/tmp/depnotify.log
	/usr/bin/defaults delete menu.nomad.DEPNotify
	
	## Disable Caffeine
	/bin/kill "$caffeinatepid"	
}

function DEPNotify {
	
	local NotifyCommand=$1
	/bin/echo "$NotifyCommand" >> /var/tmp/depnotify.log
}

function jamfCommand {
	
	local jamfTrigger=$1
	
	if [[ $jamfTrigger == "recon" ]]; then
		/usr/local/bin/jamf recon
	elif [[ $jamfTrigger == "policy" ]]; then
		/usr/local/bin/jamf policy
	else 
		/usr/local/bin/jamf policy -event $jamfTrigger
	fi
}

###		###
### Main Script	###
###		###

## These next four lines execute functions above
coffee				## Uses 'caffeinate' to disable sleep and stores the PID for later
pauseJamfFramework 		## Disables recurring Jamf check-ins to prevent overlaps
waitForUser 			## Blocking loop; Waits until DEP is complete and user is logged in
startDEPNotify 			## Initial setup and execution of DEPNotify as user

###                      ###
### YOUR STUFF GOES HERE ###
###                      ###

## NOTES:
##	There are two functions to help simplify your DEPNotify commands and
##		calls to Jamf for other policies.
##
##	1. DEPNotify - Appends text to /var/tmp/depnotify.log
##		Ex. DEPNotify "Command: MainText: Message goes here"
##			DEPNotify "Status: Tell the user what we are doing..."
##
##	2. jamfCommand - Simplifies calls to the jamf binary with three options
##		'recon' 	- Submits an inventory to udpate Smart Groups, etc.
##		'policy' 	- Makes a normal policy check for new applicable policies
##		other 		- Calls jamf policy with the passed in argument as a manual trigger
##			Ex. "jamfCommand renameComputer" - executes "/usr/local/bin/jamf policy -trigger renameComputer"

## Machine Configuration
DEPNotify "Command: Image: ${LOGOFILE}"
DEPNotify "Command: MainText: Configuring Machine."
DEPNotify "Status: Setting Computer Name"
jamfCommand configureComputer
jamfCommand createERD
jamfCommand installJamfRestart
jamfCommand installInventorySNOW

## Installers required for every Mac - Runs policies with 'deploy' manual trigger
DEPNotify "Status: Add Printer support"
DEPNotify "Command: MainText: Starting software deployment."
#jamfCommand deploy
jamfCommand InstallUniflowDrivers
jamfCOmmand uniflowDefaultPrinterOptions
jamfCommand installCanonMacSecurePrint
sleep 3

## Add Departmental Apps - Run polices with "installDepartmentalApps" manual and scoped to departments
DEPNotify "Command: MainText: Adding Base Components."
DEPNotify "Status: Adding Base Applications."
jamfCommand installChrome

sleep 1
#jamfCommand installDepartmentalApps
#jamfCommand policy

# ## Send updated inventory for Smart Groups and check for any remaining scoped policies
# DEPNotify "Command: MainText: Final install checks."
# DEPNotify "Status: Update inventory record."
# jamfCommand recon 
# sleep 1
# DEPNotify "Status: Final policy check."
# jamfCommand policy
# #added 2020/10/28 by JA - Technicians reported that a device had policies waiting after Onboard completion when they ran recon and policy manually
# DEPNotify "Status: Final policy double check."
# jamfCommand recon
# sleep 1
# jamfCommand policy
# #added 2021/01/27 by JA - Technicians observed that a dock icon was missing, and appeared after force check in.  Adding one more round of inventory and policy to the process
# sleep 1
# jamfCommand recon
# sleep 1
# jamfCommand policy
#added 2021/07/09 by JA - attempt to apply softwareupdate to computers in scope, computers out of scope for this policy should not execute on the trigger
#commented out 2021/07/16 by JA because software update needs a password provided to run on M1 devices, which is what this was for.  May uncomment if we implement an API script to kick of OS update
#DEPNotify "Status: Check for available patches"
#jamfCommand softwareupdateInstallAll

#####
#modified on 2021/07/19 by JA - add custom trigger to call securly proxy script.  Scoped to M1, Limited to LDAP Students/mdm_Student/mdm_SummerStudent
#moved to end of the onboarding process on 2021/07/21.  Issues with connectivity to jamf distribution point from 10.5.16.x and 10.8.x.x 
#workaround:  delay application of the securly proxy until the payload is complete and the end user will use their wifi cred to connect to an unaffected network.  
#Currently assuming 10.3.x.x is not affected, as student wifi does not seem to be affected by issue.
DEPNotify "Status: Proxy Settings check."
jamfCommand SecurlyProxyScript

#added 2024/07/15 by JA - call Sophos explicitly via event trigger to ensure that it runs at the end of the onboarding process.  An attempt to resolve an internet conectivity issue 
DEPNotify "Status: Antivirus install"
jamfCommand InterceptX
#added 2024/08/08 by JA - call Arctic Wolf explicitly via event trigger to ensure that it runs after Sophos installation.  Sophos support identified a connectivity issue as Sophos briefly takes the device offline at the end of it's installation, and Arctic Wolf traffic is identified as interfering with the re-connect step.  Arctic Wolf to be installed after Sophos installation complete
DEPNotify "Status: Arctic Wolf install"
jamfCommand ArcticWolf

# Submit inventory
jamfCommand recon

#added 2020/10/05 by JA - attempt to put a button on the splash screen which needs to be clicked to close DEPNotify
DEPNotify "Command: MainText: Configuration Complete!"
DEPNotify "Status: Complete"
#DEPNotify "Command: ContinueButton: Get Started"

#added 2020/10/05 by JA attempt to leave behind a prompt
JamfHelper='/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper'
#"$JamfHelper" -windowType hud -title "Deployment Complete" -heading "Deployment complete." -alignHeading left -description "Click OK to close the Deployment window" -icon /System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/keychain.tiff -button1 "OK"
"$JamfHelper" -windowType hud \
	-title "Deployment Complete" \
    -heading "Deployment complete." \
    -description "Click OK to close the Deployment window" \
    -icon "$LOGOFILE" \
    -button1 "OK"

###         ###     
### Cleanup ###
###         ###     
cleanUp ## Quits application, deletes temporary files, and resumes normal operation

# Run "Provisioning - payload audit" Policy
jamf policy -event PayloadAudit