#!/bin/bash
set -euo pipefail

# Advanced Dotfiles Management Script
# Version: 2.0
# Features: AI commits, smart sync, backups, templates, hooks

# ============================================================================
# CONFIGURATION & COLORS
# ============================================================================

# Colors (optimized for kitty terminal)
declare -r RED='\033[0;31m'
declare -r GREEN='\033[0;32m'
declare -r BLUE='\033[0;34m'
declare -r YELLOW='\033[1;33m'
declare -r PURPLE='\033[0;35m'
declare -r CYAN='\033[0;36m'
declare -r WHITE='\033[1;37m'
declare -r GRAY='\033[0;90m'
declare -r NC='\033[0m'

# Script configuration
declare -r SCRIPT_VERSION="2.0"
declare -r CONFIG_FILE="$HOME/.dotfiles-config"
declare -r LOG_FILE="/tmp/dotfiles-$(date +%Y%m%d).log"
declare -r BACKUP_DIR="$HOME/.dotfiles-backups"

# Default settings
declare -A CONFIG=(
    [ai_enabled]="true"
    [ai_model]="auto"
    [auto_backup]="true"
    [confirm_actions]="true"
    [log_level]="info"
    [remote_protocol]="ssh"
    [max_backups]="10"
    [hook_dir]="$HOME/.dotfiles-hooks"
)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    local level="$1"
    shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $*" >> "$LOG_FILE"
}

print_status()   { echo -e "${BLUE}[*]${NC} $1"; log "INFO" "$1"; }
print_success()  { echo -e "${GREEN}[✓]${NC} $1"; log "SUCCESS" "$1"; }
print_error()    { echo -e "${RED}[✗]${NC} $1"; log "ERROR" "$1"; }
print_warning()  { echo -e "${YELLOW}[!]${NC} $1"; log "WARNING" "$1"; }
print_info()     { echo -e "${CYAN}[i]${NC} $1"; log "INFO" "$1"; }
print_debug()    { [[ "${CONFIG[log_level]}" == "debug" ]] && echo -e "${GRAY}[d]${NC} $1"; log "DEBUG" "$1"; }

print_header() {
    echo -e "${PURPLE}╭─────────────────────────────────────────────╮${NC}"
    echo -e "${PURPLE}│${NC} $1 ${PURPLE}│${NC}"
    echo -e "${PURPLE}╰─────────────────────────────────────────────╯${NC}"
}

