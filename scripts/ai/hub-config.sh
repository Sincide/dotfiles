#!/bin/bash

# =============================================================================
# ⚙️ AI HUB CONFIGURATION MANAGER
# =============================================================================
# Centralized configuration management for AI Hub
# Handles settings, profiles, caching, and user preferences

set -euo pipefail

# Configuration paths
readonly CONFIG_DIR="$HOME/.config/ai-hub"
readonly CACHE_DIR="/tmp/ai-hub-cache"
readonly CONFIG_FILE="$CONFIG_DIR/settings.conf"
readonly PROFILES_DIR="$CONFIG_DIR/profiles"
readonly THEMES_DIR="$CONFIG_DIR/themes"

# Default configuration
readonly DEFAULT_CONFIG='# AI Hub Configuration
# ======================

# Performance settings
CACHE_TTL=300
MAX_ANALYSIS_TIME=30
ENABLE_PERFORMANCE_TIMING=true

# UI preferences  
DEFAULT_THEME=dark
SHOW_BREADCRUMBS=true
AUTO_REFRESH_STATUS=true
CONFIRMATION_PROMPTS=true

# AI settings
OLLAMA_TIMEOUT=10
PREFERRED_MODEL=qwen2.5-coder:1.5b-base
ENABLE_AI_CACHING=true
AI_ANALYSIS_LEVEL=comprehensive

# Plugin settings
ENABLE_PLUGINS=true
AUTO_LOAD_PLUGINS=true
PLUGIN_TIMEOUT=30

# Logging
LOG_LEVEL=INFO
KEEP_LOGS_DAYS=7
MAX_LOG_SIZE=10M'

# =============================================================================
# CORE FUNCTIONS
# =============================================================================

init_config() {
    # Create directories
    mkdir -p "$CONFIG_DIR" "$PROFILES_DIR" "$THEMES_DIR" "$CACHE_DIR"
    
    # Create default config if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "$DEFAULT_CONFIG" > "$CONFIG_FILE"
        echo "Created default configuration at $CONFIG_FILE"
    fi
    
    # Load configuration
    source "$CONFIG_FILE"
}

