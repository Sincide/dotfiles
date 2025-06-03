#!/bin/bash

# =============================================================================
# 🧠 AI-ENHANCED THEMING CONFIGURATION & CONTROL
# =============================================================================
# Easy configuration and control interface for AI theming modes
# Usage: source this file or run directly for interactive configuration

# Configuration file location
AI_CONFIG_FILE="$HOME/.config/dynamic-theming/ai-config.conf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure gum is available
ensure_gum() {
    if ! command -v gum &>/dev/null; then
        echo -e "${YELLOW}Installing gum for better UI...${NC}"
        if command -v yay &>/dev/null; then
            yay -S --noconfirm gum
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy --noconfirm gum
        else
            echo -e "${RED}Error: Neither yay nor pacman found. Please install gum manually.${NC}"
            return 1
        fi
    fi
}

# Default AI configuration
DEFAULT_AI_MODE="enhanced"  # Options: enhanced, vision, mathematical, disabled
DEFAULT_VISION_AI="true"
DEFAULT_MATHEMATICAL_AI="true"
DEFAULT_PERFORMANCE_TARGET="fast"  # Options: fast (<2s), balanced (<4s), quality (<6s)

# Create config directory
mkdir -p "$(dirname "$AI_CONFIG_FILE")"

# Initialize configuration file if it doesn't exist
init_ai_config() {
    if [[ ! -f "$AI_CONFIG_FILE" ]]; then
        cat > "$AI_CONFIG_FILE" << EOF
# AI-Enhanced Dynamic Theming Configuration
# Generated: $(date)

# AI Mode: enhanced, vision, mathematical, disabled
AI_MODE="$DEFAULT_AI_MODE"

# Individual AI Components
ENABLE_VISION_AI="$DEFAULT_VISION_AI"
ENABLE_MATHEMATICAL_AI="$DEFAULT_MATHEMATICAL_AI"

# Performance Settings
PERFORMANCE_TARGET="$DEFAULT_PERFORMANCE_TARGET"

# Vision AI Settings
VISION_WEIGHT="0.6"
MATHEMATICAL_WEIGHT="0.4"

# Fallback Behavior
FALLBACK_TO_STANDARD="true"
SHOW_AI_NOTIFICATIONS="true"

# Debug and Logging
AI_DEBUG="false"
AI_LOG_LEVEL="INFO"  # DEBUG, INFO, WARN, ERROR
EOF
        echo "✅ AI configuration initialized: $AI_CONFIG_FILE"
    fi
}

# Load current configuration
load_ai_config() {
    if [[ -f "$AI_CONFIG_FILE" ]]; then
        source "$AI_CONFIG_FILE"
    else
        init_ai_config
        source "$AI_CONFIG_FILE"
    fi
}

# Save configuration
save_ai_config() {
    cat > "$AI_CONFIG_FILE" << EOF
# AI-Enhanced Dynamic Theming Configuration
# Updated: $(date)

# AI Mode: enhanced, vision, mathematical, disabled
AI_MODE="$AI_MODE"

# Individual AI Components
ENABLE_VISION_AI="$ENABLE_VISION_AI"
ENABLE_MATHEMATICAL_AI="$ENABLE_MATHEMATICAL_AI"

# Performance Settings
PERFORMANCE_TARGET="$PERFORMANCE_TARGET"

# Vision AI Settings
VISION_WEIGHT="${VISION_WEIGHT:-0.6}"
MATHEMATICAL_WEIGHT="${MATHEMATICAL_WEIGHT:-0.4}"

# Fallback Behavior
FALLBACK_TO_STANDARD="${FALLBACK_TO_STANDARD:-true}"
SHOW_AI_NOTIFICATIONS="${SHOW_AI_NOTIFICATIONS:-true}"

# Debug and Logging
AI_DEBUG="${AI_DEBUG:-false}"
AI_LOG_LEVEL="${AI_LOG_LEVEL:-INFO}"
EOF
    echo "✅ AI configuration saved to: $AI_CONFIG_FILE"
}

# Set AI mode with validation
set_ai_mode() {
    local mode="$1"
    
    case "$mode" in
        "enhanced")
            AI_MODE="enhanced"
            ENABLE_VISION_AI="true"
            ENABLE_MATHEMATICAL_AI="true"
            echo "🧠 AI Mode: Enhanced Intelligence (Vision + Mathematical)"
            ;;
        "vision")
            AI_MODE="vision"
            ENABLE_VISION_AI="true"
            ENABLE_MATHEMATICAL_AI="false"
            echo "👁️ AI Mode: Vision Only (Content-aware theming)"
            ;;
        "mathematical")
            AI_MODE="mathematical"
            ENABLE_VISION_AI="false"
            ENABLE_MATHEMATICAL_AI="true"
            echo "🔢 AI Mode: Mathematical Only (Harmony + Accessibility)"
            ;;
        "disabled")
            AI_MODE="disabled"
            ENABLE_VISION_AI="false"
            ENABLE_MATHEMATICAL_AI="false"
            echo "❌ AI Mode: Disabled (Standard matugen only)"
            ;;
        *)
            echo "❌ Invalid AI mode: $mode"
            echo "Valid modes: enhanced, vision, mathematical, disabled"
            return 1
            ;;
    esac
    
    save_ai_config
}

