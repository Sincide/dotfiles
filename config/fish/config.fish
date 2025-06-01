# Set environment variables
set -gx EDITOR nano
set -gx VISUAL nano
set -x OPENAI_API_KEY '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'

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
    alias ll='eza -l -a --icons --git --group --header --binary --classify --time-style=relative --sort=modified'
    
    # Additional useful variants
    alias la='ll -a'           # Show all files including hidden
    alias lt='ll --tree'       # List with tree view
    alias ltr='lt --sort=modified' # Tree view sorted by modification date
    alias lg='ll --git-ignore' # List respecting .gitignore
else
    set -a missing_commands eza
end

# File manager - lf with key-chord escape sequence
if command -v lf > /dev/null
    alias fm='lf'
    
    # Function to use lf for navigation
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
else
    set -a missing_commands lf
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
alias cleanall='sudo journalctl --vacuum-time=2weeks; sudo pacman -Sc --noconfirm'

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
    # Set FZF default options
    set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
    set -gx FZF_CTRL_T_OPTS '--preview "bat --color=always --style=numbers --line-range=:500 {}"'
    set -gx FZF_ALT_C_OPTS '--preview "ls -la {}"'
    
    # Limit history size
    set -gx HISTSIZE 2000
    set -gx HISTFILESIZE 2000
    
    # Bind fzf to Ctrl+R
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

# Zoxide: smarter cd
if command -v zoxide > /dev/null
    zoxide init fish | source
end

# Universal extract function
function extract
    if test -f $argv[1]
        switch $argv[1]
            case '*.tar.bz2'
                tar xjf $argv[1]
            case '*.tar.gz'
                tar xzf $argv[1]
            case '*.bz2'
                bunzip2 $argv[1]
            case '*.rar'
                unrar x $argv[1]
            case '*.gz'
                gunzip $argv[1]
            case '*.tar'
                tar xf $argv[1]
            case '*.tbz2'
                tar xjf $argv[1]
            case '*.tgz'
                tar xzf $argv[1]
            case '*.zip'
                unzip $argv[1]
            case '*.Z'
                uncompress $argv[1]
            case '*.7z'
                7z x $argv[1]
            case '*'
                echo "Cannot extract '$argv[1]' via extract()"
        end
    else
        echo "'$argv[1]' is not a valid file"
    end
end

# Print $PATH entries on separate lines
function path
    echo $PATH | tr ' ' '\n' | tr ':' '\n'
end 

# === pyenv integration ===
status --is-interactive; and pyenv init - | source

set -gx ENABLE_AI_OPTIMIZATION true
