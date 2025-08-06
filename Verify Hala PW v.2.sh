#!/bin/bash

####### New 2025 Hala PW ##################
if [[ "$4" != "" ]] && [[ $newPW == "" ]]; then
	newPW=$4
fi
####### Old 2024 Hala PW ##################
if [[ "$5" != "" ]] && [[ $oldPW == "" ]]; then
	oldPW=$5
fi
####### Old Covid Hala PW ##################
if [[ "$6" != "" ]] && [[ $oldCovidPW == "" ]]; then
	oldCovidPW=$6
fi
##############################################
###  Environment Variables
##############################################
salt="ecb239fd67940f87"
passphrase="e021a9f3b71ad886d6febdfa"
##############################################
oldsalt="3c6b9b530cc0ee77"
oldpassphrase="2ded5894d7f55f2e7dfa575b"
##############################################
oldcovidsalt="0310e003bc2d4e20"
oldcovidpassphrase="b84f73f0a5ded5e473a83bc7"
##############################################

##############################################
###  Functions
##############################################
# Include DecryptString() with your script to decrypt the password sent by the JSS
# The 'Salt' and 'Passphrase' values would be present in the script
function DecryptString() {
	# Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
	# echo "${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "${2}" -k "${3}"
	# add args to openssl command to handle Ventura 2023/01/25 by JA
	echo "${1}" | /usr/bin/openssl enc -md md5 -aes256 -d -a -A -S "${2}" -k "${3}"
}

newpassword=$(DecryptString "$newPW" "$salt" "$passphrase")
oldpassword=$(DecryptString "$oldPW" "$oldsalt" "$oldpassphrase")
covidpassword=$(DecryptString "$oldCovidPW" "$oldcovidsalt" "$oldcovidpassphrase")


#Define the username and password
USERNAME="hala"
PASSWORD="$newpassword"
OLDPASSWORD="$oldpassword"
OLDCOVIDPASSWORD="$covidpassword"

#Verify the password
if dscl /Local/Default authonly "$USERNAME" "$PASSWORD" &>/dev/null; then 
	RESULT="25"
elif dscl /Local/Default authonly "$USERNAME" "$OLDPASSWORD" &>/dev/null; then 
	RESULT="24"
elif dscl /Local/Default authonly "$USERNAME" "$OLDCOVIDPASSWORD" &>/dev/null; then 
	RESULT="20"
else
    RESULT="N/A"
fi

#Define the folder and filename to write the result
OUTPUT_FOLDER="/Library/Punahou"
OUTPUT_FILENAME="pw_verify.txt"

#Write the result to the file
echo "$RESULT" > "$OUTPUT_FOLDER/$OUTPUT_FILENAME"

#Print result in JAMF log
if [[ "$RESULT" == "N/A" ]]; then
    echo "No valid password matched. Password verification failed."
else
    echo "hala password year: $RESULT"
fi
####### Jamf Script object
### General
# Display NameDisplay name for the script
# Verify Hala PW v.2
# CategoryCategory to add the script to
# Maintenance
# InformationInformation to display to the administrator when the script is run
# Verifying hala password v2
# NotesNotes to display about the script (e.g., who created it and when it was created)
# Created Verify Hala PW v.2 from Verify Hala PW v.Mar 6, 2024 on 2025/08/06 by AM.
# Comparing the hala password to determine which one is which.
# Contains Hala passwords from 2025, 2024 and 2020.
### Options
# PriorityPriority to use for running the script in relation to other actions
# After
# Parameter LabelsLabels to use for script parameters. Parameters 1 through 3 are predefined as mount point, computer name, and username
# Parameter 4
# New Hala PW Encrypted String
# Parameter 5
# Old Hala PW Encrypted String
# Parameter 6
# Old Covid Hala PW Encrypted String
####### End Jamf script object
