#!/bin/bash

# Color Harmony Analyzer - Phase 1 AI Enhancement
# Purpose: Analyze and optimize color harmony from matugen JSON output
# Input: JSON color data from matugen
# Output: Optimized color palette with harmony scores

# Safety: Pure mathematics, no external dependencies, easy rollback

set -euo pipefail

# Configuration
SCRIPT_NAME="color-harmony-analyzer"
LOG_FILE="/tmp/${SCRIPT_NAME}.log"
DEBUG="${DEBUG:-false}"

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

# Color utility functions
hex_to_rgb() {
    local hex="$1"
    # Remove # if present
    hex="${hex#\#}"
    
    # Extract RGB components
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    
    echo "$r $g $b"
}

rgb_to_hsl() {
    local r=$1 g=$2 b=$3
    
    # Normalize RGB to 0-1
    r=$(echo "scale=6; $r / 255" | bc)
    g=$(echo "scale=6; $g / 255" | bc)
    b=$(echo "scale=6; $b / 255" | bc)
    
    # Find min and max
    local max=$(echo "$r $g $b" | tr ' ' '\n' | sort -nr | head -1)
    local min=$(echo "$r $g $b" | tr ' ' '\n' | sort -n | head -1)
    
    # Calculate lightness
    local l=$(echo "scale=6; ($max + $min) / 2" | bc)
    
    # Calculate saturation and hue
    local delta=$(echo "scale=6; $max - $min" | bc)
    
    if (( $(echo "$delta == 0" | bc -l) )); then
        # Achromatic (gray)
        echo "0 0 $(echo "scale=2; $l * 100" | bc)"
    else
        # Chromatic
        local s
        if (( $(echo "$l < 0.5" | bc -l) )); then
            s=$(echo "scale=6; $delta / ($max + $min)" | bc)
        else
            s=$(echo "scale=6; $delta / (2 - $max - $min)" | bc)
        fi
        
        # Calculate hue
        local h
        if (( $(echo "$max == $r" | bc -l) )); then
            h=$(echo "scale=6; (($g - $b) / $delta) % 6" | bc)
        elif (( $(echo "$max == $g" | bc -l) )); then
            h=$(echo "scale=6; ($b - $r) / $delta + 2" | bc)
        else
            h=$(echo "scale=6; ($r - $g) / $delta + 4" | bc)
        fi
        
        h=$(echo "scale=2; $h * 60" | bc)
        if (( $(echo "$h < 0" | bc -l) )); then
            h=$(echo "scale=2; $h + 360" | bc)
        fi
        
        echo "$(echo "scale=2; $h" | bc) $(echo "scale=2; $s * 100" | bc) $(echo "scale=2; $l * 100" | bc)"
    fi
}

# Calculate color distance (Delta E approximation)
color_distance() {
    local r1=$1 g1=$2 b1=$3
    local r2=$4 g2=$5 b2=$6
    
    # Simple Euclidean distance in RGB space
    local dr=$((r1 - r2))
    local dg=$((g1 - g2))
    local db=$((b1 - b2))
    
    echo "scale=2; sqrt($dr*$dr + $dg*$dg + $db*$db)" | bc
}

# Calculate contrast ratio (WCAG)
contrast_ratio() {
    local r1=$1 g1=$2 b1=$3
    local r2=$4 g2=$5 b2=$6
    
    # Calculate relative luminance
    local lum1=$(relative_luminance $r1 $g1 $b1)
    local lum2=$(relative_luminance $r2 $g2 $b2)
    
    # Ensure lighter color is first
    if (( $(echo "$lum1 < $lum2" | bc -l) )); then
        local temp=$lum1
        lum1=$lum2
        lum2=$temp
    fi
    
    # Calculate contrast ratio
    echo "scale=2; ($lum1 + 0.05) / ($lum2 + 0.05)" | bc
}

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

