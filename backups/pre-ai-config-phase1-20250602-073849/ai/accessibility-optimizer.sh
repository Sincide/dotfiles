#!/bin/bash

# Accessibility Optimizer - Phase 1B AI Enhancement
# Purpose: Optimize colors for better accessibility while maintaining harmony
# Input: Color harmony analysis JSON + original matugen JSON
# Output: Optimized color palette with improved accessibility

# Safety: Non-destructive, generates new files, easy rollback

set -euo pipefail

# Configuration
SCRIPT_NAME="accessibility-optimizer"
LOG_FILE="/tmp/${SCRIPT_NAME}.log"
DEBUG="${DEBUG:-false}"

# Accessibility targets
MIN_CONTRAST_AA=4.5
MIN_CONTRAST_AAA=7.0
TARGET_CONTRAST=7.5  # Aim slightly above AAA

# Logging function
log_message() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') [${SCRIPT_NAME}] $1"
    echo "$message" >> "$LOG_FILE"
    # Only echo to stderr if not being used in a pipeline (to avoid polluting stdout)
    if [[ -t 1 ]]; then
        echo "$message"
    fi
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

# Color utility functions (enhanced versions)
hex_to_rgb() {
    local hex="$1"
    hex="${hex#\#}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "$r $g $b"
}

rgb_to_hex() {
    local r=$1 g=$2 b=$3
    printf "#%02x%02x%02x\n" "$r" "$g" "$b"
}

# Advanced relative luminance calculation
relative_luminance() {
    local r=$1 g=$2 b=$3
    
    # Normalize to 0-1
    r=$(echo "scale=6; $r / 255" | bc)
    g=$(echo "scale=6; $g / 255" | bc)
    b=$(echo "scale=6; $b / 255" | bc)
    
    # Apply gamma correction
    if (( $(echo "$r <= 0.03928" | bc -l) )); then
        r=$(echo "scale=6; $r / 12.92" | bc)
    else
        r=$(echo "scale=6; e(l(($r + 0.055) / 1.055) * 2.4)" | bc -l)
    fi
    
    if (( $(echo "$g <= 0.03928" | bc -l) )); then
        g=$(echo "scale=6; $g / 12.92" | bc)
    else
        g=$(echo "scale=6; e(l(($g + 0.055) / 1.055) * 2.4)" | bc -l)
    fi
    
    if (( $(echo "$b <= 0.03928" | bc -l) )); then
        b=$(echo "scale=6; $b / 12.92" | bc)
    else
        b=$(echo "scale=6; e(l(($b + 0.055) / 1.055) * 2.4)" | bc -l)
    fi
    
    # Calculate luminance
    echo "scale=6; 0.2126 * $r + 0.7152 * $g + 0.0722 * $b" | bc
}

# Enhanced contrast ratio calculation
contrast_ratio() {
    local r1=$1 g1=$2 b1=$3
    local r2=$4 g2=$5 b2=$6
    
    local lum1=$(relative_luminance $r1 $g1 $b1)
    local lum2=$(relative_luminance $r2 $g2 $b2)
    
    # Ensure lighter color is first
    if (( $(echo "$lum1 < $lum2" | bc -l) )); then
        local temp=$lum1
        lum1=$lum2
        lum2=$temp
    fi
    
    echo "scale=3; ($lum1 + 0.05) / ($lum2 + 0.05)" | bc
}

# Lighten/darken color while preserving hue
adjust_lightness() {
    local hex="$1"
    local adjustment="$2"  # Positive to lighten, negative to darken
    
    local rgb=($(hex_to_rgb "$hex"))
    local r=${rgb[0]} g=${rgb[1]} b=${rgb[2]}
    
    # Simple linear adjustment (could be enhanced with HSL conversion)
    r=$(echo "scale=0; $r + $adjustment" | bc)
    g=$(echo "scale=0; $g + $adjustment" | bc)
    b=$(echo "scale=0; $b + $adjustment" | bc)
    
    # Clamp to 0-255
    r=$(echo "if ($r < 0) 0 else if ($r > 255) 255 else $r" | bc)
    g=$(echo "if ($g < 0) 0 else if ($g > 255) 255 else $g" | bc)
    b=$(echo "if ($b < 0) 0 else if ($b > 255) 255 else $b" | bc)
    
    rgb_to_hex $r $g $b
}

