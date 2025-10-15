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
#   uploadClientLogs.sh
#
# SYNOPSIS - How to use
#   
#   Add this script to Jamf so we can use it within a policy.  Please modify the variables below under
#   the JSS Variables section.  Once those steps are completed, please create a policy and add this script
#   using the script payload.  Scope the policy to the computers we wish to upload logs for.
# 
# DESCRIPTION
#   
#   This script will silently compress client side logs and upload them to the device record within
#   Jamf.  The end users will not be needed for any part of this policy and will run at an admins
#   discretion.  After the logs are uploaded to the devices inventory record, we are cleaning up the
#   compressed logs on the client side.
# 
####################################################################################################
#
# HISTORY
#
#   Version: 1.0 by Lucas Vance @ JAMF Software 11-4-16
#   Modified on 12/28/2022 by Jason Abdul to update API Authenticationt to Bearer Token
#   Modified on 6/6/2023 by Jason Abdul to repurpose for API EraseDevice command to be sent to the calling computer
#
####################################################################################################
####################################################################################################
#
# Jamf Script Details
# 
#  
# Display NameDisplay name for the script
# JamfAPIEraseDevice
# CategoryCategory to add the script to
# Helpdesk Tools
# InformationInformation to display to the administrator when the script is run
# NotesNotes to display about the script (e.g., who created it and when it was created)
# adapted from UploadClientLogs script on 6/6/2023 by JA
# provide Jamf URL, API User, API Password, passcode optional
# create API_EraseDevice user with Computer create read, and Send Computer Remote Wipe Command, update script to hold salt and passphrase to decrypt password
# Parameter 4
# JSS URL
# Parameter 5
# Username
# Parameter 6
# Password
# Parameter 7
# Passcode (optional)
####################################################################################################

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
####### JSS Admin User Password Encrypted #######
if [[ "$7" != "" ]] && [[ $passcode == "" ]]; then
    passcode=$7
else
    passcode=123456
fi

####### Test for values
if [[ "$URL" == "" ]] || [[ "$apiUsername" == "" ]] || [[ "$apiPassword" == "" ]] || [[ "$passcode" == "" ]]; then
    echo "Check parameter values - exiting with error"
    echo "URL : $URL"
    echo "apiUsername : $apiUsername"
    echo "apiPassword : $apiPassword"
    echo "passcode : $passcode"
    exit 1
fi
##############################################
###  Environment Variables
##############################################
#salt="13406516bc72d4e1"
#passphrase="a13d932cb16d82acf26448e4"
salt="7a47a720d45987ec"
passphrase="570fa57d04b22c39059d1e99"
##############################################

##############################################
###  Functions
##############################################
# Include DecryptString() with your script to decrypt the password sent by the JSS
# The 'Salt' and 'Passphrase' values would be present in the script
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
#    echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
    #add args to openssl command to handle Ventura 2023/01/25 by JA
    echo "${1}" | /usr/bin/openssl enc -md md5 -aes256 -d -a -A -S "${2}" -k "${3}"

}
#Variable declarations
bearerToken=""
tokenExpirationEpoch="0"
username=$apiUsername
password=$(DecryptString "$apiPassword" "$salt" "$passphrase")

getBearerToken() {
    response=$(curl -s -u "$username":"$password" "$URL"/api/v1/auth/token -X POST)
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
################################################
###  Main Block
################################################
checkTokenExpiration
#check Jamf version
curl -s -H "Authorization: Bearer ${bearerToken}" $URL/api/v1/jamf-pro-version -X GET

########## Device Serial Number Variable ##########
#computer=$(scutil --get ComputerName)
#echo "Computer name: $computer"
computer=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
########## Create an ID variable to pull in our computer ID from the JSS so we can upload our Logs to the inventory record ##########
id=$(/usr/bin/curl -sk -H "Authorization: Bearer ${bearerToken}" -H "Accept: application/xml" $URL/JSSResource/computers/serialnumber/$computer | xmllint --xpath '/computer/general/id/text()' -)
echo "Computer Jamf ID: $id"
########## Send EraseDevice Command to the computer via Jamf Classic API ##########
response=$( /usr/bin/curl \
--header "Authorization: Bearer ${bearerToken}" \
--header "Content-Type: text/xml" \
--request POST \
--silent \
--url "$URL/JSSResource/computercommands/command/EraseDevice/passcode/$passcode/id/$id" )

echo "$response"
##### Clean up ###############################################
invalidateToken
exit 0