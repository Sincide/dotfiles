// Package system handles system health analysis and data parsing
package system

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"ai-system-dashboard/pkg/models"
)

const (
	// AnalysisCachePath is the default location of the system health analysis JSON
	AnalysisCachePath = "/tmp/system-health-analysis.json"
)

// Analyzer handles system health data parsing and analysis
type Analyzer struct {
	cachePath string
}

// NewAnalyzer creates a new system analyzer
func NewAnalyzer() *Analyzer {
	return &Analyzer{
		cachePath: AnalysisCachePath,
	}
}

// NewAnalyzerWithPath creates a new system analyzer with custom cache path
func NewAnalyzerWithPath(path string) *Analyzer {
	return &Analyzer{
		cachePath: path,
	}
}

// GetSystemHealth parses the system health analysis JSON and returns structured data
func (a *Analyzer) GetSystemHealth() (*models.SystemHealth, error) {
	// Check if analysis cache exists
	if _, err := os.Stat(a.cachePath); os.IsNotExist(err) {
		return nil, fmt.Errorf("no system health analysis found at %s", a.cachePath)
	}

	// Read the JSON file
	data, err := ioutil.ReadFile(a.cachePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read analysis cache: %w", err)
	}

	// Parse the JSON structure
	var rawData map[string]interface{}
	if err := json.Unmarshal(data, &rawData); err != nil {
		return nil, fmt.Errorf("failed to parse JSON: %w", err)
	}

	// Extract system health analysis section
	healthData, ok := rawData["system_health_analysis"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("invalid JSON structure: missing system_health_analysis")
	}

	// Parse overall scores
	overallScore, _ := healthData["overall_score"].(float64)
	overallStatus, _ := healthData["overall_status"].(string)
	analysisDuration, _ := healthData["analysis_duration"].(string)

	// Parse analysis duration
	duration, _ := strconv.ParseFloat(analysisDuration, 64)

	// Parse generated timestamp
	generated, _ := healthData["generated"].(string)
	lastAnalysis, _ := time.Parse("2006-01-02 15:04:05", generated)

	// Parse system profile
	profileData, _ := healthData["system_profile"].(map[string]interface{})
	profile := models.SystemProfile{
		OS:           getString(profileData, "os"),
		Desktop:      getString(profileData, "desktop"),
		Shell:        getString(profileData, "shell"),
		AIEnhanced:   getBool(profileData, "ai_enhanced"),
		LLMAvailable: getBool(profileData, "llm_available"),
	}

	// Parse individual components
	components := make(map[string]*models.Component)

	// CPU Component
	if cpuData, ok := healthData["cpu"].(map[string]interface{}); ok {
		components["cpu"] = &models.Component{
			Name:            "CPU Performance",
			Score:           getFloat(cpuData, "score"),
			Status:          getString(cpuData, "status"),
			Recommendations: getString(cpuData, "recommendations"),
			Details: models.CPUInfo{
				Model:         getString(cpuData, "model"),
				Cores:         getInt(cpuData, "cores"),
				Threads:       getInt(cpuData, "threads"),
				MaxFrequency:  getString(cpuData, "max_frequency"),
				CurrentUsage:  getString(cpuData, "current_usage"),
				Temperature:   getString(cpuData, "temperature"),
				ThermalStatus: getString(cpuData, "thermal_status"),
			},
		}
	}

	// Memory Component
	if memData, ok := healthData["memory"].(map[string]interface{}); ok {
		components["memory"] = &models.Component{
			Name:            "Memory Usage",
			Score:           getFloat(memData, "score"),
			Status:          getString(memData, "status"),
			Recommendations: getString(memData, "recommendations"),
			Details: models.MemoryInfo{
				Total:        getString(memData, "total"),
				Used:         getString(memData, "used"),
				Free:         getString(memData, "free"),
				Available:    getString(memData, "available"),
				UsagePercent: getFloat(memData, "usage_percent"),
			},
		}
	}

	// Boot Component
	if bootData, ok := healthData["boot"].(map[string]interface{}); ok {
		components["boot"] = &models.Component{
			Name:            "Boot Performance",
			Score:           getFloat(bootData, "score"),
			Status:          getString(bootData, "status"),
			Recommendations: getString(bootData, "recommendations"),
			Details: models.BootInfo{
				TotalTime:           getString(bootData, "total_time"),
				KernelTime:          getString(bootData, "kernel_time"),
				UserspaceTime:       getString(bootData, "userspace_time"),
				OptimizationApplied: getBool(bootData, "mandb_optimization_applied"),
				SlowServices:        getString(bootData, "slow_services"),
			},
		}
	}

	// Disk Component
	if diskData, ok := healthData["disk"].(map[string]interface{}); ok {
		components["disk"] = &models.Component{
			Name:            "Disk Health",
			Score:           getFloat(diskData, "score"),
			Status:          getString(diskData, "status"),
			Recommendations: getString(diskData, "recommendations"),
			Details: models.DiskInfo{
				RootUsagePercent: getInt(diskData, "root_usage_percent"),
				RootUsed:         getString(diskData, "root_used"),
				RootAvailable:    getString(diskData, "root_available"),
				PackageCacheSize: getString(diskData, "package_cache_cleanup"),
			},
		}
	}

	// GPU Component
	if gpuData, ok := healthData["gpu"].(map[string]interface{}); ok {
		components["gpu"] = &models.Component{
			Name:            "GPU Performance",
			Score:           getFloat(gpuData, "score"),
			Status:          getString(gpuData, "status"),
			Recommendations: getString(gpuData, "recommendations"),
			Details: models.GPUInfo{
				Driver:      getString(gpuData, "driver"),
				Temperature: getString(gpuData, "temperature"),
				MemoryUsage: getString(gpuData, "memory_usage"),
				PowerDraw:   getString(gpuData, "power_draw"),
			},
		}
	}

	// Package Component
	if pkgData, ok := healthData["packages"].(map[string]interface{}); ok {
		components["packages"] = &models.Component{
			Name:            "Package System",
			Score:           getFloat(pkgData, "score"),
			Status:          getString(pkgData, "status"),
			Recommendations: getString(pkgData, "recommendations"),
			Details: models.PackageInfo{
				TotalPackages:    getInt(pkgData, "total_packages"),
				ExplicitPackages: getInt(pkgData, "explicit_packages"),
				OrphanedPackages: getInt(pkgData, "orphaned_packages"),
				AURPackages:      getInt(pkgData, "aur_packages"),
				CacheCleanupSize: getString(pkgData, "cache_cleanup_available"),
			},
		}
	}

	return &models.SystemHealth{
		OverallScore:     overallScore,
		OverallStatus:    overallStatus,
		LastAnalysis:     lastAnalysis,
		AnalysisDuration: duration,
		Components:       components,
		SystemProfile:    profile,
	}, nil
}

