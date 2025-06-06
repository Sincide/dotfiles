# GPTDiag Development Documentation

## Project Overview

GPTDiag is an advanced terminal-based diagnostic and system monitoring tool with integrated AI-powered analysis capabilities. Built using Python's Textual framework for a modern TUI experience with full arrow key navigation.

**Current Status:** 🚧 In Development  
**Version:** 1.0.0  
**Target Platform:** Arch Linux (primary), Linux (general)  
**Python Version:** 3.8+ (Tested on 3.13.3)  
**AI Focus:** 🤖 Ollama local models (primary), Cloud APIs (secondary)

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GPTDiag Application                      │
├─────────────────────────────────────────────────────────────┤
│  main.py (CLI Entry Point)                                 │
│  ├── Click CLI Framework                                   │
│  ├── Configuration Setup                                   │
│  └── TUI App Launcher                                      │
├─────────────────────────────────────────────────────────────┤
│  app.py (Main TUI Application)                             │
│  ├── Textual App Framework                                 │
│  ├── Tab Management (Dashboard, Monitor, AI, etc.)         │
│  ├── Real-time Data Updates                                │
│  └── Event Handling & Navigation                           │
├─────────────────────────────────────────────────────────────┤
│  Widget Layer                                              │
│  ├── DashboardWidget (System Overview)                     │
│  ├── MonitorWidget (Real-time Metrics)                     │
│  ├── AIDiagWidget (AI Chat & Analysis)                     │
│  ├── ServicesWidget (System Services)                      │
│  ├── LogsWidget (Log Analysis)                             │
│  └── HistoryWidget (Historical Data)                       │
├─────────────────────────────────────────────────────────────┤
│  Core Services Layer                                       │
│  ├── SystemInfo (psutil wrapper)                           │
│  ├── DiagnosticRunner (Analysis engine)                    │
│  ├── ConfigManager (YAML config handling)                  │
│  └── AI Integration (LLM providers)                        │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                │
│  ├── Configuration Files (~/.config/gptdiag/)              │
│  ├── Historical Data (~/.local/share/gptdiag/)             │
│  └── Cache (~/.cache/gptdiag/)                             │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Progress

### ✅ Completed Components

1. **Project Structure & Setup**
   - [x] Package structure with proper `__init__.py`
   - [x] `setup.py` for Arch Linux installation
   - [x] `requirements.txt` with Arch package mappings
   - [x] Installation script (`install.sh`) for Arch Linux
   - [x] Comprehensive README.md

2. **Main Application Framework**
   - [x] `main.py` - CLI entry point with Click framework
   - [x] `app.py` - Main TUI application class
   - [x] Tab-based navigation structure
   - [x] Key bindings and navigation handlers
   - [x] Real-time data update system

3. **Configuration System**
   - [x] Config package structure (`config/__init__.py`)
   - [x] ConfigManager implementation (`config/manager.py`)
   - [x] Default configurations (`config/defaults.py`) with Ollama focus

### 🚧 In Progress

1. **Configuration Manager** (`config/manager.py`)
   - ✅ Loading and saving YAML configurations
   - ✅ Configuration validation
   - ✅ Default settings management

2. **AI Integration Framework** ✅ **COMPLETED**
   - [x] AI provider interface (`ai/providers.py`)
   - [x] AI package structure (`ai/__init__.py`)
   - [x] Ollama provider implementation (`ai/ollama.py`) ✅
   - [x] AI manager for multi-model coordination (`ai/manager.py`) ✅
   - [x] **WORKING AI INTEGRATION** - Successfully connects to local Ollama models!

### 📋 TODO - Next Steps

1. **Core Components**
   - [ ] `config/defaults.py` - Default configuration values
   - [ ] `config/wizard.py` - Configuration wizard
   - [ ] `utils/system.py` - System information collector
   - [ ] `diagnostics/runner.py` - Diagnostic engine

2. **Widget Implementation**
   - [ ] `widgets/dashboard.py` - Dashboard widget
   - [ ] `widgets/monitor.py` - Real-time monitoring
   - [ ] `widgets/ai_diag.py` - AI diagnostics interface
   - [ ] `widgets/services.py` - Service management
   - [ ] `widgets/logs.py` - Log viewer
   - [ ] `widgets/history.py` - Historical data

