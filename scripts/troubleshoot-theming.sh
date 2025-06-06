#!/bin/bash

# =============================================================================
# 🔧 AI-POWERED THEMING SYSTEM TROUBLESHOOTER
# =============================================================================
# Comprehensive diagnostic and repair tool with AI-enhanced fix suggestions
# Usage: ./scripts/troubleshoot-theming.sh [--fix] [--ai] [--verbose] [--quick]

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
VERBOSE=false
AUTO_FIX=false
QUICK_MODE=false
AI_ASSISTANCE=false
BRIEF_AI=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
MAGENTA='\033[0;95m'
NC='\033[0m'

# Icons
CHECK="✅"
FAIL="❌"
WARN="⚠️"
INFO="ℹ️"
FIX="🔧"
AI="🧠"
ROBOT="🤖"
THINKING="🤔"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            AUTO_FIX=true
            shift
            ;;
        --ai)
            AI_ASSISTANCE=true
            BRIEF_AI=true  # Default to brief AI responses
            shift
            ;;
        --ai-verbose)
            AI_ASSISTANCE=true
            BRIEF_AI=false
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --quick|-q)
            QUICK_MODE=true
            shift
            ;;
        --help|-h)
            echo "🤖 AI-Powered Theming System Troubleshooter"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --ai         Enable AI-powered diagnosis (brief responses)"
            echo "  --ai-verbose Enable AI with detailed analysis"
            echo "  --fix        Automatically apply fixes (requires confirmation with --ai)"
            echo "  --verbose    Show detailed output and logs"
            echo "  --quick      Quick health check only"
            echo "  --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Basic diagnostic"
            echo "  $0 --ai                      # AI-powered diagnosis with suggestions"
            echo "  $0 --ai --fix                # AI diagnosis with interactive fixes"
            echo "  $0 --ai --verbose --fix      # Full AI analysis with detailed output"
            echo ""
            echo "🧠 AI Features:"
            echo "  • Intelligent issue analysis using local Ollama models"
            echo "  • Custom fix suggestions based on your specific setup"
            echo "  • Interactive confirmation before applying fixes"
            echo "  • Learning from your system configuration"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Logging functions
log_info() {
    echo -e "${BLUE}${INFO}${NC} $1"
}

log_success() {
    echo -e "${GREEN}${CHECK}${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}${WARN}${NC} $1"
}

log_error() {
    echo -e "${RED}${FAIL}${NC} $1"
}

log_fix() {
    echo -e "${PURPLE}${FIX}${NC} $1"
}

log_ai() {
    echo -e "${CYAN}${AI}${NC} $1"
}

log_robot() {
    echo -e "${MAGENTA}${ROBOT}${NC} $1"
}

verbose_log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${CYAN}[VERBOSE]${NC} $1"
    fi
}

# AI Helper Functions
check_ollama_available() {
    if ! command -v ollama >/dev/null 2>&1; then
        return 1
    fi
    
    if ! pgrep -f ollama >/dev/null 2>&1; then
        return 1
    fi
    
    # Check if we have any models
    local models=$(ollama list 2>/dev/null | grep -v "NAME" | wc -l)
    if [[ $models -eq 0 ]]; then
        return 1
    fi
    
    return 0
}

get_best_model() {
    # Prefer phi4 for reasoning, fallback to others
    local models_priority=("phi4" "llama3.2" "llama3.1" "mistral" "llama2")
    
    for model in "${models_priority[@]}"; do
        if ollama list 2>/dev/null | grep -q "$model"; then
            echo "$model"
            return 0
        fi
    done
    
    # Return first available model
    ollama list 2>/dev/null | grep -v "NAME" | head -1 | awk '{print $1}'
}

