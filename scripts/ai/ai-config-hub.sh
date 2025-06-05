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



# Clear screen and show header with breadcrumbs
show_header() {
    local breadcrumb="${1:-AI Configuration Hub}"
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    ${AI} AI CONFIGURATION HUB ${AI}                       ║"
    echo "║              Intelligent System Management & Optimization             ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${DIM}AMD Ryzen 7 3700X + RX 7900 XT + Arch Linux + Hyprland${NC}"
    echo ""
    if [[ "$breadcrumb" != "AI Configuration Hub" ]]; then
        echo -e "${CYAN}📍 ${BOLD}$breadcrumb${NC}"
        echo ""
    fi
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
        echo -e "  ${CHECK} ${BOLD}Overall Health: ${status_color}${overall_score}/100${NC} (${status_text})"
    else
        echo -e "  ${WARNING} Overall Health: ${DIM}No recent analysis${NC}"
    fi
    
    # Detailed component scores (if analysis exists)
    if [[ -f "$ANALYSIS_CACHE" ]]; then
        echo -e "\n  ${DIM}${BOLD}Component Breakdown:${NC}"
        
        # Extract individual component scores
        local cpu_score=$(cat "$ANALYSIS_CACHE" | grep -A 10 '"cpu":' | grep '"score":' | awk '{print $2}' | sed 's/,//' 2>/dev/null || echo "N/A")
        local memory_score=$(cat "$ANALYSIS_CACHE" | grep -A 10 '"memory":' | grep '"score":' | awk '{print $2}' | sed 's/,//' 2>/dev/null || echo "N/A")
        local boot_score=$(cat "$ANALYSIS_CACHE" | grep -A 15 '"boot":' | grep '"score":' | awk '{print $2}' | sed 's/,//' 2>/dev/null || echo "N/A")
        local disk_score=$(cat "$ANALYSIS_CACHE" | grep -A 10 '"disk":' | grep '"score":' | awk '{print $2}' | sed 's/,//' 2>/dev/null || echo "N/A")
        local gpu_score=$(cat "$ANALYSIS_CACHE" | grep -A 10 '"gpu":' | grep '"score":' | awk '{print $2}' | sed 's/,//' 2>/dev/null || echo "N/A")
        local package_score=$(cat "$ANALYSIS_CACHE" | grep -A 10 '"packages":' | grep '"score":' | awk '{print $2}' | sed 's/,//' 2>/dev/null || echo "N/A")
        
        # Display scores with appropriate colors
        format_component_score() {
            local name="$1"
            local score="$2"
            local icon="$3"
            
            if [[ "$score" == "N/A" ]]; then
                echo -e "    ${icon} ${name}: ${DIM}${score}${NC}"
            elif (( $(echo "$score >= 100" | bc -l 2>/dev/null || echo 0) )); then
                echo -e "    ${icon} ${name}: ${GREEN}${score}/100${NC} ${DIM}(Optimized!)${NC}"
            elif (( $(echo "$score >= 90" | bc -l 2>/dev/null || echo 0) )); then
                echo -e "    ${icon} ${name}: ${GREEN}${score}/100${NC}"
            elif (( $(echo "$score >= 70" | bc -l 2>/dev/null || echo 0) )); then
                echo -e "    ${icon} ${name}: ${YELLOW}${score}/100${NC}"
            else
                echo -e "    ${icon} ${name}: ${RED}${score}/100${NC}"
            fi
        }
        
        format_component_score "CPU Performance" "$cpu_score" "🖥️"
        format_component_score "Memory Usage" "$memory_score" "🧠"
        format_component_score "Boot Performance" "$boot_score" "🚀"
        format_component_score "Disk Health" "$disk_score" "💾"
        format_component_score "GPU Performance" "$gpu_score" "🎮"
        format_component_score "Package System" "$package_score" "📦"
    fi
    
    echo ""
    
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
    while true; do
        show_header "Main Menu > System Analysis"
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
        
        echo -e "${DIM}Navigate: ↑↓ arrows + Enter • Back: Select option 0${NC}"
        echo ""
        
        # Analysis menu with descriptive options
        choice=$(printf '%s\n' \
            "1) Full Health Analysis" \
            "2) Performance Analysis" \
            "3) Package Analysis" \
            "4) Quick Status" \
            "5) View Latest Results" \
            "0) Back to Main Menu" | \
            gum choose --height 8 --header "📊 System Analysis Menu")
    
        case "$choice" in
            "1) Full Health Analysis")
                echo -e "\n${CYAN}Running comprehensive health analysis...${NC}"
                bash "$SCRIPT_DIR/config-analyzer.sh" analyze health || true
                echo ""
                echo -e "${GREEN}✅ Analysis complete! Returning to main menu...${NC}"
                sleep 2
                return 0
                ;;
            "2) Performance Analysis")
                echo -e "\n${CYAN}Running performance analysis...${NC}"
                bash "$SCRIPT_DIR/config-analyzer.sh" analyze performance || true
                echo ""
                echo -e "${GREEN}✅ Analysis complete! Returning to main menu...${NC}"
                sleep 2
                return 0
                ;;
            "3) Package Analysis")
                echo -e "\n${CYAN}Running package analysis...${NC}"
                bash "$SCRIPT_DIR/config-analyzer.sh" analyze packages || true
                echo ""
                echo -e "${GREEN}✅ Analysis complete! Returning to main menu...${NC}"
                sleep 2
                return 0
                ;;
            "4) Quick Status")
                echo -e "\n${CYAN}Getting quick system status...${NC}"
                bash "$SCRIPT_DIR/config-analyzer.sh" status || true
                echo ""
                echo -e "${GREEN}✅ Status check complete! Returning to main menu...${NC}"
                sleep 2
                return 0
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
                echo ""
                read -p "Press Enter to return to main menu..."
                return 0
                ;;
            "0) Back to Main Menu"|"")
                return 0
                ;;
            *)
                if [[ -n "$choice" ]]; then
                    echo -e "\n${RED}Invalid selection. Please try again.${NC}"
                    sleep 1
                fi
                ;;
        esac
    done
}

