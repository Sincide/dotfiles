# 🧠 Offline ChatGPT on Arch Linux: Ollama + Phi-4 + Open WebUI

This guide walks you through setting up a local, offline ChatGPT-style environment on a **fresh Arch Linux** system using:
- [Ollama](https://ollama.com) for local LLM backend
- [Phi-4](https://ollama.com/library/phi) as your model
- [Open WebUI](https://github.com/open-webui/open-webui) for a sleek frontend

---

## ✅ Requirements
- Arch Linux (fresh or clean install)
- Internet access (for one-time downloads)
- Fish or Bash shell

---

## 🔧 1. Install Ollama

### 1.1 Install prerequisites:
```bash
sudo pacman -S curl git
```

### 1.2 Download and install Ollama:
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### 1.3 Start the Ollama service:
```bash
ollama serve &
```

---

## 📥 2. Pull Phi-4 Model
```bash
ollama pull phi
```
> Optional: `phi3:mini` if you want smaller footprint.

Test it:
```bash
ollama run phi
```
(Exit with Ctrl+C)

---

## 🐍 3. Set Up Python 3.11 with `pyenv`
Arch often ships Python 3.13+ which is **too new** for Open WebUI.

### 3.1 Install pyenv
```bash
sudo pacman -S pyenv
```

### 3.2 Set it up for Fish (or adapt for Bash)
```fish
set -Ux PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin
status --is-interactive; and pyenv init - | source
```

Add to `~/.config/fish/config.fish` for persistence.

### 3.3 Install Python 3.11.9
```bash
pyenv install 3.11.9
pyenv global 3.11.9
```

Check:
```bash
python --version
# → Python 3.11.9
```

---

## 🌐 4. Install Open WebUI via pip

### 4.1 Install pip-based WebUI:
```bash
pip install open-webui
```

### 4.2 Start it:
```bash
open-webui serve
```

Web UI launches at:
```
http://localhost:8080
```

---

## ✅ 5. Use it
- Choose model: `phi4:latest` from dropdown
- Upload files: top-right 📎 icon or drag-drop
- Download answers: click ⋮ menu next to a response

---

## 🧹 Optional Cleanups
- Set alias:
```bash
echo 'alias chatgpt="open-webui serve"' >> ~/.bashrc  # or config.fish
```
- Autostart Ollama:
```bash
systemctl --user enable --now ollama
```

---

## ✅ You're Done!
You now have:
- Full offline LLM interface
- GPT-style chats
- File upload/download support
- All powered by your GPU/CPU
