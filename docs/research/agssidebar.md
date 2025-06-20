Great. I’ll gather a detailed guide on setting up AGS (Aylur’s Gtk Shell) as a toggled sidebar in Hyprland on Arch Linux, focusing entirely on Wayland-native tools. The sidebar will be tailored for custom functionality like system stats, music control, and app launching.

I’ll also include configuration examples, keybind setup, performance considerations, and usage of AGS APIs. I’ll let you know as soon as it’s ready.

# Hyprland Sidebar with AGS: Installation and Configuration Guide

Installing **Aylur’s GTK Shell (AGS)** on Arch Linux and configuring it as a toggleable sidebar in **Hyprland** allows you to create a sleek, custom panel for system stats, media controls, and app launchers – all **Wayland-native** (no X11 or XWayland needed). This guide will walk you through installing AGS, setting up its configuration, creating a sidebar UI with custom widgets, and integrating it with Hyprland (including keybinds to toggle visibility). We’ll also cover styling (CSS, animations) and performance tips to ensure a smooth experience.

## 1. Installing AGS on Arch Linux

**AGS** can be easily installed on Arch via the AUR or built from source. On Arch, the AGS package is called **`aylurs-gtk-shell`** (with an optional `-git` variant for the latest dev version):

* **From AUR**: Use an AUR helper (like `yay` or `paru`) to install. For example:

  ```bash
  yay -S aylurs-gtk-shell    # or use aylurs-gtk-shell-git for the bleeding-edge
  ```

  This will fetch AGS and all needed dependencies (GTK, layer-shell libraries, GJS, etc.). The AUR package ensures you don’t need to use `pip` or any Python modules – all components are provided via system packages.

* **From Source (GitHub)**: First, install the required build dependencies: TypeScript, Node/NPM, Meson build system, GJS (Gnome JavaScript), GTK3 (or GTK4), GTK Layer Shell, and various GNOME libs for system integration (Bluetooth, UPower, NetworkManager, etc.). On Arch, the dependencies can be installed with pacman:

  ```bash
  sudo pacman -S typescript npm meson gjs gtk3 gtk-layer-shell \
               gnome-bluetooth-3.0 upower networkmanager \
               gobject-introspection libdbusmenu-gtk3 libsoup3
  ```

  Then clone and build AGS:

  ```bash
  git clone --recursive https://github.com/Aylur/ags.git  
  cd ags  
  npm install               # install Astal (AGS libraries) and TypeScript types  
  meson setup build         # configure the build  
  meson install -C build    # build and install AGS  
  ```

  This will place the `ags` executable in your system (e.g. under `/usr/bin/ags`). Once installed, you can verify by running `ags --help` to see available commands.

**Note:** AGS v2 (latest major version) is a **scaffolding tool for Astal**, meaning the `ags` binary mainly helps you create and run widget projects, while the actual functionality resides in the Astal libraries. If you were using an older AGS v1 config, be aware that v2 introduced breaking changes and a new project structure. In this guide we will use the latest AGS v2 approach.

## 2. Initial Setup: AGS Configuration Project Structure

After installing, the next step is to set up your AGS configuration (essentially a project) which will define the sidebar’s behavior and appearance. AGS uses **TypeScript/JavaScript** (running on GJS) to declaratively define GTK widgets and windows.

**Initialize the AGS project**: Run the `ags init` command to scaffold a config project. By default, AGS will create the project in `~/.config/ags` unless you specify another directory. For example:

```bash
ags init --gtk 3
```

This will set up a basic configuration using GTK3 (you can use `--gtk 4` for GTK4 if desired). The initializer generates a template with a simple bar widget, which we will adapt into a sidebar. The created file structure (`~/.config/ags/`) includes files like:

