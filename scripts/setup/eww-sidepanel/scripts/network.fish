#!/usr/bin/env fish
# Network information script for EWW sidebar (Fish Shell)

switch $argv[1]
    case "status"
        # Check network connectivity
        if ping -c 1 8.8.8.8 >/dev/null 2>&1
            echo "Connected"
        else
            echo "Disconnected"
        end
    
    case "name"
        # Get network name/SSID
        set network_name ""
        
        # Try nmcli first (NetworkManager)
        if command -v nmcli >/dev/null 2>&1
            # Get active WiFi connection
            set wifi_name (nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
            if test -n "$wifi_name"
                set network_name $wifi_name
            else
                # Check for active ethernet connection
                set eth_name (nmcli -t -f name,type connection show --active | grep ethernet | cut -d: -f1 | head -1)
                if test -n "$eth_name"
                    set network_name $eth_name
                end
            end
        end
        
        # Fallback: try iwgetid for WiFi
        if test -z "$network_name"; and command -v iwgetid >/dev/null 2>&1
            set wifi_ssid (iwgetid -r 2>/dev/null)
            if test -n "$wifi_ssid"
                set network_name $wifi_ssid
            end
        end
        
        # Fallback: check for ethernet interface
        if test -z "$network_name"
            # Check if ethernet is up
            for interface in /sys/class/net/e*
                if test -d $interface
                    set iface (basename $interface)
                    if test (cat "$interface/operstate" 2>/dev/null) = "up"
                        set network_name "Ethernet ($iface)"
                        break
                    end
                end
            end
        end
        
        echo (test -n "$network_name"; and echo $network_name; or echo "Unknown")
    
    case "type"
        # Determine connection type
        set connection_type "Unknown"
        
        if command -v nmcli >/dev/null 2>&1
            # Check active connection type
            set active_type (nmcli -t -f type connection show --active | head -1)
            switch $active_type
                case "802-11-wireless" "wifi"
                    set connection_type "WiFi"
                case "802-3-ethernet" "ethernet"
                    set connection_type "Ethernet"
                case "*"
                    set connection_type $active_type
            end
        else
            # Fallback method
            if command -v iwgetid >/dev/null 2>&1; and iwgetid >/dev/null 2>&1
                set connection_type "WiFi"
            else if test -d /sys/class/net
                for interface in /sys/class/net/e*
                    if test -d $interface; and test (cat "$interface/operstate" 2>/dev/null) = "up"
                        set connection_type "Ethernet"
                        break
                    end
                end
            end
        end
        
        echo $connection_type
    
    case "ip"
        # Get local IP address
        set local_ip ""
        
        # Try multiple methods to get IP
        if command -v ip >/dev/null 2>&1
            set local_ip (ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+')
        end
        
        if test -z "$local_ip"; and command -v hostname >/dev/null 2>&1
            set local_ip (hostname -I 2>/dev/null | awk '{print $1}')
        end
        
        if test -z "$local_ip"
            set local_ip (ifconfig 2>/dev/null | grep -E 'inet [0-9]' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | cut -d: -f2)
        end
        
        echo (test -n "$local_ip"; and echo $local_ip; or echo "Unknown")
    
    case "speed"
        # Get connection speed (for WiFi)
        set speed ""
        
        if command -v iwconfig >/dev/null 2>&1
            set speed (iwconfig 2>/dev/null | grep -i "bit rate" | awk '{print $2}' | cut -d: -f2)
        else if command -v nmcli >/dev/null 2>&1
            set speed (nmcli -f SPEED device show 2>/dev/null | grep SPEED | awk '{print $2}' | head -1)
            if test -n "$speed"; and not string match -q "--" $speed
                set speed "$speed Mb/s"
            end
        end
        
        echo (test -n "$speed"; and echo $speed; or echo "Unknown")
    
    case "signal"
        # Get WiFi signal strength
        set signal ""
        
        if command -v iwconfig >/dev/null 2>&1
            set signal (iwconfig 2>/dev/null | grep -i "signal level" | awk '{print $4}' | cut -d= -f2)
        else if command -v nmcli >/dev/null 2>&1
            set signal (nmcli -f IN-USE,SIGNAL dev wifi | grep '^\*' | awk '{print $2}')
            if test -n "$signal"; and not string match -q "--" $signal
                set signal "$signal%"
            end
        end
        
        echo (test -n "$signal"; and echo $signal; or echo "Unknown")
    
    case "usage"
        # Get network usage (basic implementation)
        set interface ""
        
        # Find active network interface
        if command -v ip >/dev/null 2>&1
            set interface (ip route | grep default | awk '{print $5}' | head -1)
        end
        
        if test -n "$interface"; and test -f "/sys/class/net/$interface/statistics/rx_bytes"
            set rx_bytes (cat "/sys/class/net/$interface/statistics/rx_bytes")
            set tx_bytes (cat "/sys/class/net/$interface/statistics/tx_bytes")
            
            # Convert to MB
            set rx_mb (math $rx_bytes / 1024 / 1024)
            set tx_mb (math $tx_bytes / 1024 / 1024)
            
            echo "↓$rx_mb MB ↑$tx_mb MB"
        else
            echo "Unknown"
        end
    
    case "*"
        echo "Usage: $argv[0] {status|name|type|ip|speed|signal|usage}"
        echo "Available options:"
        echo "  status - Connection status"
        echo "  name   - Network name (SSID or connection name)"
        echo "  type   - Connection type (WiFi/Ethernet)"
        echo "  ip     - Local IP address"
        echo "  speed  - Connection speed"
        echo "  signal - WiFi signal strength"
        echo "  usage  - Network usage statistics"
        exit 1
end