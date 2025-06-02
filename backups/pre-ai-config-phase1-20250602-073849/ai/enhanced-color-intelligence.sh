#!/bin/bash

# =============================================================================
# 🧠 ENHANCED COLOR INTELLIGENCE - VISION + MATHEMATICAL AI
# =============================================================================
# Combines ollama vision analysis with mathematical color intelligence
# Part of: AI-Enhanced Dynamic Theming System  
# Phase: 2C - Enhanced Color Intelligence Integration

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENHANCED_LOG="/tmp/enhanced-color-intelligence.log"
PERFORMANCE_LOG="/tmp/enhanced-performance.log"

# AI configuration
ENABLE_VISION_AI="${ENABLE_VISION_AI:-true}"
ENABLE_MATHEMATICAL_AI="${ENABLE_MATHEMATICAL_AI:-true}"
VISION_WEIGHT="${VISION_WEIGHT:-0.6}"
MATHEMATICAL_WEIGHT="${MATHEMATICAL_WEIGHT:-0.4}"

# Performance timing
start_timer() {
    TIMER_START=$(date +%s.%3N)
}

end_timer() {
    local TIMER_END=$(date +%s.%3N)
    local DURATION=$(echo "$TIMER_END - $TIMER_START" | bc -l)
    echo "$DURATION"
}

# Logging function
log_enhanced() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+[%s] %H:%M:%S')
    echo "$timestamp - $message" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$ENHANCED_LOG"
}

# Check dependencies
check_enhanced_dependencies() {
    log_enhanced "INFO" "Checking enhanced AI dependencies..."
    
    # Check vision analyzer
    if [[ "$ENABLE_VISION_AI" == "true" ]]; then
        if [[ ! -f "$SCRIPT_DIR/vision-analyzer.sh" ]]; then
            log_enhanced "ERROR" "Vision analyzer not found: $SCRIPT_DIR/vision-analyzer.sh"
            return 1
        fi
    fi
    
    # Check mathematical AI components
    if [[ "$ENABLE_MATHEMATICAL_AI" == "true" ]]; then
        if [[ ! -f "$SCRIPT_DIR/color-harmony-analyzer.sh" ]]; then
            log_enhanced "ERROR" "Color harmony analyzer not found: $SCRIPT_DIR/color-harmony-analyzer.sh"
            return 1
        fi
        
        if [[ ! -f "$SCRIPT_DIR/accessibility-optimizer.sh" ]]; then
            log_enhanced "ERROR" "Accessibility optimizer not found: $SCRIPT_DIR/accessibility-optimizer.sh"
            return 1
        fi
    fi
    
    # Check required tools
    for tool in jq bc; do
        if ! command -v "$tool" &> /dev/null; then
            log_enhanced "ERROR" "Required tool not found: $tool"
            return 1
        fi
    done
    
    log_enhanced "INFO" "Enhanced AI dependencies check passed"
    return 0
}

# Run vision analysis
run_vision_analysis() {
    local wallpaper_path="$1"
    local vision_output="/tmp/vision-analysis-enhanced.json"
    
    if [[ "$ENABLE_VISION_AI" != "true" ]]; then
        log_enhanced "INFO" "Vision AI disabled, skipping vision analysis"
        return 1
    fi
    
    log_enhanced "INFO" "Running vision analysis..."
    start_timer
    
    if bash "$SCRIPT_DIR/vision-analyzer.sh" "$wallpaper_path" "$vision_output" >/dev/null 2>&1; then
        local duration=$(end_timer)
        log_enhanced "INFO" "Vision analysis completed in ${duration}s"
        echo "$vision_output"
        return 0
    else
        local duration=$(end_timer)
        log_enhanced "WARN" "Vision analysis failed in ${duration}s"
        return 1
    fi
}

# Run mathematical analysis (existing color harmony + accessibility)
run_mathematical_analysis() {
    local matugen_colors="$1"
    local harmony_output="/tmp/harmony-analysis-enhanced.json"
    local accessibility_output="/tmp/accessibility-analysis-enhanced.json"
    
    if [[ "$ENABLE_MATHEMATICAL_AI" != "true" ]]; then
        log_enhanced "INFO" "Mathematical AI disabled, skipping mathematical analysis"
        return 1
    fi
    
    log_enhanced "INFO" "Running mathematical analysis..."
    start_timer
    
    # Run color harmony analysis
    if ! bash "$SCRIPT_DIR/color-harmony-analyzer.sh" "$matugen_colors" "$harmony_output" >/dev/null 2>&1; then
        log_enhanced "WARN" "Color harmony analysis failed"
        return 1
    fi
    
    # Run accessibility optimization
    if ! bash "$SCRIPT_DIR/accessibility-optimizer.sh" "$harmony_output" "$matugen_colors" "$accessibility_output" >/dev/null 2>&1; then
        log_enhanced "WARN" "Accessibility optimization failed"
        return 1
    fi
    
    local duration=$(end_timer)
    log_enhanced "INFO" "Mathematical analysis completed in ${duration}s"
    echo "$accessibility_output"
    return 0
}