# Optimize contrast between two colors
optimize_contrast() {
    local color1_hex="$1"
    local color2_hex="$2"
    local target_contrast="$3"
    local adjust_which="$4"  # "first", "second", or "both"
    
    debug_log "Optimizing contrast between $color1_hex and $color2_hex (target: $target_contrast)"
    
    local color1_rgb=($(hex_to_rgb "$color1_hex"))
    local color2_rgb=($(hex_to_rgb "$color2_hex"))
    
    local current_contrast=$(contrast_ratio ${color1_rgb[0]} ${color1_rgb[1]} ${color1_rgb[2]} ${color2_rgb[0]} ${color2_rgb[1]} ${color2_rgb[2]})
    
    debug_log "Current contrast: $current_contrast"
    
    # If already meeting target, return original colors
    if (( $(echo "$current_contrast >= $target_contrast" | bc -l) )); then
        echo "$color1_hex $color2_hex"
        return
    fi
    
    # Determine which color to adjust based on luminance
    local lum1=$(relative_luminance ${color1_rgb[0]} ${color1_rgb[1]} ${color1_rgb[2]})
    local lum2=$(relative_luminance ${color2_rgb[0]} ${color2_rgb[1]} ${color2_rgb[2]})
    
    local optimized_color1="$color1_hex"
    local optimized_color2="$color2_hex"
    
    # Optimization strategy: make darker color darker or lighter color lighter
    if [[ "$adjust_which" == "first" ]] || [[ "$adjust_which" == "both" ]]; then
        if (( $(echo "$lum1 > $lum2" | bc -l) )); then
            # Color1 is lighter, make it lighter
            for adjustment in 20 40 60 80 100; do
                local test_color=$(adjust_lightness "$color1_hex" $adjustment)
                local test_rgb=($(hex_to_rgb "$test_color"))
                local test_contrast=$(contrast_ratio ${test_rgb[0]} ${test_rgb[1]} ${test_rgb[2]} ${color2_rgb[0]} ${color2_rgb[1]} ${color2_rgb[2]})
                if (( $(echo "$test_contrast >= $target_contrast" | bc -l) )); then
                    optimized_color1="$test_color"
                    break
                fi
            done
        else
            # Color1 is darker, make it darker
            for adjustment in -20 -40 -60 -80 -100; do
                local test_color=$(adjust_lightness "$color1_hex" $adjustment)
                local test_rgb=($(hex_to_rgb "$test_color"))
                local test_contrast=$(contrast_ratio ${test_rgb[0]} ${test_rgb[1]} ${test_rgb[2]} ${color2_rgb[0]} ${color2_rgb[1]} ${color2_rgb[2]})
                if (( $(echo "$test_contrast >= $target_contrast" | bc -l) )); then
                    optimized_color1="$test_color"
                    break
                fi
            done
        fi
    fi
    
    if [[ "$adjust_which" == "second" ]] || [[ "$adjust_which" == "both" ]]; then
        local base_color2_rgb=($(hex_to_rgb "$color2_hex"))
        if (( $(echo "$lum2 > $lum1" | bc -l) )); then
            # Color2 is lighter, make it lighter
            for adjustment in 20 40 60 80 100; do
                local test_color=$(adjust_lightness "$color2_hex" $adjustment)
                local test_rgb=($(hex_to_rgb "$test_color"))
                local optimized_color1_rgb=($(hex_to_rgb "$optimized_color1"))
                local test_contrast=$(contrast_ratio ${optimized_color1_rgb[0]} ${optimized_color1_rgb[1]} ${optimized_color1_rgb[2]} ${test_rgb[0]} ${test_rgb[1]} ${test_rgb[2]})
                if (( $(echo "$test_contrast >= $target_contrast" | bc -l) )); then
                    optimized_color2="$test_color"
                    break
                fi
            done
        else
            # Color2 is darker, make it darker
            for adjustment in -20 -40 -60 -80 -100; do
                local test_color=$(adjust_lightness "$color2_hex" $adjustment)
                local test_rgb=($(hex_to_rgb "$test_color"))
                local optimized_color1_rgb=($(hex_to_rgb "$optimized_color1"))
                local test_contrast=$(contrast_ratio ${optimized_color1_rgb[0]} ${optimized_color1_rgb[1]} ${optimized_color1_rgb[2]} ${test_rgb[0]} ${test_rgb[1]} ${test_rgb[2]})
                if (( $(echo "$test_contrast >= $target_contrast" | bc -l) )); then
                    optimized_color2="$test_color"
                    break
                fi
            done
        fi
    fi
    
    # Verify final contrast
    local final_color1_rgb=($(hex_to_rgb "$optimized_color1"))
    local final_color2_rgb=($(hex_to_rgb "$optimized_color2"))
    local final_contrast=$(contrast_ratio ${final_color1_rgb[0]} ${final_color1_rgb[1]} ${final_color1_rgb[2]} ${final_color2_rgb[0]} ${final_color2_rgb[1]} ${final_color2_rgb[2]})
    
    debug_log "Optimized contrast: $final_contrast ($optimized_color1 vs $optimized_color2)"
    
    echo "$optimized_color1 $optimized_color2"
}

