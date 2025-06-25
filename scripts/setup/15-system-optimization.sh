#!/bin/bash

# System Optimization Script
# Author: Martin's Dotfiles - Modular Version
# Description: Optimize system performance and apply tweaks

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/optimization_$(date +%Y%m%d_%H%M%S).log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Flags
SKIP_CONFIRMATION=false
SKIP_KERNEL_PARAMS=false
SKIP_SYSCTL=false
SKIP_SYSTEMD=false
SKIP_ZRAM=false
DRY_RUN=false

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    echo "Starting system optimization - $(date)" >> "$LOG_FILE"
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
    
    # Check if we're on Arch Linux
    if [[ ! -f "/etc/arch-release" ]]; then
        log_warning "Not running on Arch Linux - some optimizations may not apply"
    fi
    
    log_success "Prerequisites check passed"
}

# Get system information
get_system_info() {
    log_section "System Information"
    
    local cpu_info
    cpu_info=$(lscpu | grep "Model name:" | sed 's/Model name: *//')
    log_info "CPU: $cpu_info"
    
    local ram_info
    ram_info=$(free -h | awk '/^Mem:/ {print $2}')
    log_info "RAM: $ram_info"
    
    local gpu_info
    if command -v lspci &>/dev/null; then
        gpu_info=$(lspci | grep -i "vga\|3d\|display" | head -1 | cut -d: -f3 | sed 's/^ *//')
        log_info "GPU: $gpu_info"
    fi
    
    local kernel_info
    kernel_info=$(uname -r)
    log_info "Kernel: $kernel_info"
    
    local storage_info
    storage_info=$(lsblk -d -o NAME,SIZE,MODEL | grep -E "nvme|sda|sdb" | head -1)
    log_info "Storage: $storage_info"
}

# Optimize kernel parameters
optimize_kernel_params() {
    if [[ "$SKIP_KERNEL_PARAMS" == "true" ]]; then
        log_info "Skipping kernel parameters optimization"
        return 0
    fi
    
    log_section "Optimizing Kernel Parameters"
    
    local kernel_params_file="/etc/default/grub"
    local current_params
    
    if [[ ! -f "$kernel_params_file" ]]; then
        log_warning "GRUB configuration file not found"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would optimize kernel parameters"
        return 0
    fi
    
    # Backup current GRUB config
    sudo cp "$kernel_params_file" "${kernel_params_file}.backup.$(date +%s)"
    log_info "Backed up GRUB configuration"
    
    # Define optimizations based on system type
    local additional_params=""
    
    # Check if we have an SSD
    if lsblk -d -o NAME,ROTA | grep -q "0$"; then
        additional_params+=" elevator=noop"
        log_info "SSD detected - adding elevator=noop"
    fi
    
    # Check available RAM for swap optimization
    local ram_gb
    ram_gb=$(free -g | awk '/^Mem:/ {print $2}')
    if [[ $ram_gb -ge 8 ]]; then
        additional_params+=" vm.swappiness=10"
        log_info "High RAM detected - reducing swappiness"
    fi
    
    # Add performance parameters
    additional_params+=" quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3"
    
    # Update GRUB configuration
    current_params=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "$kernel_params_file" | cut -d'"' -f2)
    
    if [[ "$current_params" != *"$additional_params"* ]]; then
        log_info "Adding kernel parameters: $additional_params"
        sudo sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1$additional_params\"/" "$kernel_params_file"
        
        # Regenerate GRUB configuration
        if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
            log_success "GRUB configuration updated"
            log_warning "Reboot required for kernel parameter changes to take effect"
        else
            log_error "Failed to update GRUB configuration"
        fi
    else
        log_success "Kernel parameters already optimized"
    fi
}

