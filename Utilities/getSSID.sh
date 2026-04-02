#!/bin/bash

# 1. Dynamically find the name of the Wi-Fi hardware port (e.g., en0, en1, etc.)
#    It looks for 'Wi-Fi' in the list of ports, gets the next line, and prints the last field (the device name).
WIFI_PORT=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $NF}')

# Check if a Wi-Fi port was found
if [[ -z "$WIFI_PORT" ]]; then
    echo "Error: Wi-Fi hardware port not found."
    exit 1
fi
echo "$WIFI_PORT"
# 2. Use the dynamically found port name to get the connected network's SSID.
#    This command handles the output of networksetup -getairportnetwork
SSID=$(networksetup -getairportnetwork "$WIFI_PORT" | cut -d ':' -f 2 | xargs)

# 3. Output the result
if [[ -n "$SSID" ]]; then
    echo "$SSID"
else
    # This happens if Wi-Fi is on but not connected to a network
    echo "Not connected to a Wi-Fi network."
fi