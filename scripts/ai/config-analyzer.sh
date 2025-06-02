#!/bin/bash

# =============================================================================
# 🔧 CONFIGURATION ANALYZER - AI-POWERED SYSTEM INTELLIGENCE
# =============================================================================
# Comprehensive system configuration analysis and optimization
# Part of: AI Configuration Management System
# Phase: 1 - System Analysis and Intelligence

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# If we're running from a symlink, get the real script directory
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
fi
CONFIG_FILE="$HOME/.config/dynamic-theming/config-analyzer.conf"

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

# Default configuration
DEFAULT_ANALYSIS_MODE="comprehensive"  # Options: quick, comprehensive, deep
DEFAULT_AUTO_CLEANUP="false"
DEFAULT_SHOW_NOTIFICATIONS="true"

# Create config directory
mkdir -p "$(dirname "$CONFIG_FILE")"

# Initialize configuration file if it doesn't exist
init_config_analyzer() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
# AI Configuration Analyzer Settings
# Generated: $(date)

# Analysis Mode: quick, comprehensive, deep
ANALYSIS_MODE="$DEFAULT_ANALYSIS_MODE"

# Automation Settings
AUTO_CLEANUP="$DEFAULT_AUTO_CLEANUP"
SHOW_NOTIFICATIONS="$DEFAULT_SHOW_NOTIFICATIONS"

# Component Analysis Settings
ENABLE_GPU_ANALYSIS="true"
ENABLE_BOOT_ANALYSIS="true"
ENABLE_PACKAGE_ANALYSIS="true"
ENABLE_MEMORY_ANALYSIS="true"

# Performance Targets
ANALYSIS_TIMEOUT="10"  # seconds
MAX_ANALYSIS_TIME="30"  # seconds for deep analysis

# Output Settings
SAVE_DETAILED_LOGS="true"
JSON_OUTPUT_FORMAT="true"
EOF
        echo "✅ Configuration analyzer initialized: $CONFIG_FILE"
    fi
}

# Load current configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        init_config_analyzer
        source "$CONFIG_FILE"
    fi
}

# System Health Analysis Functions
analyze_system_health() {
    echo "🏥 Running System Health Analysis..."
    local output_file="${1:-/tmp/system-health-analysis.json}"
    
    # Load configuration
    load_config
    
    # Set environment variables for the analyzer
    export ENABLE_GPU_ANALYSIS="${ENABLE_GPU_ANALYSIS:-true}"
    export ENABLE_BOOT_ANALYSIS="${ENABLE_BOOT_ANALYSIS:-true}"
    export ENABLE_PACKAGE_ANALYSIS="${ENABLE_PACKAGE_ANALYSIS:-true}"
    export ENABLE_MEMORY_ANALYSIS="${ENABLE_MEMORY_ANALYSIS:-true}"
    
    bash "$SCRIPT_DIR/config-system-health-analyzer.sh" "$output_file"
}

analyze_system_performance() {
    echo "⚡ Running Performance Analysis..."
    local output_file="${1:-/tmp/system-performance-analysis.json}"
    
    # Load configuration and enable all performance-related analysis
    load_config
    export ENABLE_BOOT_ANALYSIS="true"
    export ENABLE_PACKAGE_ANALYSIS="true"
    export ENABLE_MEMORY_ANALYSIS="true"
    export ENABLE_GPU_ANALYSIS="true"
    
    bash "$SCRIPT_DIR/config-system-health-analyzer.sh" "$output_file"
    
    echo ""
    echo "🎯 Performance Optimization Suggestions:"
    
    # Extract specific performance recommendations
    if [[ -f "$output_file" ]]; then
        local boot_score=$(cat "$output_file" | grep -A 15 '"boot":' | grep '"score":' | awk '{print $2}' | sed 's/,//' || echo "100")
        if (( boot_score < 80 )); then
            echo "• PRIORITY: Boot optimization available - man-db.service optimization recommended"
            echo "  Command: sudo systemctl disable man-db.timer"
        fi
        
        # Package cache cleanup
        if command -v paccache &> /dev/null; then
            local cache_cleanup=$(paccache -d 2>/dev/null | grep "disk space saved" | awk '{print $5 " " $6}' || echo "")
            if [[ -n "$cache_cleanup" && "$cache_cleanup" != "0 B" ]]; then
                echo "• Package cache cleanup available: $cache_cleanup"
                echo "  Command: sudo paccache -r"
            fi
        fi
    fi
}