# Get current AI status
get_ai_status() {
    load_ai_config
    
    echo "=== 🧠 AI-Enhanced Theming Status ==="
    echo "Mode: $AI_MODE"
    echo "Vision AI: $ENABLE_VISION_AI"
    echo "Mathematical AI: $ENABLE_MATHEMATICAL_AI"
    echo "Performance Target: $PERFORMANCE_TARGET"
    
    case "$AI_MODE" in
        "enhanced")
            echo "🎯 Active: Full AI intelligence with content-aware strategy selection"
            ;;
        "vision")
            echo "👁️ Active: Content analysis and mood-based theming"
            ;;
        "mathematical")
            echo "🔢 Active: Color harmony optimization and accessibility enhancement"
            ;;
        "disabled")
            echo "⚫ Inactive: Using standard matugen color extraction"
            ;;
    esac
    
    echo "Config file: $AI_CONFIG_FILE"
}

# Configure advanced AI settings
configure_advanced_settings() {
    load_ai_config
    echo "=== ⚙️ Advanced AI Settings ==="
    echo ""
    echo "Current Settings:"
    echo "  Vision Weight: ${VISION_WEIGHT:-0.6}"
    echo "  Mathematical Weight: ${MATHEMATICAL_WEIGHT:-0.4}"
    echo "  Performance Target: ${PERFORMANCE_TARGET:-fast}"
    echo "  Show Notifications: ${SHOW_AI_NOTIFICATIONS:-true}"
    echo ""
    
    # Ensure gum is available
    ensure_gum
    
    local choice_desc
    choice_desc=$(printf '%s\n' \
        "1) Set Vision Weight (${VISION_WEIGHT:-0.6})" \
        "2) Set Mathematical Weight (${MATHEMATICAL_WEIGHT:-0.4})" \
        "3) Set Performance Target (${PERFORMANCE_TARGET:-fast})" \
        "4) Toggle AI Notifications (${SHOW_AI_NOTIFICATIONS:-true})" \
        "5) Back to main menu" | \
        gum choose --height 8 --header "⚙️ Advanced Settings")
    
    local choice=$(echo "$choice_desc" | cut -d')' -f1)
    
    case "$choice" in
        1)
            echo "Current Vision Weight: ${VISION_WEIGHT:-0.6}"
            echo "Controls how much weight Vision AI has in color decisions (0.0-1.0)"
            local new_weight
            new_weight=$(gum input --placeholder "0.6" --prompt "Vision Weight: ")
            if [[ "$new_weight" =~ ^0\.[0-9]+$ ]] || [[ "$new_weight" =~ ^1\.0+$ ]]; then
                VISION_WEIGHT="$new_weight"
                MATHEMATICAL_WEIGHT=$(echo "1.0 - $VISION_WEIGHT" | bc -l | xargs printf "%.1f")
                save_ai_config
                echo "✅ Vision Weight set to $VISION_WEIGHT, Mathematical Weight adjusted to $MATHEMATICAL_WEIGHT"
            else
                echo "❌ Invalid weight. Must be between 0.0 and 1.0"
            fi
            ;;
        2)
            echo "Current Mathematical Weight: ${MATHEMATICAL_WEIGHT:-0.4}"
            echo "Controls how much weight Mathematical AI has in color decisions (0.0-1.0)"
            local new_weight
            new_weight=$(gum input --placeholder "0.4" --prompt "Mathematical Weight: ")
            if [[ "$new_weight" =~ ^0\.[0-9]+$ ]] || [[ "$new_weight" =~ ^1\.0+$ ]]; then
                MATHEMATICAL_WEIGHT="$new_weight"
                VISION_WEIGHT=$(echo "1.0 - $MATHEMATICAL_WEIGHT" | bc -l | xargs printf "%.1f")
                save_ai_config
                echo "✅ Mathematical Weight set to $MATHEMATICAL_WEIGHT, Vision Weight adjusted to $VISION_WEIGHT"
            else
                echo "❌ Invalid weight. Must be between 0.0 and 1.0"
            fi
            ;;
        3)
            echo "Current Performance Target: ${PERFORMANCE_TARGET:-fast}"
            local target_choice
            target_choice=$(printf '%s\n' \
                "fast - Prioritize speed (<2s)" \
                "balanced - Balance speed/quality (<4s)" \
                "quality - Prioritize quality (<6s)" | \
                gum choose --height 5 --header "Performance Target")
            
            local target=$(echo "$target_choice" | cut -d' ' -f1)
            if [[ -n "$target" ]]; then
                PERFORMANCE_TARGET="$target"
                save_ai_config
                echo "✅ Performance Target set to $target"
            fi
            ;;
        4)
            if [[ "${SHOW_AI_NOTIFICATIONS:-true}" == "true" ]]; then
                SHOW_AI_NOTIFICATIONS="false"
                echo "🔕 AI notifications disabled"
            else
                SHOW_AI_NOTIFICATIONS="true"
                echo "🔔 AI notifications enabled"
            fi
            save_ai_config
            ;;
        5)
            return 0
            ;;
        *)
            echo "❌ Invalid option"
            ;;
    esac
    
    # Show updated configuration after change
    echo ""
    echo "Updated Settings:"
    echo "  Vision Weight: ${VISION_WEIGHT}"
    echo "  Mathematical Weight: ${MATHEMATICAL_WEIGHT}"
    echo "  Performance Target: ${PERFORMANCE_TARGET}"
    echo "  Show Notifications: ${SHOW_AI_NOTIFICATIONS}"
    echo ""
    read -p "Press Enter to continue..."
}

