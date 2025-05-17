# Set environment variables
set -gx EDITOR nvim
set -gx VISUAL nvim
# Set TERM only for non-Kitty terminals
if not string match -q 'xterm-kitty' $TERM
    set -gx TERM xterm-256color
end

# Add to PATH
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin

# Check for required commands
set -l missing_commands

# Better ls with eza if available
if command -v eza > /dev/null
    # Base eza command with icons
    alias ls='eza --icons'
    
    # Detailed listing with:
    # - Git status
    # - File sizes with units
    # - Permissions as text (rwx)
    # - Group info
    # - Header row
    # - Natural sort order
    # - Time/date in recent format
    # - Sort by modified time
    alias ll='eza -l --icons --git --group --header --binary --classify --time-style=relative --sort=modified'
    
    # Additional useful variants
    alias la='ll -a'           # Show all files including hidden
    alias lt='ll --tree'       # List with tree view
    alias ltr='lt --sort=modified' # Tree view sorted by modification date
    alias lg='ll --git-ignore' # List respecting .gitignore
else
    set -a missing_commands eza
end

# File manager - add Yazi alias with key-chord escape sequence
if command -v yazi > /dev/null
    alias fm='yazi'
    
    # Function to use Yazi for navigation
    function ya
        yazi $argv
        
        # When exiting Yazi, change to the last directory
        set tmp (mktemp)
        yazi --cwd-file=$tmp $argv
        if test -f $tmp
            set dir (cat $tmp)
            if test -d $dir
                cd $dir
            end
            rm -f $tmp
        end
    end
else
    set -a missing_commands yazi
end

# Report missing commands
if test (count $missing_commands) -gt 0
    echo "Missing commands: $missing_commands"
    echo "Install them for a better experience"
end

# Vi mode for Fish shell
fish_vi_key_bindings

# Aliases
alias g='git'
alias v='nvim'

# Custom functions
function md
    mkdir -p $argv && cd $argv
end

# Load custom Fish functions
for file in ~/.config/fish/functions/*.fish
    source $file
end

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'

# Git aliases
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gst='git status'
alias gaa='git add --all'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias gl='git log --oneline'
alias grb='git rebase'
alias grs='git restore'
alias grst='git restore --staged'
alias gf='git fetch'
alias gcl='git clone'

# Dotfiles management aliases
alias dot='$HOME/dotfiles/scripts/dotfiles.sh'
alias dots='$HOME/dotfiles/scripts/dotfiles.sh sync'
alias dotst='$HOME/dotfiles/scripts/dotfiles.sh status'
alias dotd='$HOME/dotfiles/scripts/dotfiles.sh diff'

# AMD GPU management
alias amd-oc='sudo $HOME/dotfiles/scripts/amd-overdrive.sh'

# System
alias update='sudo pacman -Syu'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'

# Better grep with ripgrep if available
if command -v rg > /dev/null
    alias grep='rg'
else
    set -a missing_commands "ripgrep"
end

# Directory shortcuts
alias dl='cd ~/Downloads'
alias docs='cd ~/Documents'
alias cfg='cd ~/.config'

# Custom functions
function mkcd
    mkdir -p $argv[1] && cd $argv[1]
end

# Use vim bindings
fish_vi_key_bindings

# Better command history with fzf if available
if command -v fzf > /dev/null
    bind \cr 'history | fzf | read -l command; commandline $command'
else
    set -a missing_commands "fzf"
end

# Disable fish greeting
set -g fish_greeting

# Print missing commands warning if any
if test (count $missing_commands) -gt 0
    set_color yellow
    echo "Warning: The following recommended commands are not installed:"
    for cmd in $missing_commands
        echo "  - $cmd"
    end
    echo "You can install them using 'yay -S $missing_commands'"
    set_color normal
end 