"""
Dependency Manager for AI Diagnostic System

This module handles checking and installing system dependencies:
- Maps Python packages to Arch Linux package names  
- Checks if packages are installed via pacman
- Offers to install missing packages automatically
- Handles both official repos (pacman) and AUR (yay/paru)
- Provides user-friendly prompts and error handling
"""

import logging
import subprocess
import sys
from typing import Dict, List, Optional, Tuple, Set
from dataclasses import dataclass
from enum import Enum

from rich.console import Console
from rich.panel import Panel
from rich.prompt import Confirm, Prompt
from rich.table import Table
from rich.text import Text


class PackageSource(str, Enum):
    """Source where a package can be installed from."""
    PACMAN = "pacman"     # Official Arch repositories
    AUR = "aur"          # Arch User Repository (via yay/paru)
    MANUAL = "manual"    # Manual installation required


@dataclass
class PackageDependency:
    """Represents a system package dependency."""
    python_name: str          # Python package name (e.g., "textual")
    system_name: str          # System package name (e.g., "python-textual")
    source: PackageSource     # Where to install from
    description: str          # Human-readable description
    required: bool = True     # Whether this is required or optional
    check_command: Optional[str] = None  # Custom command to verify installation


class DependencyManager:
    """
    Manages system dependencies for the AI diagnostic system.
    
    Handles dependency checking, installation prompts, and automatic
    package installation via system package managers.
    """
    
    # Mapping of Python packages to Arch Linux packages
    PACKAGE_MAPPING = {
        "textual": PackageDependency(
            python_name="textual",
            system_name="python-textual",
            source=PackageSource.AUR,
            description="Interactive terminal UI framework"
        ),
        "rich": PackageDependency(
            python_name="rich",
            system_name="python-rich",
            source=PackageSource.PACMAN,
            description="Rich text and beautiful formatting"
        ),
        "ollama": PackageDependency(
            python_name="ollama",
            system_name="python-ollama",
            source=PackageSource.AUR,
            description="Ollama Python client library",
            check_command="python -c 'import ollama'"
        ),
        "psutil": PackageDependency(
            python_name="psutil",
            system_name="python-psutil",
            source=PackageSource.PACMAN,
            description="System and process utilities"
        ),
        "aiofiles": PackageDependency(
            python_name="aiofiles",
            system_name="python-aiofiles",
            source=PackageSource.PACMAN,
            description="Async file I/O operations"
        ),
        "aiosqlite": PackageDependency(
            python_name="aiosqlite",
            system_name="python-aiosqlite",
            source=PackageSource.AUR,
            description="Async SQLite database operations"
        ),
        "click": PackageDependency(
            python_name="click",
            system_name="python-click",
            source=PackageSource.PACMAN,
            description="Command-line interface creation toolkit"
        ),
        "pydantic": PackageDependency(
            python_name="pydantic",
            system_name="python-pydantic",
            source=PackageSource.PACMAN,
            description="Data validation and settings management"
        ),
        "watchdog": PackageDependency(
            python_name="watchdog",
            system_name="python-watchdog",
            source=PackageSource.AUR,
            description="File system event monitoring"
        ),
        # Special system dependencies
        "ollama-binary": PackageDependency(
            python_name="ollama-binary",
            system_name="ollama",
            source=PackageSource.MANUAL,
            description="Ollama binary for LLM functionality",
            check_command="which ollama"
        )
    }
    
    def __init__(self):
        self.console = Console()
        self.logger = logging.getLogger(__name__)
        self._aur_helper = self._detect_aur_helper()
    
    def check_all_dependencies(self) -> Tuple[List[PackageDependency], List[PackageDependency]]:
        """
        Check all required dependencies.
        
        Returns:
            Tuple of (missing_packages, installed_packages)
        """
        missing = []
        installed = []
        
        for dep in self.PACKAGE_MAPPING.values():
            if self._is_package_installed(dep):
                installed.append(dep)
            else:
                missing.append(dep)
        
        return missing, installed
    
    def check_python_imports(self) -> List[str]:
        """
        Check which Python packages can be imported.
        
        Returns:
            List of Python package names that failed to import
        """
        failed_imports = []
        
        for python_name in self.PACKAGE_MAPPING.keys():
            if python_name == "ollama-binary":  # Skip non-Python packages
                continue
                
            try:
                __import__(python_name)
            except ImportError:
                failed_imports.append(python_name)
        
        return failed_imports
    
    async def install_missing_dependencies(self, missing_packages: List[PackageDependency], 
                                         interactive: bool = True) -> bool:
        """
        Install missing dependencies with user confirmation.
        
        Args:
            missing_packages: List of missing package dependencies
            interactive: Whether to prompt user for confirmation
            
        Returns:
            bool: True if all installations successful, False otherwise
        """
        if not missing_packages:
            self.console.print("[green]✅ All dependencies are already installed![/green]")
            return True
        
        # Display missing dependencies
        self._display_missing_dependencies(missing_packages)
        
        if interactive:
            # Check sudo access before proceeding
            if not self._check_sudo_access():
                self.console.print("[yellow]⚠️ Sudo access required for package installation[/yellow]")
                if not Confirm.ask("Continue anyway? (you'll be prompted for password)"):
                    return False
            
            if not Confirm.ask("Install missing dependencies?"):
                self.console.print("[yellow]⚠️ Skipping dependency installation[/yellow]")
                return False
        
        # Group packages by installation method
        pacman_packages = [dep for dep in missing_packages if dep.source == PackageSource.PACMAN]
        aur_packages = [dep for dep in missing_packages if dep.source == PackageSource.AUR]
        manual_packages = [dep for dep in missing_packages if dep.source == PackageSource.MANUAL]
        
        success = True
        
        # Install pacman packages
        if pacman_packages:
            success &= await self._install_pacman_packages(pacman_packages)
        
        # Install AUR packages
        if aur_packages:
            success &= await self._install_aur_packages(aur_packages)
        
        # Handle manual packages
        if manual_packages:
            success &= await self._handle_manual_packages(manual_packages)
        
        return success
    
    def _display_missing_dependencies(self, missing_packages: List[PackageDependency]) -> None:
        """Display missing dependencies in a formatted table."""
        table = Table(title="Missing Dependencies")
        table.add_column("Package", style="cyan")
        table.add_column("Source", style="magenta")
        table.add_column("Description", style="white")
        table.add_column("Required", style="yellow")
        
        for dep in missing_packages:
            required_text = "✅ Yes" if dep.required else "⚠️ Optional"
            table.add_row(
                dep.system_name,
                dep.source.value,
                dep.description,
                required_text
            )
        
        self.console.print(table)
    
    def _is_package_installed(self, dep: PackageDependency) -> bool:
        """Check if a package dependency is installed."""
        # Use custom check command if provided
        if dep.check_command:
            try:
                result = subprocess.run(
                    dep.check_command,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                return result.returncode == 0
            except Exception:
                return False
        
        # Check if system package is installed
        if dep.source in [PackageSource.PACMAN, PackageSource.AUR]:
            try:
                result = subprocess.run(
                    ["pacman", "-Q", dep.system_name],
                    capture_output=True,
                    text=True
                )
                return result.returncode == 0
            except Exception:
                return False
        
        # For manual packages, try to import Python module
        if dep.python_name != "ollama-binary":
            try:
                __import__(dep.python_name)
                return True
            except ImportError:
                return False
        
        return False
    
    def _detect_aur_helper(self) -> Optional[str]:
        """Detect available AUR helper (yay, paru, etc.)."""
        aur_helpers = ["yay", "paru", "trizen", "pikaur"]
        
        for helper in aur_helpers:
            try:
                subprocess.run(
                    ["which", helper],
                    capture_output=True,
                    check=True
                )
                self.logger.info(f"Detected AUR helper: {helper}")
                return helper
            except subprocess.CalledProcessError:
                continue
        
        self.logger.warning("No AUR helper found")
        return None
    
    def _check_sudo_access(self) -> bool:
        """Check if user has sudo access without password or can use sudo."""
        try:
            # Try sudo -n (non-interactive) to see if passwordless sudo works
            result = subprocess.run(
                ["sudo", "-n", "true"],
                capture_output=True,
                timeout=5
            )
            return result.returncode == 0
        except Exception:
            return False
    
    async def _install_pacman_packages(self, packages: List[PackageDependency]) -> bool:
        """Install packages from official repositories via pacman."""
        package_names = [dep.system_name for dep in packages]
        
        self.console.print(f"[blue]📦 Installing {len(package_names)} packages via pacman...[/blue]")
        self.console.print(f"[yellow]💡 You may be prompted for sudo password[/yellow]")
        
        cmd = ["sudo", "pacman", "-S", "--noconfirm"] + package_names
        
        try:
            # Don't capture output so user can see sudo prompt
            self.console.print(f"[dim]Running: {' '.join(cmd)}[/dim]")
            result = subprocess.run(
                cmd,
                timeout=300  # 5 minute timeout
            )
            
            if result.returncode == 0:
                self.console.print("[green]✅ Pacman packages installed successfully[/green]")
                return True
            else:
                self.console.print(f"[red]❌ Pacman installation failed with exit code {result.returncode}[/red]")
                return False
                
        except subprocess.TimeoutExpired:
            self.console.print("[red]❌ Pacman installation timed out[/red]")
            return False
        except KeyboardInterrupt:
            self.console.print("[yellow]⚠️ Installation cancelled by user[/yellow]")
            return False
        except Exception as e:
            self.console.print(f"[red]❌ Error installing pacman packages: {e}[/red]")
            return False
    
    async def _install_aur_packages(self, packages: List[PackageDependency]) -> bool:
        """Install packages from AUR via helper."""
        if not self._aur_helper:
            self.console.print("[red]❌ No AUR helper found. Please install yay or paru first.[/red]")
            self.console.print("Install with: [cyan]sudo pacman -S yay[/cyan]")
            return False
        
        package_names = [dep.system_name for dep in packages]
        
        self.console.print(f"[blue]📦 Installing {len(package_names)} packages via {self._aur_helper}...[/blue]")
        self.console.print(f"[yellow]💡 AUR builds may take several minutes and require user input[/yellow]")
        
        cmd = [self._aur_helper, "-S", "--noconfirm"] + package_names
        
        try:
            # Don't capture output so user can see build progress and prompts
            self.console.print(f"[dim]Running: {' '.join(cmd)}[/dim]")
            result = subprocess.run(
                cmd,
                timeout=600  # 10 minute timeout for AUR builds
            )
            
            if result.returncode == 0:
                self.console.print(f"[green]✅ AUR packages installed successfully via {self._aur_helper}[/green]")
                return True
            else:
                self.console.print(f"[red]❌ AUR installation failed with exit code {result.returncode}[/red]")
                return False
                
        except subprocess.TimeoutExpired:
            self.console.print("[red]❌ AUR installation timed out[/red]")
            return False
        except KeyboardInterrupt:
            self.console.print("[yellow]⚠️ AUR installation cancelled by user[/yellow]")
            return False
        except Exception as e:
            self.console.print(f"[red]❌ Error installing AUR packages: {e}[/red]")
            return False
    
    async def _handle_manual_packages(self, packages: List[PackageDependency]) -> bool:
        """Handle packages that require manual installation."""
        for dep in packages:
            if dep.system_name == "ollama":
                self.console.print("[yellow]📋 Manual installation required for Ollama[/yellow]")
                
                install_ollama = Confirm.ask("Install Ollama now?")
                if install_ollama:
                    if not await self._install_ollama():
                        return False
                else:
                    self.console.print("[yellow]⚠️ Skipping Ollama installation[/yellow]")
        
        return True
    
    async def _install_ollama(self) -> bool:
        """Install Ollama binary."""
        self.console.print("[blue]🤖 Installing Ollama...[/blue]")
        
        try:
            # Download and install Ollama
            with self.console.status("Downloading Ollama installer..."):
                result = subprocess.run(
                    ["curl", "-fsSL", "https://ollama.com/install.sh"],
                    capture_output=True,
                    text=True,
                    timeout=60
                )
            
            if result.returncode != 0:
                self.console.print("[red]❌ Failed to download Ollama installer[/red]")
                return False
            
            # Execute installer
            with self.console.status("Installing Ollama..."):
                install_result = subprocess.run(
                    ["sh"],
                    input=result.stdout,
                    text=True,
                    timeout=300
                )
            
            if install_result.returncode == 0:
                self.console.print("[green]✅ Ollama installed successfully[/green]")
                
                # Start and enable Ollama service
                self.console.print("[blue]🔧 Configuring Ollama service...[/blue]")
                subprocess.run(["systemctl", "--user", "enable", "ollama"])
                subprocess.run(["systemctl", "--user", "start", "ollama"])
                
                # Install required models
                install_models = Confirm.ask("Install required AI models (phi4, llama3.2)?")
                if install_models:
                    await self._install_ollama_models()
                
                return True
            else:
                self.console.print("[red]❌ Ollama installation failed[/red]")
                return False
                
        except Exception as e:
            self.console.print(f"[red]❌ Error installing Ollama: {e}[/red]")
            return False
    
    async def _install_ollama_models(self) -> bool:
        """Install required Ollama models."""
        models = ["phi4", "llama3.2"]
        
        for model in models:
            self.console.print(f"[blue]🧠 Installing AI model: {model}[/blue]")
            try:
                with self.console.status(f"Downloading {model}..."):
                    result = subprocess.run(
                        ["ollama", "pull", model],
                        capture_output=True,
                        text=True,
                        timeout=1800  # 30 minutes for large models
                    )
                
                if result.returncode == 0:
                    self.console.print(f"[green]✅ Model {model} installed[/green]")
                else:
                    self.console.print(f"[red]❌ Failed to install model {model}[/red]")
                    return False
                    
            except subprocess.TimeoutExpired:
                self.console.print(f"[red]❌ Model {model} download timed out[/red]")
                return False
            except Exception as e:
                self.console.print(f"[red]❌ Error installing model {model}: {e}[/red]")
                return False
        
        return True
    
    def get_installation_summary(self) -> Dict[str, List[str]]:
        """Get summary of package installation methods."""
        summary = {
            "pacman": [],
            "aur": [],
            "manual": []
        }
        
        for dep in self.PACKAGE_MAPPING.values():
            if dep.source == PackageSource.PACMAN:
                summary["pacman"].append(dep.system_name)
            elif dep.source == PackageSource.AUR:
                summary["aur"].append(dep.system_name)
            elif dep.source == PackageSource.MANUAL:
                summary["manual"].append(dep.system_name)
        
        return summary
    
    def display_installation_help(self) -> None:
        """Display manual installation instructions."""
        self.console.print(Panel(
            "[bold blue]Manual Installation Instructions[/bold blue]\n\n"
            "[yellow]Core packages (pacman):[/yellow]\n"
            "sudo pacman -S python-rich python-click python-pydantic python-psutil python-aiofiles\n\n"
            "[yellow]Additional packages (AUR):[/yellow]\n"
            "yay -S python-textual python-aiosqlite python-watchdog python-ollama\n\n"
            "[yellow]Ollama binary:[/yellow]\n"
            "curl -fsSL https://ollama.com/install.sh | sh\n"
            "systemctl --user enable ollama\n"
            "systemctl --user start ollama\n"
            "ollama pull phi4\n"
            "ollama pull llama3.2",
            title="📦 Dependencies",
            border_style="blue"
        )) 