# Main optimization function
optimize_palette() {
    local harmony_analysis_file="$1"
    local original_colors_file="$2"
    local output_file="$3"
    
    log_message "Starting palette optimization"
    
    # Extract colors from original file
    if command -v jq >/dev/null 2>&1; then
        local primary=$(jq -r '.colors.dark.primary // .primary // ""' "$original_colors_file")
        local surface=$(jq -r '.colors.dark.surface // .surface // ""' "$original_colors_file")
        local on_surface=$(jq -r '.colors.dark.on_surface // .on_surface // ""' "$original_colors_file")
        local secondary=$(jq -r '.colors.dark.secondary // .secondary // ""' "$original_colors_file")
        local on_primary=$(jq -r '.colors.dark.on_primary // .on_primary // ""' "$original_colors_file")
    else
        error_exit "jq is required for palette optimization"
    fi
    
    # Extract current scores from harmony analysis
    local text_contrast_score=$(jq -r '.harmony_analysis.text_contrast.accessibility_score // 0' "$harmony_analysis_file")
    local palette_score=$(jq -r '.palette_score // 0' "$harmony_analysis_file")
    
    debug_log "Current scores - Text contrast: $text_contrast_score, Palette: $palette_score"
    
    # Initialize optimized colors with originals
    local opt_primary="$primary"
    local opt_surface="$surface"
    local opt_on_surface="$on_surface"
    local opt_secondary="$secondary"
    local opt_on_primary="$on_primary"
    
    local optimizations_made=()
    
    # Optimize text contrast if needed
    if [[ -n "$on_surface" && "$on_surface" != "null" ]] && (( $(echo "$text_contrast_score < 80" | bc -l) )); then
        log_message "Optimizing text contrast (current score: $text_contrast_score)"
        local optimized_pair=($(optimize_contrast "$surface" "$on_surface" "$TARGET_CONTRAST" "second"))
        opt_surface="${optimized_pair[0]}"
        opt_on_surface="${optimized_pair[1]}"
        optimizations_made+=("text_contrast")
    fi
    
    # Optimize primary-on_primary contrast if needed
    if [[ -n "$on_primary" && "$on_primary" != "null" ]]; then
        local primary_rgb=($(hex_to_rgb "$primary"))
        local on_primary_rgb=($(hex_to_rgb "$on_primary"))
        local primary_contrast=$(contrast_ratio ${primary_rgb[0]} ${primary_rgb[1]} ${primary_rgb[2]} ${on_primary_rgb[0]} ${on_primary_rgb[1]} ${on_primary_rgb[2]})
        
        if (( $(echo "$primary_contrast < $MIN_CONTRAST_AA" | bc -l) )); then
            log_message "Optimizing primary-on_primary contrast (current: $primary_contrast)"
            local optimized_pair=($(optimize_contrast "$opt_primary" "$on_primary" "$TARGET_CONTRAST" "second"))
            opt_primary="${optimized_pair[0]}"
            opt_on_primary="${optimized_pair[1]}"
            optimizations_made+=("primary_contrast")
        fi
    fi
    
    # Generate optimized color JSON
    local optimization_timestamp=$(date -Iseconds)
    local optimized_file="$output_file"
    
    # Create optimized JSON based on original structure
    if command -v jq >/dev/null 2>&1; then
        jq --arg primary "$opt_primary" \
           --arg surface "$opt_surface" \
           --arg on_surface "$opt_on_surface" \
           --arg secondary "$opt_secondary" \
           --arg on_primary "$opt_on_primary" \
           --arg timestamp "$optimization_timestamp" \
           --argjson optimizations "$(printf '%s\n' "${optimizations_made[@]}" | jq -R . | jq -s .)" \
           '
           .colors.dark.primary = $primary |
           .colors.dark.surface = $surface |
           .colors.dark.on_surface = $on_surface |
           .colors.dark.secondary = $secondary |
           .colors.dark.on_primary = $on_primary |
           .optimization_metadata = {
             "timestamp": $timestamp,
             "optimizations_applied": $optimizations,
             "original_file": "'"$original_colors_file"'",
             "accessibility_target": "WCAG_AAA"
           }
           ' "$original_colors_file" > "$optimized_file"
    fi
    
    # Generate optimization report
    local report_file="${output_file%.*}-report.json"
    cat > "$report_file" << EOF
{
  "optimization_timestamp": "$optimization_timestamp",
  "original_colors": {
    "primary": "$primary",
    "surface": "$surface",
    "on_surface": "$on_surface",
    "secondary": "$secondary",
    "on_primary": "$on_primary"
  },
  "optimized_colors": {
    "primary": "$opt_primary",
    "surface": "$opt_surface",
    "on_surface": "$opt_on_surface",
    "secondary": "$opt_secondary",
    "on_primary": "$opt_on_primary"
  },
  "optimizations_applied": $(printf '%s\n' "${optimizations_made[@]}" | jq -R . | jq -s .),
  "optimization_summary": {
    "changes_made": ${#optimizations_made[@]},
    "accessibility_target": "WCAG_AAA",
    "target_contrast_ratio": $TARGET_CONTRAST
  }
}
EOF
    
    local changes_count=${#optimizations_made[@]}
    if [[ $changes_count -gt 0 ]]; then
        log_message "Palette optimization complete. Applied $changes_count optimizations: ${optimizations_made[*]}"
    else
        log_message "Palette optimization complete. No changes needed - colors already optimal!"
    fi
    
    log_message "Optimized colors saved to: $optimized_file"
    log_message "Optimization report saved to: $report_file"
    
    echo "$optimized_file"
}

# Main function
main() {
    local harmony_analysis_file="$1"
    local original_colors_file="$2"
    local output_file="${3:-/tmp/optimized-colors.json}"
    
    log_message "Accessibility Optimizer started"
    debug_log "Harmony analysis: $harmony_analysis_file"
    debug_log "Original colors: $original_colors_file"
    debug_log "Output file: $output_file"
    
    # Validate inputs
    [[ ! -f "$harmony_analysis_file" ]] && error_exit "Harmony analysis file not found: $harmony_analysis_file"
    [[ ! -f "$original_colors_file" ]] && error_exit "Original colors file not found: $original_colors_file"
    
    # Verify files are valid JSON
    if command -v jq >/dev/null 2>&1; then
        jq empty "$harmony_analysis_file" 2>/dev/null || error_exit "Invalid JSON in harmony analysis file"
        jq empty "$original_colors_file" 2>/dev/null || error_exit "Invalid JSON in original colors file"
    else
        error_exit "jq is required for accessibility optimization"
    fi
    
    # Optimize the color palette
    local result=$(optimize_palette "$harmony_analysis_file" "$original_colors_file" "$output_file")
    
    log_message "Accessibility Optimizer completed successfully"
    echo "$result"
}

# Script usage
show_usage() {
    cat << EOF
Usage: $0 <harmony_analysis_file> <original_colors_file> [output_file]

Accessibility Optimizer - Phase 1B AI Enhancement

Optimizes colors for better accessibility while maintaining harmony.
Targets WCAG AAA compliance (7.0+ contrast ratio).

Arguments:
  harmony_analysis_file    Path to color harmony analysis JSON
  original_colors_file     Path to original matugen JSON colors
  output_file              Optional: Path for optimized colors (default: /tmp/optimized-colors.json)

Example:
  $0 /tmp/color-harmony-analysis.json /tmp/test-colors.json
  $0 /tmp/harmony.json /tmp/colors.json /tmp/my-optimized.json

Output:
  - Optimized color palette in /tmp/optimized-colors.json
  - Optimization report in /tmp/accessibility-optimization-report.json
  - Maintains color harmony while improving accessibility

EOF
}

# Entry point
if [[ $# -lt 2 ]]; then
    show_usage
    exit 1
fi

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Run main function
main "$1" "$2" "$3" 