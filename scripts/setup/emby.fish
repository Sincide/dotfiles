#!/usr/bin/env fish

# Emby Server Interactive Setup Script for Arch Linux with Hyprland
# Version: 1.0
# Author: System Administrator
# Description: Comprehensive installation and setup script with backup/restore functionality

# Configuration
set -g SCRIPT_NAME "Emby Server Setup"
set -g SCRIPT_VERSION "1.0"
set -g LOG_FILE "/tmp/emby_setup_"(date +%Y%m%d_%H%M%S)".log"
set -g EMBY_DATA_DIR "/var/lib/emby"
set -g MEDIA_DIR "/mnt/Media"
set -g BACKUP_DIR "/mnt/Stuff/backups"
set -g DEBUG_MODE 0

# Color definitions
set -g COLOR_INFO (set_color blue)
set -g COLOR_SUCCESS (set_color green)
set -g COLOR_WARNING (set_color yellow)
set -g COLOR_ERROR (set_color red)
set -g COLOR_RESET (set_color normal)

# Progress tracking
set -g CURRENT_STEP 0
set -g TOTAL_STEPS 0

# Logging function
function log_message --argument level message
    set -l timestamp (date '+%Y-%m-%d %H:%M:%S')
    set -l log_entry "[$timestamp] [$level] $message"
    
    switch $level
        case INFO
            echo "$COLOR_INFO""ℹ  $message""$COLOR_RESET"
        case SUCCESS
            echo "$COLOR_SUCCESS""✓ $message""$COLOR_RESET"
        case WARNING
            echo "$COLOR_WARNING""⚠  $message""$COLOR_RESET"
        case ERROR
            echo "$COLOR_ERROR""✗ $message""$COLOR_RESET" >&2
        case DEBUG
            if test $DEBUG_MODE -eq 1
                echo "$COLOR_INFO""[DEBUG] $message""$COLOR_RESET"
            end
    end
    
    echo $log_entry >> $LOG_FILE
end

# Progress indicator
function init_progress --argument total
    set -g TOTAL_STEPS $total
    set -g CURRENT_STEP 0
    log_message INFO "Starting $SCRIPT_NAME v$SCRIPT_VERSION with $total steps"
end

function update_progress --argument step_name
    set -g CURRENT_STEP (math $CURRENT_STEP + 1)
    set -l percent (math "floor($CURRENT_STEP * 100 / $TOTAL_STEPS)")
    log_message INFO "Step $CURRENT_STEP/$TOTAL_STEPS ($percent%): $step_name"
end

# User confirmation function
function confirm --argument prompt
    if test -z "$prompt"
        set prompt "Continue?"
    end
    
    while true
        read -P "$COLOR_WARNING$prompt [y/N]: $COLOR_RESET" -l response
        switch $response
            case Y y yes
                return 0
            case N n no ''
                return 1
            case '*'
                echo "$COLOR_ERROR""Please answer y or n""$COLOR_RESET"
        end
    end
end

# Auto-fix prompt function
function should_fix --argument problem solution
    echo "$COLOR_WARNING""Problem detected: $problem""$COLOR_RESET"
    echo "$COLOR_INFO""Proposed solution: $solution""$COLOR_RESET"
    
    if confirm "Should I fix this for you?"
        log_message INFO "User approved fix: $solution"
        return 0
    else
        log_message INFO "User declined fix. Manual intervention required."
        return 1
    end
end

