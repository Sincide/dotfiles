#!/bin/bash

# dotfiles.sh - A helper script for managing dotfiles with git
# Usage: dots [command] [options]
#        dots (without arguments) will sync changes (pull + add + commit + push)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Configuration
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CONFIG_DIR="$HOME/.config"
LOG_FILE="$DOTFILES_DIR/dotfiles.log"

# Ensure we're in the dotfiles directory
cd "$DOTFILES_DIR" || {
    echo -e "${RED}Error: Could not change to dotfiles directory${NC}" >&2
    exit 1
}

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== $(date) - dotfiles.sh started ===" >> "$LOG_FILE"
}

# Log a message
log() {
    local message="$1"
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $message" | tee -a "$LOG_FILE"
}

# Log an error
error() {
    local message="$1"
    echo -e "${RED}[ERROR] $message${NC}" | tee -a "$LOG_FILE" >&2
    return 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for unstaged changes
has_unstaged_changes() {
    [ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]
}

# Stash changes and return 0 if stashed, 1 if not
stash_changes() {
    if has_unstaged_changes; then
        log "Stashing unstaged changes..."
        git -C "$DOTFILES_DIR" stash push -m "Auto-stashed by dotfiles.sh $(date +%Y-%m-%d_%H-%M-%S)"
        return 0  # Changes were stashed
    fi
    return 1  # No changes to stash
}

# Apply stashed changes if any
apply_stashed_changes() {
    if [ "$(git -C "$DOTFILES_DIR" stash list | wc -l)" -gt 0 ]; then
        log "Applying stashed changes..."
        if ! git -C "$DOTFILES_DIR" stash pop; then
            error "Failed to apply stashed changes. Run 'git stash list' to see stashed changes."
            return 1
        fi
    fi
    return 0
}

# Categorize files by type
categorize_files() {
    local file="$1"
    case "$file" in
        *.conf|*rc|*.ini|*.json|*.toml|*.yml|*.yaml)
            echo "config"
            ;;
        *.sh|*.py|*.pl|*.rb|*.js|*.ts|*.lua)
            echo "script"
            ;;
        *.fish|*.zsh|*.bash)
            echo "shell"
            ;;
        *.md|*.txt|*.rst|*.adoc)
            echo "doc"
            ;;
        *.png|*.jpg|*.jpeg|*.gif|*.svg|*.ico)
            echo "image"
            ;;
        *)
            echo "other"
            ;;
    esac
}

