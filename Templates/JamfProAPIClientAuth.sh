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
#   JamfProAPIClientAuth.sh
#
# SYNOPSIS - How to use
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
#   This template is intended to be used as a header for Jamf Pro API scripts.  Parameters 7-11 are
#   still available for scripts that use this template.
#
#   FYI - Jamf code snippet assumes minimum macOS version 12, Thanks to RTrouton's derflounder (link below)
#   this code can extract an access_token in macOS < 12.  If you do not need support for macOS 11 or earlier,
#   you can replace the getAccessToken function in this file with the linked Jamf recipe (as of 2025/10/16)
# 
####################################################################################################
#
# HISTORY
#
#   Version: 1.0 by https://developer.jamf.com/jamf-pro/docs/client-credentials
#   Modified on 2025/10/16 by Jason Abdul to add parameter handling and client secret decryption to the workflow
#   include macos <12 support with RTrouton's code (linked below)
#
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
salt="440a343caef9a617"
passphrase="0491df58e5c45bebc4e773ca"
##############################################
#decode the secret with the salt and passphrase
#if you intend to pass the client secret unencrypted to this script then comment the next line of code
client_secret=$(DecryptString "$client_secret" "$salt" "$passphrase")

checkTokenExpiration

########################

########################
### Clean up
invalidateToken
# Verify token is successfully invalidated (optional)  Output at end of script should be {"httpStatus" : 401,"errors" : [ ]}
#curl -H "Authorization: Bearer $access_token" $url/api/v1/jamf-pro-version -X GET
exit 0