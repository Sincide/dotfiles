package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Model represents the application state
type model struct {
	aiStatus       AIStatus
	performance    Performance
	resources      Resources
	wallpaper      Wallpaper
	statistics     Statistics
	activityLog    ActivityLog
	startTime      time.Time
	lastUpdate     time.Time
	updateInterval time.Duration
	waybarMode     bool
}

// Data structures for different sections
type AIStatus struct {
	OllamaService string `json:"ollama_service"`
	LlavaModel    string `json:"llava_model"`
	Phi4Model     string `json:"phi4_model"`
	ColorServer   string `json:"color_server"`
	FirefoxExt    string `json:"firefox_ext"`
	OllamaMemory  string `json:"ollama_memory"`
	ModelWarmth   string `json:"model_warmth"`
}

type Performance struct {
	LastTotal   string `json:"last_total"`
	LastAI      string `json:"last_ai"`
	LastVision  string `json:"last_vision"`
	ThemesToday int    `json:"themes_today"`
}

type Resources struct {
	Memory string `json:"memory"`
	CPU    string `json:"cpu"`
	Disk   string `json:"disk"`
}

type Wallpaper struct {
	Current string   `json:"current"`
	Recent  []string `json:"recent"`
}

type Statistics struct {
	TotalAnalyses    int    `json:"total_analyses"`
	EnhancedAnalyses int    `json:"enhanced_analyses"`
	RegularAnalyses  int    `json:"regular_analyses"`
	SuccessRate      int    `json:"success_rate"`
	AvgTime          string `json:"avg_time"`
	CacheHitRate     int    `json:"cache_hit_rate"`
}

type ActivityLog struct {
	Entries []LogEntry `json:"entries"`
}

type LogEntry struct {
	Timestamp string `json:"timestamp"`
	Message   string `json:"message"`
	Duration  string `json:"duration,omitempty"`
	Type      string `json:"type"` // "start", "step", "complete", "error"
}

// Styles for the UI
var (
	titleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("86")).
			Border(lipgloss.DoubleBorder()).
			Padding(0, 1)

	panelStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			Padding(1, 2).
			Margin(0, 1)

	headerStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("39"))

	successStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("46"))

	warningStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("226"))

	errorStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("196"))
)

// Initialize the model
func initialModel() model {
	return model{
		startTime:      time.Now(),
		lastUpdate:     time.Now(),
		updateInterval: 2 * time.Second,
		waybarMode:     false,
	}
}

// Init function - required for tea.Model interface
func (m model) Init() tea.Cmd {
	return tick()
}

// Update function - handles messages and updates
func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		case "j", "w":
			// Toggle waybar mode for testing
			m.waybarMode = !m.waybarMode
			return m, nil
		}
	case tickMsg:
		m.lastUpdate = time.Now()
		m.updateData()
		return m, tick()
	}
	return m, nil
}

// Tick message for periodic updates
type tickMsg time.Time

func tick() tea.Cmd {
	return tea.Tick(2*time.Second, func(t time.Time) tea.Msg {
		return tickMsg(t)
	})
}

// View function - renders the UI
func (m model) View() string {
	if m.waybarMode {
		return m.waybarView()
	}
	return m.dashboardView()
}