# Analyze color harmony
analyze_harmony() {
    local primary_hex="$1"
    local secondary_hex="$2"
    
    debug_log "Analyzing harmony between $primary_hex and $secondary_hex"
    
    # Convert to RGB
    local primary_rgb=($(hex_to_rgb "$primary_hex"))
    local secondary_rgb=($(hex_to_rgb "$secondary_hex"))
    
    # Convert to HSL
    local primary_hsl=($(rgb_to_hsl ${primary_rgb[0]} ${primary_rgb[1]} ${primary_rgb[2]}))
    local secondary_hsl=($(rgb_to_hsl ${secondary_rgb[0]} ${secondary_rgb[1]} ${secondary_rgb[2]}))
    
    # Calculate hue difference
    local hue_diff=$(echo "scale=2; (${primary_hsl[0]} - ${secondary_hsl[0]}) % 360" | bc)
    if (( $(echo "$hue_diff < 0" | bc -l) )); then
        hue_diff=$(echo "scale=2; $hue_diff + 360" | bc)
    fi
    
    # Determine harmony type
    local harmony_type="custom"
    local harmony_score=50
    
    if (( $(echo "$hue_diff >= 0 && $hue_diff <= 30" | bc -l) )); then
        harmony_type="analogous"
        harmony_score=85
    elif (( $(echo "$hue_diff >= 150 && $hue_diff <= 210" | bc -l) )); then
        harmony_type="complementary"
        harmony_score=90
    elif (( $(echo "$hue_diff >= 110 && $hue_diff <= 130" | bc -l) )); then
        harmony_type="triadic"
        harmony_score=80
    elif (( $(echo "$hue_diff >= 80 && $hue_diff <= 100" | bc -l) )); then
        harmony_type="split_complementary"
        harmony_score=75
    fi
    
    # Calculate contrast ratio
    local contrast=$(contrast_ratio ${primary_rgb[0]} ${primary_rgb[1]} ${primary_rgb[2]} ${secondary_rgb[0]} ${secondary_rgb[1]} ${secondary_rgb[2]})
    
    # Accessibility scoring
    local accessibility_score=0
    if (( $(echo "$contrast >= 7" | bc -l) )); then
        accessibility_score=100  # WCAG AAA
    elif (( $(echo "$contrast >= 4.5" | bc -l) )); then
        accessibility_score=80   # WCAG AA
    elif (( $(echo "$contrast >= 3" | bc -l) )); then
        accessibility_score=60   # WCAG AA Large
    else
        accessibility_score=30   # Poor contrast
    fi
    
    # Overall score (weighted average)
    local overall_score=$(echo "scale=0; ($harmony_score * 0.6 + $accessibility_score * 0.4)" | bc)
    
    debug_log "Harmony: $harmony_type (${harmony_score}), Contrast: ${contrast} (${accessibility_score}), Overall: ${overall_score}"
    
    echo "$harmony_type $harmony_score $contrast $accessibility_score $overall_score"
}

