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
Usage: $(basename "$0") <command> [options]

Commands:
  status, st         Show status of dotfiles (local and remote sync info)
  sync, s [msg]      Sync dotfiles (add, commit, pull, push). 
                     If no message provided, AI will generate one using local LLM (with fallback).
  diff, d            Show diff of changes
  help, -h, --help   Show this help message

Features:
  🧠 AI-powered commit messages using your local Ollama models (phi4, llama, etc.)
  📏 Automatic adherence to GitHub/GitLab message length limits (≤72 chars)
  🔄 Graceful fallback to rule-based messages if AI is unavailable
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

# Function to generate commit message using local LLM with fallback
generate_commit_message() {
    local files_changed
    files_changed=$(git diff --cached --name-only)
    
    # Try AI-generated commit message first
    local ai_message
    ai_message=$(generate_ai_commit_message "$files_changed")
    
    if [ -n "$ai_message" ] && [ "$ai_message" != "FALLBACK" ]; then
        print_success "Generated: \"$ai_message\"" >&2
        echo "$ai_message"
        return 0
    fi
    
    # Fallback to original logic if AI fails
    print_warning "AI commit message generation failed, using fallback logic" >&2
    generate_fallback_commit_message "$files_changed"
}

# Function to generate commit message using local LLM
generate_ai_commit_message() {
    local files_changed="$1"
    
    # Check if ollama is available
    if ! command -v ollama >/dev/null 2>&1; then
        return 1
    fi
    
    # Check if ollama service is running
    if ! ollama list >/dev/null 2>&1; then
        return 1
    fi
    
    print_status "🧠 Generating AI commit message..." >&2
    
    # Get detailed git diff for better context
    local diff_context
    diff_context=$(git diff --cached --unified=2 2>/dev/null | head -50)
    
    # If diff is too long, get a summary instead
    if [ ${#diff_context} -gt 2000 ]; then
        diff_context=$(git diff --cached --stat --summary 2>/dev/null | head -15)
    fi
    
    # Prepare the prompt for the LLM with better context
    local prompt="You are a git commit message generator. Analyze the actual code changes and create a precise, professional commit message.

RULES:
- Maximum 72 characters for the subject line
- Use conventional commit format (feat:, fix:, config:, docs:, refactor:, style:)
- Be specific about what actually changed, not generic descriptions
- Focus on the PURPOSE of the change, not just what files were modified
- NO quotes, explanations, or extra text

Files changed: $files_changed

Actual changes (git diff):
$diff_context

Generate ONLY the commit message:"

    # Check if phi4 model is loaded and provide feedback
    if ollama ps 2>/dev/null | grep -q "phi4"; then
        echo -e "${BLUE}   →${NC} Using phi4 model (already loaded)" >&2
    else
        echo -e "${BLUE}   →${NC} Loading phi4 model..." >&2
    fi

    # Query phi4 with timeout
    local ai_response
    ai_response=$(timeout 15s ollama run phi4 "$prompt" 2>/dev/null | head -1 | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Validate the response
    if [ -n "$ai_response" ] && [ ${#ai_response} -le 72 ] && [ ${#ai_response} -ge 8 ]; then
        # Clean up the message (remove quotes if present)
        ai_response=$(echo "$ai_response" | sed 's/^["'\'']*//;s/["'\'']*$//')
        echo "$ai_response"
        return 0
    fi
    
    echo -e "${YELLOW}[!]${NC} phi4 failed to generate suitable commit message" >&2
    return 1
}

# Original commit message generation logic (fallback)
generate_fallback_commit_message() {
    local files_changed="$1"
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
    
    # Ensure fallback message isn't too long (GitHub/GitLab limit ~72 chars for subject)
    if [ ${#changes} -gt 72 ]; then
        changes="Updated dotfiles configuration files"
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
            print_status "Using provided commit message: \"$commit_msg\""
        else
            commit_msg=$(generate_commit_message)
        fi

        if git commit -m "$commit_msg" >/dev/null 2>&1; then
            print_success "Committed: $commit_msg"
        else
            print_error "Failed to commit changes"
            return 1
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