// Waybar JSON output with rich AI information
func (m model) waybarView() string {
	// Determine main display text based on system status
	var displayText string
	var iconStatus string

	if strings.Contains(m.aiStatus.OllamaService, "Running") {
		if m.performance.ThemesToday > 0 {
			iconStatus = "🧠"
			displayText = fmt.Sprintf("AI: %d themes", m.performance.ThemesToday)
		} else {
			iconStatus = "🧠"
			displayText = "AI: Ready"
		}
	} else {
		iconStatus = "⭕"
		displayText = "AI: Offline"
	}

	// Rich tooltip with all key information
	tooltip := fmt.Sprintf(
		"🧠 AI Desktop System\n"+
			"─────────────────────\n"+
			"🔧 Ollama: %s\n"+
			"🧠 Vision: %s\n"+
			"📝 Enhance: %s\n"+
			"🌈 Server: %s\n"+
			"🦊 Firefox: %s\n"+
			"💾 Memory: %s\n\n"+
			"⚡ Performance Today\n"+
			"─────────────────────\n"+
			"🎨 Themes: %d\n"+
			"👁️ Analyses: %d (%d%% success)\n"+
			"⏱️ Last Total: %s\n"+
			"🚀 Cache Hit: %d%%\n\n"+
			"💾 System Resources\n"+
			"─────────────────────\n"+
			"🖥️ CPU: %s\n"+
			"💾 RAM: %s\n"+
			"💿 Disk: %s\n\n"+
			"📊 Click to open full dashboard",
		m.aiStatus.OllamaService,
		m.aiStatus.LlavaModel,
		m.aiStatus.Phi4Model,
		m.aiStatus.ColorServer,
		m.aiStatus.FirefoxExt,
		m.aiStatus.OllamaMemory,
		m.performance.ThemesToday,
		m.statistics.TotalAnalyses,
		m.statistics.SuccessRate,
		m.performance.LastTotal,
		m.statistics.CacheHitRate,
		m.resources.CPU,
		m.resources.Memory,
		m.resources.Disk,
	)

	waybarData := map[string]interface{}{
		"text":    fmt.Sprintf("%s %s", iconStatus, displayText),
		"tooltip": tooltip,
		"class": fmt.Sprintf("ai-dashboard %s",
			func() string {
				if strings.Contains(m.aiStatus.OllamaService, "Running") {
					return "ai-active"
				}
				return "ai-inactive"
			}()),
		"percentage": m.getOverallHealth(),
	}

	jsonData, _ := json.Marshal(waybarData)
	return string(jsonData)
}

// Main dashboard view
func (m model) dashboardView() string {
	uptime := time.Since(m.startTime)
	uptimeStr := fmt.Sprintf("%02d:%02d", int(uptime.Minutes()), int(uptime.Seconds())%60)

	// Header with system explanation
	header := titleStyle.Render(fmt.Sprintf(
		"🧠 AI-Enhanced Desktop Performance Dashboard\n"+
			"🔄 Wallpaper → Vision Analysis → Theme Generation → UI Updates\n"+
			"Uptime: %s | %s",
		uptimeStr,
		time.Now().Format("15:04:05 2006-01-02"),
	))

	// Left column panels
	aiPanel := m.renderAIStatus()
	perfPanel := m.renderPerformance()
	resourcePanel := m.renderResources()

	// Middle column panels
	wallpaperPanel := m.renderWallpaper()
	statsPanel := m.renderStatistics()

	// Right column - Activity Log
	activityPanel := m.renderActivityLog()

	// Controls
	controls := panelStyle.Copy().
		Border(lipgloss.NormalBorder()).
		Render("Controls: [q]uit | [w]aybar mode | [r]eal-time logs | Ctrl+C")

	// 3-column layout
	leftColumn := lipgloss.JoinVertical(lipgloss.Left, aiPanel, perfPanel, resourcePanel)
	middleColumn := lipgloss.JoinVertical(lipgloss.Left, wallpaperPanel, statsPanel)
	rightColumn := activityPanel

	mainContent := lipgloss.JoinHorizontal(lipgloss.Top, leftColumn, middleColumn, rightColumn)

	return lipgloss.JoinVertical(lipgloss.Center,
		header,
		"",
		mainContent,
		"",
		controls,
	)
}

// Render AI Status panel
func (m model) renderAIStatus() string {
	content := fmt.Sprintf(
		"%s Ollama Service:   %s\n"+
			"   (AI model runner)\n"+
			"%s llava-llama3:8b:  %s\n"+
			"   (vision analysis model)\n"+
			"%s phi4:             %s\n"+
			"   (color enhancement model)\n"+
			"%s Color Server:     %s\n"+
			"   (API bridge for browser)\n"+
			"%s Firefox Ext:      %s\n"+
			"   (browser theme updater)\n"+
			"%s Ollama Memory:    %s",
		"🔧", m.getStatusIcon(m.aiStatus.OllamaService),
		"🧠", m.getStatusIcon(m.aiStatus.LlavaModel),
		"📝", m.getStatusIcon(m.aiStatus.Phi4Model),
		"🌈", m.getStatusIcon(m.aiStatus.ColorServer),
		"🦊", m.getStatusIcon(m.aiStatus.FirefoxExt),
		"💾", m.aiStatus.OllamaMemory,
	)

	return panelStyle.Copy().
		BorderForeground(lipgloss.Color("46")).
		Render(headerStyle.Render("🧠 AI System Status") + "\n\n" + content)
}

