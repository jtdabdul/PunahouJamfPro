#!/bin/bash --norc

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin: export PATH


# set -xv; exec 1>>"/private/var/tmp/LoopsTraceLog" 2>&1

#----------------------------------------------------------------------------------------------------------------------------------

#	Loops.sh
#	Copyright (c) 2022-25 Apple Inc.
#	
#	
#	This script downloads and optionally installs GarageBand, Logic Pro, or MainStage loop and instrument packages.
#	Requires curl version 7.52.0 or later.

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

#
# DESCRIPTION
# 	No options –
# 	 Downloads essential packages when:
# 		• GarageBand, Logic Pro, or MainStage are NOT installed
# 	 Downloads optional packages and ,if needed, essential packages when:
# 		• GarageBand, Logic Pro, or MainStage are installed
# 	 Downloads AND installs essential packages when:
# 		• GarageBand Logic Pro, or MainStage are NOT installed
# 		• Command is run with administrator or root user privileges
# 	 Downloads AND installs optional packages and, if needed, essential packages when:
# 		• GarageBand, Logic Pro, or MainStage are installed
# 		• Command is run with administrator or root user privileges
#
# 	Use options to download or install specific package types.

#
# APPLE INC.
# SOFTWARE LICENSE AGREEMENT FOR LOOPS SOFTWARE

# PLEASE READ THIS SOFTWARE LICENSE AGREEMENT ("LICENSE") CAREFULLY BEFORE USING THE APPLE SOFTWARE
# (DEFINED BELOW). BY USING THE APPLE SOFTWARE, YOU ARE AGREEING TO BE BOUND BY THE TERMS OF THIS
# LICENSE. IF YOU DO NOT AGREE TO THE TERMS OF THIS LICENSE, DO NOT USE THE APPLE SOFTWARE.

# 1. General.
# The Apple software, sample or example code, utilities, tools, documentation,
# interfaces, content, data, and other materials accompanying this License, whether on disk, print
# or electronic documentation, in read only memory, or any other media or in any other form,
# (collectively, the "Apple Software") are licensed, not sold, to you by Apple Inc. ("Apple") for
# use only under the terms of this License.  Apple and/or Apple’s licensors retain ownership of the
# Apple Software itself and reserve all rights not expressly granted to you. The terms of this
# License will govern any software upgrades provided by Apple that replace and/or supplement the
# original Apple Software, unless such upgrade is accompanied by a separate license in which case
# the terms of that license will govern.

# 2. Permitted License Uses and Restrictions.
# A. Service Provider License. A company delivering Apple Professional Services on Apple’s
# behalf, or with Apple’s authorization, a "Service Provider". Subject to the terms and conditions 
# of this License, if you are in good standing under an Apple authorized agreement regarding
# the delivery of Apple Professional Services, and are providing the Apple Software to a customer
# end-user under contract from Apple, you are granted a limited, non-exclusive license to install
# and use the Apple Software on Apple-branded computers for internal use within the customer
# end-user’s company, institution or organization. You may make only as many internal use copies
# of the Apple Software as reasonably necessary to use the Apple Software as permitted under this
# License and distribute such copies only to your employees and contractors whose job duties require
# them to so use the Apple Software; provided that you reproduce on each copy of the Apple Software
# or portion thereof, all copyright or other proprietary notices contained on the original.

# B. End-User License. Subject to the terms and conditions of this License, you are granted a
# limited, non-exclusive license to install and use the Apple Software on Apple-branded computers
# for internal use within your company, institution or organization. You may make only as many
# internal use copies of the Apple Software as reasonably necessary to use the Apple Software as
# permitted under this License and distribute such copies only to your employees and contractors
# whose job duties require them to so use the Apple Software; provided that you reproduce on each
# copy of the Apple Software or portion thereof, all copyright or other proprietary notices
# contained on the original.

# C. Other Use Restrictions. The grants set forth in this License do not permit you to, and you
# agree not to, install, use or run the Apple Software on any non-Apple-branded computer, or to
# enable others to do so. Except as otherwise expressly permitted by the terms of this License or as
# otherwise licensed by Apple: (i) only one user may use the Apple Software at a time; and (ii) you
# may not make the Apple Software available over a network where it could be run or used by multiple
# computers at the same time. You may not rent, lease, lend, trade, transfer, sell, sublicense or
# otherwise redistribute the Apple Software or exploit any services provided by or through the Apple
# Software in any unauthorized way.

# D. No Reverse Engineering; Limitations. You may not, and you agree not to or to enable others to,
# copy (except as expressly permitted by this License), decompile, reverse engineer, disassemble,
# attempt to derive the source code of, decrypt, modify, create derivative works of the Apple
# Software or any services provided by or through the Apple Software or any part thereof (except as
# and only to the extent any foregoing restriction is prohibited by applicable law).

# E. Compliance with Laws. You agree to use the Apple Software in compliance with all applicable
# laws, including local laws of the country or region in which you reside or in which you download
# or use the Apple Software.

# 3. No Transfer.  Except as otherwise set forth herein, you may not transfer this Apple Software
# without Apple’s express prior written approval.  All components of the Apple Software are provided
# as part of a bundle and may not be separated from the bundle and distributed as standalone
# applications.

# 4. Termination. This License is effective until terminated. Your rights under this License will
# terminate automatically or cease to be effective without notice from Apple if you fail to comply
# with any term(s) of this License.  In addition, Apple reserves the right to terminate this License
# if a new version of Apple's operating system software or the Apple Software is released which is
# incompatible with this version of the Apple Software.  Upon the termination of this License, you
# shall cease all use of the Apple Software and destroy all copies, full or partial, of the Apple
# Software.  Section 2C, 2D, and 4 through 10 of this License shall survive any termination.

# 5. Disclaimer of Warranties.
# A.  YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT, TO THE EXTENT PERMITTED BY APPLICABLE LAW, USE OF
# THE APPLE SOFTWARE AND ANY SERVICES PERFORMED BY OR ACCESSED THROUGH THE APPLE SOFTWARE IS AT YOUR
# SOLE RISK AND THAT THE ENTIRE RISK AS TO SATISFACTORY QUALITY, PERFORMANCE, ACCURACY AND
# EFFORT IS WITH YOU.

# B.  TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE APPLE SOFTWARE IS PROVIDED "AS IS" AND
# "AS AVAILABLE", WITH ALL FAULTS AND WITHOUT WARRANTY OF ANY KIND, AND APPLE AND APPLE'S LICENSORS
# (COLLECTIVELY REFERRED TO AS "APPLE" FOR THE PURPOSES OF SECTIONS 5 AND 6) HEREBY DISCLAIM ALL
# WARRANTIES AND CONDITIONS WITH RESPECT TO THE APPLE SOFTWARE, EITHER EXPRESS, IMPLIED OR
# STATUTORY, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES AND/OR CONDITIONS OF
# MERCHANTABILITY, SATISFACTORY QUALITY, FITNESS FOR A PARTICULAR PURPOSE, ACCURACY, QUIET
# ENJOYMENT, AND NON-INFRINGEMENT OF THIRD PARTY RIGHTS.

# C.  APPLE DOES NOT WARRANT AGAINST INTERFERENCE WITH YOUR ENJOYMENT OF THE APPLE SOFTWARE, THAT
# THE FUNCTIONS CONTAINED IN, OR SERVICES PERFORMED OR PROVIDED BY, THE APPLE SOFTWARE WILL MEET
# YOUR REQUIREMENTS, THAT THE OPERATION OF THE APPLE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE,
# THAT ANY SERVICES WILL CONTINUE TO BE MADE AVAILABLE, THAT THE APPLE SOFTWARE WILL BE COMPATIBLE
# OR WORK WITH ANY THIRD PARTY SOFTWARE, APPLICATIONS OR THIRD PARTY SERVICES, OR THAT DEFECTS IN
# THE APPLE SOFTWARE WILL BE CORRECTED. INSTALLATION OF THIS APPLE SOFTWARE MAY AFFECT THE
# AVAILABILITY AND USABILITY OF THIRD PARTY SOFTWARE, APPLICATIONS OR THIRD PARTY SERVICES, AS WELL
# AS APPLE PRODUCTS AND SERVICES.

# D.  YOU FURTHER ACKNOWLEDGE THAT THE APPLE SOFTWARE IS NOT INTENDED OR SUITABLE FOR USE IN
# SITUATIONS OR ENVIRONMENTS WHERE THE FAILURE OR TIME DELAYS OF, OR ERRORS OR INACCURACIES IN THE
# CONTENT, DATA OR INFORMATION PROVIDED BY, THE APPLE SOFTWARE COULD LEAD TO DEATH, PERSONAL INJURY,
# OR SEVERE PHYSICAL OR ENVIRONMENTAL DAMAGE, INCLUDING WITHOUT LIMITATION THE OPERATION OF NUCLEAR
# FACILITIES, AIRCRAFT NAVIGATION OR COMMUNICATION SYSTEMS, AIR TRAFFIC CONTROL, LIFE SUPPORT OR
# WEAPONS SYSTEMS.

# E.  NO ORAL OR WRITTEN INFORMATION OR ADVICE GIVEN BY APPLE OR AN APPLE AUTHORIZED REPRESENTATIVE
# SHALL CREATE A WARRANTY. SHOULD THE APPLE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE ENTIRE COST OF
# ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

# 6. Limitation of Liability. TO THE EXTENT NOT PROHIBITED BY APPLICABLE LAW, IN NO EVENT SHALL
# APPLE BE LIABLE FOR PERSONAL INJURY, OR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES
# WHATSOEVER, INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, CORRUPTION OR LOSS OF
# DATA, FAILURE TO TRANSMIT OR RECEIVE ANY DATA OR INFORMATION, BUSINESS INTERRUPTION OR ANY OTHER
# COMMERCIAL DAMAGES OR LOSSES, ARISING OUT OF OR RELATED TO YOUR USE OR INABILITY TO USE THE APPLE
# SOFTWARE OR ANY THIRD PARTY SOFTWARE, APPLICATIONS, OR SERVICES IN CONJUNCTION WITH THE APPLE
# SOFTWARE, HOWEVER CAUSED, REGARDLESS OF THE THEORY OF LIABILITY (CONTRACT, TORT OR OTHERWISE) AND
# EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. SOME JURISDICTIONS DO NOT ALLOW
# THE EXCLUSION OR LIMITATION OF LIABILITY FOR PERSONAL INJURY, OR OF INCIDENTAL OR CONSEQUENTIAL
# DAMAGES, SO THIS LIMITATION MAY NOT APPLY TO YOU. In no event shall Apple's total liability to you
# for all damages (other than as may be required by applicable law in cases involving personal
# injury) exceed the amount of fifty dollars ($50.00). The foregoing limitations will apply even if
# the above stated remedy fails of its essential purpose.

# 7. Export Control. You may not use or otherwise export or re-export the Apple Software except as
# authorized by United States law and the laws of the jurisdiction(s) in which the Apple Software
# was obtained. In particular, but without limitation, the Apple Software may not be exported or re-
# exported (a) into any U.S. embargoed countries or (b) to anyone on the U.S. Treasury Department's
# list of Specially Designated Nationals or the U.S. Department of Commerce Denied Person's List or
# Entity List. By using the Apple Software, you represent and warrant that you are not located in
# any such country or on any such list. You also agree that you will not use the Apple Software for
# any purposes prohibited by United States law, including, without limitation, the development,
# design, manufacture or production of missiles, nuclear, chemical or biological weapons.

# 8. Government End Users. The Apple Software and related documentation are "Commercial Items", as
# that term is defined at 48 C.F.R. §2.101, consisting of "Commercial Computer Software" and
# "Commercial Computer Software Documentation", as such terms are used in 48 C.F.R. §12.212 or 48
# C.F.R. §227.7202, as applicable. Consistent with 48 C.F.R. §12.212 or 48 C.F.R. §227.7202-1
# through 227.7202-4, as applicable, the Commercial Computer Software and Commercial Computer
# Software Documentation are being licensed to U.S. Government end users (a) only as Commercial
# Items and (b) with only those rights as are granted to all other end users pursuant to the terms
# and conditions herein. Unpublished-rights reserved under the copyright laws of the United States.

# 9. Controlling Law and Severability. This License will be governed by and construed in accordance
# with the laws of the State of California, excluding its conflict of law principles. This License
# shall not be governed by the United Nations Convention on Contracts for the International Sale of
# Goods, the application of which is expressly excluded. If for any reason a court of competent
# jurisdiction finds any provision, or portion thereof, to be unenforceable, the remainder of this
# License shall continue in full force and effect.

# 10. Complete Agreement; Governing Language. This License constitutes the entire agreement between
# you and Apple relating to the use of the Apple Software licensed hereunder and supersedes all
# prior or contemporaneous understandings regarding such subject matter. No amendment to or
# modification of this License will be binding unless in writing and signed by Apple.

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software to
# use, copy, and distribute copies, including within commercial software, subject to the following
# conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial
# portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Loops Rev. 092519


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

# A --------------------------------------------------------------------------------------------------------------------------------
function auto_Configure() {
	# update status codes (_STATUSCODE) for the appropriate package download/install if nothing has been passed on the command line
	
	local downloadBit=""
	local pathBit=""
	local installBit=""
	local verifyBit=""
	local launchBit=""
	local forceBit=""
	local suppressBit=""
	local downloadOptArg=""
	
	decode_StatusCode_FDN
	
	# get the current opt arg value
	downloadOptArg="${_DOWNLOADOPTARG}"
	
	# if nothing passed on the command line
	if [[ "${downloadBit}" -eq "0" && "${pathBit}" -eq "0" && "${installBit}" -eq "0" && -z "${_DOWNLOADSWITCH}" ]]; then
		# if running as root
		if [[ "${EUID}" -eq "0" ]]; then
			installBit="1"
		fi
		
		# if GarageBand is installed and launched
		if [[ -e "/Applications/GarageBand.app" && -e '/Library/Application Support/GarageBand' ]]; then
			downloadBit="1"
			downloadOptArg="garageband-${kOPTIONAL}"
		fi
		
		# if Logic is installed and not launched
		if [[ -e "/Applications/Logic Pro X.app" && ! -e '/Library/Application Support/Logic' ]]; then
			downloadBit="4"
			downloadOptArg="logic-${kESSENTIAL}"
		fi
		
		# if Logic is installed and launched
		if [[ -e "/Applications/Logic Pro X.app" && -e '/Library/Application Support/Logic' ]]; then
			downloadBit="5"
			downloadOptArg="logic-${kOPTIONAL}"
		fi
		
		# if MainStage is installed and not launched
		if [[ -e "/Applications/MainStage.app" && ! -e '/Library/Application Support/Logic' ]]; then
			downloadBit="9"
			downloadOptArg="mainstage-${kESSENTIAL}"
		fi
		
		# if MainStage is installed and launched
		if [[ -e "/Applications/MainStage.app" && -e '/Library/Application Support/Logic' ]]; then
			downloadBit="A"
			downloadOptArg="mainstage-${kOPTIONAL}"
		fi
		
		# if all exist
		if [[ -e "/Applications/GarageBand.app" && -e "/Applications/Logic Pro X.app" && -e "/Applications/MainStage.app" ]]; then
			downloadBit="2"
			downloadOptArg="all"
		fi
		
		# update the status code
		_STATUSCODE="${downloadBit}${pathBit}${installBit}${verifyBit}${launchBit}${forceBit}"
		
		# update optarg type
		_DOWNLOADOPTARG="${downloadOptArg}"
	fi
}
function auto_DetectPlistURL() {
	# locates and returns the current package plist URL from Apple's servers
	# $1: seed plist URL
	# returns: current plist URL
	
	local plistType=""
	local plistVers=""
	local increaseCounterBy=""
	local index=""
	local end=""
	local foundPlistURL=""
	local downloadPlistURL=""
	local response=""
	local returnCode=""
	
	foundPlistURL="$1"
	plistType="${foundPlistURL##*/}"
	plistVers="$( tr -d -c 0-9 <<< "${plistType}" )"
	plistType="${plistType%"${plistVers}"*}" # remove plist version from plistType = garageband, logic, or mainstage
	index="${plistVers}"
	increaseCounterBy="25" # set the look ahead
	end="$((index+increaseCounterBy))"
	returnCode="1"
	
	# loop until done
	until [[ "${returnCode}" -eq "0" ]]; do
		downloadPlistURL="${kAPPLEURL}/${kMS3}/${plistType}${index}.plist"
		
		# check for plist availability
		response="$( curl --location "${downloadPlistURL}" \
		--head \
		--silent \
		--output  /dev/null \
		--write-out '%{http_code}' )"
		
		# if a plist was found
		if [[ "${response}" == *"200"* ]]; then
			# generate the plist URL
			foundPlistURL="${1%%"${plistVers}"*}${index}${1##*"${plistVers}"}"
			
			# increment to look for another plist
			end="$((index+increaseCounterBy))"
		fi
		
		# if done checking for plists
		if [[ "${end}" -eq "${index}" ]]; then
			returnCode="0"
		fi
		
		# increment plist version
		((index++))
	done

	# return
	echo "${foundPlistURL}"
}

# C --------------------------------------------------------------------------------------------------------------------------------
function check_Freespace() {
	# reports the download and install disks freespace
	
	local diskFreeSpace=""
	local convertedValue=""
	local downloadBit=""
	local pathBit=""
	local installBit=""
	local verifyBit=""
	local launchBit=""
	local forceBit=""
	local suppressBit=""
	local totalSize=""
	local msgTxt=""
	local prefsFile=""
	local index=""
	local appName=""
	local returnCode=""
	
	msgTxt="download and install ${kESSENTIAL} packages"
	prefsFile="${kPREFSFILE}"
	
	# if using external path
	if [[ "${pathBit}" -eq "1" ]]; then
		prefsFile="${_SAVEPATH}/.${kPREFSFILE##*/}"
	fi
	
	decode_StatusCode_FDN
	
	# get the app name
	case "${downloadBit}" in
	7) # GarageBand
		index="0"
		;;
	8) # Logic Pro
		index="1"
		;;
	B) # MainStage
		index="2"
		;;
	esac
	
	appName="${_appName_a[index]} "
	
	# get save path disk freespace
	diskFreeSpace="$( get_Freespace "${_SAVEPATH}" )" # in Bytes
	returnCode="$?"
	
	# convert to GB
	convertedValue="$( convert_FromBytes2HumanReadable_FDN "${diskFreeSpace}" )"

	go_NoGo_FDN "${returnCode}" "diskFreeSpace=${diskFreeSpace}B (${convertedValue})." "Syntax error in expression for diskFreeSpace."

	# get download and pad for install essentials size
	totalSize="$((_INSTALLPADSIZE+_DOWNLOADSIZEESSENTIAL))"
	returnCode="$?"
	
	# get freespace values
	freespace_Total
	freespace_Download
	freespace_Install
	
	write_2Log_FDN "${_LOGTXT}"
}