# System requirements check
function check_system_requirements
    log_message INFO "Checking system requirements..."
    
    # Check if running on Arch Linux
    if not test -f /etc/arch-release
        if should_fix "Not running on Arch Linux" "Continue anyway (unsupported)"
            log_message WARNING "Continuing on non-Arch system (unsupported)"
        else
            log_message ERROR "Aborting: This script is designed for Arch Linux"
            return 1
        end
    end
    
    # Check if running as regular user (not root)
    if test (id -u) -eq 0
        if should_fix "Running as root user" "Continue with elevated privileges"
            log_message WARNING "Continuing as root user"
        else
            log_message ERROR "Aborting: Please run as regular user"
            return 1
        end
    end
    
    # Check for sudo access
    if not sudo -n true 2>/dev/null
        if should_fix "No passwordless sudo access detected" "Authenticate with sudo password"
            log_message INFO "Please enter your sudo password to continue..."
            if sudo true
                log_message SUCCESS "Sudo authentication successful"
            else
                log_message ERROR "Sudo authentication failed"
                return 1
            end
        else
            log_message ERROR "Sudo access required for installation"
            return 1
        end
    else
        log_message SUCCESS "Passwordless sudo access confirmed"
    end
    
    # Check available disk space (minimum 10GB)
    set -l available_space (df / --output=avail -BG | tail -n1 | tr -d 'G')
    if test $available_space -lt 10
        if should_fix "Insufficient disk space: {$available_space}GB" "Continue with limited space"
            log_message WARNING "Continuing with limited disk space"
        else
            log_message ERROR "Aborting: Insufficient disk space"
            return 1
        end
    end
    
    # Check memory (minimum 2GB)
    set -l memory_gb (free -g | awk '/^Mem:/{print $2}')
    if test $memory_gb -lt 2
        if should_fix "Low memory: {$memory_gb}GB" "Continue with limited memory"
            log_message WARNING "Continuing with limited memory"
        else
            log_message ERROR "Aborting: Insufficient memory"
            return 1
        end
    end
    
    log_message SUCCESS "System requirements check completed"
    return 0
end

# Check dependencies
function check_dependencies
    log_message INFO "Checking required dependencies..."
    
    set -l required_commands sudo systemctl curl wget
    set -l missing_deps
    
    for cmd in $required_commands
        if not command -v $cmd >/dev/null
            set missing_deps $missing_deps $cmd
        end
    end
    
    if test (count $missing_deps) -gt 0
        if should_fix "Missing dependencies: $missing_deps" "Install missing dependencies"
            for dep in $missing_deps
                log_message INFO "Installing $dep..."
                if not sudo pacman -S --needed --noconfirm $dep
                    log_message ERROR "Failed to install $dep"
                    return 1
                end
            end
        else
            log_message ERROR "Aborting: Missing required dependencies"
            return 1
        end
    end
    
    log_message SUCCESS "All dependencies satisfied"
    return 0
end

# Check and install AUR helper
function ensure_aur_helper
    log_message INFO "Checking for AUR helper..."
    
    if command -v yay >/dev/null
        log_message SUCCESS "yay found"
        return 0
    else if command -v paru >/dev/null
        log_message SUCCESS "paru found"
        return 0
    else
        if should_fix "No AUR helper found" "Install yay AUR helper"
            log_message INFO "Installing yay..."
            
            # Install base-devel if not present
            sudo pacman -S --needed --noconfirm base-devel git
            
            # Create temporary directory for yay installation
            set -l temp_dir (mktemp -d)
            cd $temp_dir
            
            if git clone https://aur.archlinux.org/yay.git
                cd yay
                if makepkg -si --noconfirm --needed
                    log_message SUCCESS "yay installed successfully"
                    cd /
                    rm -rf $temp_dir
                    return 0
                else
                    log_message ERROR "Failed to build yay"
                    cd /
                    rm -rf $temp_dir
                    return 1
                end
            else
                log_message ERROR "Failed to clone yay repository"
                cd /
                rm -rf $temp_dir
                return 1
            end
        else
            log_message ERROR "AUR helper required for Emby installation"
            return 1
        end
    end
end