// Render Performance panel
func (m model) renderPerformance() string {
	content := fmt.Sprintf(
		"Last Total Time:   %s  (wallpaper→theme)\n"+
			"Last AI Time:      %s  (enhancement only)\n"+
			"Last Vision Time:  %s  (AI analysis)\n"+
			"Themes Today:      %d  (wallpaper changes)",
		m.performance.LastTotal,
		m.performance.LastAI,
		m.performance.LastVision,
		m.performance.ThemesToday,
	)

	return panelStyle.Copy().
		BorderForeground(lipgloss.Color("226")).
		Render(headerStyle.Render("⚡ Performance Metrics") + "\n\n" + content)
}

// Render Resources panel
func (m model) renderResources() string {
	content := fmt.Sprintf(
		"Memory Usage:  %s\n"+
			"CPU Usage:     %s\n"+
			"Disk Usage:    %s",
		m.resources.Memory,
		m.resources.CPU,
		m.resources.Disk,
	)

	return panelStyle.Copy().
		BorderForeground(lipgloss.Color("39")).
		Render(headerStyle.Render("💾 System Resources") + "\n\n" + content)
}

// Render Wallpaper panel
func (m model) renderWallpaper() string {
	content := fmt.Sprintf("Current: %s (auto-themed)\n\n", m.wallpaper.Current)

	content += "Recent changes:\n"
	for _, recent := range m.wallpaper.Recent {
		if recent != "" {
			content += fmt.Sprintf("  %s\n", recent)
		}
	}

	if len(m.wallpaper.Recent) == 0 {
		content += "  No recent changes\n"
	}

	content += "\n💡 How AI Theming Works:\n" +
		"• Every wallpaper → AI Enhancement (fast)\n" +
		"• New image → Vision Analysis (detailed)\n" +
		"• Smart caching saves time & resources"

	return panelStyle.Copy().
		BorderForeground(lipgloss.Color("213")).
		Render(headerStyle.Render("🎨 Wallpaper History") + "\n\n" + content)
}

// Render Statistics panel
func (m model) renderStatistics() string {
	content := fmt.Sprintf(
		"AI Analyses:      %d total (%d%% success)\n"+
			"Enhanced (new):   %d analyses (8-9s each)\n"+
			"Cached (fast):    %d analyses (0.1s each)\n"+
			"Cache Hit Rate:   %d%% (reused results)\n"+
			"Average Time:     %s per analysis\n"+
			"\nSmart Caching: Heavy AI runs once\n"+
			"per wallpaper, then uses cache",
		m.statistics.TotalAnalyses,
		m.statistics.SuccessRate,
		m.statistics.EnhancedAnalyses,
		m.statistics.RegularAnalyses,
		m.statistics.CacheHitRate,
		m.statistics.AvgTime,
	)

	return panelStyle.Copy().
		BorderForeground(lipgloss.Color("86")).
		Render(headerStyle.Render("📊 AI Statistics") + "\n\n" + content)
}

// Render Activity Log panel
func (m model) renderActivityLog() string {
	content := ""

	if len(m.activityLog.Entries) == 0 {
		content = "🔍 Waiting for wallpaper changes...\n\n" +
			"When you change wallpapers, you'll see:\n" +
			"• File detection & analysis start\n" +
			"• AI vision processing steps\n" +
			"• Color extraction timing\n" +
			"• Theme generation progress\n" +
			"• Firefox CSS updates\n" +
			"• Desktop theme application\n" +
			"• Total completion time\n\n" +
			"💡 Each step shows duration for\n" +
			"   performance optimization"
	} else {
		// Show last 12-15 log entries (fit in panel)
		maxEntries := 15
		startIdx := 0
		if len(m.activityLog.Entries) > maxEntries {
			startIdx = len(m.activityLog.Entries) - maxEntries
		}

		for i := startIdx; i < len(m.activityLog.Entries); i++ {
			entry := m.activityLog.Entries[i]

			// Format based on entry type
			switch entry.Type {
			case "start":
				content += fmt.Sprintf("🚀 %s %s\n", entry.Timestamp, entry.Message)
			case "step":
				if entry.Duration != "" {
					content += fmt.Sprintf("  ⚡ %s (%s)\n", entry.Message, entry.Duration)
				} else {
					content += fmt.Sprintf("  🔄 %s\n", entry.Message)
				}
			case "complete":
				content += fmt.Sprintf("✅ %s (%s)\n", entry.Message, entry.Duration)
			case "error":
				content += fmt.Sprintf("❌ %s\n", entry.Message)
			default:
				content += fmt.Sprintf("   %s %s\n", entry.Timestamp, entry.Message)
			}
		}
	}

	// Add model warmth status right under the header
	warmthStatus := fmt.Sprintf("🌡️ Model: %s\n", m.aiStatus.ModelWarmth)

	return panelStyle.Copy().
		BorderForeground(lipgloss.Color("196")).
		Width(45).
		Height(25).
		Render(headerStyle.Render("📝 Real-time Activity Log") + "\n" + warmthStatus + "\n" + content)
}