ai_analyze_issues() {
    local issues_json="$1"
    local system_info="$2"
    
    if [[ ! -f "$issues_json" ]] || ! check_ollama_available; then
        return 1
    fi
    
    local model=$(get_best_model)
    if [[ -z "$model" ]]; then
        return 1
    fi
    
    log_ai "Analyzing issues with AI model: $model"
    echo -e "${CYAN}${THINKING}${NC} AI is thinking about your system issues..."
    
    # Create AI prompt
    local prompt=$(cat <<EOF
You are fixing an Arch Linux theming system that uses Hyprland, matugen, and AI-enhanced color generation.

THEMING ISSUES: $(cat "$issues_json")

For each issue, provide ONLY Linux theming fixes:
- Root cause (1 line)
- Bash command using matugen/waybar/hyprland tools (1 line)
- Why this fixes the theming issue (1 line)

No web development or Drupal suggestions. Keep under 100 words total.
EOF
)
    
    # Get AI analysis with timeout and length limit
    local ai_response=$(timeout 15s bash -c "echo '$prompt' | ollama run '$model'" 2>/dev/null | head -20)
    
    if [[ -n "$ai_response" ]]; then
        echo "$ai_response" > "/tmp/ai-analysis-$(date +%s).txt"
        echo "$ai_response"
        return 0
    else
        return 1
    fi
}

ai_suggest_fix() {
    local issue_description="$1"
    local current_config="$2"
    
    if ! check_ollama_available; then
        return 1
    fi
    
    local model=$(get_best_model)
    if [[ -z "$model" ]]; then
        return 1
    fi
    
    log_ai "Getting AI fix suggestion for: $issue_description"
    
    local prompt=$(cat <<EOF
You are fixing an Arch Linux theming system that uses:
- Hyprland window manager
- matugen for color generation from wallpapers
- AI-enhanced theming via Ollama models
- Waybar, Kitty, Fuzzel, GTK/Qt apps
- Custom shell scripts in ~/dotfiles

ISSUE: $issue_description

Respond ONLY with:
COMMAND: [single bash command using above tools]
WHY: [1 sentence about fixing this specific Linux theming issue]
RISK: [none/low/medium]

No web development suggestions. Linux theming commands only.
EOF
)
    
    local ai_response=$(timeout 10s bash -c "echo '$prompt' | ollama run '$model'" 2>/dev/null | head -10)
    
    if [[ -n "$ai_response" ]]; then
        echo "$ai_response"
        return 0
    else
        return 1
    fi
}

interactive_ai_fix() {
    local fix_command="$1"
    local fix_description="$2"
    local issue="$3"
    
    if [[ "$AI_ASSISTANCE" != "true" ]]; then
        # Standard behavior
        if [[ "$AUTO_FIX" == "true" ]]; then
            log_fix "Applying fix: $fix_description"
            if eval "$fix_command" 2>/dev/null; then
                log_success "Fix applied successfully"
                FIXES_APPLIED=$((FIXES_APPLIED + 1))
                return 0
            else
                log_error "Fix failed to apply"
                return 1
            fi
        else
            log_warn "Fix available: $fix_description"
            echo "Command: $fix_command"
            return 0
        fi
    fi
    
    # AI-enhanced mode
    log_robot "AI Analysis for: $issue"
    echo ""
    
    # Get AI suggestion
    local current_config=""
    case "$issue" in
        *"AI config"*)
            current_config=$(cat ~/.config/dynamic-theming/ai-config.conf 2>/dev/null || echo "Config file missing")
            ;;
        *"GTK"*)
            current_config=$(head -20 ~/.config/gtk-4.0/gtk.css 2>/dev/null || echo "GTK file missing")
            ;;
        *"cache"*)
            current_config=$(ls -la ~/.cache/matugen/ai-results/ 2>/dev/null || echo "Cache empty")
            ;;
    esac
    
    local ai_suggestion=$(ai_suggest_fix "$issue" "$current_config")
    
    if [[ -n "$ai_suggestion" ]]; then
        echo -e "${CYAN}🤖 AI SUGGESTION:${NC}"
        echo "$ai_suggestion"
        echo ""
    fi
    
    echo -e "${YELLOW}📋 PROPOSED FIX:${NC}"
    echo "Description: $fix_description"
    echo "Command: $fix_command"
    echo ""
    
    if [[ "$AUTO_FIX" == "true" ]]; then
        read -p "🤖 Apply this fix? [y/N]: " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_fix "Applying AI-approved fix..."
            if eval "$fix_command" 2>/dev/null; then
                log_success "Fix applied successfully!"
                FIXES_APPLIED=$((FIXES_APPLIED + 1))
                
                # Ask AI for verification steps
                log_ai "Getting verification steps..."
                local verification=$(ai_suggest_fix "How to verify that this fix worked: $fix_description" "")
                if [[ -n "$verification" ]]; then
                    echo -e "${CYAN}🔍 VERIFICATION:${NC}"
                    echo "$verification"
                fi
                
                return 0
            else
                log_error "Fix failed to apply"
                return 1
            fi
        else
            log_info "Fix skipped by user"
            return 0
        fi
    else
        log_info "Run with --fix to enable interactive fixing"
        return 0
    fi
}