# Hyprland compatibility setup
function setup_hyprland_compatibility
    log_message INFO "Setting up Hyprland compatibility..."
    
    # Check if Hyprland is running
    if not pgrep -x "Hyprland" >/dev/null
        log_message WARNING "Hyprland not currently running"
        if not confirm "Continue anyway?"
            return 1
        end
    end
    
    # Install required packages for Wayland/Hyprland compatibility
    set -l hyprland_packages xdg-desktop-portal-hyprland pipewire wireplumber
    log_message INFO "Installing Hyprland compatibility packages..."
    
    for package in $hyprland_packages
        if not pacman -Qi $package >/dev/null 2>&1
            log_message INFO "Installing $package..."
            if not sudo pacman -S --needed --noconfirm $package
                if should_fix "Failed to install $package" "Continue without $package"
                    log_message WARNING "Continuing without $package"
                else
                    return 1
                end
            end
        end
    end
    
    # Set up environment variables for Wayland compatibility
    set -l env_file "$HOME/.config/fish/conf.d/emby-hyprland.fish"
    
    if should_fix "Configure Wayland environment variables" "Create environment configuration"
        log_message INFO "Creating Wayland environment configuration..."
        
        mkdir -p (dirname $env_file)
        
        echo "# Emby Server Hyprland compatibility configuration" > $env_file
        echo "set -gx XDG_CURRENT_DESKTOP Hyprland" >> $env_file
        echo "set -gx XDG_SESSION_TYPE wayland" >> $env_file
        echo "set -gx XDG_SESSION_DESKTOP Hyprland" >> $env_file
        echo "set -gx ELECTRON_OZONE_PLATFORM_HINT auto" >> $env_file
        echo "set -gx GDK_BACKEND wayland" >> $env_file
        
        log_message SUCCESS "Wayland environment configuration created"
    end
    
    log_message SUCCESS "Hyprland compatibility setup completed"
    return 0
end

# Install Emby Server
function install_emby_server
    log_message INFO "Installing Emby Server..."
    
    # Check if already installed
    if pacman -Qi emby-server >/dev/null 2>&1
        log_message INFO "Emby Server already installed"
        if confirm "Reinstall Emby Server?"
            log_message INFO "Reinstalling Emby Server..."
        else
            return 0
        end
    end
    
    # Try official repository first
    log_message INFO "Attempting installation from official repository..."
    if sudo pacman -S --needed --noconfirm emby-server
        log_message SUCCESS "Emby Server installed from official repository"
        return 0
    else
        log_message WARNING "Official repository installation failed"
        
        if should_fix "Official package installation failed" "Try AUR package"
            log_message INFO "Attempting AUR installation..."
            
            # Determine AUR helper
            set -l aur_helper
            if command -v yay >/dev/null
                set aur_helper yay
            else if command -v paru >/dev/null
                set aur_helper paru
            else
                log_message ERROR "No AUR helper available"
                return 1
            end
            
            # Install from AUR
            if $aur_helper -S --needed --noconfirm emby-server
                log_message SUCCESS "Emby Server installed from AUR"
                return 0
            else
                log_message ERROR "AUR installation also failed"
                return 1
            end
        else
            log_message ERROR "Emby Server installation failed"
            return 1
        end
    end
end

