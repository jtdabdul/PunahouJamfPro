#!/bin/bash
#write out the script arguments for Apple's Loops.sh to /private/var/tmp/com.loops.launch.signal.manual

# garageband-essential | logic-essential | mainstage-essential			Essential packages by app
# garageband-optional | logic-optional | mainstage-optional				Optional packages by app
# garageband-all | logic-all | mainstage-all							All packages by app
# all																	All packages
# none																	No packages
# arguments in JAMF policy use positional parameters 
#	$1	Mount point of the target drive
#	$2	Computer name
#	$3	Username, specifically:
#		-If the script is run with a login or logout policy—Username of the account used to log in or out of the computer
#		-If the script is run from Self Service—Username of the account used to logged in to Self Service
######
#	$4	TYPE

#handle argument
if [[ "$4" != "" ]] && [[ $TYPE == "" ]]; then
    TYPE=$4
else
    #default value - garageband-all
    TYPE="-d garageband-all -v -i"
  
fi

#overwrites file if it already exists
echo $TYPE > /private/var/tmp/com.loops.launch.signal.manual

exit 0
