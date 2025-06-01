#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print colored message
print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

# Print error message
print_error() {
    echo -e "${RED}Error:${NC} $1"
}

# Print success message
print_success() {
    echo -e "${GREEN}Success:${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run as root"
    exit 1
fi

# Install required packages
print_message "Installing virtualization packages..."
yay -S --needed --noconfirm qemu-desktop virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat libguestfs

# Enable and start libvirtd service
print_message "Enabling libvirtd service..."
sudo systemctl enable --now libvirtd.service
sudo systemctl enable --now virtlogd.socket

# Configure user permissions
print_message "Configuring user permissions..."
sudo usermod -aG libvirt $(whoami)
sudo usermod -aG kvm $(whoami)

# Configure libvirt for normal user access
print_message "Configuring libvirt for user access..."
sudo sed -i 's/#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/' /etc/libvirt/libvirtd.conf
sudo sed -i 's/#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/' /etc/libvirt/libvirtd.conf

# Restart libvirtd to apply changes
print_message "Restarting libvirtd service..."
sudo systemctl restart libvirtd.service

print_success "Virtualization setup completed!"
print_message "Please log out and log back in for group changes to take effect."
print_message "You can then start virt-manager normally." 