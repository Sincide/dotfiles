#!/bin/bash
# System load indicator
load=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | sed 's/^[ 	]*//')
echo "⚡ $load"