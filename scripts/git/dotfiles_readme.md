# Dotfiles Manager (Fish Edition)

Smart dotfiles management with AI-powered commit messages for Fish shell users.

## ✨ Features

- 🤖 **AI-Generated Commit Messages** - Uses Ollama to create smart, conventional commits
- 🔄 **Smart Git Sync** - Automated pull, commit, push workflow
- 📱 **Interactive Menus** - No need to memorize commands
- 🐟 **Fish Native** - Written specifically for Fish shell
- 🎨 **Beautiful Colors** - Uses Fish's native `set_color`
- 🔍 **Repository Status** - Enhanced git status with branch info
- ⚡ **Fallback Messages** - Works even when AI is unavailable

## 🚀 Quick Start

### Installation

1. **Download the script:**
   ```fish
   curl -O https://example.com/dotfiles.fish
   chmod +x dotfiles.fish
   ```

2. **Navigate to your dotfiles repository:**
   ```fish
   cd ~/dotfiles
   ```

3. **Run interactive mode:**
   ```fish
   ./dotfiles.fish
   ```

### Prerequisites

- **Fish Shell** - Required for running the script
- **Git Repository** - Must be run from inside a git repository
- **Ollama** (optional) - For AI-powered commit messages
  ```fish
  curl -fsSL https://ollama.ai/install.sh | sh
  ollama pull qwen2.5-coder:7b  # Recommended for coding
  ```

## 📚 Usage

### Interactive Mode (Recommended)
```fish
./dotfiles.fish
```

This opens a beautiful menu:
```
╭─────────────────────────────────────────╮
│           Dotfiles Manager              │
│            Fish Edition                 │
╰─────────────────────────────────────────╯

What would you like to do?

  1️⃣  Sync (AI-powered commit & push)
  2️⃣  Status (repository overview)
  3️⃣  Diff (show changes)
  4️⃣  AI Test (test commit generation)
  5️⃣  AI Debug (detailed AI diagnostics)

  0️⃣  Exit
```

### Command Line Mode
```fish
# Quick sync with AI commit message
./dotfiles.fish sync

# Sync with custom message
./dotfiles.fish sync "fix: update fish configuration"

# Show repository status
./dotfiles.fish status

# Show changes
./dotfiles.fish diff

# Test AI functionality
./dotfiles.fish ai-test

# Debug AI issues
./dotfiles.fish ai-debug

# Show help
./dotfiles.fish help
```

## 🤖 AI Features

### Supported Models (Priority Order)
1. `qwen2.5-coder:14b` - Best for coding tasks
2. `qwen2.5-coder:7b` - Good balance of speed/quality
3. `codegemma:7b` - Alternative coding model
4. `mistral:7b-instruct` - General purpose
5. `mistral:7b` - Fallback option

### AI Commit Message Examples
The AI generates conventional commit messages like:
- `config: update fish shell settings`
- `feat: add new git aliases`
- `fix: resolve path issues in startup script`
- `chore: update dependencies`

### Fallback System
When AI is unavailable, the script generates smart fallback messages:
- Detects config files: `config: update waybar, kitty`
- Detects scripts: `scripts: update automation`
- Detects docs: `docs: update documentation`
- Generic: `chore: update 3 files`

## 🛠 Configuration

The script is self-configuring, but you can customize:

### Environment Variables
```fish
set -x DEBUG 1  # Enable debug output
```

### Preferred Models
Edit the `detect_ollama_model` function to change model priority.

## 🚨 Troubleshooting

### AI Not Working?
1. **Check Ollama installation:**
   ```fish
   ./dotfiles.fish ai-test
   ```

2. **Debug AI issues:**
   ```fish
   ./dotfiles.fish ai-debug
   ```

3. **Manual Ollama test:**
   ```fish
   ollama list
   ollama run qwen2.5-coder:7b "Hello"
   ```

### Common Issues

**"Not in a git repository"**
- Navigate to your dotfiles directory first
- Initialize git: `git init && git remote add origin <url>`

**"AI generation failed"**
- Check if Ollama is running: `pgrep ollama`
- Start Ollama: `ollama serve`
- Install a model: `ollama pull qwen2.5-coder:7b`

**"Sync failed"**
- Check remote access: `git fetch`
- Resolve conflicts manually: `git status`

## 📖 Examples

### Typical Workflow
```fish
# Navigate to dotfiles
cd ~/dotfiles

# Start interactive mode
./dotfiles.fish

# Select "1" for Sync
# AI generates: "config: update fish shell and git settings"
# Confirm with "Y"
# Script automatically commits and pushes
```

### Power User Workflow
```fish
# Quick status check
./dotfiles.fish status

# Quick sync
./dotfiles.fish sync

# Custom commit
./dotfiles.fish sync "feat: add new productivity scripts"
```

### Debugging Workflow
```fish
# Test AI
./dotfiles.fish ai-test

# Full AI debug
./dotfiles.fish ai-debug

# Check what would be committed
./dotfiles.fish diff
```

## 🎯 Advanced Features

### Smart File Detection
The script categorizes changes intelligently:
- **Config files**: `config/`, `.bashrc`, `.gitconfig`
- **Scripts**: `scripts/`, `bin/`, `*.sh`, `*.fish`
- **Documentation**: `README*`, `*.md`, `docs/`

### Git Integration
- Automatic staging of all changes
- Rebase-based pulling to maintain clean history
- Branch status and commit count tracking
- Conflict detection and guidance

### Fish Shell Optimizations
- Native Fish syntax throughout
- Proper array handling
- Built-in string operations
- Fish-compatible colors and formatting

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

### Development
The script is modular with clear function separation:
- `generate_ai_commit()` - AI message generation
- `sync_dotfiles()` - Main sync workflow
- `show_status()` - Enhanced git status
- `show_interactive_menu()` - Menu system

## 📄 License

This script is provided as-is for personal and educational use.

---

**Happy dotfile management! 🐟✨**