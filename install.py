#!/usr/bin/env python3
import os
import sys
import subprocess
import shutil
import argparse
from pathlib import Path
from datetime import datetime
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TimeElapsedColumn, TimeRemainingColumn
from rich.panel import Panel
import questionary

console = Console()

# --- Config ---
CORE_PACKAGES = [
    "hyprland", "hyprpaper", "waybar", "kitty", "fish", "fuzzel", "dunst", "polkit-gnome",
    "xdg-desktop-portal-hyprland", "xdg-desktop-portal-gtk", "qt5-wayland", "qt6-wayland",
    "pipewire", "wireplumber", "pavucontrol", "pamixer", "playerctl", "grim", "slurp",
    "wl-clipboard", "swappy", "cliphist", "catppuccin-gtk-theme-mocha", "ttf-jetbrains-mono-nerd",
    "noto-fonts", "noto-fonts-cjk", "noto-fonts-emoji", "papirus-icon-theme", "thunar",
    "thunar-volman", "thunar-archive-plugin", "xdg-utils", "xdg-user-dirs", "network-manager-applet",
    "blueman", "jq", "swaylock-effects", "vulkan-radeon", "lib32-vulkan-radeon", "libva-mesa-driver",
    "lib32-libva-mesa-driver", "mesa-vdpau", "lib32-mesa-vdpau", "gnupg", "exa", "ripgrep", "fzf",
    "lm_sensors", "radeontop", "wlsunset", "light", "ddcutil", "zoxide", "gum"
]
LF_PACKAGES = ["lf", "bat", "file", "mediainfo", "chafa", "atool", "ffmpegthumbnailer", "poppler"]
PHYSICAL_PACKAGES = ["brightnessctl"]

# --- Utility Functions ---
def run(cmd, check=True, capture_output=False, shell=False):
    """Run a shell command, print it, and return the result."""
    if isinstance(cmd, list):
        cmd_str = " ".join(cmd)
    else:
        cmd_str = cmd
    console.log(f"[bold cyan]$ {cmd_str}")
    return subprocess.run(cmd, check=check, capture_output=capture_output, shell=shell)

def is_root():
    return os.geteuid() == 0

def check_sudo():
    if is_root():
        console.print("[bold red]Please do not run as root! Exiting.")
        sys.exit(1)
    try:
        run(["sudo", "-v"])
    except Exception:
        console.print("[bold red]Sudo privileges required. Exiting.")
        sys.exit(1)

# --- Environment Detection ---
def detect_environment():
    try:
        result = run(["systemd-detect-virt", "--vm"], check=False, capture_output=True)
        if result.returncode == 0:
            return "vm"
        result = run(["systemd-detect-virt", "--container"], check=False, capture_output=True)
        if result.returncode == 0:
            return "container"
    except Exception:
        pass
    return "physical"

# --- yay install ---
def ensure_yay():
    if shutil.which("yay") is not None:
        console.print("[green]yay is already installed.")
        return
    console.print("[yellow]Installing yay-bin (AUR helper)...")
    tmpdir = Path("/tmp/yay-bin")
    if tmpdir.exists():
        shutil.rmtree(tmpdir)
    run(["git", "clone", "https://aur.archlinux.org/yay-bin.git", str(tmpdir)])
    run(["bash", "-c", f"cd {tmpdir} && makepkg -si --noconfirm"])
    shutil.rmtree(tmpdir)
    console.print("[green]yay-bin installed successfully.")

# --- Package Install with Progress Bar ---
def install_packages(packages, batch=False):
    missing = []
    for pkg in packages:
        if run(["yay", "-Q", pkg], check=False).returncode != 0:
            missing.append(pkg)
    if not missing:
        console.print("[green]All required packages are already installed.")
        return [], []
    installed = []
    failed = []
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TextColumn("{task.completed}/{task.total}"),
        TimeElapsedColumn(),
        TimeRemainingColumn(),
        console=console,
    ) as progress:
        task = progress.add_task("Installing packages...", total=len(missing))
        for pkg in missing:
            desc = f"[cyan]Installing [bold]{pkg}[/bold]"
            progress.update(task, description=desc)
            result = run(["yay", "-S", "--needed", "--noconfirm", pkg], check=False)
            if result.returncode == 0:
                installed.append(pkg)
            else:
                failed.append(pkg)
            progress.advance(task)
    return installed, failed

# --- Interactive Prompt Helper ---
def prompt_confirm(msg, batch):
    if batch:
        return True
    return questionary.confirm(msg, default=True).ask()

# --- Main Installer Logic ---
def main():
    parser = argparse.ArgumentParser(description="Arch Linux Dotfiles Installer")
    parser.add_argument("--batch", action="store_true", help="Run in batch mode (no prompts)")
    args = parser.parse_args()
    batch = args.batch

    console.print(Panel("[bold magenta]Arch Linux Dotfiles Installer[/bold magenta]", expand=False, border_style="magenta"))
    check_sudo()
    env_type = detect_environment()
    console.print(f"[bold]Detected environment:[/bold] [cyan]{env_type}[/cyan]")

    if prompt_confirm("Install yay (AUR helper) if missing?", batch):
        ensure_yay()

    if prompt_confirm("Install all required packages?", batch):
        all_pkgs = CORE_PACKAGES + LF_PACKAGES
        if env_type == "physical":
            all_pkgs += PHYSICAL_PACKAGES
        installed, failed = install_packages(all_pkgs, batch=batch)
        console.print()
        if installed:
            console.print(f"[green]Installed:[/green] {len(installed)} packages.")
        if failed:
            console.print(f"[red]Failed:[/red] {len(failed)} packages: {', '.join(failed)}")
        if not failed:
            console.print("[bold green]All packages installed successfully!")

    if prompt_confirm("Backup existing configs?", batch):
        backup_configs(batch)
        rotate_backups()

    if prompt_confirm("Create symlinks for configs?", batch):
        create_symlinks(batch)

    if prompt_confirm("Set up wallpapers?", batch):
        set_hyprpaper_conf(env_type)

    set_permissions()
    configure_env_specific(env_type)
    configure_defaults()

    if prompt_confirm("Set fish as your default shell?", batch):
        set_fish_shell()

    if env_type == "physical":
        if prompt_confirm("Set up the Windows 11 VM entry?", batch):
            install_win11_vm_entry()
            restore_vm()
        if prompt_confirm("Automatically add external drives to /etc/fstab for automounting?", batch):
            automount_external_drives()

    final_verification()
    verify_gpu_monitoring(env_type)
    console.print("\n[bold green]Installation complete![/bold green]\n")
    prompt_reboot(batch)

if __name__ == "__main__":
    main() 