# Configure Emby Server
function configure_emby_server
    log_message INFO "Configuring Emby Server..."
    
    # Create media directory
    if not test -d $MEDIA_DIR
        if should_fix "Media directory $MEDIA_DIR doesn't exist" "Create media directory"
            log_message INFO "Creating media directory: $MEDIA_DIR"
            if sudo mkdir -p $MEDIA_DIR
                sudo chown $USER:users $MEDIA_DIR
                sudo chmod 755 $MEDIA_DIR
                log_message SUCCESS "Media directory created"
            else
                log_message ERROR "Failed to create media directory"
                return 1
            end
        end
    end
    
    # Create backup directory
    if not test -d $BACKUP_DIR
        if should_fix "Backup directory $BACKUP_DIR doesn't exist" "Create backup directory"
            log_message INFO "Creating backup directory: $BACKUP_DIR"
            if sudo mkdir -p $BACKUP_DIR
                sudo chown $USER:users $BACKUP_DIR
                sudo chmod 755 $BACKUP_DIR
                log_message SUCCESS "Backup directory created"
            else
                log_message ERROR "Failed to create backup directory"
                return 1
            end
        end
    end
    
    # Set up media group permissions
    if should_fix "Configure media group permissions" "Set up proper permissions"
        log_message INFO "Setting up media group permissions..."
        
        # Create media group if it doesn't exist
        if not getent group media >/dev/null
            sudo groupadd media
        end
        
        # Add current user to media group
        sudo usermod -aG media $USER
        
        # Set permissions on media directory
        sudo chgrp -R media $MEDIA_DIR
        find $MEDIA_DIR -type d -exec sudo chmod 775 {} \;
        find $MEDIA_DIR -type f -exec sudo chmod 664 {} \;
        
        log_message SUCCESS "Media group permissions configured"
    end
    
    # Configure systemd service
    if should_fix "Configure Emby systemd service" "Set up service configuration"
        log_message INFO "Configuring Emby systemd service..."
        
        # Create service override directory
        sudo mkdir -p /etc/systemd/system/emby-server.service.d
        
        # Create override configuration
        set -l override_conf "/etc/systemd/system/emby-server.service.d/override.conf"
        
        echo "[Service]" | sudo tee $override_conf >/dev/null
        echo "SupplementaryGroups=media" | sudo tee -a $override_conf >/dev/null
        echo "ReadWritePaths=$MEDIA_DIR" | sudo tee -a $override_conf >/dev/null
        echo "UMask=0002" | sudo tee -a $override_conf >/dev/null
        
        # Reload systemd
        sudo systemctl daemon-reload
        
        log_message SUCCESS "Systemd service configured"
    end
    
    log_message SUCCESS "Emby Server configuration completed"
    return 0
end

# Check for port conflicts
function check_port_conflicts
    log_message INFO "Checking for port conflicts..."
    
    # Check if port 8096 is in use
    if netstat -tlnp 2>/dev/null | grep -q ":8096 "
        set -l process_info (netstat -tlnp 2>/dev/null | grep ":8096 " | head -1)
        log_message WARNING "Port 8096 is already in use:"
        echo "  $process_info"
        
        if should_fix "Port 8096 conflict detected" "Kill process using port 8096"
            set -l pid (echo $process_info | awk '{print $7}' | cut -d'/' -f1)
            if test -n "$pid" -a "$pid" != "-"
                log_message INFO "Killing process $pid..."
                if sudo kill $pid
                    sleep 2
                    log_message SUCCESS "Process killed"
                else
                    log_message ERROR "Failed to kill process"
                    return 1
                end
            else
                log_message WARNING "Could not identify process ID"
            end
        else
            return 1
        end
    end
    
    return 0
end

# Start and enable Emby Server
function start_emby_service
    log_message INFO "Starting and enabling Emby Server service..."
    
    # Check if service is already running
    if sudo systemctl is-active emby-server.service >/dev/null
        log_message INFO "Emby Server is already running"
        if confirm "Service is already active. Restart it?"
            log_message INFO "Restarting Emby Server..."
            sudo systemctl restart emby-server.service
            if test $status -eq 0
                log_message SUCCESS "Emby Server restarted successfully"
            else
                log_message ERROR "Failed to restart Emby Server"
                return 1
            end
        end
        return 0
    end
    
    # Check for port conflicts before starting
    if not check_port_conflicts
        log_message ERROR "Port conflict detected, cannot start service"
        return 1
    end
    
    # Enable service
    if sudo systemctl enable emby-server.service
        log_message SUCCESS "Emby Server service enabled"
    else
        log_message ERROR "Failed to enable Emby Server service"
        return 1
    end
    
    # Start service
    if sudo systemctl start emby-server.service
        log_message SUCCESS "Emby Server service started"
    else
        if should_fix "Failed to start Emby Server service" "Check service status and logs"
            log_message INFO "Service status:"
            sudo systemctl status emby-server.service
            log_message INFO "Recent logs:"
            sudo journalctl -u emby-server.service --no-pager -n 20
            
            if confirm "Try starting service again?"
                sudo systemctl start emby-server.service
                if test $status -eq 0
                    log_message SUCCESS "Service started successfully on retry"
                else
                    log_message ERROR "Service still failed to start"
                    return 1
                end
            else
                return 1
            end
        else
            return 1
        end
    end
    
    # Wait for service to be fully started
    log_message INFO "Waiting for service to fully start..."
    set -l attempts 0
    while test $attempts -lt 30
        if sudo systemctl is-active emby-server.service >/dev/null
            log_message SUCCESS "Emby Server is now running"
            return 0
        end
        sleep 1
        set attempts (math $attempts + 1)
    end
    
    log_message WARNING "Service may not be fully started yet"
    return 0
