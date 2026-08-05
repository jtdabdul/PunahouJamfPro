#!/bin/bash
# Display NameDisplay name for the script
# Install downloaded vendor dmg drag and drop
# CategoryCategory to add the script to
# Deploy
# InformationInformation to display to the administrator when the script is run
# NotesNotes to display about the script (e.g., who created it and when it was created)
# https://community.jamf.com/t5/jamf-pro/policy-to-install-from-dmg/m-p/238776
# short script to use with policy cached package to 'drag and drop' with bash, then clean up the cached file.  Needs dmg name and app name passed in as parameters.
echo $1 $2 $3 $4 $5
DISKIMAGE=/Library/Application\ Support/JAMF/Waiting\ Room/$4.dmg
echo "Mounting $DISKIMAGE"
VOLUME=$(diskutil image attach --mountOptions nobrowse "$DISKIMAGE" |
    awk 'END {$1=$2="";print $0}'; exit ${PIPESTATUS[0]}) &&
    export VOLUME=$(echo $VOLUME) &&
(rsync -a "$VOLUME/$5.app" /Applications/; SYNCED=$?
    hdiutil detach -quiet "$VOLUME"; exit $? || exit "$SYNCED") &&
    rm -f "$DISKIMAGE" &&
    rm -f "$DISKIMAGE.cache.xml"