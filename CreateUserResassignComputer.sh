#!/bin/bash 
#Display NameDisplay name for the script
# CreateAndAssignUser optional prepend
# CategoryCategory to add the script to
# Helpdesk Tools
# InformationInformation to display to the administrator when the script is run
# NotesNotes to display about the script (e.g., who created it and when it was created)
# created on 7/20/23 by JA
# put together Assign Computer API Bearer Token optional rename script and Pass Secure Token script, added create user function
# modified 7/21/23 by JA parameters 10 and 11 not passing values properly to the script, removing rename and prompt values from parameters.  use case assumes true.  local username and password (encrypted values to be moved into parameters 7 and 8.
# PriorityPriority to use for running the script in relation to other actions
# After
# Parameter LabelsLabels to use for script parameters. Parameters 1 through 3 are predefined as mount point, computer name, and username
# Parameter 4
# JSS_URL
# Parameter 5
# API username
# Parameter 6
# API Password encrypted
# Parameter 7
# token Holder Username
# Parameter 8
# token Holder Password (encrypted)
# Parameter 9
# Rename Prepend (optional) ex: loaner or LT-loaner
#
####################################################################################################
#
# Copyright (c) 2016, JAMF Software, LLC.  All rights reserved.
#
#       This script was written by JAMF Software
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#####################################################################################################
#
# SUPPORT FOR THIS PROGRAM
#
#       This program is distributed "as is" by JAMF Software. For more information or
#       support for this script, please contact your JAMF Software Account Manager.
#
#####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#   
#   RenameComputerAPIBearerToken.sh
#
# SYNOPSIS - How to use
#   
#   Add this script to Jamf so we can use it within a policy.  Please modify the variables below under
#   the JSS Variables section.  Once those steps are completed, please create a policy and add this script
#   using the script payload.  Scope the policy to the computers we wish to upload logs for.
# 
# DESCRIPTION
#   
#   This script will prompt the user via osascript to collect a username.  Script will then attempt to
#       look up that username in primary (1) LDAP server.  If the user exists, then proceed to rename the
#       computer (HostName, LocalHostName and ComputerName) to that LDAP username, then assign via jamf binary
#       recon -endUsername.  If the user is not found, retry prompt until 3 attemps have failed. User account
#       will be created on device and given secure token, loaner user will be deleted.
#       !!! Policy should not be run while logged in as loaner user.
# 
####################################################################################################
#
# HISTORY
#
#   Version: 1.0 by Lucas Vance @ JAMF Software 11-4-16
#       Adapted to use Bearer token infrastructure from this Jamf script, then apply main block from 
#       LDAPLookup script which was adapted from Migrated User assign script authored my Matthew Mitchell 
#   Modified on 12/28/2022 by Jason Abdul to update API Authenticationt to Bearer Token
#   Modified on 1/10/2023 by Jason Abdul to use branch logic and parameters to generalize the script as described below
#   Modified on 1/18/2023 by Jason Abdul to add args to openssl command in decryptString to handle Ventura requirements
#   Modified on 7/25/2023 by Jason Abdul to handle creating a user (by input) to assign device to, and remove loaner user from computer
#
####################################################################################################
####################################################################################################

#ToDo
# localhostname does not handle _ character properly and simply fails - I can catch and strip out the underscore to prevent the error and get a localhostname assigned to the computer.  as is the localhostname will not update at all

user="" # API account name
pass="" # Password for API account
#url="https://punahou.jamfcloud.com" # JPS URL including port, please leave out trailing slash, ex. https://jamf.jss.com:8443

###############################################
###  Handle Parameters
###############################################

#JSS_URL="https://punahou.jamfcloud.com"
####### JSS URL #####################
if [[ "$4" != "" ]] && [[ $URL == "" ]]; then
    URL=$4
fi
####### JJS Admin User ##############
if [[ "$5" != "" ]] && [[ $apiUsername == "" ]]; then
    apiUsername=$5
fi
####### JSS Admin User Password Encrypted #######
if [[ "$6" != "" ]] && [[ $apiPassword == "" ]]; then
    apiPassword=$6
fi
if [[ "$7" != "" ]] && [[ $tokenHolderUser == "" ]]; then
    tokenHolderUser=$7
