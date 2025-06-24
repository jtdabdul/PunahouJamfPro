#!/bin/bash
#write out the script arguments for Apple's Loops.sh to /private/var/tmp/com.loops.launch.signal.manual
# USAGE
#	Loops.sh [-d download] [-v] [-x] [-p path] [-i] [-l launch] [-s|-r] [-h]
#
# OPTIONS
# 	-d download, optional
# 		<label> ...														package type to download
# 		garageband-essential | logic-essential | mainstage-essential	Essential packages by app
# 		garageband-optional | logic-optional | mainstage-optional		Optional packages by app
# 		garageband-all | logic-all | mainstage-all						All packages by app
# 		all																All packages for all apps
# 		none															No packages
# 	-f force package download, optional
#	-v verify packages, optional
# 		Check the validity and trust of each packages signature
#	-x suppress curl output when downloading packages, optional
# 	-p path, optional
# 		Save the loop packages to path OR install packages from path
# 		Packages are saved to /private/var/tmp/Packages if -p path is not passed
# 	-i install, optional
# 		Packages are installed if -i is passed
# 		Command is run with administrator or root user privileges
#	-l launch, optional
#		<label> ...								launch after completion
#		garageband | logicpro | mainstage		Application name
#	-s|-r statistics, optional, standalone
#		Number of installed packages by category and number of packages available by category
#		-r forces a recheck of all installed packages
#		Only use standalone when running Loops, not to be passed with other parameters
# 	-h help
#
# 	These options can be passed in the text file, com.loops.launch.signal.manual
# 	The first line of the text file should contain the options as they would be typed on the command line, e.g. -d garageband-essential
# 	The text file can be located in the same directory as Loops.sh or in /private/var/tmp
#
#	A mobileconfig profile can be used to pass options to Loops.sh
#	The mobileconfig key, Parameters, contains the options as they would be entered on the command line, e.g. -d garageband-essential
#	The mobileconfig profile takes precedence over all other option passing methods

##################
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
  echo "parameter found.  using value: $4"
  TYPE=$4
else
  #default value - garageband-all
  echo "No parameter found - using default -d garageband-all -v -i"
  TYPE="-d garageband-all -v -i"
fi

#overwrites file if it already exists
echo $TYPE > /private/var/tmp/com.loops.launch.signal.manual

exit 0
