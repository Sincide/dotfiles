#!/bin/bash

# =============================================================================
# 🧠 VISION ANALYZER - AI WALLPAPER INTELLIGENCE
# =============================================================================
# Analyzes wallpaper content using ollama vision for intelligent theming
# Part of: AI-Enhanced Dynamic Theming System
# Phase: 2B - Vision Analyzer Script

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VISION_LOG="/tmp/vision-analyzer.log"
PERFORMANCE_LOG="/tmp/vision-performance.log"

# Vision analysis configuration
VISION_MODEL="llava-llama3:8b"
VISION_TIMEOUT="10"
MAX_RETRIES="2"

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
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+[%s] %H:%M:%S')
    echo "$timestamp - $message" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$VISION_LOG"
}

# Check model warmth (if already loaded in memory)
check_model_warmth() {
    if ollama ps | grep -q "$VISION_MODEL"; then
        log_message "INFO" "🔥 Model is already warm in memory - expecting fast processing"
        return 0
    else
        log_message "INFO" "❄️  Model needs loading - may take 8-9s for first analysis"
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    # Check ollama
    if ! command -v ollama &> /dev/null; then
        log_message "ERROR" "ollama not found - vision analysis disabled"
        return 1
    fi
    
    # Check if vision model is available
    if ! ollama list | grep -q "$VISION_MODEL"; then
        log_message "ERROR" "Vision model '$VISION_MODEL' not available - run: ollama pull $VISION_MODEL"
        return 1
    fi
    
    # Check jq for JSON processing
    if ! command -v jq &> /dev/null; then
        log_message "WARN" "jq not found - using fallback JSON processing"
    fi
    
    # Check model warmth for performance prediction
    check_model_warmth
    
    return 0
}

