#!/bin/bash
# Firefox CSS Generator - Martin's dotfiles integration

set -euo pipefail

SCRIPT_NAME="firefox-css-generator"
LOG_FILE="/tmp/${SCRIPT_NAME}.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [${SCRIPT_NAME}] $1" | tee -a "$LOG_FILE"
}

find_firefox_profile() {
    local profiles_ini="$HOME/.mozilla/firefox/profiles.ini"
    
    if [[ ! -f "$profiles_ini" ]]; then
        echo "ERROR: Firefox not found" >&2
        return 1
    fi
    
    local profile_path=$(awk -F= '/^Path=.*\.default/ {print $2; exit}' "$profiles_ini")
    
    if [[ -z "$profile_path" ]]; then
        profile_path=$(ls -1 "$HOME/.mozilla/firefox"/*.default* 2>/dev/null | head -1 | xargs basename)
    fi
    
    echo "$HOME/.mozilla/firefox/$profile_path"
}

generate_firefox_css() {
    local colors_file="$1"
    local profile_dir="$2"
    
    if [[ ! -f "$colors_file" ]]; then
        log_message "ERROR: Colors file not found: $colors_file"
        return 1
    fi
    
    local primary=$(jq -r '.colors.dark.primary // .primary // "#6366f1"' "$colors_file")
    local surface=$(jq -r '.colors.dark.surface // .surface // "#1e1e2e"' "$colors_file")
    local on_surface=$(jq -r '.colors.dark.on_surface // .on_surface // "#cdd6f4"' "$colors_file")
    
    mkdir -p "$profile_dir/chrome"
    
    cat > "$profile_dir/chrome/userChrome.css" << CSS_END
/* 🤖 AI-Generated Firefox Theme */
@namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");

:root {
  --ai-primary: $primary;
  --ai-surface: $surface;
  --ai-on-surface: $on_surface;
}

#nav-bar {
  background: var(--ai-surface) !important;
  color: var(--ai-on-surface) !important;
}

.tabbrowser-tab[selected="true"] .tab-background {
  background: var(--ai-primary) !important;
}

#urlbar {
  background: var(--ai-surface) !important;
  color: var(--ai-on-surface) !important;
}
CSS_END
    
    echo "{\"timestamp\": \"$(date -Iseconds)\", \"colorsFile\": \"$colors_file\"}" > /tmp/firefox-extension-trigger.json
    
    log_message "Firefox CSS generated successfully"
}

main() {
    local colors_file="${1:-/tmp/ai-optimized-colors.json}"
    
    log_message "Generating Firefox CSS from: $colors_file"
    
    local profile_dir=$(find_firefox_profile)
    if [[ $? -eq 0 ]]; then
        generate_firefox_css "$colors_file" "$profile_dir"
        echo "$profile_dir/chrome"
    else
        log_message "ERROR: Could not find Firefox profile"
        exit 1
    fi
}

main "$@"
