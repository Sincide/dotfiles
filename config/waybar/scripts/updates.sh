#!/bin/bash

# Cache file for updates
CACHE_FILE="/tmp/waybar-updates-cache"
CACHE_TIMEOUT=3600  # 1 hour in seconds

# Icons
ICON_UPDATES=""
ICON_ERROR=""
ICON_CHECKING=""

# Colors
COLOR_UPDATES="#f5c211"
COLOR_ERROR="#cc241d"
COLOR_CHECKING="#458588"

# Function to output JSON format
output_json() {
    local text="$1"
    local tooltip="$2"
    local class="$3"
    local color="$4"
    echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\", \"class\": \"$class\", \"color\": \"$color\"}"
}

# Check if we should use cache
if [ -f "$CACHE_FILE" ]; then
    CACHE_TIME=$(stat -c %Y "$CACHE_FILE")
    CURRENT_TIME=$(date +%s)
    if [ $((CURRENT_TIME - CACHE_TIME)) -lt "$CACHE_TIMEOUT" ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Show checking status while updating
output_json "$ICON_CHECKING" "Checking for updates..." "checking" "$COLOR_CHECKING"

# Update package databases with timeout
if ! timeout 10s sudo pacman -Sy >/dev/null 2>&1; then
    output_json "$ICON_ERROR" "Failed to check for updates" "error" "$COLOR_ERROR" | tee "$CACHE_FILE"
    exit 1
fi

# Count updates with timeout
UPDATES=$(timeout 10s pacman -Qu | grep -v "\[ignored\]" | wc -l)
AUR_UPDATES=$(timeout 10s yay -Qua | wc -l)

# Check if commands succeeded
if [ $? -ne 0 ]; then
    output_json "$ICON_ERROR" "Failed to check for updates" "error" "$COLOR_ERROR" | tee "$CACHE_FILE"
    exit 1
fi

TOTAL_UPDATES=$((UPDATES + AUR_UPDATES))

if [ "$TOTAL_UPDATES" -eq 0 ]; then
    output_json "" "System is up to date" "updated" "" | tee "$CACHE_FILE"
else
    TOOLTIP="$UPDATES system update(s)\n$AUR_UPDATES AUR update(s)"
    output_json "$ICON_UPDATES $TOTAL_UPDATES" "$TOOLTIP" "updates" "$COLOR_UPDATES" | tee "$CACHE_FILE"
fi 