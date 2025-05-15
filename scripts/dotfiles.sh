#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored status
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Function to generate commit message based on changes
generate_commit_message() {
    local changes=""
    local files_changed=$(git diff --cached --name-only)
    
    # Check for config changes
    if echo "$files_changed" | grep -q "config/"; then
        local configs=$(echo "$files_changed" | grep "config/" | cut -d'/' -f2 | sort -u | tr '\n' ',' | sed 's/,$//')
        [ ! -z "$configs" ] && changes+="Updated ${configs} configs. "
    fi
    
    # Check for script changes
    if echo "$files_changed" | grep -q "scripts/"; then
        local scripts=$(echo "$files_changed" | grep "scripts/" | cut -d'/' -f2 | sort -u | tr '\n' ',' | sed 's/,$//')
        [ ! -z "$scripts" ] && changes+="Modified ${scripts} scripts. "
    fi
    
    # Check for specific application changes
    for app in waybar hypr kitty fish rofi dunst; do
        if echo "$files_changed" | grep -q "config/$app/"; then
            local files=$(echo "$files_changed" | grep "config/$app/" | rev | cut -d'/' -f1 | rev | sort -u | tr '\n' ',' | sed 's/,$//')
            changes+="[$app] Changed $files. "
        fi
    done
    
    # If no specific changes detected, use a generic message
    if [ -z "$changes" ]; then
        changes="Updated dotfiles: $(echo "$files_changed" | tr '\n' ',' | sed 's/,$//')"
    fi
    
    echo "$changes"
}

# Function to show status with colors
show_status() {
    print_status "Current dotfiles status:"
    echo
    git status -s | while read -r line; do
        local status=${line:0:2}
        local file=${line:3}
        case $status in
            "M "*)
                echo -e "${YELLOW}Modified:${NC}  $file"
                ;;
            "A "*)
                echo -e "${GREEN}Added:${NC}     $file"
                ;;
            "D "*)
                echo -e "${RED}Deleted:${NC}   $file"
                ;;
            "R "*)
                echo -e "${BLUE}Renamed:${NC}   $file"
                ;;
            "??"*)
                echo -e "${BLUE}Untracked:${NC} $file"
                ;;
            *)
                echo -e "$line"
                ;;
        esac
    done
    echo
}

# Function to sync dotfiles
sync_dotfiles() {
    print_status "Syncing dotfiles..."
    
    # Check if there are any changes
    if ! git status --porcelain | grep -q '^'; then
        print_warning "No changes to sync!"
        return 0
    fi
    
    # Add all changes
    git add -A
    
    # Generate commit message
    local commit_msg=$(generate_commit_message)
    
    # Commit changes
    if git commit -m "$commit_msg"; then
        print_success "Changes committed: $commit_msg"
    else
        print_error "Failed to commit changes"
        return 1
    fi
    
    # Pull changes
    print_status "Pulling latest changes..."
    if git pull --rebase; then
        print_success "Successfully pulled changes"
    else
        print_error "Failed to pull changes"
        return 1
    fi
    
    # Push changes
    print_status "Pushing changes..."
    if git push; then
        print_success "Successfully pushed changes"
    else
        print_error "Failed to push changes"
        return 1
    fi
}

# Main script
case "$1" in
    "status"|"st")
        show_status
        ;;
    "sync"|"s")
        sync_dotfiles
        ;;
    "diff"|"d")
        git diff
        ;;
    *)
        echo "Usage: $(basename $0) <command>"
        echo "Commands:"
        echo "  status, st    Show status of dotfiles"
        echo "  sync, s       Sync dotfiles (add, commit, pull, push)"
        echo "  diff, d       Show diff of changes"
        ;;
esac 