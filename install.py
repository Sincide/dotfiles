#!/usr/bin/env python3
"""
Beautiful Python installer for Arch Linux Dotfiles
Replicates install.sh functionality with enhanced UI using the Rich library
"""

import os
import sys
import subprocess
import shutil
import time
import pwd
import grp
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from datetime import datetime
import json
import tempfile
import concurrent.futures

# Rich imports for beautiful UI
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeRemainingColumn
from rich.prompt import Confirm, Prompt
from rich.panel import Panel
from rich.table import Table
from rich.tree import Tree
from rich.text import Text
from rich.columns import Columns
from rich.align import Align
from rich.layout import Layout
from rich import box
from rich.live import Live
from rich.spinner import Spinner

console = Console()

class DotfilesInstaller:
    def __init__(self):
        self.dotfiles_dir = Path.cwd()
        self.home_dir = Path.home()
        self.config_dir = self.home_dir / ".config"
        self.log_file = self.dotfiles_dir / "install_python.log"
        
        # Installation state tracking
        self.installed_packages = []
        self.failed_packages = []
        self.skip_flags = {
            'packages': False,
            'configs': False,
            'ai_scripts': False,
            'ai_system': False,
            'fish': False,
            'vm': False,
            'wallpaper': False,
            'fstab': False
        }
        
        # Package lists
        self.core_packages = [
            "hyprland", "hyprpaper", "waybar", "kitty", "fish", "fuzzel", "dunst",
            "polkit-gnome", "xdg-desktop-portal-hyprland", "xdg-desktop-portal-gtk",
            "qt5-wayland", "qt6-wayland", "pipewire", "wireplumber", "pavucontrol",
            "pamixer", "playerctl", "grim", "slurp", "wl-clipboard", "swappy", "cliphist",
            "catppuccin-gtk-theme-mocha", "ttf-jetbrains-mono-nerd", "noto-fonts",
            "noto-fonts-cjk", "noto-fonts-emoji", "papirus-icon-theme", "thunar",
            "thunar-volman", "thunar-archive-plugin", "xdg-utils", "xdg-user-dirs",
            "network-manager-applet", "blueman", "jq", "bc", "gnupg", "exa", "ripgrep",
            "fzf", "lm_sensors", "wlsunset", "light", "zoxide", "gum", "nwg-look",
            "qt5ct", "qt6ct", "kvantum", "waypaper", "matugen", "ollama", "nano",
            "firefox-developer-edition", "unzip", "zip", "p7zip", "python", "python-pip",
            "go", "python-rich"
        ]
        
        self.lf_packages = [
            "lf", "bat", "file", "mediainfo", "chafa", "atool", "ffmpegthumbnailer", "poppler"
        ]
        
        self.optional_packages = [
            "brightnessctl", "vulkan-radeon", "lib32-vulkan-radeon", "libva-mesa-driver",
            "lib32-libva-mesa-driver", "mesa-vdpau", "lib32-mesa-vdpau", "radeontop", "ddcutil"
        ]
        
        self.all_packages = self.core_packages + self.lf_packages + self.optional_packages

    def log(self, message: str, level: str = "INFO"):
        """Log message to file"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(self.log_file, "a") as f:
            f.write(f"[{timestamp}] {level}: {message}\n")

    def run_command(self, cmd: List[str], check: bool = True, capture: bool = False, interactive: bool = False, quiet: bool = False) -> subprocess.CompletedProcess:
        """Run a command with logging"""
        cmd_str = " ".join(cmd)
        self.log(f"Running command: {cmd_str}")
        
        try:
            if capture:
                result = subprocess.run(cmd, check=check, capture_output=True, text=True)
            elif quiet:
                # Suppress output but allow password input by redirecting only stdout/stderr
                with open(self.log_file, "a") as log:
                    result = subprocess.run(cmd, check=check, stdout=log, stderr=log)
            elif interactive or (len(cmd) > 0 and cmd[0] == "sudo"):
                # For sudo and interactive commands, allow terminal input/output
                result = subprocess.run(cmd, check=check)
            else:
                result = subprocess.run(cmd, check=check)
            self.log(f"Command completed with return code: {result.returncode}")
            return result
        except subprocess.CalledProcessError as e:
            self.log(f"Command failed: {e}", "ERROR")
            if check:
                raise
            return e

    def show_welcome(self):
        """Display welcome screen"""
        welcome_panel = Panel(
            "[bold cyan]🚀 Arch Linux Dotfiles Installer[/bold cyan]\n\n"
            "[green]✨ Beautiful Python version with Rich UI ✨[/green]\n\n"
            "This installer will set up your system with:\n"
            "• [blue]Hyprland desktop environment[/blue]\n"
            "• [magenta]AI-powered dynamic theming[/magenta]\n"
            "• [yellow]Firefox web theming extension[/yellow]\n"
            "• [green]Complete development environment[/green]\n\n"
            "[dim]Safe to re-run: Only missing components will be installed[/dim]",
            title="[bold]Welcome[/bold]",
            border_style="cyan"
        )
        console.print(welcome_panel)

    def check_requirements(self):
        """Check system requirements"""
        with console.status("[yellow]Checking system requirements...", spinner="dots"):
            errors = []
            
            # Check if running as root
            if os.geteuid() == 0:
                errors.append("Please do not run as root")
            
            # Check for required commands
            required_commands = ["git", "make", "gcc", "pacman"]
            for cmd in required_commands:
                if not shutil.which(cmd):
                    errors.append(f"Required command '{cmd}' not found")
            
            # Check Wayland session
            if os.environ.get("XDG_SESSION_TYPE") != "wayland":
                console.print("[yellow]⚠️  Not running in Wayland session. Some features may not work until you log into Wayland.[/yellow]")
            
            if errors:
                for error in errors:
                    console.print(f"[red]❌ {error}[/red]")
                sys.exit(1)
            
            console.print("[green]✅ System requirements check passed[/green]")

    def check_sudo(self):
        """Check and cache sudo privileges"""
        try:
            with console.status("[yellow]Checking sudo privileges...", spinner="dots"):
                self.run_command(["sudo", "-v"])
            console.print("[green]✅ Sudo privileges cached[/green]")
            
            # Start background process to keep sudo alive (like the bash script does)
            self.start_sudo_keepalive()
            
        except subprocess.CalledProcessError:
            console.print("[red]❌ Failed to get sudo privileges[/red]")
            sys.exit(1)

    def start_sudo_keepalive(self):
        """Start background process to keep sudo privileges alive"""
        def keepalive():
            import threading
            import time
            def refresh_sudo():
                while True:
                    try:
                        subprocess.run(["sudo", "-n", "true"], check=False, 
                                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                        time.sleep(60)  # Refresh every minute
                    except:
                        break
            
            thread = threading.Thread(target=refresh_sudo, daemon=True)
            thread.start()
        
        keepalive()

    def install_yay(self):
        """Install yay AUR helper if not present"""
        if shutil.which("yay"):
            console.print("[green]✅ yay is already installed[/green]")
            return
        
        console.print("[blue]📦 Installing yay AUR helper...[/blue]")
        
        try:
            # Clean up any existing yay-bin directory
            yay_dir = Path("/tmp/yay-bin")
            if yay_dir.exists():
                shutil.rmtree(yay_dir)
            
            # Clone, build, and install - just like the bash script
            self.run_command(["git", "clone", "https://aur.archlinux.org/yay-bin.git", "/tmp/yay-bin"])
            
            # Save current directory and change to yay-bin
            original_dir = os.getcwd()
            os.chdir("/tmp/yay-bin")
            
            try:
                # Build and install in one go - simple and effective
                with console.status("[yellow]Building and installing yay...", spinner="dots"):
                    self.run_command(["makepkg", "-si", "--noconfirm"], quiet=True)
                console.print("[green]✅ yay installed successfully[/green]")
            finally:
                # Always return to original directory
                os.chdir(original_dir)
                # Clean up
                if yay_dir.exists():
                    shutil.rmtree(yay_dir)
            
        except Exception as e:
            console.print(f"[red]❌ Failed to install yay: {e}[/red]")
            console.print("[yellow]💡 You can install yay manually and re-run this installer[/yellow]")
            raise

    def run_yay(self, args: List[str]) -> subprocess.CompletedProcess:
        """Run yay with non-interactive flags"""
        cmd = ["yay", "--answerclean", "None", "--answerdiff", "None", "--answeredit", "None", "--mflags", "--noconfirm"] + args
        return self.run_command(cmd, check=False, interactive=True)

    def check_missing_packages(self) -> List[str]:
        """Check for missing packages"""
        missing = []
        
        # If yay is not installed, we can't check AUR packages yet
        # We'll assume most packages are missing and let the install process handle it
        if not shutil.which("yay"):
            console.print("[yellow]⚠️  yay not found - will install it first, then check packages[/yellow]")
            return self.all_packages  # Assume all packages need checking after yay install
        
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
            transient=True,
        ) as progress:
            task = progress.add_task("Scanning installed packages...", total=len(self.all_packages))
            
            for package in self.all_packages:
                result = self.run_command(["yay", "-Q", package], check=False, capture=True)
                if result.returncode != 0:
                    missing.append(package)
                progress.advance(task)
        
        return missing

    def install_packages(self, missing_packages: List[str]):
        """Install missing packages with beautiful progress bar"""
        if not missing_packages:
            console.print("[green]✅ All packages already installed[/green]")
            return

        console.print(f"[blue]📦 Installing {len(missing_packages)} packages...[/blue]")
        
        # Update system first
        with console.status("[yellow]Updating system packages...", spinner="dots"):
            self.run_command(["sudo", "pacman", "-Syu", "--noconfirm"], quiet=True)

        # Install packages with progress tracking
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
            TextColumn("({task.completed}/{task.total})"),
            TimeRemainingColumn(),
        ) as progress:
            
            task = progress.add_task("Installing packages...", total=len(missing_packages))
            
            for i, package in enumerate(missing_packages):
                progress.update(task, description=f"Installing [cyan]{package}[/cyan]...")
                
                # Run package installation quietly to reduce screen clutter
                result = self.run_command(["yay", "-S", "--needed", "--noconfirm", 
                                         "--answerclean", "None", "--answerdiff", "None", 
                                         "--answeredit", "None", package], 
                                         check=False, quiet=True)
                
                if result.returncode == 0:
                    self.installed_packages.append(package)
                    progress.update(task, description=f"✅ Installed [green]{package}[/green]")
                else:
                    self.failed_packages.append(package)
                    progress.update(task, description=f"❌ Failed [red]{package}[/red]")
                
                progress.advance(task)
                time.sleep(0.2)  # Slightly longer delay to show the status
        
        # Show installation summary
        self.show_package_summary()

    def show_package_summary(self):
        """Show package installation summary"""
        table = Table(title="📦 Package Installation Summary", box=box.ROUNDED)
        table.add_column("Status", style="bold", width=12)
        table.add_column("Count", justify="right", width=8)
        table.add_column("Packages", width=60)
        
        if self.installed_packages:
            table.add_row(
                "[green]✅ Installed[/green]", 
                str(len(self.installed_packages)),
                ", ".join(self.installed_packages[:10]) + ("..." if len(self.installed_packages) > 10 else "")
            )
        
        if self.failed_packages:
            table.add_row(
                "[red]❌ Failed[/red]", 
                str(len(self.failed_packages)),
                ", ".join(self.failed_packages)
            )
        
        console.print(table)

    def backup_configs(self):
        """Backup existing configurations"""
        backup_dir = self.home_dir / f".config-backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        
        if not self.config_dir.exists():
            console.print("[yellow]⚠️  No existing config directory found[/yellow]")
            return
        
        config_dirs = ["hypr", "waybar", "kitty", "fish", "dunst", "fuzzel", "lf"]
        existing_dirs = [d for d in config_dirs if (self.config_dir / d).exists()]
        
        if not existing_dirs:
            console.print("[green]✅ No configurations to backup[/green]")
            return
        
        backup_dir.mkdir(parents=True, exist_ok=True)
        
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        ) as progress:
            
            task = progress.add_task("Backing up configurations...", total=len(existing_dirs))
            
            for config_dir in existing_dirs:
                source = self.config_dir / config_dir
                dest = backup_dir / config_dir
                
                progress.update(task, description=f"Backing up [cyan]{config_dir}[/cyan]...")
                
                try:
                    shutil.copytree(source, dest)
                    progress.update(task, description=f"✅ Backed up [green]{config_dir}[/green]")
                except Exception as e:
                    console.print(f"[yellow]⚠️  Failed to backup {config_dir}: {e}[/yellow]")
                
                progress.advance(task)
        
        console.print(f"[green]✅ Configurations backed up to {backup_dir}[/green]")
        
        # Rotate old backups (keep only 5 most recent)
        self.rotate_backups()

    def rotate_backups(self):
        """Keep only the 5 most recent backups"""
        backup_pattern = ".config-backup-*"
        backup_dirs = sorted([d for d in self.home_dir.glob(backup_pattern) if d.is_dir()])
        
        if len(backup_dirs) > 5:
            for old_backup in backup_dirs[:-5]:
                shutil.rmtree(old_backup)
                console.print(f"[dim]🗑️  Removed old backup: {old_backup.name}[/dim]")

    def create_symlinks(self):
        """Create configuration symlinks"""
        config_dirs = list((self.dotfiles_dir / "config").iterdir())
        
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        ) as progress:
            
            task = progress.add_task("Creating symlinks...", total=len(config_dirs))
            
            for config_path in config_dirs:
                if not config_path.is_dir():
                    continue
                
                config_name = config_path.name
                progress.update(task, description=f"Linking [cyan]{config_name}[/cyan]...")
                
                if config_name == "applications":
                    self.setup_applications(config_path)
                else:
                    self.setup_config_symlink(config_path, config_name)
                
                progress.advance(task)
        
        console.print("[green]✅ Symlink setup completed[/green]")

    def setup_applications(self, apps_dir: Path):
        """Setup application shortcuts"""
        apps_target_dir = self.home_dir / ".local/share/applications"
        apps_target_dir.mkdir(parents=True, exist_ok=True)
        
        for app_file in apps_dir.glob("*"):
            if app_file.is_file():
                target = apps_target_dir / app_file.name
                
                if target.is_symlink() and target.readlink() == app_file:
                    continue  # Already correct symlink
                
                if target.exists():
                    target.unlink()
                
                target.symlink_to(app_file)

    def setup_config_symlink(self, source: Path, config_name: str):
        """Setup individual config symlink"""
        target = self.config_dir / config_name
        
        if target.is_symlink() and target.readlink() == source:
            return  # Already correct symlink
        
        if target.exists():
            # Check if it's a small default config (< 50KB)
            try:
                size = sum(f.stat().st_size for f in target.rglob('*') if f.is_file())
                if size < 50000:  # Less than 50KB
                    shutil.rmtree(target)
                else:
                    console.print(f"[yellow]⚠️  Skipping {config_name} - custom config detected[/yellow]")
                    return
            except:
                shutil.rmtree(target)
        
        target.parent.mkdir(parents=True, exist_ok=True)
        target.symlink_to(source)

    def setup_ai_scripts(self):
        """Setup AI scripts for system-wide access"""
        bin_dir = self.home_dir / ".local/bin"
        bin_dir.mkdir(parents=True, exist_ok=True)
        
        ai_config_source = self.dotfiles_dir / "scripts/ai/ai-config.sh"
        ai_config_target = bin_dir / "ai-config"
        
        if ai_config_source.exists():
            if ai_config_target.is_symlink() and ai_config_target.readlink() == ai_config_source:
                console.print("[green]✅ AI config script already accessible[/green]")
            else:
                if ai_config_target.exists():
                    ai_config_target.unlink()
                ai_config_target.symlink_to(ai_config_source)
                console.print("[green]✅ AI config script made system-accessible[/green]")
        
        # Setup AI scripts directory symlink
        ai_scripts_dir = self.config_dir / "dynamic-theming"
        ai_scripts_dir.mkdir(parents=True, exist_ok=True)
        
        scripts_symlink = ai_scripts_dir / "scripts"
        scripts_source = self.dotfiles_dir / "scripts/ai"
        
        if scripts_source.exists():
            if scripts_symlink.is_symlink() and scripts_symlink.readlink() == scripts_source:
                console.print("[green]✅ AI scripts directory already linked[/green]")
            else:
                if scripts_symlink.exists():
                    scripts_symlink.unlink()
                scripts_symlink.symlink_to(scripts_source)
                console.print("[green]✅ AI scripts directory linked[/green]")

    def setup_ai_system(self):
        """Setup AI-Enhanced Dynamic Theming System"""
        console.print("[bold blue]🧠 Setting up AI system...[/bold blue]")
        
        # Create AI directories
        ai_config_dir = self.config_dir / "dynamic-theming"
        ai_config_dir.mkdir(parents=True, exist_ok=True)
        
        cache_dir = self.home_dir / ".cache/matugen"
        cache_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize AI configuration
        ai_config_file = ai_config_dir / "ai-config.conf"
        if not ai_config_file.exists():
            ai_config_script = self.home_dir / ".local/bin/ai-config"
            if ai_config_script.exists():
                try:
                    self.run_command([str(ai_config_script), "init"])
                    console.print("[green]✅ AI configuration initialized[/green]")
                except:
                    console.print("[yellow]⚠️  Failed to initialize AI config[/yellow]")
        
        # Setup Ollama models
        if shutil.which("ollama"):
            self.setup_ollama_models()
        else:
            console.print("[yellow]⚠️  Ollama not found - AI features will be limited[/yellow]")
        
        # Build AI dashboard
        self.build_ai_dashboard()

    def setup_ollama_models(self):
        """Setup Ollama AI models"""
        # Wait for ollama service
        with console.status("[yellow]Starting Ollama service...", spinner="dots"):
            max_attempts = 30
            for attempt in range(max_attempts):
                try:
                    result = self.run_command(["ollama", "list"], check=False, capture=True)
                    if result.returncode == 0:
                        break
                except:
                    pass
                
                if attempt == 0:
                    # Try to start service
                    try:
                        subprocess.Popen(["ollama", "serve"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    except:
                        pass
                
                time.sleep(2)
            else:
                console.print("[red]❌ Failed to start Ollama service[/red]")
                return
        
        console.print("[green]✅ Ollama service ready[/green]")
        
        # Download models
        models = [
            ("llava-llama3:8b", "LLAVA-Llama3 Vision Model"),
            ("phi4", "Phi4 Text Model")
        ]
        
        for model_name, display_name in models:
            self.download_ollama_model(model_name, display_name)

    def download_ollama_model(self, model_name: str, display_name: str):
        """Download an Ollama model with progress"""
        # Check if model already exists
        try:
            result = self.run_command(["ollama", "list"], capture=True)
            if model_name in result.stdout:
                console.print(f"[green]✅ {display_name} already installed[/green]")
                return
        except:
            pass
        
        console.print(f"[blue]📥 Downloading {display_name}...[/blue]")
        console.print("[dim]This may take several minutes depending on your internet connection[/dim]")
        
        with console.status(f"[yellow]Downloading {display_name}...", spinner="dots"):
            try:
                result = self.run_command(["ollama", "pull", model_name], check=False)
                if result.returncode == 0:
                    console.print(f"[green]✅ {display_name} installed successfully[/green]")
                else:
                    console.print(f"[red]❌ Failed to download {display_name}[/red]")
            except Exception as e:
                console.print(f"[red]❌ Error downloading {display_name}: {e}[/red]")

    def build_ai_dashboard(self):
        """Build the AI performance dashboard"""
        if not shutil.which("go"):
            console.print("[yellow]⚠️  Go not installed - AI dashboard will not be built[/yellow]")
            return
        
        dashboard_dir = self.dotfiles_dir / "scripts/ai"
        dashboard_source = dashboard_dir / "dashboard.go"
        
        if not dashboard_source.exists():
            console.print("[yellow]⚠️  AI dashboard source not found[/yellow]")
            return
        
        with console.status("[yellow]Building AI Performance Dashboard...", spinner="dots"):
            try:
                os.chdir(dashboard_dir)
                
                # Initialize go module if needed
                if not (dashboard_dir / "go.mod").exists():
                    self.run_command(["go", "mod", "init", "ai-dashboard"])
                    self.run_command(["go", "mod", "tidy"])
                
                # Build dashboard
                self.run_command(["go", "build", "-o", "dashboard", "dashboard.go"])
                os.chmod(dashboard_dir / "dashboard", 0o755)
                
                console.print("[green]✅ AI Performance Dashboard built successfully[/green]")
                
            except Exception as e:
                console.print(f"[yellow]⚠️  Failed to build AI dashboard: {e}[/yellow]")
            finally:
                os.chdir(self.dotfiles_dir)

    def setup_wallpaper_config(self):
        """Setup wallpaper configuration"""
        config_path = self.config_dir / "hypr/hyprpaper.conf"
        wallpaper_path = self.dotfiles_dir / "assets/wallpapers/evilpuccin.png"
        
        config_content = f"""preload = {wallpaper_path}
