#!/bin/bash

# Git & SSH Development Setup Script
# Comprehensive setup for Git configuration and SSH keys for GitLab and GitHub
# Automatically detects existing configuration and provides intelligent setup

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/git-ssh-setup_$(date +%Y%m%d_%H%M%S).log"
readonly SSH_DIR="$HOME/.ssh"
readonly BACKUP_DIR="/mnt/Stuff/ssh-backup"
readonly DEFAULT_KEY_TYPE="ed25519"
readonly DEFAULT_KEY_SIZE="4096"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Flags
SKIP_CONFIRMATION=false
DRY_RUN=false
FORCE_BACKUP=false
SKIP_GENERATION=false
KEY_TYPE="$DEFAULT_KEY_TYPE"
KEY_SIZE="$DEFAULT_KEY_SIZE"
EMAIL=""
GITHUB_USERNAME=""
GITLAB_USERNAME=""

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging functions
log_info() {
    local msg="[INFO] ${1:-}"
    echo -e "${BLUE}$msg${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

log_success() {
    local msg="[SUCCESS] ${1:-}"
    echo -e "${GREEN}✓ $msg${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[ERROR] ${1:-}"
    echo -e "${RED}✗ $msg${NC}" >&2
    echo "$(date +'%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

log_warning() {
    local msg="[WARNING] ${1:-}"
    echo -e "${YELLOW}⚠ $msg${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

log_section() {
    local msg="${1:-}"
    echo -e "${CYAN}=== $msg ===${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [SECTION] $msg" >> "$LOG_FILE"
}

# Help function
show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Complete Git and SSH development environment setup for GitLab and GitHub.

OPTIONS:
    -h, --help              Show this help message
    -n, --dry-run           Show what would be done without making changes
    -y, --yes               Skip confirmation prompts
    --force-backup          Force backup even if keys don't exist
    --key-type TYPE         SSH key type (ed25519, rsa) [default: $DEFAULT_KEY_TYPE]
    --key-size SIZE         RSA key size in bits [default: $DEFAULT_KEY_SIZE]
    --email EMAIL           Email address for SSH key
    --github-user USER      GitHub username
    --gitlab-user USER      GitLab username

DESCRIPTION:
    This script provides comprehensive Git and SSH setup for development workflow.
    It automatically detects existing configuration, sets up Git identity, manages
    SSH keys for GitLab and GitHub, and provides complete setup instructions.

FEATURES:
    • Automatic Git identity configuration with smart name detection
    • Intelligent detection of existing SSH keys and Git configuration
    • GitHub CLI integration for seamless username detection
    • Secure backup of existing SSH keys with encryption
    • Generation of platform-specific SSH keys (ed25519/RSA)
    • Automatic SSH config file creation
    • Comprehensive setup instructions for both platforms
    • Zero-prompt operation when configuration is detected

EXAMPLES:
    $SCRIPT_NAME --email user@example.com --github-user myuser --gitlab-user myuser
    $SCRIPT_NAME --key-type rsa --key-size 4096 --email dev@company.com
    $SCRIPT_NAME -n --email test@example.com  # Dry run
    $SCRIPT_NAME -y --email auto@example.com  # Skip confirmations

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=true
                shift
                ;;
            --force-backup)
                FORCE_BACKUP=true
                shift
                ;;
            --key-type)
                if [[ -n "${2:-}" ]]; then
                    KEY_TYPE="$2"
                    shift 2
                else
                    log_error "--key-type requires a value (ed25519, rsa)"
                    exit 1
                fi
                ;;
            --key-size)
                if [[ -n "${2:-}" ]]; then
                    KEY_SIZE="$2"
                    shift 2
                else
                    log_error "--key-size requires a value"
                    exit 1
                fi
                ;;
            --email)
                if [[ -n "${2:-}" ]]; then
                    EMAIL="$2"
                    shift 2
                else
                    log_error "--email requires an email address"
                    exit 1
                fi
                ;;
            --github-user)
                if [[ -n "${2:-}" ]]; then
                    GITHUB_USERNAME="$2"
                    shift 2
                else
                    log_error "--github-user requires a username"
                    exit 1
                fi
                ;;
            --gitlab-user)
                if [[ -n "${2:-}" ]]; then
                    GITLAB_USERNAME="$2"
                    shift 2
                else
                    log_error "--gitlab-user requires a username"
                    exit 1
                fi
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running as regular user
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run as root"
        exit 1
    fi
    
    # Check required tools
    local required_tools=("ssh-keygen" "gpg" "tar")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            log_error "Required tool not found: $tool"
            exit 1
        fi
    done
    
    # Validate key type
    if [[ "$KEY_TYPE" != "ed25519" && "$KEY_TYPE" != "rsa" ]]; then
        log_error "Invalid key type: $KEY_TYPE (must be ed25519 or rsa)"
        exit 1
    fi
    
    # Validate email format
    if [[ -n "$EMAIL" && ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Invalid email format: $EMAIL"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Auto-detect existing configuration and SSH keys
auto_detect_config() {
    log_info "Auto-detecting existing configuration..."
    
    # Try to get email from git config first
    if [[ -z "$EMAIL" ]]; then
        local git_email=$(git config --global user.email 2>/dev/null || true)
        if [[ -n "$git_email" ]]; then
            EMAIL="$git_email"
            log_success "Using email from git config: $EMAIL"
        fi
    fi
    
    # Try to extract email from existing SSH public keys if still not found
    if [[ -z "$EMAIL" ]]; then
        for key_file in "$SSH_DIR"/id_*.pub; do
            if [[ -f "$key_file" ]]; then
                local key_email=$(awk '{print $NF}' "$key_file" 2>/dev/null | grep -E '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' || true)
                if [[ -n "$key_email" ]]; then
                    EMAIL="$key_email"
                    log_success "Using email from existing SSH key: $EMAIL"
                    break
                fi
            fi
        done
    fi
    
    # Try to get GitHub username from GitHub CLI if available and authenticated
    if [[ -z "$GITHUB_USERNAME" ]] && command -v gh &>/dev/null; then
        if gh auth status &>/dev/null; then
            local gh_user=$(gh api user --jq '.login' 2>/dev/null || true)
            if [[ -n "$gh_user" ]]; then
                GITHUB_USERNAME="$gh_user"
                log_success "Using GitHub username from GitHub CLI: $GITHUB_USERNAME"
                
                # Also try to get email from GitHub if not set
                if [[ -z "$EMAIL" ]]; then
                    local gh_email=$(gh api user --jq '.email' 2>/dev/null || true)
                    if [[ -n "$gh_email" && "$gh_email" != "null" ]]; then
                        EMAIL="$gh_email"
                        log_success "Using email from GitHub CLI: $EMAIL"
                    fi
                fi
            fi
        else
            log_info "GitHub CLI available but not authenticated"
            if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
                read -p "Would you like to authenticate with GitHub CLI now for auto-detection? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log_info "Starting GitHub CLI authentication..."
                    if gh auth login; then
                        log_success "GitHub CLI authenticated successfully"
                        # Retry getting user info
                        local gh_user=$(gh api user --jq '.login' 2>/dev/null || true)
                        if [[ -n "$gh_user" ]]; then
                            GITHUB_USERNAME="$gh_user"
                            log_success "Using GitHub username from GitHub CLI: $GITHUB_USERNAME"
                            
                            if [[ -z "$EMAIL" ]]; then
                                local gh_email=$(gh api user --jq '.email' 2>/dev/null || true)
                                if [[ -n "$gh_email" && "$gh_email" != "null" ]]; then
                                    EMAIL="$gh_email"
                                    log_success "Using email from GitHub CLI: $EMAIL"
                                fi
                            fi
                        fi
                    else
                        log_warning "GitHub CLI authentication failed or was cancelled"
                    fi
                fi
            else
                log_info "Skipping GitHub CLI authentication (use 'gh auth login' manually)"
            fi
        fi
    fi
    
    # Check for existing SSH keys to determine what platforms are already configured
    local existing_github_key=false
    local existing_gitlab_key=false
    
    if [[ -f "$SSH_DIR/id_ed25519_github" || -f "$SSH_DIR/id_rsa_github" ]]; then
        existing_github_key=true
        log_success "Found existing GitHub SSH key"
    fi
    
    if [[ -f "$SSH_DIR/id_ed25519_gitlab" || -f "$SSH_DIR/id_rsa_gitlab" ]]; then
        existing_gitlab_key=true
        log_success "Found existing GitLab SSH key"
    fi
    
    # Try to detect usernames from git remotes if keys exist
    if [[ "$existing_github_key" == "true" && -z "$GITHUB_USERNAME" ]]; then
        # First try current directory git remotes
        local github_remote=$(git remote -v 2>/dev/null | grep -E "github\.com[:/]" | head -1 | sed -E 's/.*github\.com[:/]([^/]+)\/.*$/\1/' || true)
        if [[ -n "$github_remote" ]]; then
            GITHUB_USERNAME="$github_remote"
            log_success "Detected GitHub username from git remote: $GITHUB_USERNAME"
        else
            # Try to find GitHub remotes in other git repos in common locations
            for git_dir in "$HOME"/*/.git "$HOME"/*/.*/.git "$DOTFILES_DIR"/.git; do
                if [[ -d "$git_dir" ]]; then
                    local repo_github_remote=$(git -C "$(dirname "$git_dir")" remote -v 2>/dev/null | grep -E "github\.com[:/]" | head -1 | sed -E 's/.*github\.com[:/]([^/]+)\/.*$/\1/' || true)
                    if [[ -n "$repo_github_remote" ]]; then
                        GITHUB_USERNAME="$repo_github_remote"
                        log_success "Detected GitHub username from git repo: $GITHUB_USERNAME"
                        break
                    fi
                fi
            done
            
            if [[ -z "$GITHUB_USERNAME" ]]; then
                log_info "GitHub SSH key exists - will prompt for username if needed"
            fi
        fi
    fi
    
    if [[ "$existing_gitlab_key" == "true" && -z "$GITLAB_USERNAME" ]]; then
        # First try current directory git remotes
        local gitlab_remote=$(git remote -v 2>/dev/null | grep -E "gitlab\.com[:/]" | head -1 | sed -E 's/.*gitlab\.com[:/]([^/]+)\/.*$/\1/' || true)
        if [[ -n "$gitlab_remote" ]]; then
            GITLAB_USERNAME="$gitlab_remote"
            log_success "Detected GitLab username from git remote: $GITLAB_USERNAME"
        else
            # Try to find GitLab remotes in other git repos in common locations
            for git_dir in "$HOME"/*/.git "$HOME"/*/.*/.git "$DOTFILES_DIR"/.git; do
                if [[ -d "$git_dir" ]]; then
                    local repo_gitlab_remote=$(git -C "$(dirname "$git_dir")" remote -v 2>/dev/null | grep -E "gitlab\.com[:/]" | head -1 | sed -E 's/.*gitlab\.com[:/]([^/]+)\/.*$/\1/' || true)
                    if [[ -n "$repo_gitlab_remote" ]]; then
                        GITLAB_USERNAME="$repo_gitlab_remote"
                        log_success "Detected GitLab username from git repo: $GITLAB_USERNAME"
                        break
                    fi
                fi
            done
            
            if [[ -z "$GITLAB_USERNAME" ]]; then
                log_info "GitLab SSH key exists - will prompt for username if needed"
            fi
        fi
    fi
    
    return 0
}

# Get user input only for missing information
get_user_input() {
    local need_input=false
    
    # Check if SSH keys already exist - if so, we might not need to generate new ones
    local existing_github_key=false
    local existing_gitlab_key=false
    
    if [[ -f "$SSH_DIR/id_${KEY_TYPE}_github" ]]; then
        existing_github_key=true
    fi
    
    if [[ -f "$SSH_DIR/id_${KEY_TYPE}_gitlab" ]]; then
        existing_gitlab_key=true
    fi
    
    # If keys exist, check if we should skip generation
    local keys_exist_count=0
    [[ "$existing_github_key" == "true" ]] && keys_exist_count=$((keys_exist_count + 1))
    [[ "$existing_gitlab_key" == "true" ]] && keys_exist_count=$((keys_exist_count + 1))
    
    if [[ $keys_exist_count -gt 0 ]]; then
        log_success "Found $keys_exist_count existing SSH key(s)"
        echo
        echo -e "${YELLOW}Existing SSH Keys Found:${NC}"
        [[ "$existing_github_key" == "true" ]] && echo "• GitHub key: ~/.ssh/id_${KEY_TYPE}_github"
        [[ "$existing_gitlab_key" == "true" ]] && echo "• GitLab key: ~/.ssh/id_${KEY_TYPE}_gitlab"
        [[ -n "$EMAIL" ]] && echo "• Email: $EMAIL"
        [[ -n "$GITHUB_USERNAME" ]] && echo "• GitHub username: $GITHUB_USERNAME"
        [[ -n "$GITLAB_USERNAME" ]] && echo "• GitLab username: $GITLAB_USERNAME"
        echo
        
        # If we have all the info we need, offer to skip generation
        if [[ -n "$EMAIL" && ((-n "$GITHUB_USERNAME" && "$existing_github_key" == "true") || (-n "$GITLAB_USERNAME" && "$existing_gitlab_key" == "true")) ]]; then
            if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
                read -p "Keys exist and configuration detected. Skip generation and show setup instructions? (Y/n): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    log_info "Skipping key generation - showing setup instructions for existing keys"
                    # Set a flag to skip generation but show instructions
                    SKIP_GENERATION=true
                    return 0
                fi
            else
                log_info "Auto-skipping key generation - using existing keys"
                SKIP_GENERATION=true
                return 0
            fi
        fi
        
        # Ask if they want to regenerate
        if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
            read -p "Do you want to regenerate the existing keys? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Keeping existing SSH keys - will show setup instructions"
                SKIP_GENERATION=true
                return 0
            fi
        fi
    fi
    
    # Prompt for missing email (but only if we really need it for new key generation)
    if [[ -z "$EMAIL" && "$SKIP_GENERATION" != "true" ]]; then
        echo
        read -p "Enter your email address: " EMAIL
        if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            log_error "Invalid email format"
            exit 1
        fi
        need_input=true
    elif [[ -z "$EMAIL" && "$SKIP_GENERATION" == "true" ]]; then
        # For existing keys, we can use a placeholder email for instructions
        EMAIL="your-email@example.com"
        log_info "Using placeholder email for setup instructions (keys already exist)"
    fi
    
    # Prompt for GitHub username if not detected and no existing key
    if [[ -z "$GITHUB_USERNAME" && "$existing_github_key" != "true" ]]; then
        echo
        read -p "Enter your GitHub username (optional, press Enter to skip): " GITHUB_USERNAME
        need_input=true
    fi
    
    # Prompt for GitLab username if not detected and no existing key  
    if [[ -z "$GITLAB_USERNAME" && "$existing_gitlab_key" != "true" ]]; then
        echo
        read -p "Enter your GitLab username (optional, press Enter to skip): " GITLAB_USERNAME
        need_input=true
    fi
    
    # If we have existing keys but no usernames, try to get them for instructions
    if [[ "$existing_github_key" == "true" && -z "$GITHUB_USERNAME" ]]; then
        echo
        read -p "Enter your GitHub username for setup instructions (optional): " GITHUB_USERNAME
    fi
    
    if [[ "$existing_gitlab_key" == "true" && -z "$GITLAB_USERNAME" ]]; then
        echo
        read -p "Enter your GitLab username for setup instructions (optional): " GITLAB_USERNAME  
    fi
    
    if [[ "$need_input" == "false" ]]; then
        log_success "All required information detected automatically"
    fi
}

# Create secure backup directory
setup_backup_directory() {
    log_info "Setting up backup directory..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would create backup directory: $BACKUP_DIR"
        return 0
    fi
    
    # Check if backup drive is mounted
    if [[ ! -d "/mnt/Stuff" ]]; then
        log_error "Backup drive not mounted at /mnt/Stuff"
        log_info "Please run the external drives setup script first"
        exit 1
    fi
    
    # Create backup directory with secure permissions
    if [[ ! -d "$BACKUP_DIR" ]]; then
        if mkdir -p "$BACKUP_DIR" 2>/dev/null; then
            chmod 700 "$BACKUP_DIR"
            log_success "Created secure backup directory: $BACKUP_DIR"
        else
            # Try with sudo if permission denied
            if sudo mkdir -p "$BACKUP_DIR" && sudo chown "$USER:$USER" "$BACKUP_DIR"; then
                chmod 700 "$BACKUP_DIR"
                log_success "Created secure backup directory with sudo: $BACKUP_DIR"
            else
                log_error "Failed to create backup directory: $BACKUP_DIR"
                exit 1
            fi
        fi
    else
        chmod 700 "$BACKUP_DIR"
        log_success "Backup directory exists and is secure: $BACKUP_DIR"
    fi
}

# Backup existing SSH keys
backup_existing_keys() {
    log_section "Backing Up Existing SSH Keys"
    
    if [[ ! -d "$SSH_DIR" ]]; then
        log_info "No existing SSH directory found"
        return 0
    fi
    
    # Check if there are any keys to backup
    local key_files=($(find "$SSH_DIR" -name "id_*" -type f 2>/dev/null || true))
    if [[ ${#key_files[@]} -eq 0 && "$FORCE_BACKUP" != "true" ]]; then
        log_info "No existing SSH keys found to backup"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would backup existing SSH keys"
        return 0
    fi
    
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/ssh-keys-backup-$backup_timestamp.tar.gz.gpg"
    
    log_info "Creating encrypted backup of SSH directory..."
    
    # Create temporary directory for backup
    local temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT
    
    # Copy SSH directory to temp location
    cp -r "$SSH_DIR" "$temp_dir/ssh-backup"
    
    # Create compressed archive
    local archive_file="$temp_dir/ssh-backup.tar.gz"
    tar -czf "$archive_file" -C "$temp_dir" ssh-backup
    
    # Encrypt the archive
    log_info "Encrypting backup (you'll need to enter a passphrase)..."
    if gpg --symmetric --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 \
           --s2k-digest-algo SHA512 --s2k-count 65536 \
           --output "$backup_file" "$archive_file"; then
        
        # Verify backup was created
        if [[ -f "$backup_file" ]]; then
            local backup_size=$(du -h "$backup_file" | cut -f1)
            log_success "Encrypted backup created: $backup_file ($backup_size)"
            
            # Create backup info file
            cat > "$BACKUP_DIR/backup-info-$backup_timestamp.txt" << EOF
SSH Keys Backup Information
===========================
Date: $(date)
Original Location: $SSH_DIR
Backup File: $backup_file
Encryption: AES256 with GPG symmetric encryption
Files Backed Up:
$(find "$SSH_DIR" -type f -exec basename {} \; 2>/dev/null | sort)

To restore:
1. Decrypt: gpg --decrypt "$backup_file" > ssh-backup.tar.gz
2. Extract: tar -xzf ssh-backup.tar.gz
3. Restore: cp -r ssh-backup/.ssh ~/
4. Fix permissions: chmod 700 ~/.ssh && chmod 600 ~/.ssh/*
EOF
            log_success "Backup info saved: $BACKUP_DIR/backup-info-$backup_timestamp.txt"
        else
            log_error "Backup file was not created successfully"
            exit 1
        fi
    else
        log_error "Failed to encrypt backup"
        exit 1
    fi
    
    # Clean up temp directory
    rm -rf "$temp_dir"
    trap - EXIT
}

# Generate SSH key
generate_ssh_key() {
    local platform="$1"
    local key_name="id_${KEY_TYPE}_${platform}"
    local key_path="$SSH_DIR/$key_name"
    
    log_info "Generating $KEY_TYPE SSH key for $platform..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would generate SSH key: $key_path"
        return 0
    fi
    
    # Create SSH directory if it doesn't exist
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    # Check if key already exists
    if [[ -f "$key_path" ]]; then
        log_warning "SSH key already exists: $key_path"
        read -p "Overwrite existing key? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping key generation for $platform"
            return 0
        fi
    fi
    
    # Generate key based on type
    local ssh_keygen_args=()
    if [[ "$KEY_TYPE" == "ed25519" ]]; then
        ssh_keygen_args=(-t ed25519 -C "$EMAIL")
    else
        ssh_keygen_args=(-t rsa -b "$KEY_SIZE" -C "$EMAIL")
    fi
    
    # Add common arguments
    ssh_keygen_args+=(-f "$key_path" -N "")
    
    if ssh-keygen "${ssh_keygen_args[@]}"; then
        chmod 600 "$key_path"
        chmod 644 "$key_path.pub"
        log_success "Generated SSH key: $key_path"
        return 0
    else
        log_error "Failed to generate SSH key for $platform"
        return 1
    fi
}

# Create SSH config
create_ssh_config() {
    log_section "Creating SSH Configuration"
    
    local config_file="$SSH_DIR/config"
    local config_backup=""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would create/update SSH config file"
        return 0
    fi
    
    # Backup existing config if it exists
    if [[ -f "$config_file" ]]; then
        config_backup="$config_file.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$config_file" "$config_backup"
        log_info "Backed up existing SSH config to: $config_backup"
    fi
    
    # Create or append to SSH config
    cat >> "$config_file" << EOF

# Generated by $SCRIPT_NAME on $(date)
# SSH keys for GitLab and GitHub

EOF
    
    # Add GitHub configuration if username provided
    if [[ -n "$GITHUB_USERNAME" ]]; then
        cat >> "$config_file" << EOF
# GitHub Configuration
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_${KEY_TYPE}_github
    IdentitiesOnly yes

EOF
        log_success "Added GitHub configuration to SSH config"
    fi
    
    # Add GitLab configuration if username provided
    if [[ -n "$GITLAB_USERNAME" ]]; then
        cat >> "$config_file" << EOF
# GitLab Configuration
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_${KEY_TYPE}_gitlab
    IdentitiesOnly yes

EOF
        log_success "Added GitLab configuration to SSH config"
    fi
    
    chmod 600 "$config_file"
    log_success "SSH config file updated: $config_file"
}

# Display setup instructions
show_setup_instructions() {
    log_section "Setup Instructions"
    
    echo -e "${CYAN}Git & SSH Setup Completed Successfully!${NC}"
    echo
    echo -e "${YELLOW}Next Steps:${NC}"
    echo
    
    if [[ -n "$GITHUB_USERNAME" ]]; then
        echo -e "${BLUE}📱 GitHub Setup:${NC}"
        echo "1. Copy your GitHub public key:"
        echo -e "   ${GREEN}cat ~/.ssh/id_${KEY_TYPE}_github.pub${NC}"
        echo
        echo "2. Add the key to GitHub:"
        echo "   • Go to: https://github.com/settings/keys"
        echo "   • Click 'New SSH key'"
        echo "   • Paste your public key"
        echo "   • Give it a descriptive title (e.g., 'My Laptop - $(date +%Y)')"
        echo
        echo "3. Test the connection:"
        echo -e "   ${GREEN}ssh -T git@github.com${NC}"
        echo "   (You should see: 'Hi $GITHUB_USERNAME! You've successfully authenticated...')"
        echo
        echo "4. Clone repositories using SSH:"
        echo -e "   ${GREEN}git clone git@github.com:$GITHUB_USERNAME/repository.git${NC}"
        echo
    fi
    
    if [[ -n "$GITLAB_USERNAME" ]]; then
        echo -e "${BLUE}🦊 GitLab Setup:${NC}"
        echo "1. Copy your GitLab public key:"
        echo -e "   ${GREEN}cat ~/.ssh/id_${KEY_TYPE}_gitlab.pub${NC}"
        echo
        echo "2. Add the key to GitLab:"
        echo "   • Go to: https://gitlab.com/-/user_settings/ssh_keys"
        echo "   • Paste your public key"
        echo "   • Give it a descriptive title (e.g., 'My Laptop - $(date +%Y)')"
        echo
        echo "3. Test the connection:"
        echo -e "   ${GREEN}ssh -T git@gitlab.com${NC}"
        echo "   (You should see: 'Welcome to GitLab, @$GITLAB_USERNAME!')"
        echo
        echo "4. Clone repositories using SSH:"
        echo -e "   ${GREEN}git clone git@gitlab.com:$GITLAB_USERNAME/repository.git${NC}"
        echo
    fi
    
    echo -e "${BLUE}🔧 General Git Configuration:${NC}"
    
    # Check if git config is already set
    local current_git_email=$(git config --global user.email 2>/dev/null || true)
    local current_git_name=$(git config --global user.name 2>/dev/null || true)
    
    if [[ -z "$current_git_email" || -z "$current_git_name" ]]; then
        echo "Setting up Git identity automatically..."
        
        # Set email if not configured
        if [[ -z "$current_git_email" && -n "$EMAIL" ]]; then
            if git config --global user.email "$EMAIL"; then
                log_success "Set git email: $EMAIL"
                echo -e "   ✅ ${GREEN}git config --global user.email \"$EMAIL\"${NC}"
            else
                log_warning "Failed to set git email automatically"
                echo -e "   ❌ Please run manually: ${GREEN}git config --global user.email \"$EMAIL\"${NC}"
            fi
        fi
        
        # Set name if not configured (try to derive from email or ask)
        if [[ -z "$current_git_name" ]]; then
            local suggested_name=""
            
            # Try to derive name from email
            if [[ "$EMAIL" =~ ^([^.]+)\.([^@]+)@ ]]; then
                # Extract first.last from email like martin.erman@gmail.com
                local first_name="${BASH_REMATCH[1]}"
                local last_name="${BASH_REMATCH[2]}"
                # Capitalize first letters
                first_name="$(tr '[:lower:]' '[:upper:]' <<< ${first_name:0:1})${first_name:1}"
                last_name="$(tr '[:lower:]' '[:upper:]' <<< ${last_name:0:1})${last_name:1}"
                suggested_name="$first_name $last_name"
            fi
            
            if [[ -n "$suggested_name" ]]; then
                if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
                    read -p "Set git name to '$suggested_name'? (Y/n): " -n 1 -r
                    echo
                    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                        if git config --global user.name "$suggested_name"; then
                            log_success "Set git name: $suggested_name"
                            echo -e "   ✅ ${GREEN}git config --global user.name \"$suggested_name\"${NC}"
                        else
                            log_warning "Failed to set git name automatically"
                        fi
                    else
                        echo -e "   ⏭️  Please set manually: ${GREEN}git config --global user.name \"Your Name\"${NC}"
                    fi
                else
                    # Auto-set in skip confirmation mode
                    if git config --global user.name "$suggested_name"; then
                        log_success "Auto-set git name: $suggested_name"
                        echo -e "   ✅ ${GREEN}git config --global user.name \"$suggested_name\"${NC}"
                    fi
                fi
            else
                echo -e "   ⏭️  Please set manually: ${GREEN}git config --global user.name \"Your Name\"${NC}"
            fi
        fi
        echo
    else
        echo "Git identity already configured:"
        echo -e "   ✅ Name: ${GREEN}$current_git_name${NC}"
        echo -e "   ✅ Email: ${GREEN}$current_git_email${NC}"
        echo
    fi
    
    echo -e "${BLUE}🔐 Security Notes:${NC}"
    echo "• Your private keys are stored in: ~/.ssh/"
    echo "• Keep your private keys secure and never share them"
    echo "• Your keys have been backed up to: $BACKUP_DIR"
    echo "• The backup is encrypted - remember your passphrase!"
    echo
    
    echo -e "${BLUE}🔄 Switching Between Accounts:${NC}"
    echo "If you need multiple accounts on the same platform, you can:"
    echo "1. Generate additional keys with different names"
    echo "2. Create Host aliases in ~/.ssh/config"
    echo "3. Use different remote URLs for different accounts"
    echo
    
    echo -e "${GREEN}✅ Git & SSH development setup completed successfully!${NC}"
    echo "Log file: $LOG_FILE"
}

# Main function
main() {
    echo -e "${CYAN}=== Git & SSH Development Setup ===${NC}"
    echo "Log file: $LOG_FILE"
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo
    
    parse_args "$@"
    check_prerequisites
    auto_detect_config
    get_user_input
    
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        echo
        echo -e "${YELLOW}Configuration Summary:${NC}"
        echo "• Email: $EMAIL"
        echo "• Key Type: $KEY_TYPE"
        [[ "$KEY_TYPE" == "rsa" ]] && echo "• Key Size: $KEY_SIZE bits"
        [[ -n "$GITHUB_USERNAME" ]] && echo "• GitHub: $GITHUB_USERNAME"
        [[ -n "$GITLAB_USERNAME" ]] && echo "• GitLab: $GITLAB_USERNAME"
        echo "• Backup Location: $BACKUP_DIR"
        echo
        
        read -p "Continue with Git & SSH setup? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Setup cancelled by user"
            exit 0
        fi
    fi
    
    # Skip generation if requested (keys already exist and user wants to use them)
    if [[ "$SKIP_GENERATION" == "true" ]]; then
        log_info "Skipping SSH key generation - using existing keys"
        # Still create/update SSH config if needed
        create_ssh_config
        show_setup_instructions
        return 0
    fi
    
    setup_backup_directory
    backup_existing_keys
    
    # Generate keys for requested platforms
    local keys_generated=false
    
    if [[ -n "$GITHUB_USERNAME" ]]; then
        if generate_ssh_key "github"; then
            keys_generated=true
        fi
    fi
    
    if [[ -n "$GITLAB_USERNAME" ]]; then
        if generate_ssh_key "gitlab"; then
            keys_generated=true
        fi
    fi
    
    # If no specific platforms were requested, generate generic keys
    if [[ -z "$GITHUB_USERNAME" && -z "$GITLAB_USERNAME" ]]; then
        log_info "No specific platforms requested, generating generic SSH key..."
        if generate_ssh_key "generic"; then
            keys_generated=true
        fi
    fi
    
    if [[ "$keys_generated" == "true" ]]; then
        create_ssh_config
        
        if [[ "$DRY_RUN" != "true" ]]; then
            show_setup_instructions
        else
            log_info "DRY RUN - Setup completed (no changes made)"
        fi
    else
        log_error "No SSH keys were generated"
        exit 1
    fi
}

# Run main function with all arguments
main "$@" 