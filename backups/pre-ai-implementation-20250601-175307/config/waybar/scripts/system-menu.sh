#!/bin/bash

# Gather system information
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
memory=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
disk_usage=$(df -h / | awk 'NR==2 {print $5}')

# Check if we have a GPU temp script, and use it if available
if [ -f ~/.config/waybar/scripts/gpu-temp.sh ]; then
    if command -v jq &> /dev/null; then
        gpu_temp=$(~/.config/waybar/scripts/gpu-temp.sh | jq -r '.text')
        gpu_line="GPU: $gpu_temp"
    else
        gpu_line=""
    fi
else
    gpu_line=""
fi

# For fuzzel, check if it's already running
if pidof fuzzel; then
    killall fuzzel
    exit 0
fi

options="󰒓 Screenshot
󰣆 Recording
󰨑 Applications
󰕿 Sound
 Backlight
 Notifications
󰍹 System Settings"

# Launch fuzzel in dmenu mode with position anchored to top of screen
selected=$(echo -e "$options" | fuzzel --dmenu \
    --prompt="System Menu: " \
    --width=20 \
    --anchor=top-right)

case "$selected" in
    *"Screenshot"*)
        grimblast copy area ;;
    *"Recording"*)
        wf-recorder -g "$(slurp)" ;;
    *"Applications"*)
        fuzzel ;;
    *"Sound"*)
        pavucontrol ;;
    *"Backlight"*)
        light -S 50 ;;
    *"Notifications"*)
        if pkill -SIGUSR1 dunst; then
            notify-send "Notifications" "Notifications paused"
        else
            notify-send "Notifications" "Notifications enabled"
        fi ;;
    *"System Settings"*)
        ~/.config/waybar/scripts/quick-settings.sh ;;
esac 