# Generate a descriptive commit message based on changes
generate_commit_message() {
    # Get list of changed files with status
    local changes
    changes=$(git -C "$DOTFILES_DIR" status --porcelain 2>/dev/null)
    
    if [ -z "$changes" ]; then
        echo "chore: 🔄 No changes detected"
        return 0
    fi
    
    # Initialize counters and arrays
    local added=0 modified=0 deleted=0 renamed=0
    declare -A file_types
    declare -a modified_apps
    
    # Process each change
    while IFS= read -r line; do
        local status="${line:0:2}"
        local file="${line:3}"
        
        # Skip empty lines
        [ -z "${file// }" ] && continue
        
        # Get file type and app name (first directory in path)
        local file_type=$(categorize_files "$file")
        local app_name=$(echo "$file" | cut -d'/' -f1)
        
        # Update counters
        case "$status" in
            "A "|"A\t") ((added++)) ;;
            "M "|"M\t") ((modified++)) ;;
            "D "|"D\t") ((deleted++)) ;;
            "R "|"R\t") ((renamed++)) ;;
        esac
        
        # Track file types and modified apps
        [ -n "$file_type" ] && ((file_types["$file_type"]++))
        if [[ "$app_name" != "$file" && " $app_name " != *" "*"$app_name"*"* ]]; then
            modified_apps+=("$app_name")
        fi
    done <<< "$changes"
    
    # Build commit message
    local message_parts=()
    
    # Add change type summary
    [ "$added" -gt 0 ] && message_parts+=("➕ $added")
    [ "$modified" -gt 0 ] && message_parts+=("✏️ $modified")
    [ "$deleted" -gt 0 ] && message_parts+=("🗑️ $deleted")
    [ "$renamed" -gt 0 ] && message_parts+=("🏷️ $renamed")
    
    # Add file type summary
    local type_summary=()
    for type in "${!file_types[@]}"; do
        type_summary+=("$type:${file_types[$type]}")
    done
    
    # Add modified apps summary (unique, sorted)
    local apps_summary=""
    if [ ${#modified_apps[@]} -gt 0 ]; then
        apps_summary=" (${modified_apps[*]})"
    fi
    
    # Combine everything
    local message="🔧 ${message_parts[*]} ${type_summary[*]}$apps_summary"
    
    # Ensure message is not too long
    if [ ${#message} -gt 100 ]; then
        message="${message:0:97}..."
    fi
    
    # Remove any double spaces and trim
    message=$(echo "$message" | tr -s ' ' | xargs)
    
    # Fallback if something went wrong
    [ -z "$message" ] && message="🔧 Update dotfiles"
    
    echo "$message"
}

# Show git status
git_status() {
    log "Checking git status..."
    git -C "$DOTFILES_DIR" status
}

# Add all changes and create a commit
git_add_commit() {
    local message="${1:-$(generate_commit_message)}"
    
    log "Adding all changes..."
    if ! git -C "$DOTFILES_DIR" add -A; then
        error "Failed to add changes"
        return 1
    fi
    
    log "Creating commit with message: $message"
    if ! git -C "$DOTFILES_DIR" commit -m "$message"; then
        error "Failed to create commit"
        return 1
    fi
    
    log "${GREEN}Changes committed successfully${NC}"
}

# Push changes to remote
git_push() {
    local branch
    branch=$(git -C "$DOTFILES_DIR" rev-parse --abbrev-ref HEAD)
    
    log "Pushing changes to remote..."
    if ! git -C "$DOTFILES_DIR" push -u origin "$branch"; then
        error "Failed to push changes"
        return 1
    fi
    
    log "${GREEN}Changes pushed successfully${NC}"
}

# Pull changes from remote
git_pull() {
    local stash_created=0
    
    # Stash any local changes before pulling
    if has_unstaged_changes; then
        stash_changes
        stash_created=$?
    fi
    
    log "Pulling changes from remote..."
    if ! git -C "$DOTFILES_DIR" pull --rebase; then
        error "Failed to pull changes"
        # Try to restore stashed changes if pull failed
        [ $stash_created -eq 0 ] && apply_stashed_changes
        return 1
    fi
    
    # Apply stashed changes back if any
    if [ $stash_created -eq 0 ]; then
        if ! apply_stashed_changes; then
            return 1
        fi
    fi
    
    log "${GREEN}Changes pulled successfully${NC}"
    return 0
}

# Show diff of changes
git_diff() {
    git -C "$DOTFILES_DIR" diff --color=always | less -R
}

# Show commit history
git_log() {
    git -C "$DOTFILES_DIR" log --graph --oneline --decorate --color=always | less -R
}

# Sync changes with remote (pull + add + commit + push)
git_sync() {
    log "Starting sync..."
    
    # First, pull any remote changes
    if ! git_pull; then
        error "Sync aborted due to pull failure"
        return 1
    fi
    
    # Check if there are any changes to commit
    if has_unstaged_changes; then
        log "Found local changes to commit..."
        if ! git_add_commit "$@"; then
            error "Failed to commit changes"
            return 1
        fi
        
        # Push the new commit if commit was successful
        if ! git_push; then
            error "Failed to push changes"
            return 1
        fi
    else
        log "No local changes to commit"
    fi
    
    log "${GREEN}Sync completed successfully${NC}
    ${YELLOW}Note: If you had any conflicts during sync, check 'git status' and resolve them.${NC}"
    return 0
}

# Main function
main() {
    local command="${1:-}"
    
    # Initialize logging
    init_logging
    
    # If no command is provided, default to sync
    if [ -z "$command" ]; then
        git_sync "${@:1}"
        return $?
    fi
    
    # Process commands
    case "$command" in
        status|st)
            git_status
            ;;
        add|a)
            git_add_commit "${@:2}"
            ;;
        push|p)
            git_push
            ;;
        pull|pl)
            git_pull
            ;;
        diff|d)
            git_diff
            ;;
        log|l)
            git_log
            ;;
        sync|s)
            git_sync "${@:2}"
            ;;
        *|help|h)
            echo -e "${GREEN}dotfiles.sh - Dotfiles Management Helper${NC}"
            echo "Usage: dots [command] [options]"
            echo ""
            echo "Commands:"
            echo "  (no command)   Sync changes (pull + add + commit + push)"
            echo "  status (st)    Show git status"
            echo "  add (a)        Add all changes and commit"
            echo "  push (p)       Push changes to remote"
            echo "  pull (pl)      Pull changes from remote"
            echo "  diff (d)       Show changes"
            echo "  log (l)        Show commit history"
            echo "  sync (s)       Sync with remote (pull + add + commit + push)"
            echo "  help (h)       Show this help message"
            ;;
    esac
}

# Run the script
main "$@"