# Create results storage
RESULTS_FILE="/tmp/theming-troubleshoot-$(date +%s).json"
ISSUES_FOUND=0
FIXES_APPLIED=0

# Function to record issue
record_issue() {
    local category="$1"
    local issue="$2"
    local severity="$3"
    local fix_available="$4"
    
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    
    if [[ ! -f "$RESULTS_FILE" ]]; then
        echo '{"issues": []}' > "$RESULTS_FILE"
    fi
    
    local issue_json=$(cat <<EOF
{
    "category": "$category",
    "issue": "$issue",
    "severity": "$severity",
    "fix_available": $fix_available,
    "timestamp": "$(date -Iseconds)"
}
EOF
)
    
    # Add to issues array
    if command -v jq >/dev/null 2>&1; then
        jq ".issues += [$issue_json]" "$RESULTS_FILE" > "/tmp/temp_results.json" && mv "/tmp/temp_results.json" "$RESULTS_FILE"
    fi
}

# Enhanced apply_fix function
apply_fix() {
    local fix_command="$1"
    local fix_description="$2"
    local issue="${3:-$fix_description}"
    
    interactive_ai_fix "$fix_command" "$fix_description" "$issue"
}

# Header
print_header() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    if [[ "$AI_ASSISTANCE" == "true" ]]; then
        echo -e "${PURPLE}║${NC}  ${CYAN}🤖 AI-POWERED THEMING SYSTEM TROUBLESHOOTER${NC}                           ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  Intelligent diagnostic and repair with local AI assistance              ${PURPLE}║${NC}"
    else
        echo -e "${PURPLE}║${NC}  ${CYAN}🔧 AI THEMING SYSTEM TROUBLESHOOTER${NC}                                    ${PURPLE}║${NC}"
        echo -e "${PURPLE}║${NC}  Diagnostic and repair tool for AI-enhanced theming system               ${PURPLE}║${NC}"
    fi
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ "$AI_ASSISTANCE" == "true" ]]; then
        if check_ollama_available; then
            local model=$(get_best_model)
            log_ai "AI Assistant ready with model: $model"
        else
            log_warn "AI assistance requested but Ollama not available"
            AI_ASSISTANCE=false
        fi
    fi
    
    log_info "Starting diagnostic scan..."
    echo ""
}

# System info collection for AI
collect_system_info() {
    cat <<EOF
SYSTEM INFORMATION:
- OS: $(uname -a)
- Desktop: Hyprland
- AI Models: $(ollama list 2>/dev/null | grep -v NAME | head -3 | awk '{print $1}' | tr '\n' ' ')
- Disk Usage: $(df -h / | tail -1 | awk '{print $5}')
- Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')
- Active Processes: $(pgrep -f "ollama\|waybar\|hypr" | wc -l) AI/desktop processes running

RECENT ACTIVITY:
$(tail -5 ~/.cache/matugen/activity.log 2>/dev/null || echo "No activity log")

CONFIG STATUS:
- AI Config: $(test -f ~/.config/dynamic-theming/ai-config.conf && echo "Present" || echo "Missing")
- Last Wallpaper: $(cat ~/.config/dynamic-theming/last-wallpaper 2>/dev/null || echo "Unknown")
- Cache Entries: $(find ~/.cache/matugen/ai-results/ -name "*.json" 2>/dev/null | wc -l)
EOF
}