// Helper functions
func (m model) getStatusIcon(status string) string {
	switch {
	case strings.Contains(status, "Running") || strings.Contains(status, "Active") || strings.Contains(status, "Loaded"):
		return successStyle.Render("✅ " + status)
	case strings.Contains(status, "Available") || strings.Contains(status, "Ready"):
		return warningStyle.Render("🟡 " + status)
	default:
		return errorStyle.Render("❌ " + status)
	}
}

func (m model) getOverallHealth() int {
	health := 0
	if strings.Contains(m.aiStatus.OllamaService, "Running") {
		health += 25
	}
	if strings.Contains(m.aiStatus.ColorServer, "Active") {
		health += 25
	}
	if m.performance.ThemesToday > 0 {
		health += 25
	}
	if m.statistics.SuccessRate > 80 {
		health += 25
	}
	return health
}

// Data collection functions
func (m *model) updateData() {
	m.updateAIStatus()
	m.updatePerformance()
	m.updateResources()
	m.updateWallpaper()
	m.updateStatistics()
	m.updateActivityLog()
}

func (m *model) updateAIStatus() {
	// Check Ollama service
	if output, err := exec.Command("pgrep", "-x", "ollama").Output(); err == nil && len(output) > 0 {
		m.aiStatus.OllamaService = "Running"

		// Check models
		if output, err := exec.Command("ollama", "ps").Output(); err == nil {
			loaded := string(output)
			if strings.Contains(loaded, "llava-llama3") {
				m.aiStatus.LlavaModel = "Loaded"
				m.aiStatus.ModelWarmth = "🔥 Warm (3-4s)"
			} else {
				m.aiStatus.LlavaModel = "Available"
				m.aiStatus.ModelWarmth = "❄️ Cold (8-9s load)"
			}
			if strings.Contains(loaded, "phi4") {
				m.aiStatus.Phi4Model = "Loaded"
			} else {
				m.aiStatus.Phi4Model = "Available"
			}
		} else {
			m.aiStatus.ModelWarmth = "❄️ Cold (8-9s load)"
		}

		// Get memory usage
		if pid := strings.TrimSpace(string(output)); pid != "" {
			if memOutput, err := exec.Command("ps", "-p", pid, "-o", "rss=").Output(); err == nil {
				if memStr := strings.TrimSpace(string(memOutput)); memStr != "" {
					if mem, err := strconv.Atoi(memStr); err == nil {
						m.aiStatus.OllamaMemory = fmt.Sprintf("%.1fMB", float64(mem)/1024)
					}
				}
			}
		}
	} else {
		m.aiStatus.OllamaService = "Stopped"
		m.aiStatus.LlavaModel = "Not loaded"
		m.aiStatus.Phi4Model = "Not loaded"
		m.aiStatus.OllamaMemory = "0MB"
		m.aiStatus.ModelWarmth = "🔌 Offline"
	}

	// Check color server
	if output, err := exec.Command("curl", "-s", "--max-time", "1", "http://localhost:8080/ai-colors").Output(); err == nil && len(output) > 0 {
		m.aiStatus.ColorServer = "Active"
	} else {
		m.aiStatus.ColorServer = "Stopped"
	}

	// Check Firefox and extension status
	if output, err := exec.Command("pgrep", "firefox").Output(); err == nil && len(output) > 0 {
		// Firefox is running, check if color server is responding (indicates extension working)
		if m.aiStatus.ColorServer == "Active" {
			m.aiStatus.FirefoxExt = "Active"
		} else {
			m.aiStatus.FirefoxExt = "Ready"
		}
	} else {
		m.aiStatus.FirefoxExt = "Not Running"
	}
}

