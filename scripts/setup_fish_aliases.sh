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

# Main dotfiles command (defaults to sync)
function dots --wraps='$HOME/dotfiles/scripts/git/dotfiles.sh' --description 'Sync dotfiles (pull + add + commit + push)'
    if test (count $argv) -eq 0
        $HOME/dotfiles/scripts/git/dotfiles.sh sync
    else
        $HOME/dotfiles/scripts/git/dotfiles.sh $argv
    end
end

# Status
alias dotst='$HOME/dotfiles/scripts/git/dotfiles.sh status'

# Add changes
alias dota='$HOME/dotfiles/scripts/git/dotfiles.sh add'

# Commit changes
alias dotc='$HOME/dotfiles/scripts/git/dotfiles.sh commit'

# Push changes
alias dotp='$HOME/dotfiles/scripts/git/dotfiles.sh push'

# Pull changes
alias dotpl='$HOME/dotfiles/scripts/git/dotfiles.sh pull'

# Show diff
alias dotd='$HOME/dotfiles/scripts/git/dotfiles.sh diff'

# Show log
alias dotl='$HOME/dotfiles/scripts/git/dotfiles.sh log'

# Sync (pull + add + commit + push)
alias dotsync='$HOME/dotfiles/scripts/git/dotfiles.sh sync'
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
