// A minimalist, self-contained TUI application launcher and wallpaper
// selector for Hyprland, written in Go. Now with chafa previews.
//
// Inspired by fastlauncher and designed to have minimal external dependencies.
//
// Usage:
//  1. Build the program: go build -o launcher .
//  2. Run it:
//     ./launcher launch     # To launch an application
//     ./launcher wall       # To select and set a wallpaper
//
// Dependencies:
//   - Go 1.16+ compiler
//   - `swww` for wallpaper setting (https://github.com/Horus645/swww)
//   - `stty` command (standard on most Linux systems)
//   - `chafa` for wallpaper previews (sudo pacman -S chafa)
package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"sort"
	"strings"
	"syscall"
	"time"
)

// --- ANSI Escape Codes for TUI Rendering ---
const (
	hideCursor   = "\033[?25l"
	showCursor   = "\033[?25h"
	clearScreen  = "\033[2J"
	cursorToHome = "\033[H"
	resetColor   = "\033[0m"
	invertColor  = "\033[7m"
)

// --- Configuration ---
var (
	appDirs        = []string{"/usr/share/applications", "/.local/share/applications"}
	wallpaperDir   = "dotfiles/assets/wallpapers"
	chafaAvailable = false
)

// Item represents a generic selectable entry in the TUI.
type Item struct {
	Name     string
	Exec     string
	IsRandom bool // Replaced IsVegas
}

// getHomeDir safely gets the user's home directory.
func getHomeDir() string {
	usr, err := user.Current()
	if err != nil {
		log.Fatalf("Could not get current user: %v", err)
	}
	return usr.HomeDir
}

// checkChafa sees if the chafa command is in the user's PATH.
func checkChafa() {
	_, err := exec.LookPath("chafa")
	if err == nil {
		chafaAvailable = true
	}
}

// detectCategory detects wallpaper category from file path for theme switching
func detectCategory(wallpaperPath string) string {
	if strings.Contains(wallpaperPath, "/space/") {
		return "space"
	} else if strings.Contains(wallpaperPath, "/nature/") {
		return "nature"
	} else if strings.Contains(wallpaperPath, "/gaming/") {
		return "gaming"
	} else if strings.Contains(wallpaperPath, "/minimal/") {
		return "minimal"
	} else if strings.Contains(wallpaperPath, "/dark/") {
		return "dark"
	} else if strings.Contains(wallpaperPath, "/abstract/") {
		return "abstract"
	}
	return "minimal" // Safe fallback
}

// applyDynamicTheme applies theme based on wallpaper category using the existing theme system
func applyDynamicTheme(wallpaperPath, category string) {
	homeDir := getHomeDir()
	themeSwitcher := filepath.Join(homeDir, "dotfiles/scripts/theming/dynamic_theme_switcher.sh")

	// Check if theme switcher exists
	if _, err := os.Stat(themeSwitcher); os.IsNotExist(err) {
		fmt.Printf("⚠️  Theme switcher not found, using matugen fallback...\n")
		fallbackMatugen(wallpaperPath)
		return
	}

	fmt.Printf("🎨 Applying %s theme...\n", category)
	cmd := exec.Command("bash", themeSwitcher, "apply", wallpaperPath)

	if err := cmd.Run(); err != nil {
		fmt.Printf("⚠️  Theme switching failed: %v\n", err)
		fmt.Printf("🔄 Trying matugen fallback...\n")
		fallbackMatugen(wallpaperPath)
	} else {
		fmt.Printf("✨ %s theme applied successfully!\n", strings.Title(category))
		fmt.Printf("🌈 Material You colors generated and applied\n")

		// Check if we should restart applications with debugging
		if os.Getenv("EVIL_LAUNCHER_KEYBIND_MODE") == "true" {
			fmt.Printf("  • Running in keybind mode - attempting restart with debug logging\n")
			restartApplicationsWithDebug()
		} else {
			// Only restart applications when run from terminal
			restartApplications()
		}
	}
}