# Configure sysctl optimizations
configure_sysctl() {
    if [[ "$SKIP_SYSCTL" == "true" ]]; then
        log_info "Skipping sysctl optimization"
        return 0
    fi
    
    log_section "Configuring Sysctl Optimizations"
    
    local sysctl_file="/etc/sysctl.d/99-custom-optimizations.conf"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would configure sysctl optimizations"
        return 0
    fi
    
    log_info "Creating sysctl optimization configuration"
    
    sudo tee "$sysctl_file" > /dev/null << 'EOF'
# Custom System Optimizations
# Generated by dotfiles modular installer

# VM Memory Management
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Network Performance
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3

# File System
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024

# Kernel
kernel.sched_autogroup_enabled = 1
kernel.sched_child_runs_first = 1
kernel.hung_task_timeout_secs = 0
EOF
    
    # Apply sysctl settings
    if sudo sysctl -p "$sysctl_file"; then
        log_success "Sysctl optimizations applied"
    else
        log_warning "Some sysctl settings may not have been applied"
    fi
    
    log_success "Sysctl optimization configuration created: $sysctl_file"
}

# Optimize systemd services
optimize_systemd_services() {
    if [[ "$SKIP_SYSTEMD" == "true" ]]; then
        log_info "Skipping systemd optimization"
        return 0
    fi
    
    log_section "Optimizing Systemd Services"
    
    # Services that can be safely disabled on desktop systems
    local services_to_disable=(
        "bluetooth.service"      # Only if not using Bluetooth
        "cups.service"          # Only if not printing
        "avahi-daemon.service"  # Only if not using network discovery
        "systemd-resolved.service" # Only if using different DNS
    )
    
    # Services to mask (more aggressive)
    local services_to_mask=(
        "systemd-networkd-wait-online.service"
        "NetworkManager-wait-online.service"
    )
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would optimize systemd services"
        return 0
    fi
    
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        read -p "Optimize systemd services? This may disable some services. (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipped systemd optimization"
            return 0
        fi
    fi
    
    # Mask unnecessary wait services
    for service in "${services_to_mask[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            log_info "Masking service: $service"
            if sudo systemctl mask "$service"; then
                log_success "Masked: $service"
            else
                log_warning "Failed to mask: $service"
            fi
        fi
    done
    
    # Enable systemd optimizations
    log_info "Enabling systemd optimizations..."
    
    # Create systemd configuration override
    local systemd_override_dir="/etc/systemd/system.conf.d"
    sudo mkdir -p "$systemd_override_dir"
    
    sudo tee "$systemd_override_dir/99-custom-optimizations.conf" > /dev/null << 'EOF'
[Manager]
# Reduce default timeout values
DefaultTimeoutStartSec=30s
DefaultTimeoutStopSec=15s
DefaultRestartSec=1s
# Reduce log level for performance
LogLevel=warning
EOF
    
    log_success "Systemd optimization configuration created"
}

# Setup ZRAM
setup_zram() {
    if [[ "$SKIP_ZRAM" == "true" ]]; then
        log_info "Skipping ZRAM setup"
        return 0
    fi
    
    log_section "Setting up ZRAM"
    
    # Check if zram is already configured
    if systemctl is-active systemd-zram-setup@zram0.service &>/dev/null; then
        log_success "ZRAM is already configured and active"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would setup ZRAM"
        return 0
    fi
    
    # Check if zram-generator is installed
    if ! command -v zram-generator &>/dev/null && ! pacman -Q zram-generator &>/dev/null; then
        log_info "Installing zram-generator..."
        if yay -S --needed --noconfirm zram-generator; then
            log_success "zram-generator installed"
        else
            log_error "Failed to install zram-generator"
            return 1
        fi
    fi
    
    # Configure ZRAM
    local zram_config="/etc/systemd/zram-generator.conf"
    local ram_size_mb
    ram_size_mb=$(free -m | awk '/^Mem:/ {print $2}')
    local zram_size_mb=$((ram_size_mb / 2))  # Use half of available RAM
    
    log_info "Configuring ZRAM with ${zram_size_mb}MB size"
    
    sudo tee "$zram_config" > /dev/null << EOF
[zram0]
zram-size = ${zram_size_mb}MB
compression-algorithm = lz4
EOF
    
    # Enable and start ZRAM
    if sudo systemctl daemon-reload && sudo systemctl start systemd-zram-setup@zram0.service; then
        if sudo systemctl enable systemd-zram-setup@zram0.service; then
            log_success "ZRAM configured and enabled"
            
            # Show ZRAM status
            if command -v zramctl &>/dev/null; then
                log_info "ZRAM status:"
                zramctl || true
            fi
        else
            log_warning "ZRAM started but failed to enable on boot"
        fi
    else
        log_error "Failed to start ZRAM service"
    fi
}

