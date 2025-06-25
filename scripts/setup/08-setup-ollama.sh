#!/bin/bash

# Ollama AI Models Setup Script
# Author: Martin's Dotfiles - Modular Version
# Description: Install and configure Ollama with AI models

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/ollama-setup_$(date +%Y%m%d_%H%M%S).log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Flags
SKIP_CONFIRMATION=false
SKIP_MODELS=false
SKIP_SERVICE=false
SKIP_SYSTEMD=false
DRY_RUN=false

# Available AI Models with descriptions
declare -A AVAILABLE_MODELS=(
    # General Purpose Models
    ["llama3.2:3b"]="Meta Llama 3.2 3B - Fast general purpose model (2GB)"
    ["llama3.2:1b"]="Meta Llama 3.2 1B - Ultra-fast lightweight model (1.3GB)"
    ["llama3.1:8b"]="Meta Llama 3.1 8B - Balanced performance model (4.7GB)"
    ["phi4:latest"]="Microsoft Phi-4 - Advanced reasoning model (7.4GB)"
    ["qwen2.5:7b"]="Alibaba Qwen2.5 7B - Multilingual model (4.4GB)"
    ["mistral:7b"]="Mistral 7B - High-quality general model (4.1GB)"
    
    # Coding Specialized Models  
    ["codegemma:7b"]="Google CodeGemma 7B - Specialized coding model (5.0GB)"
    ["codellama:7b"]="Meta Code Llama 7B - Code generation model (3.8GB)"
    ["deepseek-coder:6.7b"]="DeepSeek Coder 6.7B - Advanced coding model (3.8GB)"
    ["starcoder2:7b"]="StarCoder2 7B - Multi-language coding model (4.0GB)"
    
    # Embedding Models
    ["nomic-embed-text:latest"]="Nomic Embed Text - Text embeddings (274MB)"
    ["mxbai-embed-large:latest"]="MixedBread Embed Large - High-quality embeddings (669MB)"
    
    # Specialized Models
    ["llava:7b"]="LLaVA 7B - Vision + language model (4.7GB)"
    ["neural-chat:7b"]="Intel Neural Chat 7B - Conversational model (4.1GB)"
)

# Selected models (will be populated by user selection)
declare -a SELECTED_MODELS=()

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    echo "Starting Ollama setup - $(date)" >> "$LOG_FILE"
    echo "[LOG] Script: $SCRIPT_NAME" >> "$LOG_FILE"
}

# Logging functions
log_info() {
    local msg="[INFO] $1"
    echo -e "${BLUE}$msg${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

log_success() {
    local msg="[SUCCESS] $1"
    echo -e "${GREEN}✓ $msg${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[ERROR] $1"
    echo -e "${RED}✗ $msg${NC}" >&2
    echo "$(date +'%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

log_warning() {
    local msg="[WARNING] $1"
    echo -e "${YELLOW}⚠ $msg${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

log_section() {
    local msg="$1"
    echo -e "${CYAN}=== $msg ===${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [SECTION] $msg" >> "$LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running as regular user
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run as root"
        exit 1
    fi
    
    # Check system requirements
    local total_ram
    total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $total_ram -lt 4000 ]]; then
        log_warning "Low RAM detected (${total_ram}MB). AI models may not run well."
    else
        log_success "Sufficient RAM detected (${total_ram}MB)"
    fi
    
    # Check disk space
    local available_space
    available_space=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $available_space -lt 10 ]]; then
        log_warning "Low disk space (${available_space}GB). AI models require significant space."
    else
        log_success "Sufficient disk space (${available_space}GB)"
    fi
    
    log_success "Prerequisites check passed"
}

# Install Ollama
install_ollama() {
    log_section "Installing Ollama"
    
    if command -v ollama &>/dev/null; then
        local ollama_version
        ollama_version=$(ollama --version 2>/dev/null | head -1 || echo "unknown")
        log_success "Ollama is already installed: $ollama_version"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would install Ollama"
        return 0
    fi
    
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        read -p "Install Ollama AI platform? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipped Ollama installation"
            return 1
        fi
    fi
    
    log_info "Installing Ollama via official installer..."
    
    # Download and install Ollama
    if curl -fsSL https://ollama.com/install.sh | sh; then
        log_success "Ollama installed successfully"
        
        # Verify installation
        sleep 2
        if command -v ollama &>/dev/null; then
            local ollama_version
            ollama_version=$(ollama --version 2>/dev/null | head -1 || echo "unknown")
            log_success "Ollama version: $ollama_version"
        else
            log_error "Ollama installation verification failed"
            return 1
        fi
    else
        log_error "Failed to install Ollama"
        return 1
    fi
}