# Analyze wallpaper content using vision AI
analyze_wallpaper_content() {
    local wallpaper_path="$1"
    local output_file="$2"
    
    if [[ ! -f "$wallpaper_path" ]]; then
        log_message "ERROR" "Wallpaper file not found: $wallpaper_path"
        return 1
    fi
    
    # Convert to absolute path for ollama compatibility
    local absolute_wallpaper_path="$(realpath "$wallpaper_path")"
    log_message "INFO" "Analyzing wallpaper: $(basename "$wallpaper_path")"
    log_message "DEBUG" "Absolute path: $absolute_wallpaper_path"
    
    # Optimized vision analysis prompt - flexible and clear
    local vision_prompt="Look at this image and return only JSON analysis:
{\"category\":\"nature or abstract or gaming or minimal\",\"mood\":\"calm or energetic or dark or bright\",\"primary_color\":\"#hexcolor\",\"accent_color\":\"#hexcolor\",\"style\":\"light or dark\"}

Analyze what you actually see and give real hex color codes."
    
    # Run vision analysis with timeout and retries
    local attempt=1
    local analysis_result=""
    
    while [[ $attempt -le $MAX_RETRIES ]]; do
        log_message "INFO" "Vision analysis attempt $attempt/$MAX_RETRIES"
        
        start_timer
        
        # Run ollama with timeout using absolute path
        if analysis_result=$(timeout "$VISION_TIMEOUT" ollama run "$VISION_MODEL" "$vision_prompt" "$absolute_wallpaper_path" 2>/dev/null); then
            local duration=$(end_timer)
            echo "$duration" >> "$PERFORMANCE_LOG"
            log_message "INFO" "Vision analysis completed in ${duration}s"
            break
        else
            local duration=$(end_timer)
            log_message "WARN" "Vision analysis attempt $attempt failed (${duration}s)"
            ((attempt++))
            
            if [[ $attempt -le $MAX_RETRIES ]]; then
                sleep 1  # Brief pause before retry
            fi
        fi
    done
    
    # Check if analysis succeeded
    if [[ -z "$analysis_result" ]] || [[ $attempt -gt $MAX_RETRIES ]]; then
        log_message "ERROR" "Vision analysis failed after $MAX_RETRIES attempts"
        
        # Create fallback analysis
        create_fallback_analysis "$wallpaper_path" "$output_file"
        return 1
    fi
    
    # Clean and validate JSON response - improved extraction
    log_message "DEBUG" "Raw response length: ${#analysis_result} characters"
    
    # Remove ollama metadata and extract JSON
    local cleaned_response=$(echo "$analysis_result" | sed '/^Added image/d')
    
    # Try multiple JSON extraction methods
    local cleaned_json=""
    
    # Method 1: Look for complete JSON block (single line)
    cleaned_json=$(echo "$cleaned_response" | grep -E '^\{.*\}$' | head -1)
    
    # Method 2: Extract JSON from multiline (remove newlines, extract braces)
    if [[ -z "$cleaned_json" ]]; then
        cleaned_json=$(echo "$cleaned_response" | tr -d '\n' | grep -oE '\{[^}]*"theming"[^}]*\}' | head -1)
    fi
    
    # Method 3: More aggressive extraction - find any JSON-like structure
    if [[ -z "$cleaned_json" ]]; then
        cleaned_json=$(echo "$cleaned_response" | sed -n '/^{/,/^}/p' | tr '\n' ' ')
    fi
    
    # Method 4: Extract everything between first { and last }
    if [[ -z "$cleaned_json" ]]; then
        local start_brace=$(echo "$cleaned_response" | grep -n '{' | head -1 | cut -d: -f1)
        local end_brace=$(echo "$cleaned_response" | grep -n '}' | tail -1 | cut -d: -f1)
        if [[ -n "$start_brace" ]] && [[ -n "$end_brace" ]]; then
            cleaned_json=$(echo "$cleaned_response" | sed -n "${start_brace},${end_brace}p" | tr '\n' ' ')
        fi
    fi
    
    log_message "DEBUG" "Extracted JSON: ${cleaned_json:0:100}..."
    
    # Validate JSON structure
    if command -v jq &> /dev/null; then
        if echo "$cleaned_json" | jq . > /dev/null 2>&1; then
            echo "$cleaned_json" | jq . > "$output_file"
            log_message "INFO" "Vision analysis saved to: $output_file"
            return 0
        else
            log_message "WARN" "Invalid JSON from vision analysis, creating fallback"
        fi
    else
        # Basic JSON validation without jq
        if [[ "$cleaned_json" =~ ^\{.*\}$ ]] && [[ "$cleaned_json" =~ \"content\" ]] && [[ "$cleaned_json" =~ \"theming\" ]]; then
            echo "$cleaned_json" > "$output_file"
            log_message "INFO" "Vision analysis saved to: $output_file"
            return 0
        else
            log_message "WARN" "Malformed JSON from vision analysis, creating fallback"
        fi
    fi
    
    # If we reach here, JSON was invalid - create fallback
    create_fallback_analysis "$wallpaper_path" "$output_file"
    return 1
}

# Create fallback analysis when vision fails
create_fallback_analysis() {
    local wallpaper_path="$1"
    local output_file="$2"
    
    log_message "INFO" "Creating fallback analysis for: $(basename "$wallpaper_path")"
    
    # Determine basic category from file path
    local category="abstract"
    if [[ "$wallpaper_path" =~ nature ]]; then
        category="nature"
    elif [[ "$wallpaper_path" =~ gaming ]]; then
        category="gaming"
    elif [[ "$wallpaper_path" =~ minimal ]]; then
        category="minimal"
    elif [[ "$wallpaper_path" =~ dark ]]; then
        category="abstract"
    fi
    
    # Generate fallback JSON
    cat > "$output_file" << EOF
{
  "content": {
    "category": "$category",
    "subjects": ["unknown"],
    "style": "unknown"
  },
  "mood": {
    "energy": "moderate",
    "tone": "neutral", 
    "atmosphere": "professional"
  },
  "colors": {
    "dominant": ["#808080", "#606060", "#404040"],
    "accent": ["#606060", "#404040"],
    "temperature": "neutral"
  },
  "theming": {
    "primary_suggestion": "#606060",
    "accent_suggestion": "#404040",
    "background_style": "auto",
    "contrast_level": "medium"
  },
  "analysis_source": "fallback",
  "vision_available": false
}
EOF
    
    log_message "INFO" "Fallback analysis created"
}

# Extract theme recommendations from vision analysis
extract_theme_recommendations() {
    local vision_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$vision_file" ]]; then
        log_message "ERROR" "Vision analysis file not found: $vision_file"
        return 1
    fi
    
    log_message "INFO" "Extracting theme recommendations"
    
    # Extract key theming information - adapted for simplified JSON format
    if command -v jq &> /dev/null; then
        # Try new simplified format first
        local primary_color=$(jq -r '.primary_color // .theming.primary_suggestion // "#606060"' "$vision_file")
        local accent_color=$(jq -r '.accent_color // .theming.accent_suggestion // "#404040"' "$vision_file")
        local category=$(jq -r '.category // .content.category // "abstract"' "$vision_file")
        local mood=$(jq -r '.mood // .mood.energy // "moderate"' "$vision_file")
        local style=$(jq -r '.style // .theming.background_style // "auto"' "$vision_file")
        
        # Set defaults for missing fields
        local background_style="auto"
        local contrast_level="medium"
        local mood_energy="moderate"
        local mood_tone="neutral"
        
        # Parse the simplified response
        if [[ "$mood" == "dark" ]]; then
            background_style="dark"
            mood_tone="dark"
        elif [[ "$mood" == "bright" ]]; then
            background_style="light"
            mood_tone="bright"
        fi
        
        if [[ "$mood" == "energetic" ]]; then
            mood_energy="energetic"
        elif [[ "$mood" == "calm" ]]; then
            mood_energy="calm"
        fi
        
        # Create theme recommendations
        cat > "$output_file" << EOF
{
  "vision_theming": {
    "primary_color": "$primary_color",
    "accent_color": "$accent_color", 
    "background_style": "$background_style",
    "contrast_level": "$contrast_level",
    "content_category": "$category",
    "mood_energy": "$mood_energy",
    "mood_tone": "$mood_tone",
    "confidence": "high"
  }
}
EOF
    else
        # Fallback extraction without jq
        local primary_color=$(grep -o '"primary_suggestion": *"[^"]*"' "$vision_file" | cut -d'"' -f4)
        local accent_color=$(grep -o '"accent_suggestion": *"[^"]*"' "$vision_file" | cut -d'"' -f4)
        
        cat > "$output_file" << EOF
{
  "vision_theming": {
    "primary_color": "${primary_color:-#606060}",
    "accent_color": "${accent_color:-#404040}",
    "background_style": "auto",
    "contrast_level": "medium",
    "content_category": "abstract",
    "mood_energy": "moderate", 
    "mood_tone": "neutral",
    "confidence": "medium"
  }
}
EOF
    fi
    
    log_message "INFO" "Theme recommendations saved to: $output_file"
}

# Performance reporting
report_performance() {
    if [[ -f "$PERFORMANCE_LOG" ]]; then
        local total_analyses=$(wc -l < "$PERFORMANCE_LOG")
        local avg_time=$(awk '{sum+=$1} END {print sum/NR}' "$PERFORMANCE_LOG")
        local max_time=$(sort -n "$PERFORMANCE_LOG" | tail -1)
        local min_time=$(sort -n "$PERFORMANCE_LOG" | head -1)
        
        log_message "INFO" "Vision Performance Summary:"
        log_message "INFO" "  Total Analyses: $total_analyses"
        log_message "INFO" "  Average Time: ${avg_time}s"
        log_message "INFO" "  Range: ${min_time}s - ${max_time}s"
        
        # Performance status
        if (( $(echo "$avg_time < 3.0" | bc -l) )); then
            log_message "INFO" "  Performance: ✅ Excellent (< 3s average)"
        elif (( $(echo "$avg_time < 5.0" | bc -l) )); then
            log_message "INFO" "  Performance: ⚠️ Acceptable (< 5s average)"
        else
            log_message "WARN" "  Performance: ❌ Slow (> 5s average)"
        fi
    fi
}

# Main function
main() {
    local wallpaper_path="$1"
    local output_file="${2:-/tmp/vision-analysis.json}"
    
    # Initialize logs
    > "$VISION_LOG"
    
    # Validate input
    if [[ -z "$wallpaper_path" ]]; then
        echo "Usage: $0 <wallpaper_path> [output_file]"
        echo "Example: $0 /path/to/wallpaper.jpg /tmp/vision-analysis.json"
        return 1
    fi
    
    log_message "INFO" "Vision Analyzer starting..."
    log_message "INFO" "Wallpaper: $wallpaper_path"
    log_message "INFO" "Output: $output_file"
    
    # Check dependencies
    if ! check_dependencies; then
        log_message "ERROR" "Dependency check failed"
        create_fallback_analysis "$wallpaper_path" "$output_file"
        return 1
    fi
    
    # Perform vision analysis
    if analyze_wallpaper_content "$wallpaper_path" "$output_file"; then
        log_message "INFO" "Vision analysis completed successfully"
        
        # Extract theme recommendations
        local theme_file="/tmp/vision-theme-recommendations.json"
        extract_theme_recommendations "$output_file" "$theme_file"
        
        # Report performance
        report_performance
        
        # Output success
        echo "$output_file"
        return 0
    else
        log_message "WARN" "Vision analysis completed with fallback"
        echo "$output_file"
        return 0
    fi
}

# Run main function if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 