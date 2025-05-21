#!/bin/bash

# NOTE: The original version of this script is backed up as install.sh.bak

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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
        print_message "Installing yay..."
        if [ -d /tmp/yay ]; then
            print_warning "/tmp/yay already exists. Removing it to continue yay installation."
            rm -rf /tmp/yay || handle_error "Failed to remove existing /tmp/yay directory"
        fi
        git clone https://aur.archlinux.org/yay.git /tmp/yay || handle_error "Failed to clone yay repository"
        (cd /tmp/yay && makepkg -si --noconfirm) || handle_error "Failed to install yay"
        rm -rf /tmp/yay
    fi
}

install_packages() {
    print_message "Installing required packages..."
    COMMON_PACKAGES="hyprland hyprpaper waybar kitty fish fuzzel dunst polkit-gnome xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland pipewire wireplumber pavucontrol pamixer playerctl grim slurp wl-clipboard swappy cliphist catppuccin-gtk-theme-mocha ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji papirus-icon-theme thunar thunar-volman thunar-archive-plugin xdg-utils xdg-user-dirs network-manager-applet blueman jq swaylock-effects vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau gnupg exa ripgrep fzf ttf-inter lm_sensors radeontop wlsunset light ddcutil zoxide"
    MISSING_PACKAGES=()
    for package in $COMMON_PACKAGES; do
        if ! yay -Q "$package" &>/dev/null; then
            MISSING_PACKAGES+=("$package")
        fi
    done
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        print_message "Installing missing packages: ${MISSING_PACKAGES[*]}"
        for pkg in "${MISSING_PACKAGES[@]}"; do
            if yay -S --needed --noconfirm "$pkg"; then
                print_success "Installed $pkg"
            else
                print_warning "Failed to install $pkg. Please check if this package exists or if there are network/repo issues."
            fi
        done
    fi
}

install_physical_packages() {
    ENV_TYPE=$(detect_environment)
    if [ "$ENV_TYPE" = "physical" ]; then
        print_message "Installing physical machine specific packages..."
        yay -S --needed --noconfirm brightnessctl || handle_error "Failed to install brightnessctl"
    fi
}

install_lf_and_deps() {
    print_message "Setting up lf file manager..."
    if ! command -v lf &>/dev/null; then
        print_message "Installing lf..."
        yay -S --needed --noconfirm lf || handle_error "Failed to install lf file manager"
    fi
    LF_DEPENDENCIES="bat file mediainfo chafa atool ffmpegthumbnailer poppler"
    print_message "Installing lf dependencies for preview capabilities..."
    for package in $LF_DEPENDENCIES; do
        if ! yay -Q "$package" &>/dev/null; then
            print_message "Installing $package..."
            yay -S --needed --noconfirm "$package" || print_warning "Failed to install $package (non-critical)"
        fi
    done
}

backup_configs() {
    print_message "Backing up existing configurations..."
    config_dir="$HOME/.config"
    backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    if [ -d "$config_dir" ]; then
        mkdir -p "$backup_dir"
        for dir in hypr waybar kitty fish dunst fuzzel lf; do
            if [ -d "$config_dir/$dir" ]; then
                cp -r "$config_dir/$dir" "$backup_dir/" || print_warning "Failed to backup $dir"
            fi
        done
    fi
}

rotate_backups() {
    find "$HOME" -maxdepth 1 -name ".config-backup-*" -type d -printf '%T@ %p\n' | \
        sort -n | head -n -5 | cut -d' ' -f2- | xargs -r rm -rf
}

