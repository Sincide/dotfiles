# Evil Space AI Tools
*Local LLM-powered system monitoring and analysis*

## 🚀 Quick Start

```bash
# System-wide access (already installed)
log-analyzer --help

# Real-time monitoring with AI analysis
log-analyzer live

# Quick investigations
log-analyzer sudo      # Sudo authentication issues
log-analyzer security  # Security events
log-analyzer today     # Today's suspicious activity

# Beautiful TUI interface
log-analyzer-tui       # Interactive terminal interface
```

## 🔧 Tools Available

### Log Analyzer (CLI)
- **File**: `realtime_log_analyzer.py`
- **Launcher**: `log-analyzer` (Fish shell wrapper)
- **Purpose**: Command-line log monitoring with local LLM analysis

### Log Analyzer (TUI)
- **File**: `../tui/log_analyzer_tui.py`
- **Launcher**: `log-analyzer-tui` (Beautiful terminal interface)
- **Purpose**: Interactive TUI with real-time monitoring and AI analysis

## 🤖 AI Models Used

Your available Ollama models:
- **codegemma:7b** (5.0 GB) - Best for technical log analysis
- **llama3.2:3b** (2.0 GB) - Balanced performance
- **llama3.2:1b** (1.3 GB) - Fastest option

## 🔍 Example Output

```bash
❯ log-analyzer today
🔍 Investigating logs from today
Analyzed 2291 events

Pattern Matches Found:
  account_lockout: 3 events
    🤖 AI Analysis:
      Root cause: Consecutive login failures triggering PAM protection
      Impact: Disrupted administrative access  
      Recommendations: Account unlock, MFA implementation
```

## 📊 Features

- **Real-time monitoring** with journalctl streaming
- **AI-powered explanations** using local LLM
- **Pattern detection** for security, system, and performance issues
- **Historical analysis** with time-based investigations
- **Privacy-focused** - all analysis happens locally
- **Beautiful TUI** - Interactive terminal interface with Textual

## 🎨 TUI Interface

The new TUI provides:
- **Left panel**: Action choices and configuration
- **Right panel**: Real-time log output and statistics
- **Tabbed interface**: Log output, statistics, and configuration
- **Interactive controls**: Buttons, dropdowns, and real-time updates

---

*Part of the Evil Space dotfiles ecosystem* 