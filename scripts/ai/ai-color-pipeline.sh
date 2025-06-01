#!/bin/bash

# AI Color Pipeline - Phase 1C Integration
# Purpose: Unified AI-powered color optimization pipeline
# Input: Wallpaper image path
# Output: AI-optimized color palette ready for theme application

# Safety: Non-destructive, optional enhancement, easy rollback

set -euo pipefail

# Configuration
SCRIPT_NAME="ai-color-pipeline"
LOG_FILE="/tmp/${SCRIPT_NAME}.log"
DEBUG="${DEBUG:-false}"

# AI Pipeline settings
ENABLE_AI_OPTIMIZATION="${ENABLE_AI_OPTIMIZATION:-true}"
AI_OUTPUT_DIR="/tmp/ai-pipeline"

# Component paths
HARMONY_ANALYZER="scripts/ai/color-harmony-analyzer.sh"
ACCESSIBILITY_OPTIMIZER="scripts/ai/accessibility-optimizer.sh"

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [${SCRIPT_NAME}] $1" | tee -a "$LOG_FILE"
}

# Debug logging
debug_log() {
    if [[ "$DEBUG" == "true" ]]; then
        log_message "DEBUG: $1"
    fi
}

# Error handling
error_exit() {
    log_message "ERROR: $1"
    exit 1
}

# Performance monitoring
performance_timer() {
    local start_time="$1"
    local operation="$2"
    local end_time=$(date +%s%N)
    local duration=$(echo "scale=3; ($end_time - $start_time) / 1000000000" | bc)
    log_message "Performance: $operation completed in ${duration}s"
    echo "$duration"
}

# Validate dependencies
validate_dependencies() {
    debug_log "Validating AI pipeline dependencies"
    
    # Check for required commands
    local required_commands=("matugen" "jq" "bc")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error_exit "Required command not found: $cmd"
        fi
    done
    
    # Check for AI components
    if [[ ! -x "$HARMONY_ANALYZER" ]]; then
        error_exit "Harmony analyzer not found or not executable: $HARMONY_ANALYZER"
    fi
    
    if [[ ! -x "$ACCESSIBILITY_OPTIMIZER" ]]; then
        error_exit "Accessibility optimizer not found or not executable: $ACCESSIBILITY_OPTIMIZER"
    fi
    
    debug_log "All dependencies validated"
}

# Generate base colors using matugen
generate_base_colors() {
    local wallpaper_path="$1"
    local output_file="$2"
    
    debug_log "Generating base colors from wallpaper: $wallpaper_path"
    
    # Validate wallpaper exists
    [[ ! -f "$wallpaper_path" ]] && error_exit "Wallpaper not found: $wallpaper_path"
    
    # Extract colors using matugen
    local start_time=$(date +%s%N)
    if ! matugen image "$wallpaper_path" --mode dark --json hex --dry-run > "$output_file" 2>/tmp/matugen_error.log; then
        log_message "matugen error log: $(cat /tmp/matugen_error.log)"
        error_exit "Failed to generate base colors with matugen"
    fi
    
    performance_timer "$start_time" "Base color generation"
    
    # Verify output is valid JSON
    if ! jq empty "$output_file" 2>/dev/null; then
        error_exit "Generated invalid JSON from matugen"
    fi
    
    log_message "Base colors generated successfully: $output_file"
}

# Run harmony analysis
run_harmony_analysis() {
    local colors_file="$1"
    local output_file="$2"
    
    debug_log "Running color harmony analysis"
    
    local start_time=$(date +%s%N)
    if ! "$HARMONY_ANALYZER" "$colors_file" > /dev/null; then
        error_exit "Harmony analysis failed"
    fi
    
    performance_timer "$start_time" "Harmony analysis"
    
    # Move analysis result to our pipeline directory
    if [[ -f "/tmp/color-harmony-analysis.json" ]]; then
        cp "/tmp/color-harmony-analysis.json" "$output_file"
        log_message "Harmony analysis completed: $output_file"
    else
        error_exit "Harmony analysis output not found"
    fi
}

# Run accessibility optimization
run_accessibility_optimization() {
    local harmony_file="$1"
    local colors_file="$2"
    local output_file="$3"
    
    debug_log "Running accessibility optimization"
    
    local start_time=$(date +%s%N)
    local optimized_colors_path
    if ! optimized_colors_path=$("$ACCESSIBILITY_OPTIMIZER" "$harmony_file" "$colors_file"); then
        error_exit "Accessibility optimization failed"
    fi
    
    performance_timer "$start_time" "Accessibility optimization"
    
    # Move optimized colors to our pipeline directory
    if [[ -f "$optimized_colors_path" ]]; then
        cp "$optimized_colors_path" "$output_file"
        log_message "Accessibility optimization completed: $output_file"
    else
        error_exit "Optimized colors output not found"
    fi
}

