#!/bin/bash
########################################################################################################################
# Default Header
# Created by:	Jason Abdul (jabdul@punahou.edu)
# Summary:		This is a default header intended to be included in shell scripts in jamf.  
#				Commonly used Global variables, and functions are included.
# Documentation: (#URL)
#
# Note:			This is a starter header, to be updated in the future.  
#				Used Mann Consulting JNUC2025 header for reference. https://mann.com/jnuc2025
# History:		Created on 2026/02/04 by JA
#         Modified 2026/07/10 by JA - update logging - implement log levels, add caller functions named to imply the second parameter
########################################################################################################################
### Global Variables
VERSIONDATE='20260710'        # Format YYYYMMDD - used for version control
APPLICATION="ApplicationName" # Change to your application name for logging
LOCKED_THRESHOLD=604800       # If the computer is locked for this long (7 days) then exit to prevent issues with Jamf policies blocking other policies.
SHUTDOWN_THRESHOLD=2592000    # If the computer is locked for this long (30 days) then prompt for shutdown.
MINSWVERSION=13               # Minimum macOS version required to run this script
#No Datadog implementation for our organization so far.
DATADOGAPI=""                 # Add your Datadog API key here to enable Datadog logging, otherwise leave blank. NOTE: Mann recommends encryping your API keys.
icon="/Library/Punahou/256x256PunahouSeal-transparent.png"	# Path to icon to use in jamfHelper windows  

#MARK: Start Default Header
##### Start Default Header 20260707
PATH="/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin"
scriptPath=${0}

# Get current console user details safely in Bash
consoleUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
currentUser=${consoleUser:-UnknownUserName}

currentUserID=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/kCGSSessionUserIDKey :/ { print $3 }')
currentUserHome=$(dscl . -read Users/${currentUser} 2>/dev/null | grep ^NFSHomeDirectory | awk '{print $2}')
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
LogDateFormat="%Y-%m-%d %H:%M:%S"
starttime=$(date +"$LogDateFormat")
LOCAL_LOG_FILE=""			# Add file path to enable local logging, otherwise leave blank
#declare -rA levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
LOGGING="INFO"  #default log level set at info, in main this can be overwritten

### Start Logging 20250728
readonly jamfVarJSSID=$(defaults read "/Library/Managed Preferences/com.mann.jamfuserdata.plist" JSSID 2>/dev/null || echo 0)
readonly JSSURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url 2>/dev/null) \
         hostname=${hostname:-$(hostname)} \
         computername=${computername:-$(scutil --get ComputerName 2>/dev/null)} \
         serialnumber=${serialnumber:-$(ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')} \
         SESSIONID=${jamfVarJSSID}-$RANDOM
### Start logMessage 20260204
getPriorityLevel() {
  case "$1" in
    DEBUG)  echo 0 ;;
    INFO)   echo 1 ;;
    WARN)   echo 2 ;;
    ERROR)  echo 3 ;;
    *)      echo 1 ;; #default fallback
  esac
}
logMessage() {
  [[ -z "$1" ]] && return   #do nothing and exit function if no arguments are passed
  local message="$1"
  local logPriority=${2:-INFO}  #Default to INFO if no second argument is passed
  
  #get numeric priorities using the getPriorityLevel helper function
  local currentPriority=$(getPriorityLevel "$logPriority")
  local minPriority=$(getPriorityLevel "$LOGGING")
  
  if [[ $currentPriority -ge $minPriority ]]; then
      if [[ -z "$LOCAL_LOG_FILE" ]]; then
        echo "$(date +"$LogDateFormat") [$logPriority] - $message"
      else
        echo "$(date +"$LogDateFormat") [$logPriority] - $message" | tee -a "$LOCAL_LOG_FILE"
      fi
  fi
}
log() { #instead of renaming the function, add a caller function for backwards compatibility
  logMessage "$1" "$2"
}
#Add some additional logging functions to allow for single parameter logs with log priority identified in the function name
logINFO() {
  logMessage "$1" INFO
}
logDEBUG() {
  logMessage "$1" DEBUG
}
logWARN() {
  logMessage "$1" WARN
}
logERROR() {
  logMessage "$1" ERROR
}
### End logMessage
### Start runAsUser 20240419
runAsUser() {
  if [[ $currentUser != "loginwindow" ]]; then
    uid=$(id -u "$currentUser")
    launchctl asuser $uid sudo -u $currentUser "$@"
  fi
}
### End runAsUser
#MARK: End Default Header

