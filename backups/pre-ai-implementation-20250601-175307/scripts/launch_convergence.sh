#!/bin/bash
echo "Launching Convergence: Elden Ring through Proton..."
cd "/home/martin/.steam/steam/steamapps/common/ELDEN RING"
env STEAM_COMPAT_DATA_PATH=/home/martin/.steam/steam/steamapps/compatdata/1245620 STEAM_COMPAT_CLIENT_INSTALL_PATH=/home/martin/.steam/steam ~/.steam/steam/steamapps/common/Proton*/proton run ./modengine2_launcher.exe -t er -c ./config_eldenring.toml