# Main color analysis function
analyze_color_palette() {
    local json_file="$1"
    local output_file="$2"
    
    log_message "Starting color palette analysis"
    
    # Check if jq is available for better JSON parsing
    if command -v jq >/dev/null 2>&1; then
        debug_log "Using jq for JSON parsing"
        
        # Extract key colors using jq
        local primary=$(jq -r '.colors.dark.primary // .primary // ""' "$json_file" 2>/dev/null)
        local surface=$(jq -r '.colors.dark.surface // .surface // ""' "$json_file" 2>/dev/null)
        local on_surface=$(jq -r '.colors.dark.on_surface // .on_surface // ""' "$json_file" 2>/dev/null)
        local secondary=$(jq -r '.colors.dark.secondary // .secondary // ""' "$json_file" 2>/dev/null)
        
    else
        debug_log "Using fallback JSON parsing"
        
        # Fallback parsing without jq
        local primary=$(grep -o '"primary"[[:space:]]*:[[:space:]]*"[^"]*"' "$json_file" | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
        local surface=$(grep -o '"surface"[[:space:]]*:[[:space:]]*"[^"]*"' "$json_file" | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
        local on_surface=$(grep -o '"on_surface"[[:space:]]*:[[:space:]]*"[^"]*"' "$json_file" | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
        local secondary=$(grep -o '"secondary"[[:space:]]*:[[:space:]]*"[^"]*"' "$json_file" | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
    fi
    
    # Validate extracted colors
    [[ -z "$primary" || "$primary" == "null" ]] && error_exit "Failed to extract primary color"
    [[ -z "$surface" || "$surface" == "null" ]] && error_exit "Failed to extract surface color"
    
    debug_log "Extracted colors - Primary: $primary, Surface: $surface, On Surface: $on_surface, Secondary: $secondary"
    
    # Analyze primary relationships
    local primary_surface_analysis=($(analyze_harmony "$primary" "$surface"))
    local primary_secondary_analysis=()
    if [[ -n "$secondary" && "$secondary" != "null" ]]; then
        primary_secondary_analysis=($(analyze_harmony "$primary" "$secondary"))
    fi
    
    # Analyze text contrast
    local text_contrast_analysis=()
    if [[ -n "$on_surface" && "$on_surface" != "null" ]]; then
        text_contrast_analysis=($(analyze_harmony "$surface" "$on_surface"))
    fi
    
    # Calculate overall palette score
    local palette_score=75  # Base score
    
    # Adjust based on primary-surface harmony
    local harmony_bonus=$(echo "scale=0; ${primary_surface_analysis[1]} * 0.3" | bc)
    palette_score=$(echo "scale=0; $palette_score + $harmony_bonus" | bc)
    
    # Adjust based on accessibility
    if [[ ${#text_contrast_analysis[@]} -gt 0 ]]; then
        local accessibility_bonus=$(echo "scale=0; ${text_contrast_analysis[3]} * 0.2" | bc)
        palette_score=$(echo "scale=0; $palette_score + $accessibility_bonus" | bc)
    fi
    
    # Cap at 100
    if (( $(echo "$palette_score > 100" | bc -l) )); then
        palette_score=100
    fi
    
    # Generate analysis report
    cat > "$output_file" << EOF
{
  "analysis_timestamp": "$(date -Iseconds)",
  "input_colors": {
    "primary": "$primary",
    "surface": "$surface",
    "on_surface": "$on_surface",
    "secondary": "$secondary"
  },
  "harmony_analysis": {
    "primary_surface": {
      "type": "${primary_surface_analysis[0]}",
      "harmony_score": ${primary_surface_analysis[1]},
      "contrast_ratio": ${primary_surface_analysis[2]},
      "accessibility_score": ${primary_surface_analysis[3]},
      "overall_score": ${primary_surface_analysis[4]}
    }$(if [[ ${#primary_secondary_analysis[@]} -gt 0 ]]; then echo ",
    \"primary_secondary\": {
      \"type\": \"${primary_secondary_analysis[0]}\",
      \"harmony_score\": ${primary_secondary_analysis[1]},
      \"contrast_ratio\": ${primary_secondary_analysis[2]},
      \"accessibility_score\": ${primary_secondary_analysis[3]},
      \"overall_score\": ${primary_secondary_analysis[4]}
    }"; fi)$(if [[ ${#text_contrast_analysis[@]} -gt 0 ]]; then echo ",
    \"text_contrast\": {
      \"type\": \"${text_contrast_analysis[0]}\",
      \"harmony_score\": ${text_contrast_analysis[1]},
      \"contrast_ratio\": ${text_contrast_analysis[2]},
      \"accessibility_score\": ${text_contrast_analysis[3]},
      \"overall_score\": ${text_contrast_analysis[4]}
    }"; fi)
  },
  "palette_score": $palette_score,
  "recommendations": {
    "harmony_type": "${primary_surface_analysis[0]}",
    "accessibility_level": "$(if [[ ${#text_contrast_analysis[@]} -gt 0 && $(echo "${text_contrast_analysis[2]} >= 7" | bc -l) == 1 ]]; then echo "WCAG_AAA"; elif [[ ${#text_contrast_analysis[@]} -gt 0 && $(echo "${text_contrast_analysis[2]} >= 4.5" | bc -l) == 1 ]]; then echo "WCAG_AA"; else echo "Needs_Improvement"; fi)",
    "optimizations": []
  }
}
EOF
    
    log_message "Color harmony analysis complete. Palette score: $palette_score/100"
    log_message "Analysis saved to: $output_file"
    
    # Return the analysis file path
    echo "$output_file"
}

# Main function
main() {
    local input_file="$1"
    local output_file="${2:-/tmp/color-harmony-analysis.json}"
    
    log_message "Color Harmony Analyzer started"
    debug_log "Input file: $input_file"
    debug_log "Output file: $output_file"
    
    # Validate input
    [[ ! -f "$input_file" ]] && error_exit "Input file not found: $input_file"
    
    # Verify it's valid JSON
    if command -v jq >/dev/null 2>&1; then
        jq empty "$input_file" 2>/dev/null || error_exit "Invalid JSON in input file"
    fi
    
    # Analyze the color palette (pass output file)
    local result=$(analyze_color_palette "$input_file" "$output_file")
    
    log_message "Color Harmony Analyzer completed successfully"
    echo "$output_file"
}

# Script usage
show_usage() {
    cat << EOF
Usage: $0 <matugen_json_file> [output_file]

Color Harmony Analyzer - Phase 1 AI Enhancement

Analyzes color harmony and accessibility from matugen JSON output.
Provides optimization suggestions and scoring.

Arguments:
  matugen_json_file    Path to JSON file from matugen
  output_file          Optional: Path for analysis output (default: /tmp/color-harmony-analysis.json)

Example:
  $0 /tmp/matugen_colors.json
  $0 /tmp/matugen_colors.json /tmp/my-analysis.json

Output:
  - Harmony analysis in /tmp/color-harmony-analysis.json
  - Optimized color recommendations
  - Accessibility scoring and compliance information

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
main "$1" "$2" 