# Get configuration value with fallback
get_config() {
    local key="$1"
    local default="${2:-}"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        local value=$(grep "^$key=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || echo "$default")
        echo "${value:-$default}"
    else
        echo "$default"
    fi
}

# Set configuration value
set_config() {
    local key="$1"
    local value="$2"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        # Update existing value or add new one
        if grep -q "^$key=" "$CONFIG_FILE"; then
            sed -i "s|^$key=.*|$key=$value|" "$CONFIG_FILE"
        else
            echo "$key=$value" >> "$CONFIG_FILE"
        fi
    else
        init_config
        set_config "$key" "$value"
    fi
}

# =============================================================================
# PROFILE MANAGEMENT
# =============================================================================

create_profile() {
    local profile_name="$1"
    local profile_file="$PROFILES_DIR/$profile_name.conf"
    
    echo "Creating profile: $profile_name"
    
    # Copy current config as base
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$profile_file"
        echo "# Profile: $profile_name" | sed -i '1i\' "$profile_file"
        echo "Profile '$profile_name' created successfully"
    else
        echo "Error: No base configuration found"
        return 1
    fi
}

load_profile() {
    local profile_name="$1"
    local profile_file="$PROFILES_DIR/$profile_name.conf"
    
    if [[ -f "$profile_file" ]]; then
        # Backup current config
        cp "$CONFIG_FILE" "$CONFIG_DIR/settings.conf.backup"
        
        # Load profile
        cp "$profile_file" "$CONFIG_FILE"
        echo "Profile '$profile_name' loaded successfully"
        
        # Reload configuration
        source "$CONFIG_FILE"
    else
        echo "Error: Profile '$profile_name' not found"
        return 1
    fi
}

list_profiles() {
    echo "Available profiles:"
    if [[ -d "$PROFILES_DIR" ]] && [[ $(ls -A "$PROFILES_DIR" 2>/dev/null) ]]; then
        for profile in "$PROFILES_DIR"/*.conf; do
            local name=$(basename "$profile" .conf)
            local description=$(grep "^# Profile:" "$profile" 2>/dev/null | cut -d':' -f2- | xargs || echo "No description")
            echo "  • $name - $description"
        done
    else
        echo "  No profiles found"
    fi
}

# =============================================================================
# THEME MANAGEMENT
# =============================================================================

create_theme() {
    local theme_name="$1"
    local theme_file="$THEMES_DIR/$theme_name.theme"
    
    cat > "$theme_file" << EOF
# AI Hub Theme: $theme_name
# Colors in hex format

# Primary colors
PRIMARY_COLOR=#6366f1
SECONDARY_COLOR=#a6adc8
ACCENT_COLOR=#f38ba8

# Background colors
BG_PRIMARY=#1e1e2e
BG_SECONDARY=#313244
BG_SURFACE=#45475a

# Text colors
TEXT_PRIMARY=#cdd6f4
TEXT_SECONDARY=#a6adc8
TEXT_DIM=#6c7086

# Status colors
SUCCESS_COLOR=#a6e3a1
WARNING_COLOR=#f9e2af
ERROR_COLOR=#f38ba8
INFO_COLOR=#89b4fa
EOF
    
    echo "Theme '$theme_name' created at $theme_file"
}

load_theme() {
    local theme_name="$1"
    local theme_file="$THEMES_DIR/$theme_name.theme"
    
    if [[ -f "$theme_file" ]]; then
        source "$theme_file"
        set_config "CURRENT_THEME" "$theme_name"
        echo "Theme '$theme_name' loaded successfully"
    else
        echo "Error: Theme '$theme_name' not found"
        return 1
    fi
}

# =============================================================================
# CACHE MANAGEMENT
# =============================================================================

clean_cache() {
    local max_age="${1:-$(get_config CACHE_TTL 300)}"
    
    if [[ -d "$CACHE_DIR" ]]; then
        echo "Cleaning cache older than ${max_age}s..."
        find "$CACHE_DIR" -name "cache_*" -type f -mmin "+$((max_age / 60))" -delete 2>/dev/null || true
        
        # Clean old logs
        local keep_days=$(get_config KEEP_LOGS_DAYS 7)
        find "$CACHE_DIR" -name "*.log" -type f -mtime "+$keep_days" -delete 2>/dev/null || true
        
        echo "Cache cleanup completed"
    fi
}

clear_all_cache() {
    if [[ -d "$CACHE_DIR" ]]; then
        echo "Clearing all cache..."
        rm -rf "$CACHE_DIR"/cache_* "$CACHE_DIR"/*.log 2>/dev/null || true
        echo "All cache cleared"
    fi
}

show_cache_info() {
    if [[ -d "$CACHE_DIR" ]]; then
        local cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
        local cache_files=$(find "$CACHE_DIR" -name "cache_*" -type f | wc -l)
        local log_files=$(find "$CACHE_DIR" -name "*.log" -type f | wc -l)
        
        echo "Cache Information:"
        echo "  Directory: $CACHE_DIR"
        echo "  Size: $cache_size"
        echo "  Cache files: $cache_files"
        echo "  Log files: $log_files"
        
        if [[ $cache_files -gt 0 ]]; then
            echo "  Recent cache entries:"
            find "$CACHE_DIR" -name "cache_*" -type f -printf "    %f (modified %TY-%Tm-%Td %TH:%TM)\n" | head -5
        fi
    else
        echo "Cache directory not found"
    fi
}

# =============================================================================
# INTERACTIVE CONFIGURATION
# =============================================================================

configure_performance() {
    echo "Performance Configuration"
    echo "========================="
    
    local current_ttl=$(get_config CACHE_TTL 300)
    local current_timeout=$(get_config MAX_ANALYSIS_TIME 30)
    local current_timing=$(get_config ENABLE_PERFORMANCE_TIMING true)
    
    echo "Current settings:"
    echo "  Cache TTL: ${current_ttl}s"
    echo "  Analysis timeout: ${current_timeout}s"
    echo "  Performance timing: $current_timing"
    echo
    
    read -p "Cache TTL in seconds [$current_ttl]: " new_ttl
    read -p "Analysis timeout in seconds [$current_timeout]: " new_timeout
    read -p "Enable performance timing? (true/false) [$current_timing]: " new_timing
    
    # Apply changes
    [[ -n "$new_ttl" ]] && set_config "CACHE_TTL" "$new_ttl"
    [[ -n "$new_timeout" ]] && set_config "MAX_ANALYSIS_TIME" "$new_timeout"
    [[ -n "$new_timing" ]] && set_config "ENABLE_PERFORMANCE_TIMING" "$new_timing"
    
    echo "Performance settings updated!"
}

configure_ai() {
    echo "AI Configuration"
    echo "================"
    
    local current_timeout=$(get_config OLLAMA_TIMEOUT 10)
    local current_model=$(get_config PREFERRED_MODEL "qwen2.5-coder:1.5b-base")
    local current_caching=$(get_config ENABLE_AI_CACHING true)
    
    echo "Current settings:"
    echo "  Ollama timeout: ${current_timeout}s"
    echo "  Preferred model: $current_model"
    echo "  AI caching: $current_caching"
    echo
    
    # Show available models
    if command -v ollama &>/dev/null; then
        echo "Available Ollama models:"
        ollama list 2>/dev/null | tail -n +2 | awk '{print "  • " $1}' || echo "  (Ollama not running)"
        echo
    fi
    
    read -p "Ollama timeout in seconds [$current_timeout]: " new_timeout
    read -p "Preferred model [$current_model]: " new_model
    read -p "Enable AI caching? (true/false) [$current_caching]: " new_caching
    
    # Apply changes
    [[ -n "$new_timeout" ]] && set_config "OLLAMA_TIMEOUT" "$new_timeout"
    [[ -n "$new_model" ]] && set_config "PREFERRED_MODEL" "$new_model"
    [[ -n "$new_caching" ]] && set_config "ENABLE_AI_CACHING" "$new_caching"
    
    echo "AI settings updated!"
}

# =============================================================================
# MAIN CONFIGURATION MENU
# =============================================================================

show_config_menu() {
    while true; do
        echo
        echo "🔧 AI Hub Configuration Manager"
        echo "================================"
        echo
        echo "1) Performance Settings"
        echo "2) AI Configuration"
        echo "3) Profile Management"
        echo "4) Theme Management"
        echo "5) Cache Management"
        echo "6) View Current Config"
        echo "7) Reset to Defaults"
        echo "0) Exit"
        echo
        read -p "Select option: " choice
        
        case "$choice" in
            1)
                configure_performance
                ;;
            2)
                configure_ai
                ;;
            3)
                echo
                echo "Profile Management:"
                echo "1) List profiles"
                echo "2) Create profile"
                echo "3) Load profile"
                read -p "Select: " profile_choice
                
                case "$profile_choice" in
                    1) list_profiles ;;
                    2)
                        read -p "Profile name: " profile_name
                        [[ -n "$profile_name" ]] && create_profile "$profile_name"
                        ;;
                    3)
                        list_profiles
                        read -p "Profile to load: " profile_name
                        [[ -n "$profile_name" ]] && load_profile "$profile_name"
                        ;;
                esac
                ;;
            4)
                echo "Theme management coming soon..."
                ;;
            5)
                echo
                echo "Cache Management:"
                echo "1) Show cache info"
                echo "2) Clean old cache"
                echo "3) Clear all cache"
                read -p "Select: " cache_choice
                
                case "$cache_choice" in
                    1) show_cache_info ;;
                    2) clean_cache ;;
                    3) clear_all_cache ;;
                esac
                ;;
            6)
                echo
                echo "Current Configuration:"
                echo "======================"
                cat "$CONFIG_FILE"
                ;;
            7)
                read -p "Reset to defaults? This will overwrite current settings (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo "$DEFAULT_CONFIG" > "$CONFIG_FILE"
                    echo "Configuration reset to defaults"
                fi
                ;;
            0)
                echo "Configuration saved. Exiting..."
                break
                ;;
            *)
                echo "Invalid option"
                ;;
        esac
    done
}

# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

main() {
    # Initialize configuration
    init_config
    
    case "${1:-menu}" in
        "init")
            init_config
            echo "Configuration initialized"
            ;;
        "get")
            [[ -n "${2:-}" ]] && get_config "$2" "${3:-}"
            ;;
        "set")
            [[ -n "${2:-}" ]] && [[ -n "${3:-}" ]] && set_config "$2" "$3"
            ;;
        "clean")
            clean_cache
            ;;
        "clear")
            clear_all_cache
            ;;
        "info")
            show_cache_info
            ;;
        "menu"|*)
            show_config_menu
            ;;
    esac
}

# Export functions for use by other scripts
export -f init_config get_config set_config clean_cache clear_all_cache

# Run main if called directly
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@" 