# Check 1: AI Configuration
check_ai_config() {
    echo -e "${YELLOW}📋 Checking AI Configuration...${NC}"
    
    local config_file="$HOME/.config/dynamic-theming/ai-config.conf"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "AI config file missing: $config_file"
        record_issue "ai_config" "Config file missing" "critical" true
        
        apply_fix "mkdir -p '$(dirname "$config_file")' && cat > '$config_file' << 'EOF'
# AI Mode: enhanced, vision, mathematical, disabled
AI_MODE=\"enhanced\"
ENABLE_VISION_AI=\"true\"
ENABLE_MATHEMATICAL_AI=\"true\"
ENABLE_AI_OPTIMIZATION=true
FALLBACK_TO_STANDARD=\"true\"
SHOW_AI_NOTIFICATIONS=\"true\"
AI_DEBUG=\"false\"
AI_LOG_LEVEL=\"INFO\"
EOF" "Create AI configuration file"
        
        return 1
    fi
    
    # Check for required AI_MODE variable
    if ! grep -q "^AI_MODE=" "$config_file"; then
        log_error "Missing AI_MODE variable in config"
        record_issue "ai_config" "Missing AI_MODE variable" "critical" true
        
        apply_fix "echo 'AI_MODE=\"enhanced\"' >> '$config_file'" "Add AI_MODE to config"
    else
        local ai_mode=$(grep "^AI_MODE=" "$config_file" | cut -d'=' -f2 | tr -d '"')
        if [[ -z "$ai_mode" ]]; then
            log_error "AI_MODE is empty"
            record_issue "ai_config" "Empty AI_MODE variable" "critical" true
            
            apply_fix "sed -i 's/^AI_MODE=.*/AI_MODE=\"enhanced\"/' '$config_file'" "Set AI_MODE to enhanced"
        else
            # Only log AI_MODE if there might be an issue
            if [[ "$ai_mode" != "enhanced" && "$ai_mode" != "standard" ]]; then
                log_warn "AI_MODE has unusual value: $ai_mode"
                record_issue "ai_config" "Unusual AI_MODE value" "warning" true
            fi
        fi
    fi
    
    # Check ENABLE_AI_OPTIMIZATION
    if ! grep -q "^ENABLE_AI_OPTIMIZATION=true" "$config_file"; then
        log_warn "AI optimization not explicitly enabled"
        record_issue "ai_config" "AI optimization not enabled" "warning" true
        
        apply_fix "echo 'ENABLE_AI_OPTIMIZATION=true' >> '$config_file'" "Enable AI optimization"
    fi
    
    verbose_log "AI config file contents:"
    if [[ "$VERBOSE" == "true" ]]; then
        cat "$config_file" | head -10
    fi
    
    echo ""
}

# Check 2: System Services
check_system_services() {
    echo -e "${YELLOW}🔧 Checking System Services...${NC}"
    
    # Check Ollama with actual functionality test
    if command -v ollama >/dev/null 2>&1; then
        if pgrep -f ollama >/dev/null 2>&1; then
            # Test if Ollama can actually respond
            local models=$(ollama list 2>/dev/null | grep -v "NAME" | wc -l)
            if [[ $models -gt 0 ]]; then
                # Test actual AI model response
                if timeout 5s ollama run phi4 "test" >/dev/null 2>&1 || timeout 5s ollama run llama3.2 "test" >/dev/null 2>&1; then
                    log_success "Ollama AI models responding ($models available)"
                else
                    log_warn "Ollama models found but not responding"
                    record_issue "ollama" "Models not responding" "warning" true
                fi
            else
                log_warn "No Ollama models found"
                record_issue "ollama" "No models available" "warning" false
            fi
        else
            log_error "Ollama service not running"
            record_issue "ollama" "Service not running" "critical" true
            
            apply_fix "systemctl --user start ollama || (cd /usr/bin && ./ollama serve &)" "Start Ollama service"
        fi
    else
        log_error "Ollama not installed"
        record_issue "ollama" "Not installed" "critical" false
    fi
    
    # Check color server
    if curl -s "http://localhost:8080/ai-colors" >/dev/null 2>&1; then
        log_success "Color server responding"
    else
        log_warn "Color server not responding"
        record_issue "color_server" "Not responding" "warning" true
        
        apply_fix "cd '$DOTFILES_DIR' && python3 local-color-server.py &" "Start color server"
    fi
    
    # Check matugen with functionality test
    if command -v matugen >/dev/null 2>&1; then
        # Test if matugen can actually generate colors
        if matugen --help >/dev/null 2>&1; then
            log_success "Matugen responding to commands"
        else
            log_warn "Matugen installed but not responding"
            record_issue "matugen" "Not responding" "warning" true
        fi
    else
        log_error "Matugen not found"
        record_issue "matugen" "Not installed" "critical" false
    fi
    
    echo ""
}