wallpaper = DP-3,{wallpaper_path}
wallpaper = DP-1,{wallpaper_path}
wallpaper = HDMI-A-1,{wallpaper_path}
splash = false
"""
        
        config_path.parent.mkdir(parents=True, exist_ok=True)
        config_path.write_text(config_content)
        console.print("[green]✅ Wallpaper configuration created[/green]")

    def setup_fish_shell(self):
        """Setup fish as default shell"""
        fish_path = shutil.which("fish")
        if not fish_path:
            console.print("[red]❌ Fish shell not found[/red]")
            return
        
        current_shell = os.environ.get("SHELL", "")
        if current_shell == fish_path:
            console.print("[green]✅ Fish is already the default shell[/green]")
            return
        
        try:
            self.run_command(["chsh", "-s", fish_path])
            console.print("[green]✅ Default shell changed to fish[/green]")
        except:
            console.print("[yellow]⚠️  Could not change default shell automatically[/yellow]")

    def configure_defaults(self):
        """Configure default applications"""
        with console.status("[yellow]Configuring defaults...", spinner="dots"):
            # Set default terminal
            self.run_command(["xdg-mime", "default", "kitty.desktop", "x-scheme-handler/terminal"], check=False)
            self.run_command(["xdg-mime", "default", "kitty.desktop", "application/x-terminal-emulator"], check=False)
            
            # Update XDG directories
            self.run_command(["xdg-user-dirs-update"], check=False)
            
            # Create screenshots directory
            screenshots_dir = self.home_dir / "Pictures/Screenshots"
            screenshots_dir.mkdir(parents=True, exist_ok=True)
            
            # Refresh font cache
            self.run_command(["fc-cache", "-fv"], check=False, capture=True)
        
        console.print("[green]✅ Default applications configured[/green]")

    def setup_vm_entry(self):
        """Setup Windows 11 VM entry"""
        console.print("[blue]💻 Setting up Windows 11 VM entry...[/blue]")
        
        vm_desktop_content = """[Desktop Entry]
