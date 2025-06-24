# Evil Space TUI Components
*Beautiful terminal user interfaces for system management*

## 🎯 Overview

This directory contains Textual-based terminal user interfaces that provide beautiful, interactive experiences for system management tasks.

## 🚀 Available TUI Applications

### Log Analyzer TUI
- **File**: `log_analyzer_tui.py`
- **Launcher**: `log-analyzer-tui`
- **Purpose**: Interactive log analysis with AI integration

## 🔧 Installation

### Prerequisites
```bash
# Install Textual framework
pip install textual

# Ensure Ollama is available
ollama list
```

### Quick Start
```bash
# Launch the log analyzer TUI
log-analyzer-tui

# Or run directly
python3 scripts/tui/log_analyzer_tui.py
```

## 🎨 Interface Design

### Layout Structure
```
┌─────────────────────────────────────────────────────────────┐
│                    Header (with clock)                      │
├─────────────┬───────────────────────────────────────────────┤
│             │                                               │
│   Left      │              Right Panel                      │
│  Panel      │                                               │
│             │  ┌─────────────────────────────────────────┐  │
│ • Actions   │  │           Tabbed Content                │  │
│ • Config    │  │  ┌─────────┬─────────┬──────────────┐  │  │
│ • Control   │  │  │ Log     │ Stats   │ Config       │  │  │
│             │  │  │ Output  │ Table   │ Panel        │  │  │
│             │  │  └─────────┴─────────┴──────────────┘  │  │
│             │  └─────────────────────────────────────────┘  │
└─────────────┴───────────────────────────────────────────────┤
│                    Status Bar                               │
└─────────────────────────────────────────────────────────────┘
```

### Left Panel Features
- **Quick Actions**: One-click investigation buttons
- **Configuration**: Model selection and timeframe settings
- **Custom Investigation**: Pattern-based search tools
- **Control**: Monitoring controls and app management

### Right Panel Features
- **Log Output**: Real-time log streaming with highlighting
- **Statistics**: Data table with event analysis
- **Configuration**: Settings and status information

## 🎮 Usage Guide

### Quick Actions
1. **Live Monitoring**: Click "🚀 Start Live Monitoring" for real-time analysis
2. **Sudo Investigation**: Click "🔍 Investigate Sudo Issues" for authentication problems
3. **Security Analysis**: Click "🛡️ Security Analysis" for security events
4. **Today's Events**: Click "📊 Today's Events" for today's activity

### Custom Investigation
1. Enter a pattern in the "Pattern to search for" field
2. Set timeframe in "Timeframe" field (e.g., "2 hours ago")
3. Click "🔎 Custom Search"

### Configuration
1. Select AI model from dropdown (codegemma:7b, llama3.2:3b)
2. Set custom timeframe if needed
3. Click "⚙️ Update Config" to apply changes

## 🎨 Styling

The TUI uses Textual's CSS-like styling system with:
- **Color themes**: Automatic dark/light theme detection
- **Responsive layout**: Adapts to terminal size
- **Interactive elements**: Buttons, inputs, tables, tabs
- **Real-time updates**: Live status and statistics

## 🔧 Development

### Adding New TUI Components
1. Create new Python file in `scripts/tui/`
2. Inherit from `textual.app.App`
3. Define CSS styling and layout
4. Create launcher script if needed
5. Add to this README

### Styling Guidelines
- Use semantic color variables (`$primary`, `$surface`, etc.)
- Maintain consistent spacing and sizing
- Follow the established layout patterns
- Test on different terminal sizes

## 🚀 Features

### Real-time Capabilities
- Live log streaming with journalctl
- Real-time statistics updates
- AI analysis integration
- Interactive event processing

### AI Integration
- Local LLM analysis via Ollama
- Automatic pattern detection
- Context-aware explanations
- Model switching support

### User Experience
- Intuitive button-based interface
- Tabbed content organization
- Status bar with live updates
- Keyboard and mouse support

## 🔍 Troubleshooting

### Common Issues
1. **Textual not found**: `pip install textual`
2. **Ollama unavailable**: Check `ollama list` and model availability
3. **Permission errors**: Ensure journalctl access
4. **Display issues**: Check terminal size and color support

### Debug Mode
```bash
# Run with debug output
python3 -m textual dev scripts/tui/log_analyzer_tui.py
```

---

*Part of the Evil Space dotfiles ecosystem - Professional terminal interfaces for system management* 