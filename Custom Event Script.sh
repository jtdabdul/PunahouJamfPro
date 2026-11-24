#!/bin/bash
# Display NameDisplay name for the script
# Custom Event Script
# CategoryCategory to add the script to
# Custom Deployment
# InformationInformation to display to the administrator when the script is run
# NotesNotes to display about the script (e.g., who created it and when it was created)
# created on 2021-05-20 by JA
# https://www.javatpoint.com/bash-split-string
# Script takes comma separated list of values in Parameter 4 and calls the Custom Event Triggers for each in order.
# Input can be 1 string, up to X strings (up to character limit of 255) - if more custom event triggers are needed, simply call this script again for another 255 characters
# Empty Parameter 4 will return error.
# Parameter values which do not match Custom Event Triggers fail silently.
# Parameter values which match Custom Event Triggers but are for policies out of scope for client also fail silently.

triggers=($4)
jamf=$(which jamf)

if [ -z "$triggers" ]
then
	echo "No parameter value provided: exit with failure"
	exit 1;
fi

# Set comma as the delimiter
IFS=','

#Read the split words into an array based on space delimiter
read -a strarr <<< "$triggers"

#Count the total words
echo "There are ${#strarr[*]} words in the text."

# Print each value of the array by using the loop
for val in "${strarr[@]}";
do
  #printf "$val\n"
  echo "$jamf policy -event $val"
  $jamf policy -event $val
done
exit 0