# Interactive configuration menu
interactive_config() {
    while true; do
        echo "=== 🛠️ AI-Enhanced Theming Configuration ==="
        echo ""
        echo "Current Status:"
        get_ai_status
        echo ""
        
        # Ensure gum is available
        ensure_gum
        
        # Use gum for selection
        local choice_desc
        choice_desc=$(printf '%s\n' \
            "1) Enhanced Intelligence (Vision + Mathematical) - Recommended" \
            "2) Vision AI Only (Content-aware theming)" \
            "3) Mathematical AI Only (Harmony + Accessibility)" \
            "4) Disable AI (Standard theming)" \
            "5) Advanced Settings (Weights, Performance Target)" \
            "6) Show detailed status" \
            "7) Test current configuration" \
            "8) Reset to defaults" \
            "9) Exit" | \
            gum choose --height 12 --header "🛠️ AI Configuration Options")
        
        # Check if user cancelled
        if [ -z "$choice_desc" ]; then
            echo "👋 Configuration cancelled!"
            return 0
        fi
        
        # Extract number from choice
        local choice=$(echo "$choice_desc" | cut -d')' -f1)
        
        case "$choice" in
            1)
                set_ai_mode "enhanced"
                echo "🎉 Enhanced AI mode activated!"
                sleep 2
                ;;
            2)
                set_ai_mode "vision"
                echo "👁️ Vision AI mode activated!"
                sleep 2
                ;;
            3)
                set_ai_mode "mathematical"
                echo "🔢 Mathematical AI mode activated!"
                sleep 2
                ;;
            4)
                set_ai_mode "disabled"
                echo "❌ AI disabled. Using standard theming."
                sleep 2
                ;;
            5)
                configure_advanced_settings
                ;;
            6)
                show_detailed_status
                read -p "Press Enter to continue..."
                ;;
            7)
                test_ai_configuration
                read -p "Press Enter to continue..."
                ;;
            8)
                rm -f "$AI_CONFIG_FILE"
                init_ai_config
                echo "🔄 Configuration reset to defaults"
                sleep 2
                ;;
            9)
                return 0
                ;;
            *)
                echo "❌ Invalid option"
                sleep 1
                ;;
        esac
        
        # Clear screen for next iteration
        clear
    done
}

# Show detailed status
show_detailed_status() {
    load_ai_config
    
    echo "=== 📊 Detailed AI Configuration ==="
    echo ""
    echo "🎯 Core Configuration:"
    echo "  AI Mode: $AI_MODE"
    echo "  Vision AI: $ENABLE_VISION_AI"
    echo "  Mathematical AI: $ENABLE_MATHEMATICAL_AI"
    echo ""
    echo "⚡ Performance Settings:"
    echo "  Target: $PERFORMANCE_TARGET"
    echo "  Vision Weight: ${VISION_WEIGHT:-0.6}"
    echo "  Mathematical Weight: ${MATHEMATICAL_WEIGHT:-0.4}"
    echo ""
    echo "🛡️ Behavior Settings:"
    echo "  Fallback to Standard: ${FALLBACK_TO_STANDARD:-true}"
    echo "  Show Notifications: ${SHOW_AI_NOTIFICATIONS:-true}"
    echo ""
    echo "🔧 Debug Settings:"
    echo "  Debug Mode: ${AI_DEBUG:-false}"
    echo "  Log Level: ${AI_LOG_LEVEL:-INFO}"
    echo ""
    echo "📁 Files:"
    echo "  Config: $AI_CONFIG_FILE"
    echo "  Enhanced Intelligence: $SCRIPT_DIR/enhanced-color-intelligence.sh"
    echo "  Vision Analyzer: $SCRIPT_DIR/vision-analyzer.sh"
    echo "  Mathematical AI: $SCRIPT_DIR/color-harmony-analyzer.sh"
}