```plaintext
~/.config/ags/
├── widget/Bar.tsx       # Example bar widget (we will modify or replace this)
├── app.ts              # Main entry point for AGS (starts the app)
├── style.scss          # Styles (CSS/SCSS) for theming the widgets
├── env.d.ts            # Type definitions for AGS/Astal
├── package.json, tsconfig.json  # Project config files for TypeScript
└── @girs/ and node_modules/    # Support files (GObject Introspection types, etc.)
```

Key files to note:

* **`app.ts`** – The entry point script. Here you typically call `App.start()` to launch your widget windows. In AGS v2, you define a `main()` function (or JSX markup) inside `App.start` which returns the windows to create, and optionally a `requestHandler` for IPC (not needed for our purposes).
* **`widget/Bar.tsx`** – An example widget (bar) provided by the template. It demonstrates how to create a panel with some basic widgets. We can use this as a starting point for our sidebar, renaming or modifying it as needed (for example, call it `Sidebar.tsx`).
* **`style.scss`** – A Sass/SCSS stylesheet where you can define custom CSS for your widgets (colors, fonts, transparency, etc.). This will be automatically applied by AGS when it runs (AGS uses `dart-sass` to compile SCSS to CSS at runtime or bundling).
* **TypeScript config files** (`tsconfig.json`, `env.d.ts`) – These set up the TypeScript environment. You usually don’t need to edit these much, except if you want to allow pure JS (by setting `"allowJs": true`) or tweak type checking. They mainly ensure you have auto-completion and type definitions for GTK and AGS APIs in your editor.

At this point, you can test that AGS is working by running `ags run` in the project directory (or simply `ags run` if you used the default `~/.config/ags`). This should launch the example widget (which by default might be a top bar). If nothing visible happens, don’t worry – the template bar may anchor to the top of the screen and could be a thin bar. We’ll be configuring our own sidebar next.

## 3. Designing the Sidebar Layout with AGS

Now the fun part: creating a **sidebar panel** that will appear on demand. Our goal is a vertical panel on the side of the screen (e.g. left side) that is normally hidden and can be toggled with a keybind. We will configure an AGS **Window** widget for the sidebar and populate it with various modules (system stats, media, launcher).

**Window placement and properties:** AGS uses `gtk-layer-shell` under the hood to create desktop widgets that can sit on a specific layer in the Wayland compositor. To make a sidebar on the left edge, we anchor a Window to the left, as well as top and bottom so that it spans the full height. For example, in the config (TypeScript code) you might do something like:

```ts
// In widget/Sidebar.tsx (or Bar.tsx modified):
const sidebarWindow = Widget.Window({
    name: "sidebar",
    anchor: ["left", "top", "bottom"],  // Pin to left side, full height
    child: Widget.Box({
        vertical: true,
        children: [
            // ... (we will add child widgets here for each module)
        ]
    })
});
```

This creates a window named "sidebar" anchored to the left edge (and spanning from top to bottom). The `Widget.Box({ vertical: true, ... })` acts as a container to stack our sidebar elements vertically. By default, such a Window will appear on the **layer-shell** layer (so it’s not a normal tiling window). We typically do **not** want the sidebar to reserve space when it’s visible (since it’s toggled and should overlay on top of our desktop). To achieve that, we can ensure it has **no exclusive zone**. In AGS v2 (Astal), this is done by setting the window’s *exclusivity* to "ignore". For instance, using Astal constants it would be: `exclusivity: Astal.Exclusivity.IGNORE`. This tells the layer-shell to not push other windows aside. In practice, the default for an overlay panel is to not reserve space unless you explicitly request it, so our sidebar will just float above the desktop when shown.

**Window size**: By anchoring left+top+bottom without anchoring the right, the sidebar’s width will be determined by its content or explicit size. You might want to set a fixed width for the sidebar. This can be done via CSS or properties. An easy way is to give the Window (or its Box) a minimum width. For example, in CSS you could target the window by name or class and set `min-width: 300px;` (for a 300px wide sidebar). In the AGS template, you can assign a CSS class or the `name` property to the Window and then style that in `style.scss`. For instance:

```ts
Widget.Window({
    name: "sidebar",
    className: "sidebar",  // assign a CSS class
    anchor: ["left","top","bottom"],
    child: ...
});
```

And in **style.scss**:

```css
window.sidebar {
  min-width: 300px;
  max-width: 300px;
  background-color: #222c;        /* semi-transparent background, e.g., #222 with opacity */
  border-radius: 10px 0 0 10px;   /* rounded corners on the right side */
}
```

This ensures the sidebar is 300px wide and slightly transparent. If Hyprland’s blur is enabled, a semi-transparent background will allow background blur (more on blur below). You can also use the CSS to add shadows, adjust padding, etc., to get a nice appearance. AGS widgets inherit from GTK, so any CSS properties that apply to GTK widgets can be used.

**Layer and blur**: Since AGS uses `gtk-layer-shell`, the sidebar might be on a special layer (often “overlay” or “top”). Hyprland’s blur settings by default might not blur layer-shell windows unless configured. If you want a blurred frosted-glass effect for the sidebar, make sure Hyprland’s config enables blur for that layer or window. For example, you can add a Hyprland **window rule** to target AGS by its window class or title. AGS windows typically have the GTK application name `gtk-layer-shell` (or a custom name if set). A rule like the following in `hyprland.conf` can enable blur for layer-shell surfaces:

```
layerrule = blur, gtk-layer-shell
```

However, it may be necessary to use the specific window name/class of your sidebar. You can run `hyprctl layers` when the sidebar is visible to identify its exact title. One user noted that using the actual widget name was needed for blur to apply. So, if your sidebar window’s name is “sidebar”, Hyprland might see it as such – then use:

```
windowrule = blur, class:^(sidebar)$
```

(for example) to blur it. In summary: **enable blur in Hyprland**, give your sidebar some transparency via CSS, and add a rule to blur that window.

## 4. Adding Sidebar Modules and Widgets (Wayland-Native)

With the sidebar window defined, we can populate it with various **modules**: e.g. system status indicators, media controls, and an application launcher. AGS provides a rich API with **built-in services** to retrieve system information and control things (all via Wayland-friendly libraries or DBus, no X11 required). This means you often **don’t need external scripts** or X11 utilities for common tasks – AGS can interface directly with system components. Below, we outline how to implement some common sidebar widgets using AGS’s API and Wayland-native tools:

### a. System Statistics and Controls (Battery, Brightness, etc.)

For many system stats, AGS has built-in **Service** objects that tap into system daemons:

* **Battery**: The `battery` service (backed by UPower) provides battery percentage, charging status, and even icons. For example, you can import it in your config:

  ```ts
  const battery = await Service.import('battery');
  ```

  Then use it in a widget, like a circular progress bar or icon that updates automatically. For instance, a battery percentage indicator could be:

  ```ts
  const batteryWidget = Widget.CircularProgress({
      value: battery.bind('percent').as(p => p/100),  // bind progress to battery % [0-1]
      child: Widget.Icon({ icon: battery.bind('icon_name') })
  });
  ```

  This uses **binding** to link the CircularProgress value to `battery.percent`, and an Icon inside that dynamically shows the battery status icon (charging, discharging, etc.). Whenever the battery state changes, the widget updates (thanks to reactive binding). No external script needed – this is all via UPower signals.

* **Brightness (Backlight)**: AGS has a `backlight` service if available (or you can just use a small external tool since brightness control doesn’t rely on X). The Arch Wiki recommends using `brightnessctl` for brightness on Wayland. You could create a brightness module using a Button or Slider that calls `brightnessctl` under the hood via AGS’s utility functions. However, if AGS’s Backlight service is active (requires `gnome-bluetooth` and related libs, which the dependencies suggest), you might be able to bind to `backlight.brightness`. Alternatively, using a simple keybind or script outside AGS (as shown in ArchWiki) is an option. For a sidebar widget, a straightforward way is to include a **brightness slider**: use `Service.import('backlight')` to get brightness, then bind a `Widget.Slider` to it, similar to the audio example below.

