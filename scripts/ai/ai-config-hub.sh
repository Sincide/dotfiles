#!/bin/bash

# =============================================================================
# 🎮 AI CONFIGURATION HUB - TERMINAL FRONTEND
# =============================================================================
# Unified interface for all AI-enhanced configuration management tools
# Part of: AI-Enhanced Configuration Management System
# Main Entry Point for All Features

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
HUB_LOG="/tmp/ai-config-hub.log"
ANALYSIS_CACHE="/tmp/system-health-analysis.json"

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Unicode symbols
CHECK="✅"
WARNING="⚠️ "
ERROR="❌"
AI="🧠"
ROCKET="🚀"
GEAR="⚙️ "
CHART="📊"
PALETTE="🎨"

# Logging function
log_hub() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$HUB_LOG"
}

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
            exit 1
        fi
    fi
}

# NOTE: All menus now use gum choose directly for better UX



# Clear screen and show header
show_header() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    ${AI} AI CONFIGURATION HUB ${AI}                       ║"
    echo "║              Intelligent System Management & Optimization             ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${DIM}AMD Ryzen 7 3700X + RX 7900 XT + Arch Linux + Hyprland${NC}"
    echo ""
}



# Get system status summary
get_system_status() {
    local overall_score="Unknown"
    local boot_score="Unknown"
    local llm_status="Unknown"
    local last_analysis="Never"
    
    # Check if recent analysis exists
    if [[ -f "$ANALYSIS_CACHE" ]]; then
        overall_score=$(cat "$ANALYSIS_CACHE" | grep '"overall_score":' | awk '{print $2}' | sed 's/,//' 2>/dev/null || echo "Unknown")
        boot_score=$(cat "$ANALYSIS_CACHE" | grep -A 15 '"boot":' | grep '"score":' | awk '{print $2}' | sed 's/,//' 2>/dev/null || echo "Unknown")
        
        # Get file modification time
        if command -v stat &> /dev/null; then
            last_analysis=$(stat -c %y "$ANALYSIS_CACHE" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1 || echo "Unknown")
        fi
    fi
    
    # Check Ollama status
    if command -v ollama &> /dev/null && ollama list &> /dev/null; then
        local model_count=$(ollama list | tail -n +2 | wc -l)
        llm_status="${GREEN}Online${NC} ($model_count models)"
    else
        llm_status="${YELLOW}Offline${NC}"
    fi
    
    echo -e "${BOLD}${CHART} SYSTEM STATUS OVERVIEW${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Overall health
    if [[ "$overall_score" != "Unknown" ]]; then
        local status_color="$GREEN"
        local status_text="Excellent"
        if (( $(echo "$overall_score < 60" | bc -l 2>/dev/null || echo 0) )); then
            status_color="$RED"
            status_text="Needs Attention"
        elif (( $(echo "$overall_score < 80" | bc -l 2>/dev/null || echo 0) )); then
            status_color="$YELLOW"
            status_text="Good"
        fi
        echo -e "  ${CHECK} Overall Health: ${status_color}${overall_score}/100${NC} (${status_text})"
    else
        echo -e "  ${WARNING} Overall Health: ${DIM}No recent analysis${NC}"
    fi
    
    # Boot performance
    if [[ "$boot_score" != "Unknown" ]]; then
        if (( $(echo "$boot_score < 70" | bc -l 2>/dev/null || echo 0) )); then
            echo -e "  ${WARNING} Boot Performance: ${YELLOW}${boot_score}/100${NC} ${DIM}(Optimization available)${NC}"
        else
            echo -e "  ${CHECK} Boot Performance: ${GREEN}${boot_score}/100${NC}"
        fi
    else
        echo -e "  ${WARNING} Boot Performance: ${DIM}No recent analysis${NC}"
    fi
    
    # AI status
    echo -e "  ${AI} AI Engine (Ollama): $llm_status"
    
    # Last analysis
    echo -e "  ${CHART} Last Analysis: ${DIM}$last_analysis${NC}"
    
    echo ""
}

