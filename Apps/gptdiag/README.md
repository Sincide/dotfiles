# GPTDiag - Advanced System Diagnostic TUI

GPTDiag is a powerful terminal-based system diagnostic and monitoring tool with integrated AI-powered analysis capabilities. It provides a centralized TUI (Text User Interface) for comprehensive system health monitoring, intelligent diagnostics, and automated system management.

## Features

- **🎯 Central TUI Dashboard** - Single unified interface with arrow key navigation
- **📊 Real-time System Monitoring** - CPU, memory, disk I/O, and network monitoring
- **🤖 AI-Powered Diagnostics** - Intelligent system analysis and problem detection
- **⚙️ System Management** - Service control, process management, log analysis
- **🔧 Auto-Fix Capabilities** - Safe automated system repairs with user confirmation
- **📈 Historical Analysis** - Diagnostic history, trends, and statistical reports
- **🎨 Modern TUI Design** - Beautiful terminal interface with responsive layout

## Installation

### Prerequisites

- Python 3.8 or higher
- Arch Linux (primary support)
- Terminal with color support
- `yay` AUR helper (for some dependencies)

### Arch Linux Installation

```bash
# Install core dependencies via pacman
sudo pacman -S python-textual python-rich python-psutil python-aiohttp python-aiofiles python-click python-yaml python-dateutil python-tabulate

# Install AUR dependencies via yay
yay -S python-plotext python-asyncio-mqtt

# Navigate to the gptdiag directory
cd Apps/gptdiag

# Install the package using system Python
python setup.py install --user
```

### System-wide Installation (Optional)

```bash
# Install system-wide (requires root)
sudo python setup.py install

# Or create a symlink for development
sudo ln -sf $(pwd)/gptdiag/main.py /usr/local/bin/gptdiag
sudo chmod +x /usr/local/bin/gptdiag
```

### Development Setup

```bash
# For development, just run directly
cd Apps/gptdiag
python -m gptdiag.main
```

## Usage

### Launch Main TUI

```bash
gptdiag                    # Launch main TUI hub
```

### Command Line Options

```bash
gptdiag --config          # Configuration wizard
gptdiag --export-report   # Export latest diagnostic report
gptdiag --headless-scan   # Run diagnostics without TUI
gptdiag --version         # Show version info
gptdiag --help           # Show all options
```

## Navigation

### Primary Navigation
- **←/→ Arrow Keys**: Navigate between main tabs (Dashboard, Monitor, AI Diag, etc.)
- **↑/↓ Arrow Keys**: Navigate within current tab (menu items, lists)
- **Enter**: Select/activate highlighted item
- **Tab**: Move between panels within a tab
- **Escape**: Go back/cancel current action
- **q**: Quit application
- **h**: Show help/keyboard shortcuts
- **/**: Global search

### Main Sections

1. **Dashboard** - System overview, quick stats, recent activity
2. **Monitor** - Real-time metrics with live graphs and charts
3. **AI Diag** - Chat interface with AI, diagnosis results, fix suggestions
4. **Services** - Service management, process viewer, system control
5. **Logs** - Real-time log tailing, search, filtering, analysis
6. **History** - Past diagnostics, trends, reports, statistics

## Configuration

GPTDiag uses YAML configuration files located in:
- `~/.config/gptdiag/config.yaml` - Main configuration
- `~/.config/gptdiag/ai_config.yaml` - AI/LLM settings
- `~/.config/gptdiag/themes.yaml` - UI themes and colors

### AI Integration Setup

To enable AI-powered diagnostics, configure your AI provider in `ai_config.yaml`:

```yaml
ai:
  provider: "openai"  # openai, anthropic, local
  api_key: "your_api_key_here"
  model: "gpt-4"
  max_tokens: 2048
  temperature: 0.3
```

## Security

GPTDiag implements several security measures:
- **Command Whitelist**: Only approved system commands can be executed
- **User Confirmation**: All potentially dangerous operations require confirmation
- **Sudo Integration**: Secure privilege escalation when needed
- **Audit Trail**: Complete log of all system changes
- **API Key Protection**: Secure storage of sensitive credentials

## System Requirements

### Minimum Requirements
- Python 3.8+
- 2GB RAM
- 100MB disk space
- Terminal with 80x24 minimum size

### Recommended
- Python 3.10+
- 4GB RAM
- Terminal with 120x30 or larger
- Modern terminal emulator with full color support

## Troubleshooting

### Common Issues

**Permission Denied Errors**
```bash
# Run with appropriate permissions
sudo gptdiag
```

**Missing Dependencies**
```bash
# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

**TUI Display Issues**
```bash
# Check terminal compatibility
echo $TERM
# Ensure terminal supports colors
tput colors
```

## Development

### Running from Source
```bash
# Development mode
python -m gptdiag.main

# With debugging
python -m gptdiag.main --debug
```

### Testing
```bash
# Run tests
python -m pytest tests/

# Run with coverage
python -m pytest --cov=gptdiag tests/
```

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Support

For issues, questions, or contributions:
- Create an issue on the repository
- Check the built-in help system (press 'h' in the TUI)
- Review the configuration documentation

---

**Made with ❤️ for system administrators and power users** 