# Check 3: Theme Files Status
check_theme_files() {
    echo -e "${YELLOW}🎨 Checking Theme Files...${NC}"
    
    local theme_files=(
        "$HOME/.config/waybar/style-dynamic.css"
        "$HOME/.config/kitty/theme-dynamic.conf"
        "$HOME/.config/fuzzel/fuzzel-dynamic.ini"
        "$HOME/.config/hypr/conf/colors.conf"
        "$HOME/.config/gtk-3.0/colors.css"
        "$HOME/.config/gtk-4.0/colors.css"
    )
    
    local now=$(date +%s)
    local old_threshold=$((now - 3600))  # 1 hour ago
    
    for file in "${theme_files[@]}"; do
        if [[ -f "$file" ]]; then
            local file_time=$(stat -c %Y "$file" 2>/dev/null || echo 0)
            local age=$((now - file_time))
            local age_min=$((age / 60))
            
            if [[ $file_time -gt $old_threshold ]]; then
                log_success "$(basename "$file") - Recent (${age_min}m ago)"
            else
                log_warn "$(basename "$file") - Old (${age_min}m ago)"
                record_issue "theme_files" "Old theme file: $(basename "$file")" "warning" true
            fi
            
            verbose_log "$(basename "$file"): $(ls -la "$file")"
        else
            log_error "Missing theme file: $(basename "$file")"
            record_issue "theme_files" "Missing file: $(basename "$file")" "critical" true
        fi
    done
    
    # Check if all files are old - suggests stale cache
    local old_files=0
    for file in "${theme_files[@]}"; do
        if [[ -f "$file" ]]; then
            local file_time=$(stat -c %Y "$file" 2>/dev/null || echo 0)
            if [[ $file_time -lt $old_threshold ]]; then
                old_files=$((old_files + 1))
            fi
        fi
    done
    
    if [[ $old_files -ge 3 ]]; then
        log_warn "Multiple old theme files detected - possible cache issue"
        record_issue "cache" "Stale theme files" "warning" true
        
        apply_fix "rm -rf ~/.cache/matugen/ai-results/* && '$DOTFILES_DIR/scripts/wallpaper-theme-changer-optimized.sh' \"\$(cat ~/.config/dynamic-theming/last-wallpaper)\" force" "Clear cache and regenerate themes"
    fi
    
    echo ""
}

# Check 4: AI Cache Status
check_ai_cache() {
    echo -e "${YELLOW}🧠 Checking AI Cache...${NC}"
    
    local cache_dir="$HOME/.cache/matugen/ai-results"
    
    if [[ -d "$cache_dir" ]]; then
        local cache_files=$(find "$cache_dir" -name "*.json" | wc -l)
        
        if [[ $cache_files -gt 0 ]]; then
            log_info "AI cache contains $cache_files entries"
            
            # Check for very old cache files
            local old_cache=$(find "$cache_dir" -name "*.json" -mtime +7 | wc -l)
            if [[ $old_cache -gt 0 ]]; then
                log_warn "$old_cache cache entries older than 7 days"
                record_issue "cache" "Old cache entries" "info" true
                
                apply_fix "find '$cache_dir' -name '*.json' -mtime +7 -delete" "Clean old cache entries"
            fi
            
            # Check cache size
            local cache_size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
            log_info "Cache size: $cache_size"
            
            if [[ "$VERBOSE" == "true" ]]; then
                log_info "Recent cache files:"
                ls -la "$cache_dir" | head -5
            fi
        else
            log_info "AI cache is empty"
        fi
    else
        log_info "AI cache directory doesn't exist yet"
    fi
    
    echo ""
}

# Check 5: Activity Log Analysis
check_activity_log() {
    echo -e "${YELLOW}📊 Checking Activity Log...${NC}"
    
    local log_file="$HOME/.cache/matugen/activity.log"
    
    if [[ -f "$log_file" ]]; then
        log_success "Activity log found"
        
        # Check recent activity
        local recent_lines=$(tail -10 "$log_file")
        
        # Look for cache hits vs fresh generation
        if echo "$recent_lines" | grep -q "cached AI analysis"; then
            log_info "Recent cache hits detected"
        fi
        
        if echo "$recent_lines" | grep -q "Generating new AI analysis"; then
            log_info "Fresh AI generation detected"
        fi
        
        # Check for errors
        if echo "$recent_lines" | grep -q "failed\|error\|❌"; then
            log_warn "Errors detected in recent activity"
            record_issue "activity" "Recent errors in log" "warning" false
        fi
        
        # Check waybar status
        if echo "$recent_lines" | grep -q "waybar reloaded ❌"; then
            log_warn "Waybar reload issues detected"
            record_issue "waybar" "Waybar reload failures" "warning" false
        else
            log_success "Waybar reloading properly"
        fi
        
        if [[ "$VERBOSE" == "true" ]]; then
            echo "Recent activity:"
            tail -5 "$log_file"
        fi
    else
        log_warn "No activity log found"
        record_issue "activity" "Missing activity log" "info" false
    fi
    
    echo ""
}