// logToFile logs both to stdout and to debug file
func logToFile(message string) {
	fmt.Print(message)
	
	// Also log to debug file
	homeDir := getHomeDir()
	logFile := filepath.Join(homeDir, "dotfiles/logs/waybar-debug.log")
	
	file, err := os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err == nil {
		defer file.Close()
		timestamp := time.Now().Format("2006-01-02 15:04:05")
		file.WriteString(fmt.Sprintf("[%s] %s", timestamp, message))
	}
}

// restartApplicationsWithDebug - same as restartApplications but with detailed logging
func restartApplicationsWithDebug() {
	logToFile("🔄 Starting restart with debug logging...\n")
	
	// Check environment
	logToFile(fmt.Sprintf("Environment: WAYLAND_DISPLAY=%s, XDG_RUNTIME_DIR=%s\n", 
		os.Getenv("WAYLAND_DISPLAY"), os.Getenv("XDG_RUNTIME_DIR")))
	
	// Check if we're running under Wayland/Hyprland
	cmd := exec.Command("sh", "-c", "[[ \"$WAYLAND_DISPLAY\" ]] && pgrep -x Hyprland > /dev/null")
	if err := cmd.Run(); err != nil {
		logToFile(fmt.Sprintf("  ⚠️  Hyprland check failed: %v\n", err))
		return
	}
	logToFile("  ✓ Hyprland is running\n")
	
	logToFile("  • Reloading Hyprland configuration...\n")
	cmd = exec.Command("hyprctl", "reload")
	if err := cmd.Run(); err != nil {
		logToFile(fmt.Sprintf("    ⚠️  hyprctl reload failed: %v\n", err))
	} else {
		logToFile("    ✓ hyprctl reload successful\n")
	}
	
	// Check waybar before restart
	cmd = exec.Command("pgrep", "-x", "waybar")
	output, err := cmd.CombinedOutput()
	if err == nil {
		logToFile(fmt.Sprintf("  • Waybar PIDs before kill: %s", string(output)))
		logToFile("  • Killing waybar...\n")
		
		cmd = exec.Command("pkill", "waybar")
		if err := cmd.Run(); err != nil {
			logToFile(fmt.Sprintf("    ⚠️  pkill waybar failed: %v\n", err))
		} else {
			logToFile("    ✓ pkill waybar successful\n")
		}
		
		logToFile("  • Waiting 500ms...\n")
		time.Sleep(500 * time.Millisecond)
		
		// Check if waybar is actually dead
		cmd = exec.Command("pgrep", "-x", "waybar")
		output, err = cmd.CombinedOutput()
		if err == nil {
			logToFile(fmt.Sprintf("    ⚠️  Waybar still running after kill: %s", string(output)))
		} else {
			logToFile("    ✓ Waybar successfully killed\n")
		}
	} else {
		logToFile("  • No waybar processes found to kill\n")
	}
	
	// Start waybar processes completely detached from this process
	logToFile("  • Starting top Waybar (detached)...\n")
	cmd = exec.Command("sh", "-c", "nohup waybar > /dev/null 2>&1 & disown")
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true} // New process group
	if err := cmd.Run(); err != nil {
		logToFile(fmt.Sprintf("    ⚠️  Failed to start top waybar: %v\n", err))
	} else {
		logToFile("    ✓ Top waybar command executed (detached)\n")
	}
	
	// Small delay
	time.Sleep(100 * time.Millisecond)
	
	// Start bottom waybar
	logToFile("  • Starting bottom Waybar (detached)...\n")
	cmd = exec.Command("sh", "-c", "nohup waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom.css > /dev/null 2>&1 & disown")
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true} // New process group
	if err := cmd.Run(); err != nil {
		logToFile(fmt.Sprintf("    ⚠️  Failed to start bottom waybar: %v\n", err))
	} else {
		logToFile("    ✓ Bottom waybar command executed (detached)\n")
	}
	
	// Check if waybar started
	time.Sleep(1 * time.Second)
	cmd = exec.Command("pgrep", "-x", "waybar")
	output, err = cmd.CombinedOutput()
	if err == nil {
		logToFile(fmt.Sprintf("  ✓ Waybar PIDs after start: %s", string(output)))
	} else {
		logToFile("    ⚠️  No waybar processes found after start\n")
	}
	
	logToFile("🔄 Debug restart completed\n\n")
}

