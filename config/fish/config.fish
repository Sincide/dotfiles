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

# Better ls with exa if available
if command -v exa > /dev/null
    alias ls='exa --icons'
    alias ll='exa -l --icons'
    alias la='exa -la --icons'
    alias lt='exa --tree --icons'
else
    set -a missing_commands "exa"
    alias ll='ls -lh'
    alias la='ls -lah'
end

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'

# Git aliases
alias g='git'
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