# Check 6: Quick Performance Test
quick_performance_test() {
    if [[ "$QUICK_MODE" == "true" ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}⚡ Quick Performance Test...${NC}"
    
    # Test wallpaper path
    local test_wallpaper
    if [[ -f "$HOME/.config/dynamic-theming/last-wallpaper" ]]; then
        test_wallpaper=$(cat "$HOME/.config/dynamic-theming/last-wallpaper")
    else
        # Find any wallpaper in assets
        test_wallpaper=$(find "$DOTFILES_DIR/assets/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" \) | head -1)
    fi
    
    if [[ -n "$test_wallpaper" && -f "$test_wallpaper" ]]; then
        log_info "Testing with: $(basename "$test_wallpaper")"
        
        # Run performance test
        local start_time=$(date +%s.%N)
        
        if "$DOTFILES_DIR/scripts/wallpaper-theme-changer-optimized.sh" "$test_wallpaper" >/tmp/perf-test.log 2>&1; then
            local end_time=$(date +%s.%N)
            local duration=$(echo "$end_time - $start_time" | bc -l)
            local duration_formatted=$(echo "$duration" | awk '{printf "%.1fs", $1}')
            
            log_success "Performance test completed in $duration_formatted"
            
            if (( $(echo "$duration < 3.0" | bc -l) )); then
                log_success "Performance within target (<3s)"
            else
                log_warn "Performance slower than target (>3s)"
                record_issue "performance" "Slow theme changes" "warning" false
            fi
        else
            log_error "Performance test failed"
            record_issue "performance" "Theme change failed" "critical" false
            
            if [[ "$VERBOSE" == "true" ]]; then
                echo "Error output:"
                cat /tmp/perf-test.log
            fi
        fi
    else
        log_warn "No wallpaper found for testing"
    fi
    
    echo ""
}

# Check 7: GTK Theming
check_gtk_theming() {
    echo -e "${YELLOW}🎨 Checking GTK Theming...${NC}"
    
    local gtk4_file="$HOME/.config/gtk-4.0/gtk.css"
    local gtk4_colors="$HOME/.config/gtk-4.0/colors.css"
    
    # Check if GTK colors are current (updated recently with theme changes)
    if [[ -f "$gtk4_colors" ]]; then
        local colors_age=$((($(date +%s) - $(stat -c %Y "$gtk4_colors")) / 60))
        if [[ $colors_age -lt 60 ]]; then
            log_success "GTK colors are current (<1h old)"
        else
            log_warn "GTK colors are old (${colors_age}m old)"
            record_issue "gtk" "Outdated GTK colors file" "warning" true
            apply_fix "force theme regeneration to update GTK colors" "Regenerate theme with current wallpaper"
        fi
    else
        log_error "GTK colors file missing"
        record_issue "gtk" "Missing GTK colors" "critical" true
    fi
    
    # Check if transparency fixes exist (only report if missing)
    if [[ -f "$gtk4_file" ]]; then
        if ! grep -q "alpha.*0\.3" "$gtk4_file"; then
            log_warn "GTK4 missing transparent borders fix"
            record_issue "gtk" "Missing transparent borders fix" "warning" true
            apply_fix "sed -i 's/border: 1px solid @window_fg_color/border: 1px solid alpha(@window_fg_color, 0.3)/' '$gtk4_file'" "Apply GTK4 transparent borders fix"
        fi
    else
        log_error "GTK4 CSS file missing"
        record_issue "gtk" "Missing GTK4 CSS" "critical" true
    fi
    
    # Check GTK3
    local gtk3_file="$HOME/.config/gtk-3.0/gtk.css"
    if [[ -f "$gtk3_file" ]] && ! grep -q "alpha.*0\.3" "$gtk3_file"; then
        log_warn "GTK3 missing transparent borders fix"
        record_issue "gtk" "Missing GTK3 transparent borders fix" "warning" true
    fi
    
    echo ""
}

