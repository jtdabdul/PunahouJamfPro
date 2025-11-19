#!/bin/bash 
#
####################################################################################################
#
#   Code snippet based on Client Credentials Authorization recipe found at 
#   https://developer.jamf.com/jamf-pro/docs/client-credentials
#
#####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#   
#   JamfAPIEraseDevice.sh
#
# SYNOPSIS - How to use
#   
#   Script is intended to be used in a Jamf policy run from the client side.  Jamf Pro API will be utilized to 
#   obtain the client's Jamf Id, then use the v2 post mdm command ERASE_DEVICE to Erase all Contents and Settings
#   on the client.  Optional argument can be included to delete the client from Jamf Pro, ensuring that any
#   static groups or other customizations on the computer do not survive re-enroll.
#

#   This template is intended for use as a header to Jamf policy scripts which utilize the Jamf Pro API.
#   It is based on a developer.jamf.com code snippet.  Our environment requires us to obscure the 
#   client secret by encrypting it and passing the encrypted string as a parameter, holding the salt and 
#   passphrase in the script body so that the client secret can be decrypted by the script and used to 
#   obtain the bearer token.
#   Parameters 4-6 will contain the jamf pro URL, the client ID, and the client secret (encrypted)
# 
# DESCRIPTION
#
#   This script will erase a client computer and optiionally delete it from the Jamf Pro server.
#   
#   Template JamfProAPIClientAuth.sh
#   This template is intended to be used as a header for Jamf Pro API scripts.  Parameters 7-11 are
#   still available for scripts that use this template.
#
#   FYI - Jamf code snippet assumes minimum macOS version 12, Thanks to RTrouton's derflounder (link below)
#   this code can extract an access_token in macOS < 12.  If you do not need support for macOS 11 or earlier,
#   you can replace the getAccessToken function in this file with the linked Jamf recipe (as of 2025/10/16)
# 
####################################################################################################
####################################################################################################
#
# HISTORY
#
#   Version: 1.0 by Lucas Vance @ JAMF Software 11-4-16
#   Modified on 12/28/2022 by Jason Abdul to update API Authenticationt to Bearer Token
#   Modified on 6/6/2023 by Jason Abdul to repurpose for API EraseDevice command to be sent to the calling computer
#   Modified on 2025/10/16 by Jason Abdul to utilize Template JamfProAPIClientAuth.sh to update auth
#       method to clientID/clientSecret and update Jamf Api Classic calls to Jamf Pro Api
#   Modified on 2025/11/18 by Jason Abdul to update eraseComputer function to use Jamf Pro API v2 to send the erase
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
# Delete device (TRUE||FALSE) (optional) Default FALSE
# Parameter 8
# Passcode (optional)
####################################################################################################
###############################################
###  Handle Parameters
###############################################

####### URL #####################  
if [[ "$4" != "" ]] && [[ $url == "" ]]; then
    url=$4
fi
####### API Client ##############
if [[ "$5" != "" ]] && [[ $client_id == "" ]]; then
    client_id=$5
fi
####### API Client Secret Encrypted #######
if [[ "$6" != "" ]] && [[ $client_secret == "" ]]; then
    client_secret=$6
fi

####### Test for values
if [[ "$url" == "" ]] || [[ "$client_id" == "" ]] || [[ "$client_secret" == "" ]]; then
    echo "Check parameter values - exiting with error"
    echo "URL : $url"
    echo "API Client ID : $client_id"
    echo "API Client Secret (encrypted): $client_secret"
    exit 1
fi

##############################################
###  Functions
##############################################
# Added on 2025/10/16 by JA to handle secret decryption
# Include DecryptString() with your script to decrypt the password sent by the Jamf policy
# The 'Salt' and 'Passphrase' values would be present in the script
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
#    echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
    #add args to openssl command to handle Ventura 2023/01/25 by JA
    echo "${1}" | /usr/bin/openssl enc -md md5 -aes256 -d -a -A -S "${2}" -k "${3}"
}

# Included in Jamf recipe, but commented out to accept these values as arguments.
# Un-comment these lines to embed credentials in your script instead (not recommended for production but could be useful in troubleshooting)
# url="https://yourserver.jamfcloud.com"
# client_id="your-client-id"
# client_secret="yourClientSecret"

