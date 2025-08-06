#!/bin/bash

# https://github.com/daveyboymath/Jamf/blob/MacOS/PassSecureToken.sh

# modified by JA on 1/5/23 for our environment
# The end user (who is not currently an admin) has a secure token
# The local admin user does not have secureToken
# modified to get rid of 'Jamf wants to ...' permission dialog on client device - use osascript -e instead of TELL APPLICATION syntax
# per https://community.jamf.com/t5/jamf-pro/quot-jamf-quot-wants-access-to-control-quot-system-events-quot/m-p/140815/highlight/true

# Workflow:
# 1 discover currently logged in username
#   todo: 1.5 test for secureToken status for that user - if not found exit with failure
# 2 prompt for currently logged in user's password
# 3 promote local user to admin
# 4 run sysadminctl command to pass securetoken from end user to local admin
# 5 check for success
# 6 demote currently logged in user back to standard whether successful or not - do not leave end user promoted

## To Do
## implement 1.5 above to cleanly exit without
## per Nolan suggestion: 3 tries to enter password? - DONE
## add logging to show secure token status for user and local admin both before and after execution - DONE
## add error checking for input parameters - DONE
## add logic to detect if current user is admin already - this should skip the promote and demote steps so that if we want faculty to run this, they retain membership in the admin group after the run

####  Implement before beta testing begins ####
## change success and failure messages to use jamfhelper instead. - DONE

## Per Matt (no title bar)
## Initial Prompt: Please make sure you back up your data first and quit any open applications - DONE
## password prompt: Please type in your Punahou Password to authorize the patch installation - DONE
## success prompt: The Patch has been successfully applied! - DONE
## failed prompt: Patch failed to install, please try again or contact the helpdesk. - DONE

###############################################
###  Handle Parameters
###############################################

#JSS_URL="https://punahou.jamfcloud.com"
####### JSS URL #####################
if [[ "$4" != "" ]] && [[ $adminUser == "" ]]; then
    adminUser=$4
fi
####### JJS Admin User ##############
if [[ "$5" != "" ]] && [[ $adminPassword == "" ]]; then
    adminPassword=$5
fi

####### Test for values
if [[ "$adminUser" == "" ]] || [[ "$adminPassword" == "" ]] ; then
    echo "Check parameter values - exiting with error"
    echo "adminUser : $adminUser"
    echo "adminPassword : $adminPassword"
    exit 1
fi
##############################################
###  Environment Variables
##############################################
salt=ecb239fd67940f87
passphrase=e021a9f3b71ad886d6febdfa

jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
icon="/Library/Punahou/256x256PunahouSeal-transparent.png"
successPrompt="The Patch has been successfully applied!"
failedPrompt="Patch failed to install, please try again or contact the helpdesk."
##############################################
###  Functions
##############################################
# Include DecryptString() with your script to decrypt the password sent by the JSS
# The 'Salt' and 'Passphrase' values would be present in the script
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    #handle Ventura or later
    echo "${1}" | /usr/bin/openssl enc -md md5 -aes256 -d -a -A -S "${2}" -k "${3}"
#   echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
}
# this function is not working - it returns FALSE even when TRUE
# function hasSecureToken() {
#     #usage foo=$(hasSecureToken "username")
#     status="ENABLED"  #desired status
#     output=$(sysadminctl -secureTokenStatus $1)
#  #   echo $output
#     if [[ $output =~ "ENABLED" ]]; then
#         echo TRUE
#     else
#         echo FALSE
#     fi
# }
function isAdmin() {
    #usage foo=$(isAdmin "username")
    if groups $1 | grep -q -w admin; then 
        echo TRUE; 
    else 
        echo FALSE; 
    fi 
}
function logUserStatus() {
    #pass in username
 #   echo "user $1 hasSecureToken $(hasSecureToken $1)"
    echo $(sysadminctl "-secureTokenStatus" $1)
    echo "user $1 is Admin $(isAdmin $1)"
}
function promoteUser() {
    #pass in $username
    userName=$1
    if [[ $(isAdmin $userName) == TRUE ]]; then
        echo "promote skipped - user is already admin"
        logUserStatus $userName
    else
        echo "Promote $userName"
        #Promote currently logged in user
        /usr/sbin/dseditgroup -o edit -a $userName -t user admin
        echo "log User status post-promote"
        logUserStatus $userName
    fi
}
function demoteUser() {
    #pass in $username and $alreadyAdmin
    userName=$1
    alreadyAdmin=$2
    if [[ $alreadyAdmin == TRUE ]]; then
        echo "skip demote - user was already admin before the run"
    else
        dseditgroup -o edit -d $userName -t user -L admin
        echo "demote $userName, log both users status"
        logUserStatus $userName
        logUserStatus $adminUser
    fi
}
##############################################
###  Main 
##############################################


