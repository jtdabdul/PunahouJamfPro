#!/bin/bash 
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
#       recon -endUsername.  If the user is not found, retry prompt until 3 attemps have failed. 
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
#
####################################################################################################
####################################################################################################

##### Consolidate to a single script with parameters to catch use cases
# Assign and rename computer - prompts up to 3 times for provided username, renames computer to end username assign computer via recon
#   <script> JamfURL APIUser APIPassword(enc) promptForUser=TRUE rename=TRUE renamePrepend=""
# Assign and rename loaner - prompts up to 3 times for provided username, renames computer to "loaaner-"<end username> assign computer via recon
#   <script> JamfURL APIUser APIPassword(enc) promptForUser=TRUE rename=TRUE renamePrepend="loaner"
#   need to handle jamfhelper title to include the prepend parameter - this script used title 'Assign loaner computer'
# Assign and rename long term loaner - prompts up to 3 times for provided username, renames computer to "LT-loaaner-"<end username> assign computer via recon
#   <script> JamfURL APIUser APIPassword(enc) promptForUser=TRUE rename=TRUE renamePrepend="LT-loaner"
#   need to handle jamfhelper title to include the prepend parameter - this script used title 'Assign Long Term Loaner computer'
# Assign computer to logged in user - does not prompt for username to assign to, detects logged in user and assigns from there.  Uses a wait for user function to ensure that a user is logged in prior to functions running. no rename just assign via recon
#   <script> JamfURL APIUser APIPassword(enc) promptForUser=FALSE rename=FALSE renamePrepend=""
#   skip username prompt and use logged in user to check for existence in LDAP, then rename computer to detected user, assign via jamf recon
# Assign Shared Computer to Logged in user no rename - do assign step, but skip rename function
#   <script> JamfURL APIUser APIPassword(enc) promptForUser=TRUE rename=FALSE renamePrepend=""

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
####### Execution switches: prompt (TRUE/FALSE) optional default FALSE #######
if [[ "$7" != "" ]] && [[ $promptForUser == "" ]]; then
    promptForUser=$7
else
    promptForUser=FALSE
fi
####### Execution switches: rename (T/F||0/1) optional default FALSE #######
if [[ "$8" != "" ]] && [[ $rename == "" ]]; then
    rename=$8
else
    rename=FALSE
fi
####### Execution switches: prepend (optional) #######
if [[ "$9" != "" ]] && [[ $renamePrepend == "" ]]; then
    renamePrepend=$9
else
    renamePrepend=""
fi
####### Test for values
if [[ "$URL" == "" ]] || [[ "$apiUsername" == "" ]] || [[ "$apiPassword" == "" ]]; then
    echo "Check parameter values - exiting with error"
    echo "URL : $URL"
    echo "apiUsername : $apiUsername"
    echo "apiPassword : $apiPassword"
    exit 1
fi

#debug only
#echo "URL : $URL"
#echo "apiUsername : $apiUsername"
#echo "apiPassword : $apiPassword"
#echo "promptForUser : $promptForUser"
#echo "rename : $rename"
#echo "renamePrepend : $renamePrepend"

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

if [[ $promptForUser == FALSE ]]; then
    #if promptForUser is false, silently assign the computer to currently logged in user
    username=$CURRENT_USER
    ldapUsername=$(getLDAPusername $URL $bearerToken $username)
    echo "getLDAPusername result: $ldapUsername"
    if [[ $username == $ldapUsername ]]; then
        echo "Ldap username: $username found."
        if [[ $rename == TRUE ]]; then
            #rename computer
            updateComputerName $username $renamePrepend
        fi
        #assign computer with jamf binary
        echo "assign: jamf recon -endUsername $username"
        /usr/local/bin/jamf recon -endUsername $username
        exit 0
    else
        echo "user $username not found in LDAP"
        exit 1
    fi
    #If I get here, then prompt == FALSE - continue execution below
fi

displayBrandedWarningPrompt $CURRENT_USER

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
        #function will rename computer if rename is TRUE, include prepend
        if [[ $rename == "TRUE" ]] ; then
            updateComputerName $username $renamePrepend
        fi
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
exit 0