# Test current AI configuration
test_ai_configuration() {
    load_ai_config
    
    echo "🧪 Testing AI configuration..."
    echo "Mode: $AI_MODE"
    
    # Test with the numbers.jpg wallpaper if available
    local test_wallpaper="/home/martin/dotfiles/assets/wallpapers/abstract/numbers.jpg"
    local test_colors="/tmp/test-matugen-colors.json"
    
    if [[ ! -f "$test_wallpaper" ]]; then
        echo "❌ Test wallpaper not found: $test_wallpaper"
        return 1
    fi
    
    if [[ ! -f "$test_colors" ]]; then
        echo "❌ Test colors file not found: $test_colors"
        echo "💡 Run a standard matugen extraction first"
        return 1
    fi
    
    case "$AI_MODE" in
        "enhanced")
            echo "Testing Enhanced Intelligence..."
            if bash "$SCRIPT_DIR/enhanced-color-intelligence.sh" "$test_wallpaper" "$test_colors" "/tmp/ai-test-output.json"; then
                echo "✅ Enhanced AI test successful!"
                if [[ -f "/tmp/ai-test-output.json" ]]; then
                    echo "Strategy: $(jq -r '.enhanced_intelligence.strategy' /tmp/ai-test-output.json)"
                    echo "Confidence: $(jq -r '.enhanced_intelligence.confidence' /tmp/ai-test-output.json)"
                fi
            else
                echo "❌ Enhanced AI test failed"
            fi
            ;;
        "vision")
            echo "Testing Vision AI..."
            if bash "$SCRIPT_DIR/vision-analyzer.sh" "$test_wallpaper" "/tmp/vision-test-output.json"; then
                echo "✅ Vision AI test successful!"
                if [[ -f "/tmp/vision-test-output.json" ]]; then
                    echo "Category: $(jq -r '.category' /tmp/vision-test-output.json)"
                    echo "Mood: $(jq -r '.mood' /tmp/vision-test-output.json)"
                fi
            else
                echo "❌ Vision AI test failed"
            fi
            ;;
        "mathematical")
            echo "Testing Mathematical AI..."
            if bash "$SCRIPT_DIR/color-harmony-analyzer.sh" "$test_colors" "/tmp/math-test-output.json"; then
                echo "✅ Mathematical AI test successful!"
                if [[ -f "/tmp/math-test-output.json" ]]; then
                    echo "Palette Score: $(jq -r '.palette_score' /tmp/math-test-output.json)"
                fi
            else
                echo "❌ Mathematical AI test failed"
            fi
            ;;
        "disabled")
            echo "✅ AI disabled - no testing needed"
            ;;
    esac
}

# Quick mode switchers (for scripts/aliases)
ai_enhanced() { set_ai_mode "enhanced"; }
ai_vision() { set_ai_mode "vision"; }
ai_mathematical() { set_ai_mode "mathematical"; }
ai_disable() { set_ai_mode "disabled"; }
ai_status() { get_ai_status; }
ai_config() { interactive_config; }


# Main entry point
main() {
    case "${1:-status}" in
        "enhanced"|"vision"|"mathematical"|"disabled")
            set_ai_mode "$1"
            ;;
        "status")
            get_ai_status
            ;;
        "config"|"configure")
            interactive_config
            ;;
        "test")
            test_ai_configuration
            ;;
        "init")
            init_ai_config
            ;;
        "--help"|"-h"|"help")
            echo "AI-Enhanced Theming Control"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  enhanced     - Enable full AI intelligence"
            echo "  vision       - Enable vision AI only"
            echo "  mathematical - Enable mathematical AI only"
            echo "  disabled     - Disable AI theming"
            echo "  status       - Show current status"
            echo "  config       - Interactive configuration"
            echo "  test         - Test current configuration"
            echo "  init         - Initialize configuration"
            echo ""
            echo "Examples:"
            echo "  $0 enhanced    # Enable full AI"
            echo "  $0 status      # Check current mode"
            echo "  $0 config      # Interactive setup"
            ;;
        *)
            echo "❌ Unknown command: $1"
            echo "Use '$0 help' for usage information"
            return 1
            ;;
    esac
}

# Auto-initialize on source/load
init_ai_config >/dev/null 2>&1

# Run main if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 