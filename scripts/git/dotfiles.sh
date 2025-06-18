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
LOG_DIR="$DOTFILES_DIR/logs"
LOG_FILE="$LOG_DIR/dotfiles-$(date +%Y%m%d).log"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null || {
    echo "Failed to create log directory: $LOG_DIR" >&2
    LOG_FILE="/tmp/dotfiles-$(date +%s).log"
    echo "Using temporary log file: $LOG_FILE" >&2
}

# Ensure log file exists
touch "$LOG_FILE" 2>/dev/null || {
    LOG_FILE="/tmp/dotfiles-$(date +%s).log"
    echo "Using temporary log file: $LOG_FILE" >&2
    touch "$LOG_FILE"
}

# Ensure we're in the dotfiles directory
cd "$DOTFILES_DIR" || {
    echo -e "${RED}Error: Could not change to dotfiles directory${NC}" >&2
    exit 1
}

# Initialize logging
init_logging() {
    # Ensure log directory exists
    mkdir -p "$LOG_DIR" 2>/dev/null || {
        LOG_FILE="/tmp/dotfiles-$(date +%s).log"
        echo "Warning: Using temporary log file: $LOG_FILE" >&2
    }
    
    # Create log file
    touch "$LOG_FILE" 2>/dev/null || {
        LOG_FILE="/tmp/dotfiles-$(date +%s).log"
        echo "Warning: Using temporary log file: $LOG_FILE" >&2
        touch "$LOG_FILE"
    }
    
    echo -e "\n=== $(date) - dotfiles.sh started ===" >> "$LOG_FILE"
    log "Log file: $LOG_FILE"
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
        # Exclude log files from stashing
        git -C "$DOTFILES_DIR" stash push --keep-index --include-untracked -- "$(git -C "$DOTFILES_DIR" rev-parse --show-toplevel | tr -d '\n')" \
            -- "$(git -C "$DOTFILES_DIR" ls-files --others --exclude-standard | grep -v "\.log$" | tr '\n' ' ')" \
            -m "Auto-stashed by dotfiles.sh $(date +%Y-%m-%d_%H-%M-%S)" || {
            log "Warning: Failed to stash changes. Continuing anyway..."
            return 1
        }
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

# Generate a commit message based on changes
generate_commit_message() {
    local message=""
    
    # Get list of changed files
    local changed_files
    changed_files=$(git -C "$DOTFILES_DIR" status --porcelain | awk '{print $2}')
    
    if [ -z "$changed_files" ]; then
        echo "chore: update dotfiles"
        return 0
    fi
    
    # Count changes by type
    local added=0 modified=0 deleted=0 renamed=0
    while read -r status file; do
        case "$status" in
            "A") ((added++)) ;;
            "M") ((modified++)) ;;
            "D") ((deleted++)) ;;
            "R") ((renamed++)) ;;
        esac
    done < <(git -C "$DOTFILES_DIR" status --porcelain)
    
    # Build commit message
    message="chore: "
    [ "$added" -gt 0 ] && message+="add $added files, "
    [ "$modified" -gt 0 ] && message+="modify $modified files, "
    [ "$deleted" -gt 0 ] && message+="delete $deleted files, "
    [ "$renamed" -gt 0 ] && message+="rename $renamed files, "
    
    # Remove trailing comma and space
    message="${message%, }"
    
    # If no changes were detected (shouldn't happen)
    [ "$message" = "chore:" ] && message="chore: update dotfiles"
    
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