3. **AI Integration** (PRIMARY FOCUS 🎯)
   - [ ] `ai/providers.py` - AI provider interfaces
   - [ ] `ai/ollama.py` - Ollama local models (PRIORITY)
   - [ ] `ai/openai.py` - OpenAI integration (secondary)
   - [ ] `ai/anthropic.py` - Anthropic integration (secondary)
   - [ ] `ai/analyzer.py` - AI-powered system analysis
   - [ ] `ai/autofix.py` - AI-generated system fixes

4. **Diagnostics Engine**
   - [ ] System health checks
   - [ ] Performance analysis
   - [ ] Security scanning
   - [ ] Auto-fix suggestions

5. **UI/UX Enhancements**
   - [ ] `styles.css` - Textual CSS styling
   - [ ] Custom themes support
   - [ ] Responsive layout handling
   - [ ] Help screens and modals

## Technical Decisions

### Framework Choices

| Component | Framework/Library | Rationale |
|-----------|------------------|-----------|
| TUI Framework | Textual | Modern, Python-native, excellent docs, active development |
| CLI Framework | Click | Industry standard, powerful argument parsing, extensible |
| System Info | psutil | Cross-platform, comprehensive system metrics |
| Config Format | YAML | Human-readable, supports comments, widely used |
| HTTP Client | aiohttp | Async support for AI API calls |
| Package Manager | Arch pacman/yay | User requirement, no pip/pipx |

### Architecture Patterns

1. **Observer Pattern**: Used for real-time data updates across widgets
2. **Strategy Pattern**: AI provider implementations
3. **Command Pattern**: System operations and auto-fixes
4. **MVC Pattern**: Widget structure (Model=SystemInfo, View=Widget, Controller=App)

## File Structure (Current)

```
Apps/gptdiag/
├── gptdiag/                    # Main package
│   ├── __init__.py            ✅ Package init
│   ├── main.py                ✅ CLI entry point
│   ├── app.py                 ✅ Main TUI application
│   ├── config/                # Configuration management
│   │   ├── __init__.py       ✅ Config package init
│   │   ├── manager.py        ✅ Config manager
│   │   ├── defaults.py       ✅ Default configurations (AI-focused)
│   │   └── wizard.py         📋 Configuration wizard
│   ├── widgets/               # TUI widgets
│   │   ├── __init__.py       📋 Widget package
│   │   ├── dashboard.py      📋 Dashboard widget
│   │   ├── monitor.py        📋 Monitor widget
│   │   ├── ai_diag.py        📋 AI diagnostics widget
│   │   ├── services.py       📋 Services widget
│   │   ├── logs.py           📋 Logs widget
│   │   └── history.py        📋 History widget
│   ├── utils/                 # Utility modules
│   │   ├── __init__.py       📋 Utils package
│   │   ├── system.py         📋 System information
│   │   └── helpers.py        📋 Helper functions
│   ├── diagnostics/           # Diagnostic engine
│   │   ├── __init__.py       📋 Diagnostics package
│   │   ├── runner.py         📋 Main diagnostic runner
│   │   ├── checks.py         📋 System checks
│   │   └── analyzer.py       📋 Analysis engine
│   └── ai/                    # AI integration
│       ├── __init__.py       ✅ AI package
│       ├── providers.py      ✅ Provider interface
│       ├── ollama.py         ✅ Ollama integration (WORKING!)
│       ├── manager.py        ✅ AI manager
│       ├── openai.py         📋 OpenAI integration
│       └── anthropic.py      📋 Anthropic integration
├── requirements.txt           ✅ Arch package dependencies
├── setup.py                   ✅ Installation setup
├── install.sh                 ✅ Arch installation script
├── README.md                  ✅ User documentation
├── DEVELOPMENT.md             ✅ This development doc
└── styles.css                 📋 TUI styling
```

## Key Dependencies

### Arch Linux Packages

**Core Dependencies (pacman):**
- `python` - Python interpreter
- `python-rich` - Rich text and beautiful formatting
- `python-psutil` - System and process utilities
- `python-aiohttp` - Async HTTP client/server
- `python-aiofiles` - Async file operations
- `python-click` - CLI framework
- `python-yaml` - YAML parsing
- `python-dateutil` - Date utilities
- `python-tabulate` - Table formatting

**AUR Dependencies (yay):**
- `python-textual` - Modern TUI framework
- `python-plotext` - Terminal plotting
- `python-asyncio-mqtt` - MQTT async support (future use)

## Configuration System Design

### Configuration Files Location
- `~/.config/gptdiag/config.yaml` - Main application settings
- `~/.config/gptdiag/ai_config.yaml` - AI provider settings
- `~/.config/gptdiag/themes.yaml` - UI themes and colors