# Start Ollama service
start_ollama_service() {
    if [[ "$SKIP_SERVICE" == "true" ]]; then
        log_info "Skipping Ollama service startup"
        return 0
    fi
    
    log_section "Starting Ollama Service"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would start Ollama service"
        return 0
    fi
    
    # Check if Ollama service is already running
    if pgrep -f "ollama serve" &>/dev/null; then
        log_success "Ollama service is already running"
        return 0
    fi
    
    log_info "Starting Ollama service..."
    
    # Start Ollama in background
    nohup ollama serve > /dev/null 2>&1 &
    sleep 3
    
    # Verify service is running
    if pgrep -f "ollama serve" &>/dev/null; then
        log_success "Ollama service started successfully"
        
        # Configure systemd service for autostart
        configure_systemd_service
    else
        log_error "Failed to start Ollama service"
        return 1
    fi
}

# Configure systemd service for autostart
configure_systemd_service() {
    if [[ "$SKIP_SYSTEMD" == "true" ]]; then
        log_info "Skipping systemd service configuration"
        return 0
    fi
    
    log_section "Configuring Ollama Systemd Service"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would configure systemd service"
        return 0
    fi
    
    # Check if system service already exists
    if systemctl --user list-unit-files ollama.service &>/dev/null; then
        log_success "Ollama user service already exists"
        
        # Enable and start if not already
        if ! systemctl --user is-enabled ollama.service &>/dev/null; then
            systemctl --user enable ollama.service
            log_success "Enabled Ollama user service"
        fi
        
        if ! systemctl --user is-active ollama.service &>/dev/null; then
            systemctl --user start ollama.service
            log_success "Started Ollama user service"
        fi
        return 0
    fi
    
    log_info "Creating Ollama user systemd service..."
    
    # Create user systemd directory
    local user_systemd_dir="$HOME/.config/systemd/user"
    mkdir -p "$user_systemd_dir"
    
    # Create systemd service file
    cat > "$user_systemd_dir/ollama.service" << EOF
[Unit]
Description=Ollama AI Platform
Documentation=https://ollama.com/
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
ExecStart=$(which ollama) serve
Environment=OLLAMA_HOST=127.0.0.1:11434
Environment=HOME=%h
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ollama

[Install]
WantedBy=default.target
EOF
    
    log_success "Created Ollama systemd service file"
    
    # Reload systemd and enable service
    systemctl --user daemon-reload
    log_info "Reloaded systemd user daemon"
    
    # Stop the manual process first
    if pgrep -f "ollama serve" &>/dev/null; then
        log_info "Stopping manual Ollama process..."
        pkill -f "ollama serve" || true
        sleep 2
    fi
    
    # Enable and start the service
    if systemctl --user enable ollama.service; then
        log_success "Enabled Ollama service for autostart"
    else
        log_error "Failed to enable Ollama service"
        return 1
    fi
    
    if systemctl --user start ollama.service; then
        log_success "Started Ollama systemd service"
    else
        log_error "Failed to start Ollama service"
        return 1
    fi
    
    # Enable lingering to start service at boot even when user not logged in
    if ! loginctl show-user "$USER" --property=Linger | grep -q "yes"; then
        log_info "Enabling user lingering for boot autostart..."
        if sudo loginctl enable-linger "$USER"; then
            log_success "Enabled user lingering - Ollama will start at boot"
        else
            log_warning "Failed to enable user lingering - service may not start at boot"
        fi
    else
        log_success "User lingering already enabled"
    fi
    
    # Verify service status
    sleep 2
    if systemctl --user is-active ollama.service &>/dev/null; then
        log_success "Ollama service is running and will autostart at boot"
        
        # Show service status
        local status_output
        status_output=$(systemctl --user status ollama.service --no-pager -l | head -10)
        echo -e "${BLUE}Service Status:${NC}"
        echo "$status_output"
    else
        log_error "Ollama service failed to start properly"
        systemctl --user status ollama.service --no-pager -l || true
        return 1
    fi
}