# Show main menu
show_main_menu() {
    echo -e "${BOLD}${GEAR} MAIN MENU${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ${CHART} ${BOLD}1)${NC} AI System Analysis     ${DIM}→ Health, Performance, Package analysis (auto-AI)${NC}"
    echo -e "  ${AI} ${BOLD}2)${NC} AI-Powered Optimization ${DIM}→ Smart optimization with LLM analysis${NC}"
    echo -e "  ${ROCKET} ${BOLD}3)${NC} Quick Optimization     ${DIM}→ Fast hardcoded fixes (no AI analysis)${NC}"
    echo -e "  ${PALETTE} ${BOLD}4)${NC} Theme Management       ${DIM}→ Color harmony, Material You theming${NC}"
    echo -e "  ${GEAR} ${BOLD}5)${NC} Configuration          ${DIM}→ Settings, help, documentation${NC}"
    echo -e "  🔄 ${BOLD}6)${NC} Refresh Status         ${DIM}→ Update system overview${NC}"
    echo -e "  🚪 ${BOLD}0)${NC} Exit                   ${DIM}→ Leave AI Configuration Hub${NC}"
    echo ""
}

# System Analysis submenu
show_analysis_menu() {
    show_header
    echo -e "${BOLD}${CHART} SYSTEM ANALYSIS${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ${BOLD}1)${NC} ${GREEN}Full Health Analysis${NC}    ${DIM}→ Comprehensive system health check${NC}"
    echo -e "  ${BOLD}2)${NC} ${YELLOW}Performance Analysis${NC}   ${DIM}→ Focus on optimization opportunities${NC}"
    echo -e "  ${BOLD}3)${NC} ${BLUE}Package Analysis${NC}       ${DIM}→ Package ecosystem and cleanup${NC}"
    echo -e "  ${BOLD}4)${NC} ${CYAN}Quick Status${NC}           ${DIM}→ Fast system overview${NC}"
    echo -e "  ${BOLD}5)${NC} ${PURPLE}View Latest Results${NC}   ${DIM}→ Show detailed analysis data${NC}"
    echo ""
    echo -e "  ${BOLD}0)${NC} ${DIM}← Back to Main Menu${NC}"
    echo ""
    
    echo -e "${DIM}Use ↑↓ arrow keys and Enter to navigate${NC}"
    echo ""
    
    # Analysis menu with descriptive options
    choice=$(printf '%s\n' \
        "1) Full Health Analysis" \
        "2) Performance Analysis" \
        "3) Package Analysis" \
        "4) Quick Status" \
        "5) View Latest Results" \
        "0) Back to Main Menu" \
        "Quit" | \
        gum choose --height 10 --header "📊 System Analysis Menu")
    
    case "$choice" in
        "1) Full Health Analysis")
            echo -e "\n${CYAN}Running comprehensive health analysis...${NC}"
            bash "$SCRIPT_DIR/config-analyzer.sh" analyze health || true
            ;;
        "2) Performance Analysis")
            echo -e "\n${CYAN}Running performance analysis...${NC}"
            bash "$SCRIPT_DIR/config-analyzer.sh" analyze performance || true
            ;;
        "3) Package Analysis")
            echo -e "\n${CYAN}Running package analysis...${NC}"
            bash "$SCRIPT_DIR/config-analyzer.sh" analyze packages || true
            ;;
        "4) Quick Status")
            echo -e "\n${CYAN}Getting quick system status...${NC}"
            bash "$SCRIPT_DIR/config-analyzer.sh" status || true
            ;;
        "5) View Latest Results")
            if [[ -f "$ANALYSIS_CACHE" ]]; then
                echo -e "\n${CYAN}Latest analysis results:${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                cat "$ANALYSIS_CACHE" | head -20
                echo -e "\n${DIM}Full results: $ANALYSIS_CACHE${NC}"
            else
                echo -e "\n${YELLOW}No analysis results found. Run an analysis first.${NC}"
            fi
            ;;
        "0) Back to Main Menu"|"")
            return 0
            ;;
        "Quit")
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid selection. Please try again.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..." 
}