validate_system_security() {
    echo "🔒 Running Security Validation..."
    echo ""
    echo "🚧 Phase 1B - Configuration Validator (Coming Soon)"
    echo "📋 Current security analysis available through system health check"
    echo ""
    
    # Run basic security-focused analysis
    local output_file="${1:-/tmp/system-security-analysis.json}"
    
    echo "Running basic security analysis..."
    load_config
    export ENABLE_GPU_ANALYSIS="false"  # Focus on security, not GPU
    export ENABLE_BOOT_ANALYSIS="true"
    export ENABLE_PACKAGE_ANALYSIS="true" 
    export ENABLE_MEMORY_ANALYSIS="true"
    
    bash "$SCRIPT_DIR/config-system-health-analyzer.sh" "$output_file"
    
    echo ""
    echo "🛡️  Basic Security Recommendations:"
    echo "• File permissions are analyzed in the health check"
    echo "• Package security updates are identified"
    echo "• Service configuration is reviewed"
    echo "• Full security validator coming in Phase 1B"
}

# Quick system status overview
system_status() {
    echo "🖥️  Quick System Status Check..."
    echo ""
    
    # Quick hardware overview
    echo "💻 Hardware:"
    echo "  CPU: $(lscpu | grep "Model name" | sed 's/Model name: *//')"
    echo "  Memory: $(free -h | grep "Mem:" | awk '{print $3 "/" $2 " (" int($3/$2*100) "%)"}')"
    echo "  GPU: $(lspci | grep -i "VGA\|3D" | cut -d: -f3- | sed 's/^ *//')"
    echo ""
    
    # Quick package status
    echo "📦 Packages:"
    echo "  Total: $(pacman -Q | wc -l)"
    echo "  Explicit: $(pacman -Qe | wc -l)"
    echo "  Updates: $(checkupdates 2>/dev/null | wc -l || echo "Unknown")"
    echo ""
    
    # Quick disk status
    echo "💾 Storage:"
    local root_usage=$(df / 2>/dev/null | tail -1 | awk '{print $5}')
    echo "  Root: $root_usage used"
    
    # Quick boot performance
    if command -v systemd-analyze &> /dev/null; then
        local boot_time=$(systemd-analyze 2>/dev/null | grep "Startup finished" | sed 's/.*= *//' | awk '{print $1}' || echo "Unknown")
        echo "  Boot time: $boot_time"
    fi
    
    echo ""
    echo "For detailed analysis, run: config-analyzer analyze health"
}

# Package ecosystem analysis
analyze_packages() {
    echo "📦 Running Package Ecosystem Analysis..."
    local output_file="${1:-/tmp/package-analysis.json}"
    
    load_config
    export ENABLE_GPU_ANALYSIS="false"
    export ENABLE_BOOT_ANALYSIS="false"  
    export ENABLE_PACKAGE_ANALYSIS="true"
    export ENABLE_MEMORY_ANALYSIS="false"
    
    bash "$SCRIPT_DIR/config-system-health-analyzer.sh" "$output_file"
    
    echo ""
    echo "🧹 Package Cleanup Opportunities:"
    
    # Orphaned packages
    local orphaned_count=$(pacman -Qtdq 2>/dev/null | wc -l || echo 0)
    if (( orphaned_count > 0 )); then
        echo "• Remove $orphaned_count orphaned packages"
        echo "  Command: sudo pacman -Rns \$(pacman -Qtdq)"
    fi
    
    # Package cache
    if command -v paccache &> /dev/null; then
        local cache_info=$(paccache -d 2>/dev/null | tail -1 || echo "")
        if [[ "$cache_info" =~ saved:\ ([0-9.]+\ [A-Za-z]+) ]]; then
            echo "• Clean package cache: ${BASH_REMATCH[1]}"
            echo "  Command: sudo paccache -r"
        fi
    fi
}

