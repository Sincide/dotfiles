#!/bin/bash

# =============================================================================
# 🎨 AI COLOR PIPELINE - INTEGRATION WRAPPER
# =============================================================================
# Integrates AI-enhanced color intelligence with existing theming system
# Called by wallpaper-theme-changer-optimized.sh

set -e

WALLPAPER_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Load AI configuration
source "$SCRIPT_DIR/ai-config.sh"
load_ai_config

# Logging function
log_pipeline() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] AI-Pipeline: $message" >&2
}

# Validate input
if [[ -z "$WALLPAPER_PATH" ]]; then
    log_pipeline "ERROR" "No wallpaper path provided"
    echo "Usage: $0 <wallpaper_path>"
    exit 1
fi

if [[ ! -f "$WALLPAPER_PATH" ]]; then
    log_pipeline "ERROR" "Wallpaper file not found: $WALLPAPER_PATH"
    exit 1
fi

log_pipeline "INFO" "Starting AI color pipeline for: $WALLPAPER_PATH"
log_pipeline "INFO" "AI Mode: $AI_MODE"

# Performance timing
start_time=$(date +%s.%N)

# Step 1: Generate base colors with matugen
log_pipeline "INFO" "Generating base colors with matugen..."
if command -v matugen >/dev/null 2>&1; then
    if matugen image "$WALLPAPER_PATH" --config ~/.config/matugen/config.toml >/dev/null 2>&1; then
        log_pipeline "INFO" "Base matugen colors generated successfully"
        
        # Get the generated colors file
        MATUGEN_OUTPUT="/tmp/test-matugen-colors.json"
        
        # Check if matugen created the expected output (adjust path as needed)
        if [[ -f "$HOME/.cache/matugen/colors.json" ]]; then
            cp "$HOME/.cache/matugen/colors.json" "$MATUGEN_OUTPUT"
        elif [[ -f "/tmp/matugen_colors.json" ]]; then
            cp "/tmp/matugen_colors.json" "$MATUGEN_OUTPUT"
        else
            log_pipeline "WARN" "Matugen output location unknown, generating test colors"
            # Create a basic color structure for AI processing
            cat > "$MATUGEN_OUTPUT" << 'EOF'
{
  "colors": {
    "dark": {
      "primary": "#82d3e2",
      "surface": "#0e1416",
      "on_surface": "#dee3e5",
      "secondary": "#b1cbd0"
    }
  }
}
EOF
        fi
    else
        log_pipeline "ERROR" "Matugen failed"
        exit 1
    fi
else
    log_pipeline "ERROR" "Matugen not found"
    exit 1
fi

