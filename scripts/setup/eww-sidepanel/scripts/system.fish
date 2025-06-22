#!/usr/bin/env fish
# System monitoring script for EWW sidebar (Fish Shell)

switch $argv[1]
    case "cpu"
        # Get CPU usage percentage
        set cpu_usage (top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
        # Alternative method if top format is different
        if test -z "$cpu_usage"
            set cpu_usage (grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print int(usage)}')
        end
        echo (test -n "$cpu_usage"; and echo $cpu_usage; or echo "0")
    
    case "ram"
        # Get RAM usage percentage
        set ram_info (free | grep Mem)
        set total (echo $ram_info | awk '{print $2}')
        set used (echo $ram_info | awk '{print $3}')
        set ram_usage (echo "scale=0; $used * 100 / $total" | bc)
        echo (test -n "$ram_usage"; and echo $ram_usage; or echo "0")
    
    case "disk"
        # Get disk usage percentage for root partition
        set disk_usage (df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
        echo (test -n "$disk_usage"; and echo $disk_usage; or echo "0")
    
    case "temp"
        # Get CPU temperature
        set temp ""
        
        # Try different temperature sources
        if test -f /sys/class/thermal/thermal_zone0/temp
            set temp_raw (cat /sys/class/thermal/thermal_zone0/temp)
            set temp (math $temp_raw / 1000)
        else if command -v sensors >/dev/null 2>&1
            set temp (sensors | grep -E "Core 0|Tctl|Package id 0" | head -1 | awk '{print $3}' | sed 's/+//;s/°C.*//')
        else if test -f /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input
            set temp_file (find /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)
            if test -n "$temp_file"
                set temp_raw (cat $temp_file)
                set temp (math $temp_raw / 1000)
            end
        end
        
        echo (test -n "$temp"; and echo $temp; or echo "0")
    
    case "battery"
        # Get battery percentage
        set battery ""
        
        if test -d /sys/class/power_supply/BAT0
            set battery (cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
        else if test -d /sys/class/power_supply/BAT1
            set battery (cat /sys/class/power_supply/BAT1/capacity 2>/dev/null)
        else if command -v acpi >/dev/null 2>&1
            set battery (acpi -b | grep -P -o '[0-9]+(?=%)')
        end
        
        # If no battery found, return 100 (desktop)
        echo (test -n "$battery"; and echo $battery; or echo "100")
    
    case "*"
        echo "Usage: $argv[0] {cpu|ram|disk|temp|battery}"
        exit 1
end