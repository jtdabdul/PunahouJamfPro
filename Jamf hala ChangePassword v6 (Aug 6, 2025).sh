#!/bin/bash

###############################################
###  Handle Parameters
###############################################

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
### Variables
##############################################
username="hala"
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
#newPW
newpassword=$(DecryptString "$newPW" "$salt" "$passphrase")
#echo $newpassword
#
#oldPW
oldpassword=$(DecryptString "$oldPW" "$oldsalt" "$oldpassphrase")
#echo $oldpassword
#
#oldCovidPW
oldcovidpassword=$(DecryptString "$oldCovidPW" "$oldcovidsalt" "$oldcovidpassphrase")
#echo $oldcovidpassword

#Checking if hala password has already been updated
if dscl /Local/Default authonly "$username" "$newpassword" &>/dev/null; then
	echo "No action needed. Password is already updated to 2025 hala password."
	exit 0
fi

#Updating old hala password to new 2025 Hala password
/usr/local/bin/jamf changePassword -username $username -password "$newpassword" -oldPassword "$oldpassword"
if [[ $? -ne 0 ]]; then
	echo "First attempt with old 2024 hala password failed, trying old COVID hala password..."
	/usr/local/bin/jamf changePassword -username $username -password "$newpassword" -oldPassword "$oldcovidpassword"
	if [[ $? -ne 0 ]]; then
		echo "Password change failed with both old hala passwords."
		exit 1
	else
		echo "Password changed using old COVID hala password."
	fi
else
	echo "Password changed using old 2024 hala password."
fi
#
####### Jamf Script object
### General
# Display NameDisplay name for the script
# Jamf hala ChangePassword v6 (Aug 6, 2025)
# CategoryCategory to add the script to
# Maintenance
# InformationInformation to display to the administrator when the script is run
# Changing hala password v6
# NotesNotes to display about the script (e.g., who created it and when it was created)
# Created test Jamf hala ChangePassword v6 (July 14, 2025) from Jamf hala ChangePassword vOkra to newpw (Mar 6, 2024) on 2025/08/06 by AM to change hala 2024 password to new hala 2025 password. 
# If the 2024 Hala password fails to change the Hala password, it will use the previous Hala passwords to change the Hala password to the 2025 Hala password.  
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