* **Audio Volume**: The `audio` service in AGS connects to PulseAudio/PipeWire. You can get a `speaker` object from it and bind volume. For example:

  ```ts
  const { speaker } = await Service.import("audio");
  const volumeSlider = Widget.Slider({
      value: speaker.bind("volume"),               // bind slider to current volume level
      onChange: ({ value }) => speaker.volume = value  // adjust system volume on slide
  });
  ```

  This creates a volume slider that directly controls the audio volume (via PipeWire) in real time. You can also monitor mute state or output changes with this service. This approach uses PipeWire’s native interface (via GObject introspection), not X11, so it’s Wayland-friendly. If you prefer simple buttons, you could use `speaker.volume` in a Label and have +/- buttons that call something like `speaker.volume = Math.min(1, speaker.volume+0.05)` and so on. (As an aside, external CLI tools like `pamixer` or `wpctl` can also be bound to keys for volume, but AGS’s service makes it unnecessary here.)

* **Network**: AGS’s `network` service (via NetworkManager) can provide connectivity status, SSID, etc. You might display an icon or label indicating wired/wireless status. For example, `const net = await Service.import("network");` then bind `net.connected` or `net.ssid` to a Label or Icon. This way, you avoid calling `nmcli` externally, since AGS listens to NetworkManager DBus signals.

* **Other Stats (CPU, Memory, Sensors)**: These do not have built-in services in AGS, but you can still include them using **custom scripts or services** in a Wayland-safe manner. One approach is using AGS’s **polling utility** to periodically run a command or read a file:

  * For CPU usage, you could read from `/proc/stat` in an interval and compute usage, or call a lightweight tool like `grep` or `vmstat`. AGS offers `Utils.exec()` or you can use GJS’s GLib to spawn a process. For example, you might use `Widget.Label().poll(interval, () => { /* update label with new CPU% */ })` – the v1 docs show a pattern to poll values and update a widget.
  * Alternatively, write a **custom Service** in JS that uses `GLib.timeout_add()` to update its value every second. (AGS’s documentation has a section on creating custom services for such cases.)
  * **Important:** Keep such polling to a reasonable interval (e.g. 1 or 2 seconds for CPU load) to avoid performance issues. Leverage AGS’s reactive system so that when the service updates, the UI automatically refreshes.

  For GPU or other sensors, you might integrate with existing Linux tools that have DBus interfaces, or simply call CLI programs that are Wayland-agnostic (like `sensors` from lm\_sensors for temperatures, which is not X11-dependent).

In general, try to **use AGS Services instead of external scripts** wherever possible for stats. As the AGS docs note, “for most of your system, you don’t have to use external binaries to query information” because the built-in services cover common needs. This leads to cleaner, faster updates and a fully Wayland-native solution.

### b. Media Playback Controls (MPRIS Integration)

For a music player or media control widget, AGS provides the **MPRIS service**. MPRIS is a DBus interface supported by many media players (Spotify, VLC, Firefox, etc.) to report track info and accept control commands. AGS’s `mpris` service can listen for any active player and allow control. Example usage:

* Import the MPRIS service:

  ```ts
  const mpris = await Service.import("mpris");
  ```

  This gives you access to properties like `mpris.title`, `mpris.artist`, etc., of the currently playing track (if any). It also emits signals like `"song-changed"` or `"player-added"` that you can react to.

* **Display Track Info**: You can bind a `Widget.Label` to show the song title or artist. For instance:

  ```ts
  const titleLabel = Widget.Label({
      label: mpris.bind("title")  // automatically update when title changes
  });
  const artistLabel = Widget.Label({
      label: mpris.bind("artist")
  });
  ```

  If nothing is playing, these might be empty; you can use `.as()` to format or provide a default (e.g., `.as(t => t || "No music")`).

