#!/bin/bash

# Firefox AI Extension Uninstaller
# "Nuclear option" - removes everything safely
# Because Martin is smart and knows things can go wrong! 🚀💥

set -euo pipefail

SCRIPT_NAME="firefox-ai-uninstaller"
LOG_FILE="/tmp/${SCRIPT_NAME}.log"
BACKUP_DIR="/tmp/firefox-ai-backup-$(date +%Y%m%d-%H%M%S)"

# Text colors for dramatic effect
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [${SCRIPT_NAME}] $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${RESET}"
}

info() {
    echo -e "${BLUE}🔵 $1${RESET}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${RESET}"
}

error() {
    echo -e "${RED}❌ $1${RESET}"
}

nuclear() {
    echo -e "${RED}💥 $1${RESET}"
}

dramatic_header() {
    echo -e "${PURPLE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🚀 FIREFOX AI UNINSTALLER 🚀              ║"
    echo "║                                                              ║"
    echo "║     \"Sometimes you need to nuke it from orbit\"               ║"
    echo "║                    - Ellen Ripley                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

show_uninstall_menu() {
    echo -e "${CYAN}${BOLD}What do you want to uninstall?${RESET}"
    echo
    echo "1) 🗂️  Extension files only (keep settings)"
    echo "2) ⚙️  Firefox settings only (keep extension)"
    echo "3) 🔄 Background processes only"
    echo "4) 🧹 Temporary files and logs"
    echo "5) 💥 NUCLEAR OPTION - Remove EVERYTHING"
    echo "6) 🔍 Show what would be removed (dry run)"
    echo "7) 📊 Show current status"
    echo "8) 🚪 Exit (chicken out)"
    echo
    read -p "Choose your destruction level (1-8): " choice
    echo "$choice"
}

create_backup() {
    local what="$1"
    
    info "Creating backup before $what..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup Firefox profile chrome directory
    local firefox_profile=$(find "$HOME/.mozilla/firefox" -name "*.default*" -type d | head -1)
    if [[ -n "$firefox_profile" && -d "$firefox_profile/chrome" ]]; then
        cp -r "$firefox_profile/chrome" "$BACKUP_DIR/chrome-backup" 2>/dev/null || true
        log_message "Backed up Firefox chrome directory"
    fi
    
    # Backup extension files
    if [[ -d "firefox-ai-extension" ]]; then
        cp -r "firefox-ai-extension" "$BACKUP_DIR/extension-backup" 2>/dev/null || true
        log_message "Backed up extension files"
    fi
    
    # Backup Firefox-specific AI scripts (keep other AI scripts)
    if [[ -d "scripts/ai" ]]; then
        mkdir -p "$BACKUP_DIR/scripts-backup"
        for script in "firefox-css-generator.sh" "realtime-firefox-integration.sh"; do
            if [[ -f "scripts/ai/$script" ]]; then
                cp "scripts/ai/$script" "$BACKUP_DIR/scripts-backup/" 2>/dev/null || true
            fi
        done
        log_message "Backed up Firefox AI scripts"
    fi
    
    # Backup settings
    local settings_files=(
        "$HOME/.config/dynamic-theming"
        "/tmp/ai-optimized-colors.json"
        "/tmp/firefox-extension-trigger.json"
        "local-color-server.py"
        "README-FIREFOX-AI.md"
    )
    
    for file in "${settings_files[@]}"; do
        if [[ -e "$file" ]]; then
            cp -r "$file" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done
    
    success "Backup created in: $BACKUP_DIR"
}

remove_extension_files() {
    info "Removing Firefox AI extension files..."
    
    local files_to_remove=(
        "firefox-ai-extension/"
        "local-color-server.py"
        "README-FIREFOX-AI.md"
        "install-firefox-ai-extension.sh"
    )
    
    for file in "${files_to_remove[@]}"; do
        if [[ -e "$file" ]]; then
            rm -rf "$file"
            log_message "Removed: $file"
        fi
    done
    
    success "Extension files removed"
}

remove_firefox_settings() {
    info "Removing Firefox AI settings..."
    
    # Find Firefox profile
    local firefox_profile=$(find "$HOME/.mozilla/firefox" -name "*.default*" -type d | head -1)
    
    if [[ -n "$firefox_profile" ]]; then
        # Remove AI-generated CSS files
        local css_files=(
            "$firefox_profile/chrome/userChrome.css"
            "$firefox_profile/chrome/userContent.css"  
            "$firefox_profile/chrome/ai-variables.css"
        )
        
        for css_file in "${css_files[@]}"; do
            if [[ -f "$css_file" ]]; then
                # Check if it's AI-generated before removing
                if grep -q "AI-Generated\|AI Colors\|🤖" "$css_file" 2>/dev/null; then
                    rm "$css_file"
                    log_message "Removed AI CSS: $(basename "$css_file")"
                else
                    warning "Kept non-AI CSS: $(basename "$css_file")"
                fi
            fi
        done
        
        # Ask about reverting userChrome.css setting
        echo
        read -p "🤔 Disable userChrome.css in Firefox? (y/N): " disable_chrome
        if [[ "$disable_chrome" =~ ^[Yy]$ ]]; then
            # Reset the preference in prefs.js
            local prefs_file="$firefox_profile/prefs.js"
            if [[ -f "$prefs_file" ]]; then
                # Create backup
                cp "$prefs_file" "${prefs_file}.backup"
                # Remove the userChrome setting (safe way)
                grep -v 'toolkit.legacyUserProfileCustomizations.stylesheets' "$prefs_file" > "${prefs_file}.new" || true
                mv "${prefs_file}.new" "$prefs_file"
                success "Disabled userChrome.css setting"
            fi
        fi
        
        success "Firefox settings cleaned"
    else
        warning "No Firefox profile found"
    fi
}

stop_background_processes() {
    info "Stopping AI-related background processes..."
    
    local processes_to_kill=(
        "realtime-firefox-integration"
        "firefox-ai-monitor"
        "local-color-server"
        "ai-color-pipeline"
        "color-harmony-analyzer"
        "accessibility-optimizer"
    )
    
    for process in "${processes_to_kill[@]}"; do
        if pgrep -f "$process" > /dev/null; then
            pkill -f "$process" || true
            log_message "Killed process: $process"
        fi
    done
    
    # Stop Python color server specifically
    if lsof -ti:8080 > /dev/null 2>&1; then
        kill $(lsof -ti:8080) 2>/dev/null || true
        log_message "Stopped color server on port 8080"
    fi
    
    success "Background processes stopped"
}

remove_temp_files() {
    info "Removing temporary files and logs..."
    
    local temp_files=(
        "/tmp/ai-optimized-colors.json"
        "/tmp/firefox-extension-trigger.json"
        "/tmp/firefox-ai-colors.json"
        "/tmp/firefox-native-message.json"
        "/tmp/firefox-ai-monitor.sh"
        "/tmp/gnome-wallpaper-monitor.sh"
        "/tmp/ai-pipeline/"
        "/tmp/color-harmony-analysis.json"
        "/tmp/accessibility-optimization-report.json"
        "/tmp/optimized-colors.json"
        "/tmp/firefox-css-generator.log"
        "/tmp/realtime-firefox-integration.log"
        "/tmp/ai-color-pipeline.log"
        "/tmp/color-harmony-analyzer.log"
        "/tmp/accessibility-optimizer.log"
        "/tmp/wallpaper-theme-optimized.log"
        "/tmp/wallpaper-selector.log"
        "/tmp/wallpaper-restore.log"
        "/tmp/transition-engine.log"
        "/tmp/matugen-optimized.log"
        "/tmp/matugen_error.log"
        "/tmp/waybar-main.log"
        "/tmp/waybar-bottom.log"
        "$HOME/.cache/dynamic-theming/"
    )
    
    for file in "${temp_files[@]}"; do
        if [[ -e "$file" ]]; then
            rm -rf "$file"
            log_message "Removed temp file: $file"
        fi
    done
    
    success "Temporary files cleaned"
}

remove_ai_scripts() {
    info "Removing Firefox AI scripts..."
    
    read -p "🤔 Remove Firefox AI scripts only (keeps your main AI pipeline)? (y/N): " remove_scripts
    if [[ "$remove_scripts" =~ ^[Yy]$ ]]; then
        # Only remove Firefox-specific AI scripts, not the whole AI directory
        local firefox_scripts=(
            "scripts/ai/firefox-css-generator.sh"
            "scripts/ai/realtime-firefox-integration.sh"
        )
        
        for script in "${firefox_scripts[@]}"; do
            if [[ -f "$script" ]]; then
                rm "$script"
                log_message "Removed Firefox script: $script"
            fi
        done
        
        success "Firefox AI scripts removed (main AI pipeline preserved)"
    else
        info "Keeping all AI scripts (wise choice!)"
    fi
}

show_dry_run() {
    info "DRY RUN - Here's what would be removed:"
    echo
    
    echo -e "${YELLOW}📁 Extension files:${RESET}"
    [[ -d "firefox-ai-extension" ]] && echo "  - firefox-ai-extension/"
    [[ -f "local-color-server.py" ]] && echo "  - local-color-server.py"
    [[ -f "README-FIREFOX-AI.md" ]] && echo "  - README-FIREFOX-AI.md"
    
    echo -e "${YELLOW}⚙️  Firefox settings:${RESET}"
    local firefox_profile=$(find "$HOME/.mozilla/firefox" -name "*.default*" -type d | head -1)
    if [[ -n "$firefox_profile" ]]; then
        [[ -f "$firefox_profile/chrome/userChrome.css" ]] && echo "  - userChrome.css"
        [[ -f "$firefox_profile/chrome/userContent.css" ]] && echo "  - userContent.css"
        [[ -f "$firefox_profile/chrome/ai-variables.css" ]] && echo "  - ai-variables.css"
    fi
    
    echo -e "${YELLOW}🔄 Background processes:${RESET}"
    for process in "realtime-firefox-integration" "local-color-server" "ai-color-pipeline"; do
        if pgrep -f "$process" > /dev/null; then
            echo "  - $process (running)"
        fi
    done
    
    echo -e "${YELLOW}🗑️  Temporary files:${RESET}"
    for file in "/tmp/ai-optimized-colors.json" "/tmp/firefox-extension-trigger.json" "/tmp/ai-pipeline/"; do
        [[ -e "$file" ]] && echo "  - $file"
    done
    
    echo -e "${YELLOW}🤖 AI Scripts (Firefox-specific only):${RESET}"
    [[ -f "scripts/ai/firefox-css-generator.sh" ]] && echo "  - Firefox CSS generator"
    [[ -f "scripts/ai/realtime-firefox-integration.sh" ]] && echo "  - Real-time integration"
    echo "  - (Main AI pipeline will be preserved)"
    
    echo
    # Check if we're in Martin's dotfiles directory
    if [[ ! -f "scripts/wallpaper-selector.sh" ]]; then
        warning "Not in ~/dotfiles directory, but proceeding anyway..."
    fi
}

show_current_status() {
    info "Current Firefox AI system status:"
    echo
    
    # Extension files
    echo -e "${CYAN}📁 Extension Files:${RESET}"
    [[ -d "firefox-ai-extension" ]] && echo "  ✅ Extension directory exists" || echo "  ❌ Extension directory missing"
    [[ -f "local-color-server.py" ]] && echo "  ✅ Color server script exists" || echo "  ❌ Color server script missing"
    
    # Firefox settings
    echo -e "${CYAN}⚙️  Firefox Configuration:${RESET}"
    local firefox_profile=$(find "$HOME/.mozilla/firefox" -name "*.default*" -type d | head -1)
    if [[ -n "$firefox_profile" ]]; then
        [[ -f "$firefox_profile/chrome/userChrome.css" ]] && echo "  ✅ userChrome.css exists" || echo "  ❌ userChrome.css missing"
        
        # Check if userChrome is enabled
        if grep -q "toolkit.legacyUserProfileCustomizations.stylesheets.*true" "$firefox_profile/prefs.js" 2>/dev/null; then
            echo "  ✅ userChrome.css enabled in Firefox"
        else
            echo "  ❌ userChrome.css disabled in Firefox"
        fi
    else
        echo "  ❌ No Firefox profile found"
    fi
    
    # Background processes
    echo -e "${CYAN}🔄 Background Processes:${RESET}"
    if pgrep -f "realtime-firefox-integration" > /dev/null; then
        echo "  ✅ Firefox integration running"
    else
        echo "  ❌ Firefox integration not running"
    fi
    
    if lsof -ti:8080 > /dev/null 2>&1; then
        echo "  ✅ Color server running on port 8080"
    else
        echo "  ❌ Color server not running"
    fi
    
    # AI files  
    echo -e "${CYAN}🤖 AI System:${RESET}"
    [[ -f "/tmp/ai-optimized-colors.json" ]] && echo "  ✅ AI colors available" || echo "  ❌ No AI colors found"
    [[ -d "scripts/ai" ]] && echo "  ✅ AI scripts directory available" || echo "  ❌ AI scripts missing"
    [[ -f "scripts/ai/firefox-css-generator.sh" ]] && echo "  ✅ Firefox CSS generator available" || echo "  ❌ Firefox CSS generator missing"
    [[ -f "scripts/ai/realtime-firefox-integration.sh" ]] && echo "  ✅ Real-time integration available" || echo "  ❌ Real-time integration missing"
    [[ -f "scripts/wallpaper-selector.sh" ]] && echo "  ✅ Wallpaper selector available" || echo "  ❌ Wallpaper selector missing"
    
    echo
}

nuclear_option() {
    nuclear "☢️  NUCLEAR OPTION ACTIVATED ☢️"
    echo
    warning "This will remove EVERYTHING related to Firefox AI!"
    warning "Including your AI scripts, settings, and temporary files!"
    echo
    read -p "🚨 Are you ABSOLUTELY sure? Type 'NUKE' to confirm: " confirmation
    
    if [[ "$confirmation" == "NUKE" ]]; then
        echo
        nuclear "💥 LAUNCHING NUCLEAR STRIKE..."
        sleep 1
        
        create_backup "nuclear destruction"
        
        stop_background_processes
        remove_extension_files
        remove_firefox_settings
        remove_temp_files
        remove_ai_scripts
        
        # Extra cleanup
        info "Performing deep cleanup..."
        
        # Remove any wallpaper hooks (but preserve Martin's existing ones)
        rm -f "/tmp/wallpaper-changed.trigger" 2>/dev/null || true
        rm -f "/tmp/firefox-extension-trigger.json" 2>/dev/null || true
        
        # DON'T touch Martin's main config
        # rm -f "$HOME/.config/dynamic-theming/last-wallpaper" 2>/dev/null || true
        
        # Kill any rogue matugen processes (but be gentle)
        pkill -f "firefox.*matugen" 2>/dev/null || true
        
        # Clean browser cache (ask first)
        read -p "🤔 Also clear Firefox cache? (y/N): " clear_cache
        if [[ "$clear_cache" =~ ^[Yy]$ ]]; then
            if command -v firefox >/dev/null; then
                firefox --headless --new-instance --profile-manager 2>/dev/null &
                local ff_pid=$!
                sleep 2
                kill $ff_pid 2>/dev/null || true
            fi
        fi
        
        nuclear "💥💥💥 NUCLEAR STRIKE COMPLETE 💥💥💥"
        echo
        success "Everything has been obliterated!"
        success "Backup saved in: $BACKUP_DIR"
        echo
        info "To restore from backup:"
        info "  cp -r $BACKUP_DIR/* ."
        
    else
        info "Nuclear option cancelled. Smart choice!"
    fi
}

main() {
    dramatic_header
    
    log_message "Firefox AI Uninstaller started"
    
    while true; do
        echo
        choice=$(show_uninstall_menu)
        
        case $choice in
            1)
                create_backup "extension removal"
                remove_extension_files
                ;;
            2)
                create_backup "Firefox settings reset"
                remove_firefox_settings
                ;;
            3)
                stop_background_processes
                ;;
            4)
                remove_temp_files
                ;;
            5)
                nuclear_option
                break
                ;;
            6)
                show_dry_run
                ;;
            7)
                show_current_status
                ;;
            8)
                info "Exiting without making changes. Wise choice!"
                break
                ;;
            *)
                error "Invalid choice. Try again!"
                ;;
        esac
    done
    
    echo
    success "Uninstaller finished!"
    log_message "Firefox AI Uninstaller completed"
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}⚠️  Uninstaller interrupted. No changes made.${RESET}"; exit 1' INT

# Run main function
main "$@"