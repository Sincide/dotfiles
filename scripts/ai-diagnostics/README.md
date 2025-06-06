# 🤖 AI-Powered Theming System Diagnostics

A sophisticated diagnostic and troubleshooting system for AI-enhanced theming environments, powered by local LLMs and featuring deep system integration.

## 🎯 Overview

This diagnostic system provides:
- **Real-time AI-powered analysis** of theming system health
- **Interactive terminal UI** with keyboard navigation
- **Deep LLM integration** for intelligent issue diagnosis
- **Historical trend analysis** and performance monitoring
- **Modular plugin architecture** for extensible checks
- **Automated fix suggestions** with confirmation prompts

## 🏗️ Architecture

```
ai-diagnostics/
├── core/                 # Core system components
│   ├── models.py        # Data models and schemas
│   ├── llm_engine.py    # LLM integration and AI analysis
│   ├── hub.py           # Main orchestration and coordination
│   ├── ui_engine.py     # Interactive terminal interface
│   ├── storage.py       # SQLite database and history management
│   └── plugin_manager.py # Plugin discovery and lifecycle
├── plugins/             # Diagnostic check plugins
│   ├── base.py         # Base plugin class and interfaces
│   ├── environment.py  # Environment validation (Wayland/Hyprland)
│   ├── ai_health.py    # AI model testing and responsiveness
│   ├── theming_core.py # Core theming functionality tests
│   ├── performance.py  # Performance benchmarking and stress tests
│   ├── system_logs.py  # System log analysis via journald
│   └── trends.py       # Historical trend analysis
├── outputs/             # Output formatters and exporters
│   ├── terminal.py     # Rich terminal display
│   ├── json_export.py  # JSON structured data export
│   └── html_report.py  # Detailed HTML report generation
├── data/               # Runtime data directory
│   ├── history.db      # SQLite database for historical data
│   ├── plugins/        # Auto-discovered plugin directory
│   └── exports/        # Generated reports and exports
└── ai_diagnostics.py   # Main entry point and CLI interface
```

## 📦 Installation

### System Dependencies (Arch Linux)

```bash
# Core Python packages via pacman
sudo pacman -S python-rich python-click python-pydantic python-psutil python-aiofiles

# Additional packages via AUR (yay)
yay -S python-textual python-aiosqlite python-watchdog

# Ollama for LLM functionality
curl -fsSL https://ollama.com/install.sh | sh
systemctl --user enable ollama
systemctl --user start ollama

# Install required models
ollama pull phi4         # Primary reasoning model
ollama pull llama3.2     # Explanation and natural language
```

### Manual Python Package Installation (if needed)

If packages aren't available via system package manager:

```bash
# Download and install manually (example for textual)
curl -O https://files.pythonhosted.org/packages/.../textual-0.45.0.tar.gz
tar -xzf textual-0.45.0.tar.gz
cd textual-0.45.0
python setup.py install --user
```

## 🚀 Usage

### Quick Start

```bash
# Navigate to diagnostics directory
cd ~/dotfiles/scripts/ai-diagnostics

# Run quick health check (30 seconds)
python ai_diagnostics.py --mode quick

# Run interactive diagnostic session
python ai_diagnostics.py --interactive

# Run deep analysis with stress testing
python ai_diagnostics.py --mode deep --stress-test

# Export results to JSON
python ai_diagnostics.py --mode quick --export json

# View historical trends
python ai_diagnostics.py --trends --days 30
```

### Interactive Mode

The interactive mode provides a keyboard-driven interface:

- **Arrow Keys**: Navigate between checks and options
- **Enter**: Execute selected check or drill down into details
- **Space**: Select/deselect fixes for batch application
- **Tab**: Switch between panels (checks, results, logs)
- **F1**: Show help and keyboard shortcuts
- **Esc**: Return to previous screen or exit

### Command Line Options

```bash
python ai_diagnostics.py [OPTIONS]

Options:
  --mode [quick|deep|stress]     Diagnostic depth level
  --interactive                  Launch interactive terminal UI
  --ai-model TEXT               Primary LLM model (default: phi4)
  --export [json|html|terminal]  Output format
  --trends                      Show historical trend analysis
  --days INTEGER                Days of history to analyze
  --plugin-dir PATH            Additional plugin directory
  --verbose                    Enable detailed logging
  --help                       Show this message and exit
```

## 🔌 Plugin System

### Plugin Structure

