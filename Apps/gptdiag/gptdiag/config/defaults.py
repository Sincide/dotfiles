#!/usr/bin/env python3
"""
Default Configuration Values for GPTDiag

Defines all default settings for the application with a focus on AI integration
using Ollama local models as the primary AI provider.
"""

# Main application configuration
DEFAULT_CONFIG = {
    "app": {
        "update_interval": 2.0,
        "auto_update": True,
        "theme": "default",
        "debug": False,
        "ai_enhanced": True,  # Enable AI features by default
        "auto_analyze": True,  # Automatically analyze system issues with AI
    },
    
    "monitoring": {
        "cpu_alert_threshold": 85,
        "memory_alert_threshold": 80,
        "disk_alert_threshold": 90,
        "network_interface": "auto",
        "ai_analysis_enabled": True,  # Use AI to analyze metrics
        "auto_suggestions": True,     # AI-generated optimization suggestions
    },
    
    "system": {
        "allowed_commands": [
            "systemctl", "journalctl", "ps", "top", "htop", "free", "df",
            "netstat", "ss", "lsof", "mount", "lsblk", "fdisk",
            "pacman", "yay", "makepkg",  # Arch-specific
            "dmesg", "lscpu", "lsmem", "lsusb", "lspci",
            "uname", "uptime", "who", "w", "last"
        ],
        "require_confirmation": True,
        "sudo_timeout": 300,
        "ai_fix_enabled": True,       # Allow AI to suggest and execute fixes
        "safe_mode": True,           # Only allow safe operations initially
    },
    
    "ui": {
        "refresh_rate": 60,          # FPS for real-time updates
        "animation_enabled": True,
        "progress_bars": True,
        "ai_status_display": True,   # Show AI analysis status
        "live_suggestions": True,    # Display AI suggestions in real-time
    },
    
    "logging": {
        "level": "INFO",
        "file_enabled": True,
        "max_file_size": "10MB",
        "backup_count": 5,
        "ai_logging": True,          # Log AI interactions and decisions
    },
    
    "history": {
        "max_entries": 1000,
        "auto_cleanup": True,
        "ai_insights": True,         # Store AI analysis results
        "trend_analysis": True,      # Use AI for trend detection
    }
}

# AI configuration with Ollama as primary provider
DEFAULT_AI_CONFIG = {
    "ai": {
        "enabled": True,
        "primary_provider": "ollama",
        "fallback_provider": "openai",  # Fallback if ollama fails
        "timeout": 30,
        "max_retries": 3,
        "auto_model_selection": True,   # Automatically choose best model for task
    },
    
    "ollama": {
        "enabled": True,
        "base_url": "http://localhost:11434",
        "timeout": 45,
        "keep_alive": "5m",
        
        # Available models (based on user's ollama list)
        "models": {
            "general": "phi4:latest",              # Best general purpose model
            "diagnostics": "qwen3:4b",             # Fast analysis model
            "coding": "codellama:7b-instruct",     # Code generation and fixes
            "vision": "llava-llama3:8b",           # For visual analysis (future)
            "fast": "qwen2.5-coder:1.5b-base",    # Quick responses
        },
        
        # Model-specific configurations
        "model_configs": {
            "phi4:latest": {
                "temperature": 0.3,
                "max_tokens": 4096,
                "context_window": 32768,
                "use_for": ["system_analysis", "problem_solving", "recommendations"]
            },
            "qwen3:4b": {
                "temperature": 0.2,
                "max_tokens": 2048,
                "context_window": 8192,
                "use_for": ["quick_diagnostics", "status_checks", "alerts"]
            },
            "codellama:7b-instruct": {
                "temperature": 0.1,
                "max_tokens": 2048,
                "context_window": 16384,
                "use_for": ["script_generation", "command_suggestions", "auto_fixes"]
            },
            "llava-llama3:8b": {
                "temperature": 0.3,
                "max_tokens": 2048,
                "context_window": 8192,
                "use_for": ["visual_analysis", "screenshot_analysis"]
            },
            "qwen2.5-coder:1.5b-base": {
                "temperature": 0.2,
                "max_tokens": 1024,
                "context_window": 4096,
                "use_for": ["quick_code", "simple_fixes", "fast_responses"]
            }
        }
    },
    
    "openai": {
        "enabled": False,  # Secondary provider
        "api_key": "",
        "model": "gpt-4",
        "max_tokens": 2048,
        "temperature": 0.3,
        "timeout": 30
    },
    
    "anthropic": {
        "enabled": False,  # Secondary provider
        "api_key": "",
        "model": "claude-3-sonnet-20240229",
        "max_tokens": 2048,
        "temperature": 0.3,
        "timeout": 30
    },
    
    "features": {
        "auto_diagnosis": True,           # Automatically diagnose issues
        "real_time_analysis": True,      # Continuous AI monitoring
        "predictive_alerts": True,       # AI predicts potential issues
        "auto_fix_suggestions": True,    # AI suggests fixes
        "safe_auto_fix": False,          # Actually execute safe fixes (disabled by default)
        "learning_mode": True,           # AI learns from system patterns
        "context_awareness": True,       # AI remembers previous interactions
        "multi_model_consensus": True,   # Use multiple models for important decisions
    },
    
    "prompts": {
        "system_analysis": """You are an expert system administrator analyzing a Linux system. 
Analyze the provided system information and identify any issues, performance bottlenecks, 
security concerns, or optimization opportunities. Provide specific, actionable recommendations.""",
        
        "code_generation": """You are an expert system administrator and bash scripter.
Generate safe, well-commented shell commands or scripts to address the specified system issue.
Only suggest commands that are safe to execute and explain what each command does.""",
        
        "quick_diagnosis": """You are a Linux system expert. Quickly analyze the provided metrics
and identify the most critical issues that need immediate attention. Be concise but thorough.""",
        
        "auto_fix": """You are a cautious system administrator. Suggest the safest possible fix
for the identified issue. Explain the risks and provide step-by-step instructions."""
    }
}