### Configuration Structure

```yaml
# config.yaml
app:
  update_interval: 2.0
  auto_update: true
  theme: "default"
  debug: false

monitoring:
  cpu_alert_threshold: 90
  memory_alert_threshold: 85
  disk_alert_threshold: 90
  network_interface: "auto"

system:
  allowed_commands:
    - "systemctl"
    - "journalctl" 
    - "ps"
    - "top"
    - "netstat"
  require_confirmation: true
  sudo_timeout: 300

# ai_config.yaml
ai:
  enabled: true
  provider: "openai"  # openai, anthropic, local
  api_key: ""
  model: "gpt-4"
  max_tokens: 2048
  temperature: 0.3
  timeout: 30

# themes.yaml
themes:
  default:
    primary: "#00b4d8"
    secondary: "#90e0ef"
    accent: "#0077b6"
    background: "#03045e"
    text: "#caf0f8"
```

## Navigation System Implementation

### Key Bindings
- `←/→` or `F1-F6`: Tab navigation
- `↑/↓`: Within-tab navigation
- `Enter`: Select/activate
- `Tab`: Panel switching
- `Escape`: Back/cancel
- `q`: Quit
- `h`: Help
- `/`: Search

### Tab Structure
1. **Dashboard** (F1) - System overview, quick actions
2. **Monitor** (F2) - Real-time metrics and graphs
3. **AI Diag** (F3) - AI chat and analysis
4. **Services** (F4) - System service management
5. **Logs** (F5) - Log viewing and analysis
6. **History** (F6) - Historical data and reports

## Development Workflow

### Current Phase: Core Framework (Week 1)
1. ✅ Project setup and structure
2. ✅ Main application framework
3. 🚧 Configuration system
4. 📋 System information utilities
5. 📋 Basic widget implementations

### Next Phase: Widget Development (Week 2)
1. Dashboard widget with system overview
2. Monitor widget with real-time graphs
3. Services widget with systemctl integration
4. Basic styling and responsive layout

### Future Phases:
- **Week 3**: AI integration and diagnostics engine
- **Week 4**: Advanced features, testing, and polish

## Testing Strategy

### Manual Testing
- Test on Arch Linux with various terminals
- Verify all key bindings work correctly
- Test responsive layout at different terminal sizes
- Validate configuration loading/saving

### Integration Testing
- Test with different system conditions
- Verify AI provider integrations
- Test system command execution safety
- Performance testing with long-running monitoring

## Security Considerations

### Command Execution Safety
- Whitelist of allowed system commands
- User confirmation for dangerous operations
- Sudo timeout management
- Audit trail of all system changes

### API Key Protection
- Secure storage of AI API keys
- Environment variable fallbacks
- Configuration file permissions (600)
- No logging of sensitive data

## Performance Optimization

### Real-time Updates
- Configurable update intervals
- Efficient data caching
- Background task management
- Memory usage monitoring

### Resource Management
- Async operations for non-blocking UI
- Connection pooling for API calls
- Lazy loading of expensive operations
- Cleanup of background tasks on exit

---

## 🔄 ARCHITECTURE EVOLUTION: HYBRID WEB+TUI APPROACH

**Status Change:** 2025-06-07 00:20 Swedish Time  
**Decision:** Pivot from pure TUI to hybrid web dashboard + simplified TUI

### 🤔 Problem Identified
- **TUI Aesthetic Limitation:** Terminal interfaces inherently look dated (1990s aesthetic)
- **Modern Expectations:** Users expect beautiful, modern interfaces for system monitoring
- **Showcase Potential:** Current TUI doesn't properly showcase the AI capabilities

### 💡 Solution: Hybrid Architecture

```
GPTDiag v2.0 - Modern Hybrid Architecture
├── 🧠 Core Engine (COMPLETED ✅)
│   ├── SystemInfo - Real system monitoring with psutil
│   ├── AIManager - Ollama integration with 5 working models
│   └── ConfigManager - YAML configuration system
├── 🌐 Web Dashboard (NEW - PRIMARY UI)
│   ├── FastAPI backend (reuse 90% of existing code)
│   ├── Modern HTML5/CSS3/JS frontend
│   ├── WebSocket real-time updates
│   ├── Interactive charts and graphs
│   ├── Rich AI analysis display
│   └── Mobile-responsive design
└── 📟 TUI (SIMPLIFIED - TERMINAL ACCESS)
    ├── Quick status overview
    ├── Basic system metrics
    └── SSH-friendly operation
```