Plugins are Python classes that inherit from the base plugin interface:

```python
from core.plugin_manager import DiagnosticPlugin
from core.models import DiagnosticResult, DiagnosticIssue, Severity

class MyCustomCheck(DiagnosticPlugin):
    """Custom diagnostic check example."""
    
    metadata = {
        "name": "Custom Check",
        "version": "1.0.0",
        "description": "Example custom diagnostic check",
        "author": "Your Name",
        "category": "custom"
    }
    
    async def execute(self) -> DiagnosticResult:
        """Execute the diagnostic check."""
        # Your diagnostic logic here
        return DiagnosticResult(...)
    
    async def can_fix(self, issue: DiagnosticIssue) -> bool:
        """Check if this plugin can fix the given issue."""
        return issue.category == "custom"
    
    async def apply_fix(self, issue: DiagnosticIssue) -> bool:
        """Apply fix for the given issue."""
        # Your fix logic here
        return True
```

### Adding Custom Plugins

1. Create your plugin file in `plugins/` directory
2. Inherit from `DiagnosticPlugin` base class
3. Implement required methods: `execute()`, `can_fix()`, `apply_fix()`
4. The system will auto-discover and offer to enable your plugin

## 🤖 AI Integration

### LLM Model Strategy

The system uses a multi-model approach for optimal performance:

- **Primary Brain (phi4)**: Complex reasoning, pattern recognition, root cause analysis
- **Explanation Model (llama3.2)**: User-friendly explanations, fix descriptions
- **Specialized Models**: Task-specific models can be configured per plugin

### AI Analysis Capabilities

- **Real-time Log Analysis**: Continuous monitoring and pattern detection
- **Predictive Diagnostics**: Early warning based on system trends
- **Intelligent Fix Suggestions**: Context-aware automated solutions
- **Natural Language Explanations**: Human-readable issue descriptions
- **Performance Correlation**: AI identifies relationships between metrics

### AI Configuration

```python
# AI model configuration in core/llm_engine.py
AI_CONFIG = {
    "primary_model": "phi4",           # Main reasoning engine
    "explanation_model": "llama3.2",   # User-facing explanations
    "timeout_seconds": 30,             # LLM response timeout
    "max_context_length": 4096,        # Context window size
    "temperature": 0.1,                # Response creativity (low for diagnostics)
    "enable_streaming": True,          # Real-time response streaming
}
```

## 📊 Data Storage and Trends

### Database Schema

The system maintains a SQLite database with the following structure:

- **Sessions**: Diagnostic session metadata
- **Results**: Individual check results and metrics
- **Issues**: Detected problems and their resolutions
- **Snapshots**: System state at time of analysis
- **Trends**: Aggregated performance metrics over time

### Historical Analysis

The system tracks trends including:

- **Performance Degradation**: Theme generation time increasing
- **Error Patterns**: Recurring issues and their frequency
- **AI Accuracy**: LLM diagnostic confidence over time
- **System Health Score**: Overall health trending
- **Resource Usage**: CPU, memory, disk usage patterns

## 🔧 Troubleshooting

### Common Issues

**"AI models not responding"**
```bash
# Check Ollama service status
systemctl --user status ollama

# Restart Ollama service
systemctl --user restart ollama

# Verify models are available
ollama list
```

**"Permission denied accessing logs"**
```bash
# Add user to systemd-journal group
sudo usermod -a -G systemd-journal $USER

# Re-login or use newgrp
newgrp systemd-journal
```

**"Plugin not detected"**
```bash
# Ensure plugin file has proper structure
python -c "from plugins.my_plugin import MyPlugin; print('Plugin loads correctly')"

# Check plugin directory permissions
ls -la plugins/
```

### Debug Mode

Enable verbose logging for troubleshooting:

```bash
python ai_diagnostics.py --verbose --mode quick
```

## 🤝 Contributing

### Adding New Diagnostic Checks

1. Create plugin in `plugins/` directory
2. Follow the plugin interface specification
3. Add comprehensive docstrings and type hints
4. Include unit tests for plugin functionality
5. Update this README with plugin description

### AI Model Integration

To add support for new LLM models:

1. Extend `llm_engine.py` with model-specific configurations
2. Test model performance on diagnostic tasks
3. Update model selection logic in core system
4. Document model capabilities and use cases

## 📝 License

This diagnostic system is part of the AI-enhanced theming environment and follows the same license as the parent project. 