create_symlinks() {
    print_message "Creating symlinks..."
    dotfiles_dir="$(pwd)"
    for dir in config/*; do
        if [ -d "$dir" ]; then
            base_name=$(basename "$dir")
            case "$base_name" in
                "applications")
                    mkdir -p "$HOME/.local/share/applications"
                    for file in "$dir"/*; do
                        if [ -f "$file" ]; then
                            target="$HOME/.local/share/applications/$(basename "$file")"
                            ln -sf "$dotfiles_dir/$file" "$target"
                            verify_symlink "$dotfiles_dir/$file" "$target" || print_warning "Failed to verify symlink for $(basename "$file")"
                        fi
                    done
                    ;;
                *)
                    target_dir="$HOME/.config/$base_name"
                    mkdir -p "$(dirname "$target_dir")"
                    ln -sf "$dotfiles_dir/$dir" "$target_dir"
                    verify_symlink "$dotfiles_dir/$dir" "$target_dir" || print_warning "Failed to verify symlink for $base_name"
                    ;;
            esac
        fi
    done
}

set_permissions() {
    print_message "Setting lf script permissions..."
    chmod +x "$HOME/.config/lf/preview.sh" "$HOME/.config/lf/cleaner.sh" || print_warning "Failed to set permissions for lf scripts"
    print_message "Setting script permissions..."
    find "$HOME/.config/hypr/scripts/" -type f -name "*.sh" -exec chmod +x {} \; || print_warning "Failed to set permissions for Hyprland scripts"
    find "$HOME/.config/waybar/scripts/" -type f -name "*.sh" -exec chmod +x {} \; || print_warning "Failed to set permissions for Waybar scripts"
}

configure_env_specific() {
    print_message "Configuring environment-specific settings..."
    dotfiles_dir="$(pwd)"
    ENV_TYPE=$(detect_environment)
    if [ "$ENV_TYPE" = "vm" ]; then
        ln -sf "$dotfiles_dir/config/hypr/monitors-vm.conf" "$HOME/.config/hypr/monitors.conf"
        verify_symlink "$dotfiles_dir/config/hypr/monitors-vm.conf" "$HOME/.config/hypr/monitors.conf" || \
            handle_error "Failed to configure VM monitor settings"
    else
        ln -sf "$dotfiles_dir/config/hypr/monitors-physical.conf" "$HOME/.config/hypr/monitors.conf"
        verify_symlink "$dotfiles_dir/config/hypr/monitors-physical.conf" "$HOME/.config/hypr/monitors.conf" || \
            handle_error "Failed to configure physical monitor settings"
    fi
}

configure_defaults() {
    print_message "Configuring default applications..."
    xdg-mime default kitty.desktop x-scheme-handler/terminal
    xdg-mime default kitty.desktop application/x-terminal-emulator
    print_message "Updating XDG user directories..."
    xdg-user-dirs-update || print_warning "Failed to update XDG user directories"
    mkdir -p "$HOME/Pictures/Screenshots" || handle_error "Failed to create Screenshots directory"
}

set_fish_shell() {
    local fish_path
    fish_path="$(command -v fish)"
    if [ "$SHELL" != "$fish_path" ]; then
        print_message "Setting fish as default shell..."
        if chsh -s "$fish_path"; then
            print_success "Default shell changed to fish."
        else
            print_warning "Could not change default shell. You may need to do it manually."
        fi
    else
        print_message "Fish is already the default shell."
    fi
}

install_win11_vm_entry() {
    dotfiles_dir="$(pwd)"
    chmod +x "$dotfiles_dir/scripts/launch-win11-vm.sh"
    mkdir -p "$HOME/.local/share/applications"
    cp "$dotfiles_dir/desktop/win11-vm.desktop" "$HOME/.local/share/applications/win11-vm.desktop"
}

restore_vm() {
    dotfiles_dir="$(pwd)"
    VM_XML="$dotfiles_dir/vm/win11.xml"
    VM_DISK="/mnt/Stuff/VM_Backup/win11.qcow2"
    if [ -f "$VM_XML" ] && [ -f "$VM_DISK" ]; then
        if ! virsh --connect qemu:///system list --all | grep -q win11; then
            sudo virsh --connect qemu:///system define "$VM_XML"
            print_success "Restored Windows 11 VM from repo XML."
        else
            print_message "Windows 11 VM already defined, skipping restore."
        fi
    else
        print_warning "VM XML or disk not found, skipping VM restore."
    fi
}

final_verification() {
    print_message "Performing final verification..."
    missing_deps=0
    for cmd in hyprland waybar kitty fish fuzzel dunst jq wl-copy wl-paste swaylock sensors radeontop ddcutil lf; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "Required command '$cmd' not found after installation!"
            missing_deps=1
        fi
    done
    if [ $missing_deps -eq 1 ]; then
        print_warning "Some dependencies are missing. Please check the error messages above."
    else
        print_success "All core dependencies are installed correctly."
    fi
}

verify_gpu_monitoring() {
    ENV_TYPE=$(detect_environment)
    if [ "$ENV_TYPE" = "physical" ]; then
        print_message "Verifying GPU monitoring setup..."
        if ! sensors amdgpu-* > /dev/null 2>&1; then
            print_warning "AMD GPU sensors not detected. GPU monitoring may not work correctly."
        fi
        if ! radeontop -d- -l1 > /dev/null 2>&1; then
            print_warning "Unable to read GPU usage. Make sure you have the necessary permissions."
        fi
    fi
}

prompt_reboot() {
    read -p "Would you like to reboot now? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        systemctl reboot
    fi
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
    install_yay
    install_packages
    install_physical_packages
    install_lf_and_deps
    backup_configs
    rotate_backups
    create_symlinks
    set_permissions
    configure_env_specific
    configure_defaults
    set_fish_shell
    ENV_TYPE=$(detect_environment)
    if [ "$ENV_TYPE" = "physical" ]; then
        install_win11_vm_entry
        restore_vm
    fi
    final_verification
    verify_gpu_monitoring
    print_success "Installation completed! Please log out and log back in to start Hyprland."
    print_message "Note: Some changes might require a system restart to take effect."
    prompt_reboot
}

main 