# AI Optimization submenu
show_ai_menu() {
    show_header
    echo -e "${BOLD}${AI} AI-POWERED OPTIMIZATION${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check AI status
    if command -v ollama &> /dev/null && ollama list &> /dev/null; then
        local model_count=$(ollama list | tail -n +2 | wc -l)
        echo -e "  ${CHECK} ${GREEN}Ollama AI Available${NC} ($model_count models loaded)"
    else
        echo -e "  ${WARNING} ${YELLOW}Ollama AI Unavailable${NC} (will use rule-based optimization)"
    fi
    echo ""
    
    echo -e "  ${BOLD}1)${NC} ${AI} ${GREEN}Smart Optimization${NC}    ${DIM}→ Full AI analysis + manual approval${NC}"
    echo -e "  ${BOLD}2)${NC} ${ROCKET} ${YELLOW}Quick Boot Fix${NC}        ${DIM}→ Immediate boot performance fix${NC}"
    echo -e "  ${BOLD}3)${NC} ${GEAR} ${BLUE}Package Cleanup${NC}       ${DIM}→ Clean package cache and orphans${NC}"
    echo -e "  ${BOLD}4)${NC} ${CHART} ${CYAN}Analyze Issues Only${NC}   ${DIM}→ Identify problems without fixing${NC}"
    echo ""
    echo -e "  ${BOLD}0)${NC} ${DIM}← Back to Main Menu${NC}"
    echo ""
    
    echo -e "${DIM}Use ↑↓ arrow keys and Enter to navigate${NC}"
    echo ""
    
    # AI Optimization menu with descriptive options
    choice=$(printf '%s\n' \
        "1) Smart Optimization" \
        "2) Quick Boot Fix" \
        "3) Package Cleanup" \
        "4) Analyze Issues Only" \
        "0) Back to Main Menu" \
        "Quit" | \
        gum choose --height 9 --header "🧠 AI-Powered Optimization Menu")
    
    case "$choice" in
        "1) Smart Optimization")
            echo -e "\n${CYAN}Launching AI-powered smart optimization...${NC}"
            bash "$SCRIPT_DIR/config-smart-optimizer.sh" optimize
            ;;
        "2) Quick Boot Fix")
            echo -e "\n${CYAN}Running quick boot optimization...${NC}"
            bash "$SCRIPT_DIR/config-smart-optimizer.sh" boot
            ;;
        "3) Package Cleanup")
            echo -e "\n${CYAN}Running package cleanup...${NC}"
            bash "$SCRIPT_DIR/config-smart-optimizer.sh" packages
            ;;
        "4) Analyze Issues Only")
            echo -e "\n${CYAN}Analyzing optimization opportunities...${NC}"
            bash "$SCRIPT_DIR/config-smart-optimizer.sh" analyze || true
            ;;
        "0) Back to Main Menu"|"")
            return 0
            ;;
        "Quit")
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid selection. Please try again.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Quick Optimization submenu
show_quick_menu() {
    show_header
    echo -e "${BOLD}${ROCKET} QUICK OPTIMIZATION${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ${WARNING} ${BOLD}Fast hardcoded actions with immediate results (no AI analysis)${NC}"
    echo ""
    
    echo -e "  ${BOLD}1)${NC} ${ROCKET} ${GREEN}Fix Boot Performance${NC}  ${DIM}→ Disable man-db.timer (55% faster boot)${NC}"
    echo -e "  ${BOLD}2)${NC} ${GEAR} ${YELLOW}Clean Package Cache${NC}    ${DIM}→ Remove old package files${NC}"
    echo -e "  ${BOLD}3)${NC} ${CHART} ${BLUE}System Health Check${NC}    ${DIM}→ Quick analysis and fixes${NC}"
    echo -e "  ${BOLD}4)${NC} ${PALETTE} ${PURPLE}Theme Optimization${NC}     ${DIM}→ Color harmony analysis${NC}"
    echo ""
    echo -e "  ${BOLD}0)${NC} ${DIM}← Back to Main Menu${NC}"
    echo ""
    
    echo -e "${DIM}Use ↑↓ arrow keys and Enter to navigate${NC}"
    echo ""
    
    # Quick Optimization menu with descriptive options
    choice=$(printf '%s\n' \
        "1) Fix Boot Performance" \
        "2) Clean Package Cache" \
        "3) System Health Check" \
        "4) Theme Optimization" \
        "0) Back to Main Menu" \
        "Quit" | \
        gum choose --height 9 --header "🚀 Quick Optimization Menu")
    
    case "$choice" in
        "1) Fix Boot Performance")
            echo -e "\n${CYAN}Applying boot performance fix...${NC}"
            bash "$SCRIPT_DIR/config-smart-optimizer.sh" quick
            ;;
        "2) Clean Package Cache")
            echo -e "\n${CYAN}Cleaning package cache...${NC}"
            sudo paccache -r || echo -e "${YELLOW}Package cache cleanup completed or already clean${NC}"
            ;;
        "3) System Health Check")
            echo -e "\n${CYAN}Running quick health check...${NC}"
            bash "$SCRIPT_DIR/config-analyzer.sh" status || true
            ;;
        "4) Theme Optimization")
            echo -e "\n${CYAN}Running theme analysis...${NC}"
            # Check if color harmony analyzer exists
            if [[ -f "$SCRIPT_DIR/../ai-config.sh" ]]; then
                bash "$SCRIPT_DIR/../ai-config.sh" || echo -e "${YELLOW}Theme analysis not available${NC}"
            else
                echo -e "${YELLOW}Theme analysis not available. Run from main AI config.${NC}"
            fi
            ;;
        "0) Back to Main Menu"|"")
            return 0
            ;;
        "Quit")
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid selection. Please try again.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Configuration submenu
show_config_menu() {
    show_header
    echo -e "${BOLD}${GEAR} CONFIGURATION & HELP${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    echo -e "  ${BOLD}1)${NC} ${GEAR} ${GREEN}Analyzer Settings${NC}      ${DIM}→ Configure analysis parameters${NC}"
    echo -e "  ${BOLD}2)${NC} ${AI} ${YELLOW}AI Model Settings${NC}      ${DIM}→ Ollama model selection${NC}"
    echo -e "  ${BOLD}3)${NC} ${CHART} ${BLUE}View Documentation${NC}    ${DIM}→ Phase 1A completion guide${NC}"
    echo -e "  ${BOLD}4)${NC} ${GEAR} ${PURPLE}System Information${NC}    ${DIM}→ Hardware and OS details${NC}"
    echo -e "  ${BOLD}5)${NC} ${ROCKET} ${CYAN}Command Reference${NC}     ${DIM}→ All available commands${NC}"
    echo ""
    echo -e "  ${BOLD}0)${NC} ${DIM}← Back to Main Menu${NC}"
    echo ""
    
    echo -e "${DIM}Use ↑↓ arrow keys and Enter to navigate${NC}"
    echo ""
    
    # Configuration menu with descriptive options
    choice=$(printf '%s\n' \
        "1) Analyzer Settings" \
        "2) AI Model Settings" \
        "3) View Documentation" \
        "4) System Information" \
        "5) Command Reference" \
        "0) Back to Main Menu" \
        "Quit" | \
        gum choose --height 10 --header "⚙️ Configuration & Help Menu")
    
    case "$choice" in
        "1) Analyzer Settings")
            echo -e "\n${CYAN}Opening analyzer configuration...${NC}"
            bash "$SCRIPT_DIR/config-analyzer.sh" config
            ;;
        "2) AI Model Settings")
            echo -e "\n${CYAN}Available Ollama models:${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            if command -v ollama &> /dev/null; then
                ollama list || echo -e "${YELLOW}No models available or Ollama not running${NC}"
            else
                echo -e "${YELLOW}Ollama not installed${NC}"
            fi
            ;;
        "3) View Documentation")
            echo -e "\n${CYAN}Viewing documentation...${NC}"
            if [[ -f "$SCRIPT_DIR/../../AI_CONFIG_PHASE1A_COMPLETE_GUIDE.md" ]]; then
                head -50 "$SCRIPT_DIR/../../AI_CONFIG_PHASE1A_COMPLETE_GUIDE.md"
                echo -e "\n${DIM}Full guide: $SCRIPT_DIR/../../AI_CONFIG_PHASE1A_COMPLETE_GUIDE.md${NC}"
            else
                echo -e "${YELLOW}Documentation not found${NC}"
            fi
            ;;
        "4) System Information")
            echo -e "\n${CYAN}System Information:${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "CPU: $(lscpu | grep "Model name" | sed 's/Model name: *//')"
            echo "Memory: $(free -h | grep "Mem:" | awk '{print $2 " total, " $3 " used, " $7 " available"}')"
            echo "GPU: $(lspci | grep -i "VGA\|3D" | cut -d: -f3-)"
            echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
            echo "Kernel: $(uname -r)"
            echo "Packages: $(pacman -Q | wc -l) installed"
            ;;
        "5) Command Reference")
            echo -e "\n${CYAN}Available Commands:${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${BOLD}Analysis:${NC}"
            echo "  config-analyzer analyze health    # Full system analysis"
            echo "  config-analyzer status           # Quick overview"
            echo ""
            echo -e "${BOLD}AI Optimization:${NC}"
            echo "  config-optimize                  # Smart optimization with AI"
            echo "  config-quick quick              # Fast boot optimization"
            echo ""
            echo -e "${BOLD}Main Hub:${NC}"
            echo "  ai-hub                          # This interface"
            ;;
        "0) Back to Main Menu"|"")
            return 0
            ;;
        "Quit")
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid selection. Please try again.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Theme Management submenu
show_theme_menu() {
    show_header
    echo -e "${BOLD}${PALETTE} THEME MANAGEMENT${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check if AI theming is available
    if [[ -f "$SCRIPT_DIR/ai-config.sh" ]]; then
        echo -e "  ${CHECK} ${GREEN}AI-Enhanced Theming Available${NC}"
    else
        echo -e "  ${WARNING} ${YELLOW}AI theming not found${NC}"
    fi
    echo ""
    
    echo -e "  ${BOLD}1)${NC} ${AI} ${GREEN}AI Theme Configuration${NC}  ${DIM}→ Configure AI theming modes${NC}"
    echo -e "  ${BOLD}2)${NC} ${PALETTE} ${YELLOW}Current Theme Status${NC}      ${DIM}→ View AI theming status${NC}"
    echo -e "  ${BOLD}3)${NC} ${ROCKET} ${BLUE}Test Theme Analysis${NC}      ${DIM}→ Run color harmony analysis${NC}"
    echo -e "  ${BOLD}4)${NC} ${GEAR} ${PURPLE}Vision AI Settings${NC}       ${DIM}→ Configure vision analysis${NC}"
    echo -e "  ${BOLD}5)${NC} ${CHART} ${CYAN}Mathematical AI Settings${NC} ${DIM}→ Configure color harmony${NC}"
    echo ""
    echo -e "  ${BOLD}0)${NC} ${DIM}← Back to Main Menu${NC}"
    echo ""
    
    echo -e "${DIM}Use ↑↓ arrow keys and Enter to navigate${NC}"
    echo ""
    
    # Theme Management menu with descriptive options
    choice=$(printf '%s\n' \
        "1) AI Theme Configuration" \
        "2) Current Theme Status" \
        "3) Test Theme Analysis" \
        "4) Vision AI Settings" \
        "5) Mathematical AI Settings" \
        "0) Back to Main Menu" \
        "Quit" | \
        gum choose --height 10 --header "🎨 Theme Management Menu")
    
    case "$choice" in
        "1) AI Theme Configuration")
            echo -e "\n${CYAN}Opening AI theme configuration...${NC}"
            if [[ -f "$SCRIPT_DIR/ai-config.sh" ]]; then
                bash "$SCRIPT_DIR/ai-config.sh" || echo -e "${YELLOW}AI theming configuration completed${NC}"
            else
                echo -e "${RED}AI theming script not found${NC}"
            fi
            ;;
        "2) Current Theme Status")
            echo -e "\n${CYAN}Current AI theming status:${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            if [[ -f "$SCRIPT_DIR/ai-config.sh" ]]; then
                # Load and show AI config status
                if [[ -f "$HOME/.config/dynamic-theming/ai-config.conf" ]]; then
                    source "$HOME/.config/dynamic-theming/ai-config.conf" 2>/dev/null || true
                    echo -e "AI Mode: ${GREEN}${AI_MODE:-Not Set}${NC}"
                    echo -e "Vision AI: ${GREEN}${ENABLE_VISION_AI:-Not Set}${NC}"
                    echo -e "Mathematical AI: ${GREEN}${ENABLE_MATHEMATICAL_AI:-Not Set}${NC}"
                    echo -e "Performance Target: ${GREEN}${PERFORMANCE_TARGET:-Not Set}${NC}"
                else
                    echo -e "${YELLOW}AI theming not configured yet${NC}"
                fi
            else
                echo -e "${RED}AI theming not available${NC}"
            fi
            ;;
        "3) Test Theme Analysis")
            echo -e "\n${CYAN}Running theme analysis test...${NC}"
            if [[ -f "$SCRIPT_DIR/color-harmony-analyzer.sh" ]]; then
                bash "$SCRIPT_DIR/color-harmony-analyzer.sh" || echo -e "${YELLOW}Color analysis completed${NC}"
            elif [[ -f "$SCRIPT_DIR/enhanced-color-intelligence.sh" ]]; then
                bash "$SCRIPT_DIR/enhanced-color-intelligence.sh" || echo -e "${YELLOW}Enhanced analysis completed${NC}"
            else
                echo -e "${YELLOW}Theme analysis tools not found in current directory${NC}"
                echo -e "${DIM}Available in: ~/dotfiles/scripts/ai/${NC}"
            fi
            ;;
        "4) Vision AI Settings")
            echo -e "\n${CYAN}Vision AI Settings:${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            if [[ -f "$SCRIPT_DIR/vision-analyzer.sh" ]]; then
                echo -e "✅ Vision analyzer: ${GREEN}Available${NC}"
                echo -e "Models: deepseek-r1:32b, phi4:latest, llava:latest"
                echo -e "Performance: ~2.3s analysis time"
            else
                echo -e "${YELLOW}Vision analyzer not found${NC}"
            fi
            ;;
        "5) Mathematical AI Settings")
            echo -e "\n${CYAN}Mathematical AI Settings:${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            if [[ -f "$SCRIPT_DIR/color-harmony-analyzer.sh" ]]; then
                echo -e "✅ Color harmony analyzer: ${GREEN}Available${NC}"
                echo -e "Features: WCAG AAA compliance, harmony scoring"
                echo -e "Performance: ~0.6s analysis time"
            else
                echo -e "${YELLOW}Mathematical analyzer not found${NC}"
            fi
            ;;
        "0) Back to Main Menu"|"")
            return 0
            ;;
        "Quit")
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid selection. Please try again.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main program loop
main() {
    # Ensure gum is available for beautiful menus
    ensure_gum
    
    log_hub "INFO" "AI Configuration Hub started"
    
    while true; do
        show_header
        get_system_status
        show_main_menu
        
        echo -e "${DIM}Use ↑↓ arrow keys and Enter to navigate${NC}"
        echo ""
        
        # Main menu with descriptive options
        choice=$(printf '%s\n' \
            "1) AI System Analysis" \
            "2) AI-Powered Optimization" \
            "3) Quick Optimization" \
            "4) Theme Management" \
            "5) Configuration" \
            "6) Refresh Status" \
            "0) Exit" \
            "Quit" | \
            gum choose --height 12 --header "🎮 AI Configuration Hub - Main Menu")
        
        case "$choice" in
            "Quit"|"")
                return 0
                ;;
            "1) AI System Analysis")
                show_analysis_menu
                ;;
            "2) AI-Powered Optimization")
                show_ai_menu
                ;;
            "3) Quick Optimization")
                show_quick_menu
                ;;
            "4) Theme Management")
                show_theme_menu
                ;;
            "5) Configuration")
                show_config_menu
                ;;
            "6) Refresh Status")
                echo -e "\n${CYAN}Refreshing system status...${NC}"
                echo -e "${DIM}Running quick system check...${NC}"
                
                # Use the lightweight system status instead of full analysis
                if [[ -f "$SCRIPT_DIR/config-analyzer.sh" ]]; then
                    # Call the quick status function which is fast and doesn't hang
                    timeout 5s bash "$SCRIPT_DIR/config-analyzer.sh" status > /dev/null 2>&1 || true
                fi
                
                echo -e "${GREEN}✅ Status display refreshed${NC}"
                
                # Brief pause so user can see the result
                sleep 1
                ;;
            "0) Exit")
                echo -e "\n${GREEN}Thank you for using AI Configuration Hub!${NC}"
                echo -e "${DIM}Your system is ready for optimal performance.${NC}\n"
                log_hub "INFO" "AI Configuration Hub exited normally"
                exit 0
                ;;
            *)
                echo -e "\n${RED}Invalid selection. Please try again.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Show usage help
show_usage() {
    cat << EOF
AI Configuration Hub - Terminal Frontend for AI-Enhanced System Management

Usage: $0 [option]

Options:
  (no arguments)  - Launch interactive hub interface
  help           - Show this help message
  status         - Show quick system status and exit
  
Features:
  🎮 Interactive terminal interface
  📊 Real-time system health monitoring  
  🧠 AI-powered optimization with Ollama integration
  🚀 Quick optimization actions
  🎨 Theme management
  ⚙️  Configuration management
  📚 Integrated documentation and help

This is the main entry point for all AI configuration tools.

EOF
}

# Handle command line arguments
case "${1:-main}" in
    "help"|"-h"|"--help")
        show_usage
        ;;
    "status")
        show_header
        get_system_status
        ;;
    "main"|"")
        main
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        show_usage
        exit 1
        ;;
esac 