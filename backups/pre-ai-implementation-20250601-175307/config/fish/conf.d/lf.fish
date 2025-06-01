# LF file manager configuration

# Set environment variables
set -gx LF_ICONS true

# Define aliases
alias fm='lf'

# Set nano as the default editor for lf to use
set -gx EDITOR nano

# Function to change directory to the last visited by lf
function lfcd
    set tmp (mktemp)
    lf -last-dir-path=$tmp $argv
    if test -f "$tmp"
        set dir (cat $tmp)
        rm -f $tmp
        if test -d "$dir"
            if test "$dir" != (pwd)
                cd $dir
            end
        end
    end
end

# Optional keybinding to launch lfcd with Alt+o
bind \eo 'lfcd; commandline -f repaint' 