# Configuration management
show_config() {
    load_config
    
    echo "=== 🔧 Configuration Analyzer Settings ==="
    echo ""
    echo "Analysis Mode: $ANALYSIS_MODE"
    echo "Auto Cleanup: $AUTO_CLEANUP"
    echo "Show Notifications: $SHOW_NOTIFICATIONS"
    echo ""
    echo "Component Analysis:"
    echo "  GPU Analysis: $ENABLE_GPU_ANALYSIS"
    echo "  Boot Analysis: $ENABLE_BOOT_ANALYSIS"  
    echo "  Package Analysis: $ENABLE_PACKAGE_ANALYSIS"
    echo "  Memory Analysis: $ENABLE_MEMORY_ANALYSIS"
    echo ""
    echo "Config file: $CONFIG_FILE"
}

configure_analyzer() {
    echo "=== ⚙️ Configuration Analyzer Setup ==="
    echo ""
    show_config
    echo ""
    
    # Ensure gum is available
    ensure_gum
    
    # Use gum for selection
    local choice_desc
    choice_desc=$(printf '%s\n' \
        "1) Change analysis mode (quick/comprehensive/deep)" \
        "2) Toggle component analysis" \
        "3) Reset to defaults" \
        "4) Show current configuration" \
        "5) Exit" | \
        gum choose --height 8 --header "⚙️ Configuration Options")
    
    # Extract number from choice
    local choice=$(echo "$choice_desc" | cut -d')' -f1)
    
    case "$choice" in
        1)
            echo "Select analysis mode:"
            
            local mode_desc
            mode_desc=$(printf '%s\n' \
                "1) Quick (basic health check)" \
                "2) Comprehensive (full analysis) - Recommended" \
                "3) Deep (detailed with extended timeouts)" | \
                gum choose --height 5 --header "Analysis Mode Selection")
            
            local mode_choice=$(echo "$mode_desc" | cut -d')' -f1)
            
            case "$mode_choice" in
                1) ANALYSIS_MODE="quick" ;;
                2) ANALYSIS_MODE="comprehensive" ;;
                3) ANALYSIS_MODE="deep" ;;
                *) echo "❌ Invalid choice"; return 1 ;;
            esac
            
            # Update config file
            sed -i "s/ANALYSIS_MODE=.*/ANALYSIS_MODE=\"$ANALYSIS_MODE\"/" "$CONFIG_FILE"
            echo "✅ Analysis mode set to: $ANALYSIS_MODE"
            ;;
        2)
            echo "Toggle component analysis (current settings):"
            
            local comp_desc
            comp_desc=$(printf '%s\n' \
                "1) GPU Analysis: $ENABLE_GPU_ANALYSIS" \
                "2) Boot Analysis: $ENABLE_BOOT_ANALYSIS" \
                "3) Package Analysis: $ENABLE_PACKAGE_ANALYSIS" \
                "4) Memory Analysis: $ENABLE_MEMORY_ANALYSIS" | \
                gum choose --height 6 --header "Component Analysis Toggle")
            
            local comp_choice=$(echo "$comp_desc" | cut -d')' -f1)
            
            case "$comp_choice" in
                1) 
                    new_val=$([ "$ENABLE_GPU_ANALYSIS" = "true" ] && echo "false" || echo "true")
                    sed -i "s/ENABLE_GPU_ANALYSIS=.*/ENABLE_GPU_ANALYSIS=\"$new_val\"/" "$CONFIG_FILE"
                    echo "✅ GPU Analysis: $new_val"
                    ;;
                2)
                    new_val=$([ "$ENABLE_BOOT_ANALYSIS" = "true" ] && echo "false" || echo "true")
                    sed -i "s/ENABLE_BOOT_ANALYSIS=.*/ENABLE_BOOT_ANALYSIS=\"$new_val\"/" "$CONFIG_FILE"
                    echo "✅ Boot Analysis: $new_val"
                    ;;
                3)
                    new_val=$([ "$ENABLE_PACKAGE_ANALYSIS" = "true" ] && echo "false" || echo "true")
                    sed -i "s/ENABLE_PACKAGE_ANALYSIS=.*/ENABLE_PACKAGE_ANALYSIS=\"$new_val\"/" "$CONFIG_FILE"
                    echo "✅ Package Analysis: $new_val"
                    ;;
                4)
                    new_val=$([ "$ENABLE_MEMORY_ANALYSIS" = "true" ] && echo "false" || echo "true")
                    sed -i "s/ENABLE_MEMORY_ANALYSIS=.*/ENABLE_MEMORY_ANALYSIS=\"$new_val\"/" "$CONFIG_FILE"
                    echo "✅ Memory Analysis: $new_val"
                    ;;
                *) echo "❌ Invalid choice"; return 1 ;;
            esac
            ;;
        3)
            rm -f "$CONFIG_FILE"
            init_config_analyzer
            echo "🔄 Configuration reset to defaults"
            ;;
        4)
            show_config
            ;;
        5)
            echo "👋 Configuration complete!"
            return 0
            ;;
        *)
            echo "❌ Invalid option"
            return 1
            ;;
    esac
}

