function fish_right_prompt --description 'Evil Space right prompt with system info'
    set -l normal (set_color normal)
    set -l gray (set_color -o black)
    set -l blue (set_color blue)
    set -l yellow (set_color yellow)
    
    # Command duration
    if test "$CMD_DURATION" -gt 2000
        set -l duration (math "$CMD_DURATION / 1000")
        echo -n -s $yellow "⏱ ${duration}s" $normal " "
    end
    
    # Show time
    echo -n -s $gray (date '+%H:%M') $normal
end 