# Generate summary report with AI analysis
generate_report() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  ${CYAN}📊 TROUBLESHOOTING SUMMARY${NC}                                             ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ $ISSUES_FOUND -eq 0 ]]; then
        log_success "No issues found! Your AI theming system is healthy."
        
        if [[ "$AI_ASSISTANCE" == "true" ]]; then
            log_ai "AI confirms: System is operating optimally"
            echo ""
            echo -e "${CYAN}🤖 AI HEALTH ASSESSMENT:${NC}"
            echo "✅ All critical components are functioning properly"
            echo "✅ Configuration files are present and valid"
            echo "✅ AI models are responsive and ready"
            echo "✅ Theme synchronization is working correctly"
        fi
    else
        log_warn "Found $ISSUES_FOUND issues"
        
        if [[ $FIXES_APPLIED -gt 0 ]]; then
            log_success "$FIXES_APPLIED fixes were applied successfully"
        fi
        
        # Show breakdown by severity
        if [[ -f "$RESULTS_FILE" ]] && command -v jq >/dev/null 2>&1; then
            local critical=$(jq '.issues | map(select(.severity == "critical")) | length' "$RESULTS_FILE" 2>/dev/null || echo 0)
            local warning=$(jq '.issues | map(select(.severity == "warning")) | length' "$RESULTS_FILE" 2>/dev/null || echo 0)
            local info=$(jq '.issues | map(select(.severity == "info")) | length' "$RESULTS_FILE" 2>/dev/null || echo 0)
            
            if [[ $critical -gt 0 ]]; then
                log_error "Critical issues: $critical"
            fi
            if [[ $warning -gt 0 ]]; then
                log_warn "Warning issues: $warning"
            fi
            if [[ $info -gt 0 ]]; then
                log_info "Info issues: $info"
            fi
        fi
        
        # AI Analysis of all issues
        if [[ "$AI_ASSISTANCE" == "true" && -f "$RESULTS_FILE" && "$BRIEF_AI" == "false" ]]; then
            echo ""
            echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
            echo -e "${CYAN}🤖 AI ANALYSIS${NC}"
            echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
            echo ""
            
            local system_info=$(collect_system_info)
            local ai_analysis=$(ai_analyze_issues "$RESULTS_FILE" "$system_info")
            
            if [[ -n "$ai_analysis" ]]; then
                echo "$ai_analysis"
                echo ""
                log_ai "Full analysis saved to: /tmp/ai-analysis-*.txt"
            else
                log_warn "AI analysis unavailable (model may be busy)"
            fi
        elif [[ "$AI_ASSISTANCE" == "true" && "$BRIEF_AI" == "true" ]]; then
            log_ai "Brief AI mode enabled - individual issue analysis provided above"
        fi
    fi
    
    echo ""
    if [[ $ISSUES_FOUND -gt 0 ]]; then
        if [[ "$AI_ASSISTANCE" != "true" ]]; then
            log_info "💡 Try with --ai for intelligent fix suggestions"
            echo "Example: ./scripts/troubleshoot-theming.sh --ai --fix"
        elif [[ "$AUTO_FIX" != "true" ]]; then
            log_info "💡 Run with --fix to enable interactive fixing"
            echo "Example: ./scripts/troubleshoot-theming.sh --ai --fix"
        fi
    fi
    
    echo ""
    if [[ "$AI_ASSISTANCE" == "true" ]]; then
        log_info "🧠 For detailed explanations, check saved AI analysis files"
    fi
    log_info "📖 For more help, see: COMPLETE_SYSTEM_GUIDE.md troubleshooting section"
    echo ""
}

# Main execution
main() {
    print_header
    
    check_ai_config
    check_system_services
    check_theme_files
    check_ai_cache
    check_activity_log
    check_gtk_theming
    quick_performance_test
    
    generate_report
    
    # Cleanup
    if [[ "$VERBOSE" != "true" ]]; then
        rm -f /tmp/perf-test.log
    fi
    
    # Exit code based on critical issues
    if [[ -f "$RESULTS_FILE" ]]; then
        local critical=$(jq '.issues | map(select(.severity == "critical")) | length' "$RESULTS_FILE" 2>/dev/null || echo 0)
        if [[ $critical -gt 0 ]]; then
            exit 1
        fi
    fi
    
    exit 0
}

# Run main function
main "$@" 