// restartApplications - EXACT copy from wallpaper_manager.sh
func restartApplications() {
	fmt.Printf("🔄 Reloading applications with new theme...\n")
	
	// Check if we're running under Wayland/Hyprland - EXACT same check
	cmd := exec.Command("sh", "-c", "[[ \"$WAYLAND_DISPLAY\" ]] && pgrep -x Hyprland > /dev/null")
	if cmd.Run() != nil {
		fmt.Printf("  ⚠️  Not running under Hyprland - applications won't be restarted\n")
		return
	}
	
	fmt.Printf("  • Reloading Hyprland configuration...\n")
	exec.Command("hyprctl", "reload").Run()
	
	// Restart Waybar (dual bars: top + bottom) - EXACT same logic
	cmd = exec.Command("pgrep", "-x", "waybar")
	if cmd.Run() == nil {
		fmt.Printf("  • Restarting Waybar instances...\n")
		exec.Command("pkill", "waybar").Run()
		time.Sleep(500 * time.Millisecond)
	}
	fmt.Printf("  • Starting top Waybar...\n")
	cmd1 := exec.Command("sh", "-c", "nohup waybar > /dev/null 2>&1 & disown")
	cmd1.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	cmd1.Run()
	fmt.Printf("  • Starting bottom Waybar (AMDGPU monitoring)...\n")
	cmd2 := exec.Command("sh", "-c", "nohup waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom.css > /dev/null 2>&1 & disown")
	cmd2.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	cmd2.Run()
	
	// Restart Dunst - EXACT same logic
	cmd = exec.Command("pgrep", "-x", "dunst")
	if cmd.Run() == nil {
		fmt.Printf("  • Restarting Dunst...\n")
		exec.Command("pkill", "dunst").Run()
		time.Sleep(500 * time.Millisecond)
	}
	fmt.Printf("  • Starting Dunst...\n")
	exec.Command("sh", "-c", "dunst > /dev/null 2>&1 &").Run()
	
	// Reload Kitty configurations - EXACT same
	fmt.Printf("  • Reloading Kitty configurations...\n")
	exec.Command("killall", "-USR1", "kitty").Run()
}

// Note: We no longer force-restart cursor-sensitive applications
// as this causes crashes and data loss. Applications will pick up
// the new cursor theme on their next natural launch.

// isProcessRunning checks if a process with the given name is running
func isProcessRunning(processName string) bool {
	cmd := exec.Command("pgrep", "-x", processName)
	err := cmd.Run()
	return err == nil
}

// fallbackMatugen generates colors using matugen when theme switcher fails
func fallbackMatugen(wallpaperPath string) {
	homeDir := getHomeDir()
	configPath := filepath.Join(homeDir, "dotfiles/matugen/config.toml")

	var cmd *exec.Cmd
	if _, err := os.Stat(configPath); err == nil {
		cmd = exec.Command("matugen", "image", "--config", configPath, wallpaperPath)
		fmt.Printf("🌈 Generating Material You colors with dotfiles config...\n")
	} else {
		cmd = exec.Command("matugen", "image", wallpaperPath)
		fmt.Printf("🌈 Generating Material You colors with default settings...\n")
	}

	if err := cmd.Run(); err != nil {
		fmt.Printf("⚠️  Matugen color generation failed: %v\n", err)
		fmt.Printf("💡 Install matugen for automatic color theming\n")
	} else {
		fmt.Printf("✅ Material You colors generated successfully!\n")
	}
}

// setWindowClass sets the WM_CLASS property to identify the window to Hyprland
func setWindowClass() {
	// Set terminal title for Hyprland window rules
	fmt.Printf("\033]0;Evil Launcher\007")
	// Set the terminal application ID for Wayland
	fmt.Printf("\033]1;evil-launcher\007")
}

