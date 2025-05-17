#!/bin/bash

# For fuzzel, check if it's already running
if pidof fuzzel; then
    killall fuzzel
    exit 0
fi

options="󰍃 Lock
󰒲 Suspend
󰗽 Logout
󰑐 Reboot
󰐥 Shutdown"

# Launch fuzzel in dmenu mode with position anchored to top of screen
selected=$(echo -e "$options" | fuzzel --dmenu \
    --prompt="Power Menu: " \
    --width=20 \
    --anchor=top-right)

case "$selected" in
    *"Lock"*)
        swaylock -f ;;
    *"Suspend"*)
        systemctl suspend ;;
    *"Logout"*)
        hyprctl dispatch exit ;;
    *"Reboot"*)
        systemctl reboot ;;
    *"Shutdown"*)
        systemctl poweroff ;;
esac 