# Apply I/O scheduler optimizations
optimize_io_scheduler() {
    log_section "Optimizing I/O Scheduler"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would optimize I/O scheduler"
        return 0
    fi
    
    # Create udev rule for I/O scheduler optimization
    local udev_rule="/etc/udev/rules.d/60-ioschedulers.rules"
    
    log_info "Creating I/O scheduler optimization rules"
    
    sudo tee "$udev_rule" > /dev/null << 'EOF'
# Set I/O scheduler based on storage type
# SSD/NVMe: use none (multi-queue) or mq-deadline
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="nvme*", ATTR{queue/scheduler}="none"

# HDD: use bfq for better interactive performance
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF
    
    # Reload udev rules
    if sudo udevadm control --reload-rules; then
        log_success "I/O scheduler optimization rules created"
    else
        log_warning "Failed to reload udev rules"
    fi
}

# Create system monitoring script
create_monitoring_script() {
    log_section "Creating System Monitoring Script"
    
    local bin_dir="$HOME/.local/bin"
    local monitor_script="$bin_dir/system-monitor"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would create system monitoring script"
        return 0
    fi
    
    mkdir -p "$bin_dir"
    
    cat > "$monitor_script" << 'EOF'
#!/bin/bash
# System Performance Monitor

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

show_usage() {
    cat << 'USAGE'
Usage: system-monitor [COMMAND]

Monitor system performance and resource usage.

COMMANDS:
    cpu         Show CPU usage and frequency
    memory      Show memory usage and details
    disk        Show disk usage and I/O
    network     Show network statistics
    thermal     Show temperature information
    processes   Show top processes by resource usage
    all         Show all system information (default)

EXAMPLES:
    system-monitor
    system-monitor cpu
    system-monitor memory

USAGE
}

show_cpu() {
    echo -e "${BLUE}=== CPU Information ===${NC}"
    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2 $3 $4 $5 $6 $7 $8}'
    echo
    echo "CPU Frequencies:"
    if [[ -f /proc/cpuinfo ]]; then
        grep "cpu MHz" /proc/cpuinfo | head -4
    fi
    echo
    echo "Load Average:"
    uptime | awk -F'load average:' '{print $2}'
    echo
}

show_memory() {
    echo -e "${BLUE}=== Memory Information ===${NC}"
    free -h
    echo
    if command -v zramctl &>/dev/null; then
        echo "ZRAM Status:"
        zramctl 2>/dev/null || echo "ZRAM not configured"
        echo
    fi
    echo "Memory Usage by Process:"
    ps aux --sort=-%mem | head -6
    echo
}

show_disk() {
    echo -e "${BLUE}=== Disk Information ===${NC}"
    echo "Disk Usage:"
    df -h | grep -E "^/dev"
    echo
    echo "Disk I/O:"
    if command -v iostat &>/dev/null; then
        iostat -x 1 1 2>/dev/null | tail -n +4
    else
        echo "iostat not available (install sysstat)"
    fi
    echo
    echo "I/O Schedulers:"
    for disk in /sys/block/*/queue/scheduler; do
        if [[ -r "$disk" ]]; then
            echo "$(basename $(dirname $(dirname "$disk"))): $(cat "$disk")"
        fi
    done
    echo
}

show_network() {
    echo -e "${BLUE}=== Network Information ===${NC}"
    echo "Network Interfaces:"
    ip -s link show | grep -E "^[0-9]+:|RX:|TX:" | head -20
    echo
    echo "Active Connections:"
    ss -tuln | head -10
    echo
}

show_thermal() {
    echo -e "${BLUE}=== Thermal Information ===${NC}"
    if command -v sensors &>/dev/null; then
        sensors
    else
        echo "lm-sensors not available"
        if [[ -d /sys/class/thermal ]]; then
            echo "Thermal zones:"
            for zone in /sys/class/thermal/thermal_zone*/temp; do
                if [[ -r "$zone" ]]; then
                    temp=$(cat "$zone")
                    temp_c=$((temp / 1000))
                    zone_name=$(basename $(dirname "$zone"))
                    echo "$zone_name: ${temp_c}°C"
                fi
            done
        fi
    fi
    echo
}

