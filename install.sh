#!/bin/bash

# NOTE: The original version of this script is backed up as install.sh.bak

# Set up log file immediately
LOGFILE="$(pwd)/install.log"
echo "Install log started at $(date)" > "$LOGFILE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m'

# Check if we have sudo privileges and cache them
check_sudo() {
    print_step "Checking sudo privileges"
    if ! sudo -v; then
        handle_error "Failed to get sudo privileges"
    fi
    # Extend sudo timeout to 15 minutes
    sudo -v -S <<< "" 2>/dev/null
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done &
    SUDO_PID=$!
    print_success "Sudo privileges cached for 15 minutes"
}

# Function to run yay with non-interactive AUR flags (no sudo)
run_yay() {
    yay --answerclean None --answerdiff None --answeredit None --mflags --noconfirm "$@"
}

cleanup() {
    if [ -n "$SUDO_PID" ]; then
        kill $SUDO_PID 2>/dev/null
    fi
}

# Register cleanup function
trap cleanup EXIT

print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_success() {
    echo -e "${GREEN}Success:${NC} $1"
}

print_step() {
    echo -e "\n${BOLD}${MAGENTA}==>${NC} ${BOLD}$1${NC}"
}

print_substep() {
    echo -e "${CYAN}  ->${NC} $1"
}

print_progress() {
    echo -e "${BLUE}    Progress:${NC} $1"
}

handle_error() {
    print_error "$1"
    echo
    print_message "❌ An error occurred. What would you like to do?"
    echo
    local choice=$(gum_choose "What would you like to do?" \
        "Continue anyway (ignore this error)" \
        "Retry the last operation" \
        "Open debug shell (for manual fixing)" \
        "View install log" \
        "Abort installation")
    
    case "$choice" in
        "Continue anyway (ignore this error)")
            print_warning "Continuing despite error..."
            return 0
            ;;
        "Retry the last operation")
            print_message "You chose to retry. The calling function should handle this."
            return 2  # Special return code for retry
            ;;
        "Open debug shell (for manual fixing)")
            print_message "Opening debug shell. Type 'exit' when you're done fixing the issue."
            print_message "Current directory: $(pwd)"
            print_message "Error was: $1"
            bash
            print_message "Continuing after debug session..."
            return 0
            ;;
        "View install log")
            if [ -f "$LOGFILE" ]; then
                print_message "Last 50 lines of install log:"
                tail -n 50 "$LOGFILE"
            else
                print_message "No log file found at $LOGFILE"
            fi
            # Ask again after showing log
            handle_error "$1"
            ;;
        "Abort installation")
            print_error "Installation aborted by user."
            exit 1
            ;;
        *)
            print_error "Invalid choice. Aborting."
            exit 1
            ;;
    esac
}

handle_warning() {
    print_warning "$1"
    echo
    print_message "⚠️  A warning/inconsistency was detected. What would you like to do?"
    echo
    local choice=$(gum_choose "How should we proceed?" \
        "Continue (ignore warning)" \
        "Investigate (debug shell)" \
        "View details (show log)" \
        "Abort installation")
    
    case "$choice" in
        "Continue (ignore warning)")
            print_message "Continuing despite warning..."
            return 0
            ;;
        "Investigate (debug shell)")
            print_message "Opening debug shell for investigation. Type 'exit' when done."
            print_message "Warning was: $1"
            bash
            print_message "Continuing after investigation..."
            return 0
            ;;
        "View details (show log)")
            if [ -f "$LOGFILE" ]; then
                print_message "Last 30 lines of install log:"
                tail -n 30 "$LOGFILE"
            else
                print_message "No log file available"
            fi
            echo
            # Ask again after showing details
            handle_warning "$1"
            ;;
        "Abort installation")
            print_error "Installation aborted by user due to warning."
            exit 1
            ;;
        *)
            print_error "Invalid choice. Aborting."
            exit 1
            ;;
    esac
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        handle_error "Required command '$1' not found. Please install it first."
    fi
}

verify_symlink() {
    local source="$1"
    local target="$2"
    if [ ! -L "$target" ]; then
        print_error "Failed to create symlink from $source to $target"
        return 1
    fi
    if [ ! "$(readlink "$target")" = "$source" ]; then
        print_error "Symlink $target points to wrong location"
        return 1
    fi
    return 0
}

check_wayland_session() {
    if [ "$XDG_SESSION_TYPE" != "wayland" ]; then
        print_warning "Not running in a Wayland session. Some features may not work until you log into Wayland."
    fi
}

# VM detection removed - script now works for all environments

install_yay() {
    if ! command -v yay &>/dev/null; then
        print_step "Installing yay-bin (AUR helper)"
        if [ -d /tmp/yay-bin ]; then
            print_warning "/tmp/yay-bin already exists. Removing it to continue yay-bin installation."
            rm -rf /tmp/yay-bin || handle_error "Failed to remove existing /tmp/yay-bin directory"
        fi
        print_substep "Cloning yay-bin repository..."
        git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin || handle_error "Failed to clone yay-bin repository"
        print_substep "Building and installing yay-bin..."
        (cd /tmp/yay-bin && makepkg -si --noconfirm) || handle_error "Failed to install yay-bin"
        rm -rf /tmp/yay-bin
        print_success "yay-bin installed successfully"
    else
        print_message "yay-bin is already installed"
    fi
}

