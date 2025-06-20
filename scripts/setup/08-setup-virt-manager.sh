#!/bin/bash

# Virtualization Setup Script
# Author: Martin's Dotfiles - Modular Version
# Description: Setup KVM/QEMU virtualization with virt-manager

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/virt-setup_$(date +%Y%m%d_%H%M%S).log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Flags
SKIP_CONFIRMATION=false
SKIP_PACKAGES=false
SKIP_SERVICES=false
SKIP_USER_SETUP=false
DRY_RUN=false

# Global variable to track group changes
declare -a GROUPS_ADDED=()

# Virtualization packages
declare -a VIRT_PACKAGES=(
    "qemu-full"
    "libvirt"
    "virt-manager"
    "virt-viewer"
    "dnsmasq"
    "vde2"
    "bridge-utils"
    "openbsd-netcat"
    # Note: iptables-nft is handled separately due to conflicts
)

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    echo "Starting virtualization setup - $(date)" >> "$LOG_FILE"
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
    
    # Check sudo access
    if ! sudo -v &>/dev/null; then
        log_error "No sudo access"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Check virtualization support
check_virtualization_support() {
    log_section "Checking Virtualization Support"
    
    # Check for CPU virtualization extensions
    local virt_support=""
    if grep -q "vmx" /proc/cpuinfo; then
        virt_support="Intel VT-x"
    elif grep -q "svm" /proc/cpuinfo; then
        virt_support="AMD-V"
    else
        log_error "No CPU virtualization support detected"
        log_error "Enable VT-x/AMD-V in BIOS/UEFI settings"
        return 1
    fi
    
    log_success "CPU virtualization support: $virt_support"
    
    # Check if KVM module is loaded
    if lsmod | grep -q "kvm"; then
        log_success "KVM kernel module is loaded"
    else
        log_warning "KVM kernel module not loaded"
        log_info "Attempting to load KVM module..."
        
        if [[ "$DRY_RUN" != "true" ]]; then
            if grep -q "vmx" /proc/cpuinfo; then
                sudo modprobe kvm_intel || log_warning "Failed to load kvm_intel"
            elif grep -q "svm" /proc/cpuinfo; then
                sudo modprobe kvm_amd || log_warning "Failed to load kvm_amd"
            fi
            sudo modprobe kvm || log_warning "Failed to load kvm"
        fi
    fi
    
    # Check KVM device permissions
    if [[ -e "/dev/kvm" ]]; then
        if [[ -r "/dev/kvm" && -w "/dev/kvm" ]]; then
            log_success "KVM device is accessible"
        else
            log_warning "KVM device permissions need adjustment"
        fi
    else
        log_warning "KVM device not found"
    fi
    
    log_success "Virtualization support check completed"
}

# Handle package conflicts
handle_package_conflicts() {
    log_info "Checking for package conflicts..."
    
    # Handle iptables vs iptables-nft conflict
    if pacman -Q iptables &>/dev/null && ! pacman -Q iptables-nft &>/dev/null; then
        log_info "Detected iptables conflict - need to replace with iptables-nft"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "DRY RUN - Would replace iptables with iptables-nft"
            return 0
        fi
        
        if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
            read -p "Replace iptables with iptables-nft? (required for virtualization) (Y/n): " -r
            if [[ $REPLY =~ ^[Nn]$ ]]; then
                log_warning "Skipping iptables replacement - virtualization may not work properly"
                return 0
            fi
        fi
        
        log_info "Replacing iptables with iptables-nft..."
        log_info "This requires removing the conflicting iptables package first..."
        
        # Step 1: Remove conflicting package
        if sudo pacman -Rdd --noconfirm iptables; then
            log_success "Removed conflicting iptables package"
            
            # Step 2: Install iptables-nft
            if sudo pacman -S --noconfirm iptables-nft; then
                log_success "Successfully installed iptables-nft"
            else
                log_error "Failed to install iptables-nft after removing iptables"
                log_warning "System may be in inconsistent state - reinstalling iptables..."
                sudo pacman -S --noconfirm iptables || true
                return 1
            fi
        else
            log_error "Failed to remove conflicting iptables package"
            log_warning "You may need to manually resolve this conflict:"
            log_info "  sudo pacman -Rdd iptables"
            log_info "  sudo pacman -S iptables-nft"
            return 1
        fi
    elif pacman -Q iptables-nft &>/dev/null; then
        log_success "iptables-nft is already installed"
    fi
}