getAccessToken() {
    response=$(curl --silent --location --request POST "${url}/api/oauth/token" \
        --header "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "client_id=${client_id}" \
        --data-urlencode "grant_type=client_credentials" \
        --data-urlencode "client_secret=${client_secret}")
    ## Courtesy of Der Flounder
    ## Source: https://derflounder.wordpress.com/2021/12/10/obtaining-checking-and-renewing-bearer-tokens-for-the-jamf-pro-api/
    ## Successfully added this code to extract the token from macOS version < 12 Monterey, but this does not handle the expiration or expirationEpoch like the jamf recipe does
    ## Jamf recipe assumes minimum OS version 12
    if [[ $(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}') -lt 12 ]]; then   
        access_token=$(/usr/bin/awk -F \" 'NR==2{print $4}' <<< "$response" | /usr/bin/xargs)
    else
        access_token=$(echo "$response" | plutil -extract access_token raw -)
        token_expires_in=$(echo "$response" | plutil -extract expires_in raw -)
    fi
    token_expiration_epoch=$(($current_epoch + $token_expires_in - 1))
}

checkTokenExpiration() {
    current_epoch=$(date +%s)
    if [[ token_expiration_epoch -ge current_epoch ]]
    then
        echo "Token valid until the following epoch time: " "$token_expiration_epoch"
    else
        echo "No valid token available, getting new token"
        getAccessToken
    fi
}

invalidateToken() {
    responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${access_token}" $url/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
    if [[ ${responseCode} == 204 ]]
    then
        echo "Token successfully invalidated"
        access_token=""
        token_expiration_epoch="0"
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

##############################################
###  Custom Parameters
##############################################

####### Delete device from Jamf Pro (TRUE || FALSE) #######
if [[ "$7" != "" ]] && [[ $delete == "" ]]; then
    delete=$7
else
    delete="FALSE"
fi
####### Passcode #######
if [[ "$8" != "" ]] && [[ $passcode == "" ]]; then
    passcode=$8
else
    passcode=123456
fi

##############################################
###  Setup Environment
##############################################

#Variable declarations
access_token=""
token_expiration_epoch="0"

### End Setup Environment ####################

########################
### Sample Usage code from Recipe 

## You may comment out this code block and replace with your logic
## checkTokenExpiration will get an access token if none is currently active
# checkTokenExpiration
# curl -H "Authorization: Bearer $access_token" $url/api/v1/jamf-pro-version -X GET
# checkTokenExpiration
# invalidateToken
# curl -H "Authorization: Bearer $access_token" $url/api/v1/jamf-pro-version -X GET
### End Sample Code ###

#####################################################################################
###########################    Your Code Here
#####################################################################################

##############################################
###  Environment Variables
##############################################
# These values are obtained by running the encryptString function
# These values will need to be re-generated and updated in the script each time the client secret is rotated
salt="b46124640ded7e1e"
passphrase="1b51f10e36b1ae7a4f8d87f5"
##############################################
#decode the secret with the salt and passphrase
#if you intend to pass the client secret unencrypted to this script then comment the next line of code
client_secret=$(DecryptString "$client_secret" "$salt" "$passphrase")

### End Setup Environment ####################

### Functions ##########
getInventoryFromSerial() {
    result="$(curl -sS -G "$url/api/v1/computers-inventory" \
    -H "Authorization: Bearer $access_token" \
    -H 'Accept: application/json' \
    --data-urlencode 'section=GENERAL' \
    --data-urlencode 'page=0' \
    --data-urlencode 'page-size=1' \
    --data-urlencode "filter=hardware.serialNumber==\"$serial\"")"
    echo $result
}
eraseComputer() {
    #v2 needs a computer's management ID
    # Jamf Pro v2 - not working return code 500 even when I use swaggerUI with full admin - come back to investigate
    # Needed a passcode in the data body.
    # -w "%{http_code}" - write-out HTTP status code
response=$(curl -sS -X POST "$url/api/v2/mdm/commands" \
    -H "Authorization: Bearer $access_token" \
    -H 'accept: application/json' \
    -H 'content-type: application/json' \
    -w "%{http_code}" \
    -d @- <<EOF
{
    "commandData": {
        "commandType": "ERASE_DEVICE",
        "obliterationBehavior": "DoNotObliterate",
          "pin": "$2"
    },
    "clientData": [
    {
        "managementId": "$1"
    }
  ]
  
}
EOF
)
    ### Pro v1
    # Needs a Jamf Pro Computer ID (.results[0].id)
    # Collect Https response code indicating success or failure of the command instead of the command output
# response=$(
# curl -s -o /dev/null -w "%{http_code}" -X POST "$url/api/v1/computer-inventory/$1/erase" \
#   -H "Authorization: Bearer $access_token" \
#   -H "Accept: application/json" \
#   -H "Content-Type: application/json" \
#   -d @- <<EOF
# {
#   "pin": "$passcode"
# }
# EOF
# )
echo "$response"
}
deleteComputer() {
    response=$(curl --request DELETE \
    --url $url/api/v2/computers-inventory/$jamfID \
    -H "Authorization: Bearer $access_token" \
    -H 'accept: application/json')
    echo $response
}
# Function to log messages to file and echo to console
LOG_FILE="/var/log/jamfEraseDelete.log"
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}
### End Functions #####

#get bearer token if no curent token found
checkTokenExpiration

#get serial number
serial=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
log_message "serial: $serial"

#get id from serial number
jamfID=$(getInventoryFromSerial "$serial" | jq -r '.results[0].id')
log_message "jamfID: $jamfID"

managementID=$(getInventoryFromSerial "$serial" | jq -r '.results[0].general.managementId' )
log_message "managementID: $managementID"

#send erase device
log_message "erase device"

#response=$(eraseComputer "$jamfID")    #pass in jamfID for v1 command, managementID for v2 command
response=$(eraseComputer "$managementID" "$passcode")
# eraseComputer curl command includes -w "%{http_code}" to include https response code to stdout so we can get it from the response variable
log_message "erase response $response"

HTTP_STATUS=$(echo "${response}" | tail -c 4)   #last 4 bytes of the response should contain the http response code, tried 3 but got 01 not 201 so use -c 4
log_message "erase response header: $HTTP_STATUS"
if [[ $HTTP_STATUS =~ ^2 ]]; then
    log_message "HTTP request to $url successul (2xx status code: $HTTP_STATUS)"
    #optional delete device
    if [[ $delete == "TRUE" ]]; then
        sleep 1
        log_message "delete device= TRUE, remove Jamf record for $jamfID"
        response=$(deleteComputer "jamfID")
        log_message "delete response: $response"
     else
        log_message "delete set to FALSE, Jamf record will not be deleted"
    fi
else
    log_message "HTTP request to $url failed (status code: $HTTP_STATUS)"
    invalidateToken
    exit 1
fi
########################

########################
### Clean up
invalidateToken
# Verify token is successfully invalidated (optional)  Output at end of script should be {"httpStatus" : 401,"errors" : [ ]}
curl -H "Authorization: Bearer $access_token" $url/api/v1/jamf-pro-version -X GET
exit 0