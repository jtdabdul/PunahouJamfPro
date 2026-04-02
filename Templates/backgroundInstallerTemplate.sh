#!/bin/bash

# --- VARIABLES ---
# The $4, $5, etc., parameters are positional parameters passed from Jamf Pro
# Set the package name (must match the name in the Jamf Pro Package record)
PKG_NAME="MySoftwareInstaller.pkg"

# Set the name of the main process/app that runs during the installation (or the app that gets installed)
# Use a partial or full process name to check if the installation is still running.
# For .pkg installations, this might be the 'installer' process or the process of the installed app if it launches automatically.
# Adjust as needed for your specific installer.
PROCESS_NAME="Installer" # Common for PKG installs, use the name of the main process if different

# Path to the cached package
CACHED_PKG="/Library/Application Support/JAMF/Waiting Room/$PKG_NAME"

# Path for the installation log file
LOG_FILE="/var/log/my_install_script.log"

# --- FUNCTIONS ---
# Function to check if the installation process is still running
check_process () {
	# Check for the process name and return 0 if found (running), 1 if not found (finished)
	# The [p] syntax in grep prevents the grep process itself from showing up
	if pgrep -f "$PROCESS_NAME" > /dev/null; then
		return 0 # Process is running
	else
		return 1 # Process is not running
	fi
}

# --- SCRIPT BODY ---

echo "Starting installation for $PKG_NAME..." | tee -a "$LOG_FILE"

# 1. Start the Installation
# Use the installer command to run the package that was cached by the policy.
# Redirect the process to the background (&) so the Jamf binary can exit.
/usr/sbin/installer -pkg "$CACHED_PKG" -target / > "$LOG_FILE" 2>&1 &
INSTALL_PID=$!

echo "Installation process started with PID: $INSTALL_PID" | tee -a "$LOG_FILE"

# 2. Verify that the installer process is running
# This is a critical step to free up the Jamf binary
if ps -p $INSTALL_PID > /dev/null
then
	echo "Installation successfully started in background. Exiting script to free Jamf binary." | tee -a "$LOG_FILE"
	# Exit with 0 (success). This signals Jamf Pro that the policy script completed.
	# The actual *installation* is still running in the background, *separate* from the Jamf policy execution.
	exit 0
else
	echo "ERROR: Installation process failed to start or immediately exited." | tee -a "$LOG_FILE"
	# Exit with 1 (failure) to flag an issue in Jamf Pro logs.
	exit 1
fi