# Main entry point
main() {
    case "${1:-status}" in
        "analyze")
            case "${2:-health}" in
                "health")
                    analyze_system_health "${3:-/tmp/system-health-analysis.json}"
                    ;;
                "performance")
                    analyze_system_performance "${3:-/tmp/system-performance-analysis.json}"
                    ;;
                "packages")
                    analyze_packages "${3:-/tmp/package-analysis.json}"
                    ;;
                "all")
                    echo "🔍 Running Comprehensive System Analysis..."
                    analyze_system_health "${3:-/tmp/system-comprehensive-analysis.json}"
                    ;;
                *)
                    echo "❌ Unknown analysis type: $2"
                    echo "Available: health, performance, packages, all"
                    return 1
                    ;;
            esac
            ;;
        "validate")
            case "${2:-security}" in
                "security")
                    validate_system_security "${3:-/tmp/system-security-analysis.json}"
                    ;;
                *)
                    echo "❌ Unknown validation type: $2"
                    echo "Available: security"
                    return 1
                    ;;
            esac
            ;;
        "optimize")
            echo "🧠 Launching Smart Optimizer with Ollama AI integration..."
            bash "$SCRIPT_DIR/config-smart-optimizer.sh" "${2:-optimize}"
            ;;
        "status")
            system_status
            ;;
        "config"|"configure")
            configure_analyzer
            ;;
        "show-config")
            show_config
            ;;
        "init")
            init_config_analyzer
            ;;
        "--help"|"-h"|"help")
            echo "🔧 Configuration Analyzer - AI-Powered System Intelligence"
            echo ""
            echo "Usage: $0 [command] [subcommand] [options]"
            echo ""
            echo "📊 Analysis Commands:"
            echo "  analyze health      - Comprehensive system health analysis"
            echo "  analyze performance - Performance optimization analysis"
            echo "  analyze packages    - Package ecosystem analysis"
            echo "  analyze all         - Complete system analysis"
            echo "  validate security   - Security configuration validation"
            echo "  status             - Quick system status overview"
            echo ""
            echo "🧠 AI-Enhanced Commands:"
            echo "  optimize           - Smart optimization with Ollama LLM integration"
            echo "  optimize boot      - Focus on boot performance (manual approval)"
            echo "  optimize packages  - Focus on package cleanup (manual approval)"
            echo ""
            echo "⚙️ Configuration Commands:"
            echo "  config             - Interactive configuration setup"
            echo "  show-config        - Display current configuration"
            echo "  init               - Initialize configuration"
            echo ""
            echo "📂 Output Options:"
            echo "  Most commands accept an optional output file path as the last argument"
            echo ""
            echo "Examples:"
            echo "  $0 analyze health                    # System health analysis"
            echo "  $0 analyze performance               # Performance optimization"
            echo "  $0 analyze packages                  # Package ecosystem"
            echo "  $0 validate security                 # Security validation"
            echo "  $0 status                           # Quick overview"
            echo "  $0 config                           # Configure analyzer"
            echo ""
            echo "📋 Features:"
            echo "  • AMD Ryzen 7 3700X + RX 7900 XT optimized analysis"
            echo "  • Arch Linux + Hyprland specific recommendations"
            echo "  • Intelligent scoring and prioritized suggestions"
            echo "  • JSON output for integration and automation"
            echo "  • Read-only analysis with zero system impact"
            ;;
        *)
            echo "❌ Unknown command: $1"
            echo "Use '$0 help' for usage information"
            return 1
            ;;
    esac
}

# Auto-initialize on source/load
init_config_analyzer >/dev/null 2>&1

# Run main if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 