end

# Backup Emby data
function backup_emby_data
    log_message INFO "Starting Emby data backup..."
    
    if not test -d $EMBY_DATA_DIR
        log_message ERROR "Emby data directory not found: $EMBY_DATA_DIR"
        return 1
    end
    
    # Create timestamped backup directory
    set -l timestamp (date +%Y%m%d_%H%M%S)
    set -l backup_path "$BACKUP_DIR/emby_backup_$timestamp"
    
    if mkdir -p $backup_path
        log_message SUCCESS "Created backup directory: $backup_path"
    else
        log_message ERROR "Failed to create backup directory"
        return 1
    end
    
    # Stop Emby service before backup
    log_message INFO "Stopping Emby service for backup..."
    sudo systemctl stop emby-server.service
    
    # Backup essential directories
    set -l essential_dirs config data plugins root
    
    for dir in $essential_dirs
        if test -d "$EMBY_DATA_DIR/$dir"
            log_message INFO "Backing up $dir..."
            if cp -r "$EMBY_DATA_DIR/$dir" "$backup_path/"
                log_message SUCCESS "Backed up $dir"
            else
                log_message ERROR "Failed to backup $dir"
                # Restart service before returning
                sudo systemctl start emby-server.service
                return 1
            end
        else
            log_message WARNING "Directory not found: $EMBY_DATA_DIR/$dir"
        end
    end
    
    # Create backup metadata
    echo "Emby Server Backup" > "$backup_path/backup_info.txt"
    echo "Timestamp: $timestamp" >> "$backup_path/backup_info.txt"
    echo "Emby Version: "(pacman -Qi emby-server | grep Version | cut -d: -f2 | string trim) >> "$backup_path/backup_info.txt"
    echo "System: "(uname -a) >> "$backup_path/backup_info.txt"
    echo "User: $USER" >> "$backup_path/backup_info.txt"
    
    # Create compressed archive
    log_message INFO "Creating compressed archive..."
    if tar -czf "$backup_path.tar.gz" -C $BACKUP_DIR (basename $backup_path)
        log_message SUCCESS "Compressed backup created: $backup_path.tar.gz"
        rm -rf $backup_path
    else
        log_message WARNING "Failed to create compressed archive, keeping uncompressed backup"
    end
    
    # Restart Emby service
    log_message INFO "Restarting Emby service..."
    sudo systemctl start emby-server.service
    
    log_message SUCCESS "Backup completed successfully"
    return 0
end