# D --------------------------------------------------------------------------------------------------------------------------------
function declare_Constants() {
	local versStamp=""
	
	# define version number
	versStamp="Version 2.0.1 (1A6), 06-05-2025"
	
	kPID="$$"
	kSCRIPTVERS="${versStamp:8:${#versStamp}-20}"
	kSCRIPTPATH="${BASH_SOURCE[0]}"
	kSCRIPTNAME="${kSCRIPTPATH##*/}"
	kSCRIPTDATE="${versStamp##* }"
	kAPPLEURL="http://audiocontentdownload.apple.com"
	kMS3="lp10_ms3_content_2016"
	kURLCONFIGFILE="${kVARTMP}/${kREVERSEDNS}.curlrc.txt"
	kCDNURLCONFIGFILE="${kVARTMP}/${kREVERSEDNS}.CDN.curlrc.txt"
	kLOGFILE="${kLOGPATH}/${kSCRIPTNAME%.*}-$( date +"%Y-%m-%d_%H%M%S" ).log"
	kDOWNLOADEDLOOPSPLIST="${kVARTMP}/${kREVERSEDNS}.downloaded.loops.plist"
	kCURLVERS="$( curl --version | head -n 1 | awk '{print $2}' )"
	kCURLVERSMIN="7.52.0"
	
	declare -r kSCRIPTVERS
	declare -r kSCRIPTPATH
	declare -r kSCRIPTNAME
	declare -r kSCRIPTDATE
	declare -r kAPPLEURL
	declare -r kMS3
	declare -r kURLCONFIGFILE
	declare -r kCDNURLCONFIGFILE
	declare -r kLOGFILE
	declare -r kDOWNLOADEDLOOPSPLIST
	declare -r kCURLVERS
	declare -r kCURLVERSMIN
}
function declare_Globals() {
	# $1: parameters
	
	_PREFLIGHTLOGTXT=""
	_ERRTRACKMSG=""
	_GARAGEBANDDOWNLOADPLISTNAME="garageband1047.plist"
	_LOGICDOWNLOADPLISTNAME="logicpro1100.plist"
	_MAINSTAGEDOWNLOADPLISTNAME="mainstage362.plist"
	_DOWNLOADSIZEESSENTIAL="0"
	_INSTALLSIZEESSENTIAL="0"
	_DOWNLOADSIZEOPTIONAL="0"
	_INSTALLSIZEOPTIONAL="0"
	_STATUSCODE="000000"
	_PKGCOUNT="0"
	_PKGFILEPATH=""
	_SAVEPATH="${kVARTMP}/Packages"
	_DOWNLOADOPTARG="garageband-${kESSENTIAL}"
	_DOWNLOADSWITCH=""
	_STATUSCODELASTRUN=""
	_URLTYPE=""
	_URLCONFIGFILE="${kURLCONFIGFILE}"
	_INSTALLPADSIZE=""
	_PARAMS="$*"
	
	# if called from Jamf Pro
	if [[ "${_MDMINFO}" == *"Jamf"* && "${1:0:1}" != "-" ]]; then
		# if script called directly from Jamf Pro
		_PARAMS="$4"
	fi
}
function decode_Args() {
	# decodes the parameters passed on the command line and places them in the global array _args_a
	# ${1-n}: passed parameters
	
	local manualPath=""
	local secondaryPath=""
	local managedPrefFile=""
	local params=""
	local word=""
	
	manualPath="${kMANUALSIGNAL}"
	secondaryPath="${kSCRIPTPATH}/${kMANUALSIGNALNAME}"
	managedPrefFile="${kMANAGEDPREFSPATH}/${kREVERSEDNS}.parameters.plist"
	
	# if parameters passed and the first character of the first parameter is not a dash
	if [[ "$#" -ne "0" && "${1:0:1}" != "-" ]]; then
		# get the passed parameters
		params="$( cut -d "-" -f2- <<< "$@" )"
		
		# if something passed in
		if [[ "${#params}" -gt "1" ]]; then
			# add the initial dash back
			params="-${params}"
			# loop through the parameters
			for word in ${params}; do
				# setup the array with the passed parameters
				_args_a+=("${word}")
			done
		fi
	fi
	
	# if nothing passed
	if [[ -z "${params}" ]]; then
		# setup the array with the passed parameters
		IFS=" " read -r -a _args_a <<< "$@"
	fi
	
	# if only statistics
	case "${_args_a[0]}" in
	-s|-r)
		# exit
		return "0"
	;;
	esac
	
	# if parameters passed via file in same directory
	if [[ -s "${secondaryPath}" ]]; then
		manualPath="${secondaryPath}"
	fi
	
	# if parameters passed via file in different directory
	if [[ -s "${manualPath}" ]]; then
		# make sure the array is clear
		_args_a=()
		
		# get the saved parameters into array
		IFS=" " read -r -a _args_a <<< "$( cat "${manualPath}" )"
	fi
	
	# if parameters passed via mobile config file
	if [[ -e "${managedPrefFile}" ]]; then
		# make sure the array is clear
		_args_a=()
		
		IFS=" " read -r -a _args_a <<< "$( ${kPLISTBUDDY} -c "Print Parameters" "${managedPrefFile}" 2> /dev/null )"
	fi
}
function decode_OptArgs() {
	# decodes the passed opt args and creates the global variable _STATUSCODE containing a 6 bit value, {downloadBit}{pathBit}{installBit}{verifyBit}{launchBit}{forceBit}
	# ${1-n}: passed parameters
	
	#	____________		_______________
	#	download bit		_DOWNLOADOPTARG
	#	------------		---------------
	#		0				garageband-essential
	#		1				garageband-optional
	#		2				all
	#		3				none
	#		4				logic-essential
	#		5				logic-optional
	#		7				garageband-all
	#		8				logic-all
	#		9				mainstage-essential
	#		A				mainstage-optional
	#		B				mainstage-all
	
	local optSpec=""
	local optChar=""
	local downloadBit=""
	local pathBit=""
	local installBit=""
	local verifyBit=""
	local launchBit=""
	local forceBit=""
	local suppressBit=""
	
	# setup the switches to look for
	optSpec=":d:p:l:fihvsrx"
	
	decode_StatusCode_FDN
	
	while getopts "${optSpec}" optChar; do
		case "${optChar}" in
		d) # download
			_DOWNLOADOPTARG="${OPTARG}" >&2
			_DOWNLOADSWITCH="${optChar}" >&2
			
			# opt arg
			case "${OPTARG}" in
			garageband-optional)
				downloadBit="1" >&2
				;;
			all)
				downloadBit="2" >&2
				;;
			none)
				downloadBit="3" >&2
				;;
			logic-essential)
				downloadBit="4" >&2
				;;
			logic-optional)
				downloadBit="5" >&2
				;;
			garageband-all)
				downloadBit="7" >&2
				;;
			logic-all)
				downloadBit="8" >&2
				;;
			mainstage-essential)
				downloadBit="9" >&2
				;;
			mainstage-optional)
				downloadBit="A" >&2
				;;
			mainstage-all)
				downloadBit="B" >&2
				;;	
			*) # no match
				# if not garageband-essential
				if [[ "${OPTARG}" != *"garageband-${kESSENTIAL}"* ]]; then
					_LOGTXT="⛔️ Option ${kBOLD}-${optChar}${kNC} requires a valid type."
				fi
				;;
			esac
			;;
		v) # verify
			verifyBit="1" >&2
			;;
		p) # save path
			pathBit="1" >&2
			_SAVEPATH="${OPTARG%/}" >&2 # remove any trailing slash
			
			# if save path exists, write out for LaunchControl to use
			if [[ -e "${_SAVEPATH%/*}" ]]; then
				echo "${_SAVEPATH}" > "${kVARTMP}/${kREVERSEDNS}.save.path.txt"
				
			# if save path does not exist
			else
				_LOGTXT="⛔️ Option ${kBOLD}-${optChar}${kNC} requires a valid path." >&2
			fi
			;;
		i) # install
			installBit="1" >&2
			
			# if not running as root
			if [[ "${EUID}" -ne "0" ]]; then
				_LOGTXT="⛔️ To install packages, use ${kBOLD}sudo ${kSCRIPTNAME}${kNC}." >&2
			fi
			;;
		l) # launch
			# opt arg
			case "${OPTARG}" in
			garageband)
				launchBit="1" >&2
				;;
			logicpro)
				launchBit="2" >&2
				;;
			esac
			;;
		f) # force all downloads
			forceBit="1" >&2
			;;
		x) # suppress curl output
			suppressBit="1" >&2
			;;
		h) # help
			display_Help >&2
			
			go_NoGo_FDN "99" "" "User requested help: -h" >&2
			;;
		s|r) # statistics
			display_Stats "${optChar}"
			
			go_NoGo_FDN "99" "" "User requested statistics: -s" >&2
			;;
		\?) # invalid
			# clear the array to initiate automated mode
			_args_a=() >&2
			_PREFLIGHTLOGTXT="Switching to automated mode, invalid parameter: ${kBOLD}${OPTARG}${kNC}" >&2
			
			echo "${_PREFLIGHTLOGTXT}" >&2
			
			# remove color formatting
			_PREFLIGHTLOGTXT="$( remove_ColorFormatting_FDN "${_PREFLIGHTLOGTXT}" )"
			;;
		:) # no option
			_LOGTXT="${kBOLD}Option${kNC} requires a valid parameter." >&2
			;;
		esac
		
		# if an error occurred
		if [[ -n "${_LOGTXT}" && "${optChar}" != "s" && "${optChar}" != "r" ]]; then
			echo >&2
			echo "${_LOGTXT}" >&2
			display_Help "Abbreviated" >&2
			
			# log and exit
			go_NoGo_FDN "99" "" "$( remove_ColorFormatting_FDN "${_LOGTXT}" )" >&2
		fi
	done
	
	# if just downloading packages
	if [[ "${installBit}" -eq "0" && "${verifyBit}" -eq "0" ]]; then
		# always force the download
		forceBit="1"
	fi
	
	# set
	_STATUSCODE="${downloadBit}${pathBit}${installBit}${verifyBit}${launchBit}${forceBit}${suppressBit}"
}
function display_Help() {
	# display help at the command line and optionally truncate help if passed a flag
	# $1: optional, flag to only display abbreviated help
	
	echo >&2
	echo "${kBOLD}USAGE${kNC}" >&2
	echo "${0##*/} [-d ${kUNDERLINE}type${kNL}] [-v] [-p ${kUNDERLINE}path${kNL}] [-i] [-l ${kUNDERLINE}application${kNL}] [-s] [-h]" >&2
	echo >&2
	echo >&2
	echo "${kBOLD}OPTIONS${kNC}" >&2
	echo " ${kBOLD}-d${kNC} ${kUNDERLINE}type${kNL}, ${kOPTIONAL}" >&2
	echo "${kTAB}<label> ...${kTAB}${kTAB}${kTAB}${kTAB}${kTAB}${kTAB}${kTAB}package ${kUNDERLINE}type${kNL} to download" >&2
	echo "${kTAB}garageband-${kESSENTIAL} | logic-${kESSENTIAL} | mainstage-${kESSENTIAL}${kTAB}${kESSENTIALCAP} packages by app" >&2
	echo "${kTAB}garageband-${kOPTIONAL} | logic-${kOPTIONAL} | mainstage-${kOPTIONAL}${kTAB}${kOPTIONALCAP} packages by app" >&2
	echo "${kTAB}garageband-all | logic-all | mainstage-all${kTAB}${kTAB}${kTAB}All packages by app" >&2
	echo "${kTAB}all${kTAB}${kTAB}${kTAB}${kTAB}${kTAB}${kTAB}${kTAB}${kTAB}All packages for all apps" >&2
	echo "${kTAB}none${kTAB}${kTAB}${kTAB}${kTAB}${kTAB}${kTAB}${kTAB}${kTAB}No packages" >&2
	echo " ${kBOLD}-v${kNC} verify packages, ${kOPTIONAL}" >&2
	echo "${kTAB}Check the validity and trust of each packages signature" >&2
	echo " ${kBOLD}-x${kNC} suppress curl output when downloading packages, ${kOPTIONAL}" >&2
	echo " ${kBOLD}-p${kNC} ${kUNDERLINE}path${kNL}, ${kOPTIONAL}" >&2
	echo "${kTAB}Save the packages to ${kUNDERLINE}path${kNL} OR install packages from ${kUNDERLINE}path${kNL}" >&2
	echo "${kTAB}Packages are saved to /private/var/tmp/Loops/Packages if ${kBOLD}-p${kNC} ${kUNDERLINE}path${kNL} is not passed" >&2
	echo "${kTAB}Contents of ${kUNDERLINE}path${kNL} are deleted before downloading" >&2
	echo " ${kBOLD}-i${kNC} install, ${kOPTIONAL}" >&2
	echo "${kTAB}Packages are installed if ${kBOLD}-i${kNC} is passed" >&2
	echo "${kTAB}Command must be run with administrator or root user privileges to install packages" >&2
	echo " ${kBOLD}-l${kNC} ${kUNDERLINE}application${kNL}, ${kOPTIONAL}" >&2
	echo "${kTAB}<label> ...${kTAB}${kTAB}${kTAB}${kTAB}${kUNDERLINE}launch${kNL} after completion" >&2
	echo "${kTAB}garageband | logicpro | mainstage${kTAB}Application name" >&2
	echo " ${kBOLD}-s|-r${kNC} statistics" >&2
	echo "${kTAB}Number of installed packages by category and number of packages available by category" >&2
	echo "${kTAB}-r forces a recheck of all installed packages" >&2
	echo "${kTAB}Statistics are automatically provided when Loops downloads or installs packages" >&2
	echo "${kTAB}Only use standalone when running Loops, not to be passed with other parameters" >&2
	echo " ${kBOLD}-h${kNC} help" >&2
	echo >&2
	# if display full help
	if [[ "$#" -eq "0" ]]; then
		echo "The text file, ${kMANUALSIGNALNAME}, can be used to pass options to Loops.sh." >&2
		echo "The first line of the text file should contain the options as they would be entered on the command line, e.g. -d garageband-${kESSENTIAL}." >&2
		echo "The text file can be located in the same directory as ${kSCRIPTNAME} or in ${kVARTMP}." >&2
		echo >&2
		echo "A mobileconfig profile can be used to pass options to Loops.sh." >&2
		echo "The mobileconfig key, Parameters, contains the options as they would be entered on the command line, e.g. -d garageband-essential." >&2
		echo "The mobileconfig profile takes precedence over all other option passing methods." >&2
		echo >&2
		echo >&2
		echo "${kBOLD}DESCRIPTION${kNC}" >&2
		echo "No ${kBOLD}options${kNC} –" >&2
		echo " Downloads ${kUNDERLINE}${kESSENTIAL}${kNL} packages when:" >&2
		echo "${kTAB}• GarageBand, Logic Pro, or MainStage are NOT installed." >&2
		echo "${kTAB}• ${kESSENTIALCAP} loops and instruments are not installed." >&2
		echo >&2
		echo " Downloads ${kUNDERLINE}${kOPTIONAL}${kNL} packages and, if needed, ${kUNDERLINE}${kESSENTIAL}${kNL} packages when:" >&2
		echo "${kTAB}• GarageBand, Logic Pro, or MainStage are installed." >&2
		echo >&2
		echo " Downloads AND installs ${kUNDERLINE}${kESSENTIAL}${kNL} packages when:" >&2
		echo "${kTAB}• GarageBand, Logic Pro, or MainStage are NOT installed." >&2
		echo "${kTAB}• Command is run with administrator or root user privileges." >&2
		echo >&2
		echo " Downloads AND installs ${kUNDERLINE}${kOPTIONAL}${kNL} packages and, if needed, ${kUNDERLINE}${kESSENTIAL}${kNL} packages when:" >&2
		echo "${kTAB}• GarageBand, Logic Pro, or MainStage are installed." >&2
		echo "${kTAB}• Command is run with administrator or root user privileges." >&2
		echo >&2
		echo "Use ${kBOLD}options${kNC} to download or install specific package types." >&2
		echo >&2
		echo >&2
		echo "${kBOLD}ADDITIONAL${kNC}" >&2
		echo "• Content Caching service will be used when downloading packages, if available." >&2
		echo "• Packages can be saved to an alternate location, thumb drive etc., if the ${kOPTIONAL} ${kBOLD}-p${kNC} parameter is passed. The default path is /private/var/tmp/Loops/Packages and the contents of path are deleted before downloading." >&2
		echo "• Packages saved at the default path will be deleted once installation is complete." >&2
		echo "• Package downloading and installation can be separate operations. This allows for caching of the downloads and installation at a later time." >&2
		echo "• Logs can be found in Console app Reports>Log Reports>Loops-[timestamp].log and Loops_LaunchControl-[timestamp].log." >&2
		echo >&2
		echo >&2
		echo "${kBOLD}LOOP REINDEXING${kNC}" >&2
		echo "Installing loops and instruments may require loops to be reindexed in GarageBand or Logic Pro by selecting View>Show Loop Browser, Loop Packs>Reindex All Loops." >&2
		echo >&2
		echo >&2
		echo "${kBOLD}EXAMPLES${kNC}" >&2
		echo "Download AND install GarageBand ${kUNDERLINE}${kESSENTIAL}${kNL} packages, when GarageBand is not installed OR ${kUNDERLINE}${kESSENTIAL}${kNL} loops and instruments are not installed:" >&2
		echo "${kTAB}sudo Loops.sh" >&2
		echo >&2
		echo "Download AND install GarageBand ${kUNDERLINE}${kOPTIONAL}${kNL} packages:" >&2
		echo "${kTAB}sudo Loops.sh -d garageband-${kOPTIONAL} -i" >&2
		echo >&2
		echo "Download ${kUNDERLINE}all${kNL} packages to an ${kUNDERLINE}external disk${kNL}:" >&2
		echo "${kTAB}Loops.sh -d all -p /Volumes/myDisk" >&2
		echo >&2
		echo "Download AND install ${kUNDERLINE}all${kNL} packages:" >&2
		echo "${kTAB}sudo Loops.sh -d all -i" >&2
		echo >&2
		echo "Install packages that have been previously downloaded to the default ${kUNDERLINE}path${kNL}:" >&2
		echo "${kTAB}sudo Loops.sh -d none -i" >&2
		echo >&2
		echo >&2
		echo "Loops ${kSCRIPTVERS}, ${kSCRIPTDATE}" >&2
		echo "Copyright (c) 2022-24 Apple Inc." >&2
		curl --version | head -n 2 >&2
	fi
	
	echo >&2
}
function display_Stats() {
	# displays installed and available package statistics
	# $1: optChar, s or r
	
	local i=""
	local keyValue=""
	local downloadPlist=""
	local prefValue=""
	local index=""
	local count=""
	local returnCode=""
	
	declare -a values_a
	declare -a realKeyNames_a
	declare -a availableValues_a
	declare -a filePaths_a
	declare -a downloadPlists_a
	
	realKeyNames_a=(
		"GarageBand ${kESSENTIAL}:"
		"GarageBand ${kOPTIONAL}:"
		"Logic Pro ${kESSENTIAL}:"
		"Logic Pro ${kOPTIONAL}:"
		"MainStage ${kESSENTIAL}:"
		"MainStage ${kOPTIONAL}:"
	)
	
	filePaths_a=(
		"${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}0.txt"
		"${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}0.txt"
		"${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}1.txt"
		"${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}1.txt"
		"${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}2.txt"
		"${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}2.txt"
	)
	
	downloadPlists_a=(
		"${_GARAGEBANDDOWNLOADPLISTNAME}"
		"${_LOGICDOWNLOADPLISTNAME}"
		"${_MAINSTAGEDOWNLOADPLISTNAME}"
	)
	
	_STATUSCODE="200000"
	readValue="0"
	prefValue="0"
	index="0"
	
	pre_Flight_FDN "runAsuser"
	
	echo >&2
	echo "Gathering installed packages..." >&2
	
	# loop through the pref key values for each loop type
	for i in "${_keys_a[@]}"; do
		# get the saved pref value
		readValue="$( pref_Read_FDN "${i}" "${kPREFSFILE}" )"
		prefValue="$((prefValue+readValue))"
	done
	
	# loop through the file paths
	for i in "${filePaths_a[@]}"; do
		# if the per loop package list does not exist
		if [[ ! -e "${i}" ]]; then
			prefValue="0"
			touch "${i}"
		fi
	done
	
	# if no values available or forcing check of installed packages
	if [[ "${prefValue}" -eq "0" || "$1" == "r" ]]; then
		downloadPlist="1"
		
		prep_DownloadInstallSizing
		download_Plist
		parse_Plist
		packages_GetInstalled_FDN
		packages_InstalledPackageCount_FDN
	fi
	
	# loop through the keys
	for ((i=0; i<${#_keys_a[@]}; i++)); do
		# get the key value
		keyValue="${_keys_a[i]}"
		values_a+=("${realKeyNames_a[i]} $( "${kPLISTBUDDY}" -c "print :\"$keyValue\"" "${kPREFSFILE}" 2>&1 )")
		returnCode="$(($?*-1))"
		
		# if the key does not exist
		if [[ "${returnCode}" -ne "0" ]]; then
			# reset
			values_a[i]="${realKeyNames_a[i]} 0"
		fi
	done
	
	# move back up a line
	echo -e "\033[2A" >&2 # move up a line
	echo -en $'\033[2K' >&2 # clear the line
	
	echo "${kUNDERLINE}Installed packages${kNL}" >&2
	printf '%s\n' "${values_a[@]}"
	echo >&2
	echo "Gathering available packages..." >&2
	
	# if need to check for download plist update
	if [[ -z "${downloadPlist}" ]]; then
		# loop through the download plists
		for i in "${downloadPlists_a[@]}"; do
			# garageband, index=0; logic, index=1; mainStage, index=2
			downloadPlistName="${kDOWNLOADEDLOOPSPLIST%.*}${index}.plist"
			
			# read the current config version for the particular plist
			_configVersion_a[index]="$( "${kPLISTBUDDY}" -c 'Print :ConfigVersion' "${downloadPlistName}" 2> /dev/null )"
			
			# read the previously saved config version from preferences for the particular plist
			_configVersion_a[index+3]="$( pref_Read_FDN "${_appName_a[index]//[[:blank:]]/}ConfigVersion" "${kPREFSFILE}" )"
			
			# if the config versions do not match
			if [[ "${_configVersion_a[index]}" -ne "${_configVersion_a[index+3]}" ]]; then
				# force redownload of plists
				download_Plist
				parse_Plist
				
				# exit
				break
			fi
			
			((index++))
		done
	fi
	
	# loop through the files
	for ((i=0; i<${#filePaths_a[@]}; i++)); do
		# get the available value
		availableValues_a+=("${realKeyNames_a[i]} $( trim_WhiteSpace_FDN "$( wc -l < "${filePaths_a[i]}" )" )")
	done

	echo -e "\033[2A" >&2 # move up a line
	echo -en $'\033[2K' >&2 # clear the line
	echo "${kUNDERLINE}Available packages${kNL}" >&2
	printf '%s\n' "${availableValues_a[@]}"
	echo >&2
	
	# clear
	_STATUSCODE=""
}
function download_Engine() {
	# downloads (curl) the packages listed in _downloadPKGs_a to _SAVEPATH
	
	local i=""
	local downloadBit=""
	local pathBit=""
	local installBit=""
	local verifyBit=""
	local launchBit=""
	local forceBit=""
	local suppressBit=""
	local count=""
	local response=""
	local fileName=""
	local pkgSize=""
	local returnCode=""
	
	declare -a responseCodes_a
	
	count="1"
	returnCode="0"
	
	decode_StatusCode_FDN
	
	# if downloading packages
	if [[ "${downloadBit}" -ne "3" || "${downloadBit}" == [A-Z] ]]; then
		# if not saving to an alternate path
		if [[ "${pathBit}" -ne "1" ]]; then
			# delete any existing packages
			delete_File_FDN "${_SAVEPATH}" "deleteFolder"
		fi
		
		# delete the curl config file
		delete_File_FDN "${_URLCONFIGFILE}"
		
		get_PackageDownloadArray
		
		write_2Log_FDN "${_LOGTXT}"
		
		# if there are no packages to download, exit the function
		skip_Function_FDN "download" || return 0
		
		generate_URLConfigFile
		
		# move back up a line
		echo -e "\033[2A" >&2
		
		# let the user know how many packages to download
		echo "Downloading ${kBOLD}$(($( wc -l < "${_URLCONFIGFILE}" ) / 2))${kNC} packages:" >&2
		
		# verify active network connection
		verify_Network_FDN
		
		go_NoGo_FDN "0" "Waiting for package downloads to complete..."
		
		write_2Log_FDN "${_LOGTXT}"
		
		# curl settings:
		# --connect-timeout (connection timeout)
		# --max-time		(how long each retry will wait)
		# --retry			(number of retry times)
		# --retry-delay		(an exponential backoff algorithm)
		# --retry-max-time	(total time before it's considered failed)
		# --remove-on-error	(remove partially saved file if error when downloading)
		# -#				(display progress bar)
		
		# loop until no fallback
		until false; do
			# caffeinate the curl command; follow the location and download files in parallel
			case "${suppressBit}" in
			1)
				response="$( caffeinate -u -d -i curl --location \
				--retry 10 \
				--retry-connrefused \
				--parallel \
				--parallel-immediate \
				--config "${_URLCONFIGFILE}" \
				--no-progress-meter \
				--write-out "%{http_code}";echo ",$?" )"
			;;
			*)
				response="$( caffeinate -u -d -i curl --location \
				--retry 10 \
				--retry-connrefused \
				--parallel \
				--parallel-immediate \
				--config "${_URLCONFIGFILE}" \
				--write-out "%{http_code}";echo ",$?" )"
			;;
			esac
			
			# place the response codes into an array
			IFS=$'\n' read -d '' -r -a responseCodes_a <<< "$( fold -w3 <<< "${response%,*}" )"
			
			# if content cache failed, fallback to CDN
			if [[ "${response#*,}" -ne "0" && -z "${_URLTYPE}" ]]; then
				_URLCONFIGFILE="${kCDNURLCONFIGFILE}"
				
				fallBack_URLConfig
				
				# verify active network connection
				verify_Network_FDN
				
			else
				# continue
				break
			fi
		done
		
		# loop the response codes
		for i in "${responseCodes_a[@]}"; do
			# get the odd numbered line in the curlrc.txt file
			fileName="$( sed "${count}q;d" "${_URLCONFIGFILE}" )"
			fileName="${fileName##*/}"
			fileName="${fileName%\?*}" # remove ?source <url>
			fileName="${fileName//%20/ }" # replace %20 with space
			fileName="${fileName//\"}" # remove tailing double-quote
			
			# get the actual package size
			pkgSize="$( stat -f%z "${_SAVEPATH}/${fileName}" )"
			pkgSize="$( convert_FromBytes2HumanReadable_FDN "${pkgSize}" "1" )"
			
			# verify the curl response
			xml_ErrorCheck_FDN "${i}" "200" "${fileName}" "report&Continue"
			returnCode="$(($?*-1))"
			
			go_NoGo_FDN "${returnCode}" "Successfully downloaded ${fileName} (${pkgSize})" "Unable to download ${fileName}"
			
			# increment by 2
			((count+=2))
		done
		
	# only installing packages
	elif [[ "${downloadBit}" -eq "3" && "${verifyBit}" -eq "0" ]]; then
		go_NoGo_FDN "${returnCode}" "Only installing packages." ""
		
	# verifying and installing packages
	elif [[ "${downloadBit}" -eq "3" && "${verifyBit}" -eq "1" && "${installBit}" -eq "1" ]]; then
		go_NoGo_FDN "${returnCode}" "Verifying and installing packages." ""
		
	# only verify packages
	else
		go_NoGo_FDN "${returnCode}" "Only verifying packages." ""
	fi
	
	write_2Log_FDN "${_LOGTXT}"
}
function download_Plist() {
	# downloads the package plists from the current URL
	
	local keyValue=""
	local seedURL=""
	local response=""
	local downloadPlistName=""
	local downloadLoopsURL=""
	local i=""
	local index=""
	local returnCode=""
	
	declare -a downloadPlists_a
	
	# if only verifying or installing packages, exit the function
	skip_Function_FDN || return 0
	
	downloadPlists_a=(
		"${_GARAGEBANDDOWNLOADPLISTNAME}"
		"${_LOGICDOWNLOADPLISTNAME}"
		"${_MAINSTAGEDOWNLOADPLISTNAME}"
	)
	
	# verify active network connection
	verify_Network_FDN
	
	go_NoGo_FDN "0" "Preparing package plists"
	
	index="0"
	
	# loop through downloadPlists_a and download the plists for each application
	for i in "${downloadPlists_a[@]}"; do
		downloadLoopsURL="${kAPPLEURL}/${kMS3}/${i}"
		# get the pref key value
		keyValue="${_appName_a[index]//[[:blank:]]/}SeedURL"
		seedURL="$( pref_Read_FDN "${keyValue}" "${kPREFSFILE}" )"
		
		# if downloadLoopsURL is outdated
		if [[ "${downloadLoopsURL}" != "${seedURL}" && -n "${seedURL}" ]]; then
			downloadLoopsURL="${seedURL}"
		fi
		
		downloadPlistName="${kDOWNLOADEDLOOPSPLIST%.*}${index}.plist" # garageband, index=0; logic, index=1; mainStage, index=2
		
		# search for a newer plist URL
		downloadLoopsURL="$( auto_DetectPlistURL "${downloadLoopsURL}" )"
		
		# if downloadLoopsURL is newer 
		if [[ "${downloadLoopsURL}" != "${seedURL}" ]]; then
			# save the current seed URL
			pref_Write_FDN "${keyValue}" "${downloadLoopsURL}" "${kPREFSFILE}"
		fi
		
		# curl the packages plist; following locations, failing if an issue, and executing silently
		curl --location "${downloadLoopsURL}" \
		--fail \
		--silent \
		--output "${downloadPlistName}"
		returnCode="$(($?*-1))"
		
		go_NoGo_FDN "${returnCode}" "Downloaded ${downloadLoopsURL##*/}." "Unable to download ${downloadLoopsURL##*/}."
		
		# read the current config version for the particular plist
		_configVersion_a[index]="$( "${kPLISTBUDDY}" -c 'Print :ConfigVersion' "${downloadPlistName}" 2> /dev/null )"
		
		# read the previously saved config version from preferences for the particular plist
		_configVersion_a[index+3]="$( pref_Read_FDN "${_appName_a[index]//[[:blank:]]/}ConfigVersion" "${kPREFSFILE}" )"
		
		# save the current config version to preferences
		pref_Write_FDN "${_appName_a[index]//[[:blank:]]/}ConfigVersion" "${_configVersion_a[index]}" "${kPREFSFILE}"
		
		# increment to the next plist name
		((index++))
	done
	
	write_2Log_FDN "${_LOGTXT}"
}

# E --------------------------------------------------------------------------------------------------------------------------------
function exit_Check() {
	# determines exit type caught by trap 'trap_Exit' and unloads LaunchAgent|LaunchDaemon
	# $1: exit code
	
	# if not an error or help selected in decode_OptArgs
	if [[ "$1" -ne "99" ]]; then
		# if exited with failure
		if [[ "$1" -ge "1" && "$1" -ne "99" ]]; then
			exited_WithFailure "$1"
			
		# if exited normally
		elif [[ "$1" -eq "0" ]]; then
			exited_Normally "$1"
		fi
		
		# clear the log file path
		xattr_Write_FDN "logFile" "" "${kPREFSFILE}"
		
	else
		# make sure the Loops Log folder exists
		mkdir -m 755 "${kLOGPATH}" &> /dev/null
		
		# indicate error with get_OptArgs
		write_2Log_FDN "${_ERRTRACKMSG}"
	fi
}
function exit_ErrorLogExists() {
	# if an error log exists, rename the log and rename the log file with current timestamp
	
	local errLogPath=""
	
	# if an error log exists
	if [[ -e "${kERRLOG}" ]]; then
		errLogPath="${kERRLOG%.*}-$( date +%Y-%m-%d_%H%M%S ).log"
		
		# rename the file
		mv "${kERRLOG}" "${errLogPath}"
		
		set_Ownership_FDN "${errLogPath}"
		set_Permissions_FDN "${errLogPath}"
	fi
}
function exit_LoggingToUser() {
	# write out _LOGTXT to log if something in _LOGTXT
	
	# if completed and logs not moved
	if [[ -z "${logPath501}" ]]; then # TODO investigate this variable
		# if something in _LOGTXT
		if [[ -n "${_LOGTXT}" ]]; then
			_LOGTXT="${_LOGTXT}${kNEWLINE}"
		fi
		
		go_NoGo_FDN "0" "Done" ""
		
		write_2Log_FDN "${_LOGTXT}"
	fi
}
function exit_Restart() {
	# restart to activate essential loops and instruments if required
	
	local waitTime=""
	
	# if need to restart
	if [[ -n "${restartNow}" ]]; then
		waitTime="10"
		
		# loop showing countdown timer
		while [[ "${waitTime}" -gt "0" ]]; do
		  # clear the line
		  echo -en $'\033[2K'
		  
		  # if still counting down
		  if [[ "${waitTime}" -ge "10" ]]; then
			printf "\\rRestarting to activate ${kESSENTIAL} loops and instruments in %2d seconds" "${waitTime}"
			
		  elif [[ "${waitTime}" -ne "1" ]]; then
			printf "\\rRestarting to activate ${kESSENTIAL} loops and instruments in %1d seconds" "${waitTime}"
			
		  else
			printf "\\rRestarting to activate ${kESSENTIAL} loops and instruments in %1d second" "${waitTime}"
		  fi
		  
		  # wait
		  sleep 1
		  
		  ((waitTime--))
		done
		
		# clear the line
		echo -en $'\033[2K'
		
		printf "\\rRestarting"
		
		# restart to activate essential loops
		shutdown -r now
	fi
}
function exit_RunningAsRoot() {
	# script run as root and a 501 user exists, change log ownership to the 501 user
	
	local returnCode=""
	
	# if running as root and there are user accounts
	if [[ "${EUID}" -eq "0" && -n "${user501}" ]]; then
		# if the console user is not root
		if [[ "${kUSER}" != "root" ]]; then
			user501="${kUSER}"
		fi
		
		# reset ownership
		chown -R "${user501}:staff" "${kVARTMP}" &> /dev/null
		returnCode="$(($?*-1))"
		
		go_NoGo_FDN "${returnCode}" "Set ${kVARTMP} ownership to ${user501}:staff." "Unable to set ${kVARTMP} ownership to ${user501}:staff."
	fi
}
function exited_Normally() {
	# update pref plist keys scriptVersion and StatusCode, display notification, open the Packages folder if not installing, and set restart in _DOWNLOADOPTARG if applicable
	# $1: exit code
	
	local title=""
	local subtitle=""
	local notification=""
	local loginWindowUser=""
	local returnCode=""
	
	declare -a appName_a
	
	appName_a=('' "${_appName_a[@]}")
	
	title="Loops"
	notification="New loops and instruments downloaded"
	
	loginWindowUser="$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }' )"
	
	# if normal exit
	if [[ "$1" -eq "0" ]]; then			
		# set the script version for comparison when prepping the LaunchDaemon
		"${kPLISTBUDDY}" -c "Set :ScriptVersion ${kSCRIPTVERS}" "${kPREFSFILE}" &> /dev/null
		
		# make sure the StatusCode entry exists. Maybe working with a 1.0 previously created prefs plist. Will just silently fail if the entry already exists.
		"${kPLISTBUDDY}" -c "Add :StatusCode string " "${kPREFSFILE}" &> /dev/null
		
		# set the status code for this run to be used to compare against for the next run
		"${kPLISTBUDDY}" -c "Set :StatusCode ${_STATUSCODE}" "${kPREFSFILE}" &> /dev/null
		
		# if packages downloaded
		if [[ "${downloadBit}" -ne "3" || "${downloadBit}" == [A-Z] ]]; then
			# make sure the downloadBit entry exists. Maybe working with a 1.0 previously created prefs plist. Will just silently fail if the entry already exists.
			"${kPLISTBUDDY}" -c "Add :downloadBit string " "${kPREFSFILE}" &> /dev/null
			
			# set the downloadBit to be used to if only installing
			"${kPLISTBUDDY}" -c "Set :downloadBit ${downloadBit}" "${kPREFSFILE}" &> /dev/null
		fi
		
		# if using external path
		if [[ "${pathBit}" -eq "1" ]]; then
			# copy the prefs file to the external disk
			ditto "${kPREFSFILE}" "${_SAVEPATH}/.${kPREFSFILE##*/}"
		fi
		
		# if the install bit is not set, not running as root user, not at the login window, and packages were downloaded
		if [[ "${installBit}" -eq "0" && "${EUID}" -ne "0" && "${loginWindowUser}" != "loginwindow" && "${#_downloadPKGs_a[@]}" -ne "0" ]]; then
			# show the packages
			open "${_SAVEPATH}"
		fi
		
		# if install bit is set
		if [[ "${installBit}" -eq "1" ]]; then
			notification="New loops and instruments available"
			subtitle="Reindex All Loops to view updates"
			
			# if forced the essential packages if user is logged in
			if [[ "${_DOWNLOADOPTARG}" == *"force"* && (-e "/Applications/GarageBand.app" || -e "/Applications/MainStage.app" || -e "/Applications/MainStage.app") ]]; then
				# if the user is logged in
				# shellcheck disable=SC2034
				if dockPID=$( pgrep Dock ) && finderPID=$( pgrep Finder ) && winServer=$( pgrep WindowServer ); then
					notification="Restarting in 10 seconds"
				fi
				
				subtitle="${kESSENTIALCAP} loops and instruments installed"
				restartNow="1"
			fi
			
			go_NoGo_FDN "0" "${notification}" ""
			go_NoGo_FDN "0" "${subtitle}" ""
		fi
		
		# open the app if flagged
		open_App_FDN "${appName_a[launchBit]}"
		
		# if display notification if running as the logged in user
		if [[ ("${downloadBit}" -ne "3" || "${installBit}" -eq "1") && "${#_downloadPKGs_a[@]}" -ne "0" ]]; then
			# display notification
			display_Notification_FDN "${title}" "${notification}" "${subtitle}"
			
		# no packages to download
		elif [[ "${#_downloadPKGs_a[@]}" -eq "0" ]];then
			# clear
			restartNow=""
			notification="No packages to download"
			subtitle=""
			
			# move back up a line
			echo -e "\033[2A" >&2
			echo "${notification} ✅" >&2
			
			# display notification
			display_Notification_FDN "${title}" "${notification}" "${subtitle}"
		fi
		
		echo "Done${kNEWLINE}" >&2
	fi
}
function exited_WithFailure() {
	# trapped error so display notification, kill all active PIDs, and log error
	# $1: exit code
	
	local msgTxt=""
	
	# if exited with failure
	if [[ "$1" -ge "1" && "$1" -ne "99" ]]; then
		# display failure notification
		display_Notification_FDN "Loops" "Package(s) install failed" "See Loops log for details"
		
		msgTxt="${kNEWLINE}⛔️ ${_ERRTRACKMSG}"
		
		kill_ActivePIDs_FDN
		
		# if date/time stamp in the first line
		if [[ "$( head -n 1 <<< "${_ERRTRACKMSG}" )" == '['* ]]; then
			# remove date/time stamp information
			echo "${kNEWLINE}⛔️ ${_ERRTRACKMSG#*: }" >&2
			
		else
			echo "${msgTxt}" >&2
		fi
		
		# if package saved locally
		if [[ "${_SAVEPATH}" == "${kVARTMP}/Packages" ]]; then
			# delete the packages
			delete_File_FDN "${_SAVEPATH}" "emptyFolder"
		fi
		
		echo "${kNEWLINE}Done${kNEWLINE}" >&2
		
		# indicate failure
		write_2Log_FDN "${msgTxt}"
	fi
}

# F --------------------------------------------------------------------------------------------------------------------------------
function fallBack_URLConfig() {
	# update the curlrc.txt file to be used by curl with remaining packages to download
	
	local i=""
	local msgTxt=""
	local pkgInfo=""
	local pkgSize=""
	local returnCode=""
	
	declare -a downloadedPKGs_a
	declare -a diff_a
	
	returnCode="-1"
	
	go_NoGo_FDN "${returnCode}" "" "Falling back to CDN from content cache server for package downloading"
	
	write_2Log_FDN "${_LOGTXT}"
	
	# wait for curl to settle out
	sleep 5
	
	# temporarily move to _SAVEPATH
	pushd "${_SAVEPATH}" || return
	
	# loop over the files in _SAVEPATH
	for i in *.pkg; do
		pkgInfo="$( grep -w "${i}" "${kVARTMP}/${kREVERSEDNS}.size.${kESSENTIAL}.txt" )"
		
		# if package does not exist in essential size file
		if [[ -z "${pkgInfo}" ]]; then
			pkgInfo="$( grep -w "${i}" "${kVARTMP}/${kREVERSEDNS}.size.${kOPTIONAL}.txt" )"
		fi
		
		# get the estimated package size
		pkgInfo="$( awk -F ',' '{print $2}' <<< "${pkgInfo}" )"
		
		# get the actual package size
		pkgSize="$( stat -f%z "${_SAVEPATH}/${i}" )"
		
		# get the size differential as an absolute value
		(( pkgSize=pkgInfo-pkgSize ))
		
		# if the size differential is greater than 10KB
		if [[ "${pkgSize}" -gt "10000" ]]; then
			downloadedPKGs_a+=("${i}")
		fi
	done
	
	popd || return
	
	# get the package difference
	# shellcheck disable=SC2207
	diff_a=($( printf "%s\n" "${_downloadPKGs_a[@]}" "${downloadedPKGs_a[@]}" | sort | uniq -u ))
	
	# clear the array
	unset _downloadPKGs_a
	
	# copy the array
	_downloadPKGs_a=("${diff_a[@]}")
	
	# clear the array
	unset diff_a
	
	generate_URLConfigFile "ignore"
}
function Foundation() {
	# write script to /private/var/Loops
	# $1: destination path
	# returns: exit code
	
	# write the script out
cat <<"FDNEOF" >"$1/${FUNCNAME[0]}"
#!/bin/bash --norc


# set -xv; exec 1>>"/private/var/tmp/FoundationTraceLog" 2>&1

#----------------------------------------------------------------------------------------------------------------------------------	

#	Foundation
#	Copyright (c) 2022-25 Apple Inc.
#	
#	
#	This script contains shared variables and functions that are imported into other scripts.

#
# APPLE INC.
# SOFTWARE LICENSE AGREEMENT FOR FOUNDATION SOFTWARE

# PLEASE READ THIS SOFTWARE LICENSE AGREEMENT ("LICENSE") CAREFULLY BEFORE USING THE APPLE SOFTWARE
# (DEFINED BELOW). BY USING THE APPLE SOFTWARE, YOU ARE AGREEING TO BE BOUND BY THE TERMS OF THIS
# LICENSE. IF YOU DO NOT AGREE TO THE TERMS OF THIS LICENSE, DO NOT USE THE APPLE SOFTWARE.

# 1. General.
# The Apple software, sample or example code, utilities, tools, documentation,
# interfaces, content, data, and other materials accompanying this License, whether on disk, print
# or electronic documentation, in read only memory, or any other media or in any other form,
# (collectively, the "Apple Software") are licensed, not sold, to you by Apple Inc. ("Apple") for
# use only under the terms of this License.  Apple and/or Apple’s licensors retain ownership of the
# Apple Software itself and reserve all rights not expressly granted to you. The terms of this
# License will govern any software upgrades provided by Apple that replace and/or supplement the
# original Apple Software, unless such upgrade is accompanied by a separate license in which case
# the terms of that license will govern.

# 2. Permitted License Uses and Restrictions.
# A. Service Provider License. A company delivering Apple Professional Services on Apple’s
# behalf, or with Apple’s authorization, a "Service Provider". Subject to the terms and conditions 
# of this License, if you are in good standing under an Apple authorized agreement regarding
# the delivery of Apple Professional Services, and are providing the Apple Software to a customer
# end-user under contract from Apple, you are granted a limited, non-exclusive license to install
# and use the Apple Software on Apple-branded computers for internal use within the customer
# end-user’s company, institution or organization. You may make only as many internal use copies
# of the Apple Software as reasonably necessary to use the Apple Software as permitted under this
# License and distribute such copies only to your employees and contractors whose job duties require
# them to so use the Apple Software; provided that you reproduce on each copy of the Apple Software
# or portion thereof, all copyright or other proprietary notices contained on the original.

# B. End-User License. Subject to the terms and conditions of this License, you are granted a
# limited, non-exclusive license to install and use the Apple Software on Apple-branded computers
# for internal use within your company, institution or organization. You may make only as many
# internal use copies of the Apple Software as reasonably necessary to use the Apple Software as
# permitted under this License and distribute such copies only to your employees and contractors
# whose job duties require them to so use the Apple Software; provided that you reproduce on each
# copy of the Apple Software or portion thereof, all copyright or other proprietary notices
# contained on the original.

# C. Other Use Restrictions. The grants set forth in this License do not permit you to, and you
# agree not to, install, use or run the Apple Software on any non-Apple-branded computer, or to
# enable others to do so. Except as otherwise expressly permitted by the terms of this License or as
# otherwise licensed by Apple: (i) only one user may use the Apple Software at a time; and (ii) you
# may not make the Apple Software available over a network where it could be run or used by multiple
# computers at the same time. You may not rent, lease, lend, trade, transfer, sell, sublicense or
# otherwise redistribute the Apple Software or exploit any services provided by or through the Apple
# Software in any unauthorized way.

# D. No Reverse Engineering; Limitations. You may not, and you agree not to or to enable others to,
# copy (except as expressly permitted by this License), decompile, reverse engineer, disassemble,
# attempt to derive the source code of, decrypt, modify, create derivative works of the Apple
# Software or any services provided by or through the Apple Software or any part thereof (except as
# and only to the extent any foregoing restriction is prohibited by applicable law).

# E. Compliance with Laws. You agree to use the Apple Software in compliance with all applicable
# laws, including local laws of the country or region in which you reside or in which you download
# or use the Apple Software.

# 3. No Transfer.  Except as otherwise set forth herein, you may not transfer this Apple Software
# without Apple’s express prior written approval.  All components of the Apple Software are provided
# as part of a bundle and may not be separated from the bundle and distributed as standalone
# applications.

# 4. Termination. This License is effective until terminated. Your rights under this License will
# terminate automatically or cease to be effective without notice from Apple if you fail to comply
# with any term(s) of this License.  In addition, Apple reserves the right to terminate this License
# if a new version of Apple's operating system software or the Apple Software is released which is
# incompatible with this version of the Apple Software.  Upon the termination of this License, you
# shall cease all use of the Apple Software and destroy all copies, full or partial, of the Apple
# Software.  Section 2C, 2D, and 4 through 10 of this License shall survive any termination.

# 5. Disclaimer of Warranties.
# A.  YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT, TO THE EXTENT PERMITTED BY APPLICABLE LAW, USE OF
# THE APPLE SOFTWARE AND ANY SERVICES PERFORMED BY OR ACCESSED THROUGH THE APPLE SOFTWARE IS AT YOUR
# SOLE RISK AND THAT THE ENTIRE RISK AS TO SATISFACTORY QUALITY, PERFORMANCE, ACCURACY AND
# EFFORT IS WITH YOU.

# B.  TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE APPLE SOFTWARE IS PROVIDED "AS IS" AND
# "AS AVAILABLE", WITH ALL FAULTS AND WITHOUT WARRANTY OF ANY KIND, AND APPLE AND APPLE'S LICENSORS
# (COLLECTIVELY REFERRED TO AS "APPLE" FOR THE PURPOSES OF SECTIONS 5 AND 6) HEREBY DISCLAIM ALL
# WARRANTIES AND CONDITIONS WITH RESPECT TO THE APPLE SOFTWARE, EITHER EXPRESS, IMPLIED OR
# STATUTORY, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES AND/OR CONDITIONS OF
# MERCHANTABILITY, SATISFACTORY QUALITY, FITNESS FOR A PARTICULAR PURPOSE, ACCURACY, QUIET
# ENJOYMENT, AND NON-INFRINGEMENT OF THIRD PARTY RIGHTS.

# C.  APPLE DOES NOT WARRANT AGAINST INTERFERENCE WITH YOUR ENJOYMENT OF THE APPLE SOFTWARE, THAT
# THE FUNCTIONS CONTAINED IN, OR SERVICES PERFORMED OR PROVIDED BY, THE APPLE SOFTWARE WILL MEET
# YOUR REQUIREMENTS, THAT THE OPERATION OF THE APPLE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE,
# THAT ANY SERVICES WILL CONTINUE TO BE MADE AVAILABLE, THAT THE APPLE SOFTWARE WILL BE COMPATIBLE
# OR WORK WITH ANY THIRD PARTY SOFTWARE, APPLICATIONS OR THIRD PARTY SERVICES, OR THAT DEFECTS IN
# THE APPLE SOFTWARE WILL BE CORRECTED. INSTALLATION OF THIS APPLE SOFTWARE MAY AFFECT THE
# AVAILABILITY AND USABILITY OF THIRD PARTY SOFTWARE, APPLICATIONS OR THIRD PARTY SERVICES, AS WELL
# AS APPLE PRODUCTS AND SERVICES.

# D.  YOU FURTHER ACKNOWLEDGE THAT THE APPLE SOFTWARE IS NOT INTENDED OR SUITABLE FOR USE IN
# SITUATIONS OR ENVIRONMENTS WHERE THE FAILURE OR TIME DELAYS OF, OR ERRORS OR INACCURACIES IN THE
# CONTENT, DATA OR INFORMATION PROVIDED BY, THE APPLE SOFTWARE COULD LEAD TO DEATH, PERSONAL INJURY,
# OR SEVERE PHYSICAL OR ENVIRONMENTAL DAMAGE, INCLUDING WITHOUT LIMITATION THE OPERATION OF NUCLEAR
# FACILITIES, AIRCRAFT NAVIGATION OR COMMUNICATION SYSTEMS, AIR TRAFFIC CONTROL, LIFE SUPPORT OR
# WEAPONS SYSTEMS.

# E.  NO ORAL OR WRITTEN INFORMATION OR ADVICE GIVEN BY APPLE OR AN APPLE AUTHORIZED REPRESENTATIVE
# SHALL CREATE A WARRANTY. SHOULD THE APPLE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE ENTIRE COST OF
# ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

# 6. Limitation of Liability. TO THE EXTENT NOT PROHIBITED BY APPLICABLE LAW, IN NO EVENT SHALL
# APPLE BE LIABLE FOR PERSONAL INJURY, OR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES
# WHATSOEVER, INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, CORRUPTION OR LOSS OF
# DATA, FAILURE TO TRANSMIT OR RECEIVE ANY DATA OR INFORMATION, BUSINESS INTERRUPTION OR ANY OTHER
# COMMERCIAL DAMAGES OR LOSSES, ARISING OUT OF OR RELATED TO YOUR USE OR INABILITY TO USE THE APPLE
# SOFTWARE OR ANY THIRD PARTY SOFTWARE, APPLICATIONS, OR SERVICES IN CONJUNCTION WITH THE APPLE
# SOFTWARE, HOWEVER CAUSED, REGARDLESS OF THE THEORY OF LIABILITY (CONTRACT, TORT OR OTHERWISE) AND
# EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. SOME JURISDICTIONS DO NOT ALLOW
# THE EXCLUSION OR LIMITATION OF LIABILITY FOR PERSONAL INJURY, OR OF INCIDENTAL OR CONSEQUENTIAL
# DAMAGES, SO THIS LIMITATION MAY NOT APPLY TO YOU. In no event shall Apple's total liability to you
# for all damages (other than as may be required by applicable law in cases involving personal
# injury) exceed the amount of fifty dollars ($50.00). The foregoing limitations will apply even if
# the above stated remedy fails of its essential purpose.

# 7. Export Control. You may not use or otherwise export or re-export the Apple Software except as
# authorized by United States law and the laws of the jurisdiction(s) in which the Apple Software
# was obtained. In particular, but without limitation, the Apple Software may not be exported or re-
# exported (a) into any U.S. embargoed countries or (b) to anyone on the U.S. Treasury Department's
# list of Specially Designated Nationals or the U.S. Department of Commerce Denied Person's List or
# Entity List. By using the Apple Software, you represent and warrant that you are not located in
# any such country or on any such list. You also agree that you will not use the Apple Software for
# any purposes prohibited by United States law, including, without limitation, the development,
# design, manufacture or production of missiles, nuclear, chemical or biological weapons.

# 8. Government End Users. The Apple Software and related documentation are "Commercial Items", as
# that term is defined at 48 C.F.R. §2.101, consisting of "Commercial Computer Software" and
# "Commercial Computer Software Documentation", as such terms are used in 48 C.F.R. §12.212 or 48
# C.F.R. §227.7202, as applicable. Consistent with 48 C.F.R. §12.212 or 48 C.F.R. §227.7202-1
# through 227.7202-4, as applicable, the Commercial Computer Software and Commercial Computer
# Software Documentation are being licensed to U.S. Government end users (a) only as Commercial
# Items and (b) with only those rights as are granted to all other end users pursuant to the terms
# and conditions herein. Unpublished-rights reserved under the copyright laws of the United States.

# 9. Controlling Law and Severability. This License will be governed by and construed in accordance
# with the laws of the State of California, excluding its conflict of law principles. This License
# shall not be governed by the United Nations Convention on Contracts for the International Sale of
# Goods, the application of which is expressly excluded. If for any reason a court of competent
# jurisdiction finds any provision, or portion thereof, to be unenforceable, the remainder of this
# License shall continue in full force and effect.

# 10. Complete Agreement; Governing Language. This License constitutes the entire agreement between
# you and Apple relating to the use of the Apple Software licensed hereunder and supersedes all
# prior or contemporaneous understandings regarding such subject matter. No amendment to or
# modification of this License will be binding unless in writing and signed by Apple.

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software to
# use, copy, and distribute copies, including within commercial software, subject to the following
# conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial
# portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Foundation Rev. 092519


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

# C --------------------------------------------------------------------------------------------------------------------------------
function clear_AppResources_FDN() {
	local i=""
	local returnCode=""
		
	# delete previous directories
	for i in "${resourcePaths_a[@]}"; do
		returnCode="-1"
		
		# if the directory exists
		if [[ -d "${i}" ]]; then
			rm -rf "${i:?}/"
			returnCode="$(($?*-1))"
		fi
		
		go_NoGo_FDN "${returnCode}" "Deleted ${i}." "Unable to delete ${i} or does not exist."
	done
}
function compare_Files_FDN() {
	# compares files providing union or difference
	# $1: type of comparison, diff for union
	# $2: file 1
	# $3: file 2
	# $4: output file path
	# returns 0=OK, or 1=failed
	
	local returnCode="1"
	
	# if the files exist
	if [[ -e "$2" && -e "$3" ]]; then
		# do the thing
		case "$1" in
		diff) # find lines only in file $2
			comm -23 <(sort "$2") <(sort "$3") > "$4" 2> /dev/null
			returnCode="$?"
		;;
		union) # find lines common to both files
			comm -12 <(sort "$2") <(sort "$3") > "$4" 2> /dev/null
			returnCode="$?"
		;;
		esac
	fi
	
	# return
	return "${returnCode}"
}
function convert_FromBytes2HumanReadable_FDN() {
  # convert from Bytes to KB, MB, GB, TB, or PB
  
  # $1: numeric byte value
  # $2: optional, # of decimal places, default is 2
  # returns: value in KB, MB, GB, TB, or PB
  
  local k_ilo=""
  local m_ega=""
  local g_gia=""
  local t_era=""
  local p_eta=""
  local multiplier=""
  local convertThisValue=""
  local convertedValue=""
  local scaleValue=""
  local i=""

  # remove negative sign if present
  convertThisValue="${1#-}"
  
  k_ilo=1024
  m_ega="$((k_ilo*k_ilo))"
  g_gia="$((m_ega*k_ilo))"
  t_era="$((g_gia*k_ilo))"
  p_eta="$((t_era*k_ilo))"
  scaleValue="2"
  
  # if decimal place length passed
  if [[ -n "$2" ]]; then
	scaleValue="$2"
  fi
  
  for i in KB MB GB TB PB; do
	case "${i}" in
	  KB)
		multiplier="${k_ilo}"
	  ;;
	  MB)
		multiplier="${m_ega}"
	  ;;
	  GB)
		multiplier="${g_gia}"
	  ;;
	  TB)
		multiplier="${t_era}"
	  ;;
	  PB)
		multiplier="${p_eta}"
	  ;;
	esac
	
	# convert using multiplier
	convertedValue="$( echo "scale=$scaleValue; $convertThisValue/(${multiplier})" | bc )"
	
	# if in the range
	if [[ "${convertedValue%.*}" -le "1000" && "${convertedValue%.*}" -ge "1" ]]; then
	  # tag on value indicator
	  convertedValue="${convertedValue}${i}"
	  
	  break
	fi
  done
  
  # return
  echo "${convertedValue}"
}