# Install virtualization packages
install_virt_packages() {
    if [[ "$SKIP_PACKAGES" == "true" ]]; then
        log_info "Skipping virtualization packages installation"
        return 0
    fi
    
    log_section "Installing Virtualization Packages"
    
    # Handle conflicts first
    handle_package_conflicts
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would install ${#VIRT_PACKAGES[@]} virtualization packages:"
        for package in "${VIRT_PACKAGES[@]}"; do
            echo "  • $package"
        done
        return 0
    fi
    
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        echo "Virtualization packages to install:"
        for package in "${VIRT_PACKAGES[@]}"; do
            echo "  • $package"
        done
        echo
        read -p "Install virtualization packages? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipped virtualization packages installation"
            return 0
        fi
    fi
    
    log_info "Installing virtualization packages..."
    local failed_packages=()
    
    for package in "${VIRT_PACKAGES[@]}"; do
        log_info "Installing: $package"
        
        if yay -Q "$package" &>/dev/null; then
            log_success "$package is already installed"
            continue
        fi
        
        if yay -S --needed --noconfirm --overwrite '*' "$package"; then
            log_success "$package installed successfully"
        else
            log_error "Failed to install: $package"
            failed_packages+=("$package")
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warning "Failed to install some packages:"
        for package in "${failed_packages[@]}"; do
            echo "  ✗ $package"
        done
        return 1
    fi
    
    log_success "All virtualization packages installed successfully"
}

# Configure user groups
setup_user_groups() {
    if [[ "$SKIP_USER_SETUP" == "true" ]]; then
        log_info "Skipping user group setup"
        return 0
    fi
    
    log_section "Setting up User Groups"
    
    local required_groups=("libvirt" "kvm")
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would add user to groups: ${required_groups[*]}"
        return 0
    fi
    
    for group in "${required_groups[@]}"; do
        if groups "$USER" | grep -q "\b$group\b"; then
            log_success "User already in group: $group"
        else
            log_info "Adding user to group: $group"
            if sudo usermod -aG "$group" "$USER"; then
                log_success "Added user to group: $group"
                GROUPS_ADDED+=("$group")
            else
                log_warning "Failed to add user to group: $group"
            fi
        fi
    done
    
    if [[ ${#GROUPS_ADDED[@]} -gt 0 ]]; then
        log_warning "Group membership changes require logout/login to take effect"
        log_info "Added to groups: ${GROUPS_ADDED[*]}"
    fi
}

# Configure libvirt services
setup_libvirt_services() {
    if [[ "$SKIP_SERVICES" == "true" ]]; then
        log_info "Skipping libvirt services setup"
        return 0
    fi
    
    log_section "Setting up Libvirt Services"
    
    local services=("libvirtd" "virtlogd")
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would enable and start services: ${services[*]}"
        return 0
    fi
    
    for service in "${services[@]}"; do
        log_info "Configuring service: $service"
        
        # Enable service
        if sudo systemctl enable "$service"; then
            log_success "Enabled service: $service"
        else
            log_warning "Failed to enable service: $service"
        fi
        
        # Start service
        if sudo systemctl start "$service"; then
            log_success "Started service: $service"
        else
            log_warning "Failed to start service: $service"
        fi
        
        # Check service status
        if sudo systemctl is-active "$service" &>/dev/null; then
            log_success "Service is running: $service"
        else
            log_warning "Service is not running: $service"
        fi
    done
}

# Configure libvirt network
setup_libvirt_network() {
    log_section "Setting up Libvirt Network"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would configure libvirt default network"
        return 0
    fi
    
    # Wait for libvirtd to be ready
    sleep 2
    
    # Check if default network exists
    if sudo virsh net-list --all | grep -q "default"; then
        log_success "Default network already exists"
        
        # Ensure it's active
        if ! sudo virsh net-list | grep -q "default.*active"; then
            log_info "Starting default network..."
            if sudo virsh net-start default; then
                log_success "Default network started"
            else
                log_warning "Failed to start default network"
            fi
        fi
        
        # Ensure it's set to autostart
        if ! sudo virsh net-list --autostart | grep -q "default"; then
            log_info "Setting default network to autostart..."
            if sudo virsh net-autostart default; then
                log_success "Default network set to autostart"
            else
                log_warning "Failed to set default network to autostart"
            fi
        fi
    else
        log_info "Creating default network..."
        
        # Create default network configuration
        local network_xml="/tmp/default-network.xml"
        cat > "$network_xml" << 'EOF'
<network>
  <name>default</name>
  <uuid>9a05da11-e96b-47f3-8253-a3a482e445f5</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:0a:cd:21'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF
        
        if sudo virsh net-define "$network_xml"; then
            log_success "Default network defined"
            
            if sudo virsh net-start default && sudo virsh net-autostart default; then
                log_success "Default network started and set to autostart"
            else
                log_warning "Failed to start or configure autostart for default network"
            fi
        else
            log_warning "Failed to define default network"
        fi
        
        rm -f "$network_xml"
    fi
}

# Create VM management utilities
create_vm_utilities() {
    log_section "Creating VM Management Utilities"
    
    local bin_dir="$HOME/.local/bin"
    local vm_script="$bin_dir/vm-manager"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would create VM management utilities"
        return 0
    fi
    
    mkdir -p "$bin_dir"
    
    cat > "$vm_script" << 'EOF'
#!/bin/bash
# VM Management Utility

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
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
Usage: vm-manager COMMAND [OPTIONS]

Manage virtual machines with libvirt/KVM.

COMMANDS:
    list            List all VMs
    start VM        Start a VM
    stop VM         Stop a VM
    restart VM      Restart a VM
    status VM       Show VM status
    console VM      Connect to VM console
    info VM         Show VM information
    create          Launch virt-manager GUI
    networks        List virtual networks
    storage         List storage pools

EXAMPLES:
    vm-manager list
    vm-manager start myvm
    vm-manager console ubuntu-desktop
    vm-manager create

USAGE
}

case "${1:-}" in
    list)
        echo -e "${BLUE}Virtual Machines:${NC}"
        virsh list --all
        ;;
    start)
        if [[ -z "${2:-}" ]]; then
            echo -e "${YELLOW}Usage: vm-manager start VM_NAME${NC}"
            exit 1
        fi
        log_info "Starting VM: $2"
        virsh start "$2" && log_success "VM started: $2"
        ;;
    stop)
        if [[ -z "${2:-}" ]]; then
            echo -e "${YELLOW}Usage: vm-manager stop VM_NAME${NC}"
            exit 1
        fi
        log_info "Stopping VM: $2"
        virsh shutdown "$2" && log_success "VM stopped: $2"
        ;;
    restart)
        if [[ -z "${2:-}" ]]; then
            echo -e "${YELLOW}Usage: vm-manager restart VM_NAME${NC}"
            exit 1
        fi
        log_info "Restarting VM: $2"
        virsh reboot "$2" && log_success "VM restarted: $2"
        ;;
    status)
        if [[ -z "${2:-}" ]]; then
            echo -e "${YELLOW}Usage: vm-manager status VM_NAME${NC}"
            exit 1
        fi
        echo -e "${BLUE}VM Status: $2${NC}"
        virsh domstate "$2"
        ;;
    console)
        if [[ -z "${2:-}" ]]; then
            echo -e "${YELLOW}Usage: vm-manager console VM_NAME${NC}"
            exit 1
        fi
        log_info "Connecting to VM console: $2"
        virsh console "$2"
        ;;
    info)
        if [[ -z "${2:-}" ]]; then
            echo -e "${YELLOW}Usage: vm-manager info VM_NAME${NC}"
            exit 1
        fi
        echo -e "${BLUE}VM Information: $2${NC}"
        virsh dominfo "$2"
        ;;
    create)
        log_info "Launching virt-manager GUI..."
        virt-manager &
        ;;
    networks)
        echo -e "${BLUE}Virtual Networks:${NC}"
        virsh net-list --all
        ;;
    storage)
        echo -e "${BLUE}Storage Pools:${NC}"
        virsh pool-list --all
        ;;
    -h|--help|*)
        show_usage
        ;;
