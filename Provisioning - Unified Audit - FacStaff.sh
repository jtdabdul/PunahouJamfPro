#!/bin/bash

# Modified 2026/07/14 by JA - macOS Login Window List v2 profile updated to v3.
# Modified 2026/07/22 by JA - Jamf Connect functionality superceded by Self Service +, remove Jamf Connect from apps to check
# Modified 2026/11/17 by JA - remove Faculty Staff Restrictions v2 (Main deployment), Super Preferences and SUPER disable update notifications from PROFILE_NAMES array 
##################################  Application Check  ###############################
# List of applications to check
appsToCheck=("Google Chrome" "Punahou Self Service" "Safari" "Sophos/Sophos Endpoint")

# Initialize the variable to store the results
appChecks=""

# Initialize the variable to store the results
failedApps=""

# Function to check if an application is installed
function appCheck() {
    local app="${1}"
    if [[ -d "/Applications/${app}.app" ]]; then
        appChecks+="${app}: Available"$'\n'
    else
        appChecks+="${app}: FAILED"$'\n'
        failedApps+="${app}"$'\n'  # Add to failedApps
    fi
}

# Check each application in the list
for app in "${appsToCheck[@]}"; do
  appCheck "$app"
done

# Remove the trailing newline
appChecks=${appChecks%$'\n'}
#failedApps=${failedApps%$'\n'}  # Remove trailing newline from failedApps if needed


################################## Arctic Wolf check ###############################

# Function to search for a process and return true/false
search_process() {
    if pgrep -q "$1"; then
        echo "true"
    else
        echo "false"
    fi
}

# Search for scout-client
scout_client=$(search_process "scout-client")

# Search for scout-desktop
scout_desktop=$(search_process "scout-desktop")

# Prepare the output
output="scout-client: $scout_client
scout-desktop: $scout_desktop"

################################## Config Profile Audit ###############################

# List of profile names to check 
PROFILE_NAMES=(
"App Installers - PPPC and Managed Login Items"
"Cert - GoDaddy Cert"
#"Faculty Staff Restrictions v2 (Main deployment)"
"Google Chrome Enrollment - Staff"
"Jamf Connect Actions Menu v12"
"Jamf Connect License (ex. 2026)"
"Jamf Connect Notifications"
"Jamf Connect w/temp promo v9"
"Jamf Notifications"
"Jamf Remote Assist PPPC"
"macOS Login Window List v3"
"Managed Login Items - Jamf Apps"
"MDM Profile"
"PPPC Canon Uniflow Client Application"
"PPPC Canvas Screen Recorder"
"PPPC Cisco Webex"
"PPPC Wacom bundle"
"PPPC Webex Allow"
"Privacy Preferences Policy Control"
"Privacy Profile Jamf Processes - AppleEvent"
"PunahouSchool Wifi - Medium Sized group"
"Require Filevault"
"Sophos Endpoint"
#"SUPER auto update settings"
#"SUPER disable update notifications"
#"SUPER preferences"
"System Extension Google Drive"
)


# Function to check if a profile exists
check_profile() {
    local profile_name="$1"
    profiles -C -v | awk -F: '/attribute: name/{print $NF}' | grep -qF "$profile_name"
    return $?
}

all_found=true
result_message=""

# Check each profile in the list
for profile in "${PROFILE_NAMES[@]}"; do
    if check_profile "$profile"; then
        result_message="${result_message}Profile '$profile' found."$'\n'
    else
        result_message="${result_message}Profile '$profile' NOT FOUND."$'\n'
        all_found=false
    fi
done

# Final result
if $all_found; then
    final_message="Success: All profiles were found."$'\n\n'"${result_message}"
#    icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarFavoritesIcon.icns"
else
    final_message="Fail: Some profiles were not found."$'\n\n'"${result_message}"
#    icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns"
fi

echo "###############################################################################" > /Users/Shared/jamfDaemons.txt
echo "##############################  FAC/STAFF AUDIT  ##############################" >> /Users/Shared/jamfDaemons.txt
echo "                                ITEMS TO CHECK" >> /Users/Shared/jamfDaemons.txt
#Verify Hostname
echo "Hostname:" >> /Users/Shared/jamfDaemons.txt
hostname >> /Users/Shared/jamfDaemons.txt
echo -e "\n" >> /Users/Shared/jamfDaemons.txt
#Verify SecureToken status
secureTokenStatus=$(sysadminctl -secureTokenStatus "hala" 2>&1)
if [[ $secureTokenStatus == *"DISABLED"* ]]; then
    echo -e "\n" >> /Users/Shared/jamfDaemons.txt
    echo "Secure Token Status:" >> /Users/Shared/jamfDaemons.txt
    echo "$secureTokenStatus" >> /Users/Shared/jamfDaemons.txt