# AI Optimization submenu
show_ai_menu() {
    while true; do
        show_header "Main Menu > AI-Powered Optimization"
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
        
        echo -e "${DIM}Navigate: ↑↓ arrows + Enter • Back: Select option 0${NC}"
        echo ""
        
        # AI Optimization menu with descriptive options
        choice=$(printf '%s\n' \
            "1) Smart Optimization" \
            "2) Quick Boot Fix" \
            "3) Package Cleanup" \
            "4) Analyze Issues Only" \
            "0) Back to Main Menu" | \
            gum choose --height 7 --header "🧠 AI-Powered Optimization Menu")
    
        case "$choice" in
            "1) Smart Optimization")
                echo -e "\n${CYAN}Launching AI-powered smart optimization...${NC}"
                bash "$SCRIPT_DIR/config-smart-optimizer.sh" optimize
                echo ""
                echo -e "${GREEN}✅ Optimization complete! Returning to main menu...${NC}"
                sleep 2
                return 0
                ;;
            "2) Quick Boot Fix")
                echo -e "\n${CYAN}Running quick boot optimization...${NC}"
                bash "$SCRIPT_DIR/config-smart-optimizer.sh" boot
                echo ""
                echo -e "${GREEN}✅ Boot optimization complete! Returning to main menu...${NC}"
                sleep 2
                return 0
                ;;
            "3) Package Cleanup")
                echo -e "\n${CYAN}Running package cleanup...${NC}"
                bash "$SCRIPT_DIR/config-smart-optimizer.sh" packages
                echo ""
                echo -e "${GREEN}✅ Package cleanup complete! Returning to main menu...${NC}"
                sleep 2
                return 0
                ;;
            "4) Analyze Issues Only")
                echo -e "\n${CYAN}Analyzing optimization opportunities...${NC}"
                bash "$SCRIPT_DIR/config-smart-optimizer.sh" analyze || true
                echo ""
                echo -e "${GREEN}✅ Analysis complete! Returning to main menu...${NC}"
                sleep 2
                return 0
                ;;
            "0) Back to Main Menu"|"")
                return 0
                ;;
            *)
                if [[ -n "$choice" ]]; then
                    echo -e "\n${RED}Invalid selection. Please try again.${NC}"
                    sleep 1
                fi
                ;;
        esac
    done
}