* **Playback Controls**: The MPRIS service likely provides methods to control playback (play, pause, next, previous). In AGS v1, one could use `Service.Mpris({ player: 'spotify' })` to target a specific player or leave it generic. In AGS v2 Astal, after importing mpris, it may expose methods or you might need to call via DBus. However, an easier method is to call an external command `playerctl` (which is a Wayland-friendly CLI for MPRIS) if direct control is not obvious via AGS. For example, you could create Buttons for play/pause, next, prev that execute commands:

  ```ts
  Widget.Button({ child: Widget.Icon({ icon: "media-playback-start-symbolic" }),
                  onClick: () => GLib.spawn_command_line_async("playerctl play-pause") });
  ```

  Ensure `playerctl` is installed (it’s in Arch community repo). This approach uses no X and leverages the MPRIS interface via a CLI. If AGS’s service exposes a direct API (for instance, `mpris.playPause()`), you can use that instead – check AGS docs or source for available methods.

* **Volume Control**: You might integrate volume in the media section or use the audio slider we added earlier. MPRIS doesn’t directly handle volume (that’s through audio service), so reuse the volume widget or add simple volume up/down buttons.

* **Visuals**: You can add an album art display if you retrieve the cover image. MPRIS can sometimes give a URL to cover art. Implementing this might be advanced (requiring downloading the image and displaying it in a `Widget.DrawingArea` or GTK Image). This is optional; many users stick to text and icons for simplicity.

Overall, the media widget in the sidebar will let you see what song is playing and control it without needing an external program UI. All interactions happen via Wayland-friendly interfaces (DBus MPRIS and PipeWire).

### c. Application Launcher Module

A sidebar is a great place to put an application launcher or menu. There are two main routes here:

1. **Using AGS’s Application Service**: AGS has an `applications` service that can query installed apps (it reads .desktop files via GLib/GIO). This allows you to build a custom launcher widget. For example:

   ```ts
   const apps = await Service.import('applications');
   // You can query for apps by name or category:
   const results = apps.query("firefox");  // hypothetical usage, returns matching apps
   ```

   The `applications` service likely provides a method `.query()` that you can call to search application names. You could create a search bar (an Entry field) in AGS that on text change calls this query and then populates a list of results (maybe using a `Widget.ListBox` of Buttons for each app result). Each Button’s onClick would launch the app (the service probably has a method to launch by desktop ID, or you can use `GLib.spawn` to run `gtk-launch <desktop-file>`).

   *Example:* A simple approach is to have a static list of favorite apps: use `apps.getApps()` (if available) to retrieve app info objects, filter your favorites, and then for each create a `Widget.Button` with the app’s icon and name, launching it on click. The AGS example “Applauncher” demonstrates how to use the service; it essentially replaced the need for rofi/wofi by providing a searchable menu. If using this, keep in mind to update AGS to latest version, as some early issues (like binding `this` context in query) have been fixed in newer releases.

2. **Using an External Launcher (wofi)**: If writing a full menu in AGS feels complex, you can simply trigger an external Wayland-native launcher like **wofi**. Wofi is a dmenu/rofi alternative that runs on Wayland natively. You could bind a button in the sidebar that, when clicked, runs `wofi --show drun` (drun = desktop run, which lists applications). In Hyprland’s config, they often bind wofi to a hotkey (e.g., `bind = SUPER, F, exec, wofi --show drun` launches a app menu). For our sidebar, clicking the “App Launcher” button could just call that same command. This way, wofi’s menu appears (likely centered or where configured) and you choose an app. After launching, wofi closes and you still have your sidebar open.

   Alternatively, since the sidebar itself can be shown with a keybind, one might integrate the search field directly in it for a more cohesive look (which is the AGS applications service approach). This is more advanced but yields a unified sidebar experience (like an app drawer). If you prefer simplicity, using wofi (or **tofi**, another minimal Wayland launcher) is perfectly fine and doesn’t involve X11.