// getDesktopApps scans for and parses .desktop files.
func getDesktopApps() []Item {
	home := getHomeDir()
	var items []Item
	seen := make(map[string]bool)
	fullAppDirs := []string{appDirs[0], home + appDirs[1]}

	for _, dir := range fullAppDirs {
		files, err := ioutil.ReadDir(dir)
		if err != nil {
			continue
		}

		for _, file := range files {
			if strings.HasSuffix(file.Name(), ".desktop") {
				path := filepath.Join(dir, file.Name())
				content, err := ioutil.ReadFile(path)
				if err != nil {
					continue
				}

				var name, execCmd, entryType string
				noDisplay := false
				inDesktopEntry := false
				scanner := bufio.NewScanner(strings.NewReader(string(content)))

				for scanner.Scan() {
					line := strings.TrimSpace(scanner.Text())
					if line == "[Desktop Entry]" {
						inDesktopEntry = true
						continue
					}
					if strings.HasPrefix(line, "[") {
						inDesktopEntry = false
					}
					if inDesktopEntry {
						if strings.HasPrefix(line, "Name=") {
							name = strings.SplitN(line, "=", 2)[1]
						}
						if strings.HasPrefix(line, "Exec=") {
							execCmd = strings.SplitN(line, "=", 2)[1]
						}
						if strings.HasPrefix(line, "Type=") {
							entryType = strings.SplitN(line, "=", 2)[1]
						}
						if strings.HasPrefix(line, "NoDisplay=true") {
							noDisplay = true
							break
						}
					}
				}

				if !noDisplay && name != "" && execCmd != "" && (entryType == "Application" || entryType == "") && !seen[name] {
					parts := strings.Fields(execCmd)
					var cleanedParts []string
					for _, part := range parts {
						if !strings.HasPrefix(part, "%") {
							cleanedParts = append(cleanedParts, part)
						}
					}
					execCmd = strings.Join(cleanedParts, " ")
					items = append(items, Item{Name: name, Exec: execCmd})
					seen[name] = true
				}
			}
		}
	}

	sort.Slice(items, func(i, j int) bool { return strings.ToLower(items[i].Name) < strings.ToLower(items[j].Name) })
	return items
}

// getWallpapers scans the configured directory for image files.
func getWallpapers() []Item {
	home := getHomeDir()
	fullPath := filepath.Join(home, wallpaperDir)
	var items []Item
	items = append(items, Item{Name: "Random Wallpaper", IsRandom: true})

	filepath.Walk(fullPath, func(path string, info os.FileInfo, err error) error {
		if err == nil && !info.IsDir() {
			ext := strings.ToLower(filepath.Ext(path))
			if ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".gif" {
				items = append(items, Item{Name: info.Name(), Exec: path})
			}
		}
		return nil
	})

	sort.Slice(items[1:], func(i, j int) bool { return strings.ToLower(items[i+1].Name) < strings.ToLower(items[j+1].Name) })
	return items
}

// getPathExecutables scans all directories in $PATH for executables
func getPathExecutables() []Item {
	var items []Item
	seen := make(map[string]bool)
	for _, dir := range filepath.SplitList(os.Getenv("PATH")) {
		files, err := ioutil.ReadDir(dir)
		if err != nil {
			continue
		}
		for _, file := range files {
			if !file.IsDir() && file.Mode()&0111 != 0 && !seen[file.Name()] {
				items = append(items, Item{Name: file.Name(), Exec: file.Name()})
				seen[file.Name()] = true
			}
		}
	}
	sort.Slice(items, func(i, j int) bool { return strings.ToLower(items[i].Name) < strings.ToLower(items[j].Name) })
	return items
}

// setTerminalMode configures the terminal for raw input.
func setTerminalMode(raw bool) {
	mode := "sane"
	if raw {
		mode = "cbreak"
	}
	cmd := exec.Command("stty", "-F", "/dev/tty", mode, "min", "1", "-echo")
	cmd.Stdin = os.Stdin
	cmd.Run()
}

