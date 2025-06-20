# Dotfiles Python TUI Installer — Development Plan

## Overview
A modern, robust, and beautiful Python-based TUI installer for Arch Linux dotfiles, configs, packages, assets, and system tasks. Designed for maximum user control, clarity, and extensibility, with a dark-themed, keyboard-driven interface and advanced features for LLMs, automounting, and Brave backup/restore.

---

## Key Features & Requirements

### User Experience
- Full TUI (text user interface) with keyboard navigation (no mouse required)
- Sidebar/top-level menu for jumping between major sections
- Dark theme with graceful color fallback
- Built-in help/about section and README
- Section-by-section confirmation and full summary before applying changes
- Ability to go back and edit selections from the summary screen
- No install profiles; fresh run each time
- English only

### Installation Modes
- Quick install (recommended/default setup)
- Custom install (choose categories, subcategories, individual packages, assets, system tasks)

### Package Management
- All packages (official, AUR, Chaotic-AUR) installed via yay (except yay-bin, which is installed with pacman if missing)
- System update and sync via yay
- Parallel package installation for speed
- YAML file defines all package categories, subcategories, and packages, with descriptions and recommended/optional flags
- Section for LLMs (Ollama + models) with descriptions and selection

### Config & Asset Deployment
- Symlinks configs from dotfiles repo to appropriate locations (e.g., ~/.config/)
- Always prompt on overwrite (backup, overwrite, skip, etc.)
- Hybrid asset deployment: scans folders (scripts, fonts, wallpapers, etc.), uses YAML metadata if present for descriptions/grouping
- Lets user choose which asset types to deploy

### System Tasks
- Optional, prompted steps for system-level tasks (systemd services, default shell, sysctl tweaks, user groups)
- Persistent automounting for selected internal SSD/NVMe drives (mount points always under /mnt)
- Displays drive details before mounting; supports NTFS/exFAT

### Brave Backup & Restore
- Restore only (no backup on new install)
- Only prompts if user selects restore
- Looks for backups in /mnt/Stuff/brave-backups (drive must be mounted first)
- Finishes silently after restore

### Logging
- Option to enable plain text logging at startup (logs stored in ~/dotfiles/logs/)

### Error Handling
- Prompts user for action (retry, skip, abort) on any failure
- No dry run mode

### Internet & Updates
- Checks for internet connectivity at startup only
- Mentions (but does not track) reboot/logout needs

---

## High-Level Architecture

- **installer.py** — Main entry point, TUI logic, navigation, and orchestration
- **/modules/** — Modular Python files for:
  - tui.py (TUI components, sidebar, menus, dialogs)
  - packages.py (package management, YAML parsing, yay/pacman logic)
  - configs.py (symlinking, conflict handling)
  - assets.py (asset scanning, YAML metadata, deployment)
  - system.py (system tasks, automount, shell, sysctl, services)
  - llms.py (Ollama install, model selection, systemd setup)
  - brave.py (backup/restore logic)
  - logging.py (logging utilities)
  - utils.py (shared helpers)
- **/assets/** — Asset folders (fonts, wallpapers, scripts, etc.)
- **/package_definitions.yaml** — Main YAML file for packages, categories, descriptions, recommended/optional flags
- **/assets/** (subfolders) — Each may contain optional metadata.yaml for descriptions/grouping
- **/docs/INSTALLER_DEV_PLAN.md** — This development plan

---

## Implementation Plan

1. **Project Skeleton**
   - Create main script and modules directory
   - Set up basic TUI with sidebar and navigation
   - Implement help/about section and README

2. **YAML Package Definition**
   - Design schema for categories, subcategories, packages, descriptions, recommended/optional
   - Implement parser and TUI display logic

3. **Package Management**
   - yay-bin install logic (with pacman)
   - yay-based install/update logic (parallel where possible)
   - Section for LLMs (Ollama + models)

4. **Config & Asset Deployment**
   - Symlink logic with conflict prompts
   - Asset scanning and YAML metadata support
   - TUI for asset selection

5. **System Tasks**
   - Automounting logic for internal drives (persistent, /mnt, details display)
   - Systemd, shell, sysctl, user group management

6. **Brave Backup & Restore**
   - Restore logic (from /mnt/Stuff/brave-backups)
   - TUI prompt and silent finish

7. **Logging & Error Handling**
   - Plain text logging option
   - Prompt on failure (retry, skip, abort)

8. **Finalization**
   - Summary/review screen with edit capability
   - Section-by-section confirmation
   - Internet check at startup
   - Reboot/logout mention if needed

9. **Polish & Documentation**
   - Dark theme, color fallback
   - README and built-in help
   - Code comments and maintainability

---

## Notes
- No pip/venv required; all dependencies must be available via system package manager or bundled.
- TUI library: [Textual](https://github.com/Textualize/textual) is preferred for modern, beautiful TUI (available as Arch package: python-textual).
- All logic must be modular and extensible for future features.

---

# End of Plan 