# D --------------------------------------------------------------------------------------------------------------------------------
function declare_Constants_FDN() {
	local versStamp=""
	local supportFolderName=""
	
	versStamp="Version 2.0.1 (1A3), 06-05-2025"
	supportFolderName="Loops"
	
	kFOUNDATIONVERSION="${versStamp:8:${#versStamp}-20}"
	kPLISTBUDDY="/usr/libexec/PlistBuddy"
	kVARTMP="/private/var/tmp/${supportFolderName}"
	kROOTREVERSEDNS="com.$( tr '[:upper:]' '[:lower:]' <<< "${supportFolderName}" )"
	kREVERSEDNS="${kROOTREVERSEDNS}"
	kERRMSGFILE="${kVARTMP}/${kREVERSEDNS}.goNoGo.error.txt"
	kERRLOG="${kVARTMP}/${kREVERSEDNS}.error.log"
	kUSER="$( stat -f%Su /dev/console )"
	kHOME="$( dscl . -read /Users/"${kUSER}" | grep NFSHomeDirectory | awk '{print $NF}' )"
	kUID="$( id -u "${kUSER}" )"
	kLOGPATH="/private/var/log/${supportFolderName}"
	# if not running as root
	if [[ "${EUID}" -ne "0" ]]; then
		kLOGPATH="${kHOME}/Library/Logs/${supportFolderName}"
	fi
	kMANUALSIGNALNAME="${kREVERSEDNS}.launch.signal.manual"
	kMANUALSIGNAL="${kVARTMP%/*}/${kMANUALSIGNALNAME}"
	kLASCRIPTNAME="LaunchControl"
	kLANAME="${kREVERSEDNS}.watch.plist"
	kLDPATH="/Library/LaunchAgents/${kLANAME}"
	kLAPATH="${HOME}/Library/LaunchAgents/${kLANAME}"
	kLAUNCHSIGNAL="${kVARTMP}/${kREVERSEDNS}.launch.signal"
	kPROGRESSFILE="${kVARTMP}/${kREVERSEDNS}.progress.txt"
	kACTIVEPIDFILE="${kVARTMP}/${kREVERSEDNS}.active.pid"
	kPREFSFILE="${kVARTMP}/${kREVERSEDNS}.prefs.plist"
	kESSENTIAL="essential"
	kOPTIONAL="optional"
	kESSENTIALCAP="$(tr '[:lower:]' '[:upper:]' <<< ${kESSENTIAL:0:1})${kESSENTIAL:1}"
	kOPTIONALCAP="$(tr '[:lower:]' '[:upper:]' <<< ${kOPTIONAL:0:1})${kOPTIONAL:1}"
	kGARAGEBANDCONFIGVERSION="$( pref_Read_FDN "GarageBandConfigVersion" "${kPREFSFILE}" || echo "0" )"
	kLOGICPROCONFIGVERSION="$( pref_Read_FDN "LogicProConfigVersion" "${kPREFSFILE}" || echo "0" )"
	kMAINSTAGECONFIGVERSION="$( pref_Read_FDN "MainStageConfigVersion" "${kPREFSFILE}" || echo "0" )"
	kINSTALLEDPACKAGELIST="${kVARTMP}/${kREVERSEDNS}.installed.packages.txt"
	kMANAGEDPREFSPATH="/Library/Managed Preferences"
	kNEWLINE=$'\n'
	kTAB=$'\t'
	
	# declare terminal text colors
	kLIGHTGREENBOLD=$'\033[1;32m'
	kLIGHTBLUEBOLD=$'\033[1;36m'
	kREDBOLD=$'\033[1;91m'
	kBOLD=$'\033[1m'
	kUNDERLINE=$'\033[4m'
	kNL=$'\033[24m'	# No underline
	kNC=$'\033[0m'	# No Color
	
	declare -rx kFOUNDATIONVERSION
	declare -rx kPLISTBUDDY
	declare -rx kVARTMP
	declare -rx kROOTREVERSEDNS
	declare -rx kREVERSEDNS
	declare -rx kERRMSGFILE
	declare -rx kERRLOG
	declare -rx kUSER
	declare -rx kHOME
	declare -rx kLOGPATH
	declare -rx kMANUALSIGNALNAME
	declare -rx kMANUALSIGNAL
	declare -rx kLASCRIPTNAME
	declare -rx kLANAME
	declare -rx kLAPATH
	declare -rx kLDPATH
	declare -rx kLAUNCHSIGNAL
	declare -rx kPROGRESSFILE
	declare -rx kACTIVEPIDFILE
	declare -rx kPREFSFILE
	declare -rx kESSENTIAL
	declare -rx kOPTIONAL
	declare -rx kESSENTIALCAP
	declare -rx kOPTIONALCAP
	declare -rx kGARAGEBANDCONFIGVERSION
	declare -rx kLOGICPROCONFIGVERSION
	declare -rx kMAINSTAGECONFIGVERSION
	declare -rx kINSTALLEDPACKAGELIST
	declare -rx kMANAGEDPREFSPATH
	declare -rx kNEWLINE
	declare -rx kTAB
	declare -rx kLIGHTGREENBOLD
	declare -rx kLIGHTBLUEBOLD
	declare -rx kREDBOLD
	declare -rx kBOLD
	declare -rx kUNDERLINE
	declare -rx kNL
	declare -rx kNC
}
function declare_Globals_FDN() {
	_appName_a=(
		'GarageBand'
		'Logic Pro'
		'MainStage'
	)
	
	_keys_a=(
		"garageband${kESSENTIALCAP}Installed"
		"garageband${kOPTIONALCAP}Installed"
		"logic${kESSENTIALCAP}Installed"
		"logic${kOPTIONALCAP}Installed"
		"mainstage${kESSENTIALCAP}Installed"
		"mainstage${kOPTIONALCAP}Installed"
	)
	
	_LOGTXT=""
	_ERRTRACKMSG=""
	_BYPASSLOGGING=""
	_SERIALNUMBER="$( ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}' )"
	_MDMINFO="$( get_MDM_FDN )"
	_LASCRIPTNAME="${kLASCRIPTNAME}"
	_LANAME="${kLANAME}"
	_LASCRIPTPATH="${kVARTMP}/${_LASCRIPTNAME}"
	_WATCHPATH=""
	_LAUNCHPLIST="${kLAPATH}"
	# if running as root
	if [[ "${EUID}" -eq "0" ]]; then
		_LAUNCHPLIST="${kLDPATH}"
	fi
}
function decode_StatusCode_FDN() {
	downloadBit="${_STATUSCODE:0:1}"
	pathBit="${_STATUSCODE:1:1}"
	installBit="${_STATUSCODE:2:1}"
	verifyBit="${_STATUSCODE:3:1}"
	launchBit="${_STATUSCODE:4:1}"
	forceBit="${_STATUSCODE:5:1}"
	suppressBit="${_STATUSCODE:6:1}"
}
function delete_File_FDN() {
	# $1: path to file
	# $2: optional, leave the root directory
	# $3: optional, only report deleted file name
	# returns: 0 or 1
	
	local filePath=""
	local msgTxt=""
	local returnCode=""
	
	filePath="$1"
	msgTxt="Deleted "
	returnCode="0"
	
	# if a directory
	if [[ -d "${filePath}" ]]; then
		# delete the directory
		rm -rf "${filePath:?}" &> /dev/null
		
		# if leave root directory
		if [[ "$#" -eq "2" ]]; then
			msgTxt="Deleted contents of "
			
			# recreate the directory
			mkdir -m 755 "${filePath}" &> /dev/null
			
			# if directory does not exist
			if [[ ! -d "${filePath}" ]]; then
				returnCode="1"
			fi
		fi
		
	else
		# delete the file
		rm -f "${filePath}" &> /dev/null
		
		# if the file was not deleted
		if [[ -e "${filePath}" ]]; then
			returnCode="1"
		fi
	fi
	
	# if only report file name
	if [[ -n "$3" ]]; then
		filePath="${filePath##*/}"
	fi
	
	go_NoGo_FDN "$((returnCode*-1))" "${msgTxt}${filePath}" "Unable to delete ${filePath}"
	
	# return
	return "${returnCode}"
}
function display_Notification_FDN() {
	# $1: title
	# $2: subtitle
	# $3: message
	
	local returnCode=""
	
	verify_LoggedIn_FDN "-1"
	returnCode="$?"
	
	# if user is logged in and script is running as root
	if [[ "${returnCode}" -eq "0" && "${EUID}" -eq "0" ]]; then
		run_AsUser_FDN osascript -e 'display notification "'"$3"'" with title "'"$1"'" subtitle "'"$2"'"'
		
	# if user is logged in and script is running as the user
	elif [[ "${returnCode}" -eq "0" && "${EUID}" -ne "0" ]]; then
		osascript -e 'display notification "'"$3"'" with title "'"$1"'" subtitle "'"$2"'"'
		
	else
		# cache the notification messaging
		echo "$1${kNEWLINE}$2${kNEWLINE}$3" >> "${kVARTMP}/com.loops.notification"
	fi
}