fi
if [[ "$8" != "" ]] && [[ $tokenHolderPassword == "" ]]; then
    tokenHolderPassword=$8
fi
####### Execution switches: prepend (optional) #######
if [[ "$9" != "" ]] && [[ $renamePrepend == "" ]]; then
    renamePrepend=$9
else
    renamePrepend=""
fi
###############################################
###  Handle Parameters
###############################################
##!! Do not use parameters 10 and 11 - the values are not passed to the script properly
#we could use parameter with more than one digit with this method in bash
# https://www.computerhope.com/jargon/p/positional-parameter.htm#:~:text=Parameters%20greater%20than%209%20can%20be%20accessed%20using%20curly%20braces%20around%20the%20number%3B%20for%20instance%2C%20%24%7B10%7D%20would%20be%20the%20tenth%20parameter%2C%20and%20%24%7B123%7D%20would%20be%20the%20123rd

#JSS_URL="https://punahou.jamfcloud.com"
####### token Holder #####################
#use built in jamf variable to specify currently logged in user
# if [[ "$10" != "" ]] && [[ $tokenHolderUser == "" ]]; then
#     tokenHolderUser=$10
# fi
# if [[ "$11" != "" ]] && [[ $tokenHolderPassword == "" ]]; then
#     tokenHolderPassword=$11
# fi
#this script will create the tokenRecipientUser during execution, so the username and pasword is known and does not have to be passed in
####### token Recipient #####################
# if [[ "$5" != "" ]] && [[ $tokenRecipientUser == "" ]]; then
#     tokenRecipientUser=$5
# fi
# if [[ "$6" != "" ]] && [[ $tokenRecipientPassword == "" ]]; then
#     tokenRecipientPassword=$6
# fi

##############################################
###  Environment Variables
##############################################
tokenHolderSalt=29ea9b33804ce6f8
tokenHolderPassphrase=d1427b6369805712e37656bf

#this script will create the tokenRecipientUser during execution, so the username and pasword is known and does not have to be passed in
#tokenHolderSalt=5019b69ed73e5823
#tokenHolderPassphrase=cd234f5e93920c06d611e3f0
#tokenRecipientSalt=29ea9b33804ce6f8
#tokenRecipientPassphrase=d1427b6369805712e37656bf
####### Test for values
####### Test for values
if [[ "$tokenHolderUser" == "" ]] || [[ "$tokenHolderPassword" == "" ]] ; then
    echo "Check parameter values - exiting with error"
    echo "tokenHolderUser : $tokenHolderUser"
    echo "tokenHolderPassword : $tokenHolderPassword"
    exit 1
fi
if [[ "$URL" == "" ]] || [[ "$apiUsername" == "" ]] || [[ "$apiPassword" == "" ]]; then
    echo "Check parameter values - exiting with error"
    echo "URL : $URL"
    echo "apiUsername : $apiUsername"
    echo "apiPassword : $apiPassword"
    exit 1
fi

#debug only
echo "URL : $URL"
echo "apiUsername : $apiUsername"
echo "apiPassword : $apiPassword"
echo "tokenHolderUser : $tokenHolderUser"
echo "tokenHolderPassword : $tokenHolderPassword"
echo "renamePrepend : $renamePrepend"

##############################################
###  Environment Variables
##############################################
salt=6890970ed9c9b938
passphrase=9ee9e75eaeec4376b8f07671
##### values for API_User
#salt=46ea5be9f1163295
#passphrase=06edd3b45c0bdfa242cd4f33

##############################################

##############################################
###  Functions
##############################################

############## API related functions##########
# Include DecryptString() with your script to decrypt the password sent by the JSS
# The 'Salt' and 'Passphrase' values would be present in the script
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    #echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
    #add args to openssl command to handle Ventura 2023/01/18 by JA
    echo "${1}" | /usr/bin/openssl enc -md md5 -aes256 -d -a -A -S "${2}" -k "${3}"

}
#Variable declarations
bearerToken=""
tokenExpirationEpoch="0"
#username=$apiUsername
apiPassword=$(DecryptString "$apiPassword" "$salt" "$passphrase")