// GetOptimizationStatus analyzes available and applied optimizations
func (a *Analyzer) GetOptimizationStatus() (*models.OptimizationStatus, error) {
	health, err := a.GetSystemHealth()
	if err != nil {
		return nil, err
	}

	var available []models.Optimization
	var applied []models.Optimization
	criticalCount := 0
	minorCount := 0

	// Check each component for optimization opportunities
	for _, component := range health.Components {
		if component.Score < 70 {
			criticalCount++
			available = append(available, models.Optimization{
				Type:        "critical",
				Priority:    "HIGH",
				Target:      component.Name,
				Description: fmt.Sprintf("%s needs attention (Score: %.0f/100)", component.Name, component.Score),
				Impact:      "Significant performance improvement",
				Risk:        "Low",
			})
		} else if component.Score < 90 {
			minorCount++
			available = append(available, models.Optimization{
				Type:        "minor",
				Priority:    "MEDIUM",
				Target:      component.Name,
				Description: fmt.Sprintf("%s could be optimized (Score: %.0f/100)", component.Name, component.Score),
				Impact:      "Minor performance improvement",
				Risk:        "Low",
			})
		} else if component.Score >= 100 {
			applied = append(applied, models.Optimization{
				Type:        "applied",
				Priority:    "COMPLETED",
				Target:      component.Name,
				Description: fmt.Sprintf("%s is optimized (Score: %.0f/100)", component.Name, component.Score),
				Impact:      "Optimization active",
				Risk:        "None",
			})
		}
	}

	return &models.OptimizationStatus{
		Available:     available,
		Applied:       applied,
		TotalIssues:   len(available),
		CriticalCount: criticalCount,
		MinorCount:    minorCount,
	}, nil
}

// GetAISystemStatus checks the status of AI components
func (a *Analyzer) GetAISystemStatus() (*models.AISystemStatus, error) {
	status := &models.AISystemStatus{}

	// Check Ollama status
	if err := exec.Command("ollama", "list").Run(); err == nil {
		status.OllamaOnline = true

		// Get model count
		out, err := exec.Command("ollama", "list").Output()
		if err == nil {
			lines := strings.Split(string(out), "\n")
			// Skip header line and empty lines
			modelCount := 0
			var models []string
			for i, line := range lines {
				if i > 0 && strings.TrimSpace(line) != "" {
					modelCount++
					// Extract model name (first column)
					parts := strings.Fields(line)
					if len(parts) > 0 {
						models = append(models, parts[0])
					}
				}
			}
			status.ModelCount = modelCount
			status.Models = models
		}
	}

	// Check color server status (simple port check)
	if err := exec.Command("curl", "-s", "http://localhost:8080/ai-colors").Run(); err == nil {
		status.ColorServer = true
	}

	// Check if theming is active (look for recent theme files)
	if _, err := os.Stat("/tmp/ai-optimized-colors.json"); err == nil {
		status.ThemingActive = true

		// Get last modification time
		if info, err := os.Stat("/tmp/ai-optimized-colors.json"); err == nil {
			status.LastThemeTime = info.ModTime().Format("15:04:05")
		}
	}

	return status, nil
}

// RefreshAnalysis triggers a new system health analysis
func (a *Analyzer) RefreshAnalysis() error {
	// Run the health analyzer script
	cmd := exec.Command("bash", "../scripts/ai/config-system-health-analyzer.sh")
	return cmd.Run()
}

// Helper functions for safe type conversion
func getString(data map[string]interface{}, key string) string {
	if val, ok := data[key].(string); ok {
		return val
	}
	return ""
}

func getFloat(data map[string]interface{}, key string) float64 {
	if val, ok := data[key].(float64); ok {
		return val
	}
	return 0
}

func getInt(data map[string]interface{}, key string) int {
	if val, ok := data[key].(float64); ok {
		return int(val)
	}
	return 0
}

func getBool(data map[string]interface{}, key string) bool {
	if val, ok := data[key].(bool); ok {
		return val
	}
	if val, ok := data[key].(string); ok {
		return val == "true"
	}
	return false
}
