# Set environment variables
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERM xterm-256color

# Add to PATH
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin

# Better ls with exa if available
if command -v exa > /dev/null
    alias ls='exa --icons'
    alias ll='exa -l --icons'
    alias la='exa -la --icons'
    alias lt='exa --tree --icons'
else
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

# System
alias update='sudo pacman -Syu'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'

# Better grep with ripgrep if available
if command -v rg > /dev/null
    alias grep='rg'
end

# Directory shortcuts
alias dl='cd ~/Downloads'
alias docs='cd ~/Documents'
alias cfg='cd ~/.config'

# Custom functions
function mkcd
    mkdir -p $argv[1] && cd $argv[1]
end

# Initialize starship prompt if installed
# Commented out since we're using custom fish prompt
# if command -v starship > /dev/null
#     starship init fish | source
# end

# Use vim bindings
fish_vi_key_bindings

# Better command history with fzf if available
if command -v fzf > /dev/null
    bind \cr 'history | fzf | read -l command; commandline $command'
end

# Disable fish greeting
set -g fish_greeting 