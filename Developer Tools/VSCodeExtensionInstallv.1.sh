#!/bin/bash

################
## Handle Args
pathToScript=$0
pathToPackage=$1
targetLocation=$2
targetVolume=$3

#enumerate args
#for((i=1;i<=$#;i++)); do
#   echo "${!i}"
#done

if [ ! $# > 4 ]; then {
    echo "No arguments found.  Arguments expected"
    exit 1
} else {
    echo "At least one argument found."
}
fi
################

# 1. Get the currently logged-in GUI user
currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')

# 2. Safety check: Exit if no user or root is logged in
if [ -z "$currentUser" ] || [ "$currentUser" = "loginwindow" ] || [ "$currentUser" = "root" ]; then
    echo "No GUI user logged in. Exiting."
    exit 0
fi

# 3. Path to the VS Code binary
VSCODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

# 4. Install the extensions as the logged-in user
function install-extension() {
    if [ -z $1 ]; then
        exit 1
    else
        echo "Install extension $1"
        sudo -u "$currentUser" "$VSCODE_CLI" --install-extension $1
    fi
}
if [ -f "$VSCODE_CLI" ]; then
    echo "Installing extensions for $currentUser..."
    
    # Repeat this line for each extension ID you wish to install
    #while arg-1 is non-empty, keep looping
    #i starts at 4 because the first three args are predefined by jamf
    #$1 = Mount point of the target drive. This is / if you're booted to the target or /Volumes/targetDrive if you're not booted to it.
    #$2 = the computer name
    #$3 = the current user's shortname
    for((i=4;i<=$#;i++)); do
        if [[ ! -z "${!i}" ]]; then
            echo "${!i}"
            install-extension "${!i}"
        fi
    done
    
    echo "Extension installation completed."
else
    echo "Visual Studio Code is not installed in /Applications."
    exit 1
fi