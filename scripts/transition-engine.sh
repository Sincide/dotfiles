#!/bin/bash

# Transition Engine for Dynamic Wallpaper Transitions
# Generates swww commands with various transition effects

TRANSITIONS_CONFIG="$HOME/dotfiles/config/dynamic-theming/transitions.conf"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /tmp/transition-engine.log
}

# Load transition configuration
load_config() {
    if [ -f "$TRANSITIONS_CONFIG" ]; then
        source "$TRANSITIONS_CONFIG"
        log_message "Loaded transition config: mode=$TRANSITION_MODE"
    else
        log_message "Warning: No transition config found, using defaults"
        # Set defaults
        TRANSITION_MODE="random"
        RANDOM_TRANSITIONS="fade left right wipe wave grow center"
        TRANSITION_DURATION_MIN="1"
        TRANSITION_DURATION_MAX="3"
    fi
}

# Generate random transition parameters
generate_random_transition() {
    local transitions=($RANDOM_TRANSITIONS)
    local transition_count=${#transitions[@]}
    local selected_transition=${transitions[$((RANDOM % transition_count))]}
    
    # Random duration between min and max
    local duration=$((RANDOM % (TRANSITION_DURATION_MAX - TRANSITION_DURATION_MIN + 1) + TRANSITION_DURATION_MIN))
    
    # Special parameters based on transition type
    local extra_params=""
    
    case "$selected_transition" in
        "wipe"|"wave")
            local angle=$((RANDOM % 360))
            extra_params="--transition-angle $angle"
            if [ "$selected_transition" = "wave" ]; then
                extra_params="$extra_params --transition-wave $WAVE_WIDTH,$WAVE_HEIGHT"
            fi
            ;;
        "grow"|"outer"|"any")
            if [ "$ENABLE_SPECIAL_EFFECTS" = "true" ]; then
                local positions=($GROW_POSITIONS)
                local pos_count=${#positions[@]}
                local position=${positions[$((RANDOM % pos_count))]}
                extra_params="--transition-pos $position"
            fi
            ;;
        "fade")
            if [ "$ENABLE_SPECIAL_EFFECTS" = "true" ]; then
                # Randomly select bezier curve
                local beziers=("$FADE_BEZIER_SMOOTH" "$FADE_BEZIER_DRAMATIC" "$FADE_BEZIER_CURRENT")
                local bezier_count=${#beziers[@]}
                local selected_bezier=${beziers[$((RANDOM % bezier_count))]}
                extra_params="--transition-bezier $selected_bezier"
            fi
            ;;
    esac
    
    echo "--transition-type $selected_transition --transition-duration $duration $extra_params"
}

# Generate category-based transition
generate_category_transition() {
    local wallpaper_path="$1"
    local category=$(basename "$(dirname "$wallpaper_path")")
    
    # Get category-specific transition
    local transition_type=""
    case "$category" in
        "abstract") transition_type="$TRANSITION_ABSTRACT" ;;
        "nature") transition_type="$TRANSITION_NATURE" ;;
        "dark") transition_type="$TRANSITION_DARK" ;;
        "gaming") transition_type="$TRANSITION_GAMING" ;;
        "minimal") transition_type="$TRANSITION_MINIMAL" ;;
        "space") transition_type="$TRANSITION_SPACE" ;;
        *) transition_type="$CATEGORY_TRANSITION" ;;
    esac
    
    echo "--transition-type $transition_type --transition-duration 2"
}

# Generate smart transition based on context
generate_smart_transition() {
    local context="$1"  # startup, category, quick
    
    local transition_type=""
    case "$context" in
        "startup") transition_type="$STARTUP_TRANSITION" ;;
        "category") transition_type="$CATEGORY_TRANSITION" ;;
        "quick") transition_type="$QUICK_TRANSITION" ;;
        *) transition_type="fade" ;;
    esac
    
    echo "--transition-type $transition_type --transition-duration 2"
}

# Generate fixed transition
generate_fixed_transition() {
    local extra_params=""
    
    if [ "$FIXED_TRANSITION_TYPE" = "wipe" ] || [ "$FIXED_TRANSITION_TYPE" = "wave" ]; then
        extra_params="--transition-angle $FIXED_TRANSITION_ANGLE"
    fi
    
    echo "--transition-type $FIXED_TRANSITION_TYPE --transition-duration $FIXED_TRANSITION_DURATION $extra_params"
}

# Main function to generate transition command
generate_transition() {
    local wallpaper_path="$1"
    local context="${2:-normal}"  # startup, category, quick, normal
    
    log_message "Generating transition for: $(basename "$wallpaper_path") (context: $context)"
    
    load_config
    
    local transition_params=""
    
    case "$TRANSITION_MODE" in
        "random")
            transition_params=$(generate_random_transition)
            ;;
        "category")
            transition_params=$(generate_category_transition "$wallpaper_path")
            ;;
        "smart")
            transition_params=$(generate_smart_transition "$context")
            ;;
        "fixed")
            transition_params=$(generate_fixed_transition)
            ;;
        *)
            log_message "Unknown transition mode: $TRANSITION_MODE, using fixed"
            transition_params=$(generate_fixed_transition)
            ;;
    esac
    
    # Add FPS if specified
    if [ ! -z "$TRANSITION_FPS" ]; then
        transition_params="$transition_params --transition-fps $TRANSITION_FPS"
    fi
    
    log_message "Generated transition: $transition_params"
    echo "$transition_params"
}

# If script is called directly, generate transition for given wallpaper
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <wallpaper_path> [context]"
        echo "Context: startup, category, quick, normal"
        exit 1
    fi
    
    generate_transition "$@"
fi 