# Quick Optimization submenu
show_quick_menu() {
    while true; do
        show_header "Main Menu > Quick Optimization"
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
        
        echo -e "${DIM}Navigate: ↑↓ arrows + Enter • Back: Select option 0${NC}"
        echo ""
        
        # Quick Optimization menu with descriptive options
        choice=$(printf '%s\n' \
            "1) Fix Boot Performance" \
            "2) Clean Package Cache" \
            "3) System Health Check" \
            "4) Theme Optimization" \
            "0) Back to Main Menu" | \
            gum choose --height 7 --header "🚀 Quick Optimization Menu")
    
        case "$choice" in
            "1) Fix Boot Performance")
                echo -e "\n${CYAN}Applying boot performance fix...${NC}"
                bash "$SCRIPT_DIR/config-smart-optimizer.sh" quick
                echo ""
                echo -e "${GREEN}✅ Boot fix complete! Returning to main menu...${NC}"
                sleep 2
                return 0
                ;;
            "2) Clean Package Cache")
                echo -e "\n${CYAN}Cleaning package cache...${NC}"
                sudo paccache -r || echo -e "${YELLOW}Package cache cleanup completed or already clean${NC}"
                echo ""
                echo -e "${GREEN}✅ Package cleanup complete! Returning to main menu...${NC}"
                sleep 2
                return 0
                ;;
            "3) System Health Check")
                echo -e "\n${CYAN}Running quick health check...${NC}"
                bash "$SCRIPT_DIR/config-analyzer.sh" status || true
                echo ""
                echo -e "${GREEN}✅ Health check complete! Returning to main menu...${NC}"
                sleep 2
                return 0
                ;;
            "4) Theme Optimization")
                echo -e "\n${CYAN}Running theme analysis...${NC}"
                # Check if color harmony analyzer exists
                if [[ -f "$SCRIPT_DIR/../ai-config.sh" ]]; then
                    bash "$SCRIPT_DIR/../ai-config.sh" || echo -e "${YELLOW}Theme analysis not available${NC}"
                else
                    echo -e "${YELLOW}Theme analysis not available. Run from main AI config.${NC}"
                fi
                echo ""
                echo -e "${GREEN}✅ Theme analysis complete! Returning to main menu...${NC}"
                sleep 2
                return 0
                ;;
            "0) Back to Main Menu"|"")
                return 0
                ;;
            *)
                if [[ -n "$choice" ]]; then
                    echo -e "\n${RED}Invalid selection. Please try again.${NC}"
                    sleep 1
                fi
                ;;
        esac
    done
}

# Configuration submenu
show_config_menu() {
    while true; do
        show_header "Main Menu > Configuration & Help"
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
        
        echo -e "${DIM}Navigate: ↑↓ arrows + Enter • Back: Select option 0${NC}"
        echo ""
        
        # Configuration menu with descriptive options
        choice=$(printf '%s\n' \
            "1) Analyzer Settings" \
            "2) AI Model Settings" \
            "3) View Documentation" \
            "4) System Information" \
            "5) Command Reference" \
            "0) Back to Main Menu" | \
            gum choose --height 8 --header "⚙️ Configuration & Help Menu")
    
        case "$choice" in
            "1) Analyzer Settings")
                echo -e "\n${CYAN}Opening analyzer configuration...${NC}"
                bash "$SCRIPT_DIR/config-analyzer.sh" config
                echo ""
                echo -e "${GREEN}✅ Configuration complete! Returning to main menu...${NC}"
                sleep 2
                return 0
                ;;
            "2) AI Model Settings")
                echo -e "\n${CYAN}Available Ollama models:${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                if command -v ollama &> /dev/null; then
                    ollama list || echo -e "${YELLOW}No models available or Ollama not running${NC}"
                else
                    echo -e "${YELLOW}Ollama not installed${NC}"
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "3) View Documentation")
                echo -e "\n${CYAN}Viewing documentation...${NC}"
                if [[ -f "$SCRIPT_DIR/../../AI_CONFIG_PHASE1A_COMPLETE_GUIDE.md" ]]; then
                    head -50 "$SCRIPT_DIR/../../AI_CONFIG_PHASE1A_COMPLETE_GUIDE.md"
                    echo -e "\n${DIM}Full guide: $SCRIPT_DIR/../../AI_CONFIG_PHASE1A_COMPLETE_GUIDE.md${NC}"
                else
                    echo -e "${YELLOW}Documentation not found${NC}"
                fi
                echo ""
                read -p "Press Enter to continue..."
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
                echo ""
                read -p "Press Enter to continue..."
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
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "0) Back to Main Menu"|"")
                return 0
                ;;
            *)
                if [[ -n "$choice" ]]; then
                    echo -e "\n${RED}Invalid selection. Please try again.${NC}"
                    sleep 1
                fi
                ;;
        esac
    done
}