# Step 2: Apply AI enhancement based on configuration
case "$AI_MODE" in
    "enhanced")
        log_pipeline "INFO" "Running Enhanced AI Intelligence..."
        if bash "$SCRIPT_DIR/enhanced-color-intelligence.sh" "$WALLPAPER_PATH" "$MATUGEN_OUTPUT" "/tmp/ai-enhanced-result.json"; then
            
            # Extract AI-optimized colors and update matugen output
            if [[ -f "/tmp/ai-enhanced-result.json" ]]; then
                AI_PRIMARY=$(jq -r '.enhanced_intelligence.primary_color' /tmp/ai-enhanced-result.json)
                AI_ACCENT=$(jq -r '.enhanced_intelligence.accent_color' /tmp/ai-enhanced-result.json)
                AI_STRATEGY=$(jq -r '.enhanced_intelligence.strategy' /tmp/ai-enhanced-result.json)
                
                log_pipeline "INFO" "AI Strategy: $AI_STRATEGY"
                log_pipeline "INFO" "AI Primary: $AI_PRIMARY"
                log_pipeline "INFO" "AI Accent: $AI_ACCENT"
                
                # Update the matugen colors with AI suggestions
                if [[ -n "$AI_PRIMARY" && "$AI_PRIMARY" != "null" && "$AI_PRIMARY" != "" ]]; then
                    jq --arg primary "$AI_PRIMARY" '.colors.dark.primary = $primary' "$MATUGEN_OUTPUT" > /tmp/ai-updated-colors.json
                    mv /tmp/ai-updated-colors.json "$MATUGEN_OUTPUT"
                fi
                
                if [[ -n "$AI_ACCENT" && "$AI_ACCENT" != "null" && "$AI_ACCENT" != "" ]]; then
                    jq --arg accent "$AI_ACCENT" '.colors.dark.secondary = $accent' "$MATUGEN_OUTPUT" > /tmp/ai-updated-colors.json
                    mv /tmp/ai-updated-colors.json "$MATUGEN_OUTPUT"
                fi
            fi
            
            log_pipeline "INFO" "Enhanced AI intelligence applied successfully"
        else
            log_pipeline "WARN" "Enhanced AI failed, using standard colors"
        fi
        ;;
        
    "vision")
        log_pipeline "INFO" "Running Vision AI Only..."
        if bash "$SCRIPT_DIR/vision-analyzer.sh" "$WALLPAPER_PATH" "/tmp/vision-result.json"; then
            if [[ -f "/tmp/vision-result.json" ]]; then
                VISION_PRIMARY=$(jq -r '.primary_color' /tmp/vision-result.json)
                VISION_ACCENT=$(jq -r '.accent_color' /tmp/vision-result.json)
                VISION_CATEGORY=$(jq -r '.category' /tmp/vision-result.json)
                
                log_pipeline "INFO" "Vision Category: $VISION_CATEGORY"
                log_pipeline "INFO" "Vision Primary: $VISION_PRIMARY"
                log_pipeline "INFO" "Vision Accent: $VISION_ACCENT"
                
                # Update colors if valid
                if [[ -n "$VISION_PRIMARY" && "$VISION_PRIMARY" != "null" && "$VISION_PRIMARY" != "#000000" && ${#VISION_PRIMARY} -eq 7 ]]; then
                    jq --arg primary "$VISION_PRIMARY" '.colors.dark.primary = $primary' "$MATUGEN_OUTPUT" > /tmp/ai-updated-colors.json
                    mv /tmp/ai-updated-colors.json "$MATUGEN_OUTPUT"
                fi
                
                if [[ -n "$VISION_ACCENT" && "$VISION_ACCENT" != "null" && "$VISION_ACCENT" != "#000000" && ${#VISION_ACCENT} -eq 7 ]]; then
                    jq --arg accent "$VISION_ACCENT" '.colors.dark.secondary = $accent' "$MATUGEN_OUTPUT" > /tmp/ai-updated-colors.json
                    mv /tmp/ai-updated-colors.json "$MATUGEN_OUTPUT"
                fi
            fi
            
            log_pipeline "INFO" "Vision AI applied successfully"
        else
            log_pipeline "WARN" "Vision AI failed, using standard colors"
        fi
        ;;
        
    "mathematical")
        log_pipeline "INFO" "Running Mathematical AI Only..."
        if bash "$SCRIPT_DIR/color-harmony-analyzer.sh" "$MATUGEN_OUTPUT" "/tmp/harmony-result.json"; then
            if bash "$SCRIPT_DIR/accessibility-optimizer.sh" "/tmp/harmony-result.json" "$MATUGEN_OUTPUT" "/tmp/math-result.json"; then
                # Use the mathematically optimized colors
                if [[ -f "/tmp/math-result.json" ]]; then
                    cp "/tmp/math-result.json" "$MATUGEN_OUTPUT"
                    log_pipeline "INFO" "Mathematical optimization applied successfully"
                else
                    log_pipeline "WARN" "Mathematical result file not found"
                fi
            else
                log_pipeline "WARN" "Mathematical optimization failed"
            fi
        else
            log_pipeline "WARN" "Mathematical analysis failed, using standard colors"
        fi
        ;;
        
    "disabled")
        log_pipeline "INFO" "AI disabled, using standard matugen colors"
        ;;
        
    *)
        log_pipeline "WARN" "Unknown AI mode: $AI_MODE, using standard colors"
        ;;
esac

# Step 3: Ensure output compatibility with existing system
# Copy the final colors to the expected location for the theme changer
if [[ -f "$MATUGEN_OUTPUT" ]]; then
    # Make sure the output is in the format your theme system expects
    cp "$MATUGEN_OUTPUT" "/tmp/ai-optimized-colors.json"
    
    # Also update the standard matugen cache location if it exists
    if [[ -d "$HOME/.cache/matugen" ]]; then
        cp "$MATUGEN_OUTPUT" "$HOME/.cache/matugen/colors.json"
    fi
    
    log_pipeline "INFO" "AI-optimized colors saved to: /tmp/ai-optimized-colors.json"
    

    
else
    log_pipeline "ERROR" "No color output generated"
    exit 1
fi

# Performance reporting
end_time=$(date +%s.%N)
duration=$(echo "$end_time - $start_time" | bc -l)
log_pipeline "INFO" "AI color pipeline completed in ${duration}s"

# Show AI notification if enabled
if [[ "$SHOW_AI_NOTIFICATIONS" == "true" ]] && command -v notify-send >/dev/null 2>&1; then
    case "$AI_MODE" in
        "enhanced")
            notify-send "🧠 AI Theming" "Enhanced intelligence applied in ${duration}s" -t 3000
            ;;
        "vision")
            notify-send "👁️ AI Theming" "Vision analysis applied in ${duration}s" -t 3000
            ;;
        "mathematical")
            notify-send "🔢 AI Theming" "Mathematical optimization applied in ${duration}s" -t 3000
            ;;
    esac
fi

# Output the final colors file path for the theme changer
echo "/tmp/ai-optimized-colors.json" 