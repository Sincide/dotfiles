#!/usr/bin/env fish

# Safe brightness control for all 3 displays
# Usage: brightness.fish [25|50|75|100]

if test (count $argv) -ne 1
    echo "Usage: brightness.fish [25|50|75|100]"
    exit 1
end

set brightness $argv[1]

# Validate brightness value
if not contains $brightness 25 50 75 100
    echo "Error: Brightness must be 25, 50, 75, or 100"
    exit 1
end

echo "Setting brightness to $brightness% on all displays..."

# Set brightness on each display with delays to prevent system overload
ddcutil setvcp 10 $brightness --display 1 2>/dev/null &
sleep 0.5
ddcutil setvcp 10 $brightness --display 2 2>/dev/null &
sleep 0.5
ddcutil setvcp 10 $brightness --display 3 2>/dev/null &

echo "Brightness set to $brightness% on all displays" 