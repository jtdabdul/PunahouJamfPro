#!/bin/sh
#
# SOPHOS CENTRAL INSTALLER (BACKGROUND)
# This script downloads the Sophos installer, unzips it, launches the main
# installer binary as recommended by Sophos, and then immediately exits to
# free the jamf binary.
#
# NOTE: The Sophos installer will continue running in the background.
# Any cleanup or verification must be done via a separate policy or Extension Attribute.

# --- VARIABLES & LOGGING SETUP ---
LOG_FILE="/var/log/SophosInstall.log"

# Function to log messages to file and echo to console
log_message() {
	local message="$1"
	echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

log_message "--- STARTING SOPHOS CENTRAL INSTALLATION SCRIPT ---"

# --- PRE-CHECK (Optional, retain your logic) ---
# Your existing user check is commented out, keeping it here for reference:
# if no 502 user exists on the system, exit 1
# username502=$(dscl . list /Users UniqueID | grep 502 | awk '{print $1}')
# if [ -z $username502 ]; then
# 	echo "no user at UID 502, Sophos Install aborted for now"
# 	exit 1
# fi

# --- SETUP AND DOWNLOAD ---

# Set the working folder and create it
INSTALL_DIR="/private/var/tmp/sophos"
if [ -d "$INSTALL_DIR" ]; then
    rm -rf $INSTALL_DIR
fi
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

log_message "Working directory set to: $INSTALL_DIR"
log_message "Starting download of SophosInstall.zip..."

# Curl the Sophos Installer using a direct URL
/usr/bin/curl -L -O https://api-cloudstation-us-east-2.prod.hydra.sophos.com/api/download/8114f1dee414dc41ffea4274618a6dd1/SophosInstall.zip
CURL_RESULT=$?

if [ $CURL_RESULT -ne 0 ]; then
    log_message "ERROR: Curl failed to download SophosInstall.zip (Exit Code: $CURL_RESULT). Aborting."
    exit 1
fi

fileSize=$(/usr/bin/du -h SophosInstall.zip | /usr/bin/awk '{print $1}')
log_message "Download complete. File Size: $fileSize"

# Unzip the file
/usr/bin/unzip -o SophosInstall.zip >> "$LOG_FILE" 2>&1

log_message "Unzip complete. Sophos Installer.app contents extracted."

# --- LAUNCH INSTALLER PROPERLY ---

# Use the direct path to the binary as specified in Sophos documentation.
# We redirect stdout/stderr to the log file and background the process (&)
# to detach it from the Jamf policy script execution.

SOPHOS_BINARY="$INSTALL_DIR/Sophos Installer.app/Contents/MacOS/Sophos Installer"
chmod a+x "$INSTALL_DIR/Sophos Installer.app/Contents/MacOS/tools/com.sophos.bootstrap.helper"
chmod a+x "$SOPHOS_BINARY"

if [ ! -f "$SOPHOS_BINARY" ]; then
    log_message "ERROR: Sophos installer binary not found at $SOPHOS_BINARY. Aborting."
    exit 1
fi

log_message "Launching Sophos installer binary: $SOPHOS_BINARY"

# Launch the installation and get its PID immediately
#"$SOPHOS_BINARY" --quiet --install >> "$LOG_FILE" 2>&1 &
sudo "$SOPHOS_BINARY" --quiet >> "$LOG_FILE" 2>&1 &
INSTALL_PID=$!

log_message "Installation process started in background with PID: $INSTALL_PID"

# --- EXIT TO FREE JAMF BINARY ---

# 1. Verify the process is running. This is a very brief check.
if /bin/ps -p $INSTALL_PID > /dev/null
then
	log_message "SUCCESS: Sophos Installer successfully launched in the background."
    log_message "The policy script is now exiting immediately to free the Jamf binary."
    
    # 2. Clean up the temp files immediately after launching
    sleep 2 #give the installer a chance to read the plist file before deleting it
	/bin/rm -rf "$INSTALL_DIR" 
    log_message "Cleanup of $INSTALL_DIR completed"
    #we will put the cleanup steps in a cleanup policy targeted at Sophos Validated Smart group
    
    # 3. Exit the Jamf script successfully
	exit 0
else
	log_message "ERROR: Installation process failed to start or immediately exited."
	exit 1
fi