# E --------------------------------------------------------------------------------------------------------------------------------
function echo_Log() {
	# $1: text to save to log
	
	printf '%s\n' "$1" >> "${kLOGFILE}"
}

# G --------------------------------------------------------------------------------------------------------------------------------
function generate_Launchd_FDN() {
	# generate the LaunchAgent|LaunchDaemon plist
	
	local plistPath=""
	local returnCode=""
	
	plistPath="${_LAUNCHPLIST}"

	# if user LaunchAgent
	if [[ "${EUID}" -ne "0" ]]; then
		# make sure the ~/Library/LaunchAgent folder exists
		mkdir -m 755 "${plistPath%/*}" &> /dev/null
		# if directory does not exist
		if [[ ! -d "${plistPath%/*}" ]]; then
			returnCode="1"
		fi
		
		go_NoGo_FDN "${returnCode}" "${plistPath%/*}, created or exists." "Unable to create ${plistPath%/*}."
		
		# set ownership
		chown "${kUSER}:staff" "${plistPath%/*}"
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "Set ownership for ${kHOME}/Library/LaunchAgent to ${kUSER}:staff." "Unable to set ownership for ${kHOME}/Library/LaunchAgent to ${kUSER}:staff."
	fi

	# write out the LaunchAgent|LaunchDaemon plist
cat <<PLISTEOF >"${plistPath}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<false/>
	<key>EnvironmentVariables</key>
	<dict>
		<key>PATH</key>
		<string>/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/usr/local/sbin:/opt/local/bin</string>
	</dict>
	<key>Label</key>
	<string>${_LANAME%.*}</string>
PLISTEOF

	# if need to watch a file, add watch file path
	if [[ -n "${_WATCHPATH}" ]]; then
cat <<PLISTEOF >>"${plistPath}"
	<key>WatchPaths</key>
	<array>
		<string>${_WATCHPATH}</string>
	</array>
PLISTEOF
	fi
	
	# complete the LaunchAgent|LaunchDaemon plist
cat <<PLISTEOF >>"${plistPath}"
	<key>ProgramArguments</key>
	<array>
		<string>${_LASCRIPTPATH}</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
PLISTEOF
	
	returnCode="$?"

	go_NoGo_FDN "${returnCode}" "Created ${plistPath}." "Unable to create ${plistPath}."
}
function get_MDM_FDN() {
	# returns: MDM URL,MDM vendor
	
	local profileXML=""
	local mdmURL=""
	local mdmVendor=""
	local msgTxt=""
	local returnCode=""
	
	returnCode="1"
	msgTxt="Not enrolled in MDM."
	mdmVendor="Indeterminant"
	
	# verify enrolled in MDM
	if [[ -n "$( profiles list -output stdout-xml | awk '/com.apple.mdm/ {print $1}' | tail -1 )" && "${returnCode}" -eq "1" ]]; then
		returnCode="1"
		msgTxt="Failed to read MDM profile."
		
		profileXML="$( profiles list -output stdout-xml | xmllint --xpath '//dict[key = "_computerlevel"]/array/dict[key = "ProfileItems"]/array/dict[key = "PayloadType" and string = "com.apple.mdm"]' - 2> /dev/null )"
	fi
	
	# if items returned
	if [[ -n "${profileXML}" ]]; then
		returnCode="1"
		msgTxt="Failed to read MDM URL."
		
		mdmURL="$( xmllint --xpath '//dict[key = "PayloadContent"]/dict/key[text() = "ServerURL"]/following-sibling::string[1]/text()' - 2>/dev/null <<< "${profileXML}" )"
	fi
	
	# if items returned
	if [[ -n "${mdmURL}" ]]; then
		mdmURL="${mdmURL%//*}//$( awk -F '/' '{print $3}' <<< "${mdmURL}" )"
		
		# determine the MDM
		case "${mdmURL}" in
		*jamf*)
			mdmVendor="Jamf"
			;;
		*mosyle*)
			mdmVendor="Mosyle"
			;;
		*intune*|*microsoft*)
			mdmVendor="Intune"
			;;
		esac
		
		returnCode="0"
		msgTxt="MDM ${mdmVendor}, URL: ${mdmURL}."
	fi
	
	# return
	echo "${mdmURL},${mdmVendor}"
	
	return "${returnCode}"
}
function go_NoGo_FDN() {
	# $1: return code
	# $2: OK message
	# $3: error message
	# returns: 0 or 1

	# function depends upon the availability of the variable _LOGTXT

	local msgTxt=""
	local errMsg=""
	local funcName=""
	local logStamp=""
	local i=""
	local returnCode=""

	logStamp="$( date -j +%F\ %H:%M:%S ) "
	returnCode="$1"
	msgTxt="$( awk '!/[[:punct:]]$/ && NF{$NF=$NF"."}1' <<< "$2" )" # inject a period if one does not exist
	errMsg="$( awk '!/[[:punct:]]$/ && NF{$NF=$NF"."}1' <<< "$3" )" # inject a period if one does not exist
	funcName="${FUNCNAME[1]}"
	
	# loop through called functions
	for ((i=2; i<${#FUNCNAME[@]}; i++)); do
		# if called from another function
		if [[ "${FUNCNAME[i]}" != "__start__" && "${FUNCNAME[i]}" != "main" ]]; then
			# add calling function
			funcName="${FUNCNAME[i]}:${funcName}"
			
		# if at end of call chain
		elif [[ "${FUNCNAME[i]}" == "__start__" || "${FUNCNAME[i]}" == "main" ]]; then
			# exit
			break
		fi
	done

	# if log the message
	if [[ "${returnCode}" -eq "0" ]]; then
		returnCode="0"
		_LOGTXT="${_LOGTXT}${kNEWLINE}${logStamp}[${kUSER}] - ${funcName}: ${msgTxt}"
		
	# if log the error message and move on
	elif [[ "${returnCode}" -lt "0" ]]; then
		returnCode="0"
		_LOGTXT="${_LOGTXT}${kNEWLINE}${logStamp}[${kUSER}] - ${funcName}: ⚠️${errMsg}"
		
		# track the error message for potential future processing
		_ERRTRACKMSG="${logStamp}[${kUSER}] - ${kSCRIPTNAME}:${funcName}: ${errMsg}"
		
	# if error, trap and exit
	else
		# if not an error from get_OptArgs
		if [[ "${returnCode}" -ne "99" ]]; then
			# include log stamp
			errMsg="${logStamp}[${kUSER}] - ${kSCRIPTNAME}:${funcName}: ${errMsg}"
			
			# if the file exists and there is something in it
			if [[ -s "${kERRMSGFILE}" ]]; then
				# get the error message from the file and add it to the string
				errMsg+=", $(<"${kERRMSGFILE}")"
				# delete the file so the message is not errantly repeated
				rm -f "${kERRMSGFILE}" &> /dev/null
			fi
			
			# if something in _LOGTXT
			if [[ -n "${_LOGTXT}" ]]; then
				# need to purge _LOGTXT to the log
				write_2Log_FDN "${_LOGTXT}"
			fi
			
			# write out to the error log
			echo "${errMsg}" >> "${kERRLOG}"
			
			# set the user output message
			_ERRTRACKMSG="${errMsg}"
			
			# write error to logging
			write_2Log_FDN "${_ERRTRACKMSG}"
			
			# set final user output message
			_ERRTRACKMSG="${kNEWLINE}${_ERRTRACKMSG}"
			
		else
			# set the user output message
			_ERRTRACKMSG="${logStamp}[${kUSER}] - ${kSCRIPTNAME}:${funcName}: ${errMsg}"
		fi
		
		# force trap_Exit
		exit "${returnCode}"
	fi

	# return
	return "${returnCode}"
}

# K --------------------------------------------------------------------------------------------------------------------------------
function kill_ActivePIDs_FDN() {
	local i=""
	local pid=""
	local returnCode=""
	
	declare -a activePIDs_a

	# if the active PID file exists
	if [[ -e "${kACTIVEPIDFILE}" ]]; then
		echo >&2
		echo "Terminating active processes..." >&2
		
		# put active PIDs into an array
		IFS=$'\n' read -d '' -r -a activePIDs_a <<< "$( cat "${kACTIVEPIDFILE}" )"
		
		# loop through the active PIDs
		for i in "${activePIDs_a[@]}"; do
			# if a PID exists
			if [[ -n "${i}" ]]; then
				pid="${i%,*}" # get the PID
				
				# if running
				if ps -p "${pid}" > /dev/null; then
					# kill the PID nicely
					kill -15 "${pid}" &> /dev/null
					returnCode="$?"
					
					# if unable to kill the PID
					if [[ "${returnCode}" -ne "0" ]]; then
						# kill the PID
						kill -9 "${pid}" &> /dev/null
						returnCode="$?"
					fi
					
					returnCode="$((returnCode*-1))"
					go_NoGo_FDN "${returnCode}" "Termiated PID=${pid}." "Unable to terminate PID=${pid}."
				fi
			fi
		done
		
		# delete the active PID file
		delete_File_FDN "${kACTIVEPIDFILE}"
		
		write_2Log_FDN "${_LOGTXT}"
	fi
}

# L --------------------------------------------------------------------------------------------------------------------------------
function launchd_JobActive_FDN() {
	# get the state of the launchd job based on the passed job name
	# $1: launchd job name
	# return: 0=job active, 1=job not active

	launchctl list | grep "$1" &> /dev/null
	
	# return
	return "$?"
}
function launchd_Load_FDN() {
	# load the launchd job passed on the passed plist path
	# $1: launchd plist path

	local serviceName=""
	local returnCode=""
	
	serviceName="${1##*/}"
	serviceName="${serviceName%.*}"
	# <Foundation overrides>
	kUSER="$( stat -f%Su /dev/console )"
	kUID="$( id -u "${kUSER}" )"
	# </Foundation overrides>
	returnCode="-1"
	
	# if LaunchDaemon
	if [[ "$1" == *"LaunchDaemons"* ]]; then
		launchctl bootstrap system "$1" > /dev/null 2>&1
		
	# if LaunchAgent and user is logged in
	elif [[ "$1" == *"LaunchAgents"* && "${kUID}" -ge "501" ]]; then
		# try to launch as user
		run_AsUser_FDN launchctl bootout "gui/${kUID}/${serviceName}" > /dev/null 2>&1
		run_AsUser_FDN launchctl bootstrap "gui/${kUID} $1" > /dev/null 2>&1
		
	# if run LaunchAgent as system
	elif [[ "$1" == *"LaunchAgents"* ]]; then
		# try to launch as system
		launchctl bootout "system/${serviceName}" > /dev/null 2>&1
		launchctl bootstrap system "$1" > /dev/null 2>&1
	fi

	returnCode="$(($?*-1))"

	go_NoGo_FDN "${returnCode}" "Loaded $1." "Unable to load $1."
}
function launchd_Unload_FDN() {
	# unload the launchd job
	# $1: 0=just unload, 1=unload and delete plist, 2=unload and delete script, 3=unload, delete plist, delete script
	# $2: job name
	# $3: plist path
	# $4: script path
	
	local launchdType=""
	local launchdBootOut=""
	local userLaunchAgent=""
	local returnCode=""
	
	launchdType="LaunchAgent"
	launchdBootOut="gui/${kUID}/$2"
	userLaunchAgent="$( print gui/"${kUID}" | grep "$2" )"
	
	# if running as root and not running as a user LaunchAgent
	if [[ -z "${userLaunchAgent}" && "${EUID}" -eq "0" ]]; then
		launchdType="LaunchDaemon"
		launchdBootOut="system/$2"
	fi
	
	# if need to delete plist or script
	if [[ "$1" -gt "0" ]]; then
		# if delete plist if exists
		if [[ ("$1" -eq "1" || "$1" -eq "3") && -e "$3" ]]; then
			# delete the LaunchAgent|LaunchDaemon plist
			rm -f "$3" &> /dev/null
			returnCode="$?"
			
			go_NoGo_FDN "${returnCode}" "Deleted ${launchdType} $3." "Unable to delete ${launchdType} $3."
		fi
		
		# if delete script
		if [[ ("$1" -eq "2" || "$1" -eq "3") && -e "$4" ]]; then
			# delete the script
			rm -f "$4" &> /dev/null
			returnCode="$?"
			
			go_NoGo_FDN "${returnCode}" "Deleted ${launchdType} script $4." "Unable to delete ${launchdType} script $4."
		fi
	fi
	
	# check to see if the launchd job is active
	launchd_JobActive_FDN "${_LANAME%.*}"
	returnCode="$?"
	
	# if launchd job is active
	if [[ "${returnCode}" -eq "0" ]]; then
		launchctl bootout "${launchdBootOut}" > /dev/null 2>&1
		returnCode="$(($?*-1))"
		
		go_NoGo_FDN "${returnCode}" "Unloaded ${launchdType} $2." "Unable to unload ${launchdType} $2."
	fi
	
	# delete the launch signal file
	delete_File_FDN "${kLAUNCHSIGNAL}"
	
	# delete the launch signal file
	delete_File_FDN "${kMANUALSIGNAL}"
	
	# delete the watch file
	delete_File_FDN "${_WATCHPATH}"
}

# O --------------------------------------------------------------------------------------------------------------------------------
function open_App_FDN() {
	# $1: full app name
	
	# if launch bit is set and running in the user space
	if [[ "${launchBit}" -ne "0" && "${kUID}" -ge "501" && "$( pgrep Dock )" && "$( pgrep Finder )" && "$( pgrep WindowServer )" ]]; then
		open -a "$1" &> /dev/null
		returnCode="$(($?*-1))"
		
		go_NoGo_FDN "${returnCode}" "Launched $1." "Unable to launch $1."
	fi
}

# P --------------------------------------------------------------------------------------------------------------------------------
function packages_GetInstalled_FDN() {
	# get a list of installed packages
	
	declare -a installedPKGs_a
	
	# remove the installed packages list
	delete_File_FDN "${kINSTALLEDPACKAGELIST}"
	
	# write out the list of currently installed packages
	{
	pkgutil --pkgs=.\+_Instruments\+
	pkgutil --pkgs=.\+BasicContent\+
	pkgutil --pkgs=.\+MAContent10_.\+
	pkgutil --pkgs=.\+JamPack1\+
	} > "${kINSTALLEDPACKAGELIST}"
	
	# dedup the file
	sort -o "${kINSTALLEDPACKAGELIST}" -u "${kINSTALLEDPACKAGELIST}"
	returnCode="$(($?*-1))"
	
	go_NoGo_FDN "${returnCode}" "Removed any duplicate entries from ${kINSTALLEDPACKAGELIST##*/}" "Unable to remove any duplicate entries from ${kINSTALLEDPACKAGELIST##*/}"

	# read the installed packages to array
	IFS=$'\n' read -d '' -r -a installedPKGs_a <<< "$( cat "${kINSTALLEDPACKAGELIST}" 2> /dev/null )"

	# if installed packages
	if [[ "${#installedPKGs_a[@]}" -ne "0" ]]; then
		shopt -s extglob >&2
		
		# remove com.apple.pkg from each array element
		installedPKGs_a=( "${installedPKGs_a[@]##*(com.apple.pkg.)}" )
		
		shopt -u extglob >&2
		
		# resave the file
		printf "%s\n" "${installedPKGs_a[@]}" > "${kINSTALLEDPACKAGELIST}"
		
		# append .pkg to each line of the file
		sed -i '' -e 's/$/.pkg/' "${kINSTALLEDPACKAGELIST}"
	fi
	
	go_NoGo_FDN "0" "${#installedPKGs_a[@]} packages installed based on package receipts" ""
	
	write_2Log_FDN "${_LOGTXT}"
}
function packages_InstalledPackageCount_FDN() {
	# get all installed package counts by loop type
	
	local i=""
	local j=""
	local start=""
	local end=""
	local typeName=""
	local typeStart=""
	local typeEnd=""
	local typeFile=""
	local tmpTypeFile=""
	local diffFile=""
	local removedFile=""
	local pkgCount=""
	local returnCode=""
	
	start="0"
	end="3"
	typeStart="0"
	typeEnd="2"
	index="0"
	diffFile="${kVARTMP}/diffFile.txt"
	removedFile="${kVARTMP}/${kREVERSEDNS}.removed.txt"
	
	declare -a installedPKGs_a
	
	# loop through the files: garageband, index=0; logic, index=1; mainstage, index=2
	for (( i = start; i < end; ++i )); do
		# loop through the package types, 0=essential, 1=optional
		for (( j = typeStart; j < typeEnd; ++j )); do
			typeName="${kESSENTIAL}"
			pkgCount="0"
			
			# if optional
			if [[ "${j}" -ne "0" ]]; then
				typeName="${kOPTIONAL}"
			fi
			
			IFS=$'\n' read -d '' -r -a installedPKGs_a <<< "$( cat "${kINSTALLEDPACKAGELIST}" 2> /dev/null )"
			
			# if installed packages
			if [[ "${#installedPKGs_a[@]}" -ne "0" ]]; then
				typeFile="${kVARTMP}/${kREVERSEDNS}.${typeName}${i}.txt"
				tmpTypeFile="${kVARTMP}/${kREVERSEDNS}.tmp.${typeName}${i}.txt"
				
				# if the typeFile exists
				if [[ -e "${typeFile}" ]]; then
					# make a copy of the packages list
					cp "${typeFile}" "${tmpTypeFile}"
					returnCode="$?"
					
					go_NoGo_FDN "${returnCode}" "Duplicated ${typeFile##*/}" "Unable to duplicate ${typeFile##*/}"
					
					# remove prefixes to match contents of kINSTALLEDPACKAGELIST
					sed -i '' 's/..\/lp10_ms3_content_2013\///g' "${tmpTypeFile}"
					returnCode="$?"
					
					go_NoGo_FDN "${returnCode}" "Removed ../lp10_ms3_content_2013 prefixes from ${tmpTypeFile##*/}" "Unable to remove ../lp10_ms3_content_2013 prefixes from ${tmpTypeFile##*/}"
					
					# remove the installed packages from the global essential or optional file
					compare_Files_FDN "diff" "${tmpTypeFile}" "${kINSTALLEDPACKAGELIST}" "${diffFile}"
					returnCode="$?"
					
					# get the removed packages
					compare_Files_FDN "diff" "${tmpTypeFile}" "${diffFile}" "${removedFile}"
					returnCode="$(($?+$?))"
					
					# get the count
					pkgCount="$( wc -l "${removedFile}" | awk '{print $1}' )"
					
					# if returned count is higher than pkgutil is reporting or one of the files to compare did not exist
					if [[ "${pkgCount}" -gt "$( wc -l "${kINSTALLEDPACKAGELIST}" | awk '{print $1}' )" || "${returnCode}" -eq "1" || -z "${pkgCount}" || ("${returnCode}" -eq "2" && "${pkgCount}" -eq "0") ]]; then
						# no packages installed
						pkgCount="0"
						returnCode="0"
					fi
				fi
			fi
			
			# if packages to report
			if [[ "${pkgCount}" -ne "0" ]]; then
				go_NoGo_FDN "${returnCode}" "${pkgCount} ${_appName_a[i]} ${typeName} package(s) installed based on package receipts" "Unable to retrieve ${_appName_a[i]} ${typeName} package count"
				
				pref_Write_FDN "${_keys_a[index]}" "${pkgCount% *}" "${kPREFSFILE}"
			fi
			
			((index++))
		done
		
		# empty or delete the files
		truncate -s 0 "${diffFile}"
		truncate -s 0 "${removedFile}"
		delete_File_FDN "${tmpTypeFile}"
	done
	
	# delete diff file
	delete_File_FDN "${diffFile}"
	
	# delete the removed file
	delete_File_FDN "${removedFile}"
	
	write_2Log_FDN "${_LOGTXT}"
}
function pre_Flight_FDN() {
	# $1: optional flag, OK to run as user
	# $2: optional flag, turn on logging
	
	local byPassLogging=""
	local returnCode=""
	
	# turn off logging temporarily
	byPassLogging="ON"
	
	# if logging on
	if [[ "$2" ]]; then
		byPassLogging=""
	fi
	
	# check running user type
	verify_Root_FDN
	returnCode="$?"
	
	# if must be run as root
	if [[ "${returnCode}" -eq "99" && -z "$1" ]]; then
		go_NoGo_FDN "${returnCode}" "" "Script must be run as root."
		
		echo "Script must be run as root."
	fi
	
	# make sure the log folder exists
	mkdir -m 755 "${kLOGPATH}" &> /dev/null
	returnCode="0"
	
	# if directory does not exist
	if [[ ! -d "${kLOGPATH}" ]]; then
		returnCode="99" # exit without logging, otherwise will loop forever attempting to write to the log
	fi
	
	# if logging not bypassed or an error
	if [[ -z "${byPassLogging}" || "${returnCode}" -eq "99" ]]; then
		go_NoGo_FDN "${returnCode}" "${kLOGPATH}, created or exists." "Unable to create ${kLOGPATH}."
	fi
	
	# create the temp directory
	mkdir -m 777 "${kVARTMP}" &> /dev/null
	
	# if directory does not exist
	if [[ ! -d "${kVARTMP}" ]]; then
		returnCode="99" # exit without logging, otherwise will loop forever attempting to write to the log
	fi
	
	# if logging not bypassed or an error
	if [[ -z "${byPassLogging}" || "${returnCode}" -eq "99" ]]; then
		go_NoGo_FDN "${returnCode}" "${kVARTMP}, created or exists." "Unable to create ${kVARTMP}."
	fi
}
function pref_Read_FDN() {
	# $1: key
	# $2: path to file
	# returns: value or blank, exit code 0=OK, 1=fail
	
	local key=""
	local filePath=""
	local capturedOutput=""
	local returnCode=""
	
	key="$1"
	filePath="$2"

	capturedOutput="$( defaults read "${filePath}" "${key}" 2> /dev/null )"
	returnCode="$(($?*-1))"
	
	go_NoGo_FDN "${returnCode}" "Read ${key} from ${filePath##*/}." "Unable to read ${key} from ${filePath##*/}."
	
	# return
	echo "${capturedOutput}"
	return "$((returnCode*-1))"
}
function pref_Write_FDN() {
	# $1: key
	# $2: value
	# $3: path to file
	# returns: exit code 0=OK, 1=fail
	
	local key=""
	local value=""
	local filePath=""
	local octalPermissions=""
	local returnCode=""
	
	key="$1"
	value="$2"
	filePath="$3"
	
	# get the files current permissions
	octalPermissions="$( stat -f '%A' "${filePath}" 2> /dev/null )"
	
	defaults write "${filePath}" "${key}" "${value}" 2> /dev/null
	returnCode="$(($?*-1))"
	
	go_NoGo_FDN "${returnCode}" "Wrote ${key}=${value} to ${filePath##*/}." "Unable to write ${key}=${value} to ${filePath##*/}."
	
	# if permissions changed
	if [[ "$( stat -f '%A' "${filePath}" 2> /dev/null )" -ne "${octalPermissions}" ]]; then
		set_Permissions_FDN "${filePath}"
	fi
	
	# return
	return "$((returnCode*-1))"
}

# R --------------------------------------------------------------------------------------------------------------------------------
function remove_ColorFormatting_FDN() {
	# $1: string
	# returns: string w/o color formatting
	
	shopt -s extglob >&2
	# return
	echo "${1//$'\e'[\[(]*([0-9;])[@-n]/}"
	shopt -u extglob >&2
}
function run_AsUser_FDN() {
	# $@: command to run as logged in user
	# returns: 0 or -1 exit code
	
	local returnCode=""
	
	returnCode="-1"
	
	launchctl asuser "${kUID}" sudo -u "${kUSER}" "$@"
	returnCode="$?"
	
	go_NoGo_FDN "${returnCode}" "Command $* run as ${kUSER}." "Unable to run command $* as ${kUSER}."
	
	# return
	return "${returnCode}"
}

# S --------------------------------------------------------------------------------------------------------------------------------
function search_Array_FDN() {
	# $1: array to search
	# $2: seach term
	# returns: value found or null
	
	local i=""
	local searchTerm=""
	
	declare -a array_a
	
	array_a=("$@")
	searchTerm="${array_a[${#array_a[@]}-1]}"
	
	# remove search term from array, $2
	unset "array_a[${#array_a[@]}-1]"
	
	# loop through the array looking for search term
	for i in "${array_a[@]}"; do
		if [[ "${i}" == *"${searchTerm}"* ]]; then
			# return found value
			echo "${i}"
			
			# exit
			return
		fi
	done
	
	# return null
	echo "${searchTerm}"
	return 1
}
function set_Ownership_FDN() {
	# $1: file or directory path
	
	local group=""
	local returnCode=""
	
	group="staff"
	
	# if running as root
	if [[ "${EUID}" -eq "0" ]]; then
		# if a directory
		if [[ -d "$1" ]]; then
			group="wheel"
		fi
		
		# reset the owner
		chown "${kUSER}":"${group}" "$1" &> /dev/null
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "Set ownership for ${1##*/} to ${kUSER}:${group}" "Unable to set ownership for ${1##*/} to ${kUSER}:${group}"
	fi
}
function set_Permissions_FDN() {
	# $1: file or directoy path
	
	local returnCode=""
	
	# if running as root
	if [[ "${EUID}" -eq "0" ]]; then
		# -rw-rw-rw
		chmod 644 "$1" &> /dev/null
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "Set permissions for ${1##*/} to 644" "Unable to set permissions for ${1##*/} to 644"
	fi
}
function skip_Function_FDN() {
	# checks packages are only being verified or installed or there are no packages to download
	
	# $1: flag, optional: packages, verify, download, parse, or force
	# returns: 0=don't skip, 1=skip
	
	local returnCode=""
	
	returnCode="0"
	
	# if only verifying or installing packages
	# 		  (downloadBit=none			&&		installBit=yes)			 || 	(downloadBit=none		  &&	 pathBit=yes)			   ||		packages	  ||		verify
	if [[ ("${_STATUSCODE:0:1}" -eq "3" && "${_STATUSCODE:3:1}" -eq "1") || ("${_STATUSCODE:0:1}" -eq "3" && "${_STATUSCODE:2:1}" -eq "1") || ("$1" == "packages" || "$1" == "verify") ]]; then
		# exit
		returnCode="1"
		
	# if there are no packages to download
	#			array is empty				 &&			 download
	elif [[ "${#_downloadPKGs_a[@]}" -eq "0" && "$1" == "download" ]]; then
		# exit
		returnCode="1"
		
	# if either
	#		(downloadBit=none		 	  &&	# installBit=yes)		   ||	(downloadBit=none			&&		# pathBit=yes)			 ||		(no download packages		  &&	 download flag)
	elif [[ ("${_STATUSCODE:0:1}" -eq "3" && "${_STATUSCODE:3:1}" -eq "1") || ("${_STATUSCODE:0:1}" -eq "3" && "${_STATUSCODE:2:1}" -eq "1") || ("${#_downloadPKGs_a[@]}" -eq "0" && "$1" == "download") ]]; then
		# exit
		returnCode="1"
		
	# if forcing download
	#			downloadBit=yes	  		 &&		force
	elif [[ "${_STATUSCODE:0:1}" -ne "3" && "$1" == "1" ]]; then
			# exit
			returnCode="1"
			
	# if no plist change, no need to parse the downloaded plists
	#		downloadBit=yes				  &&	  flag
	elif [[ "${_STATUSCODE:0:1}" -ne "3"  && "$1" == "parse" ]]; then
		# if the downloaded config versions match the previously parsed config versions and all the package list files exist and are >0 in size
		if [[ "${_configVersion_a[0]}" -eq "${_configVersion_a[3]}" && "${_configVersion_a[1]}" -eq "${_configVersion_a[4]}" && "${_configVersion_a[2]}" -eq "${_configVersion_a[5]}" && -s "${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}0.txt" && -s "${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}0.txt" && -s "${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}1.txt" && -s "${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}1.txt" && -s "${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}2.txt" && -s "${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}2.txt" ]]; then
			# exit
			returnCode="1"
		fi
	fi
	
	# return
	return "${returnCode}"
}

# T --------------------------------------------------------------------------------------------------------------------------------
function trim_WhiteSpace_FDN() {
	# $1: string
	# $2: optional: leading, trailing, or null=both
	# returns: trimmed string
	
	local trimmed=""
	
	trimmed="$1"
	
	# turn on the extglob shell option
	shopt -s extglob

	# if trim leading white space
	if [[ -z "$2" || "$2" == "leading" ]]; then
		# trim leading whitespaces 
		trimmed="${trimmed##*( )}"
	fi

	# if trim trailing white space
	if [[ -z "$2" || "$2" == "trailing" ]]; then
		# trim trailing whitespaces
		trimmed="${trimmed%%*( )}"
	fi
	
	# turn off the extglob shell option
	shopt -u extglob
	
	# return
	echo "${trimmed}"
}
function trap_Error_FDN() {
	# $1: error code of last command
	# $2: last line of error occurrence
	# $3: offending command
	
	local lastLine=""
	local lastErr=""
	local offendingCommand=""
	local errMsg=""
	local logStamp=""
	local funcName=""
	
	lastErr="$1"
	lastLine="$2"
	offendingCommand="$3"
	logStamp="$( date -j +%F\ %H:%M:%S ) "
	funcName="${FUNCNAME[1]}"
	
	case "${lastErr}" in
	1)
		exitStatus="general error"
		;;
	2)
		exitStatus="misuse of shell builtins"
		;;
	127)
		exitStatus="command not found"
		;;
	128 )
		exitStatus="invalid argument to exit"
		;;
	130)
		exitStatus="script terminated by Control-C"
		;;
	*)
		exitStatus="fatal error signal or exit status out of range"
		;;
	esac
	
	# if lastErr > 0 then echo error msg and log
	if [[ "${lastErr}" -ne "0" ]]; then
		echo "ERROR: ${logStamp}[${kUSER}] - ${kSCRIPTNAME}:${funcName} encountered an error. Line: ${lastLine}: Offending command: ${offendingCommand}: Exit status of last command: ${lastErr} (${exitStatus})" >> "${kERRLOG}"
		
		errMsg="${kNEWLINE}ERROR: ${logStamp}[${kUSER}] - ${kSCRIPTNAME}:${funcName} encountered an error.${kNEWLINE}Line: ${lastLine}${kNEWLINE}Offending command: ${offendingCommand}${kNEWLINE}Exit status of last command: ${lastErr} (${exitStatus})${kNEWLINE}"
		
		# set the user output message
		_ERRTRACKMSG="${_ERRTRACKMSG}${kNEWLINE}${errMsg}"
		
		write_2Log_FDN "${kNEWLINE}${_ERRTRACKMSG}"
		
		# clean up, remove any leftover files
		find "${kVARTMP}" -type f -name "*${kREVERSEDNS}*" -delete &> /dev/null
		
		# stop and exit the current command
		kill -s TERM "${kPID}"
	fi
}