#LOGGING="WARN"
##LOCAL_LOG_FILE="$currentUserHome/test.log"
#echo "logging level = $LOGGING"
#logMessage "this is a test log message using default priority"
#logMessage "this is a debug level log entry" DEBUG
#logMessage "this is an explicitly INFO level log message" INFO
#logMessage "this is a WARN level" WARN
#logMessage "this is an ERROR level" ERROR
#logMessage "test log"
#
#logMessage "test additional log functions"
#log "test log"
#logWARN "test log WARN"
#logERROR "test log Error"
#logDEBUG "this should not output, unless I set to debug"

####################################################################
### Begin Pass Secure Token
# https://github.com/daveyboymath/Jamf/blob/MacOS/PassSecureToken.sh

# modified by JA on 1/5/23 for our environment
# The end user (who is not currently an admin) has a secure token
# The local admin user does not have secureToken
# modified to get rid of 'Jamf wants to ...' permission dialog on client device - use osascript -e instead of TELL APPLICATION syntax
# per https://community.jamf.com/t5/jamf-pro/quot-jamf-quot-wants-access-to-control-quot-system-events-quot/m-p/140815/highlight/true

# 2026/07/17 JA - this is an enhancement of the Pass secure token script which is intended to generalize the pass secure token process.
# This implementation should handle optional parameters to specify the token holder user token holder password (encrypted) token recipient username and token holder recipient password (encrypted)
# In order to support password decryption, the salt and passphrase matching the password for either parameter must be embedded in the script itself
# If no token holder username is provided, prompt for the username.  if no password provided, prompt for password.
# if both usernames and encrypted passwords are provided then run in silent mode

######### UPDATE THIS WORKFLOW TO REFLECT CURRENT IMPLEMENTATION STRATEGY
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
####### Token Holder #####################
if [[ "$4" != "" ]] && [[ $tokenHolder == "" ]]; then
    tokenHolder=$4
fi
####### Token Holder Password ##############
if [[ "$5" != "" ]] && [[ $tokenHolderPassword == "" ]]; then
    tokenHolderPassword=$5
fi
####### Token Recipient #####################
if [[ "$6" != "" ]] && [[ $tokenRecipient == "" ]]; then
    tokenRecipient=$4
fi
####### Token Recipient Password ##############
if [[ "$7" != "" ]] && [[ $tokenRecipientPassword == "" ]]; then
    tokenRecipientPassword=$5
fi


####### Test for values
if [[ "$tokenHolder" == "" ]] || [[ "$tokenHolderPassword" == "" ]] ; then
    echo "Check parameter values - exiting with error"
    echo "tokenHolder : $tokenHolder"
    echo "tokenHolderPassword : $tokenHolderPassword"
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

LOCAL_LOG_FILE="/Library/Punahou/logs/secureToken.log"     # Add file path to enable local logging, otherwise leave blank
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
    log $(sysadminctl "-secureTokenStatus" $1)
    log "user $1 is Admin $(isAdmin $1)"
}
function promoteUser() {
    #pass in $username
    userName=$1
    if [[ $(isAdmin $userName) == TRUE ]]; then
        log "promote skipped - user is already admin"
        logUserStatus $userName
    else
        log "Promote $userName"
        #Promote currently logged in user
        /usr/sbin/dseditgroup -o edit -a $userName -t user admin
        log "log User status post-promote"
        logUserStatus $userName
    fi
}
function demoteUser() {
    #pass in $username and $alreadyAdmin
    userName=$1
    alreadyAdmin=$2
    if [[ $alreadyAdmin == TRUE ]]; then
        log "skip demote - user was already admin before the run"
    else
        dseditgroup -o edit -d $userName -t user -L admin
        log "demote $userName, log both users status"
        logUserStatus $userName
#        logUserStatus $adminUser
    fi
}
function simpleJamfHelperUtilityOK() {
  if [ ! -z $1 ]; then
    "$jamfHelper" -windowType "utility" -icon $icon -description "$1" -button1 "OK"
  else
    log "simpleJamfHelperUtilityOK failed - no input provided"
    return 1
  fi
}
function promtForUsername() {
    simpleJamfHelperUtilityOK "Please provide a username"
    user=$(/usr/bin/osascript -e 'set the answer to text returned of (display dialog "Please type in your Punahou Password to authorize the patch installation:" default answer "" with hidden answer buttons {"Continue"} default button 1)')
    echo $user
}
##############################################
###  Main 
##############################################

### Handle parameters and define workflow
if [ -z $tokenHolder ]; then
  log "prompt for username of tokenHolder"
  tokenHolder=$(promptForUsername)
  log "tokenHolder is $tokenHolder"
fi