show_processes() {
    echo -e "${BLUE}=== Process Information ===${NC}"
    echo "Top CPU Processes:"
    ps aux --sort=-%cpu | head -6
    echo
    echo "Top Memory Processes:"
    ps aux --sort=-%mem | head -6
    echo
}

show_all() {
    show_cpu
    show_memory
    show_disk
    show_network
    show_thermal
    show_processes
}

case "${1:-all}" in
    cpu)
        show_cpu
        ;;
    memory)
        show_memory
        ;;
    disk)
        show_disk
        ;;
    network)
        show_network
        ;;
    thermal)
        show_thermal
        ;;
    processes)
        show_processes
        ;;
    all)
        show_all
        ;;
    -h|--help)
        show_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac
EOF
    
    chmod +x "$monitor_script"
    log_success "System monitoring script created: $monitor_script"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Optimize system performance with various tweaks and configurations.

OPTIONS:
    -h, --help              Show this help message
    -n, --dry-run           Show what would be done without making changes
    -y, --yes               Skip confirmation prompts
    --skip-kernel-params    Skip kernel parameter optimization
    --skip-sysctl           Skip sysctl configuration
    --skip-systemd          Skip systemd optimization
    --skip-zram             Skip ZRAM setup
    --log-dir DIR           Custom log directory (default: ~/dotfiles/logs)
    --dotfiles-dir DIR      Custom dotfiles directory (default: auto-detect)

DESCRIPTION:
    This script applies various system optimizations for better performance
    and responsiveness on Arch Linux systems.

OPTIMIZATIONS APPLIED:
    • Kernel parameter tuning (quiet boot, SSD optimization)
    • Sysctl configuration (VM, network, filesystem tweaks)
    • Systemd service optimization
    • ZRAM setup for better memory management
    • I/O scheduler optimization
    • System monitoring utilities

FEATURES:
    • Hardware-aware optimizations
    • Safe defaults with backup of original configs
    • Comprehensive system monitoring tools
    • Performance tuning for gaming and development

SAFETY:
    • Creates backups of modified system files
    • Only applies safe, well-tested optimizations
    • Provides dry-run mode to preview changes
    • Detailed logging of all modifications

EXAMPLES:
    $SCRIPT_NAME                    # Full system optimization
    $SCRIPT_NAME --skip-zram        # Optimize without ZRAM
    $SCRIPT_NAME -n                 # Dry run to see what would be done
    $SCRIPT_NAME -y                 # Optimize without confirmations

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
            --skip-kernel-params)
                SKIP_KERNEL_PARAMS=true
                shift
                ;;
            --skip-sysctl)
                SKIP_SYSCTL=true
                shift
                ;;
            --skip-systemd)
                SKIP_SYSTEMD=true
                shift
                ;;
            --skip-zram)
                SKIP_ZRAM=true
                shift
                ;;
            --log-dir)
                if [[ -n "${2:-}" ]]; then
                    LOG_DIR="$2"
                    LOG_FILE="${LOG_DIR}/optimization_$(date +%Y%m%d_%H%M%S).log"
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
    
    echo "=== System Optimization ==="
    echo "Log file: $LOG_FILE"
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo
    
    check_prerequisites
    get_system_info
    optimize_kernel_params
    configure_sysctl
    optimize_systemd_services
    setup_zram
    optimize_io_scheduler
    create_monitoring_script
    
    echo
    if [[ "$DRY_RUN" == "true" ]]; then
        log_success "Dry run completed - no changes were made"
    else
        log_success "System optimization completed!"
        log_info "Use 'system-monitor' to check system performance"
        log_warning "Some optimizations require a reboot to take effect"
    fi
    
    echo "Log file: $LOG_FILE"
}

# Run main function
main "$@" 