// runTUI is the main loop that draws the interface and handles input.
func runTUI(items []Item, prompt, mode string, altItems []Item, altPrompt string) *Item {
	if len(items) == 0 {
		fmt.Println("No items found.")
		return nil
	}

	setWindowClass()
	setTerminalMode(true)
	defer setTerminalMode(false)

	var query string
	selectedIndex := 0
	reader := bufio.NewReader(os.Stdin)

	for {
		var filteredItems []Item
		if query == "" {
			filteredItems = items
		} else {
			lcQuery := strings.ToLower(query)
			for _, item := range items {
				if strings.Contains(strings.ToLower(item.Name), lcQuery) {
					filteredItems = append(filteredItems, item)
				}
			}
		}

		if selectedIndex < 0 {
			selectedIndex = 0
		}
		if len(filteredItems) > 0 && selectedIndex >= len(filteredItems) {
			selectedIndex = len(filteredItems) - 1
		} else if len(filteredItems) == 0 {
			selectedIndex = 0
		}

		// Drawing logic
		sttyCmd := exec.Command("stty", "size")
		sttyCmd.Stdin = os.Stdin
		out, _ := sttyCmd.Output()
		var termHeight, termWidth int
		fmt.Sscanf(string(out), "%d %d", &termHeight, &termWidth)
		if termHeight == 0 || termWidth == 0 {
			termHeight, termWidth = 24, 80 // Fallback
		}

		var screenBuf bytes.Buffer
		screenBuf.WriteString(clearScreen)
		screenBuf.WriteString(cursorToHome)
		screenBuf.WriteString(hideCursor)

		listWidth := termWidth
		showPreview := chafaAvailable && mode == "wall" && termWidth > 60
		if showPreview {
			listWidth = termWidth / 2
		}

		screenBuf.WriteString(fmt.Sprintf("%s> %s\n", prompt, query))
		screenBuf.WriteString(strings.Repeat("-", listWidth-1) + "\n")

		var listLines []string
		start := 0
		maxItems := termHeight - 3
		if maxItems < 0 {
			maxItems = 0
		}
		if selectedIndex >= maxItems {
			start = selectedIndex - maxItems + 1
		}
		end := start + maxItems
		if end > len(filteredItems) {
			end = len(filteredItems)
		}

		for i := start; i < end; i++ {
			line := filteredItems[i].Name
			if len(line) >= listWidth {
				line = line[:listWidth-1]
			}
			if i == selectedIndex {
				listLines = append(listLines, fmt.Sprintf("%s%s%s", invertColor, line, resetColor))
			} else {
				listLines = append(listLines, line)
			}
		}

		var previewLines []string
		if showPreview && len(filteredItems) > 0 {
			selectedItem := filteredItems[selectedIndex]
			previewWidth := termWidth - listWidth - 1
			previewHeight := termHeight - 1

			if selectedItem.IsRandom {
				placeholder := "   [ Random ]   "
				padding := strings.Repeat(" ", (previewWidth-len(placeholder))/2)
				for i := 0; i < previewHeight/2-1; i++ {
					previewLines = append(previewLines, "")
				}
				previewLines = append(previewLines, padding+placeholder)
			} else {
				previewCmd := exec.Command("chafa", "--size", fmt.Sprintf("%dx%d", previewWidth, previewHeight), selectedItem.Exec)
				previewOutput, err := previewCmd.CombinedOutput()
				if err != nil {
					errorMsg := fmt.Sprintf("Chafa Error: %v", err)
					previewLines = strings.Split(errorMsg, "\n")
				} else {
					previewLines = strings.Split(string(previewOutput), "\n")
				}
			}
		}

		for i := 0; i < maxItems; i++ {
			screenRow := i + 3
			if i < len(listLines) {
				screenBuf.WriteString(fmt.Sprintf("\033[%d;1H", screenRow))
				screenBuf.WriteString(listLines[i])
				screenBuf.WriteString("\033[K")
			}
			if showPreview && i < len(previewLines) {
				screenBuf.WriteString(fmt.Sprintf("\033[%d;%dH", screenRow, listWidth+2))
				screenBuf.WriteString(previewLines[i])
			}
		}

		fmt.Print(screenBuf.String())

		char, _, _ := reader.ReadRune()
		switch char {
		case '\r', '\n':
			if len(filteredItems) > 0 {
				return &filteredItems[selectedIndex]
			}
		case '\x1b':
			if reader.Buffered() >= 2 {
				reader.ReadRune()
				arrow, _, _ := reader.ReadRune()
				if arrow == 'A' && selectedIndex > 0 {
					selectedIndex--
				}
				if arrow == 'B' && selectedIndex < len(filteredItems)-1 {
					selectedIndex++
				}
			} else {
				return nil
			}
		case 127, '\b':
			if len(query) > 0 {
				query = query[:len(query)-1]
				selectedIndex = 0
			}
		case 3:
			return nil
		case '\t':
			// Tab key no longer switches modes - just ignore
		default:
			if char >= ' ' && char <= '~' {
				query += string(char)
				selectedIndex = 0
			}
		}
	}
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: ./launcher [launch|wall]")
		os.Exit(1)
	}
	mode := os.Args[1]

	var items []Item
	var prompt string
	var altItems []Item
	var altPrompt string

	if mode == "launch" {
		// Combine desktop apps and PATH executables into unified list
		desktopApps := getDesktopApps()
		pathApps := getPathExecutables()
		
		// Merge lists with desktop apps first (they're usually more relevant)
		items = append(items, desktopApps...)
		items = append(items, pathApps...)
		
		prompt = "Launch"
		altItems = nil  // No longer using alt items
		altPrompt = ""
	} else if mode == "wall" {
		checkChafa()
		items = getWallpapers()
		prompt = "Wallpaper"
		altItems = nil
		altPrompt = ""
	} else {
		fmt.Printf("Unknown mode: %s\n", mode)
		os.Exit(1)
	}

	defer setTerminalMode(false)
	defer fmt.Print(showCursor)

	selectedItem := runTUI(items, prompt, mode, altItems, altPrompt)

	fmt.Print(clearScreen, cursorToHome)

	if selectedItem != nil {
		if mode == "launch" {
			cmdParts := strings.Fields(selectedItem.Exec)
			cmd := exec.Command(cmdParts[0], cmdParts[1:]...)
			cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
			if err := cmd.Start(); err != nil {
				log.Fatalf("Failed to launch %s: %v", selectedItem.Name, err)
			}
			fmt.Printf("Launching %s...\n", selectedItem.Name)
		} else if mode == "wall" {
			var cmd *exec.Cmd
			var wallName string
			var wallpaperPath string

			if selectedItem.IsRandom {
				var wallpaperPaths []string
				for _, item := range items {
					if !item.IsRandom {
						wallpaperPaths = append(wallpaperPaths, item.Exec)
					}
				}

				if len(wallpaperPaths) > 0 {
					rand.Seed(time.Now().UnixNano())
					randomPath := wallpaperPaths[rand.Intn(len(wallpaperPaths))]
					wallpaperPath = randomPath
					cmd = exec.Command("swww", "img", randomPath)
					wallName = filepath.Base(randomPath)
				} else {
					fmt.Println("No wallpapers found to select from.")
					return
				}
			} else {
				wallpaperPath = selectedItem.Exec
				cmd = exec.Command("swww", "img", selectedItem.Exec)
				wallName = selectedItem.Name
			}

			// Set wallpaper with swww
			if err := cmd.Run(); err != nil {
				log.Fatalf("Failed to set wallpaper with swww: %v\n\nHint: Is the swww-daemon running?", err)
			}
			fmt.Printf("🖼️  Wallpaper set to %s\n", wallName)

			// Apply dynamic theme based on wallpaper category
			if wallpaperPath != "" {
				category := detectCategory(wallpaperPath)
				fmt.Printf("📂 Detected category: %s\n", category)
				applyDynamicTheme(wallpaperPath, category)
			}
		}
	}
}