# Restore Emby data
function restore_emby_data
    log_message INFO "Starting Emby data restore..."
    
    # Check if backup directory exists
    if not test -d $BACKUP_DIR
        log_message ERROR "Backup directory not found: $BACKUP_DIR"
        return 1
    end
    
    # List available backups
    log_message INFO "Available backups:"
    set -l backup_files
    for backup in (find $BACKUP_DIR -name "emby_backup_*.tar.gz" -o -name "emby_backup_*" -type d 2>/dev/null | sort)
        set backup_files $backup_files $backup
    end
    
    if test (count $backup_files) -eq 0
        log_message ERROR "No backups found in $BACKUP_DIR"
        return 1
    end
    
    # Display backup options
    set -l backup_index 1
    for backup in $backup_files
        echo "$backup_index) "(basename $backup)
        set backup_index (math $backup_index + 1)
    end
    
    # Get user selection
    while true
        read -P "Select backup to restore (1-"(count $backup_files)", or 0 to cancel): " -l choice
        if test $choice -eq 0
            log_message INFO "Restore cancelled by user"
            return 0
        else if test $choice -ge 1 -a $choice -le (count $backup_files)
            set -l selected_backup $backup_files[$choice]
            log_message INFO "Selected backup: "(basename $selected_backup)
            break
        else
            echo "Invalid selection. Please try again."
        end
    end
    
    # Confirm restore
    if not confirm "This will overwrite current Emby data. Continue?"
        log_message INFO "Restore cancelled by user"
        return 0
    end
    
    # Stop Emby service
    log_message INFO "Stopping Emby service..."
    sudo systemctl stop emby-server.service
    
    # Backup current data
    set -l current_backup "$BACKUP_DIR/emby_before_restore_"(date +%Y%m%d_%H%M%S)
    log_message INFO "Backing up current data to: $current_backup"
    if cp -r $EMBY_DATA_DIR $current_backup
        log_message SUCCESS "Current data backed up"
    else
        log_message ERROR "Failed to backup current data"
        sudo systemctl start emby-server.service
        return 1
    end
    
    # Clear existing data
    log_message INFO "Clearing existing Emby data..."
    sudo rm -rf "$EMBY_DATA_DIR"/*
    
    # Restore from backup
    log_message INFO "Restoring from backup..."
    if string match -q "*.tar.gz" $selected_backup
        # Extract compressed backup
        set -l temp_dir (mktemp -d)
        if tar -xzf $selected_backup -C $temp_dir
            if cp -r "$temp_dir"/*/* $EMBY_DATA_DIR
                log_message SUCCESS "Data restored from compressed backup"
                rm -rf $temp_dir
            else
                log_message ERROR "Failed to copy restored data"
                rm -rf $temp_dir
                return 1
            end
        else
            log_message ERROR "Failed to extract backup archive"
            return 1
        end
    else
        # Restore from uncompressed backup
        if cp -r "$selected_backup"/* $EMBY_DATA_DIR
            log_message SUCCESS "Data restored from uncompressed backup"
        else
            log_message ERROR "Failed to restore data"
            return 1
        end
    end
    
    # Fix permissions
    log_message INFO "Fixing permissions..."
    if sudo chown -R emby:emby $EMBY_DATA_DIR
        log_message SUCCESS "Permissions fixed"
    else
        log_message WARNING "Failed to fix some permissions"
    end
    
    # Restart Emby service
    log_message INFO "Starting Emby service..."
    if sudo systemctl start emby-server.service
        log_message SUCCESS "Emby service restarted"
    else
        log_message ERROR "Failed to start Emby service"
        return 1
    end
    
    log_message SUCCESS "Restore completed successfully"
    return 0
end

# Verify installation
function verify_installation
    log_message INFO "Verifying Emby Server installation..."
    
    # Check if service is running
    if sudo systemctl is-active emby-server.service >/dev/null
        log_message SUCCESS "Emby Server service is running"
    else
        log_message ERROR "Emby Server service is not running"
        return 1
    end
    
    # Check if service is enabled
    if sudo systemctl is-enabled emby-server.service >/dev/null
        log_message SUCCESS "Emby Server service is enabled"
    else
        log_message WARNING "Emby Server service is not enabled for autostart"
    end
    
    # Check if web interface is accessible
    log_message INFO "Checking web interface accessibility..."
    set -l attempts 0
    set -l max_attempts 10
    set -l interface_ready false
    
    while test $attempts -lt $max_attempts
        set -l http_code (curl -s -o /dev/null -w "%{http_code}" http://localhost:8096 2>/dev/null)
        if echo $http_code | grep -q "200\|302"
            set interface_ready true
            break
        end
        sleep 2
        set attempts (math $attempts + 1)
        log_message DEBUG "Attempt $attempts/$max_attempts: HTTP $http_code"
    end
    
    if test $interface_ready = true
        log_message SUCCESS "Web interface is accessible at http://localhost:8096"
    else
        log_message WARNING "Web interface not ready after $max_attempts attempts (HTTP $http_code)"
        log_message INFO "Try accessing http://localhost:8096 manually in a few minutes"
    end
    
    # Check media directory
    if test -d $MEDIA_DIR
        log_message SUCCESS "Media directory exists: $MEDIA_DIR"
    else
        log_message WARNING "Media directory not found: $MEDIA_DIR"
    end
    
    # Check backup directory
    if test -d $BACKUP_DIR
        log_message SUCCESS "Backup directory exists: $BACKUP_DIR"
    else
        log_message WARNING "Backup directory not found: $BACKUP_DIR"
    end
    
    log_message SUCCESS "Installation verification completed"
    return 0
end

# Main menu
function show_main_menu
    while true
        echo ""
        echo "=== $SCRIPT_NAME v$SCRIPT_VERSION ==="
        echo "1. Full Installation"
        echo "2. Backup Emby Data"
        echo "3. Restore Emby Data"
        echo "4. Verify Installation"
        echo "5. View Logs"
        echo "6. Service Management"
        echo "7. Emergency Cleanup"
        echo "8. Debug Mode Toggle"
        echo "0. Exit"
        echo ""
        
        read -P "Select an option: " -l choice
        
        switch $choice
            case 1
                full_installation
            case 2
                backup_emby_data
            case 3
                restore_emby_data
            case 4
                verify_installation
            case 5
                view_logs
            case 6
                service_management
            case 7
                cleanup_existing_installation
            case 8
                toggle_debug_mode
            case 0
                log_message INFO "Exiting $SCRIPT_NAME"
                exit 0
            case '*'
                echo "Invalid option. Please try again."
        end
    end
end

# Clean up any existing installations
function cleanup_existing_installation
    log_message INFO "Cleaning up any existing Emby installations..."
    
    # Stop service if running
    if sudo systemctl is-active emby-server.service >/dev/null
        log_message INFO "Stopping existing Emby service..."
        sudo systemctl stop emby-server.service
    end
    
    # Kill any processes using port 8096
    if netstat -tlnp 2>/dev/null | grep -q ":8096 "
        log_message INFO "Killing processes using port 8096..."
        set -l pids (netstat -tlnp 2>/dev/null | grep ":8096 " | awk '{print $7}' | cut -d'/' -f1 | grep -v '^-$')
        for pid in $pids
            if test -n "$pid"
                sudo kill $pid 2>/dev/null
            end
        end
        sleep 3
    end
    
    log_message SUCCESS "Cleanup completed"
    return 0
end

# Full installation process
function full_installation
    log_message INFO "Starting full Emby Server installation..."
    
    init_progress 9
    
    update_progress "Cleaning up existing installations"
    if not cleanup_existing_installation
        log_message ERROR "Cleanup failed"
        return 1
    end
    
    update_progress "Checking system requirements"
    if not check_system_requirements
        log_message ERROR "System requirements check failed"
        return 1
    end
    
    update_progress "Checking dependencies"
    if not check_dependencies
        log_message ERROR "Dependency check failed"
        return 1
    end
    
    update_progress "Ensuring AUR helper is available"
    if not ensure_aur_helper
        log_message ERROR "AUR helper setup failed"
        return 1
    end
    
    update_progress "Setting up Hyprland compatibility"
    if not setup_hyprland_compatibility
        log_message ERROR "Hyprland compatibility setup failed"
        return 1
    end
    
    update_progress "Installing Emby Server"
    if not install_emby_server
        log_message ERROR "Emby Server installation failed"
        return 1
    end
    
    update_progress "Configuring Emby Server"
    if not configure_emby_server
        log_message ERROR "Emby Server configuration failed"
        return 1
    end
    
    update_progress "Starting Emby service"
    if not start_emby_service
        log_message ERROR "Emby service startup failed"
        return 1
    end
    
    update_progress "Verifying installation"
    if not verify_installation
        log_message WARNING "Installation verification had issues"
    end
    
    log_message SUCCESS "Full installation completed successfully!"
    echo ""
    echo "=== Installation Complete ==="
    echo "• Emby Server is now running"
    echo "• Web interface: http://localhost:8096"
    echo "• Media directory: $MEDIA_DIR"
    echo "• Backup directory: $BACKUP_DIR"
    echo "• Log file: $LOG_FILE"
    echo ""
    echo "Next steps:"
    echo "1. Open http://localhost:8096 in your browser"
    echo "2. Complete the initial setup wizard"
    echo "3. Add your media libraries"
    echo "4. Configure users and permissions"
    echo ""
end

# Service management submenu
function service_management
    while true
        echo ""
        echo "=== Service Management ==="
        echo "1. Start Emby Server"
        echo "2. Stop Emby Server"
        echo "3. Restart Emby Server"
        echo "4. Enable Emby Server (autostart)"
        echo "5. Disable Emby Server (no autostart)"
        echo "6. View Service Status"
        echo "7. View Service Logs"
        echo "0. Back to Main Menu"
        echo ""
        
        read -P "Select an option: " -l choice
        
        switch $choice
            case 1
                log_message INFO "Starting Emby Server..."
                sudo systemctl start emby-server.service
            case 2
                log_message INFO "Stopping Emby Server..."
                sudo systemctl stop emby-server.service
            case 3
                log_message INFO "Restarting Emby Server..."
                sudo systemctl restart emby-server.service
            case 4
                log_message INFO "Enabling Emby Server for autostart..."
                sudo systemctl enable emby-server.service
            case 5
                log_message INFO "Disabling Emby Server autostart..."
                sudo systemctl disable emby-server.service
            case 6
                echo ""
                sudo systemctl status emby-server.service
            case 7
                echo ""
                sudo journalctl -u emby-server.service --no-pager -n 50
            case 0
                return 0
            case '*'
                echo "Invalid option. Please try again."
        end
    end
end

# View logs
function view_logs
    echo ""
    echo "=== Script Logs ==="
    echo "Log file: $LOG_FILE"
    echo ""
    
    if test -f $LOG_FILE
        tail -n 50 $LOG_FILE
    else
        echo "No log file found."
    end
    
    echo ""
    read -P "Press Enter to continue..."
end

# Toggle debug mode
function toggle_debug_mode
    if test $DEBUG_MODE -eq 0
        set -g DEBUG_MODE 1
        log_message INFO "Debug mode enabled"
    else
        set -g DEBUG_MODE 0
        log_message INFO "Debug mode disabled"
    end
end

# Cleanup function
function cleanup
    log_message INFO "Cleaning up temporary files..."
    # Add cleanup code here if needed
    set_color normal
end

# Signal handling
function handle_interrupt
    log_message WARNING "Script interrupted by user"
    cleanup
    exit 130
end

# Main execution
function main
    # Set up signal handling
    trap handle_interrupt INT TERM
    
    # Create log file
    touch $LOG_FILE
    
    # Display welcome message
    echo ""
    echo "======================================"
    echo "   $SCRIPT_NAME v$SCRIPT_VERSION"  
    echo "======================================"
    echo ""
    echo "This script will help you:"
    echo "• Install Emby Server on Arch Linux"
    echo "• Configure it for Hyprland compatibility"
    echo "• Set up media directories"
    echo "• Manage backups and restores"
    echo ""
    echo "Log file: $LOG_FILE"
    echo ""
    
    if confirm "Continue with $SCRIPT_NAME?"
        show_main_menu
    else
        log_message INFO "Script cancelled by user"
        exit 0
    end
end

# Run main function
main