# Intelligent color fusion - combine vision and mathematical insights
fuse_color_intelligence() {
    local vision_file="$1"
    local mathematical_file="$2"
    local output_file="$3"
    
    log_enhanced "INFO" "Fusing vision and mathematical intelligence..."
    
    # Extract vision insights
    local vision_available=false
    local vision_category=""
    local vision_mood=""
    local vision_primary=""
    local vision_accent=""
    local vision_style=""
    
    if [[ -f "$vision_file" ]]; then
        if jq -e . "$vision_file" >/dev/null 2>&1; then
            vision_available=true
            vision_category=$(jq -r '.category // .content.category // "unknown"' "$vision_file")
            vision_mood=$(jq -r '.mood // .mood.energy // "unknown"' "$vision_file")
            vision_primary=$(jq -r '.primary_color // .theming.primary_suggestion // ""' "$vision_file")
            vision_accent=$(jq -r '.accent_color // .theming.accent_suggestion // ""' "$vision_file")
            vision_style=$(jq -r '.style // .theming.background_style // ""' "$vision_file")
        fi
    fi
    
    # Extract mathematical insights
    local math_available=false
    local math_harmony_score=""
    local math_accessibility=""
    local math_primary_color=""
    local math_secondary_color=""
    
    if [[ -f "$mathematical_file" ]]; then
        if jq -e . "$mathematical_file" >/dev/null 2>&1; then
            math_available=true
            math_harmony_score=$(jq -r '.optimization_metadata.accessibility_target // "WCAG_AAA"' "$mathematical_file")
            math_accessibility=$(jq -r '.optimization_metadata.accessibility_target // "WCAG_AAA"' "$mathematical_file")
            math_primary_color=$(jq -r '.colors.dark.primary // ""' "$mathematical_file")
            math_secondary_color=$(jq -r '.colors.dark.secondary // ""' "$mathematical_file")
        fi
    fi
    
    # Intelligent color strategy based on content and analysis
    local final_strategy="balanced"
    local primary_color_source="mathematical"
    local accent_color_source="mathematical"
    local confidence="medium"
    
    # Content-aware strategy selection
    if [[ "$vision_available" == "true" ]]; then
        case "$vision_category" in
            "abstract")
                if [[ "$vision_mood" == "dark" ]]; then
                    final_strategy="vision_guided_dark"
                    primary_color_source="vision"
                    confidence="high"
                elif [[ "$vision_mood" == "energetic" ]]; then
                    final_strategy="vision_guided_vibrant"
                    primary_color_source="mathematical"
                    accent_color_source="vision"
                    confidence="high"
                fi
                ;;
            "gaming")
                final_strategy="vision_guided_vibrant"
                primary_color_source="vision"
                accent_color_source="mathematical"
                confidence="high"
                ;;
            "nature")
                final_strategy="mathematical_harmony"
                primary_color_source="mathematical"
                accent_color_source="vision"
                confidence="high"
                ;;
            "minimal")
                final_strategy="mathematical_accessibility"
                primary_color_source="mathematical"
                confidence="high"
                ;;
        esac
    fi
    
    # Select optimal colors based on strategy
    local final_primary=""
    local final_accent=""
    
    # Primary color selection
    if [[ "$primary_color_source" == "vision" ]] && [[ -n "$vision_primary" ]] && [[ "$vision_primary" != "#000000" ]] && [[ "$vision_primary" != "#00000" ]]; then
        final_primary="$vision_primary"
        log_enhanced "INFO" "Using vision primary color: $final_primary"
    elif [[ "$math_available" == "true" ]] && [[ -n "$math_primary_color" ]]; then
        final_primary="$math_primary_color"
        log_enhanced "INFO" "Using mathematical primary color: $final_primary"
    fi
    
    # Accent color selection
    if [[ "$accent_color_source" == "vision" ]] && [[ -n "$vision_accent" ]] && [[ "$vision_accent" != "#000000" ]] && [[ ${#vision_accent} -eq 7 ]]; then
        final_accent="$vision_accent"
        log_enhanced "INFO" "Using vision accent color: $final_accent"
    elif [[ "$math_available" == "true" ]] && [[ -n "$math_secondary_color" ]]; then
        final_accent="$math_secondary_color"
        log_enhanced "INFO" "Using mathematical accent color: $final_accent"
    fi
    
    # Create enhanced intelligence output
    cat > "$output_file" << EOF
{
  "enhanced_intelligence": {
    "strategy": "$final_strategy",
    "confidence": "$confidence",
    "primary_color": "$final_primary",
    "accent_color": "$final_accent",
    "vision_insights": {
      "available": $vision_available,
      "category": "$vision_category",
      "mood": "$vision_mood",
      "style": "$vision_style"
    },
    "mathematical_insights": {
      "available": $math_available,
      "harmony_score": "$math_harmony_score",
      "accessibility": "$math_accessibility"
    },
    "color_sources": {
      "primary": "$primary_color_source",
      "accent": "$accent_color_source"
    },
    "processing_weights": {
      "vision_weight": "$VISION_WEIGHT",
      "mathematical_weight": "$MATHEMATICAL_WEIGHT"
    }
  }
}
EOF
    
    log_enhanced "INFO" "Enhanced color intelligence saved to: $output_file"
    log_enhanced "INFO" "Strategy: $final_strategy, Confidence: $confidence"
    log_enhanced "INFO" "Final colors - Primary: $final_primary, Accent: $final_accent"
}

# Performance reporting
report_enhanced_performance() {
    if [[ -f "$PERFORMANCE_LOG" ]]; then
        local total_analyses=$(wc -l < "$PERFORMANCE_LOG")
        local avg_time=$(awk '{sum+=$1} END {print sum/NR}' "$PERFORMANCE_LOG")
        local max_time=$(sort -n "$PERFORMANCE_LOG" | tail -1)
        local min_time=$(sort -n "$PERFORMANCE_LOG" | head -1)
        
        log_enhanced "INFO" "Enhanced AI Performance Summary:"
        log_enhanced "INFO" "  Total Enhanced Analyses: $total_analyses"
        log_enhanced "INFO" "  Average Time: ${avg_time}s"
        log_enhanced "INFO" "  Range: ${min_time}s - ${max_time}s"
        
        # Performance targets: <4s for full enhanced analysis
        if (( $(echo "$avg_time < 4.0" | bc -l) )); then
            log_enhanced "INFO" "  Performance: ✅ Excellent (< 4s average)"
        elif (( $(echo "$avg_time < 6.0" | bc -l) )); then
            log_enhanced "INFO" "  Performance: ⚠️ Acceptable (< 6s average)"
        else
            log_enhanced "WARN" "  Performance: ❌ Slow (> 6s average)"
        fi
    fi
}

# Main enhanced color intelligence function
main() {
    local wallpaper_path="$1"
    local matugen_colors="$2"
    local output_file="${3:-/tmp/enhanced-color-intelligence.json}"
    
    # Initialize logs
    > "$ENHANCED_LOG"
    
    # Validate inputs
    if [[ -z "$wallpaper_path" ]] || [[ -z "$matugen_colors" ]]; then
        echo "Usage: $0 <wallpaper_path> <matugen_colors_json> [output_file]"
        echo "Example: $0 /path/to/wallpaper.jpg /tmp/matugen_colors.json /tmp/enhanced_output.json"
        return 1
    fi
    
    log_enhanced "INFO" "Enhanced Color Intelligence starting..."
    log_enhanced "INFO" "Wallpaper: $wallpaper_path"
    log_enhanced "INFO" "Matugen colors: $matugen_colors"
    log_enhanced "INFO" "Vision AI: $ENABLE_VISION_AI"
    log_enhanced "INFO" "Mathematical AI: $ENABLE_MATHEMATICAL_AI"
    
    start_timer
    
    # Check dependencies
    if ! check_enhanced_dependencies; then
        log_enhanced "ERROR" "Enhanced dependency check failed"
        return 1
    fi
    
    # Run AI analyses
    local vision_result=""
    local mathematical_result=""
    
    # Vision analysis
    if vision_result=$(run_vision_analysis "$wallpaper_path"); then
        log_enhanced "INFO" "Vision analysis successful: $vision_result"
    else
        log_enhanced "WARN" "Vision analysis unavailable, proceeding with mathematical only"
    fi
    
    # Mathematical analysis  
    if mathematical_result=$(run_mathematical_analysis "$matugen_colors"); then
        log_enhanced "INFO" "Mathematical analysis successful: $mathematical_result"
    else
        log_enhanced "WARN" "Mathematical analysis unavailable, proceeding with vision only"
    fi
    
    # Intelligent fusion
    fuse_color_intelligence "$vision_result" "$mathematical_result" "$output_file"
    
    # Performance tracking
    local total_duration=$(end_timer)
    echo "$total_duration" >> "$PERFORMANCE_LOG"
    log_enhanced "INFO" "Enhanced intelligence completed in ${total_duration}s"
    
    # Report performance
    report_enhanced_performance
    
    # Output success
    echo "$output_file"
    return 0
}

# Run main function if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 