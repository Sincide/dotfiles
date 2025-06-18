#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status()    { echo -e "${BLUE}[*]${NC} $1"; }
print_success()   { echo -e "${GREEN}[✓]${NC} $1"; }
print_error()     { echo -e "${RED}[✗]${NC} $1"; }
print_warning()   { echo -e "${YELLOW}[!]${NC} $1"; }

print_help() {
    cat <<EOF
Usage: $(basename "$0") [--remote=ssh|https] <command> [options]

Commands:
  status, st         Show status of dotfiles (local and remote sync info)
  sync, s [msg]      Sync dotfiles (add, commit, pull, push). Optionally provide a commit message.
  diff, d            Show diff of changes
  help, -h, --help   Show this help message
EOF
}

# Check if inside a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    print_error "Not inside a Git repository! Aborting."
    exit 2
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || { print_error "Failed to cd to repo root: $REPO_ROOT"; exit 1; }
print_status "Using repository root: $REPO_ROOT"

# Parse and apply remote override early
for arg in "$@"; do
    case "$arg" in
        --remote=ssh)
            git remote set-url origin git@github.com:$(git remote get-url origin | sed -E 's|https://github.com/||;s|^.*:||')
            print_success "Remote set to SSH"
            shift
            ;;
        --remote=https)
            git remote set-url origin https://github.com/$(git remote get-url origin | sed -E 's|.*github.com[:/]||')
            print_success "Remote set to HTTPS"
            shift
            ;;
    esac
done

# Show current repo info
REPO_NAME=$(basename -s .git "$(git remote get-url origin 2>/dev/null)" 2>/dev/null)
REMOTE_URL=$(git remote get-url origin 2>/dev/null)

echo
echo -e "${YELLOW}==============================${NC}"
echo -e "${YELLOW}  GIT REPOSITORY IN USE:${NC}"
echo -e "${YELLOW}  → ${BLUE}${REPO_NAME:-<unknown>}${NC}"
echo -e "${YELLOW}  → ${REMOTE_URL:-<no remote found>}${NC}"
echo -e "${YELLOW}==============================${NC}"
echo

# Only allow [Enter] or [Y/y] to proceed
read -n 1 -p "Press [Y] or [Enter] to continue, anything else to abort: " confirm
echo
if [[ -n "$confirm" && "$confirm" != "y" && "$confirm" != "Y" ]]; then
    print_error "Aborted by user."
    exit 4
fi

# Function to generate commit message based on changes
generate_commit_message() {
    local files_changed
    files_changed=$(git diff --cached --name-only)
    local changes=""

    if echo "$files_changed" | grep -q "config/"; then
        local configs
        configs=$(echo "$files_changed" | grep "config/" | cut -d'/' -f2 | sort -u | tr '\n' ',' | sed 's/,$//')
        [ -n "$configs" ] && changes+="Updated ${configs} configs. "
    fi
    if echo "$files_changed" | grep -q "scripts/"; then
        local scripts
        scripts=$(echo "$files_changed" | grep "scripts/" | cut -d'/' -f2 | sort -u | tr '\n' ',' | sed 's/,$//')
        [ -n "$scripts" ] && changes+="Modified ${scripts} scripts. "
    fi
    for app in waybar hypr kitty fish fuzzel dunst; do
        if echo "$files_changed" | grep -q "config/$app/"; then
            local files
            files=$(echo "$files_changed" | grep "config/$app/" | rev | cut -d'/' -f1 | rev | sort -u | tr '\n' ',' | sed 's/,$//')
            changes+="[$app] Changed $files. "
        fi
    done
    if [ -z "$changes" ]; then
        changes="Updated dotfiles: $(echo "$files_changed" | tr '\n' ',' | sed 's/,$//')"
    fi
    echo "$changes"
}

show_status() {
    print_status "Current dotfiles status:"
    echo
    while IFS= read -r line; do
        local status="${line:0:2}"
        local filename="${line:3}"
        case "$status" in
            " M"|"M "|"MM") echo -e "${YELLOW}Modified:${NC}  $filename";;
            "A "|"AM")      echo -e "${GREEN}Added:${NC}     $filename";;
            "D "|" D")      echo -e "${RED}Deleted:${NC}   $filename";;
            "R ")           echo -e "${BLUE}Renamed:${NC}   $filename";;
            "??")           echo -e "${BLUE}Untracked:${NC} $filename";;
            *)              echo -e "Unknown:    $filename";;
        esac
    done < <(git status --porcelain)
    echo

    # --- Remote sync status ---
    git fetch --quiet

    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u} 2>/dev/null)
    BASE=$(git merge-base @ @{u} 2>/dev/null)

    if [[ "$LOCAL" = "$REMOTE" ]]; then
        print_success "Local and remote are in sync."
    elif [[ "$LOCAL" = "$BASE" ]]; then
        print_warning "Your branch is BEHIND remote. Run 'dotfiles.sh sync' to pull changes!"
    elif [[ "$REMOTE" = "$BASE" ]]; then
        print_warning "Your branch is AHEAD of remote. Run 'dotfiles.sh sync' to push changes!"
    else
        print_error "Your branch and remote have diverged. Manual intervention needed."
    fi
}

sync_dotfiles() {
    print_status "Syncing dotfiles..."

    local local_changes=0
    if git status --porcelain | grep -q '^'; then
        local_changes=1
        git add -A

        local commit_msg
        if [ -n "$1" ]; then
            commit_msg="$1"
        else
            commit_msg=$(generate_commit_message)
        fi

        if ! git commit -m "$commit_msg"; then
            print_error "Failed to commit changes"
            return 1
        else
            echo -e "${YELLOW}[✓] Changes committed: $commit_msg${NC}"
        fi
    else
        print_warning "No local changes to commit!"
    fi

    # Always pull from remote to get latest changes
    print_status "Pulling latest changes..."
    if ! git pull --rebase; then
        print_error "Failed to pull (rebase) changes! You probably have merge conflicts."
        print_warning "Resolve conflicts, run 'git rebase --continue' or 'git rebase --abort', then re-run this script."
        return 1
    else
        print_success "Successfully pulled changes"
    fi

    # Always push (in case rebase rewrote local commits, or you resolved conflicts)
    print_status "Pushing changes..."
    if ! git push; then
        print_error "Failed to push changes. Check your remote/network."
        return 1
    else
        print_success "Successfully pushed changes"
    fi
}

show_diff() {
    print_status "Showing changes:"
    echo
    git --no-pager diff
    echo
}

# Main script dispatcher
case "$1" in
    "status"|"st")
        show_status
        ;;
    "sync"|"s")
        shift
        sync_dotfiles "$*"
        ;;
    "diff"|"d")
        show_diff
        ;;
    "help"|"-h"|"--help")
        print_help
        ;;
    *)
        print_help
        ;;
esac