func (m *model) updatePerformance() {
	logPath := "/tmp/wallpaper-theme-optimized.log"

	// Get last total time
	if output, err := exec.Command("bash", "-c", fmt.Sprintf("grep 'completed in' %s | tail -1", logPath)).Output(); err == nil {
		re := regexp.MustCompile(`(\d+\.?\d*)s`)
		if match := re.FindStringSubmatch(string(output)); len(match) > 1 {
			m.performance.LastTotal = match[0]
		}
	}

	// Get themes today count - count all theme changer starts (logs reset daily)
	if output, err := exec.Command("bash", "-c", fmt.Sprintf("grep -c 'Theme Changer.*Started' %s", logPath)).Output(); err == nil {
		if count, err := strconv.Atoi(strings.TrimSpace(string(output))); err == nil {
			m.performance.ThemesToday = count
		}
	}

	// Get AI pipeline timing
	aiLogPath := "/tmp/ai-pipeline-output.log"
	if output, err := exec.Command("bash", "-c", fmt.Sprintf("grep 'completed in' %s | tail -1", aiLogPath)).Output(); err == nil {
		re := regexp.MustCompile(`(\d+\.?\d*)s`)
		if match := re.FindStringSubmatch(string(output)); len(match) > 1 {
			m.performance.LastAI = match[0]
		}
	}

	// Get vision timing
	visionLogPath := "/tmp/vision-analyzer.log"
	if output, err := exec.Command("bash", "-c", fmt.Sprintf("grep 'completed in' %s | tail -1", visionLogPath)).Output(); err == nil {
		re := regexp.MustCompile(`(\d+\.?\d*)s`)
		if match := re.FindStringSubmatch(string(output)); len(match) > 1 {
			m.performance.LastVision = match[0]
		}
	}
}

func (m *model) updateResources() {
	// Memory usage
	if output, err := exec.Command("free", "-h").Output(); err == nil {
		lines := strings.Split(string(output), "\n")
		for _, line := range lines {
			if strings.HasPrefix(line, "Mem:") {
				parts := strings.Fields(line)
				if len(parts) >= 3 {
					m.resources.Memory = fmt.Sprintf("%s/%s", parts[2], parts[1])
				}
				break
			}
		}
	}

	// CPU usage
	if output, err := exec.Command("bash", "-c", "top -bn1 | head -3 | /usr/bin/grep '%Cpu'").Output(); err == nil {
		re := regexp.MustCompile(`(\d+\.?\d*)\s+us`)
		if match := re.FindStringSubmatch(string(output)); len(match) > 1 {
			m.resources.CPU = match[1] + "%"
		}
	}

	// Disk usage
	if output, err := exec.Command("df", "-h", "/").Output(); err == nil {
		lines := strings.Split(string(output), "\n")
		if len(lines) > 1 {
			parts := strings.Fields(lines[1])
			if len(parts) >= 5 {
				m.resources.Disk = parts[4]
			}
		}
	}
}

func (m *model) updateWallpaper() {
	// Current wallpaper
	wallpaperFile := filepath.Join(os.Getenv("HOME"), ".config/dynamic-theming/last-wallpaper")
	if data, err := os.ReadFile(wallpaperFile); err == nil {
		path := strings.TrimSpace(string(data))
		if path != "" {
			m.wallpaper.Current = filepath.Base(path)
		}
	}

	// Recent changes
	logPath := "/tmp/wallpaper-theme-optimized.log"
	if output, err := exec.Command("bash", "-c", fmt.Sprintf("grep 'Setting wallpaper:' %s | tail -5", logPath)).Output(); err == nil {
		lines := strings.Split(strings.TrimSpace(string(output)), "\n")
		m.wallpaper.Recent = make([]string, 0, 5)

		for _, line := range lines {
			if line != "" {
				// Extract timestamp and wallpaper name
				re := regexp.MustCompile(`\[[\d.]+\] ([\d:]+).*Setting wallpaper: ([^\s]+)`)
				if match := re.FindStringSubmatch(line); len(match) > 2 {
					entry := fmt.Sprintf("%s → %s", match[1], filepath.Base(match[2]))
					m.wallpaper.Recent = append(m.wallpaper.Recent, entry)
				}
			}
		}
	}
}

