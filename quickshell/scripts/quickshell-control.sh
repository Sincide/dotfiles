#!/bin/bash

# QuickShell Control Script
# This script provides external control for QuickShell overlays using signal files

SIGNAL_DIR="/tmp/quickshell-signals"
mkdir -p "$SIGNAL_DIR"

# Function to send signal to QuickShell
send_signal() {
    local signal="$1"
    touch "$SIGNAL_DIR/$signal"
    echo "Signal sent: $signal"
}

# Function to toggle app launcher
toggle_app_launcher() {
    send_signal "toggle_app_launcher"
}

# Function to toggle weather widget
toggle_weather() {
    send_signal "toggle_weather"
}

# Function to toggle system tray
toggle_system_tray() {
    send_signal "toggle_system_tray"
}

# Function to show notification
show_notification() {
    local title="${1:-Test}"
    local message="${2:-This is a test notification}"
    echo "$title|$message" > "$SIGNAL_DIR/show_notification"
    echo "Notification signal sent: $title - $message"
}

# Main command dispatcher
case "$1" in
    "app_launcher"|"launcher"|"apps")
        toggle_app_launcher
        ;;
    "weather")
        toggle_weather
        ;;
    "system_tray"|"tray"|"system") 
        toggle_system_tray
        ;;
    "notification"|"notify")
        show_notification "$2" "$3"
        ;;
    *)
        echo "Usage: $0 {app_launcher|weather|system_tray|notification [title] [message]}"
        echo ""
        echo "Commands:"
        echo "  app_launcher  - Toggle app launcher overlay"
        echo "  weather       - Toggle weather widget"
        echo "  system_tray   - Toggle system tray controls"
        echo "  notification  - Show test notification"
        echo ""
        echo "Examples:"
        echo "  $0 app_launcher"
        echo "  $0 weather"
        echo "  $0 notification 'Hello' 'This is a test'"
        exit 1
        ;;
esac 