# V --------------------------------------------------------------------------------------------------------------------------------
function verify_LoggedIn_FDN() {
	# $1: optional, duration, if -1, duration infinite
	# returns: 0=user logged in, -1=user not logged in
	
	local dockPID=""
	local finderPID=""
	local winServer=""
	local duration=""
	local end=""
	local returnCode=""
	
	duration="120"
	end="$(( SECONDS+duration ))"
	returnCode="0"
	
	# if passed duration
	if [[ -n "$1" ]]; then
		duration="$1"
	fi
	
	# wait for the Finder, Dock, WindowServer, and user -ge 501
	# shellcheck disable=SC2034
	until dockPID=$( pgrep -x Dock ) && finderPID=$( pgrep -x Finder) && winServer=$( pgrep -x WindowServer ) && [ "${kUID}" -gt "500" ]; do
		sleep .01
		
		# if timed out
		if [[ "${SECONDS}" -gt "${end}" && "${duration}" -ne "-1" ]]; then
			returnCode="-1"
			break
		fi
		
		# recheck the logged in user
		kUSER="$( stat -f%Su /dev/console )"
		kUID="$( id -u "${kUSER}" )"
	done
	
	go_NoGo_FDN "${returnCode}" "${kUSER} logged in: Finder, Dock, and WindowServer available." "Timed out waiting for ${kUSER} to login."
	
	return "${returnCode}"
}
function verify_Network_FDN() {
	local duration=""
	local end=""
	local returnCode=""

	duration="480" # default=2 minutes
	returnCode="0"
	
	# if no network connection
	if [[ "$( scutil --nwi )" == *"(Not Reachable)"* ]]; then
		echo "Waiting for network connection..." >&2
		
		go_NoGo_FDN "0" "Waiting for network connection" ""
		
		write_2Log_FDN "${_LOGTXT}"
		
		returnCode="1"
		end="$((SECONDS+duration))"
		
		# wait for the specified amount of time
		until [[ "${SECONDS}" -gt "${end}" ]]; do
			# if network connection is active
			if [[ "$( scutil --nwi )" == *"(Reachable)"* ]]; then
				returnCode="0"
				
				# exit the loop
				break
			fi
			
			# wait half a second
			sleep 0.5
		done
		
		go_NoGo_FDN "${returnCode}" "Network connection available" "Network connection unavailable"
		
		write_2Log_FDN "${_LOGTXT}"
		
		# move back up a line
		echo -e "\033[2A" >&2 # move up a line
		echo -en $'\033[2K' >&2 # clear the line
	fi
	
	return "${returnCode}"
}
function verify_Root_FDN() {
	# returns 0 if running as root or 99 as user
	
	local returnCode=""
	
	returnCode="0"

	# if not running as root
	if [[ "${EUID}" -ne "0" ]]; then
		returnCode="99"
	fi
	
	# return
	return "${returnCode}"
}
function version_Check_FDN() {
	# compares version numbers passed as integers or decimals
	# $1: version to compare
	# $2: version to compare
	# returns: 0, 1, or 2
	#	0 if ver1_a = ver2_a
	#	1 if ver1_a > ver2_a
	#	2 if ver1_a < ver2_a

	local IFS="."
	local i="0"

	declare -a ver1_a
	declare -a ver2_a

	# values match, return 0
	if [[ "$1" == "$2" ]]; then
		return 0
	fi
	# shellcheck disable=SC2206
	{
		ver1_a=($1)
		ver2_a=($2)
	}
	
	# fill empty fields in ver1_a with zeros
	for ((i=${#ver1_a[@]}; i<${#ver2_a[@]}; i++)); do
		ver1_a[i]=0
	done

	for ((i=0; i<${#ver1_a[@]}; i++)); do
		# fill empty fields in ver2_a with zeros
		if [[ -z ${ver2_a[i]} ]]; then
			ver2_a[i]=0
		fi
		
		# if ver1_a > ver2_a, return 1
		if ((10#${ver1_a[i]} > 10#${ver2_a[i]})); then
			return 1
		fi
		
		# if ver1_a < ver2_a, return 2
		if ((10#${ver1_a[i]} < 10#${ver2_a[i]})); then
			return 2
		fi
	done

	# otherwise return 0
	return 0
}

# W --------------------------------------------------------------------------------------------------------------------------------
function wait_4File_FDN() {
	# $1: file to look for
	# $2: optional: length of time * 0.5
	
	local counter=""
	local duration=""
	
	counter="0"
	duration="240" # default=2 minutes
	
	# if duration was passed
	if [[ "$#" -eq "2" ]]; then
		duration="$2"
	fi
	
	# wait for the specified amount of time
	until [[ "${counter}" -eq "${duration}" ]]; do
		# wait for the specified amount of time
		if [[ -e "$1" ]]; then
			# wait tenth of a second
			sleep 0.1
			
			# exit the loop
			break
		else
			# wait half a second
			sleep 0.5
			
			((counter++))
		fi
	done

	# if the wait was longer then the passed value
	if [[ "${counter}" -ge "${duration}" ]]; then
		go_NoGo_FDN "1" "" "Timed out waiting for $1"
	fi
}
function write_2Log_FDN() {
	# $1: text block for writing to the log

	local i=""
	
	# if something passed
	if [[ -n "$1" && -z "${_BYPASSLOGGING}" ]]; then
		# loop through the passed parameters
		for  i in "$@"; do
			# write to log
			echo_Log "${i}"
		done
		
		# clear
		_LOGTXT=""
	fi
}

# X --------------------------------------------------------------------------------------------------------------------------------
function xattr_Delete_FDN() {
	# $1: xattr name
	# $2: path to file
	# returns: exit code 0=OK, 1=fail
	
	local returnCode=""
	
	xattr -d "${kREVERSEDNS}.$1" "$2" &> /dev/null
	returnCode="$?"
	
	go_NoGo_FDN "${returnCode}" "Deleted xattr ${kREVERSEDNS}.$1 from ${2##*/}." "Unable to delete xattr ${kREVERSEDNS}.$1 from ${2##*/}."
	
	# return
	return "${returnCode}"
}
function xattr_Get_FDN() {
	# $1: xattr
	# $2: path to file
	# $3: flag, optional. If exists, delete the xattr after reading.
	# $4: flag, optional. If exists, use kROOTREVERSEDNS.
	# returns: value or blank, exit code 0=OK, 1=fail
	
	local capturedOutput=""
	local reverseDNS=""
	local returnCode=""
	
	reverseDNS="${kREVERSEDNS}"
	# if flag use root reverse DNS
	if [[ -n "$4" ]]; then
		reverseDNS="${kROOTREVERSEDNS}"
	fi

	capturedOutput="$( xattr -p "${reverseDNS}.$1" "$2" 2> /dev/null )"
	returnCode="$?"
	
	go_NoGo_FDN "$((returnCode*-1))" "Read xattr ${reverseDNS}.$1 from ${2##*/}." "Unable to read xattr ${reverseDNS}.$1 from ${2##*/}."
	
	# if the xattr exists and flagged, delete
	if [[ "${returnCode}" -eq "0" && "$#" -eq "3" ]]; then
		xattr_Delete_FDN "$1" "$2"
	fi
	
	# return
	echo "${capturedOutput}"
	return "${returnCode}"
}
function xattr_Write_FDN() {
	# $1: xattr
	# $2: value
	# $3: path to file
	# $4: optional, redact log entry
	# $5: flag, optional. If exists, use kROOTREVERSEDNS.
	# returns: exit code 0=OK, 1=fail
	
	local msgTxt=""
	local value=""
	local reverseDNS=""
	local returnCode=""
	
	value="$2"
	reverseDNS="${kREVERSEDNS}"
	# if use root reverse DNS
	if [[ -n "$5" ]]; then
		reverseDNS="${kROOTREVERSEDNS}"
	fi
	
	xattr -w "${reverseDNS}.$1" "${value}" "$3" &> /dev/null
	returnCode="$?"
	
	# if passed null
	if [[ -z "$2" ]]; then
		value="null"
	fi
	
	# if redact log entry
	if [[ -n "$4" ]]; then
		value="<private>"
	fi
	
	go_NoGo_FDN "${returnCode}" "Wrote ${value} to xattr ${reverseDNS}.$1 to ${3##*/}." "Unable to write ${value} to xattr ${reverseDNS}.$1 to ${3##*/}."
	
	# return
	return "${returnCode}"
}
function xml_ErrorCheck_FDN() {
	# $1: response code
	# $2: code to check
	# $3: resource being checked
	# $4: optional, only report and continue
	# returns: 0, 1, or -1
	
	local responseCode=""
	local returnCode=""
	local errorMsg=""
	local errorIcon=""
	local i=""
	
	responseCode="${1%,*}"
	errorIcon="⛔️"
	returnCode="0"
	
	# if error
	if [[ "${responseCode}" != "$2" ]]; then
		returnCode="1"
		responseCode="E${responseCode}"
		
		# if curl threw an error
		if [[ "${1#*,}" -gt "0" ]]; then
			responseCode="E${1#*,}"
		fi
		
		# if passed optional report and continue flag
		if [[ -n "$4" ]]; then
			returnCode="-1"
			errorIcon="⚠️"
		fi
		
		# loop through the error code array
		for i in "${!_errorCodes_a[@]}"; do
			# if the error code is found
			if [[  ${_errorCodes_a[i]}  =~  ${responseCode}  ]]; then
				errorMsg="${_errorCodes_a[i]}"
				
				# exit loop
				break
			fi
		done
		
		go_NoGo_FDN "${returnCode}" "" "${errorIcon} Error: resource=$3, error codes=$1, ${errorMsg}."
		
		write_2Log_FDN "${_LOGTXT}"
	fi
	
	# return
	return "${returnCode}"
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------

declare_Constants_FDN
declare_Globals_FDN
FDNEOF

	# return
	return "$?"
}
function freespace_Download() {
	# determine available download freespace
	
	local returnCode=""
	
	# if only verifying, exit the function
	skip_Function_FDN "verify" || return 0
	
	# check for enough disk space to download packages
	case "${downloadBit}" in
	0|4|9) # essential
		msgTxt="${appName}${kESSENTIAL} packages"
		
		# check diskFreeSpace against _DOWNLOADSIZEESSENTIAL
		if [[ "${diskFreeSpace}" -lt "${_DOWNLOADSIZEESSENTIAL}" ]]; then
			returnCode="1"
		fi
		;;
	1|5|A) # optional
		msgTxt="${appName}${kOPTIONAL} packages"
		
		# check diskFreeSpace against _DOWNLOADSIZEOPTIONAL
		if [[ "${diskFreeSpace}" -lt "${_DOWNLOADSIZEOPTIONAL}" ]]; then
			returnCode="1"
		fi
		;;
	2|7|8|B) # all
		msgTxt="all potential ${appName}packages"
		
		# check diskFreeSpace against _DOWNLOADSIZEOPTIONAL + _DOWNLOADSIZEESSENTIAL
		if [[ "${diskFreeSpace}" -lt "$((_DOWNLOADSIZEESSENTIAL+_DOWNLOADSIZEOPTIONAL))" ]]; then
			returnCode="1"
		fi
		;;
	*) # not downloading
		msgTxt=""
		;;
	esac

	# if something to log
	if [[ -n "${msgTxt}" ]]; then
		go_NoGo_FDN "${returnCode}" "Enough disk space to download ${msgTxt}." "Not enough disk space to download ${msgTxt}."
	fi
}
function freespace_Install() {
	# determine available install freespace
	
	local returnCode=""
	
	# check for enough disk space to install
	case "${downloadBit}" in
	0|4|9) # essential
		msgTxt="${appName}${kESSENTIAL} packages"
		;;
	1|5|A) # optional
		msgTxt="${appName}${kOPTIONAL} packages"
		;;
	2|7|8|B) # all
		msgTxt="all ${appName}packages"
		;;
	*) # not downloading
		msgTxt="packages"
		
		# if prefs file exists look up cached install sizes
		if [[ "${totalSize}" -eq "0" && -e "${prefsFile}" ]]; then
			# get cached information
			downloadBit="$( "${kPLISTBUDDY}" -c 'Print :downloadBit' "${prefsFile}" 2> /dev/null )"
			returnCode="$?"
			
			go_NoGo_FDN "${returnCode}" "Read downloadBit=${downloadBit} from ${prefsFile}." "Unable to read downloadBit from ${prefsFile}."
			
			_INSTALLSIZEESSENTIAL="$( "${kPLISTBUDDY}" -c 'Print :InstallSizeEssential' "${prefsFile}" 2> /dev/null )"
			returnCode="$?"
			
			go_NoGo_FDN "${returnCode}" "Read _INSTALLSIZEESSENTIAL=${_INSTALLSIZEESSENTIAL}B from ${prefsFile}." "Unable to read _INSTALLSIZEESSENTIAL from ${prefsFile}."
			
			_INSTALLSIZEOPTIONAL="$( "${kPLISTBUDDY}" -c 'Print :InstallSize' "${prefsFile}" 2> /dev/null )"
			returnCode="$?"
			
			go_NoGo_FDN "${returnCode}" "Read _INSTALLSIZEOPTIONAL=${_INSTALLSIZEOPTIONAL}B from ${prefsFile}." "Unable to read _INSTALLSIZEOPTIONAL from ${prefsFile}."
			
			# get disk space to install
			case "${downloadBit}" in
			0|4|9) # install essentials
				msgTxt="${kESSENTIAL} packages"
				totalSize="${_INSTALLSIZEESSENTIAL}"
				;;
			1|5|A) # install optionals
				msgTxt="${kOPTIONAL} packages"
				totalSize="${_INSTALLSIZEOPTIONAL}"
				;;
			2|7|8|B) # install all
				msgTxt="install all potential packages"
				totalSize="$((_INSTALLSIZEESSENTIAL+_INSTALLSIZEOPTIONAL))"
				;;
			esac
			
			returnCode="$?"
			
			convertedValue="$( convert_FromBytes2HumanReadable_FDN "${totalSize}" )"
			
			go_NoGo_FDN "${returnCode}" "totalSize=${totalSize}B (${convertedValue}) to ${msgTxt}" "Syntax error in expression for totalSize, ${msgTxt}"
		fi
		;;
	esac
	
	# if prefs file exists, check diskFreeSpace against _INSTALLSIZEESSENTIAL, _INSTALLSIZEOPTIONAL, or _INSTALLSIZEESSENTIAL + _INSTALLSIZEOPTIONAL
	if [[ "${diskFreeSpace}" -lt "${totalSize}" && -e "${prefsFile}" ]]; then
		returnCode="1"
	fi

	go_NoGo_FDN "${returnCode}" "Enough disk space to install ${msgTxt}." "Not enough disk space to install ${msgTxt}."
}
function freespace_Total() {
	# determine total freespace available
	
	local returnCode=""
	
	# if downloading and installing
	if [[ "${installBit}" -eq "1" && "${_DOWNLOADOPTARG}" != "none" ]]; then
		# get disk space to download and install
		case "${downloadBit}" in
		1|5|A) # install optionals
			msgTxt="download and install ${kOPTIONAL} ${appName}packages"
			totalSize="$((_INSTALLPADSIZE+_DOWNLOADSIZEOPTIONAL))"
			;;
		2|7|8|B) # install all
			msgTxt="download and install all potential ${appName}packages"
			totalSize="$((_INSTALLPADSIZE+_DOWNLOADSIZEOPTIONAL+_DOWNLOADSIZEESSENTIAL))"
			;;
		esac
		
		returnCode="$?"
		
	# if only installing
	elif [[ "${installBit}" -eq "1" || "${_DOWNLOADOPTARG}" == "none" ]]; then
		# get disk space to install
		case "${downloadBit}" in
		0|4|9) # install essentials
			msgTxt="install ${appName}${kESSENTIAL} packages"
			totalSize="${_INSTALLSIZEESSENTIAL}"
			;;
		1|5|A) # install optionals
			msgTxt="install ${appName}${kOPTIONAL} packages"
			totalSize="${_INSTALLSIZEOPTIONAL}"
			;;
		2|7|8|B) # install all
			msgTxt="install all ${appName}packages"
			totalSize="$((_INSTALLSIZEESSENTIAL+_INSTALLSIZEOPTIONAL))"
			;;
		esac
		
		returnCode="$?"
		
	# if only downloading
	elif [[ "${installBit}" -eq "0" && "${_DOWNLOADOPTARG}" != "none" ]]; then
		# get disk space to download
		case "${downloadBit}" in
		0|4|6|9) # download essentials
			msgTxt="download ${appName}${kESSENTIAL} packages"
			totalSize="${_DOWNLOADSIZEESSENTIAL}"
			;;
		1|5|A) # download optionals
			msgTxt="download ${appName}${kOPTIONAL} packages"
			totalSize="$((_DOWNLOADSIZEOPTIONAL))"
			;;
		2|7|8|B) # download all
			msgTxt="download all ${appName}packages"
			totalSize="$((_DOWNLOADSIZEOPTIONAL+_DOWNLOADSIZEESSENTIAL))"
			;;
		esac
		
		returnCode="$?"
	fi

	# if something to log
	if [[ "${totalSize}" -ne "0" ]]; then
		convertedValue="$( convert_FromBytes2HumanReadable_FDN "${totalSize}" )"
		
		go_NoGo_FDN "${returnCode}" "totalSize=${totalSize}B (${convertedValue}) to ${msgTxt}." "Syntax error in expression for totalSize, ${msgTxt}."
	fi
}