### 🎯 Implementation Strategy

#### **Phase 1: FastAPI Web Backend** (Day 1-2)
**Code Reuse:** 90% of existing engine transfers directly!

**API Endpoints:**
- `GET /api/system/summary` - Quick metrics (existing `get_quick_summary()`)
- `GET /api/system/detailed` - Full system info (existing `get_async_info()`)
- `POST /api/ai/analyze` - AI health analysis (existing `analyze_system_health()`)
- `WebSocket /ws/updates` - Live data stream for real-time updates

**Benefits:**
- ✅ Reuse all existing SystemInfo + AIManager code
- ✅ Keep all 5 Ollama models working as-is
- ✅ Maintain configuration system
- ✅ No rework of core engine needed

#### **Phase 2: Modern Web Frontend** (Day 3-5)
**Features:**
- 📊 **Real-time system charts** (CPU/memory graphs, not just progress bars)
- 🤖 **Rich AI analysis display** with markdown rendering and syntax highlighting
- 🎨 **Modern dark theme** with gradients, animations, smooth transitions
- 📱 **Responsive design** for desktop, tablet, mobile access
- ⚡ **WebSocket live updates** every 5 seconds
- 🚨 **Interactive alerts** with notifications
- 📈 **Historical graphs** and performance trends
- 💾 **Export capabilities** (PDF reports, JSON data)

**Design Inspiration:**
- GitHub dashboard aesthetics
- Grafana monitoring interface
- VS Code dark theme
- Modern SaaS application design

#### **Phase 3: Simplified TUI** (Day 6)
**Purpose:** Quick terminal access and SSH-friendly monitoring
**Features:**
- `gptdiag --status` - Quick system overview
- `gptdiag --ai-check` - Fast AI health analysis
- Basic text-based metrics display
- No complex styling - focus on functionality

### 🎨 Expected Results

**Web Dashboard Benefits:**
- ✅ **Professional appearance** suitable for portfolio/demos
- ✅ **Unlimited styling** with modern CSS3 and animations
- ✅ **Better AI showcase** with rich text formatting
- ✅ **Real-time interactivity** with charts and live updates
- ✅ **Mobile accessibility** for remote monitoring
- ✅ **Screenshot-worthy** interface for documentation

**TUI Benefits Retained:**
- ✅ **Quick terminal access** for daily workflow
- ✅ **SSH-friendly** for remote server monitoring
- ✅ **Lightweight** for minimal resource usage
- ✅ **Keyboard-only** operation in terminal environments

### 🔧 Technical Advantages

1. **Code Reuse:** 90% of existing engine code transfers directly to web backend
2. **Parallel Development:** Can build web and TUI simultaneously
3. **Future-Proof:** Web platform allows unlimited UI evolution
4. **Best Practices:** FastAPI + modern frontend follows current standards
5. **Accessibility:** Web interface reaches broader audience

---

## Development Notes

**Last Updated:** 2025-06-07 00:20 Swedish Time  
**Current Focus:** 🔄 **ARCHITECTURE PIVOT TO WEB+TUI HYBRID**  
**Next Sprint:** FastAPI backend development (reusing existing core engine)  

**✅ COMPLETED FOUNDATION:**
- ✅ **Core Engine (100%):** SystemInfo + AIManager + ConfigManager
- ✅ **AI Integration:** Ollama working with 5 models (phi4, qwen3:4b, etc.)
- ✅ **Real System Monitoring:** psutil-based comprehensive metrics
- ✅ **Configuration System:** YAML-based with validation
- ✅ **Proven Functionality:** 8,000+ char AI analysis in 25-30 seconds

**🚀 UPCOMING SPRINT:**
1. **FastAPI Backend** - Wrap existing engine with web API
2. **Modern Frontend** - Beautiful web dashboard with live charts
3. **Simplified TUI** - Lightweight terminal access tool

**Architecture Benefits:**
- 🎯 **Professional showcase** potential
- 🎨 **Modern aesthetics** without terminal limitations  
- 🔄 **Code reuse** maximization (90% transfer rate)
- 📱 **Multi-platform access** (web, terminal, mobile)
- 🚀 **Future extensibility** with web platform

**Technical Debt:**
- Need to implement FastAPI backend wrapper
- Create modern web frontend
- Simplify TUI to essential functionality

---

*This document tracks the evolution from pure TUI to hybrid web+TUI architecture for better user experience and modern aesthetics.* 