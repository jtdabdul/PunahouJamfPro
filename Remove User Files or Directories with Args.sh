#!/bin/bash

#Parameter value formatting instructions
#parameter should contain leading /
#	ex: value: /Desktop/filename.pdf -> script will run command rm /Users/$loggedInUser/Desktop/filename.pdf
#parameter value should be un-quoted
# Display NameDisplay name for the script
# Remove User Files or Directories with args
# CategoryCategory to add the script to
# Uninstallers
# InformationInformation to display to the administrator when the script is run
# NotesNotes to display about the script (e.g., who created it and when it was created)
# Created 2020/08/25 by JA
# pass in partial path:  Users/$loggedInUser/path
# 2024/07/25 - clarification - parameter should be an un-quoted string, paths which contain spaces should not escape each space with a preceding backslash added to comment documentation
#2025/11/20 JA add error catching for "Directory not empty" on rm -rf, attempt to use find to delete all files in the directory first and then remove directory
pathToScript=$0
pathToPackage=$1
targetLocation=$2
targetVolume=$3

#enumerate args
#for((i=1;i<=$#;i++)); do
#	echo "${!i}"
#done
echo "entering Remove User Files with Arguments"

if [ ! $# > 4 ]; then {
	echo "No arguments found.  Arguments expected"
	exit 1
} else {
	echo "At least one argument found."
}
fi

#get currently logged in user
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
echo "Logged in User found: $loggedInUser"
	

function removeCurrentlyLoggedInUserFiles () {
    local arg1=$1             # partial file path
    local loggedInUser=$2     # detected logged in user (renamed arg2 for clarity)
    local target=""           # Full path to file/directory
   
    # Test that agr1 and arg2 are not empty
    if [[ -z $arg1 || -z $loggedInUser ]]; then
        echo "Arguments missing"
        return 1 # Return a non-zero status indicating failure
    fi

    target="/Users/"$loggedInUser$arg1
    echo "Target path: $target"
    
    # Test to see if $target exists
    if [[ -e $target ]]; then
        
        # Test to see if $target is a file
        if [[ -f $target ]]; then
            echo "$target is a file"
            echo "Removing file: rm $target"
            rm "$target" || echo "Error: rm failed on file $target"

        # Test to see if $target is a directory
        elif [[ -d $target ]]; then
            removeDirectory "$target"
        else
            echo "$target exists but is neither a file nor a directory (e.g., a symbolic link or socket)."
        fi
    else
        echo "$target does not exist"
    fi
}
function removeDirectory() {
    local arg1=$1
    local rm_output="" # Variable to store the output of rm -rf
    local find_strategy="find"
    echo "In removeDirectory target $arg1"
    if [[ -d $arg1 ]]; then
        echo "$arg1 is a directory"
        echo "Attempt 1: rm -rf $arg1"

        # Execute rm -rf, capture output (stdout and stderr) into rm_output,
        # and prevent it from printing to the console immediately.
        # The || true ensures the script continues even if rm fails,
        # so we can inspect the output.
        rm_output=$(rm -rf "$arg1" 2>&1)
        if [ $? -ne 0 ]; then   #if rm -rf exit status is not 0 (success)
            
            # Check for the specific "Directory not empty" error in the captured output
            if echo "$rm_output" | grep -q "Directory not empty"; then
                echo "---"
                echo "rm -rf failed with 'Directory not empty' error."
                echo "Employing Secondary Strategy: $find_strategy"

                # Secondary Strategy: Use find -depth and then rmdir
                find "$arg1" -depth -name '*' -exec rm -rf {} +

                # Try to remove the now-empty parent directory
                if rmdir "$arg1"; then
                    echo "Secondary strategy successful: Directory removed."
                else
                    echo "---"
                    echo "Error: Secondary strategy failed. Directory or remaining contents may be protected (e.g., active mount, special permissions)."
                    echo "Original rm output was: $rm_output"
                    echo "---"
                fi
            else
                # Report a different rm -rf error
                echo "Error: rm -rf failed on $arg1 for an unknown reason."
                echo "Original rm output was: $rm_output"
            fi
        fi
    else
        echo "$arg1 is not a directory"
    fi
}
#while arg-1 exists, keep looping - might be unnecessary as Jamf passes in 11 args
for((i=4;i<=$#;i++)); do
	if [[ ! -z "${!i}" ]]; then  #if the argument's value is not empty: Jamf passes all arguments to $11
		echo "${!i}"
		removeCurrentlyLoggedInUserFiles "${!i}" "$loggedInUser"
	fi
done
exit 0