#######################
###Admin credentials###
#######################
adminUser=$4
#update to encrypt the password in input variable, add salt and passphrase along with DecryptString function
#adminPassword=$5
adminPassword=$(DecryptString "$5" "$salt" "$passphrase")
#echo "$adminUser : $adminPassword"
#####
# 1 #
#####
##############################################################
###This will store the logged in user's name to a variable.###
##############################################################
#python deprecated
echo "get currently logged in user"
#userName=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
userName=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
#log user status prior to execution
logUserStatus $userName
#determine if user is already admin at the start of this run (for use later to pass in to demote function)
alreadyAdmin=$(isAdmin $userName)
echo "Currently Logged in user admin initial state: $alreadyAdmin"
#display Initial Prompt
#"$jamfHelper" -windowType "utility" -icon $icon -title "Patch Install" -description "Please make sure you back up your data first and quit any open applications" -button1 "OK"
"$jamfHelper" -windowType "utility" -icon $icon -description "Please make sure you back up your data first and quit any open applications" -button1 "OK"

#wrap this in a loop that allows the user to try 3 times
for ((i=0; i<3; i++)); do
    echo "attempt to collect password: $i"
    if [ $i == 0 ]; then
        #####
        # 2 #
        #####
        ##############################################################################
        ###This will prompt the user for their password and store it in a variable.###
        ##############################################################################
        # userPassword=$(osascript -e '
        # tell application "Finder"
        #    display dialog "Please enter your Computer password." with hidden answer default answer ""
        #    set userPassword to the (text returned of the result)
        # end tell')
        userPassword=$(/usr/bin/osascript -e 'set the answer to text returned of (display dialog "Please type in your Punahou Password to authorize the patch installation:" default answer "" with hidden answer buttons {"Continue"} default button 1)')
    else
        userPassword=$(/usr/bin/osascript -e 'set the answer to text returned of (display dialog "Password was incorrect. Please re-type in your Punahou Password to authorize the patch installation:" default answer "" with hidden answer buttons {"Continue"} default button 1)')
    fi
    #####
    # 3 #
    #####
    # echo "Promote $userName"
    # #Promote currently logged in user
    # /usr/sbin/dseditgroup -o edit -a $userName -t user admin
    # echo "log User status post-promote"
    # logUserStatus $userName
    #call promote function instead
    promoteUser $userName
    #debug only
    #    echo "sysadminctl -adminUser "$userName" -adminPassword "$userPassword" -secureTokenOn $adminUser -password $adminPassword"

    #####
    # 4 #
    #####
    #####################################################################################################
    ###Store the output of the sysadminctl command into a variable to use it for error handling later.###
    #####################################################################################################
    logUserStatus $adminUser
    output=$(sudo sysadminctl -adminUser "$userName" -adminPassword "$userPassword" -secureTokenOn $adminUser -password $adminPassword 2>&1)

    #debug only
    echo "output: $output"
    ######################################################################################################
    ###Error handling to see if the password entered is the same password used to log into the machine.###
    ######################################################################################################

    #####
    # 5 #
    #####
    ##########################################################################################
    ###Searches for the output "Done". If this exist then the sysadminctl command will run.###
    ##########################################################################################
    if [[ $output == *"Done"* ]]; then
        echo "Success!"
        ############################################################################################################################
        ###Command used to provide the user a secureToken. The admin user must have a secure token or this command will not work.###
        ###You can always check the JAMF policy logs to see if the user is experiencing an issue.###################################
        ############################################################################################################################
        #sysadminctl -adminUser "$adminUser" -adminPassword "$adminPassword" -secureTokenOn $userName -password $userPassword
        sysadminctl -adminUser "$userName" -adminPassword "$userPassword" -secureTokenOn $adminUser -password $adminPassword
        echo "log both users status after attempt to pass token"
        logUserStatus $userName
        logUserStatus $adminUser
        #debug only
        #echo "sysadminctl -adminUser "$userName" -adminPassword "$userPassword" -secureTokenOn $adminUser -password $adminPassword"
        ##############################
        ###GUI dialog for the user.###
        ##############################
        #title='MacOS FileVault Encryption'
        #osascript -e "display dialog \"Your password has been successfully synced with FileVault!\" buttons {\"OK\"} default button \"OK\" with title \"$title\""
        "$jamfHelper" -windowType "utility" -icon $icon -description "$successPrompt" -button1 "OK"
        #####
        # 6 #
        #####
        #demote user if successful - do not leave the end user promoted
        # dseditgroup -o edit -d $userName -t user -L admin
        # echo "demote $userName, log both users status"
        # logUserStatus $userName
        # logUserStatus $adminUser
        #try demote function instead
        demoteUser $userName $alreadyAdmin
        exit 0
    elif [[ $i == 2 ]]; then
        echo "3 attempts have failed: disply failed prompt"
        ##############################
        ###GUI dialog for the user.###
        ##############################
        #title='MacOS FileVault Encryption'
        #osascript -e "display dialog \"The password entered did not match your password on this computer! Please quit and re-run the Self-Service policy to try again.\" buttons {\"Quit (Your password was not synced!)\"} default button \"Quit (Your password was not synced!)\" with title \"$title\""
        "$jamfHelper" -windowType "utility" -icon $icon -description "$failedPrompt" -button1 "OK"
        #####
        # 6 #
        #####
        #demote user if unsuccessful also - do not leave the end user promoted
        # dseditgroup -o edit -d $userName -t user -L admin
        # echo "demote $userName, log both users status"
        # logUserStatus $userName
        # logUserStatus $adminUser
        demoteUser $userName $alreadyAdmin

    exit 1
    fi