# G --------------------------------------------------------------------------------------------------------------------------------
function generate_ProcessScript() {
	# generate the LaunchAgent/LaunchDaemon script
	# $1: script name
	# $2: destination script path
	
	local scriptName=""
	local destPath=""
	local returnCode=""
	
	scriptName="$1"
	destPath="$2"
	
	# delete the script
	delete_File_FDN "${destPath}/${scriptName}"
	
	# move the script into place
	"${scriptName}" "${destPath}"
	returnCode="$?"
	
	go_NoGo_FDN "${returnCode}" "Created ${scriptName} at ${destPath}." "Unable to create ${scriptName} at ${destPath}."
	
	# remove quarantine flag
	xattr -d com.apple.quarantine "${destPath}/${scriptName}" &> /dev/null
	returnCode="$(($?*-1))"
	
	go_NoGo_FDN "${returnCode}" "Removed quarantine flag for ${scriptName}." "Unable to remove quarantine flag from ${scriptName} or does not exist."

	# set executable bit
	chmod +x "${destPath}/${scriptName}" 2> /dev/null
	returnCode="$?"
	
	go_NoGo_FDN "${returnCode}" "Set executable bit for ${scriptName}." "Unable to set executable bit for ${scriptName}."
}
function generate_URLConfigFile() {
	# generate the curlrc.txt file to be used by curl
	# $1: flag, optional, ignore cache server
	
	local audioContentURL=""
	local selectedCache=""
	local urlSuffix=""
	local pkgName=""
	local url=""
	local output=""
	local arraySize=""
	local i=""
	local msgTxt=""
	local tmpURLConfigFile=""
	local returnCode=""
	
	arraySize="${#_downloadPKGs_a[@]}"
	msgTxt=" packages to download"
	
	# if just one package
	if [[ "${arraySize}" -eq "1" ]]; then
		msgTxt=" package to download"
	fi
	
	audioContentURL="$( "${kPLISTBUDDY}" -c 'Print :audioContentURL' "${kPREFSFILE}" 2> /dev/null )"
	[ -n "${audioContentURL}" ]
	returnCode="$?"

	go_NoGo_FDN "${returnCode}" "Read audioContentURL from ${kPREFSFILE##*/}." "Unable to read audioContentURL from ${kPREFSFILE##*/}."

	# verify content caching server is available
	selectedCache="$( AssetCacheLocatorUtil 2>&1 | grep "rank" | grep "shared caching: yes" | cut -d' ' -f4,6 | sort -n -k2 | cut -d ',' -f1 | head -n 1 )"

	# set the urlSuffix for content caching
	urlSuffix="?source=${audioContentURL}&sourceScheme=https"

	# if selectedCache is blank or forcing
	if [[ -z "${selectedCache}" || "$#" -ne "0" ]]; then
		# fall back to CDN
		_URLCONFIGFILE="${kCDNURLCONFIGFILE}"
		selectedCache="${audioContentURL}"
		urlSuffix=""
		_URLTYPE="CDN"
		
		delete_File_FDN "${_URLCONFIGFILE}"
	fi

	go_NoGo_FDN "${returnCode}" "selectedCache=${selectedCache}" ""
	go_NoGo_FDN "${returnCode}" "urlSuffix=${urlSuffix}" ""
	go_NoGo_FDN "${returnCode}" "Example, url=http://${selectedCache}/${kMS3}/MAContent10_AssetPack_0539_DrummerTambourine.pkg${urlSuffix}" ""
	
	_LOGTXT="${_LOGTXT}${kNEWLINE}"
	go_NoGo_FDN "${returnCode}" "${arraySize}${msgTxt}." ""

	write_2Log_FDN "${_LOGTXT}"
	
	# loop through the packages array
	for i in "${_downloadPKGs_a[@]}"; do
		# get the package name, stripping off any prepended information
		pkgName="${i##*/}"
		
		# setup the URL configuration
		url="\"http://${selectedCache}/${kMS3}/${i}${urlSuffix}"\"
		output="\"${_SAVEPATH}/${pkgName}"\"
		
		# write out the URL configuration
		echo "url = ${url}" >> "${_URLCONFIGFILE}"
		echo "--output ${output}" >> "${_URLCONFIGFILE}"
		
		# write package to log
		go_NoGo_FDN "0" "Downloading package ${pkgName}." ""
		
		# remove newline from _LOGTXT
		_LOGTXT="${_LOGTXT//[$'\t\r\n']}"
		
		write_2Log_FDN "${_LOGTXT}"
	done
	
	# temp file for the URL config file
	tmpURLConfigFile="${_URLCONFIGFILE%%.txt*}.tmp.txt${_URLCONFIGFILE##*.txt}"
}
function get_Freespace() {
	# get freespace value the Finder will report as available in bytes
	# $1: path to volume
	# returns: freespace in bytes
	
osascript -l JavaScript << ASEOF
	ObjC.import('Foundation')
	var freeSpaceBytesRef=Ref()
	$.NSURL.fileURLWithPath('$1').getResourceValueForKeyError(freeSpaceBytesRef, 'NSURLVolumeAvailableCapacityForImportantUsageKey', null)
	ObjC.unwrap(freeSpaceBytesRef[0])
ASEOF
}
function get_AvailablePackageCount() {
	# parses the download plist (kDOWNLOADEDLOOPSPLIST) for each package type and gets the package count for each

	local pkgName=""
	local pkgsPlistFile=""
	local returnCode=""

	declare -a lines_a
	declare -a items_a
	declare -a essentialInstalled_a
	declare -a optionalInstalled_a

	pkgsPlistFile="${kVARTMP}/${kREVERSEDNS}.packages.plist"

	# loop through the plists: garageband, i=0; logic, i=1, mainstage, i=2
	for ((i=0; i<${#_appName_a[@]}; i++)); do
		# print the Packages dict to plist
		"${kPLISTBUDDY}" -x -c 'Print :Packages' "${kDOWNLOADEDLOOPSPLIST%.*}${i}.plist" > "${pkgsPlistFile}"
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "${pkgsPlistFile##*/} saved to ${kVARTMP}." "Unable to save ${pkgsPlistFile##*/} to ${kVARTMP}."
		
		# read the package names
		IFS=$'\n' read -d '' -r -a lines_a <<< "$( ${kPLISTBUDDY} -c Print "${pkgsPlistFile}" 2> /dev/null | grep ' = Dict'  | awk '{print $1}' )"
		returnCode="0"  # read -d '' always returns 1
		
		# if failed to read content into lines_a
		if [[ "${#lines_a[@]}" -le "1" ]]; then
			returnCode="1"
		fi
		
		go_NoGo_FDN "${returnCode}" "Imported ${#lines_a[@]} package names from ${pkgsPlistFile##*/}${kNEWLINE}." "Unable to import package names from ${pkgsPlistFile##*/}${kNEWLINE}."
		
		write_2Log_FDN "${_LOGTXT}"
		
		# loop through the package names
		for pkgName in "${lines_a[@]}"; do
			# read specific pkgName keys into array: items_a[0]=DownloadName, items_a[1]=DownloadSize, items_a[2]=InstalledSize, and items_a[3]=IsMandatory
			IFS=$'\n' read -d '' -r -a items_a <<< "$( "${kPLISTBUDDY}" -c "Print:${pkgName}" "${pkgsPlistFile}" 2> /dev/null | grep '=' | tr -d ' ' | grep -E 'DownloadName|DownloadSize|InstalledSize|IsMandatory' | sort )"
			
			# get key values
			case "${#items_a[@]}" in
			3|4) # valid keys
				# if essential
				if [[ "${items_a[3]#*=}" == "true" ]]; then
					essentialInstalled_a+=("${items_a[0]#*=}") # Download name
					
				# if optional
				else
					 optionalInstalled_a+=("${items_a[0]#*=}") # Download name
				fi
				;;
			*) # invalid keys
				# log and continue
				go_NoGo_FDN "-1" "" "Unable to import ${pkgName} keys"
				;;
			esac
		done
		
		# if something in the array
		if [[ "${#essentialInstalled_a[@]}" -ne "0" ]]; then
			printf '%s\n' "${essentialInstalled_a[@]}" > "${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}${i}.count.txt"
			
		# generate a zero file
		else
			printf '%s\n' "0" > "${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}${i}.count.txt"
		fi
		
		returnCode="$(($?*-1))"
		
		go_NoGo_FDN "${returnCode}" "Exported essentialInstalled_a to ${kREVERSEDNS}.${kESSENTIAL}${i}.count.txt." "Unable to export essentialInstalled_a to ${kREVERSEDNS}.${kESSENTIAL}${i}.count.txt."
		
		# if something in the array
		if [[ "${#optionalInstalled_a[@]}" -ne "0" ]]; then
			printf '%s\n' "${optionalInstalled_a[@]}" > "${kVARTMP}/${kREVERSEDNS}${i}.count.txt"
			
		# generate a zero file
		else
			printf '%s\n' "0" > "${kVARTMP}/${kREVERSEDNS}${i}.count.txt"
		fi
		
		returnCode="$(($?*-1))"
		
		go_NoGo_FDN "${returnCode}" "Exported optionalInstalled_a to ${kREVERSEDNS}${i}.count.txt." "Unable to export optionalInstalled_a to ${kREVERSEDNS}${i}.count.txt."
		
		write_2Log_FDN "${_LOGTXT}"
		
		# clear the arrays
		unset essentialInstalled_a
		unset optionalInstalled_a
	done
}
function get_PackageCount() {
	# get the package count at _SAVEPATH
	
	_PKGCOUNT="$( find -s "${_SAVEPATH}" -maxdepth 1 -iname '*pkg' 2> /dev/null | wc -l | xargs )"
}
function get_PackageDownloadArray() {
	# setup the global array _downloadPKGs_a with the name of the packages to be downloaded
	
	local returnCode=""
	
	declare -a essential_a
	declare -a optional_a
	
	# read final lists to array
	IFS=$'\n' read -d '' -r -a essential_a <<< "$( cat "${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}.txt" )"
	IFS=$'\n' read -d '' -r -a optional_a <<< "$( cat "${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}.txt" )"

	# determine download type
	case "${downloadBit}" in
	0|4|9) # essential
		_downloadPKGs_a+=("${essential_a[@]}")
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "Merged essential_a into _downloadPKGs_a." "Unable to merge essential_a into _downloadPKGs_a."
		;;
	1|5|A) # optional
		_downloadPKGs_a+=("${optional_a[@]}")
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "Merged optional_a into _downloadPKGs_a." "Unable to merge optional_a into _downloadPKGs_a."
		;;
	2|7|8|B) # all		
		_downloadPKGs_a+=("${essential_a[@]}" "${optional_a[@]}")
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "Merged essential_a and optional_a into _downloadPKGs_a." "Unable to merge essential_a and optional_a into _downloadPKGs_a."
		;;
	esac
	
	# dedup
	IFS=" " read -r -a _downloadPKGs_a <<< "$( tr ' ' '\n' <<< "${_downloadPKGs_a[@]}" | sort -u | tr '\n' ' ' )"
}

# K --------------------------------------------------------------------------------------------------------------------------------
function kick_Launchd() {
	# start the launchd job based on the passed signal
	# $1: launch signal; notification
	
	local jobName=""
	local returnCode=""
	
	jobName="${_LANAME%.*}"

	# write out the launch signal and status code for LaunchControl to use
	echo "$1" > "${kLAUNCHSIGNAL}"
	echo "${_STATUSCODE}" >> "${kLAUNCHSIGNAL}"

	launchd_JobActive_FDN "${jobName}"
	returnCode="$?"
	
	# if the LaunchAgent|LaunchDaemon is not running
	if [[ "${returnCode}" -eq "1" ]]; then
		# if the LaunchAgent|LaunchDaemon plist does not exist
		if [[ ! -e "${_LAUNCHPLIST}" ]]; then
			# put the LaunchAgent|LaunchDaemon plist in place
			generate_Launchd_FDN
		fi
		
		# load and start the LaunchAgent|LaunchDaemon
		launchd_Load_FDN "${_LAUNCHPLIST}"
	fi
	
	# if watch LaunchAgent|LaunchDaemon, kick off
	if [[ -n "${_WATCHFILE}" ]]; then
		touch "${_WATCHFILE}"
		returnCode="$(($?*-1))"
		
		go_NoGo_FDN "${returnCode}" "Touched ${_WATCHFILE}." "Unable to touch ${_WATCHFILE}."
	fi

	# if something in _LOGTXT
	if [[ -n "${_LOGTXT}" ]]; then
		_LOGTXT="${_LOGTXT}${kNEWLINE}"
	fi
	
	write_2Log_FDN "${_LOGTXT}"
}
function kick_Process() {
	# start LaunchControl in its own process
	# $1: launch signal; verify or install
	
	local returnCode=""
	
	# wait for any active PID's to complete
	wait
	
	# delete the progress file
	delete_File_FDN "${kPROGRESSFILE}"
	
	# if there are no packages to download, exit the function
	skip_Function_FDN "download" || return 0
	
	# write out the launch signal and status code for LaunchControl to use
	echo "$1" > "${kLAUNCHSIGNAL}"
	echo "${_STATUSCODE}" >> "${kLAUNCHSIGNAL}"
	
	# start LaunchControl in its own process
	"${kVARTMP}/${kLASCRIPTNAME}" &
	returnCode="$?"
	
	# capture PID for LaunchControl
	echo "$!,${FUNCNAME[0]}" >> "${kACTIVEPIDFILE}"
	
	go_NoGo_FDN "${returnCode}" "Handing off to ${kLASCRIPTNAME} to $1 loops, ${_STATUSCODE}." "Unable to hand off to ${kLASCRIPTNAME} to $1 loops."
	
	write_2Log_FDN "${_LOGTXT}"
}

# L --------------------------------------------------------------------------------------------------------------------------------
function LaunchControl() {
	# write script to /private/var/Loops
	# $1: destination path
	# returns: exit code
	
	# write the script out
cat <<"LCEOF" >"$1/${FUNCNAME[0]}"
#!/bin/bash --norc

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin: export PATH

# set -xv; exec 1>>"/private/var/tmp/LaunchControlTraceLog" 2>&1

#----------------------------------------------------------------------------------------------------------------------------------	

#	LaunchControl.sh
#	Copyright (c) 2020-2025 Apple Inc.
#	
#	
#	This script manages the installation of Loops packages.
#
#
# APPLE INC.
# SOFTWARE LICENSE AGREEMENT FOR LAUNCHCONTROL SOFTWARE

# PLEASE READ THIS SOFTWARE LICENSE AGREEMENT ("LICENSE") CAREFULLY BEFORE USING THE APPLE SOFTWARE
# (DEFINED BELOW). BY USING THE APPLE SOFTWARE, YOU ARE AGREEING TO BE BOUND BY THE TERMS OF THIS
# LICENSE. IF YOU DO NOT AGREE TO THE TERMS OF THIS LICENSE, DO NOT USE THE APPLE SOFTWARE.

# 1. General.
# The Apple software, sample or example code, utilities, tools, documentation,
# interfaces, content, data, and other materials accompanying this License, whether on disk, print
# or electronic documentation, in read only memory, or any other media or in any other form,
# (collectively, the "Apple Software") are licensed, not sold, to you by Apple Inc. ("Apple") for
# use only under the terms of this License.  Apple and/or Apple’s licensors retain ownership of the
# Apple Software itself and reserve all rights not expressly granted to you. The terms of this
# License will govern any software upgrades provided by Apple that replace and/or supplement the
# original Apple Software, unless such upgrade is accompanied by a separate license in which case
# the terms of that license will govern.

# 2. Permitted License Uses and Restrictions.
# A. Service Provider License. A company delivering Apple Professional Services on Apple’s
# behalf, or with Apple’s authorization, a "Service Provider". Subject to the terms and conditions 
# of this License, if you are in good standing under an Apple authorized agreement regarding
# the delivery of Apple Professional Services, and are providing the Apple Software to a customer
# end-user under contract from Apple, you are granted a limited, non-exclusive license to install
# and use the Apple Software on Apple-branded computers for internal use within the customer
# end-user’s company, institution or organization. You may make only as many internal use copies
# of the Apple Software as reasonably necessary to use the Apple Software as permitted under this
# License and distribute such copies only to your employees and contractors whose job duties require
# them to so use the Apple Software; provided that you reproduce on each copy of the Apple Software
# or portion thereof, all copyright or other proprietary notices contained on the original.

# B. End-User License. Subject to the terms and conditions of this License, you are granted a
# limited, non-exclusive license to install and use the Apple Software on Apple-branded computers
# for internal use within your company, institution or organization. You may make only as many
# internal use copies of the Apple Software as reasonably necessary to use the Apple Software as
# permitted under this License and distribute such copies only to your employees and contractors
# whose job duties require them to so use the Apple Software; provided that you reproduce on each
# copy of the Apple Software or portion thereof, all copyright or other proprietary notices
# contained on the original.

# C. Other Use Restrictions. The grants set forth in this License do not permit you to, and you
# agree not to, install, use or run the Apple Software on any non-Apple-branded computer, or to
# enable others to do so. Except as otherwise expressly permitted by the terms of this License or as
# otherwise licensed by Apple: (i) only one user may use the Apple Software at a time; and (ii) you
# may not make the Apple Software available over a network where it could be run or used by multiple
# computers at the same time. You may not rent, lease, lend, trade, transfer, sell, sublicense or
# otherwise redistribute the Apple Software or exploit any services provided by or through the Apple
# Software in any unauthorized way.

# D. No Reverse Engineering; Limitations. You may not, and you agree not to or to enable others to,
# copy (except as expressly permitted by this License), decompile, reverse engineer, disassemble,
# attempt to derive the source code of, decrypt, modify, create derivative works of the Apple
# Software or any services provided by or through the Apple Software or any part thereof (except as
# and only to the extent any foregoing restriction is prohibited by applicable law).

# E. Compliance with Laws. You agree to use the Apple Software in compliance with all applicable
# laws, including local laws of the country or region in which you reside or in which you download
# or use the Apple Software.

# 3. No Transfer.  Except as otherwise set forth herein, you may not transfer this Apple Software
# without Apple’s express prior written approval.  All components of the Apple Software are provided
# as part of a bundle and may not be separated from the bundle and distributed as standalone
# applications.

# 4. Termination. This License is effective until terminated. Your rights under this License will
# terminate automatically or cease to be effective without notice from Apple if you fail to comply
# with any term(s) of this License.  In addition, Apple reserves the right to terminate this License
# if a new version of Apple's operating system software or the Apple Software is released which is
# incompatible with this version of the Apple Software.  Upon the termination of this License, you
# shall cease all use of the Apple Software and destroy all copies, full or partial, of the Apple
# Software.  Section 2C, 2D, and 4 through 10 of this License shall survive any termination.

# 5. Disclaimer of Warranties.
# A.  YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT, TO THE EXTENT PERMITTED BY APPLICABLE LAW, USE OF
# THE APPLE SOFTWARE AND ANY SERVICES PERFORMED BY OR ACCESSED THROUGH THE APPLE SOFTWARE IS AT YOUR
# SOLE RISK AND THAT THE ENTIRE RISK AS TO SATISFACTORY QUALITY, PERFORMANCE, ACCURACY AND
# EFFORT IS WITH YOU.

# B.  TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE APPLE SOFTWARE IS PROVIDED "AS IS" AND
# "AS AVAILABLE", WITH ALL FAULTS AND WITHOUT WARRANTY OF ANY KIND, AND APPLE AND APPLE'S LICENSORS
# (COLLECTIVELY REFERRED TO AS "APPLE" FOR THE PURPOSES OF SECTIONS 5 AND 6) HEREBY DISCLAIM ALL
# WARRANTIES AND CONDITIONS WITH RESPECT TO THE APPLE SOFTWARE, EITHER EXPRESS, IMPLIED OR
# STATUTORY, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES AND/OR CONDITIONS OF
# MERCHANTABILITY, SATISFACTORY QUALITY, FITNESS FOR A PARTICULAR PURPOSE, ACCURACY, QUIET
# ENJOYMENT, AND NON-INFRINGEMENT OF THIRD PARTY RIGHTS.

# C.  APPLE DOES NOT WARRANT AGAINST INTERFERENCE WITH YOUR ENJOYMENT OF THE APPLE SOFTWARE, THAT
# THE FUNCTIONS CONTAINED IN, OR SERVICES PERFORMED OR PROVIDED BY, THE APPLE SOFTWARE WILL MEET
# YOUR REQUIREMENTS, THAT THE OPERATION OF THE APPLE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE,
# THAT ANY SERVICES WILL CONTINUE TO BE MADE AVAILABLE, THAT THE APPLE SOFTWARE WILL BE COMPATIBLE
# OR WORK WITH ANY THIRD PARTY SOFTWARE, APPLICATIONS OR THIRD PARTY SERVICES, OR THAT DEFECTS IN
# THE APPLE SOFTWARE WILL BE CORRECTED. INSTALLATION OF THIS APPLE SOFTWARE MAY AFFECT THE
# AVAILABILITY AND USABILITY OF THIRD PARTY SOFTWARE, APPLICATIONS OR THIRD PARTY SERVICES, AS WELL
# AS APPLE PRODUCTS AND SERVICES.

# D.  YOU FURTHER ACKNOWLEDGE THAT THE APPLE SOFTWARE IS NOT INTENDED OR SUITABLE FOR USE IN
# SITUATIONS OR ENVIRONMENTS WHERE THE FAILURE OR TIME DELAYS OF, OR ERRORS OR INACCURACIES IN THE
# CONTENT, DATA OR INFORMATION PROVIDED BY, THE APPLE SOFTWARE COULD LEAD TO DEATH, PERSONAL INJURY,
# OR SEVERE PHYSICAL OR ENVIRONMENTAL DAMAGE, INCLUDING WITHOUT LIMITATION THE OPERATION OF NUCLEAR
# FACILITIES, AIRCRAFT NAVIGATION OR COMMUNICATION SYSTEMS, AIR TRAFFIC CONTROL, LIFE SUPPORT OR
# WEAPONS SYSTEMS.

# E.  NO ORAL OR WRITTEN INFORMATION OR ADVICE GIVEN BY APPLE OR AN APPLE AUTHORIZED REPRESENTATIVE
# SHALL CREATE A WARRANTY. SHOULD THE APPLE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE ENTIRE COST OF
# ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

# 6. Limitation of Liability. TO THE EXTENT NOT PROHIBITED BY APPLICABLE LAW, IN NO EVENT SHALL
# APPLE BE LIABLE FOR PERSONAL INJURY, OR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES
# WHATSOEVER, INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, CORRUPTION OR LOSS OF
# DATA, FAILURE TO TRANSMIT OR RECEIVE ANY DATA OR INFORMATION, BUSINESS INTERRUPTION OR ANY OTHER
# COMMERCIAL DAMAGES OR LOSSES, ARISING OUT OF OR RELATED TO YOUR USE OR INABILITY TO USE THE APPLE
# SOFTWARE OR ANY THIRD PARTY SOFTWARE, APPLICATIONS, OR SERVICES IN CONJUNCTION WITH THE APPLE
# SOFTWARE, HOWEVER CAUSED, REGARDLESS OF THE THEORY OF LIABILITY (CONTRACT, TORT OR OTHERWISE) AND
# EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. SOME JURISDICTIONS DO NOT ALLOW
# THE EXCLUSION OR LIMITATION OF LIABILITY FOR PERSONAL INJURY, OR OF INCIDENTAL OR CONSEQUENTIAL
# DAMAGES, SO THIS LIMITATION MAY NOT APPLY TO YOU. In no event shall Apple's total liability to you
# for all damages (other than as may be required by applicable law in cases involving personal
# injury) exceed the amount of fifty dollars ($50.00). The foregoing limitations will apply even if
# the above stated remedy fails of its essential purpose.

# 7. Export Control. You may not use or otherwise export or re-export the Apple Software except as
# authorized by United States law and the laws of the jurisdiction(s) in which the Apple Software
# was obtained. In particular, but without limitation, the Apple Software may not be exported or re-
# exported (a) into any U.S. embargoed countries or (b) to anyone on the U.S. Treasury Department's
# list of Specially Designated Nationals or the U.S. Department of Commerce Denied Person's List or
# Entity List. By using the Apple Software, you represent and warrant that you are not located in
# any such country or on any such list. You also agree that you will not use the Apple Software for
# any purposes prohibited by United States law, including, without limitation, the development,
# design, manufacture or production of missiles, nuclear, chemical or biological weapons.

# 8. Government End Users. The Apple Software and related documentation are "Commercial Items", as
# that term is defined at 48 C.F.R. §2.101, consisting of "Commercial Computer Software" and
# "Commercial Computer Software Documentation", as such terms are used in 48 C.F.R. §12.212 or 48
# C.F.R. §227.7202, as applicable. Consistent with 48 C.F.R. §12.212 or 48 C.F.R. §227.7202-1
# through 227.7202-4, as applicable, the Commercial Computer Software and Commercial Computer
# Software Documentation are being licensed to U.S. Government end users (a) only as Commercial
# Items and (b) with only those rights as are granted to all other end users pursuant to the terms
# and conditions herein. Unpublished-rights reserved under the copyright laws of the United States.

# 9. Controlling Law and Severability. This License will be governed by and construed in accordance
# with the laws of the State of California, excluding its conflict of law principles. This License
# shall not be governed by the United Nations Convention on Contracts for the International Sale of
# Goods, the application of which is expressly excluded. If for any reason a court of competent
# jurisdiction finds any provision, or portion thereof, to be unenforceable, the remainder of this
# License shall continue in full force and effect.

# 10. Complete Agreement; Governing Language. This License constitutes the entire agreement between
# you and Apple relating to the use of the Apple Software licensed hereunder and supersedes all
# prior or contemporaneous understandings regarding such subject matter. No amendment to or
# modification of this License will be binding unless in writing and signed by Apple.

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software to
# use, copy, and distribute copies, including within commercial software, subject to the following
# conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial
# portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# LaunchControl Rev. 092519
#


#----------------------------------------------------------FUNCTIONS----------------------------------------------------------------

# D --------------------------------------------------------------------------------------------------------------------------------
function declare_Constants() {
	local versStamp=""
	
	# define version number
	versStamp="Version 2.0.0 (1A2), 06-05-2025"
	
	kPID="$$"
	kSCRIPTVERS="${versStamp:8:${#versStamp}-20}"
	kSCRIPTPATH="${BASH_SOURCE[0]}"
	kSCRIPTNAME="${BASH_SOURCE[0]##*/}"

	# define the log file
	kLOGFILE="$( xattr_Get_FDN "logFile${kLASCRIPTNAME%.*}" "${kPREFSFILE}" )"
	
	# if the log file was not previously set
	if [[ -z "${kLOGFILE}" ]]; then
		kLOGFILE="${kLOGPATH}/Loops_${kLASCRIPTNAME%.*}-$( date +"%Y-%m-%d_%H%M%S" ).log"
		
		# save the current log path
		xattr_Write_FDN "logFile${kLASCRIPTNAME%.*}" "${kLOGFILE}" "${kPREFSFILE}"
	fi
	
	declare -r kPID
	declare -r kSCRIPTVERS
	declare -r kSCRIPTNAME
	declare -r kSCRIPTPATH
	declare -r kLOGFILE
}
function declare_Globals() {
	_STATUSCODE="000000"
	_ERRTRACKMSG=""
}

# G --------------------------------------------------------------------------------------------------------------------------------
function get_SavePath() {
	# $1: save packages location, null=/var/tmp/Loops, !=null=path to location
	
	local returnCode=""
	
	returnCode="0"
	savePath="${kVARTMP}/Packages"
	
	# if passed a save path
	if [[ "${pathBit}" -eq "1" ]]; then
		savePath="$( head -n 1 "${kVARTMP}/${kREVERSEDNS}.save.path.txt" )"
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "Successfully read ${kREVERSEDNS}.save.path.txt." "Unable to read ${kREVERSEDNS}.save.path.txt."
	fi
	
	go_NoGo_FDN "${returnCode}" "Package save path is ${savePath}." "Unable to determine package save path."
}

# I --------------------------------------------------------------------------------------------------------------------------------
function installer_Engine() {
	# $1: save packages location, null=/var/tmp/Loops, !=null=path to location
	# $2: null=only download packages or 1=install
	# $3: download state, 0=essential, >1=optional
	
	local savePath=""
	local i=""
	local pkgName=""
	local pkgCount=""
	local counter=""
	local percentComplete=""
	local capturedOutput=""
	local returnCode=""
	
	declare -a installPKGs_a
	declare -a resourcePaths_a
	
	resourcePaths_a=(
		'/Library/Audio/Apple Loops'
		'/Library/Audio/Impulse Responses/Apple'
		'/Library/Application Support/GarageBand'
		'/Library/Application Support/Logic'
	)
	
	savePath="$1"
	percentComplete="0"
	counter="${percentComplete}"
	
	# install packages if running as root
	if [[ "$2" -eq "1" && "${EUID}" -eq "0" && ! -e "${kERRLOG}" ]]; then
		# get a list of the package paths
		IFS=$'\n' read -d '' -r -a installPKGs_a <<< "$( find -s "${savePath}" -maxdepth 1 -iname '*pkg' 2> /dev/null )"
		
		# get the total number of packages to downloaded
		pkgCount="${#installPKGs_a[@]}"
		
		# if there are packages to install
		if [[ "${pkgCount}" -gt "0" ]]; then		
			# if installing essentials and app resources are in place
			if [[ "$3" -eq "0" && (-e "${resourcePaths_a[0]}" || -e "${resourcePaths_a[1]}" || -e "${resourcePaths_a[2]}" || -e "${resourcePaths_a[3]}") ]]; then
				# delete previous app resource directories
				clear_AppResources_FDN
				
				write_2Log_FDN "${_LOGTXT}"
			fi
			
			go_NoGo_FDN "0" "${pkgCount} packages to install." ""
			
			write_2Log_FDN "${_LOGTXT}"
			
			# loop through the packages and install
			for i in "${installPKGs_a[@]}"; do
				pkgName="${i##*/}"
				pkgName="${pkgName%.*}"
				
				# install the package on the target in a separate process
				caffeinate -u -d -i installer -package "${i}" -target / > "${kVARTMP}/${kREVERSEDNS}.install.out.txt" 2>&1
				returnCode="$?"
				
				go_NoGo_FDN "${returnCode}" "Installed package ${pkgName}." "Unable to install package ${pkgName}."
				
				# remove newline from end of _LOGTXT
				_LOGTXT="${_LOGTXT//[$'\r\n']}"
				
				# capture current percent complete
				((counter++))
				percentComplete="$( echo "scale=3; ${counter} / ${pkgCount} * 100" | bc | xargs printf "%.*f\n" "0" )" # round to nearest integer
				
				# capture current percent complete
				echo "${percentComplete}" >> "${kPROGRESSFILE}"
				
				# if package saved locally
				if [[ "${savePath}" == "${kVARTMP}/Packages" ]]; then
					# delete the package
					delete_File_FDN "${i}" "" "1"
				fi
				
				write_2Log_FDN "${_LOGTXT}"
				
				capturedOutput="$( <"${kVARTMP}/${kREVERSEDNS}.install.out.txt" )"
				
				# if something went wrong
				if [[ "${capturedOutput}" != *"successful"* || -z "${capturedOutput}" ]]; then
					# write out error and error code for installs
					echo -n "ERR -2" >> "${kPROGRESSFILE}"
					
					# log and exit
					go_NoGo_FDN "1" "" "Failed to install ${pkgName} – ${capturedOutput}."
				fi
				
				# save the installer log
				mv "${kVARTMP}/${kREVERSEDNS}.install.out.txt" "${kVARTMP}/Installer Logs/$( date +%Y-%m-%d\ %H%M%S )_${i##*/}.txt" 2>/dev/null
			done
			
			# save the installed package count
			packages_GetInstalled_FDN
			packages_InstalledPackageCount_FDN
			
		# if pkgCount=0
		else
			go_NoGo_FDN "0" "No packages to install" ""
		fi
		
		write_2Log_FDN "${_LOGTXT}"
	fi
	
	# reached the end of the array
	echo -n "FINISH" >> "${kPROGRESSFILE}"
}

# T --------------------------------------------------------------------------------------------------------------------------------
function trap_Exit() {
	# $1: exit code
	
	local msgTxt=""
	local returnCode=""
	
	# exited with failure
	if [[ "$1" -ge "1" ]]; then
		# notify calling script, we're done
		echo "FINISH" >> "${kPROGRESSFILE}"
		
		kill_ActivePIDs_FDN
		
		# need to stop and delete the LaunchAgent
		launchd_Unload_FDN "1" "${kLANAME%.*}" "${_LAUNCHPLIST}"
		
		# indicate failure
		msgTxt="${kNEWLINE}⛔️${_ERRTRACKMSG}"

		write_2Log_FDN "${msgTxt}${_LOGTXT}"
	fi
	
	go_NoGo_FDN "0" "Done" ""
	
	_LOGTXT="${_LOGTXT}${kNEWLINE}"
	
	write_2Log_FDN "${_LOGTXT}"
}

# V --------------------------------------------------------------------------------------------------------------------------------
function verify_Engine() {
	# $1: save packages location, null=/var/tmp/Loops, !=null=path to location
	# $2: verify packages
	
	local i=""
	local pkgCount=""
	local counter=""
	local percentComplete=""
	local pkgName=""
	local savePath=""
	local returnCode=""
	
	declare -a pkgPath_a
	declare -a pkgVerify_a
	
	savePath="$1"
	percentComplete="0"
	counter="${percentComplete}"
	
	# if verify packages
	if [[ "$2" -eq "1" ]]; then
		# get a list of the package paths
		IFS=$'\n' read -d '' -r -a pkgVerify_a <<< "$( find -s "${savePath}" -maxdepth 1 -iname '*pkg' -exec basename {} \; )"
		
		# get the total number of packages to verify
		pkgCount="${#pkgVerify_a[@]}"
		
		go_NoGo_FDN "0" "${pkgCount} packages to verify." ""
		
		write_2Log_FDN "${_LOGTXT}"
		
		# verify packages
		for i in "${pkgVerify_a[@]}"; do
			pkgName="${i}"
			returnCode="0"
			
			# if legacy package
			if [[ "${pkgName}" == *'../'* ]]; then
				# get just the package name
				pkgName="${pkgName##*/}"
			fi
			
			# if the package failed to download correctly
			if ! pkgutil --check-signature "${savePath}/${pkgName}" &> /dev/null; then
				# get the verification fail package
				pkgPath_a+=("${pkgName}")
				
				go_NoGo_FDN "-1" "" "Unable to verify package ${pkgName}."
				
				# remove newline from _LOGTXT
				_LOGTXT="${_LOGTXT//[$'\t\r\n']}"
				
				write_2Log_FDN "${_LOGTXT}"
			fi
			
			# calculate percent complete
			((counter++))
			percentComplete="$( echo "scale=3; ${counter} / ${pkgCount} * 100" | bc | xargs printf "%.*f\n" "0" )" # round to nearest integer
			
			# capture current percent complete
			echo "${percentComplete}" >> "${kPROGRESSFILE}"
		done
		
		# get the total number of packages that failed
		pkgCount="${#pkgPath_a[@]}"
		
		# if verification failures
		if [[ "${pkgCount}" -ne "0" ]]; then
			# save the verification failure packages to file
			printf "%s\n" "${pkgPath_a[@]}" > "${kVARTMP}/${kREVERSEDNS}.packages.failed.verify.txt"
			
			msgTxt="${pkgCount} packages failed verification."
			
			# if just one package
			if [[ "${pkgCount}" -eq "1" ]]; then
				msgTxt="${pkgCount} package failed to verify"
			fi
			
			go_NoGo_FDN "-1" "" "${msgTxt}"
			
			write_2Log_FDN "${_LOGTXT}"
			
			echo "ERROR: ${kSCRIPTNAME} encountered an error, ${msgTxt}. Offending command: ${FUNCNAME[0]}: Exit status of last command: package verification failure (1)" >> "${kERRLOG}"
			
			errMsg="${kNEWLINE}ERROR: ${kSCRIPTNAME} encountered an error.${kNEWLINE}Offending command: ${FUNCNAME[0]}${kNEWLINE}Exit status of last command: package verification failure (1)${kNEWLINE}"
			
			# set the user output message
			_ERRTRACKMSG="${_ERRTRACKMSG}${kNEWLINE}${errMsg}"
			
			write_2Log_FDN "${kNEWLINE}${_ERRTRACKMSG}"
			
		else
			# display notification
			display_Notification_FDN "Loops" "All packages verified" ""
			
			go_NoGo_FDN "0" "All packages verified." ""
			
			# remove newline from _LOGTXT
			_LOGTXT="${_LOGTXT//[$'\t\r\n']}"
		fi
	fi
	
	echo -n "FINISH" >> "${kPROGRESSFILE}"
	
	write_2Log_FDN "${_LOGTXT}"
}

# __ -------------------------------------------------------------------------------------------------------------------------------
function __start__() {
	local downloadBit=""
	local pathBit=""
	local installBit=""
	local verifyBit=""
	local launchBit=""
	local forceBit=""
	local suppressBit=""
	local savePath=""
	local launchSignal=""
	
	# log header
	write_2Log_FDN "${kSCRIPTNAME%.*} v${kSCRIPTVERS}" \
	"$( date "+DATE: %Y-%m-%d%nTIME: %H:%M:%S" )" \
	"macOS: $( sw_vers -productVersion )" \
	"Foundation: ${kFOUNDATIONVERSION}" \
	"PID=${kPID}"
	
	# if the file exists
	if [[ -e "${kVARTMP}/${kREVERSEDNS}.launch.signal" ]]; then
		# what needs to be run
		launchSignal="$( head -n 1 "${kLAUNCHSIGNAL}" )"
		_STATUSCODE="$( head -n 2 "${kLAUNCHSIGNAL}" | tail -n 1 )"
		
		decode_StatusCode_FDN
		
		# announce what triggered LaunchControl
		go_NoGo_FDN "0" "launchSignal: ${launchSignal} => ${_STATUSCODE}" ""
		
		get_SavePath "${pathBit}"
		
		write_2Log_FDN "${_LOGTXT}"
		
		case "${launchSignal}" in
		verify) # verify packages
			verify_Engine "${savePath}" "${verifyBit}"
			;;
		install) # install packages
			installer_Engine "${savePath}" "${installBit}" "${downloadBit}"
			;;
		notification) # display notification
			notification_Engine "${launchBit}"
			;;
		esac
	fi
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
declare -a _keys_a

