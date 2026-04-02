#!/bin/bash

if pgrep -q "scout-client" && pgrep -q "scout-desktop"; then
	echo "<result>Running</result>"
	exit 0
else
	echo "<result>Failed</result>"
	exit 1
fi