fi
#Verify MacSecureprint
printers=$(lpstat -p -d | grep -i "MacSecureprint")
if [ -z "$printers" ]; then
    echo -e "\n" >> /Users/Shared/jamfDaemons.txt
    echo "MACSECUREPRINT not found" >> /Users/Shared/jamfDaemons.txt
fi
# Check if Arctic Wolf processes are not running
if [ "$scout_client" = "FALSE" ] || [ "$scout_desktop" = "FALSE" ]; then
    echo -e "\n" >> /Users/Shared/jamfDaemons.txt
    echo "ARCTIC WOLF processes not running" >> /Users/Shared/jamfDaemons.txt
fi
# Application check -- Write output only if there are failed applications
if [[ -n "$failedApps" ]]; then
    echo -e "\n" >> /Users/Shared/jamfDaemons.txt
    echo "FAILED APPLICATION INSTALLATIONS:" >> /Users/Shared/jamfDaemons.txt
    echo "$failedApps" >> /Users/Shared/jamfDaemons.txt
fi

# Config Profiles check -- Write output only for Config Profiles not found
# Initialize result variable
result_message2=""

# Check each profile in the list
for profile in "${PROFILE_NAMES[@]}"; do
    if check_profile "$profile"; then
        continue  # Skip found profiles
    else
        result_message2="${result_message2}Profile '$profile' NOT FOUND."$'\n'
    fi
done

# Final output
if [[ -n $result_message2 ]]; then
    echo -e "\n" >> /Users/Shared/jamfDaemons.txt
    echo "CONFIGURATION PROFILES NOT FOUND:" >> /Users/Shared/jamfDaemons.txt
    echo -e "$result_message2" >> /Users/Shared/jamfDaemons.txt
fi
echo "###############################################################################" >> /Users/Shared/jamfDaemons.txt
echo -e "\n" >> /Users/Shared/jamfDaemons.txt
echo -e "\n" >> /Users/Shared/jamfDaemons.txt

echo "############################  FULL AUDIT DETAILS  #############################" >> /Users/Shared/jamfDaemons.txt

#Verify Jamf Daemons running
launchctl list | grep jamf >> /Users/Shared/jamfDaemons.txt
echo -e "\n" >> /Users/Shared/jamfDaemons.txt
#Verify Hostname
echo "Hostname:" >> /Users/Shared/jamfDaemons.txt
hostname >> /Users/Shared/jamfDaemons.txt
echo -e "\n" >> /Users/Shared/jamfDaemons.txt
#Verify Secure Token passed to hala
echo "Secure Token Status:" >> /Users/Shared/jamfDaemons.txt
sysadminctl -secureTokenStatus "hala" >> /Users/Shared/jamfDaemons.txt 2>&1
echo -e "\n" >> /Users/Shared/jamfDaemons.txt
#Verify installed printers
echo "Installed Printers:" >> /Users/Shared/jamfDaemons.txt
lpstat -p -d >> /Users/Shared/jamfDaemons.txt
echo -e "\n" >> /Users/Shared/jamfDaemons.txt
#Verify Arctic Wolf processes running
echo "Arctic Wolf Processes running:" >> /Users/Shared/jamfDaemons.txt
echo "$output" >> /Users/Shared/jamfDaemons.txt
open "/Users/Shared/jamfDaemons.txt"

# Write Application check results to file
echo -e "\n" >> /Users/Shared/jamfDaemons.txt
echo "###########################  Application Check Results  ###########################" >> /Users/Shared/jamfDaemons.txt
echo "$appChecks" >> /Users/Shared/jamfDaemons.txt

# Write Config Profile Audit results to file
echo -e "\n" >> /Users/Shared/jamfDaemons.txt
echo "#########################  Config Profile Check Results  ##########################" >> /Users/Shared/jamfDaemons.txt
echo "$final_message" >> /Users/Shared/jamfDaemons.txt
echo "#############################  END OF AUDIT DETAILS  ##############################" >> /Users/Shared/jamfDaemons.txt
open "/Users/Shared/jamfDaemons.txt"

exit 0