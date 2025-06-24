# NixOS Migration Strategy for Dotfiles Package Management

## Executive Summary

Current Arch Linux dotfiles system contains **202 packages** across 6 categories. The migration to NixOS will require:
- Direct mapping for ~180 packages (89%)
- Custom derivations for ~7 critical packages
- Alternative solutions for ~15 Arch-specific packages

## Current Package Architecture Analysis

### Package Distribution by Category
- **Essential**: 65 packages (core system, Wayland, Hyprland)
- **Development**: 41 packages (languages, tools, containers)
- **Theming**: 30 packages (themes, fonts, color tools)
- **Multimedia**: 23 packages (media players, codecs, creative tools)
- **Gaming**: 21 packages (Steam, Wine, performance tools)
- **Optional**: 22 packages (browsers, communication, utilities)

### Source Distribution Analysis
- **Official Arch repos**: ~160 packages (79%)
- **AUR packages**: ~25 packages (12%)
- **Arch-specific**: ~17 packages (9%)

## Critical Dependencies for Theming System

The dotfiles' sophisticated theming system depends on these key packages:

### Essential for Dynamic Theming
1. **matugen** (AUR) - Material Design 3 color generation from wallpapers
2. **swww** - Wayland wallpaper daemon
3. **imagemagick** - Image processing for color extraction
4. **hyprland** - Core window manager
5. **waybar** - Status bars with dynamic theming

### Font Infrastructure
- **ttf-jetbrains-mono-nerd** - Primary terminal font
- **noto-fonts** + **noto-fonts-emoji** - System fonts
- **ttf-font-awesome** + **ttf-material-design-icons** - Icon fonts

## Migration Challenges & Solutions

### 1. Critical Custom Derivations Needed

#### matugen (PRIORITY: CRITICAL)
- **Function**: Core of the theming system - generates Material Design 3 colors
- **Current**: AUR package, Rust-based
- **Solution**: Custom derivation from source (https://github.com/InioX/matugen)
- **Impact**: Entire theming system depends on this

#### cursor-bin (PRIORITY: HIGH)
- **Function**: AI-powered IDE used in development workflow
- **Current**: AUR binary package
- **Solution**: Custom derivation or use VSCode with cursor extensions
- **Impact**: Development environment setup

#### cliphist (PRIORITY: MEDIUM)
- **Function**: Wayland clipboard manager for Hyprland
- **Current**: AUR package
- **Solution**: Custom derivation or use wl-clipboard alternatives
- **Impact**: Clipboard functionality in Wayland

### 2. Arch-Specific Packages Requiring Alternatives

#### pacman-contrib
- **Current**: Pacman maintenance utilities
- **NixOS Alternative**: Built-in nix tools (nix-collect-garbage, etc.)

#### lib32-gamemode, lib32-mangohud
- **Current**: 32-bit gaming libraries
- **NixOS Alternative**: Enable 32-bit support in gaming packages
- **Solution**: `pkgs.pkgsi686Linux.gamemode`, steam.enable32Bit

#### pactl
- **Current**: Standalone PulseAudio control
- **NixOS Alternative**: Part of pulseaudio/pipewire packages

### 3. Simple Packages for Custom Derivation

#### pokemon-colorscripts-git
- **Solution**: Fetch from git, simple shell scripts
- **Priority**: LOW (novelty feature)

#### pipes.sh
- **Solution**: Single shell script, easy custom derivation
- **Priority**: LOW (terminal screensaver)

## NixOS Configuration Structure Strategy

### 1. Modular Package Organization
```nix
# Mirroring current dotfiles structure
{
  imports = [
    ./packages/essential.nix
    ./packages/development.nix
    ./packages/theming.nix
    ./packages/multimedia.nix
    ./packages/gaming.nix
    ./packages/optional.nix
  ];
}
```

### 2. System vs User Packages
- **System packages** (NixOS config): Core system, drivers, services
- **User packages** (Home Manager): CLI tools, applications, themes

### 3. Custom Derivations Location
```
overlays/
├── matugen.nix           # Critical theming tool
├── cursor-bin.nix        # AI IDE
├── cliphist.nix          # Clipboard manager
├── pokemon-scripts.nix   # Terminal scripts
└── pipes-sh.nix          # Terminal screensaver
```

## Migration Roadmap

### Phase 1: Core System (Essential + Development)
1. Map 106 common packages to nixpkgs equivalents
2. Create custom derivations for:
   - matugen (critical for theming)
   - cursor-bin (development environment)
3. Test basic Hyprland + Waybar functionality

### Phase 2: Theming System
1. Verify all theming packages work with custom matugen
2. Test Material Design 3 color generation pipeline
3. Ensure font rendering and GTK theming works

### Phase 3: Multimedia & Gaming
1. Configure gaming stack with proper 32-bit support
2. Test multimedia codecs and hardware acceleration
3. Verify AMD GPU monitoring tools

### Phase 4: Optional & Polish
1. Add remaining optional packages
2. Create convenience scripts matching current automation
3. Test complete system integration

## Package Mapping Examples

### Direct Mappings (Most packages)
```nix
# Arch → NixOS
hyprland → pkgs.hyprland
waybar → pkgs.waybar
kitty → pkgs.kitty
neovim → pkgs.neovim
docker → pkgs.docker
steam → pkgs.steam
```

### Packages Needing Options
```nix
# Gaming with 32-bit support
programs.steam.enable = true;
hardware.opengl.driSupport32Bit = true;

# Docker with user access
virtualisation.docker.enable = true;
users.users.martin.extraGroups = [ "docker" ];
```

### Custom Derivations Required
```nix
# In overlays/
matugen = pkgs.rustPlatform.buildRustPackage {
  pname = "matugen";
  version = "2.2.0";
  src = pkgs.fetchFromGitHub { ... };
  # ... derivation details
};
```

## Risk Assessment

### Low Risk (90% of packages)
- Standard CLI tools, languages, libraries
- Well-maintained packages in nixpkgs
- Direct 1:1 mapping available

### Medium Risk (7% of packages)
- AUR packages with custom derivations needed
- Packages requiring specific NixOS configuration
- Alternative packages with slight functionality differences

### High Risk (3% of packages)
- matugen (critical for theming system)
- Arch-specific utilities without direct equivalents
- Binary-only packages requiring complex derivations

## Success Metrics

1. **Theming System**: Wallpaper → color generation → system-wide theming works
2. **Development Environment**: All languages, tools, and IDE functionality
3. **Gaming Performance**: Steam, Wine, hardware acceleration functioning
4. **System Monitoring**: GPU monitoring, system stats, dashboard operational
5. **Automation**: Key scripts and workflows replicated

## Conclusion

The migration is highly feasible with 89% direct package mapping possible. The main challenge is creating custom derivations for ~7 packages, particularly matugen which is critical for the theming system. The modular NixOS configuration should mirror the current dotfiles structure for maintainability.

Priority should be given to:
1. Creating matugen custom derivation
2. Setting up core Hyprland environment
3. Testing theming pipeline functionality
4. Gradually adding remaining packages by category