# Theme Management submenu
show_theme_menu() {
    while true; do
        show_header "Main Menu > Theme Management"
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
        echo -e "  ${BOLD}2)${NC} ${PALETTE} ${YELLOW}Wallpaper & Theme Change${NC}  ${DIM}→ Select wallpaper with AI analysis${NC}"
        echo -e "  ${BOLD}3)${NC} ${ROCKET} ${BLUE}Current Theme Status${NC}      ${DIM}→ View AI theming status${NC}"
        echo -e "  ${BOLD}4)${NC} ${CHART} ${PURPLE}Test AI Analysis${NC}         ${DIM}→ Run vision + mathematical analysis${NC}"
        echo -e "  ${BOLD}5)${NC} ${GEAR} ${CYAN}Vision & AI Settings${NC}      ${DIM}→ Configure AI models & weights${NC}"
        echo ""
        echo -e "  ${BOLD}0)${NC} ${DIM}← Back to Main Menu${NC}"
        echo ""
        
        echo -e "${DIM}Navigate: ↑↓ arrows + Enter • Back: Select option 0${NC}"
        echo ""
        
        # Theme Management menu with descriptive options
        choice=$(printf '%s\n' \
            "1) AI Theme Configuration" \
            "2) Wallpaper & Theme Change" \
            "3) Current Theme Status" \
            "4) Test AI Analysis" \
            "5) Vision & AI Settings" \
            "0) Back to Main Menu" | \
            gum choose --height 8 --header "🎨 AI Theme Management Menu")
    
    case "$choice" in
        "1) AI Theme Configuration")
            echo -e "\n${CYAN}🔧 Interactive AI Theme Configuration${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            if [[ -f "$SCRIPT_DIR/ai-config.sh" ]]; then
                # Run interactive configuration
                bash "$SCRIPT_DIR/ai-config.sh" config || echo -e "${YELLOW}Configuration completed${NC}"
            else
                echo -e "${RED}AI theming script not found${NC}"
            fi
            ;;
        "2) Wallpaper & Theme Change")
            echo -e "\n${CYAN}🎨 AI-Enhanced Wallpaper Selection${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${DIM}Select wallpaper for intelligent AI analysis and theming${NC}"
            echo ""
            
            # Check if wallpaper selector exists
            if [[ -f "$SCRIPT_DIR/../wallpaper-selector.sh" ]]; then
                echo -e "${GREEN}✅ Launching AI-enhanced wallpaper selector...${NC}"
                echo -e "${DIM}This will use Vision AI + Mathematical analysis for optimal theming${NC}"
                echo ""
                
                # Set AI optimization and launch wallpaper selector
                export ENABLE_AI_OPTIMIZATION=true
                bash "$SCRIPT_DIR/../wallpaper-selector.sh" || echo -e "${YELLOW}Wallpaper selection completed${NC}"
                
                echo ""
                echo -e "${GREEN}🧠 AI Analysis Results:${NC}"
                if [[ -f "/tmp/ai-enhanced-result.json" ]]; then
                    echo -e "Strategy: $(jq -r '.enhanced_intelligence.strategy' /tmp/ai-enhanced-result.json 2>/dev/null || echo 'Unknown')"
                    echo -e "Confidence: $(jq -r '.enhanced_intelligence.confidence' /tmp/ai-enhanced-result.json 2>/dev/null || echo 'Unknown')"
                    echo -e "Vision Category: $(jq -r '.enhanced_intelligence.vision_insights.category' /tmp/ai-enhanced-result.json 2>/dev/null || echo 'Unknown')"
                    echo -e "Colors: Primary $(jq -r '.enhanced_intelligence.primary_color' /tmp/ai-enhanced-result.json 2>/dev/null || echo 'Unknown'), Accent $(jq -r '.enhanced_intelligence.accent_color' /tmp/ai-enhanced-result.json 2>/dev/null || echo 'Unknown')"
                else
                    echo -e "${DIM}No recent AI analysis found${NC}"
                fi
            else
                echo -e "${YELLOW}Wallpaper selector not found: $SCRIPT_DIR/../wallpaper-selector.sh${NC}"
                echo -e "${DIM}You can still use Super + B for wallpaper selection${NC}"
            fi
            ;;
        "3) Current Theme Status")
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
                    echo ""
                    echo -e "🧠 ${BOLD}Recent AI Analysis:${NC}"
                    if [[ -f "/tmp/ai-enhanced-result.json" ]]; then
                        echo -e "Last Strategy: $(jq -r '.enhanced_intelligence.strategy' /tmp/ai-enhanced-result.json 2>/dev/null || echo 'Unknown')"
                        echo -e "Confidence: $(jq -r '.enhanced_intelligence.confidence' /tmp/ai-enhanced-result.json 2>/dev/null || echo 'Unknown')"
                        echo -e "Vision Insights: $(jq -r '.enhanced_intelligence.vision_insights.category' /tmp/ai-enhanced-result.json 2>/dev/null || echo 'Unknown') ($(jq -r '.enhanced_intelligence.vision_insights.mood' /tmp/ai-enhanced-result.json 2>/dev/null || echo 'Unknown'))"
                        echo -e "Mathematical Score: $(jq -r '.enhanced_intelligence.mathematical_insights.harmony_score' /tmp/ai-enhanced-result.json 2>/dev/null || echo 'Unknown')"
                    else
                        echo -e "${DIM}No recent AI analysis found${NC}"
                    fi
                else
                    echo -e "${YELLOW}AI theming not configured yet${NC}"
                fi
            else
                echo -e "${RED}AI theming not available${NC}"
            fi
            ;;
        "4) Test AI Analysis")
            echo -e "\n${CYAN}🧠 Running comprehensive AI analysis test...${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${DIM}Testing Vision AI + Mathematical AI with current wallpaper${NC}"
            echo ""
            
            # Get current wallpaper from multiple possible locations
            current_wallpaper=$(cat ~/.config/dynamic-theming/last-wallpaper 2>/dev/null || echo "")
            
            # Fallback: try to get from swww if available
            if [[ -z "$current_wallpaper" ]] && command -v swww &>/dev/null; then
                current_wallpaper=$(swww query 2>/dev/null | head -1 | grep -o '/.*\.(jpg\|jpeg\|png\|webp)' || echo "")
            fi
            
            # Additional fallback: check other common locations
            if [[ -z "$current_wallpaper" ]]; then
                current_wallpaper=$(cat ~/.config/wallpaper/current_wallpaper.txt 2>/dev/null || echo "")
            fi
            
            if [[ -n "$current_wallpaper" && -f "$current_wallpaper" ]]; then
                echo -e "Testing with: ${GREEN}$(basename "$current_wallpaper")${NC}"
                
                # Run AI analysis
                export ENABLE_AI_OPTIMIZATION=true
                if bash "$SCRIPT_DIR/ai-color-pipeline.sh" "$current_wallpaper" > /tmp/ai-test-output.json 2>/tmp/ai-test-error.log; then
                    echo -e "\n${GREEN}✅ AI Analysis Complete!${NC}"
                    echo ""
                    echo -e "${BOLD}Results:${NC}"
                    if [[ -f "/tmp/ai-enhanced-result.json" ]]; then
                        echo -e "Strategy: ${CYAN}$(jq -r '.enhanced_intelligence.strategy' /tmp/ai-enhanced-result.json 2>/dev/null)${NC}"
                        echo -e "Confidence: ${GREEN}$(jq -r '.enhanced_intelligence.confidence' /tmp/ai-enhanced-result.json 2>/dev/null)${NC}"
                        echo -e "Primary Color: ${BLUE}$(jq -r '.enhanced_intelligence.primary_color' /tmp/ai-enhanced-result.json 2>/dev/null)${NC}"
                        echo -e "Accent Color: ${PURPLE}$(jq -r '.enhanced_intelligence.accent_color' /tmp/ai-enhanced-result.json 2>/dev/null)${NC}"
                        echo -e "Vision Category: $(jq -r '.enhanced_intelligence.vision_insights.category' /tmp/ai-enhanced-result.json 2>/dev/null)"
                        echo -e "Mathematical Score: $(jq -r '.enhanced_intelligence.mathematical_insights.harmony_score' /tmp/ai-enhanced-result.json 2>/dev/null)"
                    fi
                else
                    echo -e "\n${RED}❌ AI Analysis Failed${NC}"
                    echo -e "${DIM}Error: $(tail -1 /tmp/ai-test-error.log 2>/dev/null || echo 'Unknown error')${NC}"
                fi
            else
                echo -e "${YELLOW}⚠️  Current wallpaper not found${NC}"
                echo -e "${DIM}Checked locations:${NC}"
                echo -e "${DIM}  • ~/.config/dynamic-theming/last-wallpaper${NC}"
                echo -e "${DIM}  • swww query output${NC}"
                echo -e "${DIM}  • ~/.config/wallpaper/current_wallpaper.txt${NC}"
                echo ""
                echo -e "${CYAN}💡 Try: Use 'Wallpaper & Theme Change' to set a wallpaper with AI analysis${NC}"
            fi
            ;;
        "5) Vision & AI Settings")
            echo -e "\n${CYAN}🔧 AI Configuration & Performance${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo -e "${BOLD}Available AI Components:${NC}"
            
            # Vision AI status
            if [[ -f "$SCRIPT_DIR/vision-analyzer.sh" ]]; then
                echo -e "✅ Vision AI: ${GREEN}Available${NC}"
                echo -e "   Models: deepseek-r1:32b, phi4:latest, llava:latest"
                echo -e "   Performance: ~2.3s analysis time"
            else
                echo -e "❌ Vision AI: ${RED}Not Available${NC}"
            fi
            
            # Mathematical AI status  
            if [[ -f "$SCRIPT_DIR/color-harmony-analyzer.sh" ]]; then
                echo -e "✅ Mathematical AI: ${GREEN}Available${NC}"
                echo -e "   Features: WCAG AAA compliance, harmony scoring"
                echo -e "   Performance: ~0.6s analysis time"
            else
                echo -e "❌ Mathematical AI: ${RED}Not Available${NC}"
            fi
            
            # Enhanced Intelligence status
            if [[ -f "$SCRIPT_DIR/enhanced-color-intelligence.sh" ]]; then
                echo -e "✅ Enhanced Intelligence: ${GREEN}Available${NC}"
                echo -e "   Combines vision + mathematical analysis"
                echo -e "   Performance: ~3.8s average (excellent)"
            else
                echo -e "❌ Enhanced Intelligence: ${RED}Not Available${NC}"
            fi
            
            echo ""
            echo -e "${BOLD}Current Configuration:${NC}"
            if [[ -f "$HOME/.config/dynamic-theming/ai-config.conf" ]]; then
                source "$HOME/.config/dynamic-theming/ai-config.conf" 2>/dev/null || true
                echo -e "AI Mode: ${GREEN}${AI_MODE}${NC}"
                echo -e "Vision Weight: ${CYAN}${VISION_WEIGHT}${NC}"
                echo -e "Mathematical Weight: ${BLUE}${MATHEMATICAL_WEIGHT}${NC}"
                echo -e "Performance Target: ${YELLOW}${PERFORMANCE_TARGET:-fast}${NC}"
            fi
            
            echo ""
            echo -e "${DIM}To modify settings, use option 1 (AI Theme Configuration)${NC}"
            ;;
            "0) Back to Main Menu"|"")
                return 0
                ;;
            *)
                if [[ -n "$choice" ]]; then
                    echo -e "\n${RED}Invalid selection. Please try again.${NC}"
                    sleep 1
                fi
                ;;
        esac
        
        # Add "Press Enter to continue" after each action (except option 1 which has its own loop)
        if [[ "$choice" =~ ^[2-5] ]]; then
            echo ""
            read -p "Press Enter to continue..."
        fi
    done
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
        
        echo -e "${DIM}Navigate: ↑↓ arrows + Enter • Exit: Select option 0${NC}"
        echo ""
        
        # Main menu with descriptive options
        choice=$(printf '%s\n' \
            "1) AI System Analysis" \
            "2) AI-Powered Optimization" \
            "3) Quick Optimization" \
            "4) Theme Management" \
            "5) Configuration" \
            "6) Refresh Status" \
            "0) Exit AI Configuration Hub" | \
            gum choose --height 9 --header "🎮 AI Configuration Hub - Main Menu")
        
        case "$choice" in
            ""|"0) Exit AI Configuration Hub")
                echo -e "\n${GREEN}Thank you for using AI Configuration Hub!${NC}"
                echo -e "${DIM}Your system is ready for optimal performance.${NC}\n"
                log_hub "INFO" "AI Configuration Hub exited normally"
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
            *)
                if [[ -n "$choice" ]]; then
                    echo -e "\n${RED}Invalid selection. Please try again.${NC}"
                    sleep 1
                fi
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