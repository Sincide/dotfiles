# Package Management - Main Module
# Imports all package categories matching your current 6-category system
{ config, pkgs, ... }:

{
  imports = [
    ./essential.nix
    ./development.nix
    ./theming.nix
    ./multimedia.nix
    ./gaming.nix
    ./optional.nix
  ];

  # Package management utilities
  home.packages = with pkgs; [
    # Nix utilities
    nix-index
    nix-tree
    nixpkgs-review
    
    # System information
    neofetch
    fastfetch
    
    # Archive tools
    unzip
    p7zip
    unrar
    
    # Network utilities
    wget
    curl
    rsync
    
    # Basic utilities that don't fit other categories
    tree
    which
    file
    lsof
  ];

  # Configure nix-index for command-not-found functionality
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  # Command-not-found replacement
  programs.command-not-found.enable = false;
}