# Display available models and get user selection
select_ai_models() {
    log_section "AI Model Selection"
    
    # Create ordered list of models for display
    local models=()
    local descriptions=()
    
    # Add models in categories
    echo -e "${CYAN}Available AI Models:${NC}\n"
    
    echo -e "${YELLOW}General Purpose Models:${NC}"
    local count=1
    for model in "llama3.2:1b" "llama3.2:3b" "llama3.1:8b" "phi4:latest" "qwen2.5:7b" "mistral:7b"; do
        models+=("$model")
        descriptions+=("${AVAILABLE_MODELS[$model]}")
        printf "%2d) %-25s - %s\n" $count "$model" "${AVAILABLE_MODELS[$model]}"
        count=$((count + 1))
    done
    
    echo -e "\n${YELLOW}Coding Specialized Models:${NC}"
    for model in "codegemma:7b" "codellama:7b" "deepseek-coder:6.7b" "starcoder2:7b"; do
        models+=("$model")
        descriptions+=("${AVAILABLE_MODELS[$model]}")
        printf "%2d) %-25s - %s\n" $count "$model" "${AVAILABLE_MODELS[$model]}"
        count=$((count + 1))
    done
    
    echo -e "\n${YELLOW}Embedding Models:${NC}"
    for model in "nomic-embed-text:latest" "mxbai-embed-large:latest"; do
        models+=("$model")
        descriptions+=("${AVAILABLE_MODELS[$model]}")
        printf "%2d) %-25s - %s\n" $count "$model" "${AVAILABLE_MODELS[$model]}"
        count=$((count + 1))
    done
    
    echo -e "\n${YELLOW}Specialized Models:${NC}"
    for model in "llava:7b" "neural-chat:7b"; do
        models+=("$model")
        descriptions+=("${AVAILABLE_MODELS[$model]}")
        printf "%2d) %-25s - %s\n" $count "$model" "${AVAILABLE_MODELS[$model]}"
        count=$((count + 1))
    done
    
    echo -e "\n${BLUE}Selection Instructions:${NC}"
    echo -e "• Select models by number (space-separated): ${GREEN}1 3 5${NC}"
    echo -e "• Select range: ${GREEN}1-4${NC} or ${GREEN}1-4 7 9${NC}"
    echo -e "• Select all: ${GREEN}all${NC}"
    echo -e "• Skip model installation: ${GREEN}none${NC} or just press Enter"
    echo -e "• Recommended for beginners: ${GREEN}1 7 11${NC} (small general + coding + embedding)"
    
    if [[ "$SKIP_CONFIRMATION" == "true" ]]; then
        # Default selection for automated runs
        SELECTED_MODELS=("llama3.2:3b" "codegemma:7b" "nomic-embed-text:latest")
        log_info "Auto-selected default models: ${SELECTED_MODELS[*]}"
        return 0
    fi
    
    echo ""
    read -p "Enter your selection: " -r selection
    
    # Handle empty selection
    if [[ -z "$selection" ]]; then
        log_info "No models selected"
        return 0
    fi
    
    # Parse selection
    case "$selection" in
        "none"|"")
            log_info "No models selected"
            return 0
            ;;
        "all")
            SELECTED_MODELS=("${models[@]}")
            ;;
        *)
            # Parse numbers and ranges
            local selected_indices=()
            for item in $selection; do
                if [[ "$item" =~ ^[0-9]+$ ]]; then
                    # Single number
                    selected_indices+=("$item")
                elif [[ "$item" =~ ^[0-9]+-[0-9]+$ ]]; then
                    # Range
                    local start="${item%-*}"
                    local end="${item#*-}"
                    for ((i=start; i<=end; i++)); do
                        selected_indices+=("$i")
                    done
                else
                    log_warning "Invalid selection format: $item"
                fi
            done
            
            # Convert indices to model names
            for index in "${selected_indices[@]}"; do
                if [[ $index -ge 1 && $index -le ${#models[@]} ]]; then
                    local model_index=$((index - 1))
                    SELECTED_MODELS+=("${models[$model_index]}")
                else
                    log_warning "Invalid model number: $index"
                fi
            done
            ;;
    esac
    
    # Remove duplicates
    if [[ ${#SELECTED_MODELS[@]} -gt 0 ]]; then
        local unique_models
        IFS=$'\n' read -d '' -r -a unique_models < <(printf '%s\n' "${SELECTED_MODELS[@]}" | sort -u) || true
        SELECTED_MODELS=("${unique_models[@]}")
        
        echo -e "\n${GREEN}Selected models:${NC}"
        local total_size=0
        for model in "${SELECTED_MODELS[@]}"; do
            echo -e "  • $model - ${AVAILABLE_MODELS[$model]}"
            # Extract size for total calculation (rough estimate)
            local size_str="${AVAILABLE_MODELS[$model]}"
            if [[ "$size_str" =~ \(([0-9.]+)(GB|MB)\) ]]; then
                local size="${BASH_REMATCH[1]}"
                local unit="${BASH_REMATCH[2]}"
                if [[ "$unit" == "GB" ]]; then
                    total_size=$(echo "$total_size + $size" | bc 2>/dev/null || echo "$total_size")
                else
                    total_size=$(echo "$total_size + $size/1000" | bc 2>/dev/null || echo "$total_size")
                fi
            fi
        done
        
        if command -v bc &>/dev/null && [[ "$total_size" != "0" ]] && [[ "$total_size" =~ ^[0-9.]+$ ]]; then
            printf "\nEstimated total download size: %.1f GB\n" "$total_size"
        fi
        
        echo ""
        read -p "Proceed with installation? (Y/n): " -r confirm
        if [[ $confirm =~ ^[Nn]$ ]]; then
            log_info "Model installation cancelled"
            SELECTED_MODELS=()
            return 0
        fi
    fi
}

# Install AI models
install_ai_models() {
    if [[ "$SKIP_MODELS" == "true" ]]; then
        log_info "Skipping AI model installation"
        return 0
    fi
    
    # Select models if not already done
    if [[ ${#SELECTED_MODELS[@]} -eq 0 ]]; then
        select_ai_models
    fi
    
    if [[ ${#SELECTED_MODELS[@]} -eq 0 ]]; then
        log_info "No AI models selected for installation"
        return 0
    fi
    
    log_section "Installing AI Models"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would install ${#SELECTED_MODELS[@]} AI models:"
        for model in "${SELECTED_MODELS[@]}"; do
            echo -e "  • $model - ${AVAILABLE_MODELS[$model]}"
        done
        return 0
    fi
    
    # Ensure Ollama service is running
    if ! pgrep -f "ollama serve" &>/dev/null; then
        log_info "Starting Ollama service for model installation..."
        start_ollama_service
        sleep 2
    fi
    
    local installed_count=0
    local failed_models=()
    
    for model in "${SELECTED_MODELS[@]}"; do
        log_info "📦 Installing model: $model"
        echo -e "    ${AVAILABLE_MODELS[$model]}"
        
        # Check if model is already installed
        if ollama list | grep -q "^${model%%:*}"; then
            log_success "Model already installed: $model"
            installed_count=$((installed_count + 1))
            continue
        fi
        
        # Install model with progress
        echo "This may take several minutes depending on model size..."
        if timeout 1800 ollama pull "$model"; then
            log_success "Model installed: $model"
            installed_count=$((installed_count + 1))
        else
            log_error "Failed to install model: $model"
            failed_models+=("$model")
        fi
        echo
    done
    
    log_success "Installed $installed_count out of ${#SELECTED_MODELS[@]} models"
    
    if [[ ${#failed_models[@]} -gt 0 ]]; then
        log_warning "Failed to install some models:"
        for model in "${failed_models[@]}"; do
            echo "  ✗ $model"
        done
    fi
}

# Test Ollama installation
test_ollama() {
    log_section "Testing Ollama Installation"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would test Ollama installation"
        return 0
    fi
    
    # Check if Ollama service is running
    if ! pgrep -f "ollama serve" &>/dev/null; then
        log_warning "Ollama service is not running"
        return 1
    fi
    
    # Test with a simple model if available
    local test_model=""
    for model in "${SELECTED_MODELS[@]}"; do
        if ollama list | grep -q "^${model%%:*}"; then
            test_model="$model"
            break
        fi
    done
    
    if [[ -z "$test_model" ]]; then
        log_warning "No models available for testing"
        return 0
    fi
    
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        read -p "Test Ollama with model $test_model? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipped Ollama testing"
            return 0
        fi
    fi
    
    log_info "Testing with model: $test_model"
    
    # Test simple generation
    local test_prompt="Hello, respond with just 'AI is working' and nothing else."
    local response
    
    if response=$(timeout 30 ollama run "$test_model" "$test_prompt" 2>/dev/null); then
        if [[ -n "$response" ]]; then
            log_success "Ollama test passed!"
            log_info "Response: $response"
        else
            log_warning "Ollama test returned empty response"
        fi
    else
        log_warning "Ollama test failed or timed out"
    fi
}

# Create Ollama utilities
create_ollama_utilities() {
    log_section "Creating Ollama Utilities"
    
    local bin_dir="$HOME/.local/bin"
    local ollama_script="$bin_dir/ollama-chat"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would create Ollama utilities"
        return 0
    fi
    
    mkdir -p "$bin_dir"
    
    # Create interactive chat script
    cat > "$ollama_script" << 'EOF'
#!/bin/bash
# Interactive Ollama Chat Script

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ [SUCCESS] $1${NC}"
}

log_error() {
    echo -e "${RED}✗ [ERROR] $1${NC}" >&2
}

show_usage() {
    cat << 'USAGE'
Usage: ollama-chat [MODEL]

Interactive chat with Ollama AI models.

OPTIONS:
    -h, --help          Show this help message
    -l, --list          List available models
    MODEL               Specific model to use (default: auto-select)

EXAMPLES:
    ollama-chat                    # Use default model
    ollama-chat phi4:latest        # Use specific model
    ollama-chat --list             # Show available models

USAGE
}

list_models() {
    echo "Available Ollama models:"
    if ollama list | tail -n +2 | grep -v "^$"; then
        true
    else
        echo "No models installed"
    fi
}

# Parse arguments
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -l|--list)
        list_models
        exit 0
        ;;
esac

# Check if Ollama is running
if ! pgrep -f "ollama serve" &>/dev/null; then
    log_error "Ollama service is not running"
    log_info "Start it with: ollama serve"
    exit 1
fi

# Select model
model="${1:-}"
if [[ -z "$model" ]]; then
    # Auto-select first available model
    model=$(ollama list | tail -n +2 | head -1 | awk '{print $1}' || echo "")
    if [[ -z "$model" ]]; then
        log_error "No models available"
        log_info "Install a model with: ollama pull phi4:latest"
        exit 1
    fi
fi

# Verify model exists
if ! ollama list | grep -q "^${model%%:*}"; then
    log_error "Model not found: $model"
    log_info "Available models:"
    list_models
    exit 1
fi

log_success "Starting chat with model: $model"
echo -e "${CYAN}Type 'quit' or 'exit' to end the conversation${NC}"
echo

# Start interactive chat
exec ollama run "$model"
EOF
    
    chmod +x "$ollama_script"
    log_success "Ollama chat utility created: $ollama_script"
    
    # Create model management script
    local model_script="$bin_dir/ollama-models"
    cat > "$model_script" << 'EOF'
#!/bin/bash
# Ollama Model Management Script

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

show_usage() {
    cat << 'USAGE'
Usage: ollama-models COMMAND

Manage Ollama AI models.

COMMANDS:
    list        List installed models
    pull MODEL  Install a model
    remove MODEL Remove a model
    update      Update all models
    info MODEL  Show model information

EXAMPLES:
    ollama-models list
    ollama-models pull llama3.2:3b
    ollama-models remove phi4:latest
    ollama-models info codegemma:7b

USAGE
}

case "${1:-}" in
    list)
        echo -e "${BLUE}Installed Ollama models:${NC}"
        ollama list
        ;;
    pull)
        if [[ -z "${2:-}" ]]; then
            echo -e "${YELLOW}Usage: ollama-models pull MODEL${NC}"
            exit 1
        fi
        echo -e "${BLUE}Installing model: $2${NC}"
        ollama pull "$2"
        ;;
    remove)
        if [[ -z "${2:-}" ]]; then
            echo -e "${YELLOW}Usage: ollama-models remove MODEL${NC}"
            exit 1
        fi
        echo -e "${BLUE}Removing model: $2${NC}"
        ollama rm "$2"
        ;;
    update)
        echo -e "${BLUE}Updating all models...${NC}"
        ollama list | tail -n +2 | awk '{print $1}' | while read -r model; do
            echo -e "${GREEN}Updating: $model${NC}"
            ollama pull "$model"
        done
        ;;
    info)
        if [[ -z "${2:-}" ]]; then
            echo -e "${YELLOW}Usage: ollama-models info MODEL${NC}"
            exit 1
        fi
        echo -e "${BLUE}Model information: $2${NC}"
        ollama show "$2"
        ;;
    -h|--help|*)
        show_usage
        ;;
esac
EOF
    
    chmod +x "$model_script"
    log_success "Ollama model management utility created: $model_script"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Install and configure Ollama with AI models.

OPTIONS:
    -h, --help              Show this help message
    -n, --dry-run           Show what would be done without making changes
    -y, --yes               Skip confirmation prompts
    --skip-models           Skip AI model installation
    --skip-service          Skip starting Ollama service
    --skip-systemd          Skip systemd service configuration
    --log-dir DIR           Custom log directory (default: ~/dotfiles/logs)
    --dotfiles-dir DIR      Custom dotfiles directory (default: auto-detect)

DESCRIPTION:
    This script installs Ollama AI platform and configures it with useful AI models
    for local development and assistance.

DEFAULT MODELS:
    • phi4:latest           - Microsoft Phi-4 (7B parameters)
    • llama3.2:3b          - Meta Llama 3.2 (3B parameters)
    • codegemma:7b         - Google CodeGemma for coding
    • nomic-embed-text     - Text embedding model

FEATURES:
    • Automatic Ollama installation
    • AI model management
    • Systemd service configuration for autostart
    • Service startup and configuration
    • Interactive chat utilities
    • Model management tools

REQUIREMENTS:
    • At least 4GB RAM recommended
    • 10GB+ free disk space for models
    • Internet connection for downloads

EXAMPLES:
    $SCRIPT_NAME                    # Full Ollama setup
    $SCRIPT_NAME --skip-models      # Install Ollama only
    $SCRIPT_NAME -n                 # Dry run to see what would be done
    $SCRIPT_NAME -y                 # Setup without confirmations

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
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
            --skip-models)
                SKIP_MODELS=true
                shift
                ;;
            --skip-service)
                SKIP_SERVICE=true
                shift
                ;;
            --skip-systemd)
                SKIP_SYSTEMD=true
                shift
                ;;
            --log-dir)
                if [[ -n "${2:-}" ]]; then
                    LOG_DIR="$2"
                    LOG_FILE="${LOG_DIR}/ollama-setup_$(date +%Y%m%d_%H%M%S).log"
                    shift 2
                else
                    log_error "--log-dir requires a directory path"
                    exit 1
                fi
                ;;
            --dotfiles-dir)
                if [[ -n "${2:-}" ]]; then
                    DOTFILES_DIR="$2"
                    shift 2
                else
                    log_error "--dotfiles-dir requires a directory path"
                    exit 1
                fi
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    parse_args "$@"
    init_logging
    
    echo "=== Ollama AI Platform Setup ==="
    echo "Log file: $LOG_FILE"
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo
    
    check_prerequisites
    install_ollama
    start_ollama_service
    install_ai_models
    create_ollama_utilities
    test_ollama
    
    echo
    if [[ "$DRY_RUN" == "true" ]]; then
        log_success "Dry run completed - no changes were made"
    else
        log_success "Ollama setup completed!"
        log_info "Use 'ollama-chat' for interactive AI conversations"
        log_info "Use 'ollama-models' to manage AI models"
        log_info "Service runs on http://localhost:11434"
    fi
    
    echo "Log file: $LOG_FILE"
}

# Run main function
main "$@" 