# Evil Space Dashboard

Comprehensive monitoring and management dashboard for the Evil Space dotfiles ecosystem.

## Features

- **Real-time System Monitoring**: CPU, RAM, disk usage, load averages
- **GPU Monitoring**: AMD ROCm integration for temperature, usage, and VRAM
- **Log Management**: Centralized log viewer with filtering and analytics
- **Theme Management**: Dynamic theme switching and wallpaper browser
- **Script Management**: Safe execution and monitoring of dotfiles scripts
- **Adaptive Updates**: 2s when active, 30s when inactive, paused when tab hidden
- **Evil Space Aesthetic**: Dark glassmorphism UI with space-themed gradients

## Quick Start

```fish
cd ~/dotfiles
fish dashboard/start_dashboard.fish
```

Then open: http://localhost:8080

## Requirements

### Required
- Python 3.7+ (uses only built-in modules)
- Fish shell (for launcher script)

### Optional (auto-detected)
- `python-psutil` - Full system monitoring
- `rocm-smi` - AMD GPU monitoring

Install optional dependencies:
```bash
sudo pacman -S python-psutil rocm-smi-lib
```

## Architecture

- **Single File Application**: 925 lines of pure Python
- **No External Dependencies**: Uses only Python standard library
- **SQLite Storage**: Persistent data in `dashboard/data/`
- **API Endpoints**: RESTful JSON API for all data
- **Responsive UI**: Mobile-friendly glassmorphism design

## API Endpoints

- `GET /api/system` - System information and metrics
- `GET /api/gpu` - GPU temperature, usage, and memory
- `GET /api/logs` - Log file analysis and recent entries  
- `GET /api/themes` - Theme status and available options
- `GET /api/scripts` - Available scripts by category

## File Structure

```
dashboard/
├── evil_space_dashboard.py  # Main application
├── start_dashboard.fish     # Fish launcher
├── data/                    # SQLite database
├── static/                  # Static assets (future)
└── templates/               # Templates (future)
```

## Security

- **Local Only**: Binds to localhost:8080 only
- **No Setup Scripts**: Excludes dangerous setup scripts from execution
- **Read-Only Logs**: Log viewing only, no modification
- **Safe Commands**: All system commands use timeouts and error handling

## Development

Dashboard follows the Evil Space development patterns:
- Comprehensive logging to `~/dotfiles/logs/`
- Fish shell integration
- Material Design 3 color schemes
- Graceful degradation for missing dependencies

## Planned Features

See `docs/EVIL_SPACE_DASHBOARD_DEVLOG.md` for complete roadmap including:
- AI integration with Ollama
- Advanced log analytics
- Custom theme creation
- Script scheduling
- System health insights 