#!/bin/bash
# Real-time Firefox Integration - Martin's dotfiles

set -euo pipefail

SCRIPT_NAME="realtime-firefox-integration"
LOG_FILE="/tmp/${SCRIPT_NAME}.log"

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AI_PIPELINE="$DOTFILES_ROOT/scripts/ai/ai-color-pipeline.sh"
FIREFOX_CSS_GENERATOR="$DOTFILES_ROOT/scripts/ai/firefox-css-generator.sh"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [${SCRIPT_NAME}] $1" | tee -a "$LOG_FILE"
}

monitor_wallpaper_changes() {
    local last_wallpaper=""
    
    log_message "🔄 Starting wallpaper monitoring (Martin's dotfiles integration)"
    
    while true; do
        local new_wallpaper=""
        
        if [[ -f "/tmp/wallpaper-changed.trigger" ]]; then
            new_wallpaper=$(cat "/tmp/wallpaper-changed.trigger")
            rm -f "/tmp/wallpaper-changed.trigger"
        fi
        
        if [[ -z "$new_wallpaper" ]] && command -v gsettings >/dev/null 2>&1; then
            new_wallpaper=$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null | sed "s/'//g" | sed 's/file:\/\///' || echo "")
        fi
        
        if [[ -n "$new_wallpaper" && "$new_wallpaper" != "$last_wallpaper" && -f "$new_wallpaper" ]]; then
            log_message "🎨 Wallpaper changed: $(basename "$new_wallpaper")"
            
            if [[ -x "$AI_PIPELINE" ]]; then
                log_message "Running AI color pipeline..."
                "$AI_PIPELINE" "$new_wallpaper" /tmp/ai-optimized-colors.json
            else
                log_message "AI pipeline not found, using matugen directly"
                matugen image "$new_wallpaper" --mode dark --json hex --dry-run > /tmp/ai-optimized-colors.json
            fi
            
            if [[ -x "$FIREFOX_CSS_GENERATOR" ]]; then
                log_message "Updating Firefox CSS..."
                "$FIREFOX_CSS_GENERATOR" /tmp/ai-optimized-colors.json
            fi
            
            last_wallpaper="$new_wallpaper"
        fi
        
        sleep 3
    done
}

main() {
    log_message "🚀 Real-time Firefox integration started (Martin's dotfiles)"
    log_message "Dotfiles root: $DOTFILES_ROOT"
    
    monitor_wallpaper_changes
}

trap 'log_message "🛑 Stopping Firefox integration"; exit 0' INT

main "$@"
