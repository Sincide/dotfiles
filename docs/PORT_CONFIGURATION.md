# 🔌 Port Configuration Guide

## ✅ **Port Conflicts Resolved**

**Problem:** qBittorrent and Dashboard both wanted to use port 8080, causing conflicts.

**Solution:** Updated qBittorrent to use port 9090, keeping Dashboard on 8080.

## 📋 **Current Port Allocation**

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **Dashboard** | **8080** | http://localhost:8080 | System monitoring & management |
| **Emby Server** | **8096** | http://localhost:8096 | Media server (movies, TV, music) |
| **qBittorrent** | **9090** | http://localhost:9090 | Torrent client web interface |
| **Ollama** | **11434** | http://localhost:11434 | AI platform API |

## 🔧 **Technical Changes Made**

### **qBittorrent Configuration:**
- ✅ **Script updated:** `10-setup-qbittorrent.sh`
- ✅ **Port changed:** 8080 → 9090
- ✅ **Config file:** Auto-created with correct port
- ✅ **Port conflict check:** Now checks 9090 instead of 8080

### **Configuration File Location:**
```bash
/var/lib/qbittorrent/.config/qBittorrent/qBittorrent.conf
```

### **Key Config Setting:**
```ini
[Preferences]
WebUI\Port=9090
```

## 🎯 **Access Information**

### **Dashboard (Port 8080):**
```bash
# Launch dashboard
dashboard

# Direct access
http://localhost:8080

# Features
- System monitoring
- GPU monitoring  
- Log management
- Service control
- Theme switching
```

### **qBittorrent (Port 9090):**
```bash
# Direct access
http://localhost:9090

# Default credentials
Username: admin
Password: adminadmin

# ⚠️ Remember to change default password!
```

### **Emby (Port 8096):**
```bash
# Direct access
http://localhost:8096

# Setup wizard on first visit
```

## 🔍 **Port Verification Commands**

### **Check what's running on each port:**
```bash
# Dashboard (should show Python process)
sudo lsof -i :8080

# Emby (should show dotnet process)  
sudo lsof -i :8096

# qBittorrent (should show qbittorrent-nox)
sudo lsof -i :9090

# Ollama (should show ollama process)
sudo lsof -i :11434
```

### **Quick health check:**
```bash
curl -s http://localhost:8080 > /dev/null && echo "✅ Dashboard OK"
curl -s http://localhost:8096 > /dev/null && echo "✅ Emby OK"
curl -s http://localhost:9090 > /dev/null && echo "✅ qBittorrent OK"
curl -s http://localhost:11434 > /dev/null && echo "✅ Ollama OK"
```

### **Network overview:**
```bash
# Show all listening ports
sudo netstat -tuln | grep -E ":(8080|8096|9090|11434)"

# Or with ss (modern replacement)
sudo ss -tuln | grep -E ":(8080|8096|9090|11434)"
```

## 🛠️ **Troubleshooting Port Issues**

### **If port 9090 is already in use:**
```bash
# Find what's using the port
sudo lsof -i :9090

# Kill the process (if safe to do so)
sudo kill -9 <PID>

# Or change qBittorrent port in config
sudo nano /var/lib/qbittorrent/.config/qBittorrent/qBittorrent.conf
# Change: WebUI\Port=9090 to WebUI\Port=9091 (or another free port)

# Restart qBittorrent service
sudo systemctl restart qbittorrent-nox
```

### **If Dashboard port 8080 conflicts:**
```bash
# Check what's using port 8080
sudo lsof -i :8080

# Dashboard can be configured to use different port if needed
# Edit: ~/dotfiles/dashboard/app/server.py
# Change: PORT = 8080 to PORT = 8081
```

## 📝 **Updated Documentation**

All documentation has been updated to reflect the new port allocation:

- ✅ **Installation scripts:** Port references updated
- ✅ **Service management:** Correct port descriptions
- ✅ **User guides:** Updated access URLs
- ✅ **Verification commands:** Correct port checks

## 🎉 **Result**

**No more port conflicts!** All services now run on dedicated ports:

- **Dashboard:** 8080 (system management)
- **Emby:** 8096 (media server)
- **qBittorrent:** 9090 (torrents)
- **Ollama:** 11434 (AI platform)

**Your installation system now provides conflict-free service access!** 🚀