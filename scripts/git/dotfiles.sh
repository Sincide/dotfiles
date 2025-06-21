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
  sync, s [msg]      Sync dotfiles (add, commit, pull, push). 
                     Uses AI-generated commit messages if no message provided.
                     Optionally provide a custom commit message.
  diff, d            Show diff of changes
  help, -h, --help   Show this help message

Features:
  🤖 AI Commit Messages - Uses local Ollama (mistral:7b-instruct) to generate
                         smart commit messages based on your changes.
                         Falls back to basic messages if AI unavailable.
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
            repo_url=$(git remote get-url origin)
            domain=$(echo "$repo_url" | sed -E 's|.*@([^:]+):.*|\1|;s|https?://([^/]+)/.*|\1|')
            repo_path=$(echo "$repo_url" | sed -E 's|.*[:/](.+/.+)(\.git)?$|\1|')
            git remote set-url origin "git@$domain:$repo_path"
            print_success "Remote set to SSH"
            shift
            ;;
        --remote=https)
            repo_url=$(git remote get-url origin)
            domain=$(echo "$repo_url" | sed -E 's|.*@([^:]+):.*|\1|;s|https?://([^/]+)/.*|\1|')
            repo_path=$(echo "$repo_url" | sed -E 's|.*[:/](.+/.+)(\.git)?$|\1|')
            git remote set-url origin "https://$domain/$repo_path"
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

# Function to generate AI-powered commit message
generate_ai_commit_message() {
    local files_changed
    files_changed=$(git diff --cached --name-only)
    local diff_summary
    diff_summary=$(git diff --cached --stat)
    
    if [ -z "$files_changed" ]; then
        echo "No changes staged"
        return 1
    fi
    
    # Check if Ollama is available
    if ! command -v ollama >/dev/null 2>&1; then
        print_warning "Ollama not found, falling back to basic commit message"
        generate_commit_message
        return
    fi
    
    # Check if Ollama is running
    if ! ollama list >/dev/null 2>&1; then
        print_warning "Ollama not running, falling back to basic commit message"
        generate_commit_message
        return
    fi
    
    print_status "🤖 Generating AI commit message..."
    
    # Create prompt for AI
    local prompt="You are a git commit message expert. Generate a concise, descriptive commit message for these dotfiles changes.

Files changed:
$files_changed

Diff summary:
$diff_summary

Rules:
- Use conventional commit format when appropriate (feat:, fix:, chore:, docs:, style:)
- Be specific about what changed
- Keep it under 72 characters for the first line
- Focus on the most important changes
- Use present tense
- Don't include 'dotfiles' in every message

Generate only the commit message, no explanation:"

    # Try to get AI response
    local ai_message
    ai_message=$(ollama run mistral:7b-instruct "$prompt" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    if [ -n "$ai_message" ] && [ ${#ai_message} -gt 5 ]; then
        echo "$ai_message"
    else
        print_warning "AI failed to generate message, falling back to basic commit message"
        generate_commit_message
    fi
}

# Function to generate commit message based on changes (fallback)
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

# Test SSH connection to remote
test_ssh_connection() {
    local remote_url="$1"
    local domain=""
    
    # Extract domain from remote URL
    if [[ "$remote_url" =~ git@([^:]+): ]]; then
        domain="${BASH_REMATCH[1]}"
    elif [[ "$remote_url" =~ https://([^/]+)/ ]]; then
        domain="${BASH_REMATCH[1]}"
        return 0  # HTTPS doesn't need SSH test
    else
        return 0  # Unknown format, skip test
    fi
    
    print_status "Testing SSH connection to $domain..."
    
    # Test SSH connection
    if ssh -T "git@$domain" 2>&1 | grep -q "successfully authenticated\|Welcome to"; then
        print_success "SSH connection to $domain working"
        return 0
    else
        print_error "SSH authentication failed for $domain"
        print_warning "You need to add your SSH key to $domain"
        
        # Show the appropriate public key
        local key_file=""
        if [[ "$domain" == "github.com" && -f "$HOME/.ssh/id_ed25519_github.pub" ]]; then
            key_file="$HOME/.ssh/id_ed25519_github.pub"
        elif [[ "$domain" == "gitlab.com" && -f "$HOME/.ssh/id_ed25519_gitlab.pub" ]]; then
            key_file="$HOME/.ssh/id_ed25519_gitlab.pub"
        elif [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
            key_file="$HOME/.ssh/id_ed25519.pub"
        elif [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
            key_file="$HOME/.ssh/id_rsa.pub"
        fi
        
        if [[ -n "$key_file" ]]; then
            echo
            print_status "Your SSH public key:"
            echo -e "${BLUE}$(cat "$key_file")${NC}"
            echo
            
            case "$domain" in
                "github.com")
                    print_status "Add this key to GitHub:"
                    echo -e "${YELLOW}→ https://github.com/settings/keys${NC}"
                    ;;
                "gitlab.com")
                    print_status "Add this key to GitLab:"
                    echo -e "${YELLOW}→ https://gitlab.com/-/user_settings/ssh_keys${NC}"
                    ;;
            esac
            
            echo
            read -p "Press Enter after adding the key to $domain, or Ctrl+C to abort: "
            
            # Test again
            if ssh -T "git@$domain" 2>&1 | grep -q "successfully authenticated\|Welcome to"; then
                print_success "SSH connection now working!"
                return 0
            else
                print_error "SSH connection still failing. Please check your key was added correctly."
                return 1
            fi
        else
            print_error "No SSH public key found. Run the git-ssh-setup.sh script first."
            
            # Try to run the setup script if it exists
            local setup_script="$REPO_ROOT/scripts/setup/git-ssh-setup.sh"
            if [[ -f "$setup_script" ]]; then
                echo
                read -p "Run git-ssh-setup.sh now? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    "$setup_script" -y
                    return $?
                fi
            fi
            return 1
        fi
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
            # Try AI-generated commit message first
            ai_commit_msg=$(generate_ai_commit_message)
            
            echo
            print_status "🤖 AI suggests: $ai_commit_msg"
            echo
            read -p "Use AI message? [Y/n/e=edit]: " -n 1 -r
            echo
            
            case "$REPLY" in
                [Nn])
                    # Use fallback message
                    commit_msg=$(generate_commit_message)
                    print_status "Using basic commit message: $commit_msg"
                    ;;
                [Ee])
                    # Let user edit the AI message
                    echo -n "Enter commit message: "
                    read -r commit_msg
                    if [ -z "$commit_msg" ]; then
                        commit_msg="$ai_commit_msg"
                    fi
                    ;;
                *)
                    # Use AI message (default)
                    commit_msg="$ai_commit_msg"
                    ;;
            esac
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

    # Test SSH connection before attempting to pull/push
    if ! test_ssh_connection "$REMOTE_URL"; then
        print_error "Cannot proceed without working SSH connection"
        return 1
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