Name=Windows 11 VM
Comment=Windows 11 Virtual Machine
Exec=virsh --connect qemu:///system start win11 && virt-viewer --connect qemu:///system --domain-name win11
Icon=windows
Terminal=false
Type=Application
Categories=System;Emulator;
"""
        
        vm_desktop_path = self.home_dir / ".local/share/applications/win11-vm.desktop"
        vm_desktop_path.parent.mkdir(parents=True, exist_ok=True)
        vm_desktop_path.write_text(vm_desktop_content)
        os.chmod(vm_desktop_path, 0o755)
        
        console.print("[green]✅ Windows 11 VM entry created[/green]")

    def setup_external_drives(self):
        """Setup external drive automounting"""
        console.print("[blue]💾 Setting up external drive automounting...[/blue]")
        
        try:
            # Get external drives with labels
            result = self.run_command(["lsblk", "-o", "NAME,LABEL,TYPE,MOUNTPOINT"], capture=True)
            lines = result.stdout.strip().split('\n')[1:]  # Skip header
            
            external_drives = []
            for line in lines:
                parts = line.split()
                if len(parts) >= 3 and parts[2] == "part" and len(parts) > 1 and parts[1] not in ["", "-"]:
                    label = parts[1]
                    # Skip system drives
                    if not any(skip in label.upper() for skip in ["ARCH", "ARCHISO", "EFI"]):
                        external_drives.append(label)
            
            if not external_drives:
                console.print("[yellow]⚠️  No external drives with labels found[/yellow]")
                return
            
            # Read current fstab
            fstab_path = Path("/etc/fstab")
            try:
                current_fstab = fstab_path.read_text()
            except:
                current_fstab = ""
            
            # Check which drives need to be added
            drives_to_add = []
            for label in external_drives:
                if f"LABEL={label}" not in current_fstab:
                    drives_to_add.append(label)
            
            if not drives_to_add:
                console.print("[green]✅ All external drives already in fstab[/green]")
                return
            
            # Add missing drives
            with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_fstab:
                temp_fstab.write(current_fstab)
                
                for label in drives_to_add:
                    mountpoint = f"/mnt/{label}"
                    # Create mountpoint
                    self.run_command(["sudo", "mkdir", "-p", mountpoint], check=False)
                    # Add to fstab
                    temp_fstab.write(f"LABEL={label} {mountpoint} auto nosuid,nodev,nofail,x-gvfs-show 0 0\n")
                    console.print(f"[green]✅ Added {label} to fstab[/green]")
                
                temp_fstab.flush()
                
                # Copy to actual fstab
                self.run_command(["sudo", "cp", temp_fstab.name, "/etc/fstab"])
                os.unlink(temp_fstab.name)
            
            console.print("[green]✅ External drive automounting configured[/green]")
            console.print("[blue]💡 Run 'sudo mount -a' to mount all drives[/blue]")
            
        except Exception as e:
            console.print(f"[yellow]⚠️  Failed to setup external drives: {e}[/yellow]")

    def configure_user_permissions(self):
        """Configure user permissions and groups"""
        console.print("[blue]👤 Configuring user permissions...[/blue]")
        
        try:
            # Get current user groups
            current_groups = [g.gr_name for g in grp.getgrall() if pwd.getpwuid(os.getuid()).pw_name in g.gr_mem]
            current_groups.append(pwd.getpwuid(os.getuid()).pw_gid)  # Primary group
            
            # Groups to add for hardware access
            groups_to_add = []
            if "video" not in current_groups:
                groups_to_add.append("video")
            if "i2c" not in current_groups:
                groups_to_add.append("i2c")
            
            if groups_to_add:
                groups_str = ",".join(groups_to_add)
                self.run_command(["sudo", "usermod", "-a", "-G", groups_str, os.getenv("USER")])
                console.print(f"[green]✅ Added user to groups: {groups_str}[/green]")
                console.print("[yellow]⚠️  You'll need to log out and back in for group changes to take effect[/yellow]")
            else:
                console.print("[green]✅ User already in required groups[/green]")
                
        except Exception as e:
            console.print(f"[yellow]⚠️  Failed to configure user permissions: {e}[/yellow]")

    def preflight_check(self) -> Dict[str, bool]:
        """Analyze current system state"""
        console.print("[bold blue]🔍 Analyzing current system state...[/bold blue]")
        
        needs = {
            'packages': False,
            'configs': False,
            'ai_scripts': False,
            'ai_system': False,
            'fish': False,
            'wallpaper': False,
            'vm': False,
            'fstab': False
        }
        
        # Check packages (but handle missing yay gracefully)
        with console.status("[yellow]Checking packages...", spinner="dots"):
            missing_packages = self.check_missing_packages()
            if missing_packages:
                needs['packages'] = True
        
        # Check configurations
        with console.status("[yellow]Checking configurations...", spinner="dots"):
            config_dirs = list((self.dotfiles_dir / "config").iterdir())
            for config_path in config_dirs:
                if not config_path.is_dir():
                    continue
                
                config_name = config_path.name
                if config_name == "applications":
                    apps_dir = self.home_dir / ".local/share/applications"
                    for app_file in config_path.glob("*"):
                        target = apps_dir / app_file.name
                        if not target.is_symlink() or target.readlink() != app_file:
                            needs['configs'] = True
                            break
                else:
                    target = self.config_dir / config_name
                    if not target.is_symlink() or target.readlink() != config_path:
                        needs['configs'] = True
        
        # Check AI scripts
        ai_config_target = self.home_dir / ".local/bin/ai-config"
        ai_config_source = self.dotfiles_dir / "scripts/ai/ai-config.sh"
        if not ai_config_target.is_symlink() or ai_config_target.readlink() != ai_config_source:
            needs['ai_scripts'] = True
        
        # Check AI system
        ai_config_file = self.config_dir / "dynamic-theming/ai-config.conf"
        if not ai_config_file.exists():
            needs['ai_system'] = True
        
        # Check fish shell
        fish_path = shutil.which("fish")
        if fish_path and os.environ.get("SHELL") != fish_path:
            needs['fish'] = True
        
        # Check wallpaper config
        wallpaper_config = self.config_dir / "hypr/hyprpaper.conf"
        if not wallpaper_config.exists():
            needs['wallpaper'] = True
        
        # Check VM setup
        vm_desktop = self.home_dir / ".local/share/applications/win11-vm.desktop"
        if not vm_desktop.exists():
            needs['vm'] = True
        
        # Check external drive automounting
        try:
            result = self.run_command(["lsblk", "-o", "NAME,LABEL,TYPE,MOUNTPOINT"], capture=True, check=False)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')[1:]  # Skip header
                has_external_drives = False
                for line in lines:
                    parts = line.split()
                    if len(parts) >= 3 and parts[2] == "part" and len(parts) > 1 and parts[1] not in ["", "-"]:
                        label = parts[1]
                        if not any(skip in label.upper() for skip in ["ARCH", "ARCHISO", "EFI"]):
                            has_external_drives = True
                            # Check if it's in fstab
                            try:
                                fstab_content = Path("/etc/fstab").read_text()
                                if f"LABEL={label}" not in fstab_content:
                                    needs['fstab'] = True
                                    break
                            except:
                                needs['fstab'] = True
        except:
            pass
        
        # Show analysis results
        self.show_analysis_results(needs, len(missing_packages) if missing_packages else 0)
        
        return needs

    def show_analysis_results(self, needs: Dict[str, bool], missing_count: int):
        """Show system analysis results"""
        table = Table(title="🔍 System Analysis Results", box=box.ROUNDED)
        table.add_column("Component", style="bold", width=20)
        table.add_column("Status", width=15)
        table.add_column("Details", width=40)
        
        components = [
            ("packages", "Packages", f"{missing_count} packages need installation" if needs['packages'] else "All packages installed"),
            ("configs", "Configurations", "Some symlinks need creation" if needs['configs'] else "All symlinks configured"),
            ("ai_scripts", "AI Scripts", "System access needs setup" if needs['ai_scripts'] else "Already accessible"),
            ("ai_system", "AI System", "Components need setup" if needs['ai_system'] else "Fully configured"),
            ("fish", "Fish Shell", "Needs to be set as default" if needs['fish'] else "Already default shell"),
            ("wallpaper", "Wallpaper", "Config needs generation" if needs['wallpaper'] else "Already configured"),
            ("vm", "VM Setup", "Windows 11 VM entry needs setup" if needs['vm'] else "Already configured"),
            ("fstab", "External Drives", "Automounting needs setup" if needs['fstab'] else "All drives in fstab")
        ]
        
        for key, name, details in components:
            if needs[key]:
                table.add_row(name, "[yellow]⚠️  Needs Setup[/yellow]", details)
            else:
                table.add_row(name, "[green]✅ Ready[/green]", details)
        
        console.print(table)
        
        if not any(needs.values()):
            console.print("\n[bold green]🎉 System appears to be fully configured![/bold green]")
            if not Confirm.ask("Everything looks good. Run full installation anyway?"):
                console.print("\n[blue]👋 Installation skipped. Run with --force to override.[/blue]")
                sys.exit(0)

    def show_final_summary(self):
        """Show final installation summary"""
        summary_panel = Panel(
            "[bold green]🎉 Installation Complete![/bold green]\n\n"
            "[blue]Your AI-Enhanced Dynamic Theming System is ready![/blue]\n\n"
            "Key Features:\n"
            "• [magenta]🧠 AI-powered wallpaper analysis[/magenta]\n"
            "• [cyan]🎨 Real-time desktop theming[/cyan]\n"
            "• [yellow]🌐 Firefox web theming extension[/yellow]\n"
            "• [green]⚡ Hyprland desktop environment[/green]\n\n"
            "Quick Start:\n"
            "• Press [bold]Super+B[/bold] to select wallpapers\n"
            "• Run [bold]ai-config status[/bold] to check AI system\n"
            "• Install Firefox extension with the provided script\n\n"
            "[dim]Check the documentation for complete setup guide[/dim]",
            title="[bold]🚀 Success[/bold]",
            border_style="green"
        )
        console.print(summary_panel)

    def main(self):
        """Main installation flow"""
        try:
            # Welcome and requirements
            self.show_welcome()
            self.check_requirements()
            self.check_sudo()
            
            # System analysis
            needs = self.preflight_check()
            
            # Package installation
            if needs['packages']:
                if Confirm.ask("\n[blue]📦 Install missing packages?[/blue]"):
                    # Ensure yay is installed first
                    self.install_yay()
                    # Re-check packages now that yay is available
                    console.print("[blue]🔍 Re-scanning packages with yay...[/blue]")
                    missing_packages = self.check_missing_packages()
                    self.install_packages(missing_packages)
            
            # Configuration setup
            if needs['configs'] or needs['ai_scripts']:
                if Confirm.ask("\n[blue]🔗 Setup configurations and symlinks?[/blue]"):
                    self.backup_configs()
                    self.create_symlinks()
                    if needs['ai_scripts']:
                        self.setup_ai_scripts()
            
            # Wallpaper setup
            if needs['wallpaper']:
                if Confirm.ask("\n[blue]🖼️  Setup wallpaper configuration?[/blue]"):
                    self.setup_wallpaper_config()
            
            # AI system setup
            if needs['ai_system']:
                if Confirm.ask("\n[blue]🧠 Setup AI system components?[/blue]"):
                    self.setup_ai_system()
            
            # Fish shell setup
            if needs['fish']:
                if Confirm.ask("\n[blue]🐚 Set fish as default shell?[/blue]"):
                    self.setup_fish_shell()
            
            # Default applications and user permissions
            self.configure_defaults()
            self.configure_user_permissions()
            
            # Optional VM setup
            if needs['vm']:
                if Confirm.ask("\n[blue]💻 Setup Windows 11 VM entry?[/blue]"):
                    self.setup_vm_entry()
            
            # Optional external drive setup
            if needs['fstab']:
                if Confirm.ask("\n[blue]💾 Setup external drive automounting?[/blue]"):
                    self.setup_external_drives()
            
            # Firefox extension setup
            firefox_extension = self.dotfiles_dir / "firefox-ai-extension.xpi"
            firefox_script = self.dotfiles_dir / "scripts/install-firefox-extension-permanent.sh"
            
            if firefox_extension.exists() and firefox_script.exists():
                if Confirm.ask("\n[blue]🌐 Setup Firefox AI Extension for web theming?[/blue]"):
                    try:
                        self.run_command([str(firefox_script)])
                        console.print("[green]✅ Firefox AI Extension setup complete[/green]")
                    except:
                        console.print("[yellow]⚠️  Firefox extension setup failed[/yellow]")
            
            # Final summary
            self.show_final_summary()
            
            # Optional reboot
            if Confirm.ask("\n[blue]🔄 Reboot system now to apply all changes?[/blue]"):
                console.print("[yellow]🔄 Rebooting system...[/yellow]")
                self.run_command(["sudo", "systemctl", "reboot"])
                
        except KeyboardInterrupt:
            console.print("\n[yellow]⚠️  Installation interrupted by user[/yellow]")
        except Exception as e:
            console.print(f"\n[red]❌ Installation failed: {e}[/red]")
            self.log(f"Installation failed: {e}", "ERROR")
            sys.exit(1)

if __name__ == "__main__":
    installer = DotfilesInstaller()
    installer.main() 