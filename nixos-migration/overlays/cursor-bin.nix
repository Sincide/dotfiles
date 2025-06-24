# Cursor IDE Custom Derivation
# AI-powered IDE based on VSCode with integrated AI features
self: super: {
  cursor = super.stdenv.mkDerivation rec {
    pname = "cursor";
    version = "0.17.2"; # Update to latest version

    src = super.fetchurl {
      url = "https://downloader.cursor.sh/linux/appImage/x64";
      # Note: Update hash after first download attempt
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      name = "cursor-${version}.AppImage";
    };

    nativeBuildInputs = with super; [
      appimage-run
      makeWrapper
      autoPatchelfHook
    ];

    buildInputs = with super; [
      # Required libraries for Electron-based applications
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      curl
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      libappindicator-gtk3
      libc
      libdrm
      libnotify
      libpulseaudio
      libuuid
      libxcb
      libxkbcommon
      mesa
      nspr
      nss
      pango
      systemd
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXtst
      xorg.libxkbfile
      xorg.libxshmfence
    ];

    # Don't strip the binary
    dontStrip = true;
    dontPatchELF = true;

    unpackPhase = ''
      runHook preUnpack
      
      # Extract AppImage
      cp $src cursor.AppImage
      chmod +x cursor.AppImage
      ./cursor.AppImage --appimage-extract
      
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      # Create installation directory
      mkdir -p $out/opt/cursor
      mkdir -p $out/bin
      mkdir -p $out/share/applications
      mkdir -p $out/share/icons/hicolor/512x512/apps

      # Copy application files
      cp -r squashfs-root/* $out/opt/cursor/

      # Create wrapper script
      makeWrapper $out/opt/cursor/cursor $out/bin/cursor \
        --set CURSOR_PATH $out/opt/cursor \
        --add-flags "--no-sandbox" \
        --add-flags "--disable-gpu-sandbox" \
        --prefix LD_LIBRARY_PATH : "${super.lib.makeLibraryPath buildInputs}"

      # Install desktop file
      cat > $out/share/applications/cursor.desktop << EOF
      [Desktop Entry]
      Name=Cursor
      Comment=AI-first code editor
      Exec=$out/bin/cursor %F
      Icon=cursor
      Type=Application
      Categories=Development;IDE;
      MimeType=text/plain;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;text/x-java;text/x-dsrc;text/x-pascal;text/x-perl;text/x-python;application/x-php;application/x-httpd-php3;application/x-httpd-php4;application/x-httpd-php5;application/xml;text/html;text/css;text/x-sql;text/x-diff;
      StartupNotify=true
      StartupWMClass=cursor
      EOF

      # Install icon
      if [ -f $out/opt/cursor/cursor.png ]; then
        cp $out/opt/cursor/cursor.png $out/share/icons/hicolor/512x512/apps/cursor.png
      fi

      runHook postInstall
    '';

    # Fix permissions and set up runtime environment
    postFixup = ''
      # Make sure the main executable is executable
      chmod +x $out/opt/cursor/cursor

      # Patch ELF files
      find $out/opt/cursor -type f -executable -exec patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" {} \; 2>/dev/null || true

      # Add library paths
      find $out/opt/cursor -name "*.so*" -exec patchelf \
        --set-rpath "${super.lib.makeLibraryPath buildInputs}:$out/opt/cursor" {} \; 2>/dev/null || true
    '';

    meta = with super.lib; {
      description = "AI-first code editor";
      longDescription = ''
        Cursor is an AI-first code editor built on top of VSCode.
        It provides integrated AI features for code completion, generation,
        and assistance powered by various language models.
      '';
      homepage = "https://cursor.sh/";
      license = licenses.unfree;
      maintainers = [ maintainers.yourusername ]; # Update with your info
      platforms = [ "x86_64-linux" ];
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      mainProgram = "cursor";
    };
  };
}

# Alternative method using AppImage directly:
# If the above doesn't work, you can also create a simpler version:
/*
self: super: {
  cursor = super.appimageTools.wrapType2 rec {
    pname = "cursor";
    version = "0.17.2";
    
    src = super.fetchurl {
      url = "https://downloader.cursor.sh/linux/appImage/x64";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      name = "cursor-${version}.AppImage";
    };

    extraInstallCommands = ''
      mv $out/bin/cursor-* $out/bin/cursor
      
      # Install desktop file
      mkdir -p $out/share/applications
      cat > $out/share/applications/cursor.desktop << EOF
      [Desktop Entry]
      Name=Cursor
      Comment=AI-first code editor
      Exec=$out/bin/cursor %F
      Icon=cursor
      Type=Application
      Categories=Development;IDE;
      EOF
    '';

    meta = with super.lib; {
      description = "AI-first code editor";
      homepage = "https://cursor.sh/";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
    };
  };
}
*/

# Usage Instructions:
# 1. Download the AppImage to get the correct hash
# 2. Update the hash in src.hash
# 3. Test with: nix-shell -p cursor --run "cursor --version"
# 4. Allow unfree packages in your configuration