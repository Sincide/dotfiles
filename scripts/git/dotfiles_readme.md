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

# Dotfiles Manager - Fish Edition - Devlog

## Latest Updates (2025-01-21)

### 🔧 **Major Fixes - Simplified AI Integration**

**Issues Fixed:**
1. **AI Response Parsing Failure**: Complex regex validation was rejecting valid commit messages
2. **String Cleaning Problems**: Extra quotes and characters weren't being removed properly
3. **Overcomplicated Validation**: 30+ lines of validation logic causing failures
4. **Verbose AI Output**: AI was generating explanatory text instead of clean commit messages
5. **Timeout Issues**: Long processing times with complex error handling

**Solutions Applied:**

1. **Simplified String Cleaning**: 
   - Replaced complex regex with simple `sed 's/[^a-zA-Z0-9:().,!? -]//g'`
   - Removes unwanted characters, keeps essentials
   - One-liner instead of multi-step processing

2. **Streamlined Validation**:
   - Removed complex regex pattern matching
   - Simple length check: 15-72 characters
   - From 30+ lines to 3 lines of validation logic

3. **Improved AI Prompting**:
   - Clearer, more direct prompt structure
   - Explicit examples and format requirements
   - Reduced timeout from 25s to 15s

4. **Better Error Handling**:
   - Simplified fallback logic with smart categorization
   - Proper directory-based commit message generation
   - No complex error state management

**Current Working Status:**
✅ AI Generation: Produces clean commit messages like `fix(gitdotfiles.fish): update script to handle new git commands`  
✅ String Processing: Proper cleaning without complex regex  
✅ Full Workflow: Complete sync process (generate → commit → pull → push)  
✅ Fallback Logic: Smart categorization by file types and directories  
✅ Performance: Fast 15s generation with immediate validation  

**Performance Results:**
- AI commit generation: ~3-5 seconds
- Full sync workflow: ~10-15 seconds
- Interactive menu: Instant response
- Ollama model detection: Works with qwen2.5-coder:14b, mistral:7b, etc.

**Example Generated Commits:**
- `fix(gitdotfiles.fish): update script to handle new git commands`
- `chore(fish): update dotfiles configuration`
- `scripts: update automation and tools`
- `config(waybar): update settings`

### 🎯 **Key Lesson Learned:**
**Simplicity wins!** The original implementation was overengineered with complex validation, error handling, and string processing. The working solution uses:
- Simple character filtering instead of complex regex
- Basic length validation instead of format validation  
- Direct timeout handling instead of complex error states
- Clean prompts instead of verbose instructions

The script now provides reliable AI-powered git commit generation with proper fallbacks and a smooth user experience.

## Features Overview

### 🤖 **AI Integration**
- Automatic commit message generation using Ollama
- Support for multiple models (qwen2.5-coder, mistral, etc.)
- Smart fallback when AI is unavailable
- Conventional commit format compliance

### 🔄 **Git Workflow**
- Smart sync: pull → commit → push
- Interactive commit message confirmation
- Repository status and diff viewing
- Automatic staging of changes

### 📱 **User Interface**
- Beautiful Fish-native colors and formatting
- Interactive menu system
- Command-line interface support
- Debug and testing modes

### 🐟 **Fish Shell Optimized**
- Native Fish functions and syntax
- Proper variable scoping
- Fish-style string processing
- Colorized output using set_color