# Generate pipeline summary report
generate_pipeline_report() {
    local wallpaper_path="$1"
    local base_colors_file="$2"
    local harmony_file="$3"
    local optimized_colors_file="$4"
    local report_file="$5"
    
    debug_log "Generating pipeline summary report"
    
    # Extract key metrics
    local harmony_score=$(jq -r '.palette_score // "unknown"' "$harmony_file" 2>/dev/null)
    local accessibility_level=$(jq -r '.recommendations.accessibility_level // "unknown"' "$harmony_file" 2>/dev/null)
    local optimizations_count=$(jq -r '.optimization_metadata.optimizations_applied | length // 0' "$optimized_colors_file" 2>/dev/null)
    
    # Extract sample colors for report
    local primary_original=$(jq -r '.colors.dark.primary // .primary // "unknown"' "$base_colors_file" 2>/dev/null)
    local primary_optimized=$(jq -r '.colors.dark.primary // .primary // "unknown"' "$optimized_colors_file" 2>/dev/null)
    
    # Generate comprehensive report
    cat > "$report_file" << EOF
{
  "ai_pipeline_report": {
    "timestamp": "$(date -Iseconds)",
    "wallpaper": {
      "path": "$wallpaper_path",
      "filename": "$(basename "$wallpaper_path")"
    },
    "processing_summary": {
      "harmony_score": $harmony_score,
      "accessibility_level": "$accessibility_level",
      "optimizations_applied": $optimizations_count,
      "ai_enhancement_enabled": $ENABLE_AI_OPTIMIZATION
    },
    "color_comparison": {
      "primary_original": "$primary_original",
      "primary_optimized": "$primary_optimized",
      "colors_changed": $(if [[ "$primary_original" != "$primary_optimized" ]]; then echo "true"; else echo "false"; fi)
    },
    "output_files": {
      "base_colors": "$base_colors_file",
      "harmony_analysis": "$harmony_file", 
      "optimized_colors": "$optimized_colors_file",
      "pipeline_report": "$report_file"
    },
    "performance_metrics": {
      "total_processing_time": "$(grep 'Performance:' "$LOG_FILE" | tail -3 | awk '{sum += $6} END {printf "%.3f", sum}')s",
      "components_tested": ["matugen", "harmony_analyzer", "accessibility_optimizer"]
    }
  }
}
EOF
    
    log_message "Pipeline report generated: $report_file"
}

# Main AI pipeline function
run_ai_pipeline() {
    local wallpaper_path="$1"
    local output_colors_file="$2"
    
    log_message "Starting AI color optimization pipeline"
    log_message "Wallpaper: $wallpaper_path"
    log_message "AI optimization enabled: $ENABLE_AI_OPTIMIZATION"
    
    # Create output directory
    mkdir -p "$AI_OUTPUT_DIR"
    
    # Define pipeline file paths
    local base_colors_file="$AI_OUTPUT_DIR/base-colors.json"
    local harmony_file="$AI_OUTPUT_DIR/harmony-analysis.json"
    local optimized_colors_file="$AI_OUTPUT_DIR/optimized-colors.json"
    local report_file="$AI_OUTPUT_DIR/pipeline-report.json"
    
    # Pipeline execution
    local pipeline_start_time=$(date +%s%N)
    
    # Step 1: Generate base colors
    generate_base_colors "$wallpaper_path" "$base_colors_file"
    
    if [[ "$ENABLE_AI_OPTIMIZATION" == "true" ]]; then
        # Step 2: Analyze color harmony
        run_harmony_analysis "$base_colors_file" "$harmony_file"
        
        # Step 3: Optimize accessibility
        run_accessibility_optimization "$harmony_file" "$base_colors_file" "$optimized_colors_file"
        
        # Use optimized colors as final output
        cp "$optimized_colors_file" "$output_colors_file"
        
        log_message "AI optimization pipeline completed successfully"
    else
        # AI disabled - use base colors directly
        cp "$base_colors_file" "$output_colors_file"
        
        # Create minimal analysis files for consistency
        echo '{"analysis_timestamp": "'$(date -Iseconds)'", "ai_disabled": true, "palette_score": 75}' > "$harmony_file"
        cp "$base_colors_file" "$optimized_colors_file"
        
        log_message "AI optimization skipped (disabled) - using base colors"
    fi
    
    # Step 4: Generate summary report
    generate_pipeline_report "$wallpaper_path" "$base_colors_file" "$harmony_file" "$optimized_colors_file" "$report_file"
    
    # Performance summary
    local pipeline_duration=$(performance_timer "$pipeline_start_time" "Complete AI pipeline")
    
    # Final validation
    if ! jq empty "$output_colors_file" 2>/dev/null; then
        error_exit "Final output is not valid JSON: $output_colors_file"
    fi
    
    log_message "AI pipeline completed successfully in ${pipeline_duration}s"
    log_message "Output file: $output_colors_file"
    log_message "Report file: $report_file"
    
    echo "$output_colors_file"
}

# Main function
main() {
    local wallpaper_path="$1"
    local output_file="${2:-/tmp/ai-optimized-colors.json}"
    
    log_message "AI Color Pipeline started"
    debug_log "Input wallpaper: $wallpaper_path"
    debug_log "Output file: $output_file"
    
    # Validate dependencies
    validate_dependencies
    
    # Run the AI pipeline
    local result=$(run_ai_pipeline "$wallpaper_path" "$output_file")
    
    log_message "AI Color Pipeline completed successfully"
    echo "$result"
}

# Script usage
show_usage() {
    cat << EOF
Usage: $0 <wallpaper_path> [output_file]

AI Color Pipeline - Phase 1C Integration

Complete AI-powered color optimization pipeline combining:
- Color harmony analysis
- Accessibility optimization  
- Performance monitoring
- Comprehensive reporting

Arguments:
  wallpaper_path       Path to wallpaper image
  output_file         Optional: Output JSON file (default: /tmp/ai-optimized-colors.json)

Environment Variables:
  ENABLE_AI_OPTIMIZATION    Enable/disable AI features (default: true)
  DEBUG                     Enable debug logging (default: false)

Examples:
  $0 assets/wallpapers/dark/evilpuccin.png
  $0 path/to/wallpaper.jpg /tmp/my-colors.json
  ENABLE_AI_OPTIMIZATION=false $0 wallpaper.png

Output:
  - AI-optimized color palette
  - Harmony analysis report
  - Accessibility optimization report
  - Performance metrics
  - Pipeline summary report

EOF
}

# Entry point
if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
fi

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Run main function
main "$@" 