print_banner() {
    cat << 'EOF'
╭──────────────────────────────────────────────────────────────╮
│  ____        _    __ _ _             __  __                   │
│ |  _ \  ___ | |_ / _(_) | ___  ___  |  \/  | __ _ _ __   __ _  │
│ | | | |/ _ \| __| |_| | |/ _ \/ __| | |\/| |/ _` | '_ \ / _` | │
│ | |_| | (_) | |_|  _| | |  __/\__ \ | |  | | (_| | | | | (_| | │
│ |____/ \___/ \__|_| |_|_|\___||___/ |_|  |_|\__, |_| |_|\__,_| │
│                                             |___/             │
│                    Advanced Edition v2.0                     │
╰──────────────────────────────────────────────────────────────╯
EOF
}

confirm_action() {
    if [[ "${CONFIG[confirm_actions]}" == "false" ]]; then
        return 0
    fi
    
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        read -p "$message [Y/n]: " -n 1 -r
        echo
        [[ -z "$REPLY" || "$REPLY" =~ ^[Yy]$ ]]
    else
        read -p "$message [y/N]: " -n 1 -r
        echo
        [[ "$REPLY" =~ ^[Yy]$ ]]
    fi
}

spinner() {
    local pid=$1
    local message="$2"
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    
    while kill -0 $pid 2>/dev/null; do
        for (( i=0; i<${#chars}; i++ )); do
            printf "\r${BLUE}[${chars:$i:1}]${NC} $message..."
            sleep 0.1
        done
    done
    printf "\r${GREEN}[✓]${NC} $message completed!\n"
}

# ============================================================================
# CONFIGURATION MANAGEMENT
# ============================================================================

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        print_debug "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        print_debug "No config file found, using defaults"
    fi
}

save_config() {
    print_status "Saving configuration..."
    cat > "$CONFIG_FILE" << EOF
# Dotfiles Management Configuration
# Generated on $(date)

declare -A CONFIG=(
$(for key in "${!CONFIG[@]}"; do
    echo "    [$key]=\"${CONFIG[$key]}\""
done)
)
EOF
    print_success "Configuration saved to $CONFIG_FILE"
}

show_config() {
    print_header "Current Configuration"
    for key in "${!CONFIG[@]}"; do
        echo -e "${YELLOW}$key${NC}: ${CONFIG[$key]}"
    done
}

configure() {
    print_header "Interactive Configuration"
    
    echo -e "${CYAN}AI Settings:${NC}"
    read -p "Enable AI commit messages? [${CONFIG[ai_enabled]}]: " -r
    [[ -n "$REPLY" ]] && CONFIG[ai_enabled]="$REPLY"
    
    if [[ "${CONFIG[ai_enabled]}" == "true" ]]; then
        echo -e "\nAvailable AI models:"
        if command -v ollama >/dev/null 2>&1 && ollama list >/dev/null 2>&1; then
            ollama list | tail -n +2 | awk '{print "  - " $1}'
        fi
        read -p "Preferred AI model [${CONFIG[ai_model]}]: " -r
        [[ -n "$REPLY" ]] && CONFIG[ai_model]="$REPLY"
    fi
    
    echo -e "\n${CYAN}Backup Settings:${NC}"
    read -p "Auto-backup before major operations? [${CONFIG[auto_backup]}]: " -r
    [[ -n "$REPLY" ]] && CONFIG[auto_backup]="$REPLY"
    
    read -p "Maximum backups to keep [${CONFIG[max_backups]}]: " -r
    [[ -n "$REPLY" ]] && CONFIG[max_backups]="$REPLY"
    
    echo -e "\n${CYAN}General Settings:${NC}"
    read -p "Confirm actions? [${CONFIG[confirm_actions]}]: " -r
    [[ -n "$REPLY" ]] && CONFIG[confirm_actions]="$REPLY"
    
    read -p "Log level (info/debug) [${CONFIG[log_level]}]: " -r
    [[ -n "$REPLY" ]] && CONFIG[log_level]="$REPLY"
    
    save_config
}

# ============================================================================
# AI COMMIT MESSAGE GENERATION
# ============================================================================

detect_ai_model() {
    if [[ "${CONFIG[ai_model]}" != "auto" ]]; then
        echo "${CONFIG[ai_model]}"
        return
    fi
    
    if ! command -v ollama >/dev/null 2>&1; then
        return 1
    fi
    
    local available_models
    available_models=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' || echo "")
    
    # Priority order for model selection
    local priority_models=(
        "qwen2.5-coder:14b"
        "qwen2.5-coder:7b"
        "qwen2.5-coder:1.5b"
        "codegemma:7b"
        "codegemma:2b"
        "mistral:7b-instruct"
        "mistral:7b"
        "llama3.2:3b"
        "llama3.2:1b"
    )
    
    for model in "${priority_models[@]}"; do
        if echo "$available_models" | grep -q "^${model}$"; then
            echo "$model"
            return 0
        fi
    done
    
    # If no priority model found, use the first available
    echo "$available_models" | head -1
}

generate_ai_commit_message() {
    if [[ "${CONFIG[ai_enabled]}" != "true" ]]; then
        generate_fallback_commit_message
        return
    fi
    
    local files_changed diff_summary
    files_changed=$(git diff --cached --name-only)
    diff_summary=$(git diff --cached --stat)
    
    if [[ -z "$files_changed" ]]; then
        echo "No changes staged"
        return 1
    fi
    
    # Check Ollama availability
    if ! command -v ollama >/dev/null 2>&1; then
        print_warning "Ollama not found, using fallback commit message"
        generate_fallback_commit_message
        return
    fi
    
    if ! timeout 3 ollama list >/dev/null 2>&1; then
        print_warning "Ollama not responding, using fallback commit message"
        generate_fallback_commit_message
        return
    fi
    
    local model
    model=$(detect_ai_model)
    if [[ -z "$model" ]]; then
        print_warning "No suitable AI model found, using fallback commit message"
        generate_fallback_commit_message
        return
    fi
    
    print_status "🤖 Generating AI commit message using ${BLUE}$model${NC}..."
    
    local prompt="You are an expert at writing git commit messages. Create a concise, descriptive commit message for these dotfiles changes.

Files changed:
$files_changed

Diff summary:
$diff_summary

Requirements:
- Use conventional commit format (feat:, fix:, chore:, docs:, style:, refactor:)
- Keep the subject line under 72 characters
- Be specific about what changed
- Use present tense imperative mood
- Focus on the most important changes
- Don't mention 'dotfiles' unless necessary

Generate ONLY the commit message with no explanation or quotes:"

    # Generate AI message with timeout and error handling
    local ai_output exit_code
    {
        ai_output=$(timeout 30 ollama run "$model" "$prompt" 2>&1)
        exit_code=$?
    } &
    
    local ollama_pid=$!
    spinner $ollama_pid "AI generating commit message"
    wait $ollama_pid
    
    if [[ $exit_code -ne 0 ]]; then
        print_warning "AI generation failed (exit code: $exit_code), using fallback"
        print_debug "AI error output: $ai_output"
        generate_fallback_commit_message
        return
    fi
    
    # Process AI output
    local ai_message
    ai_message=$(echo "$ai_output" | head -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/^["'\'']*//;s/["'\'']*$//')
    
    # Validate message
    if [[ -n "$ai_message" ]] && [[ ${#ai_message} -ge 10 ]] && [[ ${#ai_message} -le 200 ]]; then
        echo "$ai_message"
    else
        print_warning "AI generated invalid message (length: ${#ai_message}): '$ai_message'"
        generate_fallback_commit_message
    fi
}

generate_fallback_commit_message() {
    local files_changed
    files_changed=$(git diff --cached --name-only)
    
    # Smart message generation based on file patterns
    local message=""
    local file_count
    file_count=$(echo "$files_changed" | wc -l)
    
    # Categorize changes
    local configs=() scripts=() docs=() other=()
    
    while IFS= read -r file; do
        case "$file" in
            config/*|.*rc|.*config*) configs+=("$file") ;;
            scripts/*|bin/*|*.sh) scripts+=("$file") ;;
            README*|*.md|docs/*) docs+=("$file") ;;
            *) other+=("$file") ;;
        esac
    done <<< "$files_changed"
    
    # Generate message based on dominant category
    if [[ ${#configs[@]} -gt 0 ]]; then
        local app_names=()
        for config in "${configs[@]}"; do
            local app
            app=$(echo "$config" | sed -E 's|^config/([^/]+)/.*|\1|;s|^\.([^/]+).*|\1|' | head -1)
            [[ -n "$app" && ! " ${app_names[*]} " =~ " $app " ]] && app_names+=("$app")
        done
        
        if [[ ${#app_names[@]} -eq 1 ]]; then
            message="config: update ${app_names[0]} configuration"
        elif [[ ${#app_names[@]} -le 3 ]]; then
            message="config: update $(IFS=", "; echo "${app_names[*]}")"
        else
            message="config: update multiple configurations"
        fi
    elif [[ ${#scripts[@]} -gt 0 ]]; then
        message="scripts: update automation scripts"
    elif [[ ${#docs[@]} -gt 0 ]]; then
        message="docs: update documentation"
    else
        if [[ $file_count -eq 1 ]]; then
            message="chore: update $(basename "$files_changed")"
        else
            message="chore: update $file_count files"
        fi
    fi
    
    echo "$message"
}

# ============================================================================
# BACKUP MANAGEMENT
# ============================================================================

create_backup() {
    if [[ "${CONFIG[auto_backup]}" != "true" ]]; then
        return 0
    fi
    
    print_status "Creating backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    # Create backup using git bundle (includes history)
    if git bundle create "$backup_path.bundle" --all; then
        print_success "Backup created: $backup_path.bundle"
        
        # Clean old backups
        cleanup_old_backups
    else
        print_error "Failed to create backup"
        return 1
    fi
}

cleanup_old_backups() {
    local backup_count
    backup_count=$(find "$BACKUP_DIR" -name "backup-*.bundle" | wc -l)
    
    if [[ $backup_count -gt ${CONFIG[max_backups]} ]]; then
        print_status "Cleaning old backups (keeping ${CONFIG[max_backups]})"
        find "$BACKUP_DIR" -name "backup-*.bundle" -type f -printf '%T@ %p\n' | \
            sort -n | head -n -"${CONFIG[max_backups]}" | cut -d' ' -f2- | \
            xargs rm -f
    fi
}

list_backups() {
    print_header "Available Backups"
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR"/*.bundle 2>/dev/null)" ]]; then
        print_info "No backups found"
        return
    fi
    
    find "$BACKUP_DIR" -name "backup-*.bundle" -type f -printf '%T@ %p\n' | \
        sort -rn | while read -r timestamp path; do
            local date_str
            date_str=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S')
            local size
            size=$(du -h "$path" | cut -f1)
            echo -e "${CYAN}$(basename "$path")${NC} - ${date_str} (${size})"
        done
}

restore_backup() {
    local backup_name="$1"
    
    if [[ -z "$backup_name" ]]; then
        list_backups
        echo
        read -p "Enter backup name to restore: " backup_name
    fi
    
    local backup_path="$BACKUP_DIR/$backup_name"
    if [[ ! -f "$backup_path" ]]; then
        backup_path="$BACKUP_DIR/$backup_name.bundle"
    fi
    
    if [[ ! -f "$backup_path" ]]; then
        print_error "Backup not found: $backup_name"
        return 1
    fi
    
    if ! confirm_action "This will reset your repository to the backup state. Continue?"; then
        print_info "Restore cancelled"
        return 0
    fi
    
    print_status "Restoring from backup: $backup_name"
    
    # Create a safety backup first
    local safety_backup="$BACKUP_DIR/pre-restore-$(date +%Y%m%d-%H%M%S).bundle"
    git bundle create "$safety_backup" --all
    
    # Restore from bundle
    if git bundle verify "$backup_path" && git reset --hard && git clean -fd; then
        print_success "Backup restored successfully"
        print_info "Safety backup created: $(basename "$safety_backup")"
    else
        print_error "Failed to restore backup"
        return 1
    fi
}

# ============================================================================
# ENHANCED GIT OPERATIONS
# ============================================================================

smart_status() {
    print_header "Repository Status"
    
    # Basic git status with colors
    local git_status
    git_status=$(git status --porcelain)
    
    if [[ -z "$git_status" ]]; then
        print_success "Working directory clean"
    else
        echo -e "${YELLOW}Changes detected:${NC}"
        while IFS= read -r line; do
            local status="${line:0:2}"
            local filename="${line:3}"
            case "$status" in
                " M"|"M "|"MM") echo -e "  ${YELLOW}Modified:${NC}   $filename" ;;
                "A "|"AM")      echo -e "  ${GREEN}Added:${NC}      $filename" ;;
                "D "|" D")      echo -e "  ${RED}Deleted:${NC}    $filename" ;;
                "R ")           echo -e "  ${BLUE}Renamed:${NC}    $filename" ;;
                "??")           echo -e "  ${CYAN}Untracked:${NC}  $filename" ;;
                *)              echo -e "  ${GRAY}Unknown:${NC}    $filename" ;;
            esac
        done <<< "$git_status"
    fi
    
    echo
    
    # Branch information
    local current_branch
    current_branch=$(git branch --show-current)
    echo -e "${PURPLE}Current branch:${NC} $current_branch"
    
    # Remote sync status
    git fetch --quiet 2>/dev/null || true
    
    local local_commit remote_commit base_commit
    local_commit=$(git rev-parse @ 2>/dev/null)
    remote_commit=$(git rev-parse @{u} 2>/dev/null || echo "")
    base_commit=$(git merge-base @ @{u} 2>/dev/null || echo "")
    
    if [[ -n "$remote_commit" ]]; then
        if [[ "$local_commit" == "$remote_commit" ]]; then
            print_success "Branch is up to date with remote"
        elif [[ "$local_commit" == "$base_commit" ]]; then
            print_warning "Branch is behind remote"
            local commits_behind
            commits_behind=$(git rev-list --count @..@{u})
            echo -e "  ${GRAY}Behind by $commits_behind commits${NC}"
        elif [[ "$remote_commit" == "$base_commit" ]]; then
            print_info "Branch is ahead of remote"
            local commits_ahead
            commits_ahead=$(git rev-list --count @{u}..@)
            echo -e "  ${GRAY}Ahead by $commits_ahead commits${NC}"
        else
            print_warning "Branch has diverged from remote"
            local ahead behind
            ahead=$(git rev-list --count @{u}..@)
            behind=$(git rev-list --count @..@{u})
            echo -e "  ${GRAY}Ahead by $ahead, behind by $behind commits${NC}"
        fi
    else
        print_info "No remote tracking branch"
    fi
    
    # Recent commits
    echo -e "\n${PURPLE}Recent commits:${NC}"
    git log --oneline --color=always -5 | sed 's/^/  /'
}

enhanced_diff() {
    local target="${1:-}"
    
    print_header "Changes Overview"
    
    if [[ -n "$target" ]]; then
        git --no-pager diff --color=always "$target"
    else
        # Show both staged and unstaged changes
        local staged_changes unstaged_changes
        staged_changes=$(git diff --cached --name-only)
        unstaged_changes=$(git diff --name-only)
        
        if [[ -n "$staged_changes" ]]; then
            echo -e "${GREEN}Staged changes:${NC}"
            git --no-pager diff --cached --stat --color=always
            echo
            git --no-pager diff --cached --color=always
            echo
        fi
        
        if [[ -n "$unstaged_changes" ]]; then
            echo -e "${YELLOW}Unstaged changes:${NC}"
            git --no-pager diff --stat --color=always
            echo
            git --no-pager diff --color=always
        fi
        
        if [[ -z "$staged_changes" && -z "$unstaged_changes" ]]; then
            print_info "No changes to display"
        fi
    fi
}

smart_sync() {
    local commit_message="$1"
    
    print_header "Smart Sync Operation"
    
    # Create backup before major operation
    create_backup
    
    # Check for uncommitted changes
    if git status --porcelain | grep -q '^'; then
        print_status "Staging and committing local changes..."
        git add -A
        
        # Generate commit message
        if [[ -z "$commit_message" ]]; then
            local ai_message
            ai_message=$(generate_ai_commit_message)
            
            echo
            print_status "🤖 AI suggests:"
            echo -e "   ${GREEN}\"$ai_message\"${NC}"
            echo
            
            local choice
            echo "Choose an option:"
            echo "  [1] Use AI message (default)"
            echo "  [2] Use fallback message"
            echo "  [3] Enter custom message"
            echo "  [4] Show diff first"
            read -p "Choice [1]: " choice
            
            case "${choice:-1}" in
                1) commit_message="$ai_message" ;;
                2) commit_message=$(generate_fallback_commit_message) ;;
                3) 
                    echo -n "Enter commit message: "
                    read -r commit_message
                    [[ -z "$commit_message" ]] && commit_message="$ai_message"
                    ;;
                4)
                    enhanced_diff
                    echo
                    read -p "Press Enter to continue with AI message or type new message: " commit_message
                    [[ -z "$commit_message" ]] && commit_message="$ai_message"
                    ;;
                *) commit_message="$ai_message" ;;
            esac
        fi
        
        if git commit -m "$commit_message"; then
            print_success "Changes committed: $commit_message"
        else
            print_error "Failed to commit changes"
            return 1
        fi
    else
        print_info "No local changes to commit"
    fi
    
    # Sync with remote
    print_status "Syncing with remote..."
    
    if git pull --rebase; then
        print_success "Successfully pulled changes"
    else
        print_error "Failed to pull changes - you may have conflicts to resolve"
        print_info "Run 'git status' to see conflicts, then 'git rebase --continue' or 'git rebase --abort'"
        return 1
    fi
    
    if git push; then
        print_success "Successfully pushed changes"
    else
        print_error "Failed to push changes"
        return 1
    fi
    
    print_success "Sync completed successfully!"
}

# ============================================================================
# HOOKS SYSTEM
# ============================================================================

run_hook() {
    local hook_name="$1"
    shift
    local hook_file="${CONFIG[hook_dir]}/$hook_name"
    
    if [[ -f "$hook_file" && -x "$hook_file" ]]; then
        print_debug "Running hook: $hook_name"
        "$hook_file" "$@"
    fi
}

create_hook() {
    local hook_name="$1"
    
    if [[ -z "$hook_name" ]]; then
        echo "Available hooks:"
        echo "  pre-sync    - Run before sync operation"
        echo "  post-sync   - Run after successful sync"
        echo "  pre-commit  - Run before creating commit"
        echo "  post-commit - Run after creating commit"
        echo
        read -p "Enter hook name: " hook_name
    fi
    
    mkdir -p "${CONFIG[hook_dir]}"
    local hook_file="${CONFIG[hook_dir]}/$hook_name"
    
    if [[ -f "$hook_file" ]]; then
        if ! confirm_action "Hook already exists. Overwrite?"; then
            return 0
        fi
    fi
    
    cat > "$hook_file" << EOF
#!/bin/bash
# Dotfiles hook: $hook_name
# Arguments: \$@

echo "Running $hook_name hook..."

# Add your custom commands here
# Examples:
# - Restart services
# - Update symlinks  
# - Run tests
# - Send notifications

EOF
    
    chmod +x "$hook_file"
    print_success "Hook created: $hook_file"
    
    if confirm_action "Edit hook now?"; then
        "${EDITOR:-nano}" "$hook_file"
    fi
}

# ============================================================================
# HELP AND USAGE
# ============================================================================

show_help() {
    print_banner
    cat << EOF

${YELLOW}USAGE:${NC}
  $(basename "$0") [--options] <command> [arguments]

${YELLOW}COMMANDS:${NC}
  ${GREEN}status, st${NC}           Show detailed repository status
  ${GREEN}sync, s [msg]${NC}        Smart sync with AI commit messages
  ${GREEN}diff, d [target]${NC}     Show enhanced diff view
  ${GREEN}backup${NC}               Create manual backup
  ${GREEN}restore [name]${NC}       Restore from backup
  ${GREEN}backups${NC}              List available backups
  ${GREEN}config${NC}               Interactive configuration
  ${GREEN}config-show${NC}          Show current configuration
  ${GREEN}hook [name]${NC}          Create or edit hooks
  ${GREEN}install${NC}              Install/setup dotfiles
  ${GREEN}cleanup${NC}              Clean repository and backups
  ${GREEN}doctor${NC}               Diagnose common issues
  ${GREEN}help, -h, --help${NC}     Show this help

${YELLOW}OPTIONS:${NC}
  ${CYAN}--no-confirm${NC}         Skip confirmation prompts
  ${CYAN}--no-backup${NC}          Skip automatic backups
  ${CYAN}--no-ai${NC}              Disable AI commit messages
  ${CYAN}--debug${NC}              Enable debug logging
  ${CYAN}--remote=ssh|https${NC}   Set remote protocol

${YELLOW}FEATURES:${NC}
  🤖 AI-powered commit messages using local Ollama
  💾 Automatic backups before major operations
  🔄 Smart sync with conflict detection
  🎯 Hooks system for custom automation
  📊 Enhanced status and diff views
  ⚙️  Interactive configuration management
  🩺 Built-in diagnostics and repair tools

${YELLOW}EXAMPLES:${NC}
  $(basename "$0") sync                    # AI-powered sync
  $(basename "$0") sync "custom message"   # Sync with custom message
  $(basename "$0") diff HEAD~1             # Show changes since last commit
  $(basename "$0") restore backup-20240101 # Restore specific backup
  $(basename "$0") --no-confirm sync       # Sync without prompts

${YELLOW}CONFIGURATION:${NC}
  Config file: ${CONFIG_FILE}
  Log file: ${LOG_FILE}
  Backup dir: ${BACKUP_DIR}
  
  Run '$(basename "$0") config' for interactive setup.

EOF
}

# ============================================================================
# ADVANCED FEATURES
# ============================================================================

doctor() {
    print_header "System Diagnostics"
    
    local issues=0
    
    # Check git configuration
    print_status "Checking git configuration..."
    if git config user.name >/dev/null && git config user.email >/dev/null; then
        print_success "Git user configuration OK"
    else
        print_error "Git user not configured"
        echo -e "  Run: ${CYAN}git config --global user.name 'Your Name'${NC}"
        echo -e "  Run: ${CYAN}git config --global user.email 'your@email.com'${NC}"
        ((issues++))
    fi
    
    # Check repository status
    print_status "Checking repository..."
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print_success "Inside git repository"
    else
        print_error "Not inside a git repository"
        ((issues++))
    fi
    
    # Check remote
    if git remote get-url origin >/dev/null 2>&1; then
        print_success "Remote origin configured"
    else
        print_warning "No remote origin found"
    fi
    
    # Check AI setup
    print_status "Checking AI setup..."
    if command -v ollama >/dev/null 2>&1; then
        if ollama list >/dev/null 2>&1; then
            local model_count
            model_count=$(ollama list | tail -n +2 | wc -l)
            print_success "Ollama running with $model_count models"
        else
            print_warning "Ollama installed but not running"
            echo -e "  Run: ${CYAN}ollama serve${NC}"
        fi
    else
        print_info "Ollama not installed (AI features disabled)"
        echo -e "  Install: ${CYAN}curl -fsSL https://ollama.ai/install.sh | sh${NC}"
    fi
    
    # Check backup directory
    print_status "Checking backup system..."
    if [[ -d "$BACKUP_DIR" ]]; then
        local backup_count
        backup_count=$(find "$BACKUP_DIR" -name "*.bundle" 2>/dev/null | wc -l)
        print_success "Backup directory OK ($backup_count backups)"
    else
        print_info "Backup directory will be created when needed"
    fi
    
    # Check hooks
    print_status "Checking hooks..."
    if [[ -d "${CONFIG[hook_dir]}" ]]; then
        local hook_count
        hook_count=$(find "${CONFIG[hook_dir]}" -type f -executable 2>/dev/null | wc -l)
        if [[ $hook_count -gt 0 ]]; then
            print_success "Found $hook_count executable hooks"
        else
            print_info "No hooks configured"
        fi
    else
        print_info "No hooks directory"
    fi
    
    echo
    if [[ $issues -eq 0 ]]; then
        print_success "All checks passed! 🎉"
    else
        print_warning "Found $issues issues that should be addressed"
    fi
}

cleanup() {
    print_header "Repository Cleanup"
    
    if confirm_action "This will clean untracked files and optimize the repository. Continue?"; then
        print_status "Cleaning untracked files..."
        git clean -fd
        
        print_status "Running git maintenance..."
        git gc --prune=now
        
        print_status "Cleaning old backups..."
        cleanup_old_backups
        
        print_success "Cleanup completed"
    fi
}

install_dotfiles() {
    print_header "Dotfiles Installation"
    
    # This is a placeholder for installation logic
    # You can customize this based on your dotfiles structure
    
    print_status "Setting up dotfiles environment..."
    
    # Create necessary directories
    mkdir -p "$BACKUP_DIR"
    mkdir -p "${CONFIG[hook_dir]}"
    
    # Set up initial configuration
    if [[ ! -f "$CONFIG_FILE" ]]; then
        save_config
    fi
    
    # Check for install script
    local install_script="./install.sh"
    if [[ -f "$install_script" ]]; then
        if confirm_action "Run local install script?"; then
            bash "$install_script"
        fi
    fi
    
    print_success "Installation completed!"
    print_info "Run '$(basename "$0") config' to customize settings"
}

# ============================================================================
# ARGUMENT PARSING AND MAIN EXECUTION
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-confirm)
                CONFIG[confirm_actions]="false"
                shift
                ;;
            --no-backup)
                CONFIG[auto_backup]="false"
                shift
                ;;
            --no-ai)
                CONFIG[ai_enabled]="false"
                shift
                ;;
            --debug)
                CONFIG[log_level]="debug"
                shift
                ;;
            --remote=*)
                CONFIG[remote_protocol]="${1#*=}"
                shift
                ;;
            --remote)
                CONFIG[remote_protocol]="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                print_error "Unknown option: $1"
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Return remaining arguments
    echo "$@"
}

main() {
    # Load configuration
    load_config
    
    # Parse arguments
    local remaining_args
    remaining_args=$(parse_arguments "$@")
    eval set -- "$remaining_args"
    
    # Ensure we're in a git repository for most commands
    local git_commands=("status" "st" "sync" "s" "diff" "d" "backup" "cleanup")
    local command="${1:-help}"
    
    if [[ " ${git_commands[*]} " =~ " $command " ]]; then
        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            print_error "Not inside a Git repository!"
            exit 2
        fi
        
        # Change to repository root
        local repo_root
        repo_root=$(git rev-parse --show-toplevel)
        cd "$repo_root" || {
            print_error "Failed to change to repository root: $repo_root"
            exit 1
        }
        print_debug "Using repository root: $repo_root"
    fi
    
    # Run pre-command hook
    run_hook "pre-$command" "$@"
    
    # Command dispatcher
    case "$command" in
        "status"|"st")
            smart_status
            ;;
        "sync"|"s")
            shift
            smart_sync "$*"
            ;;
        "diff"|"d")
            shift
            enhanced_diff "$1"
            ;;
        "backup")
            create_backup
            ;;
        "restore")
            shift
            restore_backup "$1"
            ;;
        "backups")
            list_backups
            ;;
        "config")
            configure
            ;;
        "config-show")
            show_config
            ;;
        "hook")
            shift
            create_hook "$1"
            ;;
        "install")
            install_dotfiles
            ;;
        "cleanup")
            cleanup
            ;;
        "doctor")
            doctor
            ;;
        "help"|"-h"|"--help"|"")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo "Run '$(basename "$0") help' for usage information"
            exit 1
            ;;
    esac
    
    # Run post-command hook
    run_hook "post-$command" "$@"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Handle script interruption gracefully
trap 'print_error "Script interrupted"; exit 130' INT TERM

# Create log file directory if needed
mkdir -p "$(dirname "$LOG_FILE")"

# Execute main function with all arguments
main "$@"
