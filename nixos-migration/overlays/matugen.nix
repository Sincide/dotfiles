# Matugen Flake Integration
# CRITICAL PACKAGE: Material Design 3 color generation from wallpapers
# This is the core of your theming system

# NOTE: This file is now superseded by flake integration
# Use the flake input method instead of custom derivation

# For flake-based NixOS configuration, add to flake.nix:
#
# inputs = {
#   matugen = {
#     url = "github:InioX/Matugen";
#     ref = "refs/tags/matugen-v0.10.0"; # or latest
#   };
# };
#
# Then in your configuration:
# environment.systemPackages = with pkgs; [
#   inputs.matugen.packages.${system}.default
# ];
#
# And import the module:
# imports = [
#   inputs.matugen.nixosModules.default
# ];

# Legacy overlay (for non-flake systems)
self: super: {
  # This overlay is kept for compatibility but flake method is preferred
  matugen-legacy = super.rustPlatform.buildRustPackage rec {
    pname = "matugen";
    version = "0.10.0";

    src = super.fetchFromGitHub {
      owner = "InioX";
      repo = "matugen";
      rev = "matugen-v${version}";
      # Update hash after first build attempt
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    cargoHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";

    nativeBuildInputs = with super; [
      pkg-config
    ];

    buildInputs = with super; [
      openssl
    ] ++ super.lib.optionals super.stdenv.isDarwin [
      super.darwin.apple_sdk.frameworks.Security
      super.darwin.apple_sdk.frameworks.SystemConfiguration
    ];

    meta = with super.lib; {
      description = "Material Design 3 color scheme generator";
      homepage = "https://github.com/InioX/matugen";
      license = licenses.gpl2Plus;
      platforms = platforms.linux ++ platforms.darwin;
      mainProgram = "matugen";
    };
  };
}

# Usage Instructions:
# 1. Run the build to get the correct hash
# 2. Update the hash in src.hash with the provided hash
# 3. Update cargoHash with the provided hash
# 4. Test with: nix-shell -p matugen --run "matugen --version"
# 5. Test color generation: matugen image ~/wallpaper.jpg