**Launching apps from AGS:** If you use AGS to launch an app (either via service or calling a command), it uses standard Linux system calls or DBus – again no X dependency. For example, the Applications service likely uses `Gio.AppInfo.launch()` under the hood to start the app, or you could use `GLib.spawn_command_line_async("myapp")`. Ensure the app is Wayland-native (most GUI apps on Arch are, but avoid explicitly X11 apps unless you have XWayland enabled). For terminal apps, you’d launch them via a terminal (e.g., a button that executes `foot vim` to open Vim in Foot terminal).

### d. Other Possible Widgets

AGS is quite powerful and can host pretty much any GTK widget. Some additional ideas for your sidebar (all doable without X11):

* **Workspaces or Window Switcher**: Using the `hyprland` service, you could list workspaces or open windows. AGS’s Hyprland integration can listen to Hyprland’s IPC for workspace changes, window titles, etc.. You could display the current workspace name/number or even a small task list of open windows. This might be similar to a dock or taskbar embedded in the sidebar.
* **System Tray**: There is a `systemtray` widget in AGS which can embed a Wayland system tray (for status icons). Note this is an experimental area since status notifiers on Wayland are evolving, but AGS does list a `System Tray` service. If enabled, it could capture icons from apps like volume control, network, etc., though many modern Wayland setups prefer standalone tray apps.
* **Clock/Calendar**: You can always use a Label to show the time (update every minute via a Poll or use the GDateTime API in GJS). AGS also has a `Widget.Calendar` which can show a pop-up calendar on click. A clock and date at the top of the sidebar can be a nice touch.
* **Logout/Power Buttons**: Since the sidebar might serve as a mini “system menu”, you can add buttons for logout, reboot, suspend, etc. These can call system commands like `systemctl poweroff` or use logind DBus if you prefer. No X involved – just CLI or DBus calls.

Feel free to arrange these modules in the Box container as you like (you can also nest Boxes or use `CenterBox`, etc., for alignment). For example, you might put user info and a picture at the top, then a separator, then system stats, then media controls, then app launcher at the bottom. GTK containers (like `Box`, `CenterBox`, `Separator`) are all available through AGS’s `Widget` API. You can also use `Widget.Overlay` or `Widget.Revealer` if you want some widgets to slide in/out on events.

## 5. Hyprland Integration: Toggling Sidebar Visibility

With the sidebar config in place, we want to toggle it on demand in Hyprland. The simplest approach is to **launch or kill the AGS process** with a key press, effectively showing or hiding the sidebar application. Since AGS is a standalone program that creates the sidebar window, toggling it can be done via a keybinding that either starts AGS (if not running) or stops it (if it’s already running).

**Hyprland keybind**: In `~/.config/hypr/hyprland.conf`, under the `binds` section, add a binding for your chosen hotkey. For example, let’s use **Super + S** (for “Sidebar”):

```
bind = SUPER, S, exec, pkill ags || ags run
```

This uses a little shell trick: `pkill ags || ags run`. When you press Super+S, Hyprland will try the `pkill ags` command first – if an AGS process is running, it will be terminated (closing the sidebar). If no AGS is running, `pkill` returns an error status, and due to the `||` (OR), the next part `ags run` executes, which launches the sidebar. In essence, one hotkey acts as a toggle: pressing it alternately closes or opens the sidebar process.

**Note:** The above works because Hyprland passes the command string to a shell. Ensure you use `bind = ... exec, ...` (not `exec-once` here, since we want it on every keypress). The reddit community confirmed this approach for toggling overlays like rofi, and it applies perfectly to AGS. If you find that the key release also triggers something, you might need to use `bindr` (release binding) depending on your key choice – but for a simple mod+key combination, `bind` is usually fine.

If you installed AGS to a custom directory or want to specify the config path, adjust the command. For example, `ags run /path/to/project` or `ags run --gtk4` if you use GTK4. But since we set up in `~/.config/ags`, simply running `ags run` from anywhere should pick up that config (it defaults to that directory as the project). If needed, you could write a small shell script to toggle and bind that instead, but the one-liner above is convenient.

