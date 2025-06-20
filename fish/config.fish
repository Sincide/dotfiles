# Fish Configuration

# Set greeting
set fish_greeting ""

set -gx EDITOR nano

# Add ~/.local/bin to PATH
fish_add_path ~/.local/bin

# Dotfiles management aliases
alias dot='$HOME/dotfiles/scripts/git/dotfiles.sh'
alias dots='$HOME/dotfiles/scripts/git/dotfiles.sh sync'
alias dotst='$HOME/dotfiles/scripts/git/dotfiles.sh status'
alias dotd='$HOME/dotfiles/scripts/git/dotfiles.sh diff'
alias dotr='$HOME/dotfiles/scripts/git/dotfiles.sh --remote=ssh'
alias dotrh='$HOME/dotfiles/scripts/git/dotfiles.sh --remote=https'

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias vim='nano'
alias vi='nano'
alias cls='clear'
alias ff='fastfetch'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Additional useful aliases
alias tree='tree -C'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'
alias top='htop'

# Function to extract archives
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
                echo "'$argv[1]' cannot be extracted via extract()"
        end
    else
        echo "'$argv[1]' is not a valid file"
    end
end

# Function to create and enter directory
function mkcd
    mkdir -p $argv[1] && cd $argv[1]
end

# Function to find files
function findfile
    find . -name "*$argv[1]*" -type f
end

# Function to find directories
function fd
    find . -name "*$argv[1]*" -type d
end

# Function to show disk usage of current directory
function duh
    du -sh * | sort -hr
end

# Function to show git log with graph
function glog
    git log --oneline --graph --decorate --all
end

# Starship prompt (cross-shell prompt written in Rust)
if command -v starship > /dev/null
    starship init fish | source
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# Fish settings for better experience
set -g fish_autosuggestion_enabled 1
set -g fish_greeting ""

# Enable vi mode (optional - uncomment if you prefer vi keybindings)
# fish_vi_key_bindings
