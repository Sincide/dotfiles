#!/bin/bash

CONFIG_DIR="$HOME/.config/waybar"
CONFIG_FILE="$CONFIG_DIR/config"
STYLE_FILE="$CONFIG_DIR/style.css"
CONFIG_DEFAULT="$CONFIG_DIR/config.default"
STYLE_DEFAULT="$CONFIG_DIR/style.default.css"
CONFIG_ALT="$CONFIG_DIR/config.alt"
STYLE_ALT="$CONFIG_DIR/style.alt.css"
LOG_FILE="/tmp/waybar-toggle.log"

# Function to log messages to file and notify
log_message() {
    local level=$1
    local message=$2
    echo "[$level] $(date): $message" >> "$LOG_FILE"
    notify-send "Waybar Toggle" "$message" -t 3000
}

log_error() {
    log_message "ERROR" "$1"
    echo "Error: $1" >&2
}

log_info() {
    log_message "INFO" "$1"
    echo "Info: $1"
}

# Check if config files exist
check_files() {
    for file in "$CONFIG_DEFAULT" "$STYLE_DEFAULT" "$CONFIG_ALT" "$STYLE_ALT"; do
        if [ ! -f "$file" ]; then
            log_error "Missing file: $file"
            return 1
        fi
    done
    return 0
}

# Kill existing waybar instance
kill_waybar() {
    if pgrep -x waybar > /dev/null; then
        log_info "Killing existing waybar instance"
        killall waybar
        sleep 0.5
    else
        log_info "No existing waybar instance found"
    fi
}

# Function to start waybar and log output
start_waybar() {
    log_info "Starting waybar..."
    waybar 2>&1 | tee -a "$LOG_FILE" &
    sleep 0.5
    if ! pgrep -x waybar > /dev/null; then
        log_error "Waybar failed to start. Check $LOG_FILE for details"
        # Try to restore default config
        cp "$CONFIG_DEFAULT" "$CONFIG_FILE"
        cp "$STYLE_DEFAULT" "$STYLE_FILE"
        log_info "Restored default configuration, attempting to start waybar again"
        waybar &
        sleep 0.5
        if ! pgrep -x waybar > /dev/null; then
            log_error "Waybar failed to start even with default config"
        else
            log_info "Waybar started with default config"
        fi
    else
        log_info "Waybar started successfully"
    fi
}

# Main script logic
echo "=== Waybar Toggle $(date) ===" >> "$LOG_FILE"

if ! check_files; then
    exit 1
fi

kill_waybar

# Check which config is currently active and switch to the other one
if cmp -s "$CONFIG_FILE" "$CONFIG_DEFAULT"; then
    # Currently using default, switch to alt
    log_info "Currently using default config, switching to alternate layout"
    cp "$CONFIG_ALT" "$CONFIG_FILE"
    cp "$STYLE_ALT" "$STYLE_FILE"
    notify-send "Waybar" "Switched to alternate layout" -t 2000
elif cmp -s "$CONFIG_FILE" "$CONFIG_ALT"; then
    # Currently using alt, switch to default
    log_info "Currently using alternate config, switching to default layout"
    cp "$CONFIG_DEFAULT" "$CONFIG_FILE"
    cp "$STYLE_DEFAULT" "$STYLE_FILE"
    notify-send "Waybar" "Switched to default layout" -t 2000
else
    # Unknown state, switch to default
    log_error "Current config doesn't match either default or alternate, resetting to default"
    cp "$CONFIG_DEFAULT" "$CONFIG_FILE"
    cp "$STYLE_DEFAULT" "$STYLE_FILE"
    notify-send "Waybar" "Reset to default layout (unknown previous state)" -t 3000
fi

start_waybar