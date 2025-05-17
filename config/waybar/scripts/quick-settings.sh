#!/bin/bash

# For fuzzel, check if it's already running
if pidof fuzzel; then
    killall fuzzel
    exit 0
fi

options="󰂯 Bluetooth
󰤨 WiFi
󰕾 Volume
󰖨 Brightness
 Night Light
󰍹 System Settings"

# Launch fuzzel in dmenu mode with position anchored to top of screen
choice=$(echo -e "$options" | fuzzel --dmenu \
    --prompt="Quick Settings: " \
    --width=20 \
    --anchor=top-right)

case "$choice" in
    *"Bluetooth"*)
        blueman-manager ;;
    *"WiFi"*)
        nm-connection-editor ;;
    *"Volume"*)
        pavucontrol ;;
    *"Brightness"*)
        # Simple brightness control using wlsunset
        if [ -f ~/.config/wlsunset/brightness ]; then
            current=$(cat ~/.config/wlsunset/brightness)
            if [ "$current" == "bright" ]; then
                echo "dim" > ~/.config/wlsunset/brightness
                brightness="50"
            else
                echo "bright" > ~/.config/wlsunset/brightness
                brightness="100"
            fi
        else
            mkdir -p ~/.config/wlsunset/
            echo "bright" > ~/.config/wlsunset/brightness
            brightness="100"
        fi
        light -S $brightness
        ;;
    *"Night Light"*)
        # Toggle night light using direct temperature control
        if pgrep -x "wlsunset" > /dev/null; then
            pkill -x "wlsunset"
            notify-send "Night Light" "Turned off" -i ~/.config/dunst/icons/brightness.png
        else
            # Force immediate night light with no time-based calculation
            # Use current time as both sunrise and sunset to force constant temperature
            current_time=$(date +"%H:%M")
            # Set sunset time to 1 minute ago and sunrise time to tomorrow
            wlsunset -T 6500 -t 3500 -S 23:59 -s $(date -d "1 minute ago" +"%H:%M") &
            notify-send "Night Light" "Turned on" -i ~/.config/dunst/icons/brightness.png
        fi
        ;;
    *"System Settings"*)
        # Create a list of important config directories
        config_options="hypr\nwaybar\nfuzzel\ndunst\nkitty\nfish"
        selected_dir=$(echo -e "$config_options" | fuzzel --dmenu --prompt="Edit Config: " --width=20 \
            --anchor=top)
        
        if [ -n "$selected_dir" ]; then
            # List files in the directory and let user select one
            config_path=~/.config/$selected_dir
            # Get list of files including all visible files (not using find)
            file_list=$(ls -1 "$config_path" 2>/dev/null | grep -v "^\\.")
            
            if [ -z "$file_list" ]; then
                notify-send "Config Editor" "No files found in $selected_dir"
            else
                selected_file=$(echo -e "$file_list" | fuzzel --dmenu --prompt="Edit File: " --width=30 \
                    --anchor=top)
                
                if [ -n "$selected_file" ]; then
                    # Open the selected file in the terminal with editor
                    kitty --class floating -e fish -c "cd $config_path && $EDITOR $selected_file"
                fi
            fi
        fi
        ;;
esac 