# Themes configuration with AI-focused design
DEFAULT_THEMES = {
    "themes": {
        "default": {
            "primary": "#00d2d3",      # Cyan - AI/tech feel
            "secondary": "#01a3a4",    # Darker cyan
            "accent": "#ffd23f",       # Yellow - highlights
            "background": "#0f0f23",   # Dark blue-black
            "text": "#e6fffa",         # Light cyan
            "success": "#34d399",      # Green
            "warning": "#fbbf24",      # Amber
            "error": "#f87171",       # Red
            "ai_active": "#8b5cf6",   # Purple - AI activity
            "ai_thinking": "#06b6d4",  # Light blue - AI processing
        },
        
        "ai_dark": {
            "primary": "#8b5cf6",      # Purple - AI theme
            "secondary": "#7c3aed",    # Darker purple
            "accent": "#06d6a0",       # Green accent
            "background": "#111827",   # Very dark
            "text": "#f3f4f6",         # Light gray
            "success": "#10b981",      # Green
            "warning": "#f59e0b",      # Amber
            "error": "#ef4444",        # Red
            "ai_active": "#ec4899",    # Pink - AI activity
            "ai_thinking": "#3b82f6",  # Blue - AI processing
        },
        
        "matrix": {
            "primary": "#00ff41",      # Matrix green
            "secondary": "#008f11",    # Darker green
            "accent": "#41ff00",       # Bright green
            "background": "#000000",   # Pure black
            "text": "#00ff41",         # Matrix green
            "success": "#00ff41",      # Green
            "warning": "#ffff00",      # Yellow
            "error": "#ff0000",        # Red
            "ai_active": "#ff6600",    # Orange - AI activity
            "ai_thinking": "#00ffff",  # Cyan - AI processing
        }
    },
    
    "ui": {
        "default_theme": "default",
        "ai_indicators": {
            "thinking": "🤖",
            "analyzing": "🔍",
            "suggesting": "💡",
            "error": "❌",
            "success": "✅"
        },
        "animations": {
            "ai_typing": True,
            "progress_bars": True,
            "fade_transitions": True
        }
    }
}

# AI Analysis Templates
AI_ANALYSIS_TEMPLATES = {
    "system_health": {
        "prompt": """Analyze this Linux system health data:

CPU Usage: {cpu_percent}%
Memory Usage: {memory_percent}% ({memory_used}GB/{memory_total}GB)
Disk Usage: {disk_percent}% ({disk_used}GB/{disk_total}GB)
Load Average: {load_avg}
Uptime: {uptime}
Active Processes: {process_count}

Top Processes by CPU:
{top_cpu_processes}

Top Processes by Memory:
{top_memory_processes}

Identify any issues and provide actionable recommendations.""",
        "model": "diagnostics"
    },
    
    "log_analysis": {
        "prompt": """Analyze these system logs for patterns, errors, or security issues:

{log_entries}

Focus on:
1. Critical errors or failures
2. Security-related events
3. Performance issues
4. Unusual patterns
5. Recommended actions""",
        "model": "general"
    },
    
    "service_analysis": {
        "prompt": """Analyze these systemd services:

{service_status}

Identify:
1. Failed or problematic services
2. Services that should be running but aren't
3. Resource-heavy services
4. Security implications
5. Optimization opportunities""",
        "model": "diagnostics"
    },
    
    "performance_optimization": {
        "prompt": """Based on this system performance data, suggest optimizations:

{performance_data}

Provide specific recommendations for:
1. CPU optimization
2. Memory management
3. Disk I/O improvements
4. Network optimization
5. Service tuning""",
        "model": "general"
    }
}

# Export all defaults
__all__ = [
    "DEFAULT_CONFIG",
    "DEFAULT_AI_CONFIG", 
    "DEFAULT_THEMES",
    "AI_ANALYSIS_TEMPLATES"
] 