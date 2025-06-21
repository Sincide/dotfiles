# 🌌 Evil Space Neovim - AI Learning Environment

A beginner-friendly Neovim configuration with local AI integration using your Ollama models.

## 🚀 Quick Start

### First Time Setup
```bash
# Deploy dotfiles (this will symlink nvim config)
~/dotfiles/scripts/setup/03-deploy-dotfiles.sh

# Start Neovim
nvim
```

Plugins will auto-install on first launch. The AI features will be ready immediately using your local models!

## 🤖 AI Features

### Your Local Models
- **qwen2.5-coder:14b** - Main coding assistant
- **mistral:7b-instruct** - Chat and explanations  
- **codegemma:7b** - Backup coding model

### AI Commands

| Shortcut | Action | Description |
|----------|--------|-------------|
| `<Space>ae` | Explain Code | Select code and get AI explanation |
| `<Space>af` | Fix Code | AI fixes issues and explains what was wrong |
| `<Space>ac` | AI Chat | Open full AI chat interface |
| `<Space>ah` | Neovim Help | Ask AI about Neovim commands |
| `<Space>al` | Learn Command | Learn how to do something in Neovim |
| `<Space>ag` | Generate | Show all AI generation prompts |

### Custom Commands
- `:Learn <topic>` - Ask AI to explain a Neovim concept
- `:Tips` - Show welcome message with shortcuts
- `:AiModel <model>` - Switch between AI models

## 📚 Learning Features

### Essential Shortcuts

| Category | Shortcut | Action |
|----------|----------|--------|
| **Help** | `<Space>?` | Show all available shortcuts |
| **Help** | `<Space>h` | Open Neovim help (type topic after) |
| **Files** | `<Space>e` | Toggle file explorer |
| **Files** | `<Space>ff` | Find files fuzzy search |
| **Files** | `<Space>fg` | Search inside files |
| **Files** | `<Space>w` | Save file |
| **Files** | `<Space>q` | Quit |
| **Windows** | `<Space>sv` | Split vertically |
| **Windows** | `<Space>sh` | Split horizontally |
| **Windows** | `<Ctrl-h/j/k/l>` | Move between windows |

### Learning Assistance
- **Hardtime.nvim** - Breaks bad habits by preventing repeated keys
- **Auto-save** - Saves when you leave insert mode
- **Which-key** - Shows available shortcuts when you pause
- **Syntax highlighting** - For Fish, Lua, Python, JavaScript, etc.

## 🎨 Theme Integration

The configuration automatically matches your dotfiles theme with:
- Transparent background (like your terminal)
- Colors that complement your Material You theme
- Status line that fits your aesthetic

## 💡 Learning Workflow

### For Beginners:
1. **Start with basics**: Use `<Space>?` to see all shortcuts
2. **Learn by doing**: Try `<Space>ae` on any code to understand it  
3. **Ask for help**: Use `<Space>ah` when stuck on commands
4. **Practice navigation**: Use file explorer (`<Space>e`) and fuzzy search (`<Space>ff`)
5. **Use AI chat**: `<Space>ac` for interactive learning

### Example Learning Session:
```
1. Open Neovim: nvim
2. See welcome message with tips
3. Press <Space>? to see all shortcuts  
4. Open file explorer: <Space>e
5. Find a file: <Space>ff
6. Select some code and press <Space>ae to understand it
7. Chat with AI: <Space>ac "How do I search and replace in Neovim?"
```

## 🔧 Customization

### Switching AI Models
```vim
:AiModel qwen2.5-coder:14b    " For coding tasks
:AiModel mistral:7b-instruct  " For explanations  
:AiModel codegemma:7b         " Alternative coding model
```

### Adding Custom Prompts
Edit `nvim/init.lua` and add to the `require("gen").prompts` section:

```lua
require("gen").prompts["Custom_Prompt"] = {
  prompt = "Your custom prompt here: $text",
  replace = false,
}
```

## 🛠️ Configuration Files

- `init.lua` - Main configuration
- `README.md` - This file

## 🐛 Troubleshooting

### AI Not Working?
1. Check Ollama is running: `ollama list`
2. Start Ollama service: `ollama serve`
3. Test models: `ollama run mistral:7b-instruct`

### Plugins Not Loading?
1. Restart Neovim: `:q` then `nvim`
2. Update plugins: `:Lazy update`
3. Check health: `:checkhealth`

### Need Help?
- Use `:Learn <topic>` for AI assistance
- Check `:help` for built-in documentation
- Ask AI in chat: `<Space>ac`

## 🌟 Next Steps

Once comfortable with basics:
1. Learn about LSP (Language Server Protocol) for coding
2. Explore more advanced plugins
3. Customize keybindings to your preference
4. Try different AI models for different tasks

**Remember**: The AI is there to help you learn, not replace learning. Use it to understand concepts, then practice them yourself!

---

*Part of the Evil Space dotfiles ecosystem - your AI-powered development environment.* 