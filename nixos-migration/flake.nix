# NixOS Flake Configuration
# Modern flake-based configuration for your dotfiles migration
{
  description = "NixOS configuration with Hyprland and advanced theming";

  inputs = {
    # NixOS packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland.url = "github:hyprwm/Hyprland";

    # Matugen (CRITICAL for theming system)
    matugen = {
      url = "github:InioX/Matugen";
      ref = "refs/tags/matugen-v0.10.0";
    };

    # Additional inputs for custom packages
    # Add more as needed for other AUR packages
  };

  outputs = { self, nixpkgs, home-manager, hyprland, matugen, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # NixOS system configuration
      nixosConfigurations = {
        # Replace "nixos-hyprland" with your hostname
        nixos-hyprland = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            # System configuration
            ./system/configuration.nix
            
            # Hyprland
            hyprland.nixosModules.default
            { programs.hyprland.enable = true; }
            
            # Matugen module
            matugen.nixosModules.default
            
            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.martin = import ./home/home.nix;
            }
          ];
        };
      };

      # Standalone Home Manager configuration (optional)
      homeConfigurations = {
        martin = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./home/home.nix
            hyprland.homeManagerModules.default
          ];
        };
      };

      # Development shell for testing
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixos-rebuild
          home-manager
          git
          inputs.matugen.packages.${system}.default
        ];
        
        shellHook = ''
          echo "🚀 NixOS Migration Development Environment"
          echo "Available commands:"
          echo "  nixos-rebuild switch --flake .#nixos-hyprland"
          echo "  home-manager switch --flake .#martin"
          echo "  matugen --version"
        '';
      };

      # Overlays for custom packages
      overlays.default = final: prev: {
        # Import custom packages from overlays
        inherit (import ./overlays/cursor-bin.nix final prev) cursor;
        inherit (import ./overlays/custom-packages.nix final prev)
          pokemon-colorscripts
          cliphist
          hyprshot
          bibata-cursors-extra
          tela-icon-theme-extra
          amdgpu-monitor
          eza-enhanced
          dotfiles-scripts;
      };

      # Packages exposed by this flake
      packages.${system} = {
        # Expose matugen for easy access
        matugen = inputs.matugen.packages.${system}.default;
        
        # Custom packages
        cursor = (import ./overlays/cursor-bin.nix pkgs pkgs).cursor;
        
        # Default package
        default = inputs.matugen.packages.${system}.default;
      };

      # Formatter for `nix fmt`
      formatter.${system} = pkgs.alejandra;
    };
}