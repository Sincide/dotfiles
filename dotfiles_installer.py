#!/usr/bin/env python3
"""
Arch Linux Dotfiles Installer
A beautiful Python replacement for the bash installation script.
"""

import os
import sys
import subprocess
import shutil
import time
import json
import logging
import tempfile
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime
from contextlib import contextmanager


@dataclass
class InstallationState:
    """Track what components need installation."""
    needs_packages: bool = False
    needs_configs: bool = False
    needs_ai_scripts: bool = False
    needs_ai_system: bool = False
    needs_fish: bool = False
    needs_vm: bool = False
    needs_wallpaper: bool = False
    needs_fstab: bool = False
    missing_packages: List[str] = None
    ai_missing_count: int = 0

    def __post_init__(self):
        if self.missing_packages is None:
            self.missing_packages = []


class Colors:
    """ANSI color codes for beautiful terminal output."""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    BLUE = '\033[0;34m'
    YELLOW = '\033[1;33m'
    MAGENTA = '\033[1;35m'
    CYAN = '\033[1;36m'
    BOLD = '\033[1m'
    RESET = '\033[0m'


class ProgressBar:
    """Beautiful progress bar with spinner and ETA."""
    
    SPINNER_CHARS = ['|', '/', '-', '\\']
    
    def __init__(self, total: int, width: int = 30):
        self.total = total
        self.width = width
        self.current = 0
        self.start_time = time.time()
    
    def update(self, current: int, description: str = ""):
        """Update progress bar with current progress."""
        self.current = current
        percent = (100 * current // self.total) if self.total > 0 else 0
        filled = (self.width * current // self.total) if self.total > 0 else 0
        empty = self.width - filled
        
        bar = '#' * filled + '-' * empty
        spinner = self.SPINNER_CHARS[current % 4]
        
        # Calculate ETA
        elapsed = time.time() - self.start_time
        if current > 0:
            eta_seconds = int((elapsed / current) * (self.total - current))
            eta = f"{eta_seconds // 60:02d}:{eta_seconds % 60:02d}"
        else:
            eta = "--:--"
        
        # Clear line and print progress
        print(f"\r{' ' * 120}\r", end='', flush=True)
        print(f"    [{bar}] {percent:3d}% ({current}/{self.total}) {spinner} "
              f"ETA: {eta} | {description}", end='', flush=True)
    
    def finish(self):
        """Complete the progress bar."""
        print()


class UI:
    """Beautiful terminal UI utilities."""
    
    @staticmethod
    def print_message(msg: str, color: str = Colors.BLUE):
        """Print a styled message."""
        print(f"{color}==>{Colors.RESET} {msg}")
    
    @staticmethod
    def print_error(msg: str):
        """Print an error message."""
        print(f"{Colors.RED}Error:{Colors.RESET} {msg}")
    
    @staticmethod
    def print_warning(msg: str):
        """Print a warning message."""
        print(f"{Colors.YELLOW}Warning:{Colors.RESET} {msg}")
    
    @staticmethod
    def print_success(msg: str):
        """Print a success message."""
        print(f"{Colors.GREEN}Success:{Colors.RESET} {msg}")
    
    @staticmethod
    def print_step(msg: str):
        """Print a major step header."""
        print(f"\n{Colors.BOLD}{Colors.MAGENTA}==>{Colors.RESET} {Colors.BOLD}{msg}{Colors.RESET}")
    
    @staticmethod
    def print_substep(msg: str):
        """Print a substep."""
        print(f"{Colors.CYAN}  ->{Colors.RESET} {msg}")
    
    @staticmethod
    def print_progress(msg: str):
        """Print progress information."""
        print(f"{Colors.BLUE}    Progress:{Colors.RESET} {msg}")
    
    @staticmethod
    def confirm(question: str) -> bool:
        """Ask for user confirmation."""
        while True:
            response = input(f"{question} [y/N]: ").lower().strip()
            if response in ['y', 'yes']:
                return True
            elif response in ['n', 'no', '']:
                return False
            else:
                print("Please answer 'y' or 'n'")
    
    @staticmethod
    def choose(question: str, options: List[str]) -> str:
        """Present multiple choice question."""
        print(f"\n{question}")
        for i, option in enumerate(options, 1):
            print(f"  {i}. {option}")
        
        while True:
            try:
                choice = int(input("Enter your choice: ")) - 1
                if 0 <= choice < len(options):
                    return options[choice]
                else:
                    print("Invalid choice. Please try again.")
            except ValueError:
                print("Please enter a number.")
    
    @staticmethod
    def spinner(message: str, duration: float = 0.1):
        """Show a brief spinner animation."""
        for char in ProgressBar.SPINNER_CHARS:
            print(f"\r{message} {char}", end='', flush=True)
            time.sleep(duration / 4)
        print(f"\r{message} ✓")


class DotfilesInstaller:
    """Main installer class for Arch Linux dotfiles."""
    
    def __init__(self):
        self.dotfiles_dir = Path.cwd()
        self.log_file = self.dotfiles_dir / "install.log"
        self.state = InstallationState()
        self.sudo_cached = False
        self.sudo_pid = None
        
        # Package definitions
        self.CORE_PACKAGES = [
            "hyprland", "hyprpaper", "waybar", "kitty", "fish", "fuzzel", "dunst",
            "polkit-gnome", "xdg-desktop-portal-hyprland", "xdg-desktop-portal-gtk",
            "qt5-wayland", "qt6-wayland", "pipewire", "wireplumber", "pavucontrol",
            "pamixer", "playerctl", "grim", "slurp", "wl-clipboard", "swappy",
            "cliphist", "catppuccin-gtk-theme-mocha", "ttf-jetbrains-mono-nerd",
            "noto-fonts", "noto-fonts-cjk", "noto-fonts-emoji", "papirus-icon-theme",
            "thunar", "thunar-volman", "thunar-archive-plugin", "xdg-utils",
            "xdg-user-dirs", "network-manager-applet", "blueman", "jq", "bc",
            "gnupg", "exa", "ripgrep", "fzf", "lm_sensors", "wlsunset", "light",
            "zoxide", "gum", "nwg-look", "qt5ct", "qt6ct", "kvantum", "waypaper",
            "matugen", "ollama", "nano", "firefox-developer-edition", "unzip",
            "zip", "p7zip", "python", "python-pip", "go", "python-rich"
        ]
        
        self.LF_PACKAGES = [
            "lf", "bat", "file", "mediainfo", "chafa", "atool", 
            "ffmpegthumbnailer", "poppler"
        ]
        
        self.OPTIONAL_PACKAGES = [
            "brightnessctl", "vulkan-radeon", "lib32-vulkan-radeon",
            "libva-mesa-driver", "lib32-libva-mesa-driver", "mesa-vdpau",
            "lib32-mesa-vdpau", "radeontop", "ddcutil"
        ]
        
        self.setup_logging()
    
    def setup_logging(self):
        """Configure logging to file."""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        logging.info("Install log started")
    
    def run_command(self, cmd: List[str], check: bool = True, 
                   capture_output: bool = False) -> subprocess.CompletedProcess:
        """Run a command with proper logging."""
        cmd_str = ' '.join(cmd)
        logging.info(f"Running: {cmd_str}")
        
        try:
            result = subprocess.run(
                cmd, 
                check=check, 
                capture_output=capture_output,
                text=True
            )
            if capture_output:
                logging.info(f"Command output: {result.stdout}")
            return result
        except subprocess.CalledProcessError as e:
            logging.error(f"Command failed: {cmd_str}, Error: {e}")
            if capture_output and e.stdout:
                logging.error(f"Stdout: {e.stdout}")
            if capture_output and e.stderr:
                logging.error(f"Stderr: {e.stderr}")
            raise
    
    def check_sudo(self) -> bool:
        """Check and cache sudo privileges."""
        UI.print_step("Checking sudo privileges")
        try:
            self.run_command(['sudo', '-v'])
            self.sudo_cached = True
            UI.print_success("Sudo privileges cached")
            return True
        except subprocess.CalledProcessError:
            UI.print_error("Failed to get sudo privileges")
            return False
    
    def handle_error(self, error_msg: str) -> bool:
        """Handle errors with user interaction."""
        UI.print_error(error_msg)
        
        options = [
            "Continue anyway (ignore this error)",
            "Retry the last operation", 
            "Open debug shell (for manual fixing)",
            "View install log",
            "Abort installation"
        ]
        
        choice = UI.choose("❌ An error occurred. What would you like to do?", options)
        
        if choice == options[0]:  # Continue
            UI.print_warning("Continuing despite error...")
            return True
        elif choice == options[1]:  # Retry
            UI.print_message("Retrying operation...")
            return False  # Caller should retry
        elif choice == options[2]:  # Debug shell
            UI.print_message("Opening debug shell. Type 'exit' when done.")
            UI.print_message(f"Current directory: {os.getcwd()}")
            UI.print_message(f"Error was: {error_msg}")
            os.system('bash')
            UI.print_message("Continuing after debug session...")
            return True
        elif choice == options[3]:  # View log
            self.show_log_tail()
            return self.handle_error(error_msg)  # Ask again
        else:  # Abort
            UI.print_error("Installation aborted by user.")
            sys.exit(1)
    
    def show_log_tail(self, lines: int = 50):
        """Show last N lines of log file."""
        if self.log_file.exists():
            UI.print_message(f"Last {lines} lines of install log:")
            with open(self.log_file, 'r') as f:
                tail_lines = f.readlines()[-lines:]
                for line in tail_lines:
                    print(line.rstrip())
        else:
            UI.print_message("No log file found")
    
    def command_exists(self, command: str) -> bool:
        """Check if a command exists."""
        return shutil.which(command) is not None
    
    def package_installed(self, package: str) -> bool:
        """Check if a package is installed."""
        try:
            self.run_command(['yay', '-Q', package], capture_output=True)
            return True
        except subprocess.CalledProcessError:
            return False
    
    def install_yay(self):
        """Install yay AUR helper if not present."""
        if self.command_exists('yay'):
            UI.print_message("yay is already installed")
            return
        
        UI.print_step("Installing yay-bin (AUR helper)")
        
        # Clean up any existing installation
        yay_dir = Path('/tmp/yay-bin')
        if yay_dir.exists():
            UI.print_warning("Removing existing yay-bin directory")
            shutil.rmtree(yay_dir)
        
        try:
            UI.print_substep("Cloning yay-bin repository...")
            self.run_command([
                'git', 'clone', 
                'https://aur.archlinux.org/yay-bin.git', 
                str(yay_dir)
            ])
            
            UI.print_substep("Building and installing yay-bin...")
            os.chdir(yay_dir)
            self.run_command(['makepkg', '-si', '--noconfirm'])
            os.chdir(self.dotfiles_dir)
            
            shutil.rmtree(yay_dir)
            UI.print_success("yay-bin installed successfully")
            
        except subprocess.CalledProcessError as e:
            os.chdir(self.dotfiles_dir)  # Ensure we're back in dotfiles dir
            if not self.handle_error(f"Failed to install yay-bin: {e}"):
                self.install_yay()  # Retry
    
    def get_missing_packages(self) -> List[str]:
        """Get list of missing packages."""
        all_packages = self.CORE_PACKAGES + self.LF_PACKAGES + self.OPTIONAL_PACKAGES
        missing = []
        
        UI.print_substep("Checking for missing packages...")
        UI.spinner("Scanning installed packages...")
        
        for package in all_packages:
            if not self.package_installed(package):
                missing.append(package)
        
        return missing
    
    def install_packages(self):
        """Install missing packages with progress tracking."""
        missing_packages = self.get_missing_packages()
        
        if not missing_packages:
            UI.print_success("All required packages are already installed")
            return
        
        UI.print_message(f"Found {len(missing_packages)} packages to install")
        
        # Update system
        UI.print_substep("Updating system and refreshing package database...")
        try:
            UI.spinner("Updating system packages...")
            self.run_command(['sudo', 'pacman', '-Syu', '--noconfirm'])
            
            UI.spinner("Refreshing package database...")
            self.run_command(['yay', '-Syy', '--noconfirm'])
        except subprocess.CalledProcessError:
            UI.print_warning("Failed to update system - continuing anyway")
        
        # Install packages with progress bar
        UI.print_substep("Installing packages...")
        progress = ProgressBar(len(missing_packages))
        
        installed = []
        failed = []
        
        for i, package in enumerate(missing_packages):
            progress.update(i, f"Installing: {package}")
            
            try:
                self.run_command([
                    'yay', '-S', '--needed', '--noconfirm',
                    '--answerclean', 'None', '--answerdiff', 'None',
                    '--answeredit', 'None', '--mflags', '--noconfirm',
                    package
                ])
                installed.append(package)
            except subprocess.CalledProcessError:
                failed.append(package)
                UI.print_warning(f"Failed to install {package}")
        
        progress.update(len(missing_packages), "Complete")
        progress.finish()
        
        # Print summary
        UI.print_step("Installation Summary")
        if installed:
            UI.print_success(f"Successfully installed {len(installed)} packages:")
            for pkg in sorted(installed):
                print(f"  - {pkg}")
        
        if failed:
            UI.print_error(f"Failed to install {len(failed)} packages:")
            for pkg in sorted(failed):
                print(f"  - {pkg}")
            UI.print_warning("Some packages failed - this may cause missing functionality")
    
    def backup_configs(self):
        """Backup existing configurations."""
        UI.print_step("Backing up existing configurations")
        
        config_dir = Path.home() / '.config'
        backup_dir = Path.home() / f'.config-backup-{datetime.now().strftime("%Y%m%d-%H%M%S")}'
        
        if not config_dir.exists():
            UI.print_message("No existing config directory found")
            return
        
        backup_dir.mkdir(exist_ok=True)
        UI.print_substep(f"Creating backup in {backup_dir}")
        
        dirs_to_backup = ['hypr', 'waybar', 'kitty', 'fish', 'dunst', 'fuzzel', 'lf']
        progress = ProgressBar(len(dirs_to_backup))
        
        for i, dir_name in enumerate(dirs_to_backup):
            source_dir = config_dir / dir_name
            if source_dir.exists():
                progress.update(i, f"Backing up {dir_name}")
                try:
                    shutil.copytree(source_dir, backup_dir / dir_name)
                except Exception as e:
                    UI.print_warning(f"Failed to backup {dir_name}: {e}")
            progress.update(i + 1, dir_name)
        
        progress.finish()
        UI.print_success(f"Configurations backed up to {backup_dir}")
        
        # Rotate old backups
        self.rotate_backups()
    
    def rotate_backups(self):
        """Remove old backup directories, keeping only the latest 5."""
        UI.print_substep("Rotating old backups...")
        
        home = Path.home()
        backup_dirs = list(home.glob('.config-backup-*'))
        
        # Sort by modification time and remove all but the 5 newest
        backup_dirs.sort(key=lambda p: p.stat().st_mtime, reverse=True)
        
        for old_backup in backup_dirs[5:]:
            try:
                shutil.rmtree(old_backup)
            except Exception as e:
                UI.print_warning(f"Failed to remove old backup {old_backup}: {e}")
        
        UI.print_success("Old backups cleaned up")
    
    def verify_symlink(self, source: Path, target: Path) -> bool:
        """Verify that a symlink is correct."""
        if not target.is_symlink():
            return False
        return target.readlink() == source
    
    def create_symlinks(self):
        """Create configuration symlinks."""
        UI.print_step("Creating configuration symlinks")
        
        config_dirs = list((self.dotfiles_dir / 'config').glob('*'))
        progress = ProgressBar(len(config_dirs))
        
        for i, source_dir in enumerate(config_dirs):
            if not source_dir.is_dir():
                continue
                
            dir_name = source_dir.name
            progress.update(i, f"Setting up {dir_name}")
            
            if dir_name == "applications":
                self.setup_application_shortcuts(source_dir)
            else:
                self.setup_config_symlink(source_dir, dir_name)
            
            progress.update(i + 1, dir_name)
        
        progress.finish()
        UI.print_success("Symlink setup completed")
    
    def setup_application_shortcuts(self, source_dir: Path):
        """Set up application shortcuts."""
        UI.print_substep("Setting up application shortcuts...")
        
        apps_dir = Path.home() / '.local/share/applications'
        apps_dir.mkdir(parents=True, exist_ok=True)
        
        for app_file in source_dir.glob('*'):
            if app_file.is_file():
                target = apps_dir / app_file.name
                source_abs = self.dotfiles_dir / app_file.relative_to(self.dotfiles_dir)
                
                if target.is_symlink() and target.readlink() == source_abs:
                    UI.print_progress(f"Shortcut for {app_file.name} already correct")
                else:
                    if target.exists():
                        target.unlink()
                    target.symlink_to(source_abs)
                    if not self.verify_symlink(source_abs, target):
                        UI.print_warning(f"Failed to verify symlink for {app_file.name}")
    
    def setup_config_symlink(self, source_dir: Path, dir_name: str):
        """Set up a configuration directory symlink."""
        UI.print_substep(f"Setting up {dir_name} configuration...")
        
        target_dir = Path.home() / '.config' / dir_name
        source_abs = self.dotfiles_dir / source_dir.relative_to(self.dotfiles_dir)
        
        if target_dir.is_symlink() and target_dir.readlink() == source_abs:
            UI.print_progress(f"{dir_name} configuration already symlinked correctly")
            return
        
        if target_dir.exists():
            # Check if it's a small default config that can be replaced
            try:
                total_size = sum(f.stat().st_size for f in target_dir.rglob('*') if f.is_file())
                if total_size < 50000:  # Less than 50KB
                    UI.print_progress(f"Replacing default {dir_name} configuration...")
                    shutil.rmtree(target_dir)
                else:
                    UI.print_warning(f"{dir_name} configuration exists and seems customized. Skipping.")
                    return
            except Exception:
                UI.print_warning(f"Could not analyze {dir_name} directory size. Skipping.")
                return
        
        target_dir.parent.mkdir(parents=True, exist_ok=True)
        target_dir.symlink_to(source_abs)
        
        if not self.verify_symlink(source_abs, target_dir):
            UI.print_warning(f"Failed to verify symlink for {dir_name}")
    
    def setup_ai_scripts(self):
        """Set up AI scripts for system-wide access."""
        UI.print_step("Setting up AI scripts accessibility")
        
        # Create ~/.local/bin
        local_bin = Path.home() / '.local/bin'
        local_bin.mkdir(parents=True, exist_ok=True)
        
        # Symlink ai-config script
        ai_config_source = self.dotfiles_dir / 'scripts/ai/ai-config.sh'
        ai_config_target = local_bin / 'ai-config'
        
        if ai_config_source.exists():
            UI.print_substep("Making ai-config accessible system-wide...")
            if ai_config_target.is_symlink() and ai_config_target.readlink() == ai_config_source:
                UI.print_progress("ai-config already symlinked correctly")
            else:
                if ai_config_target.exists():
                    ai_config_target.unlink()
                ai_config_target.symlink_to(ai_config_source)
                if self.verify_symlink(ai_config_source, ai_config_target):
                    UI.print_success("ai-config command available system-wide")
                else:
                    UI.print_warning("Failed to verify ai-config symlink")
        
        # Create AI scripts directory symlink
        UI.print_substep("Creating AI scripts directory symlink...")
        ai_scripts_source = self.dotfiles_dir / 'scripts/ai'
        ai_scripts_target = Path.home() / '.config/dynamic-theming/scripts'
        
        if ai_scripts_source.exists():
            ai_scripts_target.parent.mkdir(parents=True, exist_ok=True)
            if ai_scripts_target.is_symlink() and ai_scripts_target.readlink() == ai_scripts_source:
                UI.print_progress("AI scripts directory already symlinked correctly")
            else:
                if ai_scripts_target.exists():
                    if ai_scripts_target.is_symlink():
                        ai_scripts_target.unlink()
                    else:
                        shutil.rmtree(ai_scripts_target)
                ai_scripts_target.symlink_to(ai_scripts_source)
                if self.verify_symlink(ai_scripts_source, ai_scripts_target):
                    UI.print_success("AI scripts directory accessible")
                else:
                    UI.print_warning("Failed to verify AI scripts directory symlink")
        
        UI.print_success("AI scripts accessibility setup completed")
    
    def set_permissions(self):
        """Set script permissions."""
        UI.print_step("Setting script permissions")
        
        # LF scripts
        lf_config = Path.home() / '.config/lf'
        for script in ['preview.sh', 'cleaner.sh']:
            script_path = lf_config / script
            if script_path.exists():
                script_path.chmod(0o755)
        
        # Hyprland scripts
        hypr_scripts = Path.home() / '.config/hypr/scripts'
        if hypr_scripts.exists():
            for script in hypr_scripts.glob('*.sh'):
                script.chmod(0o755)
        
        # Waybar scripts
        waybar_scripts = Path.home() / '.config/waybar/scripts'
        if waybar_scripts.exists():
            for script in waybar_scripts.glob('*.sh'):
                script.chmod(0o755)
        
        # AI scripts
        ai_scripts = self.dotfiles_dir / 'scripts/ai'
        if ai_scripts.exists():
            for script in ai_scripts.glob('*.sh'):
                script.chmod(0o755)
        
        UI.print_success("All permissions set")
    
    def setup_ai_system(self):
        """Set up AI-Enhanced Dynamic Theming System."""
        UI.print_step("Setting up AI-Enhanced Dynamic Theming System")
        
        # Create directories
        ai_config_dir = Path.home() / '.config/dynamic-theming'
        ai_config_dir.mkdir(parents=True, exist_ok=True)
        
        matugen_cache = Path.home() / '.cache/matugen'
        matugen_cache.mkdir(parents=True, exist_ok=True)
        
        # Initialize AI configuration
        ai_config_file = ai_config_dir / 'ai-config.conf'
        if not ai_config_file.exists():
            ai_config_script = Path.home() / '.local/bin/ai-config'
            if ai_config_script.exists():
                try:
                    self.run_command(['bash', str(ai_config_script), 'init'])
                    UI.print_success("AI configuration initialized")
                except subprocess.CalledProcessError:
                    UI.print_warning("Failed to initialize AI config")
        
        # Set up Ollama models if available
        if self.command_exists('ollama'):
            self.setup_ollama_models()
        else:
            UI.print_warning("Ollama not found - AI features will be limited")
        
        # Build AI Dashboard
        self.build_ai_dashboard()
        
        UI.print_success("AI system setup completed")
    
    def wait_for_ollama_service(self, max_attempts: int = 30) -> bool:
        """Wait for Ollama service to be ready."""
        UI.print_substep("Waiting for ollama service to be ready...")
        
        for attempt in range(max_attempts):
            try:
                self.run_command(['ollama', 'list'], capture_output=True)
                UI.print_success("Ollama service is ready")
                return True
            except subprocess.CalledProcessError:
                if attempt == 0:
                    UI.print_progress("Starting ollama service...")
                    # Try to start service
                    try:
                        subprocess.Popen(['ollama', 'serve'], 
                                       stdout=subprocess.DEVNULL, 
                                       stderr=subprocess.DEVNULL)
                    except Exception:
                        pass
                
                print(".", end='', flush=True)
                time.sleep(2)
        
        print()
        UI.print_error(f"Ollama service failed to start after {max_attempts} attempts")
        return False
    
    def download_ollama_model(self, model: str, display_name: str, max_retries: int = 3) -> bool:
        """Download an Ollama model with retries."""
        UI.print_substep(f"Setting up {display_name} model...")
        
        # Check if model already exists
        try:
            result = self.run_command(['ollama', 'list'], capture_output=True)
            if model in result.stdout:
                UI.print_message(f"{display_name} model already installed")
                return True
        except subprocess.CalledProcessError:
            pass
        
        for retry in range(1, max_retries + 1):
            if retry > 1:
                UI.print_progress(f"Retry {retry}/{max_retries}: Downloading {display_name} model...")
            else:
                UI.print_progress(f"Downloading {display_name} model (this may take several minutes)...")
            
            try:
                # Use timeout to prevent hanging
                self.run_command(['timeout', '1800', 'ollama', 'pull', model])
                UI.print_success(f"{display_name} model installed successfully")
                return True
            except subprocess.CalledProcessError as e:
                UI.print_warning(f"Attempt {retry} failed")
                if retry < max_retries:
                    UI.print_progress("Waiting 5 seconds before retry...")
                    time.sleep(5)
        
        UI.print_error(f"Failed to download {display_name} model after {max_retries} attempts")
        return False
    
    def setup_ollama_models(self):
        """Set up required Ollama models."""
        if not self.wait_for_ollama_service():
            UI.print_warning("Ollama service not available - skipping model setup")
            return
        
        # Download models
        models = [
            ("llava-llama3:8b", "LLAVA-Llama3 vision"),
            ("phi4", "Phi4 text")
        ]
        
        for model, display_name in models:
            self.download_ollama_model(model, display_name)
    
    def build_ai_dashboard(self):
        """Build the AI Performance Dashboard."""
        UI.print_substep("Building AI Performance Dashboard...")
        
        if not self.command_exists('go'):
            UI.print_warning("Go not installed - AI dashboard will not be built")
            return
        
        dashboard_dir = self.dotfiles_dir / 'scripts/ai'
        dashboard_source = dashboard_dir / 'dashboard.go'
        
        if not dashboard_source.exists():
            UI.print_warning("AI dashboard source not found")
            return
        
        original_cwd = os.getcwd()
        try:
            os.chdir(dashboard_dir)
            
            # Initialize Go module if needed
            if not (dashboard_dir / 'go.mod').exists():
                UI.print_progress("Initializing Go module...")
                self.run_command(['go', 'mod', 'init', 'ai-dashboard'])
                self.run_command(['go', 'mod', 'tidy'])
            
            # Build dashboard
            UI.print_progress("Compiling Go dashboard...")
            self.run_command(['go', 'build', '-o', 'dashboard', 'dashboard.go'])
            (dashboard_dir / 'dashboard').chmod(0o755)
            UI.print_success("AI Performance Dashboard built successfully")
            
        except subprocess.CalledProcessError:
            UI.print_warning("Failed to build AI dashboard")
        finally:
            os.chdir(original_cwd)
    
    def configure_defaults(self):
        """Configure default applications."""
        UI.print_step("Configuring default applications")
        
        # Set default terminal
        UI.print_substep("Setting default terminal...")
        try:
            self.run_command(['xdg-mime', 'default', 'kitty.desktop', 'x-scheme-handler/terminal'])
            self.run_command(['xdg-mime', 'default', 'kitty.desktop', 'application/x-terminal-emulator'])
        except subprocess.CalledProcessError:
            UI.print_warning("Failed to set default terminal")
        
        # Update XDG directories
        UI.print_substep("Updating XDG user directories...")
        try:
            self.run_command(['xdg-user-dirs-update'])
        except subprocess.CalledProcessError:
            UI.print_warning("Failed to update XDG user directories")
        
        # Create Screenshots directory
        screenshots_dir = Path.home() / 'Pictures/Screenshots'
        screenshots_dir.mkdir(parents=True, exist_ok=True)
        
        UI.print_success("Default applications configured")
    
    def set_fish_shell(self):
        """Set fish as the default shell."""
        UI.print_step("Setting up fish shell")
        
        fish_path = shutil.which('fish')
        current_shell = os.environ.get('SHELL', '')
        
        if current_shell != fish_path:
            UI.print_substep("Changing default shell to fish...")
            try:
                self.run_command(['chsh', '-s', fish_path])
                UI.print_success("Default shell changed to fish")
            except subprocess.CalledProcessError:
                UI.print_warning("Could not change default shell")
        else:
            UI.print_message("Fish is already the default shell")
        
        # Ensure ~/.local/bin is in fish PATH
        fish_config = Path.home() / '.config/fish/config.fish'
        if fish_config.exists():
            with open(fish_config, 'r') as f:
                content = f.read()
            
            if 'set -gx PATH.*\.local/bin' not in content:
                with open(fish_config, 'a') as f:
                    f.write('\nset -gx PATH $HOME/.local/bin $PATH\n')
                UI.print_success("Added ~/.local/bin to fish PATH")
            else:
                UI.print_message("~/.local/bin already in fish PATH")
    
    def set_hyprpaper_conf(self):
        """Set up wallpaper configuration."""
        UI.print_step("Setting up wallpaper configuration")
        
        config_path = Path.home() / '.config/hypr/hyprpaper.conf'
        wallpaper = self.dotfiles_dir / 'assets/wallpapers/evilpuccin.png'
        
        config_content = f"""preload = {wallpaper}
wallpaper = DP-3,{wallpaper}
wallpaper = DP-1,{wallpaper}
wallpaper = HDMI-A-1,{wallpaper}
splash = false
"""
        
        with open(config_path, 'w') as f:
            f.write(config_content)
        
        UI.print_success("hyprpaper.conf generated")
    
    def preflight_check(self) -> InstallationState:
        """Analyze current system state and determine what needs installation."""
        UI.print_step("Analyzing current system state")
        
        state = InstallationState()
        
        # Check packages
        UI.print_substep("Checking installed packages...")
        missing_packages = self.get_missing_packages()
        if missing_packages:
            state.needs_packages = True
            state.missing_packages = missing_packages
        
        # Check configurations
        UI.print_substep("Checking configuration symlinks...")
        state.needs_configs = self.check_config_symlinks()
        
        # Check AI scripts
        UI.print_substep("Checking AI script accessibility...")
        state.needs_ai_scripts = self.check_ai_scripts()
        
        # Check AI system
        UI.print_substep("Checking AI system setup...")
        state.needs_ai_system, state.ai_missing_count = self.check_ai_system()
        
        # Check fish shell
        UI.print_substep("Checking shell configuration...")
        fish_path = shutil.which('fish')
        current_shell = os.environ.get('SHELL', '')
        fish_config = Path.home() / '.config/fish/config.fish'
        state.needs_fish = (current_shell != fish_path or not fish_config.exists())
        
        # Check wallpaper
        UI.print_substep("Checking wallpaper configuration...")
        hyprpaper_conf = Path.home() / '.config/hypr/hyprpaper.conf'
        if hyprpaper_conf.exists():
            with open(hyprpaper_conf, 'r') as f:
                content = f.read()
            state.needs_wallpaper = 'dotfiles/assets/wallpapers' not in content
        else:
            state.needs_wallpaper = True
        
        return state
    
    def check_config_symlinks(self) -> bool:
        """Check if configuration symlinks need setup."""
        for config_dir in (self.dotfiles_dir / 'config').glob('*'):
            if not config_dir.is_dir():
                continue
                
            dir_name = config_dir.name
            if dir_name == "applications":
                # Check application shortcuts
                for app_file in config_dir.glob('*'):
                    if app_file.is_file():
                        target = Path.home() / '.local/share/applications' / app_file.name
                        source_abs = self.dotfiles_dir / app_file.relative_to(self.dotfiles_dir)
                        if not target.is_symlink() or target.readlink() != source_abs:
                            return True
            else:
                # Check config directory symlink
                target_dir = Path.home() / '.config' / dir_name
                source_abs = self.dotfiles_dir / config_dir.relative_to(self.dotfiles_dir)
                if not target_dir.is_symlink() or target_dir.readlink() != source_abs:
                    return True
        
        return False
    
    def check_ai_scripts(self) -> bool:
        """Check if AI scripts need setup."""
        ai_config_target = Path.home() / '.local/bin/ai-config'
        ai_config_source = self.dotfiles_dir / 'scripts/ai/ai-config.sh'
        
        if not ai_config_target.is_symlink() or ai_config_target.readlink() != ai_config_source:
            return True
        
        ai_scripts_target = Path.home() / '.config/dynamic-theming/scripts'
        ai_scripts_source = self.dotfiles_dir / 'scripts/ai'
        
        if not ai_scripts_target.is_symlink() or ai_scripts_target.readlink() != ai_scripts_source:
            return True
        
        return False
    
    def check_ai_system(self) -> Tuple[bool, int]:
        """Check AI system components."""
        missing_count = 0
        
        # Check AI config file
        ai_config_file = Path.home() / '.config/dynamic-theming/ai-config.conf'
        if not ai_config_file.exists():
            missing_count += 1
        
        # Check matugen cache directory
        matugen_cache = Path.home() / '.cache/matugen'
        if not matugen_cache.exists():
            missing_count += 1
        
        # Check Ollama and models
        if self.command_exists('ollama'):
            try:
                result = self.run_command(['ollama', 'list'], capture_output=True)
                if 'llava' not in result.stdout:
                    missing_count += 1
                if 'phi4' not in result.stdout:
                    missing_count += 1
            except subprocess.CalledProcessError:
                missing_count += 1
        else:
            missing_count += 1
        
        return missing_count > 0, missing_count
    
    def print_system_analysis(self, state: InstallationState):
        """Print the results of system analysis."""
        print()
        UI.print_step("System Analysis Results")
        
        if not any([state.needs_packages, state.needs_configs, state.needs_ai_scripts, 
                   state.needs_ai_system, state.needs_fish, state.needs_wallpaper]):
            UI.print_success("✅ System appears to be fully configured!")
            UI.print_message("All packages installed, configurations symlinked, AI system ready.")
            return False  # No installation needed
        
        UI.print_message("📋 Steps needed on this system:")
        
        if state.needs_packages:
            UI.print_substep(f"📦 Package Installation: {len(state.missing_packages)} packages need to be installed")
        else:
            UI.print_substep("✅ Packages: All required packages already installed")
        
        if state.needs_configs:
            UI.print_substep("🔗 Configuration Symlinks: Some config symlinks need to be created/updated")
        else:
            UI.print_substep("✅ Configurations: All symlinks properly configured")
        
        if state.needs_ai_scripts:
            UI.print_substep("🧠 AI Script Access: ai-config command needs to be set up system-wide")
        else:
            UI.print_substep("✅ AI Scripts: System-wide access already configured")
        
        if state.needs_ai_system:
            UI.print_substep(f"🤖 AI System Setup: {state.ai_missing_count} AI components need configuration")
        else:
            UI.print_substep("✅ AI System: All AI components properly configured")
        
        if state.needs_fish:
            UI.print_substep("🐚 Fish Shell: Shell configuration needs setup")
        else:
            UI.print_substep("✅ Fish Shell: Already configured as default shell")
        
        if state.needs_wallpaper:
            UI.print_substep("🖼️ Wallpaper Setup: hyprpaper.conf needs to be generated")
        else:
            UI.print_substep("✅ Wallpaper Setup: hyprpaper.conf already configured")
        
        print()
        return True  # Installation needed
    
    def print_final_instructions(self):
        """Print final setup instructions."""
        print()
        UI.print_step("🎉 Installation Complete!")
        
        print()
        UI.print_step("GTK and Qt Theming Recommendations")
        UI.print_message("For GTK theming, use the GUI tool nwg-look (Wayland-native, works with Hyprland).")
        UI.print_message("For Qt theming, use qt5ct, qt6ct, and Kvantum.")
        
        print()
        UI.print_step("AI-Enhanced Dynamic Theming System + Firefox Web Theming")
        UI.print_message("🧠 Your system now includes AI-enhanced desktop + web theming!")
        UI.print_message("  Press Super+B to select wallpapers → Desktop + Firefox themes update together")
        UI.print_message("  AI analyzes content and optimizes colors for perfect harmony")
        UI.print_message("  Configure AI settings: ai-config config")
        UI.print_message("  Check AI status: ai-config status")
        UI.print_message("See AI_COMPLETE_ECOSYSTEM_GUIDE.md for complete documentation.")
        
        print()
        if UI.confirm("Some changes might require a system restart. Reboot now?"):
            UI.print_message("Rebooting system...")
            subprocess.run(['systemctl', 'reboot'])
    
    def run(self):
        """Main installation workflow."""
        # Check if running as root
        if os.geteuid() == 0:
            UI.print_error("Please do not run as root")
            sys.exit(1)
        
        # Welcome message
        print(f"{Colors.BOLD}{Colors.MAGENTA}")
        print("=" * 60)
        print("    Arch Linux Dotfiles Installer")
        print("=" * 60)
        print(f"{Colors.RESET}")
        
        UI.print_message("This script will set up your system with the provided dotfiles.")
        UI.print_message("Safe to re-run: Only missing components will be installed/configured.")
        
        # Check prerequisites
        if not self.check_sudo():
            sys.exit(1)
        
        # Check required commands
        for cmd in ['git', 'make', 'gcc']:
            if not self.command_exists(cmd):
                UI.print_error(f"Required command '{cmd}' not found. Please install it first.")
                sys.exit(1)
        
        # Check Wayland session
        if os.environ.get('XDG_SESSION_TYPE') != 'wayland':
            UI.print_warning("Not running in a Wayland session. Some features may not work until you log into Wayland.")
        
        # Analyze system and determine what needs to be done
        self.state = self.preflight_check()
        
        if not self.print_system_analysis(self.state):
            UI.print_message("You can still run the installer to verify components.")
            if not UI.confirm("Everything looks good. Run full verification anyway?"):
                UI.print_message("Installation skipped.")
                return
        
        # Install components based on what's needed
        if self.state.needs_packages and UI.confirm("Install missing packages?"):
            self.install_yay()
            self.install_packages()
        
        if (self.state.needs_configs or self.state.needs_ai_scripts) and \
           UI.confirm("Backup existing configs and create symlinks?"):
            if self.state.needs_configs:
                self.backup_configs()
                self.create_symlinks()
            if self.state.needs_ai_scripts:
                self.setup_ai_scripts()
        
        if self.state.needs_wallpaper and UI.confirm("Set up wallpaper configuration?"):
            self.set_hyprpaper_conf()
        
        # Always set permissions and configure defaults
        self.set_permissions()
        self.configure_defaults()
        
        if self.state.needs_ai_system and UI.confirm("Set up missing AI system components?"):
            self.setup_ai_system()
        
        if self.state.needs_fish and UI.confirm("Set fish as your default shell?"):
            self.set_fish_shell()
        
        # Final instructions
        self.print_final_instructions()


if __name__ == "__main__":
    try:
        installer = DotfilesInstaller()
        installer.run()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Installation interrupted by user.{Colors.RESET}")
        sys.exit(1)
    except Exception as e:
        print(f"\n{Colors.RED}Unexpected error: {e}{Colors.RESET}")
        logging.exception("Unexpected error during installation")
        sys.exit(1)