func (m *model) updateStatistics() {
	visionLogPath := "/tmp/vision-analyzer.log"

	// Total analyses
	if output, err := exec.Command("bash", "-c", fmt.Sprintf("grep -c 'Vision analysis completed' %s", visionLogPath)).Output(); err == nil {
		if countStr := strings.TrimSpace(string(output)); countStr != "" {
			if count, err := strconv.Atoi(countStr); err == nil {
				m.statistics.TotalAnalyses = count
			}
		}
	}

	// Success rate calculation
	if m.statistics.TotalAnalyses > 0 {
		failedOutput, _ := exec.Command("bash", "-c", fmt.Sprintf("grep -c 'Vision analysis failed' %s 2>/dev/null || echo 0", visionLogPath)).Output()
		failed := 0
		if failedStr := strings.TrimSpace(string(failedOutput)); failedStr != "" {
			if f, err := strconv.Atoi(failedStr); err == nil {
				failed = f
			}
		}
		success := m.statistics.TotalAnalyses - failed
		m.statistics.SuccessRate = (success * 100) / m.statistics.TotalAnalyses
	}

	// Cache hit rate - updated to look for actual cache messages
	logPath := "/tmp/wallpaper-theme-optimized.log"

	// Count cache hits
	if output, err := exec.Command("bash", "-c", fmt.Sprintf("grep -c 'Using cached analysis' %s 2>/dev/null || echo 0", logPath)).Output(); err == nil {
		if hits, err := strconv.Atoi(strings.TrimSpace(string(output))); err == nil {
			// Count cache misses (new AI analysis)
			if output, err := exec.Command("bash", "-c", fmt.Sprintf("grep -c 'No cache found, running full analysis' %s 2>/dev/null || echo 0", logPath)).Output(); err == nil {
				if misses, err := strconv.Atoi(strings.TrimSpace(string(output))); err == nil {
					total := hits + misses
					if total > 0 {
						m.statistics.CacheHitRate = (hits * 100) / total
					}

					// Update enhanced vs regular analysis counts
					m.statistics.EnhancedAnalyses = misses // New AI analyses
					m.statistics.RegularAnalyses = hits    // Cached analyses (fast)
					m.statistics.TotalAnalyses = total
				}
			}
		}
	}
}

func (m *model) updateActivityLog() {
	// Read activity log from AI theming system
	logPath := filepath.Join(os.Getenv("HOME"), ".cache/matugen/activity.log")

	if _, err := os.Stat(logPath); os.IsNotExist(err) {
		// Create example entries for demonstration if no log exists yet
		if len(m.activityLog.Entries) == 0 {
			m.activityLog.Entries = []LogEntry{
				{
					Timestamp: time.Now().Format("15:04:05"),
					Message:   "System ready for wallpaper changes",
					Type:      "start",
				},
			}
		}
		return
	}

	// Read new log entries (in production, this would read incremental changes)
	file, err := os.Open(logPath)
	if err != nil {
		return
	}
	defer file.Close()

	var newEntries []LogEntry
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		// Parse log line format: [HH:MM:SS] TYPE: MESSAGE (DURATION)
		// Example: [14:23:45] step: Vision model processing (1.2s)
		re := regexp.MustCompile(`\[(\d{2}:\d{2}:\d{2})\]\s+(\w+):\s+(.+?)(?:\s+\(([^)]+)\))?$`)
		matches := re.FindStringSubmatch(line)

		if len(matches) >= 4 {
			entry := LogEntry{
				Timestamp: matches[1],
				Type:      matches[2],
				Message:   matches[3],
			}
			if len(matches) > 4 && matches[4] != "" {
				entry.Duration = matches[4]
			}
			newEntries = append(newEntries, entry)
		}
	}

	// Replace with new entries (or append in real implementation)
	if len(newEntries) > 0 {
		m.activityLog.Entries = newEntries
	}

	// Keep only last 50 entries to prevent memory bloat
	if len(m.activityLog.Entries) > 50 {
		m.activityLog.Entries = m.activityLog.Entries[len(m.activityLog.Entries)-50:]
	}
}

// Main function
func main() {
	// Check for waybar mode
	if len(os.Args) > 1 && os.Args[1] == "--waybar" {
		m := initialModel()
		m.waybarMode = true
		m.updateData()
		fmt.Print(m.waybarView())
		return
	}

	// App can now run from any directory

	// Initialize and run the TUI
	m := initialModel()
	m.updateData() // Initial data load

	p := tea.NewProgram(m, tea.WithAltScreen())

	if _, err := p.Run(); err != nil {
		log.Fatal(err)
	}
}