# Progress bar function with spinner, ETA, and current package name
spinner_chars=("|" "/" "-" "\\")
default_bar_length=30
show_progress_bar() {
    local current=$1
    local total=$2
    local elapsed=$3
    local pkg_name="$4"
    local bar_length=${5:-$default_bar_length}
    local percent=$(( 100 * current / total ))
    local filled=$(( bar_length * current / total ))
    local empty=$(( bar_length - filled ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="#"; done
    for ((i=0; i<empty; i++)); do bar+="-"; done
    local spinner_idx=$((current % 4))
    local spinner=${spinner_chars[$spinner_idx]}
    local eta="--:--"
    if [ "$current" -gt 0 ]; then
        local avg_time=$(awk "BEGIN {print $elapsed/$current}")
        local remaining=$((total - current))
        local eta_sec=$(awk "BEGIN {print int($remaining * $avg_time)}")
        local eta_min=$((eta_sec / 60))
        local eta_rem=$((eta_sec % 60))
        eta=$(printf "%02d:%02d" $eta_min $eta_rem)
    fi
    printf "\r%*s\r" 120 " "  # Clear the line (adjust 120 for terminal width)
    printf "    [%-*s] %3d%% (%d/%d) %s ETA: %s | Installing: %s\r" \
        $bar_length "$bar" $percent $current $total "$spinner" "$eta" "$pkg_name"
}

install_packages() {
    print_step "Installing required packages"
    
    # Define all packages (simplified - no environment detection)
    local CORE_PACKAGES="hyprland hyprpaper waybar kitty fish fuzzel dunst polkit-gnome xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland pipewire wireplumber pavucontrol pamixer playerctl grim slurp wl-clipboard swappy cliphist catppuccin-gtk-theme-mocha ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji papirus-icon-theme thunar thunar-volman thunar-archive-plugin xdg-utils xdg-user-dirs network-manager-applet blueman jq bc gnupg exa ripgrep fzf lm_sensors wlsunset light zoxide gum nwg-look qt5ct qt6ct kvantum waypaper matugen ollama nano firefox-developer-edition unzip zip p7zip python python-pip"
    local LF_PACKAGES="lf bat file mediainfo chafa atool ffmpegthumbnailer poppler"
    local OPTIONAL_PACKAGES="brightnessctl vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau radeontop ddcutil"
    
    # Arrays to track installed packages
    local INSTALLED_PACKAGES=()
    local FAILED_PACKAGES=()
    
    # Combine all packages
    local ALL_PACKAGES="$CORE_PACKAGES $LF_PACKAGES $OPTIONAL_PACKAGES"
    print_substep "Installing all packages (some may be skipped if not applicable to your system)"
    
    # Check for missing packages
    print_substep "Checking for missing packages..."
    gum_spin "Scanning installed packages..."
    local MISSING_PACKAGES=()
    for package in $ALL_PACKAGES; do
        if ! yay -Q "$package" &>/dev/null; then
            MISSING_PACKAGES+=("$package")
        fi
    done
    
    # Install missing packages
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        print_message "Found ${#MISSING_PACKAGES[@]} packages to install"
        
        # Update system and refresh package database
        print_substep "Updating system and refreshing package database..."
        gum_spin "Updating system packages..."
        sudo pacman -Syu --noconfirm || handle_warning "Failed to update system packages - this could cause package conflicts"
        gum_spin "Refreshing package database..."
        run_yay -Syy --noconfirm || handle_warning "Failed to refresh package database - package installation may fail"
        
        # Refresh sudo timestamp to avoid password prompt during suppressed output
        sudo -v
        
        # Install packages in groups with bash progress bar
        print_substep "Installing packages..."
        local total=${#MISSING_PACKAGES[@]}
        local count=0
        local start_time=$(date +%s)
        for pkg in "${MISSING_PACKAGES[@]}"; do
            local pkg_start_time=$(date +%s)
            if run_yay -S --needed --noconfirm "$pkg" &>>"$LOGFILE"; then
                INSTALLED_PACKAGES+=("$pkg")
            else
                run_yay -S --needed --noconfirm "$pkg"
                FAILED_PACKAGES+=("$pkg")
                echo -e "\n${RED}Last 20 lines of install.log for $pkg:${NC}"
                tail -n 20 "$LOGFILE"
            fi
            count=$((count + 1))
            local now=$(date +%s)
            local elapsed=$((now - start_time))
            show_progress_bar $count $total $elapsed "$pkg"
        done
        if [ $total -gt 0 ]; then echo; fi
        
        # Print installation summary
        echo
        print_step "Installation Summary"
        if [ ${#INSTALLED_PACKAGES[@]} -gt 0 ]; then
            print_success "Successfully installed ${#INSTALLED_PACKAGES[@]} packages:"
            printf '%s\n' "${INSTALLED_PACKAGES[@]}" | sort | sed 's/^/  - /'
            INSTALLED_PACKAGES_SUMMARY="$(printf '%s\n' "${INSTALLED_PACKAGES[@]}")"
        fi
        
        if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
            echo
            print_error "Failed to install ${#FAILED_PACKAGES[@]} packages:"
            printf '%s\n' "${FAILED_PACKAGES[@]}" | sort | sed 's/^/  - /'
            FAILED_PACKAGES_SUMMARY="$(printf '%s\n' "${FAILED_PACKAGES[@]}")"
            handle_warning "Some packages failed to install - this may cause missing functionality"
        fi
    else
        print_success "All required packages are already installed"
        INSTALLED_PACKAGES_SUMMARY=""
        FAILED_PACKAGES_SUMMARY=""
    fi
}

backup_configs() {
    print_step "Backing up existing configurations"
    config_dir="$HOME/.config"
    backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    if [ -d "$config_dir" ]; then
        mkdir -p "$backup_dir"
        print_substep "Creating backup in $backup_dir"
        local dirs=(hypr waybar kitty fish dunst fuzzel lf)
        local total=${#dirs[@]}
        local count=0
        local start_time=$(date +%s)
        for dir in "${dirs[@]}"; do
            if [ -d "$config_dir/$dir" ]; then
                print_progress "Backing up $dir..."
                cp -r "$config_dir/$dir" "$backup_dir/" || print_warning "Failed to backup $dir"
            fi
            count=$((count + 1))
            local now=$(date +%s)
            local elapsed=$((now - start_time))
            show_progress_bar $count $total $elapsed "$dir"
        done
        if [ $total -gt 0 ]; then echo; fi
        print_success "Configurations backed up to $backup_dir"
    fi
}

rotate_backups() {
    print_substep "Rotating old backups..."
    find "$HOME" -maxdepth 1 -name ".config-backup-*" -type d -printf '%T@ %p\n' | \
        sort -n | head -n -5 | cut -d' ' -f2- | xargs -r rm -rf
    print_success "Old backups cleaned up"
}

create_symlinks() {
    print_step "Creating configuration symlinks"
    dotfiles_dir="$(pwd)"
    local dirs=(config/*)
    local total=$(ls -1d config/* | wc -l)
    local count=0
    local start_time=$(date +%s)
    for dir in ${dirs[@]}; do
        if [ -d "$dir" ]; then
            base_name=$(basename "$dir")
            case "$base_name" in
                "applications")
                    print_substep "Setting up application shortcuts..."
                    mkdir -p "$HOME/.local/share/applications"
                    for file in "$dir"/*; do
                        if [ -f "$file" ]; then
                            target="$HOME/.local/share/applications/$(basename "$file")"
                            if [ -L "$target" ] && [ "$(readlink "$target")" = "$dotfiles_dir/$file" ]; then
                                print_progress "Shortcut for $(basename "$file") already exists and is correct"
                            else
                                # Remove existing file/link if it exists
                                [ -e "$target" ] && rm -f "$target"
                                print_progress "Creating shortcut for $(basename "$file")..."
                                ln -sf "$dotfiles_dir/$file" "$target"
                                verify_symlink "$dotfiles_dir/$file" "$target" || print_warning "Failed to verify symlink for $(basename "$file")"
                            fi
                        fi
                    done
                    ;;
                *)
                    print_substep "Setting up $base_name configuration..."
                    target_dir="$HOME/.config/$base_name"
                    
                    # Most configs can be fully symlinked
                    case "$base_name" in
                        *)
                    # Check if symlink already exists and points to correct location
                    if [ -L "$target_dir" ] && [ "$(readlink "$target_dir")" = "$dotfiles_dir/$dir" ]; then
                        print_progress "$base_name configuration already symlinked correctly"
                    elif [ -e "$target_dir" ]; then
                        # Check if it's a small default config that can be safely replaced
                        local dir_size=$(du -sb "$target_dir" 2>/dev/null | cut -f1)
                        if [ "$dir_size" -lt 50000 ]; then  # Less than 50KB = likely default configs
                            print_progress "Replacing default $base_name configuration with dotfiles..."
                            rm -rf "$target_dir"
                            mkdir -p "$(dirname "$target_dir")"
                            ln -sf "$dotfiles_dir/$dir" "$target_dir"
                            verify_symlink "$dotfiles_dir/$dir" "$target_dir" || handle_warning "Failed to verify symlink for $base_name - configuration may not work properly"
                        else
                            print_warning "$base_name configuration exists and seems customized. Skipping to prevent data loss."
                            print_warning "Manual intervention required: Remove $target_dir and re-run if you want to symlink it."
                        fi
                    else
                        print_progress "Creating symlink for $base_name configuration..."
                        mkdir -p "$(dirname "$target_dir")"
                        ln -sf "$dotfiles_dir/$dir" "$target_dir"
                        verify_symlink "$dotfiles_dir/$dir" "$target_dir" || handle_warning "Failed to verify symlink for $base_name - configuration may not work properly"
                    fi
                            ;;
                    esac
                    ;;
            esac
        fi
        count=$((count + 1))
        local now=$(date +%s)
        local elapsed=$((now - start_time))
        show_progress_bar $count $total $elapsed "$dir"
    done
    if [ $total -gt 0 ]; then echo; fi
    print_success "Symlink setup completed"
}

setup_ai_scripts() {
    print_step "Setting up AI scripts accessibility"
    dotfiles_dir="$(pwd)"
    
    # Create ~/.local/bin if it doesn't exist
    print_substep "Creating ~/.local/bin directory..."
    mkdir -p "$HOME/.local/bin" || print_warning "Failed to create ~/.local/bin directory"
    
    # Symlink the main AI configuration script for system-wide access
    if [ -f "$dotfiles_dir/scripts/ai/ai-config.sh" ]; then
        print_substep "Making ai-config accessible system-wide..."
        local ai_config_target="$HOME/.local/bin/ai-config"
        if [ -L "$ai_config_target" ] && [ "$(readlink "$ai_config_target")" = "$dotfiles_dir/scripts/ai/ai-config.sh" ]; then
            print_progress "ai-config already symlinked correctly"
        else
            ln -sf "$dotfiles_dir/scripts/ai/ai-config.sh" "$ai_config_target"
            verify_symlink "$dotfiles_dir/scripts/ai/ai-config.sh" "$ai_config_target" || print_warning "Failed to verify ai-config symlink"
            print_success "ai-config command available system-wide"
        fi
    else
        print_warning "AI config script not found, skipping system-wide setup"
    fi
    
    # Create a symlink for the entire AI scripts directory in ~/.config for easy access
    print_substep "Creating AI scripts directory symlink..."
    local ai_scripts_target="$HOME/.config/dynamic-theming/scripts"
    if [ -d "$dotfiles_dir/scripts/ai" ]; then
        if [ -L "$ai_scripts_target" ] && [ "$(readlink "$ai_scripts_target")" = "$dotfiles_dir/scripts/ai" ]; then
            print_progress "AI scripts directory already symlinked correctly"
        else
            mkdir -p "$(dirname "$ai_scripts_target")"
            ln -sf "$dotfiles_dir/scripts/ai" "$ai_scripts_target"
            verify_symlink "$dotfiles_dir/scripts/ai" "$ai_scripts_target" || print_warning "Failed to verify AI scripts directory symlink"
            print_success "AI scripts directory accessible at ~/.config/dynamic-theming/scripts"
        fi
    else
        print_warning "AI scripts directory not found, skipping symlink"
    fi
    
    print_success "AI scripts accessibility setup completed"
}

set_permissions() {
    print_step "Setting script permissions"
    print_substep "Setting lf script permissions..."
    chmod +x "$HOME/.config/lf/preview.sh" "$HOME/.config/lf/cleaner.sh" || print_warning "Failed to set permissions for lf scripts"
    print_substep "Setting Hyprland script permissions..."
    find "$HOME/.config/hypr/scripts/" -type f -name "*.sh" -exec chmod +x {} \; || print_warning "Failed to set permissions for Hyprland scripts"
    print_substep "Setting Waybar script permissions..."
    find "$HOME/.config/waybar/scripts/" -type f -name "*.sh" -exec chmod +x {} \; || print_warning "Failed to set permissions for Waybar scripts"
    print_substep "Setting AI script permissions..."
    find "$(pwd)/scripts/ai/" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || print_warning "Failed to set permissions for AI scripts (may not exist yet)"
    print_success "All permissions set"
}

configure_env_specific() {
    print_step "Configuring environment-specific settings"
    print_success "Environment configuration completed"
}

wait_for_ollama_service() {
    local max_attempts=30
    local attempt=1
    
    print_substep "Waiting for ollama service to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if ollama list >/dev/null 2>&1; then
            print_success "Ollama service is ready"
            return 0
        fi
        
        if [ $attempt -eq 1 ]; then
            print_progress "Starting ollama service..."
            # Try to start service if not running
            if ! pgrep -x ollama >/dev/null 2>&1; then
                systemctl --user start ollama.service 2>/dev/null || ollama serve >/dev/null 2>&1 &
            fi
        fi
        
        printf "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo
    print_error "Ollama service failed to start after ${max_attempts} attempts"
    return 1
}

download_ollama_model() {
    local model="$1"
    local display_name="$2"
    local max_retries=3
    local retry=1
    
    print_substep "Setting up $display_name model..."
    
    # Check if model already exists
    if ollama list 2>/dev/null | grep -q "^$model"; then
        print_message "$display_name model already installed"
        return 0
    fi
    
    while [ $retry -le $max_retries ]; do
        if [ $retry -gt 1 ]; then
            print_progress "Retry $retry/$max_retries: Downloading $display_name model..."
        else
            print_progress "Downloading $display_name model (this may take several minutes)..."
        fi
        
        # Create a temporary log file for ollama output
        local temp_log=$(mktemp)
        
        # Run ollama pull with progress indication and timeout (30 minutes)
        if timeout 1800 bash -c "
            ollama pull '$model' > '$temp_log' 2>&1 &
            pull_pid=\$!
            
            # Show progress while downloading
            while kill -0 \$pull_pid 2>/dev/null; do
                printf '.'
                sleep 3
            done
            
            wait \$pull_pid
        "; then
            rm -f "$temp_log"
            print_success "$display_name model installed successfully"
            return 0
        else
            local exit_code=$?
            print_warning "Attempt $retry failed (exit code: $exit_code)"
            
            # Show last few lines of error if available
            if [ -f "$temp_log" ] && [ -s "$temp_log" ]; then
                print_message "Last error output:"
                tail -n 3 "$temp_log" | sed 's/^/  /'
            fi
            rm -f "$temp_log"
            
            if [ $exit_code -eq 124 ]; then
                print_warning "Download timed out after 30 minutes"
            fi
            
            if [ $retry -lt $max_retries ]; then
                print_progress "Waiting 5 seconds before retry..."
                sleep 5
            fi
        fi
        
        retry=$((retry + 1))
    done
    
    print_error "Failed to download $display_name model after $max_retries attempts"
    print_warning "AI features requiring this model will be disabled"
    return 1
}

setup_ai_system() {
    print_step "Setting up AI-Enhanced Dynamic Theming System"
    
    # Create AI configuration directory
    print_substep "Creating AI configuration directory..."
    mkdir -p "$HOME/.config/dynamic-theming" || {
        print_error "Failed to create AI config directory"
        return 1
    }
    
    # Create matugen cache directory for AI processing
    print_substep "Creating matugen cache directory..."
    mkdir -p "$HOME/.cache/matugen" || {
        print_warning "Failed to create matugen cache directory"
    }
    
    # Initialize AI configuration if it doesn't exist
    print_substep "Initializing AI configuration..."
    if [ ! -f "$HOME/.config/dynamic-theming/ai-config.conf" ]; then
        # Try to use the symlinked version first, then fall back to local
        local ai_config_script=""
        if [ -x "$HOME/.local/bin/ai-config" ]; then
            ai_config_script="$HOME/.local/bin/ai-config"
        elif [ -x "$(pwd)/scripts/ai/ai-config.sh" ]; then
            ai_config_script="$(pwd)/scripts/ai/ai-config.sh"
        fi
        
        if [ -n "$ai_config_script" ]; then
            if bash "$ai_config_script" init; then
                print_success "AI configuration initialized with default settings"
            else
                print_warning "Failed to initialize AI config - continuing with defaults"
            fi
        else
            print_warning "AI config script not found, skipping initialization"
        fi
    else
        print_message "AI configuration already exists"
    fi
    
    # Set up ollama models if ollama is available
    if command -v ollama &> /dev/null; then
        # Wait for ollama service to be ready
        if wait_for_ollama_service; then
            # Download vision model (llava)
            download_ollama_model "llava" "LLAVA vision"
            
            # Download text model (phi4) 
            download_ollama_model "phi4" "Phi4 text"
            
            print_success "Ollama model setup completed"
        else
            print_warning "Ollama service not available - AI features will be limited"
        fi
    else
        print_warning "Ollama not found. AI vision and text features will be unavailable"
        print_message "You can install ollama later and run this setup again"
    fi
    
    print_success "AI system setup completed"
}

configure_defaults() {
    print_step "Configuring default applications"
    print_substep "Setting default terminal..."
    xdg-mime default kitty.desktop x-scheme-handler/terminal
    xdg-mime default kitty.desktop application/x-terminal-emulator
    print_substep "Updating XDG user directories..."
    xdg-user-dirs-update || print_warning "Failed to update XDG user directories"
    print_substep "Creating Screenshots directory..."
    mkdir -p "$HOME/Pictures/Screenshots" || handle_error "Failed to create Screenshots directory"
    print_success "Default applications configured"
}

configure_user_permissions() {
    print_step "Configuring user permissions and services"
    
    # Add user to required groups for hardware access
    print_substep "Adding user to hardware access groups..."
    local groups_to_add=""
    if ! groups | grep -q "video"; then
        groups_to_add="$groups_to_add video"
    fi
    if ! groups | grep -q "i2c"; then
        groups_to_add="$groups_to_add i2c"
    fi
    
    if [ -n "$groups_to_add" ]; then
        print_progress "Adding user to groups:$groups_to_add"
        sudo usermod -a -G "${groups_to_add# }" "$USER" || print_warning "Failed to add user to some groups"
        print_success "User added to hardware access groups"
        print_warning "You'll need to log out and back in for group changes to take effect"
    else
        print_message "User already in required groups"
    fi
    
    # Refresh font cache
    print_substep "Refreshing font cache..."
    fc-cache -fv > /dev/null 2>&1 || print_warning "Failed to refresh font cache"
    
    print_success "User permissions and services configured"
}

set_fish_shell() {
    print_step "Setting up fish shell"
    local fish_path
    fish_path="$(command -v fish)"
    if [ "$SHELL" != "$fish_path" ]; then
        print_substep "Changing default shell to fish..."
        if chsh -s "$fish_path"; then
            print_success "Default shell changed to fish"
        else
            print_warning "Could not change default shell. You may need to do it manually"
        fi
    else
        print_message "Fish is already the default shell"
    fi
    
    # Ensure ~/.local/bin is in PATH for fish
    print_substep "Ensuring ~/.local/bin is in fish PATH..."
    local fish_config="$HOME/.config/fish/config.fish"
    if [ -f "$fish_config" ]; then
        if ! /bin/grep -q "set -gx PATH.*\.local/bin" "$fish_config"; then
            echo 'set -gx PATH $HOME/.local/bin $PATH' >> "$fish_config"
            print_success "Added ~/.local/bin to fish PATH"
        else
            print_message "~/.local/bin already in fish PATH"
        fi
    fi
}

install_win11_vm_entry() {
    print_step "Setting up Windows 11 VM entry"
    dotfiles_dir="$(pwd)"
    print_substep "Setting up VM launcher script..."
    chmod +x "$dotfiles_dir/scripts/launch-win11-vm.sh"
    mkdir -p "$HOME/.local/share/applications"
    print_progress "Creating desktop entry..."
    cp "$dotfiles_dir/desktop/win11-vm.desktop" "$HOME/.local/share/applications/win11-vm.desktop"
    print_success "Windows 11 VM entry created"
}

restore_vm() {
    print_step "Restoring Windows 11 VM"
    dotfiles_dir="$(pwd)"
    VM_XML="$dotfiles_dir/vm/win11.xml"
    VM_DISK="/mnt/Stuff/VM_Backup/win11.qcow2"
    if [ -f "$VM_XML" ] && [ -f "$VM_DISK" ]; then
        if ! virsh --connect qemu:///system list --all | grep -q win11; then
            print_substep "Defining VM from XML..."
            sudo virsh --connect qemu:///system define "$VM_XML"
            print_success "Windows 11 VM restored from repo XML"
        else
            print_message "Windows 11 VM already defined, skipping restore"
        fi
    else
        print_warning "VM XML or disk not found, skipping VM restore"
    fi
}

final_verification() {
    print_step "Performing final verification"
    missing_deps=0
    print_substep "Checking core dependencies..."
    local core_commands="hyprland waybar kitty fish fuzzel dunst jq bc ollama wl-copy wl-paste lf"
    
    for cmd in $core_commands; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "Required command '$cmd' not found after installation!"
            missing_deps=1
        fi
    done
    
    # Check optional tools without failing
    print_substep "Checking optional tools..."
    local optional_commands="sensors radeontop ddcutil brightnessctl"
    for cmd in $optional_commands; do
        if command -v "$cmd" &> /dev/null; then
            print_message "Optional tool '$cmd' is available"
        else
            print_message "Optional tool '$cmd' not found (this is normal for VMs or non-AMD systems)"
        fi
    done
    
    if [ $missing_deps -eq 1 ]; then
        print_warning "Some core dependencies are missing. Please check the error messages above"
    else
        print_success "All core dependencies are installed correctly"
    fi
}

verify_gpu_monitoring() {
    print_step "Verifying GPU monitoring setup"
    print_substep "Checking GPU sensors..."
    if sensors amdgpu-* > /dev/null 2>&1; then
        print_success "AMD GPU sensors detected"
    else
        print_message "AMD GPU sensors not detected (normal for VMs or non-AMD systems)"
    fi
    
    print_substep "Checking GPU usage monitoring..."
    if command -v radeontop &> /dev/null && radeontop -d- -l1 > /dev/null 2>&1; then
        print_success "GPU usage monitoring available"
    else
        print_message "GPU usage monitoring not available (normal for VMs or non-AMD systems)"
    fi
    
    print_success "GPU monitoring verification completed"
}

prompt_reboot() {
    gum_style --bold "Installation completed!"
    print_message "Some changes might require a system restart to take effect."
    if gum_confirm "Would you like to reboot now?"; then
        print_message "Rebooting system..."
        systemctl reboot
    fi
}

set_hyprpaper_conf() {
    print_step "Setting up wallpaper configuration"
    local config_path="$HOME/.config/hypr/hyprpaper.conf"
    local wallpaper="$(pwd)/assets/wallpapers/evilpuccin.png"

    print_substep "Generating hyprpaper.conf for physical monitors..."
    cat > "$config_path" <<EOF
preload = $wallpaper
wallpaper = DP-3,$wallpaper
wallpaper = DP-1,$wallpaper
wallpaper = HDMI-A-1,$wallpaper
splash = false
EOF
    print_success "hyprpaper.conf generated"
}

automount_external_drives() {
    print_step "Setting up external drive automounting"
    print_substep "Scanning for external drives with labels..."
    # Create a temporary file for fstab modifications
    local temp_fstab=$(mktemp)
    sudo cp /etc/fstab "$temp_fstab"
    
    lsblk -o NAME,LABEL,TYPE,MOUNTPOINT | grep part | grep -v '/$' | grep -v '/boot' | while read -r line; do
        dev_name=$(echo $line | awk '{print $1}')
        label=$(echo $line | awk '{print $2}')
        if [ -n "$label" ]; then
            mountpoint="/mnt/$label"
            device="/dev/$dev_name"
            print_progress "Found drive: $label ($device)"
            # Check if already in fstab
            if ! /bin/grep -q "LABEL=$label" "$temp_fstab"; then
                print_substep "Adding $label to /etc/fstab..."
                sudo mkdir -p "$mountpoint"
                echo "LABEL=$label $mountpoint auto nosuid,nodev,nofail,x-gvfs-show 0 0" >> "$temp_fstab"
            else
                print_message "$label already in /etc/fstab"
            fi
        fi
    done
    
    # Apply all fstab changes at once
    if ! cmp -s /etc/fstab "$temp_fstab"; then
        print_substep "Applying fstab changes..."
        sudo cp "$temp_fstab" /etc/fstab
        print_success "fstab updated successfully"
    else
        print_message "No changes needed in fstab"
    fi
    rm -f "$temp_fstab"
    print_success "Automount configuration complete! You can now run: sudo mount -a"
}

print_final_summary() {
    echo
    print_step "FINAL INSTALLATION SUMMARY"
    if [ -f "$LOGFILE" ]; then
        print_message "Log file: $LOGFILE"
    fi
    if [ -n "$INSTALLED_PACKAGES_SUMMARY" ]; then
        print_success "Packages installed: $(echo "$INSTALLED_PACKAGES_SUMMARY" | wc -l)"
    fi
    if [ -n "$FAILED_PACKAGES_SUMMARY" ]; then
        print_warning "Packages failed: $(echo "$FAILED_PACKAGES_SUMMARY" | wc -l)"
        print_message "Check the log file for details."
    else
        print_success "No package installation failures detected."
    fi
    echo
}

print_theming_instructions() {
    echo
    print_step "GTK and Qt Theming Recommendations"
    print_message "For GTK theming, use the GUI tool nwg-look (Wayland-native, works with Hyprland)."
    print_message "  Install: sudo pacman -S nwg-look"
    print_message "  Run: nwg-look (from your launcher or terminal)"
    print_message "  Do NOT set GTK_THEME in env.conf or hardcode gsettings in scripts if you want GUI control."
    print_message "For Qt theming, use qt5ct, qt6ct, and Kvantum."
    print_message "  Install: sudo pacman -S qt5ct qt6ct kvantum"
    print_message "  Set style to Kvantum in qt5ct/qt6ct, and use a matching Kvantum theme."
    print_message "See the README for more details."
    echo
    
    print_step "AI-Enhanced Dynamic Theming System + Firefox Web Theming"
    print_message "🧠 Your system now includes the world's first AI-enhanced desktop + web theming!"
    print_message "  Press Super+B to select wallpapers → Desktop + Firefox themes update together"
    print_message "  AI analyzes content and optimizes colors for perfect harmony and accessibility"
    print_message "  🌐 Firefox Extension: Real-time website theming based on wallpaper colors"
    print_message "  Configure AI settings: ai-config config (available system-wide)"
    print_message "  Check AI status: ai-config status"
    print_message "  Firefox setup: ./scripts/install-firefox-extension-permanent.sh"
    print_message "  All AI scripts accessible at: ~/.config/dynamic-theming/scripts/"
    print_message "See AI_COMPLETE_ECOSYSTEM_GUIDE.md for complete documentation."
    echo
}

# Gum-based UI functions
gum_style() {
    gum style \
        --border normal \
        --border-foreground 212 \
        --foreground 212 \
        --align center \
        --width 50 \
        --margin "1 2" \
        --padding "1 2" \
        "$@"
}

gum_spin() {
    gum spin --spinner dot --title "$1" -- sleep 0.1
}

gum_confirm() {
    gum confirm --affirmative "Yes" --negative "No" "$1"
}

gum_input() {
    gum input --placeholder "$1"
}

gum_choose() {
    gum choose --header "$1" "${@:2}"
}

# Ensure gum is installed before any gum-based UI is used
ensure_gum() {
    if ! command -v gum &>/dev/null; then
        echo "==> Installing gum from the official Arch repository..."
        if command -v yay &>/dev/null; then
            yay -S --noconfirm gum
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy --noconfirm gum
        else
            echo "Error: Neither yay nor pacman found. Please install gum manually."
            exit 1
        fi
    fi
}

preflight_check() {
    print_step "Analyzing current system state"
    
    local needs_packages=false
    local needs_configs=false
    local needs_ai_scripts=false
    local needs_ai_system=false
    local needs_fish=false
    local needs_vm=false
    local needs_wallpaper=false
    local needs_fstab=false
    local missing_count=0
    local ai_missing_count=0
    
    # Check packages
    print_substep "Checking installed packages..."
    local ALL_PACKAGES="hyprland hyprpaper waybar kitty fish fuzzel dunst polkit-gnome xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland pipewire wireplumber pavucontrol pamixer playerctl grim slurp wl-clipboard swappy cliphist catppuccin-gtk-theme-mocha ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji papirus-icon-theme thunar thunar-volman thunar-archive-plugin xdg-utils xdg-user-dirs network-manager-applet blueman jq bc gnupg exa ripgrep fzf lm_sensors wlsunset light zoxide gum nwg-look qt5ct qt6ct kvantum waypaper matugen ollama nano firefox-developer-edition unzip zip p7zip python python-pip lf bat file mediainfo chafa atool ffmpegthumbnailer poppler brightnessctl vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau radeontop ddcutil"
    
    for package in $ALL_PACKAGES; do
        if ! yay -Q "$package" &>/dev/null; then
            missing_count=$((missing_count + 1))
        fi
    done
    
    if [ $missing_count -gt 0 ]; then
        needs_packages=true
    fi
    
    # Check configurations
    print_substep "Checking configuration symlinks..."
    local dotfiles_dir="$(pwd)"
    local config_missing=false
    for dir in config/*; do
        if [ -d "$dir" ]; then
            base_name=$(basename "$dir")
            case "$base_name" in
                "applications")
                    # Check if any application shortcuts are missing
                    for file in "$dir"/*; do
                        if [ -f "$file" ]; then
                            target="$HOME/.local/share/applications/$(basename "$file")"
                            if [ ! -L "$target" ] || [ "$(readlink "$target")" != "$dotfiles_dir/$file" ]; then
                                config_missing=true
                                break
                            fi
                        fi
                    done
                    ;;
                *)
                    target_dir="$HOME/.config/$base_name"
                    if [ ! -L "$target_dir" ] || [ "$(readlink "$target_dir")" != "$dotfiles_dir/$dir" ]; then
                        config_missing=true
                    fi
                    ;;
            esac
        fi
    done
    
    if [ "$config_missing" = true ]; then
        needs_configs=true
    fi
    
    # Check AI scripts symlinks
    print_substep "Checking AI script accessibility..."
    if [ ! -L "$HOME/.local/bin/ai-config" ] || [ "$(readlink "$HOME/.local/bin/ai-config")" != "$dotfiles_dir/scripts/ai/ai-config.sh" ]; then
        needs_ai_scripts=true
    fi
    if [ ! -L "$HOME/.config/dynamic-theming/scripts" ] || [ "$(readlink "$HOME/.config/dynamic-theming/scripts")" != "$dotfiles_dir/scripts/ai" ]; then
        needs_ai_scripts=true
    fi
    
    # Check AI system
    print_substep "Checking AI system setup..."
    if [ ! -f "$HOME/.config/dynamic-theming/ai-config.conf" ]; then
        ai_missing_count=$((ai_missing_count + 1))
    fi
    if [ ! -d "$HOME/.cache/matugen" ]; then
        ai_missing_count=$((ai_missing_count + 1))
    fi
    if command -v ollama &> /dev/null; then
        # Check if ollama service can respond (more robust than just pgrep)
        if ! ollama list >/dev/null 2>&1; then
            ai_missing_count=$((ai_missing_count + 1))
        else
            # Check for required models
            if ! ollama list 2>/dev/null | grep -q "^llava"; then
                ai_missing_count=$((ai_missing_count + 1))
            fi
            if ! ollama list 2>/dev/null | grep -q "^phi4"; then
                ai_missing_count=$((ai_missing_count + 1))
            fi
        fi
    else
        ai_missing_count=$((ai_missing_count + 1))
    fi
    
    if [ $ai_missing_count -gt 0 ]; then
        needs_ai_system=true
    fi
    
    # Check fish shell
    print_substep "Checking shell configuration..."
    local fish_path="$(command -v fish 2>/dev/null || echo "")"
    if [ "$SHELL" != "$fish_path" ] || [ ! -f "$HOME/.config/fish/config.fish" ]; then
        needs_fish=true
    fi
    
    # Check wallpaper configuration
    print_substep "Checking wallpaper configuration..."
    if [ ! -f "$HOME/.config/hypr/hyprpaper.conf" ]; then
        needs_wallpaper=true
    else
        # Check if the wallpaper file points to our dotfiles wallpapers (handle both absolute and $HOME paths)
        local dotfiles_dir="$(pwd)"
        local wallpaper_file="$HOME/.config/hypr/hyprpaper.conf"
        # Use /bin/grep to avoid ripgrep alias issues and check for dotfiles wallpaper references
        if /bin/grep -q "dotfiles/assets/wallpapers" "$wallpaper_file"; then
            needs_wallpaper=false
        else
            needs_wallpaper=true
        fi
    fi
    
    # Check fstab automount setup
    print_substep "Checking external drive automounting..."
    # Get list of external drives with labels and check if they're in fstab
    # Use more robust parsing - only get lines where LABEL column has actual labels
    # Filter out installation media and temporary drives
    local external_drives=$(lsblk -o NAME,LABEL,TYPE,MOUNTPOINT | awk '$3 == "part" && $2 != "" && $2 != "-" && $2 !~ /ARCH/ && $2 !~ /ARCHISO/ && $2 !~ /EFI/ && ($4 == "" || $4 == "-") {print $2}')
    
    if [ -n "$external_drives" ]; then
        local missing_drives=""
        for label in $external_drives; do
            if ! /bin/grep -q "LABEL=$label" /etc/fstab 2>/dev/null; then
                missing_drives="$missing_drives $label"
            fi
        done
        
        if [ -n "$missing_drives" ]; then
            needs_fstab=true
        fi
    fi
    
    # Check VM setup
    if [ ! -f "$HOME/.local/share/applications/win11-vm.desktop" ]; then
        needs_vm=true
    fi
    
    # Display results
    echo
    print_step "System Analysis Results"
    
    if [ "$needs_packages" = false ] && [ "$needs_configs" = false ] && [ "$needs_ai_scripts" = false ] && [ "$needs_ai_system" = false ] && [ "$needs_fish" = false ] && [ "$needs_vm" = false ] && [ "$needs_wallpaper" = false ] && [ "$needs_fstab" = false ]; then
        print_success "✅ System appears to be fully configured!"
        print_message "All packages installed, configurations symlinked, AI system ready."
        print_message "You can still run the installer to verify or update components."
        echo
        if gum_confirm "Everything looks good. Run full verification anyway?"; then
            return 0  # Continue with installation
        else
            print_message "Installation skipped. Use './install.sh --force' to run anyway."
            exit 0
        fi
    fi
    
    print_message "📋 Steps needed on this system:"
    
    if [ "$needs_packages" = true ]; then
        print_substep "📦 Package Installation: $missing_count packages need to be installed"
    else
        print_substep "✅ Packages: All required packages already installed"
    fi
    
    if [ "$needs_configs" = true ]; then
        print_substep "🔗 Configuration Symlinks: Some config symlinks need to be created/updated"
    else
        print_substep "✅ Configurations: All symlinks properly configured"
    fi
    
    if [ "$needs_ai_scripts" = true ]; then
        print_substep "🧠 AI Script Access: ai-config command needs to be set up system-wide"
    else
        print_substep "✅ AI Scripts: System-wide access already configured"
    fi
    
    if [ "$needs_ai_system" = true ]; then
        print_substep "🤖 AI System Setup: $ai_missing_count AI components need configuration"
    else
        print_substep "✅ AI System: All AI components properly configured"
    fi
    
    if [ "$needs_fish" = true ]; then
        print_substep "🐚 Fish Shell: Shell configuration needs setup"
    else
        print_substep "✅ Fish Shell: Already configured as default shell"
    fi
    
    if [ "$needs_vm" = true ]; then
        print_substep "💻 VM Setup: Windows 11 VM entry needs configuration"
    else
        print_substep "✅ VM Setup: Already configured"
    fi
    
    if [ "$needs_wallpaper" = true ]; then
        print_substep "🖼️ Wallpaper Setup: hyprpaper.conf needs to be generated"
    else
        print_substep "✅ Wallpaper Setup: hyprpaper.conf already configured"
    fi
    
    if [ "$needs_fstab" = true ]; then
        print_substep "💾 External Drives: fstab automounting needs setup"
    else
        print_substep "✅ External Drives: All drives already in fstab"
    fi
    
    echo
    
    # Set global flags for selective installation
    SKIP_PACKAGES=$( [ "$needs_packages" = false ] && echo "true" || echo "false" )
    SKIP_CONFIGS=$( [ "$needs_configs" = false ] && echo "true" || echo "false" )
    SKIP_AI_SCRIPTS=$( [ "$needs_ai_scripts" = false ] && echo "true" || echo "false" )
    SKIP_AI_SYSTEM=$( [ "$needs_ai_system" = false ] && echo "true" || echo "false" )
    SKIP_FISH=$( [ "$needs_fish" = false ] && echo "true" || echo "false" )
    SKIP_VM=$( [ "$needs_vm" = false ] && echo "true" || echo "false" )
    SKIP_WALLPAPER=$( [ "$needs_wallpaper" = false ] && echo "true" || echo "false" )
    SKIP_FSTAB=$( [ "$needs_fstab" = false ] && echo "true" || echo "false" )
}

main() {
    ensure_gum
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run as root"
        exit 1
    fi
    
    gum_style --bold "Arch Linux Dotfiles Installer"
    print_message "This script will set up your system with the provided dotfiles."
    print_message "Safe to re-run: Only missing components will be installed/configured."
    
    # Check and cache sudo privileges at the start
    check_sudo
    
    check_command "git"
    check_command "make"
    check_command "gcc"
    check_wayland_session

    # Run preflight check to determine what needs to be done
    preflight_check

    if [ "$SKIP_PACKAGES" = "false" ]; then
        if gum_confirm "Do you want to install missing packages?"; then
        install_yay
        install_packages
    fi
    else
        print_message "📦 Skipping package installation - all packages already installed"
    fi

    if [ "$SKIP_CONFIGS" = "false" ] || [ "$SKIP_AI_SCRIPTS" = "false" ]; then
        if gum_confirm "Do you want to backup existing configs and create symlinks?"; then
            if [ "$SKIP_CONFIGS" = "false" ]; then
        backup_configs
        rotate_backups
        create_symlinks
    fi
            if [ "$SKIP_AI_SCRIPTS" = "false" ]; then
                setup_ai_scripts
            fi
        fi
    else
        print_message "🔗 Skipping configuration setup - all symlinks already correct"
    fi

    if [ "$SKIP_WALLPAPER" = "false" ]; then
        if gum_confirm "Do you want to set up wallpaper configuration?"; then
        set_hyprpaper_conf
        fi
    else
        print_message "🖼️ Skipping wallpaper setup - hyprpaper.conf already configured"
    fi

    set_permissions
    configure_env_specific
    
    if [ "$SKIP_AI_SYSTEM" = "false" ]; then
        if gum_confirm "Do you want to set up missing AI system components?"; then
            setup_ai_system
        fi
    else
        print_message "🧠 Skipping AI system setup - all components already configured"
    fi
    
    # Firefox AI Extension setup
    if [ -f "firefox-ai-extension.xpi" ] && [ -x "scripts/install-firefox-extension-permanent.sh" ]; then
        if gum_confirm "Do you want to set up the Firefox AI Extension for real-time web theming?"; then
            print_step "Setting up Firefox AI Extension"
            print_message "🌐 This enables real-time website theming based on your wallpaper colors"
            print_message "✅ Firefox Developer Edition already installed for optimal compatibility"
            ./scripts/install-firefox-extension-permanent.sh
            print_success "Firefox AI Extension setup complete"
            print_message "🚀 Complete desktop + web theming ecosystem ready!"
        fi
    else
        print_message "🌐 Firefox AI Extension files not found - skipping"
    fi
    
    configure_defaults
    configure_user_permissions

    if [ "$SKIP_FISH" = "false" ]; then
    if gum_confirm "Do you want to set fish as your default shell?"; then
        set_fish_shell
        fi
    else
        print_message "🐚 Skipping fish shell setup - already configured"
    fi

    # Optional VM and drive setup
    if [ "$SKIP_VM" = "false" ]; then
        if gum_confirm "Do you want to set up the Windows 11 VM entry?"; then
            install_win11_vm_entry
            restore_vm
        fi
    else
        print_message "💻 Skipping VM setup - already configured"
    fi
    
    if [ "$SKIP_FSTAB" = "false" ]; then
        if gum_confirm "Would you like to automatically add external drives to /etc/fstab for automounting?"; then
            automount_external_drives
        fi
    else
        print_message "💾 Skipping external drive setup - all drives already in fstab"
    fi

    final_verification
    verify_gpu_monitoring
    print_final_summary
    print_theming_instructions
    prompt_reboot
}

main 