# import shared variables and functions
source "/private/var/tmp/Loops/Foundation"

# always run trap_Exit regardless of how the script terminates
trap 'trap_Exit "$?"' INT TERM EXIT
# trap errors
trap 'trap_Error_FDN "$?" "${LINENO}" "${BASH_COMMAND}"' ERR

declare_Constants
declare_Globals

__start__

exit 0
LCEOF

	# return
	return "$?"
}

# P --------------------------------------------------------------------------------------------------------------------------------
function parse_Plist() {
	# parses the download plist (kDOWNLOADEDLOOPSPLIST) for each package and retrieves 'is mandatory', 'package size', and 'installed size'
	
	local pkgName=""
	local pkgsPlistFile=""
	local pkgCount=""
	local packageName=""
	local downloadSize=""
	local installedSize=""
	local downloadBit=""
	local pathBit=""
	local installBit=""
	local verifyBit=""
	local launchBit=""
	local forceBit=""
	local suppressBit=""
	local i=""
	local index=""
	local start=""
	local end=""
	local returnCode=""
	
	declare -a lines_a
	declare -a items_a
	declare -a essential_a
	declare -a optional_a
	declare -a essentialSize_a
	declare -a optionalSize_a
	
	# if only verifying or installing packages, exit the function
	skip_Function_FDN || return 0
	
	pkgsPlistFile="${kVARTMP}/${kREVERSEDNS}.packages.plist"

	decode_StatusCode_FDN
	
	# check for app type
	case "${downloadBit}" in
	0|1|7) # garageband only
		# garageband-essential || garageband-optional || garageband-all
		index="0"
		start="0"
		end="1"
	;;
	4|5|8) # logic only
		# logic-essential || logic-optional || logic-all
		index="1"
		start="1"
		end="2"
	;;
	9|A|B) # mainstage only
		# mainstage-essential || mainstage-optional || mainstage-all
		index="2"
		start="2"
		end="3"
	;;
	2) # all apps or all packages
		index="0"
		start="0"
		end="3"
	;;
	esac

	# remove the files before updating
	delete_File_FDN "${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}.txt"
	delete_File_FDN "${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}.txt"
	
	# loop through the plists: garageband, index=0; logic, index=1; mainstage, index=2
	for (( i = start; i < end; ++i )); do
		# print the Packages dict to plist
		"${kPLISTBUDDY}" -x -c 'Print :Packages' "${kDOWNLOADEDLOOPSPLIST%.*}${index}.plist" > "${pkgsPlistFile}"
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "${pkgsPlistFile##*/} saved to ${kVARTMP}." "Unable to save ${pkgsPlistFile##*/} to ${kVARTMP}."
		
		# read the package names
		IFS=$'\n' read -d '' -r -a lines_a <<< "$( ${kPLISTBUDDY} -c Print "${pkgsPlistFile}" 2> /dev/null | grep ' = Dict'  | awk '{print $1}' )"
		returnCode="0"  # read -d '' always returns 1
		
		# if failed to read content into lines_a
		if [[ "${#lines_a[@]}" -le "1" ]]; then
			returnCode="1"
		fi
		
		go_NoGo_FDN "${returnCode}" "Imported ${#lines_a[@]} ${_appName_a[i]} package names from ${pkgsPlistFile##*/}.${kNEWLINE}" "Unable to import package names from ${pkgsPlistFile##*/}.${kNEWLINE}"
		go_NoGo_FDN "${returnCode}" "Generating download values from ${kREVERSEDNS}.${kESSENTIAL}${index}.txt." "Unable to generate download values from ${kREVERSEDNS}.${kESSENTIAL}${index}.txt."
		go_NoGo_FDN "${returnCode}" "Generating download values from ${kREVERSEDNS}.${kOPTIONAL}${index}.txt." "Unable to generate download values from ${kREVERSEDNS}.${kOPTIONAL}${index}.txt."
		
		write_2Log_FDN "${_LOGTXT}"
		
		# loop through the package names
		for pkgName in "${lines_a[@]}"; do
			# read specific pkgName keys into array: items_a[0]=DownloadName, items_a[1]=DownloadSize, items_a[2]=InstalledSize, and items_a[3]=IsMandatory
			IFS=$'\n' read -d '' -r -a items_a <<< "$( "${kPLISTBUDDY}" -c "Print:${pkgName}" "${pkgsPlistFile}" 2> /dev/null | grep '=' | tr -d ' ' | grep -E 'DownloadName|DownloadSize|InstalledSize|IsMandatory' | sort )"
			
			# get key values
			case "${#items_a[@]}" in
			3|4) # valid keys
				packageName="${items_a[0]#*=}"
				
				# extract the sizing values
				downloadSize="${items_a[1]#*=}"
				installedSize="${items_a[2]#*=}"
				 
				# sometimes these are stated as a real rather than integer, remove the decimal and the value to the right, .0000000
				downloadSize="${downloadSize%.*}"
				installedSize="${installedSize%.*}"
				
				# if essential
				# shellcheck disable=SC2199,SC2076
				if [[ "${items_a[3]#*=}" == "true" ]]; then
					essential_a+=("${packageName}") # DownloadName
					essentialSize_a+=("${packageName},${downloadSize},${installedSize}") # size information for the package
					_DOWNLOADSIZEESSENTIAL="$((_DOWNLOADSIZEESSENTIAL + downloadSize))"
					_INSTALLSIZEESSENTIAL="$((_INSTALLSIZEESSENTIAL + installedSize))"
					
				# if optional
				else
					optional_a+=("${packageName}") # DownloadName
					optionalSize_a+=("${packageName},${downloadSize},${installedSize}")
					_DOWNLOADSIZEOPTIONAL="$((_DOWNLOADSIZEOPTIONAL + downloadSize))"
					_INSTALLSIZEOPTIONAL="$((_INSTALLSIZEOPTIONAL + installedSize))"
				fi
				
				# if the installed size is greater than the tracking install pad size
				if [[ "${installedSize}" -gt "${_INSTALLPADSIZE}" ]]; then
					_INSTALLPADSIZE="${installedSize}"
				fi
				;;
			*) # invalid keys
				# log and continue
				go_NoGo_FDN "-1" "" "Unable to import ${pkgName} keys from plist"
				;;
			esac
		done
			
		# cache the arrays as text files
		# essential
		printf '%s\n' "${essential_a[@]}" > "${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}${index}.txt"
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "Exported ${#essential_a[@]} package names from essential_a to ${kREVERSEDNS}.${kESSENTIAL}${index}.txt." "Unable to export essential_a to ${kREVERSEDNS}.${kESSENTIAL}${index}.txt."
		
		# essential size information
		printf '%s\n' "${essentialSize_a[@]}" > "${kVARTMP}/${kREVERSEDNS}.size.${kESSENTIAL}${index}.txt"
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "Exported package size information for ${#essentialSize_a[@]} packages from essentialSize_a to ${kREVERSEDNS}.size.${kESSENTIAL}${index}.txt." "Unable to export essentialSize_a to ${kREVERSEDNS}.size.${kESSENTIAL}${index}.txt."
		
		# optional
		printf '%s\n' "${optional_a[@]}" > "${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}${index}.txt"
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "Exported ${#optional_a[@]} package names from optional_a to ${kREVERSEDNS}.${kOPTIONAL}${index}.txt." "Unable to export optional_a to ${kREVERSEDNS}.${kOPTIONAL}${index}.txt."
		
		# optional size information
		printf '%s\n' "${optionalSize_a[@]}" > "${kVARTMP}/${kREVERSEDNS}.size.${kOPTIONAL}${index}.txt"
		returnCode="$?"
		
		go_NoGo_FDN "${returnCode}" "Exported package size information for ${#optionalSize_a[@]} packages from optionalSize_a to ${kREVERSEDNS}.size.${kOPTIONAL}${index}.txt." "Unable to export optionalSize_a to ${kREVERSEDNS}.size.${kOPTIONAL}${index}.txt."
		
		cat "${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}${index}.txt" >> "${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}.txt"
		returnCode="${?}"
		
		go_NoGo_FDN "${returnCode}" "Exported essential_a to ${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}.txt" "Unable to export essential_a to ${kVARTMP}/${kREVERSEDNS}.${kESSENTIAL}.txt"
		
		cat "${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}${index}.txt" >> "${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}.txt"
		returnCode="${?}"
		
		go_NoGo_FDN "${returnCode}" "Exported optional_a to ${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}.txt" "Unable to export optional_a to ${kVARTMP}/${kREVERSEDNS}.${kOPTIONAL}.txt"
		
		write_2Log_FDN "${_LOGTXT}"
		
		# clear the arrays
		unset essential_a
		unset optional_a
		unset essentialSize_a
		unset optionalSize_a
		
		# increment
		((index++))
	done

	write_2Log_FDN "${_LOGTXT}"
}
function pre_Flight() {
	# preflights to ensure sure minimal structure is in place to run
	
	local installerLogsPath=""
	local downloadBit=""
	local pathBit=""
	local installBit=""
	local verifyBit=""
	local launchBit=""
	local forceBit=""
	local suppressBit=""
	local installState=""
	local verifyState=""
	local launchState=""
	local forceState=""
	local i=""
	local rootState=""
	local returnCode=""
	
	installerLogsPath="${kVARTMP}/Installer Logs"
	
	[ -e "${kVARTMP}/Foundation" ]
	returnCode="$?"
	
	# if Foundation does not exist
	if [[ "${returnCode}" -ne "0" ]]; then
		go_NoGo_FDN "${returnCode}" "" "Foundation unavailable."
	fi
	
	# check curl version
	version_Check_FDN "${kCURLVERSMIN}" "${kCURLVERS}"
	returnCode="$?"
	
	# if running same or newer version of curl
	if [[ "${returnCode}" -ne "1" ]]; then
		returnCode="0" # reset as the value could be 2
	else
		go_NoGo_FDN "${returnCode}" "" "${kSCRIPTNAME} requires curl ${kCURLVERSMIN} or later."
	fi
	
	decode_StatusCode_FDN
	
	# if not installing
	if [[ "${installBit}" -eq "0" ]]; then
		installState="not "
		rootState="1"
	fi
	
	# if not verifying
	if [[ "${verifyBit}" -eq "0" ]]; then
		verifyState="no "
	fi
	
	# if not launching
	if [[ "${launchBit}" -eq "0" ]]; then
		launchState="not "
	fi
	
	# if not forcing
	if [[ "${forceBit}" -eq "0" ]]; then
		forceState="no "
	fi
	
	# if not suppressing curl
	if [[ "${suppressBit}" -eq "0" ]]; then
		forceState="no "
	fi
	
	pre_Flight_FDN "${rootState}"
	
	go_NoGo_FDN "0" "Passed parameters: {${downloadBit}} (${_DOWNLOADOPTARG}), {${pathBit}} (${_SAVEPATH}), {${installBit}} (${installState}installing), {${verifyBit}} (${verifyState}verify), {${launchBit}} (${launchState}launching), {${forceBit}} (${forceState}force download), {${suppressBit}} (${suppressBit}suppress curl) => ${_STATUSCODE}" ""
	
	# check for app installed
	case "${downloadBit}" in
	0|1|7) # garageband
	# if GarageBand is installed
	[ -e "/Applications/${_appName_a[0]}.app" ]
	returnCode="$(($?*-1))"
	
	go_NoGo_FDN "${returnCode}" "${_appName_a[0]} is installed" "${_appName_a[0]} is not installed"
	;;
	esac
	
	# check for app installed
	case "${downloadBit}" in
	4|5|8) # logic
	# if Logic Pro is installed
	[ -e "/Applications/${_appName_a[1]}.app" ]
	returnCode="$(($?*-1))"
	
	go_NoGo_FDN "${returnCode}" "${_appName_a[1]} is installed" "${_appName_a[1]} is not installed"
	;;
	esac
	
	# check for app installed
	case "${downloadBit}" in
	9|A|B) # mainstage
	# if MainStage is installed
	[ -e "/Applications/${_appName_a[2]}.app" ]
	returnCode="$(($?*-1))"
	
	go_NoGo_FDN "${returnCode}" "${_appName_a[2]} is installed" "${_appName_a[2]} is not installed"
	;;
	esac
	
	# if the error log exists
	if [[ -e "${kERRLOG}" ]]; then
		# rename the error log
		exit_ErrorLogExists
	fi
	
	echo >&2
	echo "Preparing..." >&2
	
	returnCode="0"

	# make sure the Packages folder exists
	mkdir -m 777 "${_SAVEPATH}" &> /dev/null
	# if directory does not exist
	if [[ ! -d "${_SAVEPATH}" ]]; then
		returnCode="1"
	fi
	
	go_NoGo_FDN "${returnCode}" "${_SAVEPATH}, created or exists." "Unable to create ${_SAVEPATH}."
	
	# if the packages directory is not empty and are not needed for installing or verification
	if [[ -n "$( ls -A "${_SAVEPATH}" )" && "${_SAVEPATH}" == "${kVARTMP}/Packages" && "${installBit}" -ne "1" && "${downloadBit}" -ne "3" ]]; then
		# delete any existing packages
		rm -f "${_SAVEPATH}"/* &> /dev/null
		returnCode="$(($?*-1))"
		
		go_NoGo_FDN "${returnCode}" "Deleted all packages from ${_SAVEPATH}." "Unable to delete all packages from ${_SAVEPATH}."
	fi
	
	# make sure the Installer Logs folder exists
	mkdir -m 777 "${installerLogsPath}" &> /dev/null
	
	# if directory
	[ -d "${installerLogsPath}" ]
	returnCode="$?"
	
	go_NoGo_FDN "${returnCode}" "${installerLogsPath}, created or exists." "Unable to create ${installerLogsPath}."
	
	# setup downloads plist for the apps
	for i in "${!_appName_a[@]}"; do
		# if never run or last run did not complete
		if [[ "${_STATUSCODE}" != "${_STATUSCODELASTRUN}" ]]; then
			# delete the plist
			delete_File_FDN "${kDOWNLOADEDLOOPSPLIST%.*}${i}.plist"
		fi
		
		# if plist does not exist
		if [[ ! -e "${kDOWNLOADEDLOOPSPLIST%.*}${i}.plist" ]]; then
			"${kPLISTBUDDY}" -c 'Add :ConfigVersion string 0' "${kDOWNLOADEDLOOPSPLIST%.*}${i}.plist" &> /dev/null
			returnCode="$?"
			
			go_NoGo_FDN "${returnCode}" "Created ${kDOWNLOADEDLOOPSPLIST%.*}${i}.plist." "Unable to create ${kDOWNLOADEDLOOPSPLIST%.*}${i}.plist."
			
			set_Ownership_FDN "${kDOWNLOADEDLOOPSPLIST%.*}${i}.plist"
			set_Permissions_FDN "${kDOWNLOADEDLOOPSPLIST%.*}${i}.plist"
		fi
	done
	
	# if the prefs file exists
	if [[ -e "${kPREFSFILE}" ]]; then
		# clear the LaunchControl log file path
		xattr_Write_FDN "logFile${kLASCRIPTNAME%.*}" "" "${kPREFSFILE}"
	fi
	
	# if there is preflight _LOGTXT
	if [[ -n "${_PREFLIGHTLOGTXT}" ]]; then
		# add log stamp
		_PREFLIGHTLOGTXT="$( date -j +%F\ %H:%M:%S%z ) [${kUSER}] - ${kSCRIPTNAME}:${FUNCNAME[0]}: ${_PREFLIGHTLOGTXT}"
		
		# insert _PREFLIGHTLOGTXT after line 6 of _LOGTXT
		_LOGTXT="$( awk -v x="$_PREFLIGHTLOGTXT" 'NR==6{print x}1' <<< "${_LOGTXT}" )"
	fi
	
	# log header
	write_2Log_FDN "${kSCRIPTNAME%.*} v${kSCRIPTVERS}" \
	"$( date "+DATE: %Y-%m-%d%nTIME: %H:%M:%S" )" \
	"macOS: $( sw_vers -productVersion )" \
	"curl: ${kCURLVERS}" \
	"MDM: ${_MDMINFO#*,}" \
	"Foundation: ${kFOUNDATIONVERSION}" \
	"PID=${kPID}" \
	"${_LOGTXT}"
}
function prep_DownloadInstallSizing() {
	# creates or sets package download sizes in preferences (kPREFSFILE)
	# $1: optional, signals that pref values need to be set
	
	local i=""
	local index=""
	local convertedValue=""
	local returnCode=""
	
	declare -a emptyKeyPlaceholder_a
	declare -a keyPlaceholder_a
	declare -a keyValue_a
	declare -a numKeys_a
	
	emptyKeyPlaceholder_a=(
		'StatusCode'
		'ScriptVersion'
		'downloadBit'
	)
	keyPlaceholder_a=(
		'DownloadSizeEssential'
		'InstallSizeEssential'
		'DownloadSizeOptional'
		'InstallSizeOptional'
		'audioContentURL'
		"${_keys_a[0]}"
		"${_keys_a[1]}"
		"${_keys_a[2]}"
		"${_keys_a[3]}"
		"${_keys_a[4]}"
		"${_keys_a[5]}"
		"${_appName_a[0]//[[:blank:]]/}ConfigVersion"
		"${_appName_a[1]//[[:blank:]]/}ConfigVersion"
		"${_appName_a[2]//[[:blank:]]/}ConfigVersion"
	)
	keyValue_a=(
		"${_DOWNLOADSIZEESSENTIAL}"
		"${_INSTALLSIZEESSENTIAL}"
		"${_DOWNLOADSIZEOPTIONAL}"
		"${_INSTALLSIZEOPTIONAL}"
		'audiocontentdownload.apple.com'
		'0'
		'0'
		'0'
		'0'
		'0'
		'0'
		'0'
		'0'
		'0'
	)
	
	index="0"
	
	# if only verifying packages, exit the function
	skip_Function_FDN || return 0
	
	# get the number of keys in the prefs plist
	IFS=$'\n' read -d '' -r -a numKeys_a <<< "$( "${kPLISTBUDDY}" -c Print "${kPREFSFILE}" | perl -lne 'print $1 if /^    (\S*) =/' )"
	
	# if prefs file does not exist or only has partial keys, create placeholders
	if [[ ! -e "${kPREFSFILE}" || "${#numKeys_a[@]}" -ne "20" ]]; then
		# loop through and set empty key values
		for i in "${emptyKeyPlaceholder_a[@]}"; do
			"${kPLISTBUDDY}" -c "Add :${i} string " "${kPREFSFILE}" &> /dev/null
			returnCode="$(($?*-1))"
			
			go_NoGo_FDN "${returnCode}" "Added key ${i} to ${kPREFSFILE##*/}" "Unable to add key ${i} to ${kPREFSFILE##*/} or exists"
		done
		
		# loop through and set initial key values
		for i in "${keyPlaceholder_a[@]}"; do
			"${kPLISTBUDDY}" -c "Add :${i} string ${keyValue_a[index]}" "${kPREFSFILE}" &> /dev/null
			returnCode="$(($?*-1))"
			
			go_NoGo_FDN "${returnCode}" "Added key ${i} and value ${keyValue_a[index]} to ${kPREFSFILE##*/}" "Unable to add key ${i} to ${kPREFSFILE##*/} or exists"
			
			((index++))
		done
		
		# add log file xattr
		xattr_Write_FDN "logFile" "" "${kPREFSFILE}"
		xattr_Write_FDN "logFile${kLASCRIPTNAME%.*}" "" "${kPREFSFILE}"
		
	# if set size values
	elif [[ "$#" -eq "1" ]]; then
		# loop through the array
		for i in "${keyPlaceholder_a[@]}"; do
			# save the values into preferences
			"${kPLISTBUDDY}" -c "Set :${i} ${keyValue_a[index]}" "${kPREFSFILE}" &> /dev/null
			returnCode="$?"
			
			convertedValue="$( convert_FromBytes2HumanReadable_FDN "${keyValue_a[index]}" )"
			
			go_NoGo_FDN "${returnCode}" "Set _$( tr '[:lower:]' '[:upper:]' <<< "${i}" )=${keyValue_a[index]}B (${convertedValue})." "Unable to set _$( tr '[:lower:]' '[:upper:]' <<< "${i}" )."
			
			((index++))
			
			# if done
			if [[ "${index}" -eq "4" ]]; then
				# exit
				break
			fi
		done
		
	# if get size values
	elif [[ "${_STATUSCODE}" == "${_STATUSCODELASTRUN}" ]]; then
		# reset
		keyValue_a=()
		
		# loop through the array
		for i in "${keyPlaceholder_a[@]}"; do
			keyValue_a+=("$( "${kPLISTBUDDY}" -c "Print :${i}" "${kPREFSFILE}" &> /dev/null )")
			returnCode="$?"
			
			convertedValue="$( convert_FromBytes2HumanReadable_FDN "${keyValue_a[index]}" "GB" )"
			
			go_NoGo_FDN "${returnCode}" "Read _$( tr '[:lower:]' '[:upper:]' <<< "${i}" )=${keyValue_a[index]}B (${convertedValue})." "Unable to read _$( tr '[:lower:]' '[:upper:]' <<< "${i}" )."
			
			((index++))
			
			# if done
			if [[ "${index}" -eq "4" ]]; then
				# exit
				break
			fi
		done
	fi
	
	write_2Log_FDN "${_LOGTXT}"
}
function prep_Launchd() {
	# prepares for launchd jobs
	
	local jobName=""
	local scriptVers=""
	
	jobName="${_LANAME%.*}"
	scriptVers="$( "${kPLISTBUDDY}" -c 'Print :ScriptVersion' "${kPREFSFILE}" )"
	
	# if the main script version is not the same
	if [[ "${scriptVers}" != "${kSCRIPTVERS}" ]]; then
		scriptVers="3"
		
	# if script versions match	
	else
		scriptVers="1"
	fi
		
	# if the LaunchAgent|LaunchDaemon does not exist
	if [[ ! -e "${_LAUNCHPLIST}" ]]; then
		# stop and remove com.loops.watch.plist
		launchd_Unload_FDN "${scriptVers}" "${jobName}" "${_LAUNCHPLIST}"
	fi
	
	write_2Log_FDN "${_LOGTXT}"
}
function prep_ProcessLaunch() {
	# prepares for script jobs
	
	local scriptVers=""

	scriptVers="$( "${kPLISTBUDDY}" -c 'Print :ScriptVersion' "${kPREFSFILE}" 2> /dev/null )"
	
	# delete the active PID file
	delete_File_FDN "${kACTIVEPIDFILE}"
	
	# if the main script version is not the same
	if [[ "${scriptVers}" != "${kSCRIPTVERS}" ]]; then
		scriptVers="3"
		
	# if script versions match	
	else
		scriptVers="1"
	fi
	
	# put the script in place
	generate_ProcessScript "${kLASCRIPTNAME}" "${kVARTMP}"
	
	write_2Log_FDN "${_LOGTXT}"
}
function process_Packages() {
	# gets the list of installed packages by essential and optional for each app type
	
	local downloadSize=""
	local installedSize=""
	local downloadBit=""
	local pathBit=""
	local installBit=""
	local verifyBit=""
	local launchBit=""
	local forceBit=""
	local suppressBit=""
	local index=""
	local start=""
	local end=""
	local typeStart=""
	local typeEnd=""
	local i=""
	local j=""
	local returnCode=""
	
	declare -a type_a
	
	type_a=(
		"${kESSENTIAL}"
		"${kOPTIONAL}"
	)
	
	# move back up a line
	echo -e "\033[2A" >&2
	echo "Starting soon..." >&2
	
	decode_StatusCode_FDN
	
	# if only verifying, installing packages, or not forcing exit the function
	skip_Function_FDN || return 0
	
	typeStart="0"
	typeEnd="2"
	
	diffFile="${kVARTMP}/${kREVERSEDNS}.diff.txt"
	removedFile="${kVARTMP}/${kREVERSEDNS}.removed.txt"

	# create empty files
	touch "${kVARTMP}/${kREVERSEDNS}.${type_a[0]}.txt"
	touch "${kVARTMP}/${kREVERSEDNS}.${type_a[1]}.txt"
	
	# check for app type
	case "${downloadBit}" in
	0|1|7) # garageband only
		# garageband-essential || garageband-optional || garageband-all
		index="0"
		start="0"
		end="1"
	;;
	4|5|8) # logic only
		# logic-essential || logic-optional || logic-all
		index="1"
		start="1"
		end="2"
	;;
	9|A|B) # mainstage only
		# mainstage-essential || mainstage-optional || mainstage-all
		index="2"
		start="2"
		end="3"
	;;
	2) # all apps or all packages
		index="0"
		start="0"
		end="3"
	;;
	esac
	
	# essential only
	case "${downloadBit}" in
	0|4|9)
		typeStart="0"
		typeEnd="1"
	;;
	esac

	# loop through the files: garageband, index=0; logic, index=1; mainstage, index=2
	for (( i = start; i < end; ++i )); do
		# loop through the package types, 0=essential, 1=optional
		for (( j = typeStart; j < typeEnd; ++j )); do
			# append to the global file
			cat "${kVARTMP}/${kREVERSEDNS}.${type_a[j]}${index}.txt" >> "${kVARTMP}/${kREVERSEDNS}.${type_a[j]}.txt"
			returnCode="$(($?*-1))"
			
			pkgCount="$( wc -l < "${kVARTMP}/${kREVERSEDNS}.${type_a[j]}${index}.txt" )"
			pkgCount="$( trim_WhiteSpace_FDN "${pkgCount}" )"
			
			go_NoGo_FDN "${returnCode}" "Exported ${pkgCount} package names to ${kREVERSEDNS}.${type_a[j]}.txt." "Unable to export package names to ${kREVERSEDNS}.${type_a[j]}.txt."
			
			# append to the global size file
			cat "${kVARTMP}/${kREVERSEDNS}.size.${type_a[j]}${index}.txt" >> "${kVARTMP}/${kREVERSEDNS}.size.${type_a[j]}.txt"
			returnCode="$(($?*-1))"
			
			go_NoGo_FDN "${returnCode}" "Exported ${type_a[j]}${index} package size information to ${kREVERSEDNS}.size.${type_a[j]}.txt." "Unable to export ${type_a[j]}${index} package size information to ${kREVERSEDNS}.size.${type_a[j]}.txt."
			
			# dedupe the global file
			sort -o "${kVARTMP}/${kREVERSEDNS}.${type_a[j]}.txt" -u "${kVARTMP}/${kREVERSEDNS}.${type_a[j]}.txt"
			returnCode="$(($?*-1))"
			
			go_NoGo_FDN "${returnCode}" "Removed any duplicate entries from ${kREVERSEDNS}.${type_a[j]}.txt." "Unable to remove any duplicate entries from ${kREVERSEDNS}.${type_a[j]}.txt."
		done
		
		# increment
		((index++))
	done
	
	write_2Log_FDN "${_LOGTXT}"
}
function process_PackageReduction() {
	
	local downloadBit=""
	local pathBit=""
	local installBit=""
	local verifyBit=""
	local launchBit=""
	local forceBit=""
	local suppressBit=""
	local typeFile=""
	local tmpTypeFile=""
	local pkgCountBefore=""
	local pkgCount=""
	local diffFile=""
	local removedFile=""
	local info=""
	
	declare -a type_a
	declare -a removed_a
	
	type_a=(
		"${kESSENTIAL}"
		"${kOPTIONAL}"
	)
	
	decode_StatusCode_FDN
	
	skip_Function_FDN "${forceBit}" || return 0
	# 
	# # loop through the global essential files, optional files, or both files
	# for (( i = typeStart; i < typeEnd; ++i )); do
	# 	typeFile="${kVARTMP}/${kREVERSEDNS}.${type_a[i]}.txt"
	# 	tmpTypeFile="${kVARTMP}/${kREVERSEDNS}.${type_a[i]}.tmp.txt"
	# 	
	# 	# duplicate the file
	# 	cp "${typeFile}" "${tmpTypeFile}" &> /dev/null
	# 	returnCode="$?"
	# 	
	# 	go_NoGo_FDN "${returnCode}" "Duplicated ${typeFile}" "Unable to duplicate ${typeFile}"
	# 	
	# 	# remove prefixes to match contents of kINSTALLEDPACKAGELIST
	# 	sed -i '' 's/..\/lp10_ms3_content_2013\///g' "${tmpTypeFile}"
	# 	
	# 	# get the current package count
	# 	pkgCountBefore="$( wc -l < "${typeFile}" )"
	# 	pkgCountBefore="$( trim_WhiteSpace_FDN "${pkgCountBefore}" )"
	# 	
	# 	# remove the installed packages from the global essential or optional file
	# 	compare_Files_FDN "diff" "${tmpTypeFile}" "${kINSTALLEDPACKAGELIST}" "${diffFile}"
	# 	
	# 	# get the removed packages
	# 	compare_Files_FDN "diff" "${tmpTypeFile}" "${diffFile}" "${removedFile}"
	# 	
	# 	# rename the diff file
	# 	mv "${diffFile}" "${typeFile}"
	# 	returnCode="$(($?*-1))"
	# 	
	# 	# get the package count post-package removal
	# 	pkgCount="$( wc -l < "${typeFile}" )"
	# 	pkgCount="$( trim_WhiteSpace_FDN "${pkgCount}" )"
	# 	
	# 	go_NoGo_FDN "${returnCode}" "Removed $((pkgCountBefore-pkgCount)) package names from ${typeFile}" "Unable to remove packages from ${typeFile}"
	# 	
	# 	# copy the removed package names to array
	# 	IFS=$'\n' read -d '' -r -a removed_a <<< "$( cat "${removedFile}" 2> /dev/null )"
	# 	
	# 	# loop through the removed files
	# 	for j in "${removed_a[@]}"; do
	# 		# get package information
	# 		info="$( grep -m 1 "${j}" "${kVARTMP}/${kREVERSEDNS}.size.${type_a[i]}.txt" )"
	# 		downloadSize="$( cut -d',' -f2 <<< "${info}" )"
	# 		installedSize="${info##*,}"
	# 		
	# 		# if global essential, update sizing
	# 		if [[ "${type_a[i]}" == "${kESSENTIAL}" ]]; then
	# 			_DOWNLOADSIZEESSENTIAL="$((_DOWNLOADSIZEESSENTIAL - downloadSize))"
	# 			_INSTALLSIZEESSENTIAL="$((_INSTALLSIZEESSENTIAL - installedSize))"
	# 			
	# 		# if global optional, update sizing
	# 		else
	# 			_DOWNLOADSIZEOPTIONAL="$((_DOWNLOADSIZEOPTIONAL - downloadSize))"
	# 			_INSTALLSIZEOPTIONAL="$((_INSTALLSIZEOPTIONAL - installedSize))"
	# 		fi
	# 	done
	# 	
	# 	# delete temp file
	# 	delete_File_FDN "${tmpTypeFile}"
	# done
	# 
	# # delete removed file
	# delete_File_FDN "${removedFile}"
	# 
	# # delete diff file
	# delete_File_FDN "${diffFile}"
	# 	
	# write_2Log_FDN "${_LOGTXT}"
}
function progress_Bar() {
	# displays package verify or install progress
	# $1: current value
	# $2: ending value
	# $3: progress label
	
	local progressValue=""
	local re=""
 
	re='^[0-9]+$'
	
	# if not passed a number
	if ! [[ $1 =~ ${re} ]] ; then
		# exit
		return
	fi
	
	# process data
	progressValue="$(($1*100/$2))"
	
	# if no change
	if [[ "${progressValue}" -eq "${lastProgressValue}" ]]; then
		return
	fi

	lastProgressValue="${progressValue}"
	
	# Progress: [########################################] 100%
	printf "\r$3 ${kBOLD}${_PKGCOUNT}${kNC} packages: ${progressValue}%% Complete"
}

