#!/bin/bash
# Identify the Wi-Fi port (usually en0, en1, etc.)
wifiPort=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $NF}')

# List all preferred networks and remove them
networksetup -listpreferredwirelessnetworks "$wifiPort" | sed '1d' | while read -r network; do
    # Remove leading spaces and trailing carriage returns
    cleanNetwork=$(echo "$network" | sed 's/^[ \t]*//')
    echo "Removing: $cleanNetwork"
    networksetup -removepreferredwirelessnetwork "$wifiPort" "$cleanNetwork"
done

echo "All known Wi-Fi networks have been removed."