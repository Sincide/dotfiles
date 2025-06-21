# Complete eww Guide for Arch Linux with Hyprland

Eww (ElKowar's wacky widgets) represents one of the most flexible and powerful widget systems available for Linux desktop environments. **This guide provides everything needed to successfully set up and master eww on Arch Linux with amdgpu drivers and Hyprland window manager**, from basic installation through advanced customization techniques. The combination of Arch's cutting-edge packages, AMD's excellent open-source graphics drivers, Hyprland's modern Wayland compositor, and eww's powerful widget system creates an exceptionally capable and customizable desktop environment.

This comprehensive setup has gained significant popularity in the Linux enthusiast community due to its performance, visual appeal, and extensive customization possibilities. Unlike traditional desktop environments, this stack gives users complete control over every aspect of their interface while maintaining excellent hardware compatibility and performance.

## Prerequisites and system requirements

Before diving into eww installation, ensure your Arch Linux system meets the essential requirements. **The most critical prerequisite is having a functional Hyprland installation with amdgpu drivers properly configured**, as eww integrates deeply with both the compositor and graphics subsystem.

Your system needs a modern AMD GPU with amdgpu driver support, which includes most AMD Radeon cards from the last decade. Check driver status with `lsmod | grep amdgpu` and GPU recognition with `lspci | grep VGA`. The amdgpu driver provides excellent Wayland compatibility and performance that pairs exceptionally well with Hyprland's advanced compositor features.

Essential system packages include the complete base development tools, Rust toolchain version 1.76.0 or newer, and GTK3 with Wayland support. Install these prerequisites:

```bash
sudo pacman -S --needed base-devel git rust cargo gtk3 gtk-layer-shell pango gdk-pixbuf2 libdbusmenu-gtk3 cairo glib2 gcc-libs glibc
```

Hyprland should be installed and functional before proceeding with eww setup. Verify Hyprland works correctly with your AMD GPU by checking that hardware acceleration functions properly and multiple monitor setups display correctly if applicable.

## Installing eww on Arch Linux

The **recommended installation method for 2025 is using the eww-git AUR package**, which provides the most up-to-date features and bug fixes from active development. This approach balances stability with access to latest improvements, making it ideal for most users.

Install yay or paru if not already available:

```bash
# Install yay
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si && cd .. && rm -rf yay

# Or install paru
git clone https://aur.archlinux.org/paru.git
cd paru && makepkg -si && cd .. && rm -rf paru
```

Install eww using your preferred AUR helper:

```bash
# Recommended: Latest development version
yay -S eww-git

# Alternative options
yay -S eww          # Stable version (includes Wayland support)
yay -S eww-bin      # Pre-compiled binary
```

For building from source, which provides maximum control but requires more setup:

```bash
# Clone and build from source
git clone https://github.com/elkowar/eww.git
cd eww

# Ensure correct Rust version
export RUSTUP_TOOLCHAIN=1.76.0
rustup install 1.76.0
rustup default 1.76.0

# Build for Wayland (default, works with Hyprland)
cargo build --release

# Install binary
chmod +x target/release/eww
sudo cp target/release/eww /usr/local/bin/
```

Create the configuration directory and test the installation:

```bash
mkdir -p ~/.config/eww
echo '(defwindow test :geometry (geometry :x "50%" :y "50%" :width "200px" :height "100px" :anchor "center") "eww works!")' > ~/.config/eww/eww.yuck
eww open test
eww close test
```

## Setting up eww with Hyprland compositor

Integration between eww and Hyprland requires careful configuration of both the widget system and compositor to achieve seamless operation. **The key to successful integration lies in proper layer management, window rules, and IPC socket communication** for real-time workspace and window information.

Configure Hyprland to work optimally with eww by adding these settings to `~/.config/hypr/hyprland.conf`:

```bash
# Layer rules for eww widgets
layerrule = blur, eww
layerrule = ignorezero, eww

# Window rules for eww
windowrulev2 = float, class:eww
windowrulev2 = nofocus, class:eww
windowrulev2 = noshadow, class:eww
windowrulev2 = noborder, class:eww

# Auto-start eww with Hyprland
exec-once = eww daemon
exec-once = eww open-many bar dock

# Key bindings for eww control
bind = SUPER, B, exec, eww open-many bar dock
bind = SUPER SHIFT, B, exec, eww close-all
bind = SUPER, D, exec, eww open dashboard
```

Create workspace monitoring scripts that leverage Hyprland's IPC socket for real-time updates. These scripts enable dynamic workspace indicators and window title displays that update instantly when you switch between applications or workspaces.

Create `~/.config/eww/scripts/get-workspaces`:

```bash
#!/usr/bin/env bash
spaces() {
    WORKSPACE_WINDOWS=$(hyprctl workspaces -j | jq 'map({key: .id | tostring, value: .windows}) | from_entries')
    seq 1 10 | jq --argjson windows "${WORKSPACE_WINDOWS}" --slurp -Mc 'map(tostring) | map({id: ., windows: ($windows[.]//0)})'
}

spaces
socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
    spaces
done
```

Create `~/.config/eww/scripts/get-active-workspace`:

```bash
#!/usr/bin/env bash
hyprctl monitors -j | jq '.[] | select(.focused) | .activeWorkspace.id'

socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - |
stdbuf -o0 awk -F '>>,|,' -e '/^workspace>>/ {print $2}' -e '/^focusedmon>>/ {print $3}'
```

Make these scripts executable:

```bash
chmod +x ~/.config/eww/scripts/*
```

## Configuring amdgpu-specific considerations

AMD GPU integration with this stack provides excellent performance and compatibility with minimal additional configuration required. **The open-source amdgpu driver offers superior Wayland support compared to proprietary alternatives**, making it ideal for Hyprland and eww combinations.

Add these optimizations to your Hyprland configuration for enhanced AMD GPU performance:

```bash
# AMD GPU optimizations in ~/.config/hypr/hyprland.conf
env = LIBVA_DRIVER_NAME,radeonsi
env = WLR_DRM_NO_ATOMIC,1

# Multi-GPU systems (if using both integrated and discrete)
env = WLR_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0
```

For users running eww through uwsm (Universal Wayland Session Manager), add these environment variables to `~/.config/uwsm/env-hyprland`:

```bash
export AQ_DRM_DEVICES=/dev/dri/card1:/dev/dri/card0
export LIBVA_DRIVER_NAME=radeonsi
export WLR_DRM_NO_ATOMIC=1
```

Install additional GPU support packages for optimal performance:

```bash
sudo pacman -S vulkan-radeon mesa-utils
```

Monitor AMD GPU performance and compatibility:

```bash
# Check GPU recognition and driver loading
lspci | grep -E 'VGA|3D'
lsmod | grep amdgpu

# Verify hardware acceleration
glxinfo | grep "direct rendering"
vulkaninfo | grep deviceName

# Monitor GPU usage if needed
sudo pacman -S radeontop
radeontop
```

AMD GPUs rarely encounter specific issues with eww, but if problems arise, verify hardware acceleration works correctly and check for any kernel error messages with `dmesg | grep amdgpu`.

## Basic eww configuration and syntax

Eww uses a unique configuration approach combining **yuck (a Lisp-inspired syntax) for widget definitions and CSS/SCSS for styling**. This separation allows powerful programmatic widget creation while maintaining familiar styling approaches.

The core configuration structure revolves around three main concepts: variables for data, widgets for interface elements, and windows for display containers. Understanding these building blocks enables creation of sophisticated interface elements.

Create your main configuration file at `~/.config/eww/eww.yuck`:

```yuck
; Basic window definition
(defwindow example
  :monitor 0
  :geometry (geometry :x "50%" :y "20px" :width "400px" :height "60px" :anchor "top center")
  :stacking "fg"
  :reserve (struts :distance "60px" :side "top")
  :windowtype "dock"
  :wm-ignore false
  (example-widget))

; Widget definition with basic elements
(defwidget example-widget []
  (box :class "main-container" :orientation "h" :spacing 10
    (button :onclick "notify-send 'Hello from eww!'" :class "hello-button" "Click Me")
    (label :text "Current time: ${time}" :class "time-display")
    (scale :min 0 :max 100 :value volume :onchange "amixer sset Master {}%" :class "volume-slider")))

; Variables for dynamic content
(defpoll time :interval "1s" :initial "00:00:00" `date +%H:%M:%S`)
(defpoll volume :interval "1s" "scripts/getvol")
(deflisten music :initial "" "playerctl --follow metadata --format '{{ artist }} - {{ title }}' || true")
```

Create the corresponding stylesheet at `~/.config/eww/eww.scss`:

```scss
* {
  all: unset;
  font-family: "JetBrains Mono", monospace;
  font-size: 14px;
}

.main-container {
  background-color: rgba(0, 0, 0, 0.8);
  border-radius: 10px;
  padding: 10px 20px;
  border: 1px solid #444444;
}

.hello-button {
  background-color: #50fa7b;
  color: #000000;
  border-radius: 6px;
  padding: 8px 16px;
  font-weight: bold;
}

.hello-button:hover {
  background-color: #5af78e;
}

.time-display {
  color: #f8f8f2;
  font-weight: bold;
}

.volume-slider {
  min-width: 100px;
}

.volume-slider trough {
  background-color: rgba(255, 255, 255, 0.2);
  border-radius: 10px;
  min-height: 6px;
}

.volume-slider highlight {
  background-color: #bd93f9;
  border-radius: 10px;
}
```

Variable types include polling variables that update on intervals, listening variables that respond to external events, and magic variables that provide built-in system information. **Magic variables like EWW_CPU, EWW_RAM, and EWW_BATTERY provide instant access to system metrics without external scripts**.

Test your configuration:

```bash
eww open example
eww logs  # Check for errors
eww close example
```

## Creating and configuring widgets

Widget creation in eww follows a component-based approach where complex interfaces build from simple, reusable elements. **The most powerful widgets combine real-time system information with interactive controls and visual feedback**, creating desktop interfaces that rival traditional desktop environments.

A comprehensive system bar demonstrates advanced widget techniques:

```yuck
; System bar with multiple widget types
(defwidget bar []
  (centerbox :orientation "h"
    (workspaces)
    (window-title)
    (system-tray)))

; Workspace widget with Hyprland integration
(deflisten workspaces :initial "[]" "bash ~/.config/eww/scripts/get-workspaces")
(deflisten current_workspace :initial "1" "bash ~/.config/eww/scripts/get-active-workspace")

(defwidget workspaces []
  (eventbox :onscroll "bash ~/.config/eww/scripts/change-workspace {} ${current_workspace}" 
            :class "workspaces-widget"
    (box :space-evenly true
      (for workspace in workspaces
        (eventbox :onclick "hyprctl dispatch workspace ${workspace.id}"
          (box :class "workspace-entry ${workspace.windows > 0 ? \"occupied\" : \"empty\"} ${workspace.id == current_workspace ? \"current\" : \"\"}"
            (label :text "${workspace.id}")))))))

; Active window title
(deflisten window :initial "Desktop" "bash ~/.config/eww/scripts/get-window-title")
(defwidget window-title []
  (label :text "${window}" :limit-width 50 :class "window-title"))

; System information panel
(defwidget system-tray []
  (box :class "system-tray" :orientation "h" :spacing 8
    (cpu-widget)
    (memory-widget)
    (volume-widget)
    (battery-widget)
    (clock-widget)))

(defwidget cpu-widget []
  (eventbox :onclick "gnome-system-monitor"
    (box :class "metric cpu" :tooltip "CPU Usage: ${EWW_CPU.avg}%"
      (label :text "")
      (label :text "${round(EWW_CPU.avg, 0)}%"))))

(defwidget memory-widget []
  (eventbox :onclick "gnome-system-monitor"
    (box :class "metric memory" :tooltip "Memory Usage: ${EWW_RAM.used_mem_perc}%"
      (label :text "")
      (label :text "${round(EWW_RAM.used_mem_perc, 0)}%"))))

(defwidget volume-widget []
  (eventbox :onscroll "bash ~/.config/eww/scripts/volume-control {}"
            :onclick "pavucontrol &"
    (box :class "metric volume"
      (label :text {volume > 50 ? "🔊" : volume > 0 ? "🔉" : "🔇"})
      (label :text "${volume}%"))))

(defwidget battery-widget []
  (box :class "metric battery"
    (label :text {EWW_BATTERY.status == "Charging" ? "🔌" : EWW_BATTERY.capacity > 50 ? "🔋" : EWW_BATTERY.capacity > 20 ? "🪫" : "⚠️"})
    (label :text "${EWW_BATTERY.capacity}%")))

(defwidget clock-widget []
  (box :class "clock" :orientation "v"
    (label :class "time" :text "${formattime(EWW_TIME, \"%H:%M\")}")
    (label :class "date" :text "${formattime(EWW_TIME, \"%a %b %d\")}")))

; Main bar window
(defwindow bar
  :monitor 0
  :windowtype "dock"
  :geometry (geometry :x "0%" :y "0%" :width "100%" :height "30px" :anchor "top center")
  :reserve (struts :side "top" :distance "30px")
  :exclusive true
  (bar))
```

A system dashboard showcases advanced widget composition:

```yuck
; Comprehensive system dashboard
(defwidget dashboard []
  (box :class "dashboard" :orientation "v" :spacing 20
    (dashboard-header)
    (system-overview)
    (quick-controls)))

(defwidget dashboard-header []
  (box :class "header" :orientation "h" :space-evenly false
    (box :class "welcome" :orientation "v" :halign "start"
      (label :class "greeting" :text "Welcome back!")
      (label :class "date" :text "${formattime(EWW_TIME, \"%A, %B %d, %Y\")}"))
    (box :class "system-info" :halign "end"
      (label :text "Uptime: ${uptime}")
      (label :text "Kernel: ${kernel}"))))

(defwidget system-overview []
  (box :class "overview" :orientation "h" :spacing 15
    (circular-progress :class "cpu-circle" :value {EWW_CPU.avg} :thickness 4
      (box :orientation "v" :class "circle-content"
        (label :text "CPU" :class "circle-label")
        (label :text "${round(EWW_CPU.avg, 0)}%" :class "circle-value")))
    (circular-progress :class "memory-circle" :value {EWW_RAM.used_mem_perc} :thickness 4
      (box :orientation "v" :class "circle-content"
        (label :text "RAM" :class "circle-label")
        (label :text "${round(EWW_RAM.used_mem_perc, 0)}%" :class "circle-value")))
    (circular-progress :class "disk-circle" :value {EWW_DISK["/"].used_perc} :thickness 4
      (box :orientation "v" :class "circle-content"
        (label :text "DISK" :class "circle-label")
        (label :text "${round(EWW_DISK[\"/\"].used_perc, 0)}%" :class "circle-value")))))

(defwidget quick-controls []
  (box :class "controls" :orientation "h" :spacing 10
    (button :class "control-button terminal" :onclick "hyprctl dispatch exec [float] alacritty" "")
    (button :class "control-button files" :onclick "hyprctl dispatch exec nautilus" "")
    (button :class "control-button browser" :onclick "hyprctl dispatch exec firefox" "")
    (button :class "control-button settings" :onclick "hyprctl dispatch exec gnome-control-center" "")))

; Variables for dashboard
(defpoll uptime :interval "60s" "uptime -p | sed 's/up //'")
(defpoll kernel :interval "300s" "uname -r")

(defwindow dashboard
  :monitor 0
  :geometry (geometry :x "50%" :y "50%" :width "600px" :height "400px" :anchor "center")
  :stacking "overlay"
  (dashboard))
```

Create supporting scripts in `~/.config/eww/scripts/`:

```bash
# ~/.config/eww/scripts/getvol
#!/bin/bash
pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -1

# ~/.config/eww/scripts/volume-control
#!/bin/bash
case $1 in
    up) pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
    down) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
esac

# ~/.config/eww/scripts/change-workspace
#!/bin/bash
direction=$1
current=$2
if [[ "$direction" == "down" ]]; then
    target=$((current + 1))
elif [[ "$direction" == "up" ]]; then
    target=$((current - 1))
fi
[[ $target -ge 1 && $target -le 10 ]] && hyprctl dispatch workspace $target
```

Remember to make all scripts executable: `chmod +x ~/.config/eww/scripts/*`

## Integration with Hyprland

Deep integration between eww and Hyprland creates a cohesive desktop experience where widgets respond dynamically to window manager events. **The most powerful integrations leverage Hyprland's IPC socket system for real-time workspace tracking, window information, and compositor state changes**.

Configure automatic widget launching through Hyprland's startup system. Add these configuration blocks to ensure eww initializes properly with your desktop session:

```bash
# ~/.config/hypr/hyprland.conf - Startup configuration
exec-once = eww daemon
exec-once = sleep 2 && eww open bar  # Slight delay ensures Hyprland is ready

# Alternative: Multiple monitor setup
exec-once = eww open bar-primary --screen 0
exec-once = eww open bar-secondary --screen 1

# Essential supporting services
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = dunst  # Notification daemon
```

For reliable startup, consider creating a systemd user service:

```ini
# ~/.config/systemd/user/eww.service
[Unit]
Description=ElKowar's Wacky Widgets
Documentation=https://github.com/elkowar/eww
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Environment=PATH=/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/eww daemon --no-daemonize
ExecReload=/usr/bin/eww reload
Restart=on-failure
KillMode=mixed

[Install]
WantedBy=graphical-session.target
```

Enable with: `systemctl --user enable --now eww.service`

Advanced workspace integration requires monitoring Hyprland's socket for real-time updates. Create `~/.config/eww/scripts/get-window-title`:

```bash
#!/bin/bash
hyprctl activewindow -j | jq --raw-output .title
socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | 
stdbuf -o0 awk -F '>>|,' '/^activewindow>>/{print $3}'
```

Multi-monitor setups require careful widget positioning and monitor-specific configurations:

```yuck
; Monitor-specific widgets
(defwindow bar-primary
  :monitor 0
  :geometry (geometry :x "0%" :y "0%" :width "100%" :height "30px" :anchor "top center")
  :reserve (struts :distance "30px" :side "top")
  :windowtype "dock"
  (bar :monitor 0))

(defwindow bar-secondary  
  :monitor 1
  :geometry (geometry :x "0%" :y "0%" :width "100%" :height "30px" :anchor "top center")
  :reserve (struts :distance "30px" :side "top")
  :windowtype "dock"
  (bar :monitor 1))

; Monitor-aware workspace widget
(defwidget bar [monitor]
  (centerbox :orientation "h"
    (workspaces :monitor monitor)
    (window-title)
    (system-info)))
```

## Example configurations and popular setups

The eww community has developed numerous sophisticated configurations that serve as excellent starting points and inspiration. **These battle-tested setups demonstrate advanced techniques while providing immediately usable configurations**.

A popular minimal setup focuses on essential functionality without visual clutter:

```yuck
; Minimal but functional configuration
(defvar time_reveal false)
(defvar volume_reveal false)

(defwidget minimal-bar []
  (centerbox :orientation "h"
    (box :class "left" :halign "start"
      (workspaces-minimal))
    (box :class "center" :halign "center"
      (eventbox :onhover "eww update time_reveal=true"
                :onhoverlost "eww update time_reveal=false"
        (box :spacing 5
          (label :text "")
          (revealer :reveal time_reveal :transition "slideright"
            (label :text time)))))
    (box :class "right" :halign "end" :spacing 10
      (eventbox :onhover "eww update volume_reveal=true"
                :onhoverlost "eww update volume_reveal=false"
                :onscroll "bash ~/.config/eww/scripts/volume-control {}"
        (box :spacing 5
          (label :text "🔊")
          (revealer :reveal volume_reveal :transition "slideleft"
            (label :text "${volume}%"))))
      (battery-minimal)
      (label :text "${formattime(EWW_TIME, \"%H:%M\")}"))))

(defwidget workspaces-minimal []
  (box :class "workspaces" :spacing 2
    (for i in "[1,2,3,4,5]"
      (button :class "ws ${current_workspace == i ? \"active\" : \"\"}"
              :onclick "hyprctl dispatch workspace ${i}"
              ""))))

(defwidget battery-minimal []
  (label :text "${EWW_BATTERY.capacity}%" 
         :class "battery ${EWW_BATTERY.capacity < 20 ? \"low\" : \"\"}"
         :tooltip "Battery: ${EWW_BATTERY.capacity}% (${EWW_BATTERY.status})"))

(defwindow minimal-bar
  :monitor 0
  :windowtype "dock"
  :geometry (geometry :x "10px" :y "10px" :width "98%" :height "25px" :anchor "top center")
  :reserve (struts :side "top" :distance "35px")
  :exclusive true
  (minimal-bar))
```

A comprehensive gaming-focused setup includes performance monitoring and quick controls:

```yuck
; Gaming-oriented configuration
(defwidget gaming-bar []
  (box :class "gaming-bar" :orientation "h"
    (gaming-workspaces)
    (separator)
    (performance-monitor)
    (separator)
    (gaming-controls)
    (separator)
    (system-status)))

(defwidget gaming-workspaces []
  (box :class "workspaces gaming" :spacing 3
    (for ws in workspaces
      (button :class "workspace ${ws.focused ? \"focused\" : \"\"} ${ws.urgent ? \"urgent\" : \"\"}"
              :onclick "hyprctl dispatch workspace ${ws.id}"
              :tooltip "Workspace ${ws.id}"
              (label :text {ws.windows > 0 ? "●" : "○"})))))

(defwidget performance-monitor []
  (box :class "performance" :spacing 8
    (eventbox :tooltip "CPU: ${EWW_CPU.avg}% | Temp: ${EWW_TEMPS.CORETEMP_PACKAGE_ID_0}°C"
      (box :spacing 3
        (label :text "")
        (label :text "${round(EWW_CPU.avg, 0)}%")))
    (eventbox :tooltip "GPU: ${gpu_usage}% | VRAM: ${gpu_vram}MB"
      (box :spacing 3
        (label :text "")
        (label :text "${gpu_usage}%")))
    (eventbox :tooltip "RAM: ${round(EWW_RAM.used_mem / 1048576, 0)}MB / ${round(EWW_RAM.total_mem / 1048576, 0)}MB"
      (box :spacing 3
        (label :text "")
        (label :text "${round(EWW_RAM.used_mem_perc, 0)}%")))))

(defwidget gaming-controls []
  (box :class "controls" :spacing 3
    (button :class "control-button discord" :onclick "discord" :tooltip "Discord" "")
    (button :class "control-button steam" :onclick "steam" :tooltip "Steam" "")
    (button :class "control-button obs" :onclick "obs" :tooltip "OBS Studio" "")
    (button :class "control-button record" :onclick "bash ~/.config/eww/scripts/screen-record" :tooltip "Record" "")))

(defwidget system-status []
  (box :class "status" :spacing 8
    (network-status)
    (audio-status)
    (power-status)))

; Variables for gaming setup
(defpoll gpu_usage :interval "2s" "bash ~/.config/eww/scripts/gpu-usage")
(defpoll gpu_vram :interval "2s" "bash ~/.config/eww/scripts/gpu-vram")
(deflisten discord_status :initial "offline" "bash ~/.config/eww/scripts/discord-status")

(defwindow gaming-bar
  :monitor 0
  :windowtype "dock"
  :geometry (geometry :x "0%" :y "0%" :width "100%" :height "35px" :anchor "top center")
  :reserve (struts :side "top" :distance "35px")
  :exclusive true
  (gaming-bar))
```

## Troubleshooting common issues

Successful eww deployment often requires resolving configuration and integration challenges. **The most effective troubleshooting approach combines systematic debugging with understanding of common failure patterns** specific to the Arch + Hyprland + eww stack.

Start with basic diagnostic procedures when encountering issues:

```bash
# Essential debugging workflow
eww kill                    # Stop daemon completely
eww logs                    # Check for error messages
eww debug                   # Inspect widget structure
eww state                   # View all variable states
eww open window --debug     # Launch with verbose output
```

Configuration path and permission problems represent the most frequent initial issues. Verify configuration directory structure and file permissions:

```bash
# Check configuration structure
ls -la ~/.config/eww/
file ~/.config/eww/eww.yuck ~/.config/eww/eww.scss

# Verify script permissions
ls -la ~/.config/eww/scripts/
chmod +x ~/.config/eww/scripts/*
```

Widget positioning and layer management issues often occur with Hyprland integration. These problems typically manifest as widgets appearing in wrong locations or not responding to input correctly:

```bash
# Debug window positioning
hyprctl layers  # Check layer assignments
hyprctl clients  # Verify eww window properties

# Test window rules
hyprctl keyword windowrule "float,^(eww)$"
hyprctl keyword windowrule "nofocus,^(eww)$"
```

Compilation errors during installation usually relate to Rust version compatibility. **Eww requires Rust 1.76.0 for successful compilation of recent versions**:

```bash
# Fix Rust version issues
export RUSTUP_TOOLCHAIN=1.76.0
rustup install 1.76.0
rustup default 1.76.0

# Clean and rebuild if necessary
cargo clean
cargo build --release --no-default-features --features wayland
```

IPC socket connection problems prevent real-time workspace and window tracking. Verify Hyprland socket accessibility:

```bash
# Check Hyprland socket status
echo $HYPRLAND_INSTANCE_SIGNATURE
ls -la $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/

# Test IPC communication
hyprctl version
hyprctl workspaces
```

Performance issues typically stem from inefficient polling intervals or resource-intensive scripts. Monitor eww resource usage and optimize accordingly:

```bash
# Monitor eww performance
ps aux | grep eww
htop -p $(pgrep eww)

# Profile script execution time
time bash ~/.config/eww/scripts/script-name
```

## Performance optimization tips

Optimizing eww performance ensures responsive widgets without unnecessary system resource consumption. **The key optimization areas include intelligent polling strategies, efficient widget structures, and streamlined CSS styling** that maintains visual appeal while minimizing computational overhead.

Variable optimization provides the greatest performance impact. Configure polling intervals appropriately for different data types:

```yuck
; Optimized polling intervals
(defpoll time :interval "1s" :initial "00:00" `date +%H:%M`)          ; Frequent for clock
(defpoll weather :interval "300s" :initial "Loading..." `curl -s "wttr.in/?format=3"`)  ; Infrequent for weather
(defpoll cpu_usage :interval "2s" :run-while cpu_visible "bash ~/.config/eww/scripts/cpu")  ; Conditional polling

; Use listening variables for event-driven updates
(deflisten workspaces :initial "[]" "bash ~/.config/eww/scripts/workspace-monitor")
(deflisten volume :initial "50" "bash ~/.config/eww/scripts/volume-monitor")
```

Widget structure optimization reduces rendering complexity and improves responsiveness:

```yuck
; Efficient widget composition
(defwidget optimized-bar []
  (box :class "bar" :orientation "h"
    ; Use built-in magic variables instead of custom scripts
    (label :text "CPU: ${round(EWW_CPU.avg, 0)}%")
    (label :text "RAM: ${round(EWW_RAM.used_mem_perc, 0)}%")
    ; Cache frequently accessed calculations
    (label :text "Disk: ${disk_percent}%")))

; Pre-calculate expensive operations
(defvar disk_percent {round(EWW_DISK["/"].used_perc, 0)})
```

CSS optimization focuses on efficient selectors and minimal use of expensive visual effects:

```scss
// Optimized CSS practices
.bar {
  // Use specific selectors to avoid cascade complexity
  background-color: rgba(0, 0, 0, 0.8);
  border-radius: 6px;  // Smaller radius = better performance
  
  // Avoid expensive properties on frequently updating elements
  box-shadow: none;
  backdrop-filter: none;  // Disable for performance
}

// Minimize animation complexity
.workspace-button {
  transition: background-color 0.1s ease;  // Short, simple transitions
}

// Use hardware acceleration judiciously
.performance-critical {
  will-change: transform;  // Only when necessary
}
```

Script optimization ensures minimal external process overhead:

```bash
#!/bin/bash
# Optimized script example - cache results when appropriate
CACHE_FILE="/tmp/eww-cpu-cache"
CACHE_DURATION=2

if [[ -f "$CACHE_FILE" ]] && [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -lt $CACHE_DURATION ]]; then
    cat "$CACHE_FILE"
else
    # Use efficient commands and cache result
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print int(usage)}' | tee "$CACHE_FILE"
fi
```

## Advanced customization techniques

Advanced eww customization enables creation of sophisticated desktop interfaces that rival dedicated desktop environments. **These techniques leverage eww's full potential through dynamic widget generation, complex state management, and deep system integration**.

Dynamic widget generation using literal widgets and JSON data structures creates flexible, data-driven interfaces:

```yuck
; Dynamic widget system
(defvar widgets_config "[
  {\"type\": \"clock\", \"position\": \"right\", \"format\": \"%H:%M\"},
  {\"type\": \"cpu\", \"position\": \"left\", \"threshold\": 80},
  {\"type\": \"workspace\", \"position\": \"left\", \"count\": 6}
]")

(defwidget dynamic-bar []
  (centerbox :orientation "h"
    (box :class "left" :halign "start"
      (for widget in {widgets_config}
        (literal :content {widget.position == "left" ? 
          "(${widget.type}-widget :config '${widget}')" : ""})))
    (box :class "center" :halign "center"
      (for widget in {widgets_config}
        (literal :content {widget.position == "center" ? 
          "(${widget.type}-widget :config '${widget}')" : ""})))
    (box :class "right" :halign "end"
      (for widget in {widgets_config}
        (literal :content {widget.position == "right" ? 
          "(${widget.type}-widget :config '${widget}')" : ""})))))
```

State management for complex interactions uses variable combinations and conditional logic:

```yuck
; Advanced state management
(defvar menu_state "closed")
(defvar active_panel "none")
(defvar notification_count 0)

(defwidget stateful-interface []
  (overlay
    (main-interface)
    (revealer :reveal {menu_state != "closed"} :transition "crossfade"
      (menu-panel :type menu_state))
    (revealer :reveal {notification_count > 0} :transition "slidedown"
      (notification-indicator :count notification_count))))

(defwidget context-menu []
  (eventbox :onrightclick "eww update menu_state=${menu_state == \"context\" ? \"closed\" : \"context\"}"
    (box "Right-click for menu")))

; Complex conditional rendering
(defwidget adaptive-widget []
  (box :class "adaptive"
    {EWW_BATTERY.capacity < 20 ? 
      "(emergency-battery)" : 
      EWW_BATTERY.status == "Charging" ? 
        "(charging-indicator)" : 
        "(normal-battery)"}))
```

Multi-file configuration organization enables maintainable large-scale setups:

```yuck
; Main eww.yuck - configuration entry point
(include "./modules/variables.yuck")
(include "./modules/workspaces.yuck") 
(include "./modules/system-monitor.yuck")
(include "./modules/media-controls.yuck")
(include "./windows/bar.yuck")
(include "./windows/dashboard.yuck")
```

```yuck
; modules/workspaces.yuck - specialized workspace module
(deflisten hyprland_workspaces :initial "{}" "bash ~/.config/eww/scripts/hyprland-workspaces")

(defwidget hyprland-workspaces [monitor]
  (eventbox :onscroll "bash ~/.config/eww/scripts/workspace-scroll {} ${monitor}"
    (box :class "workspaces" :spacing 2
      (for ws in {hyprland_workspaces[monitor] ?: []}
        (workspace-button :workspace ws :monitor monitor)))))

(defwidget workspace-button [workspace monitor]
  (eventbox :onclick "hyprctl dispatch workspace ${workspace.id}"
            :onrightclick "hyprctl dispatch movetoworkspace ${workspace.id}"
    (box :class "workspace ${workspace.active ? \"active\" : \"\"} 
                          ${workspace.urgent ? \"urgent\" : \"\"}
                          ${workspace.empty ? \"empty\" : \"occupied\"}"
      (label :text {workspace.name ?: workspace.id}))))
```

## Useful resources and community configurations

The eww community provides extensive resources, documentation, and configuration examples that accelerate learning and provide inspiration for custom setups. **These community-driven resources often contain solutions to common problems and demonstrate advanced techniques not covered in official documentation**.

Essential community resources include comprehensive configuration collections and learning materials:

**Primary Resources:**
- **Official GitHub Repository**: https://github.com/elkowar/eww - Contains examples, documentation, and issue tracking
- **adi1090x/widgets**: Extensive collection of eww widget examples and complete configurations
- **Dharmx's eww guide**: Comprehensive beginner-friendly tutorial covering installation through advanced usage
- **r/unixporn**: Reddit community showcasing impressive eww configurations with source code

**Configuration Collections:**
- Search GitHub for "eww-config" to find numerous complete configurations
- Look for "dotfiles hyprland eww" repositories for integrated setups
- Check the eww repository's discussions section for community configurations

**Learning and Development Tools:**
- **Yuck Language Server**: Provides syntax highlighting and error checking for configuration files
- **GTK Inspector**: Essential for CSS debugging and widget inspection (`eww inspector`)
- **Parinfer**: Editor plugin for efficient S-expression editing in various editors

**Editor Support:**
```bash
# Vim/Neovim yuck syntax support
git clone https://github.com/elkowar/yuck.vim ~/.vim/bundle/yuck.vim

# VSCode extension
code --install-extension eww-yuck.yuck-vscode
```

For troubleshooting and community support, utilize these channels:
- GitHub issues for bug reports and feature requests
- Discord servers focused on Linux desktop customization
- r/hyprland subreddit for Hyprland-specific integration questions
- Arch Linux forums for distribution-specific issues

**Performance Monitoring Tools:**
```bash
# Install useful monitoring utilities
sudo pacman -S htop iotop nethogs radeontop

# Create monitoring script for eww performance
echo '#!/bin/bash
echo "=== EWW Performance Monitor ==="
ps aux | grep -E "(eww|PID)" | head -2
echo "Memory: $(free -h | grep Mem)"
echo "GPU: $(radeontop -d - | head -1)"' > ~/.config/eww/scripts/monitor-performance
```

This comprehensive guide provides everything needed to successfully deploy and master eww on Arch Linux with Hyprland and amdgpu drivers. The combination delivers exceptional customization capabilities, excellent performance, and a modern desktop experience that rivals any traditional desktop environment while providing complete user control over every interface element.

Remember that eww mastery develops through experimentation and iteration. Start with basic configurations, gradually add complexity, and leverage the extensive community resources available. The flexibility of this stack rewards investment in learning with a uniquely personalized and efficient desktop environment.