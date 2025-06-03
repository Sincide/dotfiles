#!/bin/bash

# AI Dashboard Waybar Integration Script
# Calls the Go dashboard in waybar mode and handles errors gracefully

# Path to the dashboard binary
DASHBOARD_PATH="$HOME/dotfiles/scripts/ai/dashboard"

# Check if dashboard exists and is executable
if [[ ! -x "$DASHBOARD_PATH" ]]; then
    echo '{"text": "⭕ AI: Missing", "tooltip": "AI Dashboard binary not found or not executable", "class": "ai-error"}'
    exit 0
fi

# Check if we can access the dotfiles directory
if [[ ! -d "$HOME/dotfiles/scripts" ]]; then
    echo '{"text": "⭕ AI: Path Error", "tooltip": "Dotfiles directory structure not found", "class": "ai-error"}'
    exit 0
fi

# Run the dashboard in waybar mode with timeout
cd "$HOME/dotfiles" || {
    echo '{"text": "⭕ AI: Dir Error", "tooltip": "Cannot change to dotfiles directory", "class": "ai-error"}'
    exit 0
}

# Execute with timeout to prevent hanging
timeout 3 "$DASHBOARD_PATH" --waybar 2>/dev/null || {
    echo '{"text": "⭕ AI: Timeout", "tooltip": "AI Dashboard timed out or failed", "class": "ai-error"}'
    exit 0
} 