done
exit 0
####### Jamf Script object
### General
# Display NameDisplay name for the script
# Pass Secure Token to Local Admin (2025 hala password)
# CategoryCategory to add the script to
# Helpdesk Tools
# InformationInformation to display to the administrator when the script is run
# NotesNotes to display about the script (e.g., who created it and when it was created)
# adapted from https://github.com/daveyboymath/Jamf/blob/MacOS/PassSecureToken.sh on 1/5/2023 by JA
# original script needed to be adapted to our environment conditions - standard user has token, admin user does not
# modified on 1/9/23 by JA - update prompts per MA content, use JamfHelper.  Add error checking for parameters and log user status.  Wrap in loop to allow 3 attempts to enter password.
# modified on 2023/01/18 by JA add arguments to openssl command in decryptString to handle Ventura
# modified on 2024/03/06 by NH to reflect new hala 2024 password
# created new Pass Secure Token to Local Admin (2025 hala passsword) from Pass Secure Token to Local Admin (2024 hala passsword) to reflect new hala 2025 password on 2025/08/06 by AM
### Options
# PriorityPriority to use for running the script in relation to other actions
# After
# Parameter LabelsLabels to use for script parameters. Parameters 1 through 3 are predefined as mount point, computer name, and username
# Parameter 4
# Local Admin Username
# Parameter 5
# Local Admin Password encrypted
####### End Jamf script object
