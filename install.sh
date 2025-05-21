#!/bin/bash

# NOTE: The original version of this script is backed up as install.sh.bak

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m'

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
    exit 1
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

detect_environment() {
    if systemd-detect-virt --vm > /dev/null 2>&1; then
        echo "vm"
    elif systemd-detect-virt --container > /dev/null 2>&1; then
        echo "container"
    else
        echo "physical"
    fi
}

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

install_packages() {
    print_step "Installing required packages"
    COMMON_PACKAGES="hyprland hyprpaper waybar kitty fish fuzzel dunst polkit-gnome xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland pipewire wireplumber pavucontrol pamixer playerctl grim slurp wl-clipboard swappy cliphist catppuccin-gtk-theme-mocha ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji papirus-icon-theme thunar thunar-volman thunar-archive-plugin xdg-utils xdg-user-dirs network-manager-applet blueman jq swaylock-effects vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau gnupg exa ripgrep fzf lm_sensors radeontop wlsunset light ddcutil zoxide"
    MISSING_PACKAGES=()
    print_substep "Checking for missing packages..."
    for package in $COMMON_PACKAGES; do
        if ! yay -Q "$package" &>/dev/null; then
            MISSING_PACKAGES+=("$package")
        fi
    done
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        print_message "Found ${#MISSING_PACKAGES[@]} packages to install"
        for pkg in "${MISSING_PACKAGES[@]}"; do
            print_progress "Installing $pkg..."
            if yay -S --needed --noconfirm "$pkg"; then
                print_success "Installed $pkg"
            else
                print_warning "Failed to install $pkg. Please check if this package exists or if there are network/repo issues."
            fi
        done
    else
        print_success "All required packages are already installed"
    fi
}

install_physical_packages() {
    ENV_TYPE=$(detect_environment)
    if [ "$ENV_TYPE" = "physical" ]; then
        print_step "Installing physical machine specific packages"
        print_substep "Installing brightnessctl..."
        yay -S --needed --noconfirm brightnessctl || handle_error "Failed to install brightnessctl"
        print_success "Physical machine packages installed"
    fi
}

install_lf_and_deps() {
    print_step "Setting up lf file manager"
    if ! command -v lf &>/dev/null; then
        print_substep "Installing lf..."
        yay -S --needed --noconfirm lf || handle_error "Failed to install lf file manager"
    fi
    LF_DEPENDENCIES="bat file mediainfo chafa atool ffmpegthumbnailer poppler"
    print_substep "Installing lf dependencies for preview capabilities..."
    for package in $LF_DEPENDENCIES; do
        if ! yay -Q "$package" &>/dev/null; then
            print_progress "Installing $package..."
            yay -S --needed --noconfirm "$package" || print_warning "Failed to install $package (non-critical)"
        fi
    done
    print_success "lf and its dependencies installed"
}

