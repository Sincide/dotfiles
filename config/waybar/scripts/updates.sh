#!/bin/bash

# Make sure checkupdates is available
if ! command -v checkupdates >/dev/null 2>&1; then
    echo "{\"text\": \" ?\", \"class\": \"error\", \"tooltip\": \"checkupdates not found\"}"
    exit 1
fi

# Make sure yay is available
if ! command -v yay >/dev/null 2>&1; then
    echo "{\"text\": \" ?\", \"class\": \"error\", \"tooltip\": \"yay not found\"}"
    exit 1
fi

# Get official repo updates count
PACMAN_COUNT=$(checkupdates 2>/dev/null | wc -l)
if [ $? -ne 0 ]; then
    PACMAN_COUNT=0
fi

# Get AUR updates count
YAY_COUNT=$(yay -Qua 2>/dev/null | wc -l)
if [ $? -ne 0 ]; then
    YAY_COUNT=0
fi

# Total number of updates
TOTAL=$((PACMAN_COUNT + YAY_COUNT))

# Initialize variables
CLASS="up-to-date"
TOOLTIP="System is up to date"

if [ "$TOTAL" -gt 0 ]; then
    CLASS="has-updates"
    if [ "$YAY_COUNT" -gt 0 ]; then
        if [ "$PACMAN_COUNT" -gt 0 ]; then
            TOOLTIP="Updates available:\n$PACMAN_COUNT official\n$YAY_COUNT AUR"
            TEXT=" $PACMAN_COUNT  $YAY_COUNT"
        else
            TOOLTIP="Updates available:\n$YAY_COUNT AUR"
            TEXT="  $YAY_COUNT"
        fi
    else
        TOOLTIP="Updates available:\n$PACMAN_COUNT official"
        TEXT=" $PACMAN_COUNT"
    fi
else
    TEXT=" 0"
fi

# Output JSON for Waybar
echo "{\"text\": \"$TEXT\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}" 