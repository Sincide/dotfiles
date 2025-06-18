#!/bin/bash

# This script sets up fish shell aliases for dotfiles management

# Exit on error
set -e

# Configuration
FISH_CONFIG_DIR="$HOME/.config/fish/conf.d"
ALIAS_FILE="$FISH_CONFIG_DIR/dotfiles_aliases.fish"
DOTFILES_SCRIPT="$HOME/dotfiles/scripts/git/dotfiles.sh"

# Create fish config directory if it doesn't exist
mkdir -p "$FISH_CONFIG_DIR"

# Create or overwrite the alias file
cat > "$ALIAS_FILE" << 'EOL'
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
EOL

# Make the script executable
chmod +x "$DOTFILES_SCRIPT"
chmod +x "$ALIAS_FILE"

echo "Fish aliases for dotfiles management have been set up in $ALIAS_FILE"
echo "The aliases will be available in new terminal sessions."
echo ""
echo "Available aliases:"
echo "  dots      - Main dotfiles management command"
echo "  dotst     - Show git status"
echo "  dota      - Add and commit changes"
echo "  dotp      - Push changes to remote"
echo "  dotpl     - Pull changes from remote"
echo "  dotd      - Show changes"
echo "  dotl      - Show commit history"
echo "  dotsync   - Sync with remote (pull + add + commit + push)"