backup_configs() {
    print_step "Backing up existing configurations"
    config_dir="$HOME/.config"
    backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    if [ -d "$config_dir" ]; then
        mkdir -p "$backup_dir"
        print_substep "Creating backup in $backup_dir"
        for dir in hypr waybar kitty fish dunst fuzzel lf; do
            if [ -d "$config_dir/$dir" ]; then
                print_progress "Backing up $dir..."
                cp -r "$config_dir/$dir" "$backup_dir/" || print_warning "Failed to backup $dir"
            fi
        done
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
    for dir in config/*; do
        if [ -d "$dir" ]; then
            base_name=$(basename "$dir")
            case "$base_name" in
                "applications")
                    print_substep "Setting up application shortcuts..."
                    mkdir -p "$HOME/.local/share/applications"
                    for file in "$dir"/*; do
                        if [ -f "$file" ]; then
                            target="$HOME/.local/share/applications/$(basename "$file")"
                            print_progress "Creating shortcut for $(basename "$file")..."
                            ln -sf "$dotfiles_dir/$file" "$target"
                            verify_symlink "$dotfiles_dir/$file" "$target" || print_warning "Failed to verify symlink for $(basename "$file")"
                        fi
                    done
                    ;;
                *)
                    print_substep "Setting up $base_name configuration..."
                    target_dir="$HOME/.config/$base_name"
                    mkdir -p "$(dirname "$target_dir")"
                    ln -sf "$dotfiles_dir/$dir" "$target_dir"
                    verify_symlink "$dotfiles_dir/$dir" "$target_dir" || print_warning "Failed to verify symlink for $base_name"
                    ;;
            esac
        fi
    done
    print_success "All symlinks created"
}

set_permissions() {
    print_step "Setting script permissions"
    print_substep "Setting lf script permissions..."
    chmod +x "$HOME/.config/lf/preview.sh" "$HOME/.config/lf/cleaner.sh" || print_warning "Failed to set permissions for lf scripts"
    print_substep "Setting Hyprland script permissions..."
    find "$HOME/.config/hypr/scripts/" -type f -name "*.sh" -exec chmod +x {} \; || print_warning "Failed to set permissions for Hyprland scripts"
    print_substep "Setting Waybar script permissions..."
    find "$HOME/.config/waybar/scripts/" -type f -name "*.sh" -exec chmod +x {} \; || print_warning "Failed to set permissions for Waybar scripts"
    print_success "All permissions set"
}

configure_env_specific() {
    print_step "Configuring environment-specific settings"
    dotfiles_dir="$(pwd)"
    ENV_TYPE=$(detect_environment)
    print_substep "Detected environment: $ENV_TYPE"
    if [ "$ENV_TYPE" = "vm" ]; then
        print_progress "Setting up VM monitor configuration..."
        ln -sf "$dotfiles_dir/config/hypr/monitors-vm.conf" "$HOME/.config/hypr/monitors.conf"
        verify_symlink "$dotfiles_dir/config/hypr/monitors-vm.conf" "$HOME/.config/hypr/monitors.conf" || \
            handle_error "Failed to configure VM monitor settings"
    else
        print_progress "Setting up physical monitor configuration..."
        ln -sf "$dotfiles_dir/config/hypr/monitors-physical.conf" "$HOME/.config/hypr/monitors.conf"
        verify_symlink "$dotfiles_dir/config/hypr/monitors-physical.conf" "$HOME/.config/hypr/monitors.conf" || \
            handle_error "Failed to configure physical monitor settings"
    fi
    print_success "Environment configuration completed"
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
    for cmd in hyprland waybar kitty fish fuzzel dunst jq wl-copy wl-paste swaylock sensors radeontop ddcutil lf; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "Required command '$cmd' not found after installation!"
            missing_deps=1
        fi
    done
    if [ $missing_deps -eq 1 ]; then
        print_warning "Some dependencies are missing. Please check the error messages above"
    else
        print_success "All core dependencies are installed correctly"
    fi
}

verify_gpu_monitoring() {
    ENV_TYPE=$(detect_environment)
    if [ "$ENV_TYPE" = "physical" ]; then
        print_step "Verifying GPU monitoring setup"
        print_substep "Checking AMD GPU sensors..."
        if ! sensors amdgpu-* > /dev/null 2>&1; then
            print_warning "AMD GPU sensors not detected. GPU monitoring may not work correctly"
        fi
        print_substep "Checking GPU usage monitoring..."
        if ! radeontop -d- -l1 > /dev/null 2>&1; then
            print_warning "Unable to read GPU usage. Make sure you have the necessary permissions"
        fi
        print_success "GPU monitoring verification completed"
    fi
}

prompt_reboot() {
    echo -e "\n${BOLD}${MAGENTA}==>${NC} ${BOLD}Installation completed!${NC}"
    echo -e "${YELLOW}Note:${NC} Some changes might require a system restart to take effect."
    read -p "Would you like to reboot now? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        print_message "Rebooting system..."
        systemctl reboot
    fi
}

set_hyprpaper_conf() {
    print_step "Setting up wallpaper configuration"
    local config_path="$HOME/.config/hypr/hyprpaper.conf"
    local wallpaper="/home/martin/dotfiles/assets/wallpapers/evilpuccin.png"
    local env_type
    env_type=$(detect_environment)

    print_substep "Generating hyprpaper.conf for $env_type environment..."
    if [ "$env_type" = "vm" ]; then
        cat > "$config_path" <<EOF
preload = $wallpaper
wallpaper = Virtual-1,$wallpaper
splash = false
EOF
    else
        cat > "$config_path" <<EOF
preload = $wallpaper
wallpaper = DP-3,$wallpaper
wallpaper = DP-1,$wallpaper
wallpaper = HDMI-A-1,$wallpaper
splash = false
EOF
    fi
    print_success "hyprpaper.conf generated"
}

automount_external_drives() {
    print_step "Setting up external drive automounting"
    print_substep "Scanning for external drives with labels..."
    lsblk -o NAME,LABEL,TYPE,MOUNTPOINT | grep part | grep -v '/$' | grep -v '/boot' | while read -r line; do
        dev_name=$(echo $line | awk '{print $1}')
        label=$(echo $line | awk '{print $2}')
        if [ -n "$label" ]; then
            mountpoint="/mnt/$label"
            device="/dev/$dev_name"
            print_progress "Found drive: $label ($device)"
            # Check if already in fstab
            if ! grep -q "LABEL=$label" /etc/fstab; then
                print_substep "Adding $label to /etc/fstab..."
                sudo mkdir -p "$mountpoint"
                echo "LABEL=$label $mountpoint auto nosuid,nodev,nofail,x-gvfs-show 0 0" | sudo tee -a /etc/fstab
            else
                print_message "$label already in /etc/fstab"
            fi
        fi
    done
    print_success "Automount configuration complete! You can now run: sudo mount -a"
}

main() {
    if [ "$EUID" -eq 0 ]; then
        handle_error "Please do not run as root"
    fi
    check_command "git"
    check_command "make"
    check_command "gcc"
    ENV_TYPE=$(detect_environment)
    print_message "Detected environment: $ENV_TYPE"
    check_wayland_session

    read -p "Do you want to install all required packages? [Y/n]: " ans
    if [[ ! "$ans" =~ ^[Nn]$ ]]; then
        install_yay
        install_packages
        install_physical_packages
        install_lf_and_deps
    fi

    read -p "Do you want to backup existing configs? [Y/n]: " ans
    if [[ ! "$ans" =~ ^[Nn]$ ]]; then
        backup_configs
        rotate_backups
    fi

    read -p "Do you want to create symlinks for configs? [Y/n]: " ans
    if [[ ! "$ans" =~ ^[Nn]$ ]]; then
        create_symlinks
    fi

    read -p "Do you want to set up wallpapers? [Y/n]: " ans
    if [[ ! "$ans" =~ ^[Nn]$ ]]; then
        set_hyprpaper_conf
    fi

    set_permissions
    configure_env_specific
    configure_defaults

    read -p "Do you want to set fish as your default shell? [Y/n]: " ans
    if [[ ! "$ans" =~ ^[Nn]$ ]]; then
        set_fish_shell
    fi

    if [ "$ENV_TYPE" = "physical" ]; then
        read -p "Do you want to set up the Windows 11 VM entry? [y/N]: " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            install_win11_vm_entry
            restore_vm
        fi
        read -p "Would you like to automatically add external drives to /etc/fstab for automounting? [y/N]: " automount_ans
        if [[ "$automount_ans" =~ ^[Yy]$ ]]; then
            automount_external_drives
        fi
    fi

    final_verification
    verify_gpu_monitoring
    prompt_reboot
}

main 