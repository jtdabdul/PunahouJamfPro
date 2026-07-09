#!/bin/bash
set_defaults() {
# Path to the script working folder
SCRIPT_FOLDER="/Library/Punahou/Scripts"
readonly SCRIPT_FOLDER
SCRIPT_NAME="restartRequiredwithLaunchDaemon.sh"
readonly SCRIPT_NAME
LAUNCH_DAEMON_LABEL="com.punahou.restartRequired"	#no trailing ".plist"
readonly LAUNCH_DAEMON_LABEL
INSTALL_PATH="$SCRIPT_FOLDER/$SCRIPT_NAME"
}
#super 3600
workflow_installation() {
	# --- Self-Installation Logic ---
	# 1. Get the absolute path of the currently running script
	CURRENT_SOURCE=$(realpath "$0")

	# 2. Check if the current location matches the intended install path
	if [ "$CURRENT_SOURCE" != "$INSTALL_PATH" ]; then
	    echo "Current location: $CURRENT_SOURCE"
	    echo "Installing to:    $INSTALL_PATH"

	    # Create the directory if it doesn't exist
	    [[ ! -d "${SCRIPT_FOLDER}" ]] && mkdir -p "$SCRIPT_FOLDER"

	    # Copy the script to the destination
	    cp "$CURRENT_SOURCE" "$INSTALL_PATH"
	    chmod +x "$INSTALL_PATH"

	    echo "Installation complete. Running from new location..."
	    
	    # 3. Execute the installed version and exit the current process
	    exec "$INSTALL_PATH" "$@"
	fi
#	cp "$0" "${SCRIPT_FOLDER}/${SCRIPT_NAME}" >/dev/null 2>&1
}
###################### MAIN #############################
set_defaults
workflow_installation

# --- Your Actual Script Starts Here ---
echo "Hello! I am running successfully from $INSTALL_PATH"