getBearerToken() {
    response=$(curl -s -u "$apiUsername":"$apiPassword" "$URL"/api/v1/auth/token -X POST)
    ## Courtesy of Der Flounder
    ## Source: https://derflounder.wordpress.com/2021/12/10/obtaining-checking-and-renewing-bearer-tokens-for-the-jamf-pro-api/
    ## Successfully added this code to extract the token from macOS version < 12 Monterey, but this does not handle the expiration or expirationEpoch like the jamf recipe does
    ## Jamf recipe assumes minimum OS version 12
    if [[ $(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}') -lt 12 ]]; then   
        bearerToken=$(/usr/bin/awk -F \" 'NR==2{print $4}' <<< "$response" | /usr/bin/xargs)
    else
        bearerToken=$(echo "$response" | plutil -extract token raw -)
        tokenExpiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
        #token=$(/usr/bin/plutil -extract token raw -o - - <<< "$authToken")
    fi  
    tokenExpirationEpoch=$(date -j -f "%Y-%m-%dT%T" "$tokenExpiration" +"%s")
}

checkTokenExpiration() {
    nowEpochUTC=$(date -j -f "%Y-%m-%dT%T" "$(date -u +"%Y-%m-%dT%T")" +"%s")
    if [[ tokenExpirationEpoch -gt nowEpochUTC ]]
    then
        echo "Token valid until the following epoch time: " "$tokenExpirationEpoch"
    else
        echo "No valid token available, getting new token"
        getBearerToken
    fi
}

invalidateToken() {
    responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${bearerToken}" $URL/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
    if [[ ${responseCode} == 204 ]]
    then
        echo "Token successfully invalidated"
        bearerToken=""
        tokenExpirationEpoch="0"
    elif [[ ${responseCode} == 401 ]]
    then
        echo "Token already invalid"
    else
        echo "An unknown error occurred invalidating the token"
    fi
}
############## My API related functions ##################################

# Usage: URL bearerToken username
getLDAPusername(){
    URL=$1
    bearerToken=$2
    username=$3
    ldapUsername=$(curl -X GET "$URL/JSSResource/ldapservers/id/1/user/$username" \
         -H "Authorization: Bearer ${bearerToken} " \
         -H "accept: application/xml" | xmllint --xpath '/ldap_users/ldap_user/username/text()' - 2> /dev/null)
    echo $ldapUsername
}
################################################


############## Prompt related functions ########
# Prompt technician to enter end-user's name.
function promptEndUser() {
  osascript <<EOT
    tell app "System Events"
      text returned of (display dialog "$1" default answer "$2" buttons {"Assign User"} default button 1 with title "Assign User")
    end tell
EOT
    # answer=$(/usr/bin/osascript -e 'set the answer to text returned of (display dialog "$1" default answer "$2" buttons {"Assign User"} default button 1 with title "Assign User"')
    # echo $answer
}
function displayBrandedWarningPrompt() {
    CURRENT_USER=$1
    # Variables
    JamfHelper='/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper'

    # Your company's logo, in PNG format. (For use in jamfHelper messages.)
    # Use standard UNIX path format:  /path/to/file.png
    LOGO_PNG="/Library/Punahou/256x256PunahouSeal-transparent.png"

    # Your company's logo, in ICNS format. (For use in AppleScript messages.)
    # Use standard UNIX path format:  /path/to/file.icns
    LOGO_ICNS="/Library/Punahou/256x256PunahouSeal.icns"
    # Convert POSIX path of logo icon to Mac path for AppleScript
    LOGO_ICNS="$(osascript -e 'tell application "System Events" to return POSIX file "'"$LOGO_ICNS"'" as text')"

    #Initial Instructions message
    # The title of the message that will be displayed to the user.
    # Not too long, or it'll get clipped.
    # added echo pipe to xargs to trim added whitespace, when I included the renamePrepend, if it is a blank value there are too many spaces in the string
    if [[ $rename == TRUE ]]; then
        PROMPT_TITLE=$(echo "Assign and Rename $renamePrepend Computer" | xargs)
    else
        PROMPT_TITLE=$(echo "Assign $renamePrepend Computer" | xargs)
    fi

    # The body of the message that will be displayed before prompting the user for
    # their password. All message strings below can be multiple lines.
    # if I tab this in to align with the rest of the function, then the prompt spacing is affected
PROMPT_MESSAGE="We will now assign this Computer to a user account. 
Please use their username (without @punahou.edu) to assign.
Click the Next button below, then enter username when prompted."

    # Display a branded prompt explaining the upcoming prompt.
    echo "Alerting user $CURRENT_USER about incoming LDAP account prompt..."
    #launchctl "$L_METHOD" "$L_ID" "$JamfHelper" -windowType "hud" -icon "$LOGO_PNG" -title "$PROMPT_TITLE" -description "$PROMPT_MESSAGE" -button1 "Next" -defaultButton 1 -startlaunchd &>/dev/null
    #"$JamfHelper" -windowType "hud" -icon "$LOGO_PNG" -title "$PROMPT_TITLE" -description "$PROMPT_MESSAGE" -button1 "Next" -defaultButton 1 -startlaunchd &>/dev/null
    "$JamfHelper" -windowType "hud" \
        -icon "$LOGO_PNG" \
        -title "$PROMPT_TITLE" \
        -description "$PROMPT_MESSAGE" \
        -button1 "Next" \
        -defaultButton 1 \
        -startlaunchd &>/dev/null
}
displayFailedPrompt() {
    # The body of the Filed Message - to be displayed if the user input not found in LDAP 3 times
    FAILED_MESSAGE="Computer Assign Failed."
    #Please contact a Punahou JAMF admin to reset this policy and make it available again. 
    #You will need to provide a Serial Number."
    echo "Displaying \"Failed\" message..."
    "$JamfHelper" -windowType hud \
        -title "$PROMPT_TITLE" \
        -heading "Failed" \
        -alignHeading left \
        -description "$FAILED_MESSAGE" \
        -icon $LOGO_PNG \
        -button1 "OK"
}
displayCompletedPrompt() {
    echo "Displaying \"Completed\" message..."
        "$JamfHelper" -windowType hud \
          -title "$PROMPT_TITLE" \
          -heading "Success" \
          -alignHeading left \
          -description "Thank you! This computer is now assigned to $username." \
          -icon $LOGO_PNG \
          -button1 "OK"
}
displaySuccessPrompt() {
    echo "Displaying \"success\" message..."
    "$JamfHelper" -windowType hud \
        -title "$PROMPT_TITLE" \
        -heading "Username Found" \
        -alignHeading left \
        -description "Username found in LDAP, $username will be assigned to this computer" \
        -icon $LOGO_PNG \
        -button1 "OK"
}
displayFailed-WrongUserPrompt() {
    # The body of the Filed Message - to be displayed if the user input not found in LDAP 3 times
    FAILED_MESSAGE="Please log in as a different user.  This policy cannot be run while logged in as loaner."
    #Please contact a Punahou JAMF admin to reset this policy and make it available again. 
    #You will need to provide a Serial Number."
    echo "Displaying \"Failed\" Wrong User message..."
    "$JamfHelper" -windowType hud \
        -title "$PROMPT_TITLE" \
        -heading "Failed" \
        -alignHeading left \
        -description "$FAILED_MESSAGE" \
        -icon $LOGO_PNG \
        -button1 "OK"
}
################################################

############## Assign Rename related functions ########
function getExistingComputerName() {
    echo "log Existing Computer Name"
    echo "Existing HostName: " `/usr/sbin/scutil --get HostName`
    echo "Existing LocalHostName: " `/usr/sbin/scutil --get LocalHostName`
    echo "Existing ComputerName: " `/usr/sbin/scutil --get ComputerName`
}

function updateComputerName() {
    echo "in updateComputerName"
    #update this function to use the rename and prepend switches
    computername=$1
    renamePrepend=$2
    echo $renamePrepend
    if [[ $renamePrepend != "" ]]; then 
         computername="$renamePrepend-$computername"
    fi
    echo "rename computer to $computername"
    echo "Set HostName to $computername"
    /usr/sbin/scutil --set HostName $computername
    echo "Set LocalHostName to $computername"
    /usr/sbin/scutil --set LocalHostName $computername
    echo "Set ComputerName to $computername"
    /usr/sbin/scutil --set ComputerName $computername
    sleep 3

}
##############################################
###  Functions from securetoken script
##############################################
# Include DecryptString() with your script to decrypt the password sent by the JSS
# The 'Salt' and 'Passphrase' values would be present in the script
#duplicate function - already included in the rename scipt above - JA 7/20/23
# function DecryptString() {
#     # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
#     #handle Ventura or later
#     echo "${1}" | /usr/bin/openssl enc -md md5 -aes256 -d -a -A -S "${2}" -k "${3}"
# #   echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
# }
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
        echo "demote $userName, log user status"
        logUserStatus $userName
    fi
}
function passSecureToken() {
    # modified from: https://github.com/daveyboymath/Jamf/blob/MacOS/PassSecureToken.sh
    #usage: tokenHolderUser tokenHolderPassword tokenRecipientUser tokenRecipientPassword
    #set tokenRecipient variables
    #tokenRecipientUser=$username
    #tokenRecipientPassword="gopuns"


    # the current problem is that this is being interpreted in the context of the whole script and not in the context of the function
    #maybe just use global variables?  must be a good way to enforce local context for the passed in variables
    tokenHolderUser=$1
    tokenHolderPassword=$2
    tokenRecipientUser=$3
    tokenRecipientPassword=$4
    #debug only
    echo "tokenHolderUser : $tokenHolderUser"
    echo "tokenHolderPassword : $tokenHolderPassword"
    echo "tokenRecipientUser : $tokenRecipientUser"
    echo "tokenRecipientPassword : $tokenRecipientPassword"

    ##############################################
    ###  Main from pass secureToken
    ##############################################
    
    #######################
    ###Decrypt Credentials ###
    #######################
    tokenHolderPassword=$(DecryptString "$tokenHolderPassword" "$tokenHolderSalt" "$tokenHolderPassphrase")
    #tokenRecipientPassword=$(DecryptString "$tokenRecipientPassword" "$tokenRecipientSalt" "$tokenRecipientPassphrase")
    #this script will create the tokenRecipientUser during execution, so the username and pasword is known and does not have to be passed in

    ##############################################################
    # Check if token holder is already admin - if so skip the demote step later in the script
    alreadyAdmin=$(isAdmin $tokenHolderUser)
    echo "Currently Logged in user admin initial state: $alreadyAdmin"
    logUserStatus $tokenHolderUser
    logUserStatus $tokenRecipientUser
    #promoteUser function will skip promotion if user is already admin - so call the function anyway
    promoteUser $tokenHolderUser
    logUserStatus $tokenHolderUser
    #debug only
    #    echo "sysadminctl -adminUser "$userName" -adminPassword "$userPassword" -secureTokenOn $adminUser -password $adminPassword"

    #####################################################################################################
    ###Store the output of the sysadminctl command into a variable to use it for error handling later.###
    #####################################################################################################
    output=$(sudo sysadminctl -adminUser "$tokenHolderUser" -adminPassword "$tokenHolderPassword" -secureTokenOn $tokenRecipientUser -password $tokenRecipientPassword 2>&1)

    #debug only
    echo "output: $output"
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
        #sysadminctl -adminUser "$tokenHolderUser" -adminPassword "$tokenHolderPassword" -secureTokenOn $tokenRecipientUser -password $tokenRecipientPassword
        echo "log both users status after attempt to pass token"
        logUserStatus $tokenHolderUser
        logUserStatus $tokenRecipientUser
        #debug only
        #echo "sysadminctl -adminUser "$userName" -adminPassword "$userPassword" -secureTokenOn $adminUser -password $adminPassword"
        echo "Demote user $tokenHolderUser"
        demoteUser $tokenHolderUser $alreadyAdmin
        echo "Log both User's status"
        logUserStatus $tokenHolderUser
        logUserStatus $tokenRecipientUser
    else
        echo "Command failed, exit with failure"
        echo "Demote user $tokenHolderUser"
        demoteUser $tokenHolderUser $alreadyAdmin
        echo "Log both User's status"
        logUserStatus $tokenHolderUser
        logUserStatus $tokenRecipientUser
    fi
}
#add create standard user function 
function createUser() {
    #pass in $username of user to create, use default password "gopuns"
    #find next available uid
    # while [[ "$uid_check" != "" ]]; do
    #     uid=`expr $uid + 1`
    #     uid_check=`dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | grep "$uid"`
    #     /bin/echo Checking for next available UID...
    #     if [[ "$uid_check" != "" ]]; then
    #         /bin/echo The UID "$uid_check" is not available, checking for next available UID.
    #     else
    #         /bin/echo next UID is $uid
    #     fi
    # done
    assignment=$1
    # Create the user
    echo "create user $assignment"
    # /usr/bin/dscl . -create /Users/$assignment
    # /usr/bin/dscl . -create /Users/$assignment UserShell /bin/bash
    # /usr/bin/dscl . -create /Users/$assignment RealName "$assignment"
    # /usr/bin/dscl . -create /Users/$assignment UniqueID "$uid"
    # /usr/bin/dscl . -create /Users/$assignment PrimaryGroupID 20
    # #create the user's home directory
    # [[ -d "/Users/$assignment" ]] && mkdir /Users/$assignment
    # /usr/bin/dscl . -create /Users/$assignment NFSHomeDirectory /Users/$assignment

    # # Set the Password
    # /usr/bin/dscl . -passwd /Users/$assignment gopuns
    # if [ $? == 0 ]; then
    #     echo "Password successfully changed!"
    # else
    #     echo "Password not changed!"
    # fi  
    #create the user's home directory
    #[[ -d "/Users/$assignment" ]] && mkdir /Users/$assignment
    #sysadminctl -addUser $assignment -fullName $assignment -shell /bin/bash -password "gopuns" -home /Users/$assignment  
    jamf createAccount -username $assignment -realname $assignment -password "gopuns" -home /Users/$assignment -shell "/bin/bash" -suppressSetupAssistant
}
#add delete user function
function deleteUser() {
    echo "delete user: $1"
    if id -u "$1" >/dev/null 2>&1; then
        echo "user $1 found, deleting"
        /usr/bin/dscl . -delete /Users/$1
        echo "delete user $1 home folder"
        rm -rf /Users/$1
    else
        echo "user $1 not found, skip delete"
    fi
} 
################################################
###  Main Block
################################################
checkTokenExpiration
#check Jamf version
curl -s -H "Authorization: Bearer ${bearerToken}" $URL/api/v1/jamf-pro-version -X GET

#log computer state before making changes
getExistingComputerName

# Get the logged in user's name
#Python depracated
#CURRENT_USER="$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')"
CURRENT_USER=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

displayBrandedWarningPrompt $CURRENT_USER

#user loaner is going to be removed from the computer as a part of the workflow.  If the currently logged in user name is loaner, display an error and exit
if [[ $CURRENT_USER == "loaner" ]]; then
    echo "Current user is loaner, this policy must be run from another account on the device"
    #display prompt
    displayFailed-WrongUserPrompt
    invalidateToken
    exit 1
fi

#try three times
for ((i=0; i<3; i++)); do
    #prompt for username to assign
    if [ $i == 0 ]; then
        username="$(promptEndUser 'Please enter the username of the end-user.' '')"
    else
        username="$(promptEndUser 'Username not found.  Please enter username of the end-user.' '')"
    fi
    echo "Username: $username entered"
    #Check if THAT username exists

    ldapUsername=$(getLDAPusername $URL $bearerToken $username)
    #debug only
    echo "ldap username lookup result: $ldapUsername"
    #If it does, assign them, and bail out
    if [[ "$username" == "$ldapUsername" ]]; then
        echo "Ldap username: $username found."
        displaySuccessPrompt
#       computername=$username
        echo "$username found in LDAP"
        #create the user
        echo "create user $username"
        createUser $username
        echo "pass token to $username"
        passSecureToken $tokenHolderUser $tokenHolderPassword $username "gopuns"
        echo "delete loaner user"
        #delete loaner user on success
        deleteUser "loaner"
        #function will rename computer and include prepend
        updateComputerName $username $renamePrepend
        #assign computer
        echo "assign: jamf recon -endUsername $username"
        /usr/local/bin/jamf recon -endUsername $username
        displayCompletedPrompt
        invalidateToken
        
        exit 0
    elif [[ $i = 2 ]]; then
        displayFailedPrompt
        invalidateToken
        exit 1  
    fi
    
done