**Startup consideration**: Because this sidebar is not persistent and only appears when toggled, you should **not** add it to Hyprland’s autostart (`exec-once`). You only run it via the keybind. That means after a reboot or Hyprland restart, the sidebar isn’t running until you call it. That’s expected for a toggled panel.

**Optional – keep AGS running hidden**: The toggle-by-kill method is straightforward. However, if you want a smoother animation (rather than the slight delay of re-launching AGS each time), you could keep AGS running and instead hide/show the sidebar window. For example, AGS’s `Revealer` widget could wrap your sidebar content and you toggle its visibility via some IPC or key event. This is an advanced setup: you might bind a Hyprland key to send an IPC message or write a small script that calls `agsctl` (if existed) to toggle the window. As of now, AGS doesn’t have a built-in IPC toggle that I’m aware of, so the simpler approach is process start/stop. The launch time of AGS with a small config is usually under a second, so it’s not too bad. If you do want animations, you could rely on Hyprland’s window animations – e.g., set a rule so that when the sidebar appears it slides in from left. Hyprland can animate window transitions globally (check `animation` settings in hyprland.conf).

**Hyprland window rules**: Aside from blur (covered earlier), you might add rules to refine the sidebar’s behavior:

* To ensure the sidebar is always on top of other windows (it should be, since layer-shell typically puts it above normal windows), you could use `layerrule = above, class:^(gtk-layer-shell)$` or similar. But usually, the layer is managed by the layer-shell protocol automatically.
* If you want the sidebar to be excluded from tiling or never gain focus, you could investigate Hyprland’s `windowrule` options like `floating` or `nofocus`. Typically, layer-shell surfaces are not part of tiling and might not take keyboard focus unless clicked. If you find the sidebar steals focus, consider setting `focuspolicy = mouse` for that window or simply don’t give it focusable elements.
* To prevent the sidebar from appearing on all workspaces or only a specific workspace: since it’s a layer-shell, it might show on all monitors by default or on one monitor. If you want it only on monitor 1, in the AGS Window definition you can set `monitor: 0` (for the first monitor). If you want it on all monitors, you would actually create one Window per monitor (like how top bars are duplicated) – AGS allows making multiple windows, one per monitor if you choose. For a sidebar, you might not need that, but it’s an option (e.g., if you want a sidebar on the left of each monitor). The example in AGS docs shows using a function to create a Window for each monitor.

Finally, after adding the keybind, reload Hyprland’s config (`hyprctl reload` or by saving the file if auto-reload is on). Press your chosen hotkey, and the sidebar should slide into view. Press again, and it disappears. 🎉

## 6. Theming and Performance Tips

**Styling with CSS:** AGS widgets use GTK, so theming is very flexible. In `style.scss` you can override GTK styles or define custom classes. Some tips:

* Use semi-transparent colors (with `alpha(color, 0.x)` in Sass) to create translucent effects that blend with your wallpaper. Pair this with Hyprland’s blur for a modern look.
* Add transitions or animations via CSS where possible. GTK supports some basic transitions (e.g., on hover states). If you want the sidebar contents to animate in, you could utilize the `Revealer` widget (which has a built-in animation for show/hide). For example, put your content inside a `Widget.Revealer` and toggle that revealer’s `reveal-child` property in response to a signal or keybind.
* Keep fonts and icons consistent with your system theme. You may want to set the GTK theme that AGS uses. By default it might use your system GTK theme. You can force it in code via `App.start({ gtkTheme: "YourThemeName", ... })` or ensure the environment theme is set. Many Hyprland users prefer using Adwaita or material-style themes for a cohesive look.
* Leverage **Nerd Fonts** or icon fonts for symbols. If you want custom icons (for example, a Wi-Fi symbol that changes based on strength), you can use an icon font or import SVGs. AGS’s `Widget.Icon` can load icons by name (from your icon theme), or you could use emoji and font icons in Labels.

