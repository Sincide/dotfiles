#!/bin/bash
# Configuration Testing Script for NixOS Migration
# Validates configuration files before installation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_DIR="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$(dirname "$MIGRATION_DIR")"

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test function wrapper
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    ((TESTS_TOTAL++))
    
    log_info "Testing: $test_name"
    
    if $test_func; then
        log_success "✓ $test_name"
        ((TESTS_PASSED++))
    else
        log_error "✗ $test_name"
        ((TESTS_FAILED++))
    fi
    echo
}

# Test if we're in the right directory
test_directory_structure() {
    local required_dirs=(
        "$MIGRATION_DIR/system"
        "$MIGRATION_DIR/home"
        "$MIGRATION_DIR/overlays"
        "$MIGRATION_DIR/themes"
        "$MIGRATION_DIR/docs"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_error "Missing directory: $dir"
            return 1
        fi
    done
    
    local required_files=(
        "$MIGRATION_DIR/flake.nix"
        "$MIGRATION_DIR/system/configuration.nix"
        "$MIGRATION_DIR/home/home.nix"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Missing file: $file"
            return 1
        fi
    done
    
    return 0
}

# Test flake syntax
test_flake_syntax() {
    cd "$MIGRATION_DIR"
    
    if command -v nix &> /dev/null; then
        # Check flake syntax
        if nix flake check --no-build 2>/dev/null; then
            return 0
        else
            log_error "Flake syntax errors found"
            return 1
        fi
    else
        log_warning "Nix not available, skipping flake syntax check"
        return 0
    fi
}

# Test system configuration syntax
test_system_config() {
    local config_file="$MIGRATION_DIR/system/configuration.nix"
    
    # Basic syntax check
    if ! grep -q "{ config, pkgs, inputs, ... }:" "$config_file"; then
        log_error "System config missing proper function signature"
        return 1
    fi
    
    # Check for required sections
    local required_sections=(
        "imports"
        "environment.systemPackages"
        "users.users"
        "system.stateVersion"
    )
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "$section" "$config_file"; then
            log_error "System config missing section: $section"
            return 1
        fi
    done
    
    return 0
}

# Test home manager configuration
test_home_config() {
    local config_file="$MIGRATION_DIR/home/home.nix"
    
    # Basic syntax check
    if ! grep -q "{ config, pkgs, inputs, ... }:" "$config_file"; then
        log_error "Home config missing proper function signature"
        return 1
    fi
    
    # Check for required sections
    local required_sections=(
        "home.username"
        "home.homeDirectory"
        "home.stateVersion"
        "programs.home-manager.enable"
    )
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "$section" "$config_file"; then
            log_error "Home config missing section: $section"
            return 1
        fi
    done
    
    return 0
}

# Test overlay files
test_overlays() {
    local overlay_dir="$MIGRATION_DIR/overlays"
    
    # Check overlay files exist
    local overlays=(
        "matugen.nix"
        "cursor-bin.nix"
        "custom-packages.nix"
    )
    
    for overlay in "${overlays[@]}"; do
        if [[ ! -f "$overlay_dir/$overlay" ]]; then
            log_error "Missing overlay: $overlay"
            return 1
        fi
        
        # Basic syntax check
        if ! grep -q "self: super:" "$overlay_dir/$overlay"; then
            log_error "Invalid overlay syntax in: $overlay"
            return 1
        fi
    done
    
    return 0
}

# Test theme configurations
test_themes() {
    local theme_dir="$MIGRATION_DIR/themes"
    
    # Check theme directories
    local themes=(
        "space"
        "nature"
    )
    
    for theme in "${themes[@]}"; do
        local theme_file="$theme_dir/$theme/default.nix"
        
        if [[ ! -f "$theme_file" ]]; then
            log_error "Missing theme file: $theme_file"
            return 1
        fi
        
        # Check theme has required sections
        local required_theme_sections=(
            "colors"
            "hyprland"
            "waybar"
            "gtk3"
            "kitty"
        )
        
        for section in "${required_theme_sections[@]}"; do
            if ! grep -q "$section" "$theme_file"; then
                log_error "Theme $theme missing section: $section"
                return 1
            fi
        done
    done
    
    return 0
}

# Test module structure
test_modules() {
    local home_modules_dir="$MIGRATION_DIR/home/modules"
    
    # Check module directories exist
    local modules=(
        "packages"
        "hyprland"
        "waybar"
        "services"
        "theming"
        "fish"
    )
    
    for module in "${modules[@]}"; do
        if [[ ! -d "$home_modules_dir/$module" ]]; then
            log_error "Missing module directory: $module"
            return 1
        fi
        
        # Check for default.nix or module-specific files
        if [[ ! -f "$home_modules_dir/$module/default.nix" ]] && [[ ! -f "$home_modules_dir/$module"/*.nix ]]; then
            log_error "Module $module has no .nix files"
            return 1
        fi
    done
    
    return 0
}

# Test package references
test_package_references() {
    local packages_dir="$MIGRATION_DIR/home/modules/packages"
    
    # Check package files exist
    local package_files=(
        "default.nix"
        "essential.nix"
        "development.nix"
        "theming.nix"
        "multimedia.nix"
        "gaming.nix"
        "optional.nix"
    )
    
    for pkg_file in "${package_files[@]}"; do
        if [[ ! -f "$packages_dir/$pkg_file" ]]; then
            log_error "Missing package file: $pkg_file"
            return 1
        fi
    done
    
    # Check for common package syntax issues
    if grep -r "pkgs\." "$packages_dir" | grep -q "pkgs\.pkgs\."; then
        log_error "Found double pkgs reference in package files"
        return 1
    fi
    
    return 0
}

# Test script permissions
test_script_permissions() {
    local scripts_dir="$MIGRATION_DIR/scripts"
    
    # Check scripts are executable
    local scripts=(
        "install.sh"
    )
    
    for script in "${scripts[@]}"; do
        local script_path="$scripts_dir/$script"
        
        if [[ ! -f "$script_path" ]]; then
            log_error "Missing script: $script"
            return 1
        fi
        
        if [[ ! -x "$script_path" ]]; then
            log_error "Script not executable: $script"
            return 1
        fi
    done
    
    return 0
}

# Test documentation
test_documentation() {
    local docs_dir="$MIGRATION_DIR/docs"
    
    # Check documentation files exist
    local docs=(
        "README.md"
        "MIGRATION_GUIDE.md"
        "PACKAGE_MAPPING.md"
        "TROUBLESHOOTING.md"
        "VM_TESTING_GUIDE.md"
        "FRESH_INSTALLATION_GUIDE.md"
    )
    
    for doc in "${docs[@]}"; do
        if [[ ! -f "$docs_dir/$doc" ]]; then
            log_error "Missing documentation: $doc"
            return 1
        fi
        
        # Check file is not empty
        if [[ ! -s "$docs_dir/$doc" ]]; then
            log_error "Empty documentation file: $doc"
            return 1
        fi
    done
    
    return 0
}

# Test for common configuration errors
test_common_errors() {
    # Check for placeholder values that need updating
    local config_errors=0
    
    # Check for placeholder email
    if grep -r "your.email@example.com" "$MIGRATION_DIR/home" >/dev/null 2>&1; then
        log_warning "Found placeholder email address - update before installation"
        ((config_errors++))
    fi
    
    # Check for placeholder repository URL
    if grep -r "yourusername/dotfiles" "$MIGRATION_DIR" >/dev/null 2>&1; then
        log_warning "Found placeholder repository URL - update before installation"
        ((config_errors++))
    fi
    
    # Check for placeholder hashes
    if grep -r "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" "$MIGRATION_DIR/overlays" >/dev/null 2>&1; then
        log_warning "Found placeholder hashes in overlays - update after first build"
        ((config_errors++))
    fi
    
    # Check for invalid paths
    if grep -r "/home/martin" "$MIGRATION_DIR/system" >/dev/null 2>&1; then
        log_error "Found hardcoded user paths in system config"
        return 1
    fi
    
    if [[ $config_errors -gt 0 ]]; then
        log_warning "Found $config_errors configuration warnings (not errors)"
    fi
    
    return 0
}

# Main testing function
main() {
    log_info "🧪 Starting NixOS Migration Configuration Tests"
    echo
    
    # Run all tests
    run_test "Directory Structure" test_directory_structure
    run_test "Flake Syntax" test_flake_syntax
    run_test "System Configuration" test_system_config
    run_test "Home Manager Configuration" test_home_config
    run_test "Package Overlays" test_overlays
    run_test "Theme Configurations" test_themes
    run_test "Module Structure" test_modules
    run_test "Package References" test_package_references
    run_test "Script Permissions" test_script_permissions
    run_test "Documentation" test_documentation
    run_test "Common Configuration Errors" test_common_errors
    
    # Print summary
    echo "=================== TEST SUMMARY ==================="
    log_info "Tests Total: $TESTS_TOTAL"
    log_success "Tests Passed: $TESTS_PASSED"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Tests Failed: $TESTS_FAILED"
        echo
        log_error "❌ Configuration validation FAILED"
        log_error "Please fix the errors above before proceeding with installation."
        exit 1
    else
        log_success "Tests Failed: $TESTS_FAILED"
        echo
        log_success "✅ All tests PASSED!"
        log_success "Configuration is ready for installation."
        echo
        log_info "Next steps:"
        echo "  1. Test in VM first: docs/VM_TESTING_GUIDE.md"
        echo "  2. Fresh installation: docs/FRESH_INSTALLATION_GUIDE.md"
        echo "  3. Update placeholder values if any warnings above"
        exit 0
    fi
}

# Help function
show_help() {
    echo "NixOS Migration Configuration Tester"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo
    echo "This script validates your NixOS migration configuration"
    echo "before attempting installation in VM or bare metal."
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main "$@"