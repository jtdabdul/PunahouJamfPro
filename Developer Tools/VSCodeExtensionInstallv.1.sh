#!/bin/bash

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
if [ -f "$VSCODE_CLI" ]; then
    echo "Installing extensions for $currentUser..."
    
    # Repeat this line for each extension ID you wish to install
    sudo -u "$currentUser" "$VSCODE_CLI" --install-extension filipesabella.live-p5
    sudo -u "$currentUser" "$VSCODE_CLI" --install-extension irti.p5js-project-generator
    
    echo "Extension installation completed."
else
    echo "Visual Studio Code is not installed in /Applications."
    exit 1
fi