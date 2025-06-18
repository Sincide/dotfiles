**Dynamic Theming Plan with Matugen (Hyprland Setup, No GTK/Qt)**

---

### ✅ Step 1: Fix Matugen
- Ensure Matugen is installed and working.
- Confirm it can generate color themes from wallpapers.
- Check that it outputs to `~/.cache/wal/colors.json`.

---

### ✅ Step 2: Fix Fuzzel
- Use Fuzzel as a wallpaper picker.
- Integrate it to trigger Matugen after wallpaper selection.

---

### ✅ Step 3: Fix Wallpaper + Theme Sync
- Confirm that setting a wallpaper via Fuzzel runs `swww`.
- Ensure Matugen is run right after and updates `colors.json`.

---

### ✅ Step 4: Fix Hyprland
- Configure Hyprland to use colors from `colors.json`.
- Update border colors, active/inactive window colors, etc.
- Reload Hyprland config dynamically (if possible).

---

### ✅ Step 5: Fix Waybar
- Extract colors from `colors.json`.
- Update Waybar's CSS/theme file to reflect current colors.
- Reload Waybar after theme update.

---

### ✅ Step 6: Fix Kitty
- Create a `colors.conf` from Matugen output.
- Include it in Kitty's config.
- Reload Kitty config without restarting the terminal.

---

### ✅ Step 7: Fix Dunst
- Update `dunstrc` with current theme colors.
- Restart Dunst to apply changes.

---

### ✅ Step 8: Automate It All
- Write a script that:
  - Lets you select wallpaper using Fuzzel
  - Sets wallpaper with `swww`
  - Runs Matugen to generate colors
  - Updates Hyprland, Waybar, Kitty, and Dunst
- Bind this script to a Hyprland key combo for fast theme switching