esac
EOF
    
    chmod +x "$vm_script"
    log_success "VM management utility created: $vm_script"
}

# Test virtualization setup
test_virtualization() {
    log_section "Testing Virtualization Setup"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would test virtualization setup"
        return 0
    fi
    
    # Test libvirt connection
    if virsh version &>/dev/null; then
        log_success "Libvirt connection test passed"
    else
        log_warning "Libvirt connection test failed"
        return 1
    fi
    
    # Check KVM acceleration
    if [[ -r "/dev/kvm" ]]; then
        log_success "KVM acceleration is available"
    else
        log_warning "KVM acceleration may not be available"
    fi
    
    # Check network status and try to activate if needed
    if virsh net-list | grep -q "default.*active"; then
        log_success "Default virtual network is active"
    else
        log_warning "Default virtual network is not active"
        
        # Check if default network exists but is inactive
        if virsh net-list --all | grep -q "default.*inactive"; then
            log_info "Attempting to start default virtual network..."
            if virsh net-start default &>/dev/null; then
                log_success "Successfully started default virtual network"
                
                # Also set it to autostart if not already
                if ! virsh net-list --autostart | grep -q "default"; then
                    if virsh net-autostart default &>/dev/null; then
                        log_success "Set default network to autostart"
                    fi
                fi
            else
                log_warning "Failed to start default virtual network"
                log_info "You may need to start it manually: virsh net-start default"
            fi
        elif ! virsh net-list --all | grep -q "default"; then
            log_warning "Default virtual network does not exist"
            log_info "It should have been created during setup - you may need to create it manually"
        fi
    fi
    
    # Test virt-manager availability
    if command -v virt-manager &>/dev/null; then
        log_success "virt-manager is available"
    else
        log_warning "virt-manager is not available"
    fi
    
    log_success "Virtualization setup test completed"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Setup KVM/QEMU virtualization with virt-manager.

OPTIONS:
    -h, --help              Show this help message
    -n, --dry-run           Show what would be done without making changes
    -y, --yes               Skip confirmation prompts
    --skip-packages         Skip virtualization packages installation
    --skip-services         Skip libvirt services setup
    --skip-user-setup       Skip user group configuration
    --log-dir DIR           Custom log directory (default: ~/dotfiles/logs)
    --dotfiles-dir DIR      Custom dotfiles directory (default: auto-detect)

DESCRIPTION:
    This script sets up a complete KVM/QEMU virtualization environment with
    virt-manager GUI for easy VM management.

PACKAGES INSTALLED:
    • qemu-full            - Full QEMU emulator
    • libvirt              - Virtualization API
    • virt-manager         - GUI management tool
    • virt-viewer          - VM console viewer
    • dnsmasq              - DHCP/DNS for VMs
    • bridge-utils         - Network bridging
    • And supporting packages

FEATURES:
    • Hardware virtualization detection
    • User group configuration (libvirt, kvm)
    • Libvirt service setup and configuration
    • Default virtual network creation
    • VM management utilities
    • KVM acceleration support

REQUIREMENTS:
    • CPU with VT-x/AMD-V support
    • VT-x/AMD-V enabled in BIOS/UEFI
    • Sufficient RAM for host and VMs
    • Storage space for VM disk images

EXAMPLES:
    $SCRIPT_NAME                    # Full virtualization setup
    $SCRIPT_NAME --skip-packages    # Setup without installing packages
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
            --skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            --skip-services)
                SKIP_SERVICES=true
                shift
                ;;
            --skip-user-setup)
                SKIP_USER_SETUP=true
                shift
                ;;
            --log-dir)
                if [[ -n "${2:-}" ]]; then
                    LOG_DIR="$2"
                    LOG_FILE="${LOG_DIR}/virt-setup_$(date +%Y%m%d_%H%M%S).log"
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
    
    echo "=== Virtualization Setup ==="
    echo "Log file: $LOG_FILE"
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo
    
    check_prerequisites
    check_virtualization_support
    install_virt_packages
    setup_user_groups
    setup_libvirt_services
    setup_libvirt_network
    create_vm_utilities
    test_virtualization
    
    echo
    if [[ "$DRY_RUN" == "true" ]]; then
        log_success "Dry run completed - no changes were made"
    else
        log_success "Virtualization setup completed!"
        log_info "Use 'virt-manager' to create and manage VMs"
        log_info "Use 'vm-manager' for command-line VM operations"
        if [[ ${#GROUPS_ADDED[@]} -gt 0 ]]; then
            log_warning "Please logout and login again for group membership changes"
        fi
    fi
    
    echo "Log file: $LOG_FILE"
}

# Run main function
main "$@" 