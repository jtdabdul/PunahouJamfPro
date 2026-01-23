#!/bin/bash 
#
#Display NameDisplay name for the script
#   Assign Computer to Static Group
#   CategoryCategory to add the script to
#   Helpdesk Tools
#   InformationInformation to display to the administrator when the script is run
#   NotesNotes to display about the script (e.g., who created it and when it was created)
#   updated on 2022/12/29 by JA to use Bearer Token Auth
#   updated on 2023/01/12 by JA to add parameter to specify add or remove from group
#   updated on 2025/02/28 by JA to add optional parameter to require macOS versions in a comma separated list
#   updated on 2025/10/01 by JA to use clientID and clientSECRET
#Parameter 4
#JSS URL
#Parameter 5
#Username
#Parameter 6
#Password
#Parameter 7
#Static Group ID
#Parameter 8
#Operation (ADD || REMOVE), optional ADD is default
#Parameter 9
#OS version requirement comma separated os versions (no spaces) ex: 14.7.2,15.2,15.2.0 (optional)
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
#   Adapted from API script to upload client files, this script will add or remove a computer from a static group
#   with an API call.  The APi user should only have permission to update static groups.
#   Parameters: JSS URL, API username, encrypted password, Static Group ID, operation (optional, ADD is default)
# 
####################################################################################################
#
# HISTORY
#
#   Version: 1.0 by Lucas Vance @ JAMF Software 11-4-16
#   Modified on 12/28/2022 by Jason Abdul to update API Authenticationt to Bearer Token
#
####################################################################################################
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
####### Static Group's ID ###########
if [[ "$7" != "" ]] && [[ $staticGroupID == "" ]]; then
    staticGroupID=$7
fi
####### Operation (ADD || REMOVE) ###########
if [[ "$8" != "" ]] && [[ $operation == "" ]]; then
    operation=$8
else
    operation="ADD"
fi
if [[ "$9" != "" ]] && [[ $compliantVersions == "" ]]; then
    IFS=','
    compliantVersions=($9)
    unset IFS
    echo "${compliantVersions[@]}"
fi
####### Test for values
if [[ "$URL" == "" ]] || [[ "$apiUsername" == "" ]] || [[ "$apiPassword" == "" ]] || [[ "$staticGroupID" == "" ]]; then
    echo "Check parameter values - exiting with error"
    echo "URL : $URL"
    echo "apiUsername : $apiUsername"
    #echo "apiPassword : $apiPassword"
    echo "staticGroupID : $staticGroupID"
    exit 1
fi
##############################################
###  Environment Variables
##############################################
salt="bfcc70d10f3bc42b"
passphrase="a57cd4d21ceac44720ad795c"
localLogFile="/Library/Punahou/staticGroup.log"
echo "$(date -u)" >> $localLogFile
##############################################

##############################################
###  Functions
##############################################
# Include DecryptString() with your script to decrypt the password sent by the JSS
# The 'Salt' and 'Passphrase' values would be present in the script
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    #updated to handle Ventura or later
    echo "${1}" | /usr/bin/openssl enc -md md5 -aes256 -d -a -A -S "${2}" -k "${3}"
#    echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
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
handleStaticGroup(){
    macSerial=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
    checkTokenExpiration
    if [ -n "$staticGroupID" ]; then
        echo "Static Group $staticGroupID $operation"
        echo "Static Group $staticGroupID $operation" >> $localLogFile
        if [[ $operation == "ADD" ]]; then
            #Add 'em
            curl -s -H "Authorization: Bearer ${bearerToken}" -H "content-type: text/xml" $URL/JSSResource/computergroups/id/$staticGroupID -X PUT -d "<computer_group><computer_additions><computer><serial_number>$macSerial</serial_number></computer></computer_additions></computer_group>"
        else
            #should be REMOVE instead
            curl -s -H "Authorization: Bearer ${bearerToken}" -H "content-type: text/xml" $URL/JSSResource/computergroups/id/$staticGroupID -X PUT -d "<computer_group><computer_deletions><computer><serial_number>$macSerial</serial_number></computer></computer_deletions></computer_group>"
        fi
    fi
}
################################################
###  Main Block
################################################
osversion=$(sw_vers -productVersion)
echo "current macOS version: $osversion"
#if no OS version requirement provided
if [[ -z "${compliantVersions[*]}" ]]; then
    echo "No OS version requirement provided in parameters, proceed with static group $operation"
    echo "No OS version requirement provided in parameters, proceed with static group $operation" >> $localLogFile
    handleStaticGroup
    ##### Clean up
    invalidateToken
    exit 0
fi
#For this implementation
echo "Check for OS version requirement in list ${compliantVersions[@]}"
echo "Check for OS version requirement in list ${compliantVersions[@]}" >> $localLogFile
if [ -n "$compliantVersions" ] && [[ " ${compliantVersions[@]} " =~ " ${osversion} " ]]; then
    echo "OS version $osversion found - device is in compliance"
    echo "${compliantVersions[@]}"
    handleStaticGroup
    ##### Clean up
    invalidateToken
    exit 0
else
    echo "Compliant macOS version specified and not found, static group $operation not performed.  exit."
    echo "Compliant macOS version specified and not found, static group $operation not performed.  exit." >> $localLogFile
    echo "${compliantVersions[@]}"
    exit 1
fi
# checkTokenExpiration
# #check Jamf version
# curl -s -H "Authorization: Bearer ${bearerToken}" $URL/api/v1/jamf-pro-version -X GET

# #Get Mac serial number
# macSerial=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')

# if [[ $operation == "ADD" ]]; then
#     #Add 'em
#     curl -s -H "Authorization: Bearer ${bearerToken}" -H "content-type: text/xml" "$URL"/JSSResource/computergroups/id/$staticGroupID -X PUT -d "<computer_group><computer_additions><computer><serial_number>$macSerial</serial_number></computer></computer_additions></computer_group>"
# else
#     #should be REMOVE instead
#     curl -s -H "Authorization: Bearer ${bearerToken}" -H "content-type: text/xml" "$URL"/JSSResource/computergroups/id/$staticGroupID -X PUT -d "<computer_group><computer_deletions><computer><serial_number>$macSerial</serial_number></computer></computer_deletions></computer_group>"
# fi
##### Clean up
#invalidateToken