# T --------------------------------------------------------------------------------------------------------------------------------
function track_Progress() {
	# tracks current package verify/install progress
	# $1: progress label
	
	local currentValue=""
	local endValue=""
	local lastProgressValue=""
	local progressLabel=""
	local downloadBit=""
	local pathBit=""
	local installBit=""
	local verifyBit=""
	local launchBit=""
	local forceBit=""
	local suppressBit=""
	local i=""
	
	currentValue="0"
	endValue="100"
	lastProgressValue="-1" # need starting value less than zero
	progressLabel="$1"
	
	# if there are no packages to download, exit the function
	skip_Function_FDN "download" || return 0
	
	decode_StatusCode_FDN
	
	# if not verifying packages
	if [[ "${progressLabel}" == *"Verifying"* && "${verifyBit}" -eq "0" ]]; then
		# continue
		currentValue="FINISH"
	fi
	
	# if not installing packages as root
	if [[ ("${progressLabel}" == *"Installing"* && "${EUID}" -ne "0") || ("${progressLabel}" == *"Installing"* && ("${EUID}" -eq "0" && "${installBit}" -eq "0")) ]]; then
		# continue
		currentValue="FINISH"
		
	# only installing packages as root
	elif [[ "${progressLabel}" == *"Installing"* && "${EUID}" -eq "0" && "${_DOWNLOADOPTARG}" == "none" && "${verifyBit}" -eq "0" ]]; then
		# move back up a line
		echo -e "\033[2A" >&2
	fi
	
	# if setup initial progress
	if [[ ("${progressLabel}" == *"Downloading"* && "${downloadBit}" -ne "3") || ("${progressLabel}" == *"Installing"* && ("${downloadBit}" -gt "0" && "${downloadBit}" -ne "3") || ("${progressLabel}" == *"Verifying"* && "${verifyBit}" -eq "1")) ]]; then
		# if download, move up a line
		if [[ "${progressLabel}" == *"Downloading"* || ("${progressLabel}" == *"Verifying"* && "${downloadBit}" -eq "3") ]]; then
			# move back up a line
			echo -e "\033[2A" >&2
			
		elif [[ "${progressLabel}" == *"Verifying"* && "${downloadBit}" -ne "3" ]]; then
			echo >&2
		fi
		
		# display 0% progress
		progress_Bar "${currentValue}" "${endValue}" "${progressLabel}"
	fi

	# loop over the process
	until [[ "${currentValue}" == "FINISH" ]]; do
		# if error file exists and is not empty or user cancelled
		if [[ -s "${kERRLOG}" ]]; then
			# set the error message
			_ERRTRACKMSG="$( tail -n 1 "${kERRLOG}" )"
			_ERRTRACKMSG="$( date +%Y-%m-%d\ %H:%M:%S%z ) [${kUSER}] - ${kSCRIPTNAME}:${FUNCNAME[0]}: ${_ERRTRACKMSG}"
		
			# exit
			return 1
	
		# if the progress file exists and is not empty
		elif [[ -s "${kPROGRESSFILE}" ]]; then
			# get the current progress value
			currentValue="$( tail -n 1 "${kPROGRESSFILE}" | awk -F '\r' '{print $NF}' )"
		
			# if race condition occurred and more than one value was saved to the file
			if [[ "${currentValue}" == *$'\n'* || "${currentValue}" == *$'\r'* ]]; then
				# get the most recent value
				currentValue="$( tail -n 1 <<< "${currentValue}" )"
			fi
	
			# display progress
			progress_Bar "${currentValue}" "${endValue}" "${progressLabel}"
		fi
	done
	
	echo >&2

	# if not installing packages
	if [[ "${progressLabel}" == *"Installing"* && "${installBit}" -eq "0" && "${verifyBit}" -eq "0" ]]; then
		# move back up a line
		echo -e "\033[2A" >&2
	fi
}
function trap_Exit() {
	# traps script exit
	# $1: exit code
	
	local downloadBit=""
	local pathBit=""
	local installBit=""
	local verifyBit=""
	local launchBit=""
	local forceBit=""
	local suppressBit=""
	local restartNow=""
	local user501=""
	
	# get the 501 user
	user501="$( dscl . -list /Users UniqueID | grep '501' | awk '{print $1}' )"
	
	decode_StatusCode_FDN
	
	exit_Check "$1"
	exit_ErrorLogExists
	exit_RunningAsRoot
	exit_LoggingToUser
	exit_Restart
}
function trap_UserCancel() {
	# traps user cancelling the script
	
	_ERRTRACKMSG="User cancelled"
	
	# force trap_Exit to run
	exit 1
}

# V --------------------------------------------------------------------------------------------------------------------------------
function verify_EssentialPackages() {
	# verifies essential packages if auto-config is attempting to install optional packages
	
	local downloadBit=""
	local pathBit=""
	local installBit=""
	local verifyBit=""
	local launchBit=""
	local forceBit=""
	local returnCode=""
	
	decode_StatusCode_FDN
	
	# if only verifying, exit the function
	skip_Function_FDN || return 0
	
	# if attempting to install optional content
	if [[ ("${_DOWNLOADOPTARG}" == *"${kOPTIONAL}"* || "${_DOWNLOADOPTARG}" == *"all"*) && "${forceBit}" -ne "1" ]]; then
		returnCode="0"
		
		go_NoGo_FDN "${returnCode}" "Verifying ${kESSENTIAL} packages." ""
		
		# if all installed
		if [[ (-e "/Applications/GarageBand.app" && -e "/Applications/MainStage.app" && -e "/Applications/MainStage.app") && "${_DOWNLOADOPTARG}" == *"all"* ]]; then
			returnCode="-1"
			downloadBit="2" # force all packages
		fi
		
		# if garageband
		if [[ -e "/Applications/GarageBand.app" && "${returnCode}" -eq "0" && "${_DOWNLOADOPTARG}" == *"garageband"* ]]; then
			returnCode="-1"
			downloadBit="7" # force garageband essential
		fi
		
		# if logic
		if [[ -e "/Applications/Logic Pro X.app" && "${returnCode}" -eq "0" && "${_DOWNLOADOPTARG}" == *"logic"* ]]; then
			returnCode="-1"
			downloadBit="8" # force logic essential
		fi
		
		# if mainstage
		if [[ -e "/Applications/MainStage.app" && "${returnCode}" -eq "0" && "${_DOWNLOADOPTARG}" == *"mainstage"* ]]; then
			returnCode="-1"
			downloadBit="B" # force mainstage essential
		fi
		
		# update the values
		_STATUSCODE="${downloadBit}${pathBit}${installBit}${verifyBit}${launchBit}${forceBit}"
		_DOWNLOADOPTARG="${_DOWNLOADOPTARG/${kOPTIONAL}/force_${kESSENTIAL}}"
		
		go_NoGo_FDN "${returnCode}" "Essential packages to be installed" "Forcing ${kESSENTIAL} packages: _DOWNLOADOPTARG=${_DOWNLOADOPTARG} => ${_STATUSCODE}"
		
		write_2Log_FDN "${_LOGTXT}"
	fi
}
function verify_Setup() {
	# make sure Loops and essential scripts are in place
	# $1: script path, which must also contain the path to Loops
	# ${2-n}: additional script paths
	
	local scriptPath=""
	local scriptName=""
	local loops=""
	local i=""
	local returnCode=""

	loops="${1%/*}"
	
	# make sure the Loops folder exists
	mkdir -m 755 "${loops}" &> /dev/null
	
	# if the directory was not created
	if [[ ! -d "${loops}" ]]; then
		echo "⛔️ Unable to create ${loops}" >&2
		
		# exit
		exit 1
	fi
	
	# loop over the passed parameters
	for i in "$@"; do
		scriptPath="${i%/*}"
		scriptName="${i##*/}"
		
		# move the script into place
		"${scriptName}" "${scriptPath}"
		returnCode="$?"
		
		# if the script was not created
		if [[ "${returnCode}" -ne "0" ]]; then
			echo "⛔️ Unable to create ${i}" >&2
			
			# exit
			exit 1
		fi
		
		# set execute bit
		chmod +x "${i}" 2> /dev/null 
		returnCode="$?"
		
		# if the executable bit was not set
		if [[ "${returnCode}" -ne "0" ]]; then
			echo "⛔️ Unable to set executable bit for ${i}" >&2
			
			# exit
			exit 1
		fi
	done
}

# __ -------------------------------------------------------------------------------------------------------------------------------
function __start__() {
	# get arguments
	decode_Args "${_PARAMS}"
	decode_OptArgs "${_args_a[@]}"
	auto_Configure
	pre_Flight
	
	# prep for download
	prep_DownloadInstallSizing
	download_Plist
	verify_EssentialPackages
	parse_Plist
	packages_GetInstalled_FDN
	process_Packages
	prep_DownloadInstallSizing "set"
	check_Freespace
	
	# download packages
	prep_ProcessLaunch
	download_Engine
	get_PackageCount
	
	# track downloads
	kick_Process "verify"
	track_Progress "Verifying"
	kick_Process "install"
	track_Progress "Installing"
	display_Stats "s"
}


#-------------------------------------------------------------MAIN-------------------------------------------------------------------
declare -a _args_a
declare -a _downloadPKGs_a
declare -a _appName_a
declare -a _configVersion_a
declare -a _keys_a

# make sure Loops and essential scripts in place
verify_Setup "/private/var/tmp/Loops/Foundation"

# import shared variables and functions
source "/private/var/tmp/Loops/Foundation"

# trap user cancelling
trap trap_UserCancel INT
# trap exit
trap 'trap_Exit "$?"' TERM EXIT
# trap errors
trap 'trap_Error_FDN "$?" "${LINENO}" "${BASH_COMMAND}"' ERR

declare_Constants
declare_Globals "$@"

__start__

exit 0
