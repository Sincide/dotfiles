**Plan: Implementing Aylurs' GTK Shell / Astal in Hyprland Setup**

---

### ✅ Step 1: Understand Astal and Requirements
- Research what Astal (Aylurs' shell) does and how it works.
- Check its dependencies (Rust, GTK4, LibAdwaita, etc.).
- Confirm it's compatible with Hyprland and your setup (Wayland-only).

---

### ✅ Step 2: Install Aylurs GTK Shell from AUR
- Install the AUR package: `aylurs-gtk-shell`.
- This will also pull required dependencies: `libastal-git`, `libastal-meta`, `gjs`, `dart-sass`, etc.
- No need to clone manually.

---

### ✅ Step 3: Configure Astal
- Launch Astal once to generate default config.
- Explore available modules/widgets.
- Adjust layout and appearance (e.g., panels, colors).

---

### ✅ Step 4: Integrate with Hyprland
- Autostart Astal in your Hyprland config.
- Remove or disable Waybar if it's being replaced.
- Ensure it's layered properly (above/below windows).

---

### ✅ Step 5: Sync with Dynamic Theming
- Make Astal read colors from Matugen (if possible).
- Hook into the same script used for dynamic theming.
- Use custom modules if Astal doesn’t support it out-of-the-box.

---

### ✅ Step 6: Customize Modules and UX
- Add calendar, sys info, notifications, etc.
- Rearrange for aesthetics and usability.
- Test responsiveness across all monitors.

---

### ✅ Step 7: Maintain and Update
- Rebuild or update periodically via AUR (`yay -Syu`).
- Watch for upstream changes in Astal.
- Backup your config to your dotfiles repo.

---

This plan keeps your system modular and allows swapping Astal in place of other shells like Waybar with dynamic theming support.

