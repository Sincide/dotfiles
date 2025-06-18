#!/bin/bash

set -euo pipefail

LOGFILE="$HOME/install.log"

log() {
    echo -e "[*] $1" | tee -a "$LOGFILE"
}

ascii_art() {
cat << "EOF"

     _    _                   _               _        
    / \  | | ___ ___  _ __ __| |   ___  _ __ | |_ ___  
   / _ \ | |/ __/ _ \| '__/ _\` |  / _ \| '_ \| __/ _ \ 
  / ___ \| | (_| (_) | | | (_| | | (_) | | | | || (_) |
 /_/   \_\_|\___\___/|_|  \__,_|  \___/|_| |_|\__\___/ 

   🔧 AMD OVERDRIVE SETUP (ppfeaturemask)

EOF
}

ascii_art

SCRIPT_PATH="$HOME/.local/bin/amdgpu-overdrive.sh"

mkdir -p "$(dirname "$SCRIPT_PATH")"

log "Creating AMDGPU overdrive script at $SCRIPT_PATH..."

cat > "$SCRIPT_PATH" <<'EOF'
#!/bin/bash

# Enable AMDGPU overdrive features
# Run this at boot via systemd or manually

echo "0xffffffff" > /sys/module/amdgpu/parameters/ppfeaturemask
echo "[✓] AMDGPU Overdrive features enabled."
EOF

chmod +x "$SCRIPT_PATH"

log "Script created. To enable AMD Overdrive, run:"
log "sudo $SCRIPT_PATH"

log ""
log "🛈 You can automate this at boot using a systemd service if desired."
log "✅ Overdrive script ready."