**Animations:** Hyprland itself supports window animations. If enabled, when the AGS sidebar appears or disappears, it can animate (fade, slide, etc., depending on your Hyprland animation settings). Check Hyprland config `animation = ...` options. If you want a sliding animation specifically for the sidebar, you might need to set a special window rule. For instance, some setups define a rule to slide in certain windows from the side. If Hyprland’s built-in animations are not granular enough, using GTK Revealer as mentioned is an alternative for a slide-out effect within the sidebar.

**Performance considerations:**

* AGS is fairly lightweight, but since it’s running on GJS (GNOME’s JavaScript engine), extremely tight loops or heavy work in the config can cause hitches. Use the reactive bindings and services instead of manually polling very frequently. AGS services are event-driven where possible (e.g., listening for DBus events) and thus efficient for things like battery or network which only change occasionally.
* If you do need to poll (like for CPU usage), consider polling at a reasonable interval (e.g. 2s). AGS provides a `Utils.interval()` or `.poll()` hook to do this cleanly.
* When using images or icons, try to keep their size reasonable. An SVG icon from your icon theme is ideal (scales well and usually small). If you use photo images (like a user avatar), scale it down to the needed size to avoid unnecessary memory usage.
* **No XWayland overhead**: Because we’re only using Wayland-native interfaces, we don’t incur the cost of running XWayland for these components. This keeps your Wayland session lean. All the tools we mentioned (playerctl, brightnessctl, wofi, etc.) work natively on Wayland without X11.
* **Testing and debugging**: Run `ags run` from a terminal to see any console output or errors. AGS will print errors if, for example, a service is not available or a binding is misused. This can help optimize and fix issues. For instance, if something isn’t updating as expected, you might need to verify you used `await Service.import(...)` correctly (since these calls are async).

## 7. Final Touches

Once configured, you should have a functioning sidebar that appears with your keybind and contains widgets showing your system status and giving quick controls. Here are some final recommendations to polish the setup:

* **Hyprland Autostart**: If you want the sidebar to launch on login in a hidden state, you could start it minimized – but since it’s a toggled UI, it’s fine to only start it when needed. Avoid auto-starting it if it’s not always used, to save resources.
* **Backup Config**: Keep a copy of your `~/.config/ags` project (or put it under version control). AGS is actively developed, and updates might require migrating your config (as seen between v1 and v2). By having your config saved, you can adapt it if needed in the future.
* **Learn and Expand**: Refer to the official AGS documentation and examples for more advanced widgets. There’s a community on Reddit (`r/hyprland`) and Discord where people share their AGS setups – you can find inspiration for additional modules (notifications center, themes switcher, etc.). Since AGS uses TypeScript, you can harness logic to make your sidebar quite sophisticated (for instance, show different content based on conditions or create interactive dialogs).
* **Troubleshooting**: If a particular service doesn’t work, ensure the corresponding system service is running (e.g., `networkmanager` for network service) or that you have the needed permissions (e.g., battery info might require membership in the `power` group depending on how upower is set up). Check the Arch Wiki or AGS wiki for any platform-specific notes.

Below is an example of a Hyprland desktop using AGS as a sidebar (on the left), showing user info, system controls, and a top panel – to illustrate what’s possible:

*Example of a Hyprland setup with an AGS-powered sidebar on the left (with user avatar, stats, media controls, and app icons). The sidebar is hidden until toggled, providing a sleek, uncluttered desktop when not in use.*

By following this guide, you’ve set up a comprehensive sidebar in Hyprland with AGS, all without relying on X11 or non-native workarounds. Enjoy your new Wayland-native sidebar, and customize it further to make your Hyprland desktop truly your own!

**Sources:**

* AGS (Aylur's GTK Shell) Documentation – *Installation and configuration guides*
* Arch Linux Wiki – *Hyprland and Wayland tips (keybinds, tools)*
* Reddit / Hyprland – *Community solutions for toggling overlays and blur effects*
