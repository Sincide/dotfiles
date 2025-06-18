# Dotfiles management aliases
# This file is auto-generated. Do not edit directly.

# Aliases for dotfiles management
function dots --wraps='$HOME/dotfiles/scripts/git/dotfiles.sh' --description 'Manage dotfiles'
    $HOME/dotfiles/scripts/git/dotfiles.sh $argv
end

# Status
alias dotst='dots status'

# Add and commit
alias dota='dots add'

# Push
alias dotp='dots push'

# Pull
alias dotpl='dots pull'

# Diff
alias dotd='dots diff'

# Log
alias dotl='dots log'

# Sync (pull + add + commit + push)
alias dotsync='dots sync'
