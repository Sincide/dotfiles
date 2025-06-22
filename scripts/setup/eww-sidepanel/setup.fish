#!/usr/bin/env fish
# EWW Sidepanel Setup Script for Hyprland (Fish Shell) - FINAL FIXED

# Colors for output
set RED '\033[0;31m'
set GREEN '\033[0;32m'
set YELLOW '\033[1;33m'
set BLUE '\033[0;34m'
set NC '\033[0m'

# Print colored output functions
function print_status
    echo -e $BLUE"[INFO]"$NC" $argv"
end

function print_success
    echo -e $GREEN"[SUCCESS]"$NC" $argv"
end

function print_warning
    echo -e $YELLOW"[WARNING]"$NC" $argv"
end

function print_error
    echo -e $RED"[ERROR]"$NC" $argv"
end

# Check if running on a supported system
function check_system
    print_status "Checking system compatibility..."
    
    if not command -v hyprctl >/dev/null 2>&1
        print_error "Hyprland not detected. This setup is designed for Hyprland."
        exit 1
    end
    
    print_success "Hyprland detected"
end

# Check and install dependencies
function install_dependencies
    print_status "Checking dependencies..."
    
    set missing_deps
    set deps eww playerctl brightnessctl bc jq curl ddcutil
    
    for dep in $deps
        if not command -v $dep >/dev/null 2>&1
            set missing_deps $missing_deps $dep
        end
    end
    
    if test (count $missing_deps) -gt 0
        print_warning "Missing dependencies: $missing_deps"
        
        if command -v pacman >/dev/null 2>&1
            print_status "Arch Linux detected. Install with:"
            echo "sudo pacman -S $missing_deps"
        else if command -v apt >/dev/null 2>&1
            print_status "Debian/Ubuntu detected. Install with:"
            echo "sudo apt install $missing_deps"
        end
        
        read -P "Do you want to continue with setup? (y/N): " -n 1 response
        echo
        if not string match -qi "y*" $response
            exit 1
        end
    else
        print_success "All dependencies are installed"
    end
end

# Create directory structure
function create_directories
    print_status "Creating directory structure..."
    
    set eww_dir $HOME/.config/eww
    set scripts_dir $eww_dir/scripts
    
    mkdir -p $scripts_dir
    print_success "Created directories: $eww_dir"
end

# Copy configuration files
function copy_files
    print_status "Copying configuration files..."
    
    set eww_dir $HOME/.config/eww
    set scripts_dir $eww_dir/scripts
    
    # Check if files exist in current directory
    if not test -f eww.yuck
        print_error "eww.yuck not found in current directory"
        print_error "Make sure you're running this script from the directory containing the EWW files"
        exit 1
    end
    
    # Copy main configuration files
    cp eww.yuck $eww_dir/
    cp eww.scss $eww_dir/
    
    # Copy scripts (only copy files that exist)
    if test -d scripts
        for script_file in scripts/*.fish
            if test -f $script_file
                cp $script_file $scripts_dir/
            end
        end
        for script_file in scripts/*.sh
            if test -f $script_file
                cp $script_file $scripts_dir/
            end
        end
    end
    
    # Make scripts executable
    chmod +x $scripts_dir/* 2>/dev/null
    
    print_success "Configuration files copied successfully"
end

# Create toggle script
function create_toggle_script
    print_status "Creating toggle script..."
    
    set eww_dir $HOME/.config/eww
    set toggle_script $eww_dir/toggle_sidebar.fish
    
    echo '#!/usr/bin/env fish
# Toggle EWW sidebar script

# Check if sidebar is open
if eww active-windows | grep -q "sidebar_window"
    eww close sidebar_window
else
    eww open sidebar_window
end' > $toggle_script
    
    chmod +x $toggle_script
    print_success "Created toggle script: $toggle_script"
end

# Setup Hyprland keybinds
function setup_keybinds
    print_status "Setting up Hyprland keybinds..."
    
    set hypr_config $HOME/.config/hypr/hyprland.conf
    
    if not test -f $hypr_config
        print_warning "Hyprland config not found at $hypr_config"
        print_status "Add this keybind manually:"
        echo "bind = SUPER, F10, exec, ~/.config/eww/toggle_sidebar.fish"
        return
    end
    
    # Check if keybind already exists
    if grep -q "eww.*sidebar" $hypr_config
        print_warning "EWW sidebar keybind already exists in Hyprland config"
        return
    end
    
    # Add keybind to toggle sidebar
    echo "" >> $hypr_config
    echo "# EWW Sidebar keybind" >> $hypr_config
    echo "bind = SUPER, F10, exec, ~/.config/eww/toggle_sidebar.fish" >> $hypr_config
    
    print_success "Added keybind: SUPER + F10 to toggle sidebar"
end

# Test the configuration
function test_config
    print_status "Testing EWW configuration..."
    
    if not eww ping >/dev/null 2>&1
        print_status "Starting EWW daemon..."
        eww daemon &
        sleep 3
    end
    
    # Test configuration syntax
    if eww reload >/dev/null 2>&1
        print_success "EWW configuration is valid"
        return 0
    else
        print_error "EWW configuration has errors"
        print_error "Run 'eww logs' to see detailed error messages"
        return 1
    end
end

# Display usage instructions
function show_usage
    print_success "Setup completed successfully!"
    echo
    echo -e $BLUE"Usage Instructions:"$NC
    echo "1. Press SUPER + F10 to toggle the sidebar"
    echo "2. Or run manually: ~/.config/eww/toggle_sidebar.fish"
    echo "3. To start EWW daemon: eww daemon"
    echo "4. To reload configuration: eww reload"
    echo
    print_status "Enjoy your new EWW sidebar!"
end

# Main execution
function main
    echo -e $BLUE"=== EWW Sidepanel Setup for Hyprland (Fish Shell) ==="$NC
    echo
    
    check_system
    install_dependencies
    create_directories
    copy_files
    create_toggle_script
    setup_keybinds
    
    if test_config
        show_usage
    else
        print_error "Setup completed with configuration errors"
        print_error "Check the fixes below and run: eww logs"
        return 1
    end
end

# Run main function
main $argv