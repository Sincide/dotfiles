# AI Health Check - Local LLM Diagnostics

Comprehensive monitoring and diagnostics for your local AI setup (Ollama, GPU acceleration, model performance).

## ✨ Features

- 🖥️ **System Resource Monitoring** - RAM, CPU, disk space analysis
- 🎯 **GPU Acceleration Detection** - NVIDIA/AMD GPU usage and VRAM monitoring
- 🤖 **Ollama Service Health** - Service status, API connectivity, version info
- 📊 **Model Analysis** - Installed models, sizes, categories, benchmarking
- ⚡ **Performance Testing** - Real-world speed tests with tokens/second metrics
- 💡 **Smart Recommendations** - Optimization tips based on your hardware
- 📱 **Interactive Menus** - Easy-to-use interface for all diagnostics

## 🚀 Quick Start

### Installation

1. **Download the script:**
   ```fish
   curl -O https://example.com/ai-health.fish
   chmod +x ai-health.fish
   ```

2. **Run health check:**
   ```fish
   ./ai-health.fish
   ```

### Prerequisites

- **Fish Shell** - Required for running the script
- **Ollama** (optional) - For AI model diagnostics
- **nvidia-smi** (optional) - For NVIDIA GPU monitoring
- **rocm-smi** (optional) - For AMD GPU monitoring

## 📚 Usage

### Interactive Mode (Recommended)
```fish
./ai-health.fish
```

This opens a comprehensive menu:
```
╭─────────────────────────────────────────────╮
│            AI Health Check                  │
│         Local LLM Diagnostics               │
╰─────────────────────────────────────────────╯

What would you like to check?

  1️⃣  Full Health Check (comprehensive)
  2️⃣  Quick Status (fast overview)
  3️⃣  GPU Diagnostics (detailed GPU info)
  4️⃣  Model Analysis (installed models)
  5️⃣  Performance Benchmark (speed test)
  6️⃣  System Resources (RAM, CPU, disk)
  7️⃣  Ollama Service Status
  8️⃣  Recommendations (optimization tips)

  0️⃣  Exit
```

### Command Line Mode
```fish
# Full comprehensive check
./ai-health.fish full

# Quick status overview
./ai-health.fish quick

# GPU-specific diagnostics
./ai-health.fish gpu

# Model analysis
./ai-health.fish models

# Performance benchmark
./ai-health.fish benchmark

# System resources only
./ai-health.fish system

# Ollama service status
./ai-health.fish ollama

# Optimization recommendations
./ai-health.fish recommendations

# Show help
./ai-health.fish help
```

## 🔍 What It Checks

### System Resources
- **RAM Usage**: Total, used, available memory with warnings for low RAM
- **CPU Information**: Model, core count, architecture details
- **Disk Space**: Available space with warnings for low storage
- **Performance Impact**: Resource usage recommendations

### GPU Acceleration
- **GPU Detection**: NVIDIA, AMD, Intel GPU identification
- **VRAM Monitoring**: Memory usage, total capacity, utilization
- **Driver Status**: CUDA, ROCm, driver version detection
- **Acceleration Testing**: Real-time GPU usage during inference

### Ollama Health
- **Service Status**: Running/stopped, memory usage, API connectivity
- **Version Information**: Ollama version, installation path
- **API Testing**: Endpoint responsiveness, connection health
- **Process Monitoring**: PID, memory consumption, startup status

### Model Analysis
- **Installed Models**: Complete list with sizes and categories
- **Model Categorization**: 
  - 🔧 Code (qwen2.5-coder, codegemma)
  - 🦙 Chat (llama models)
  - 💬 General (mistral, etc.)
- **Storage Usage**: Total disk space used by models
- **Model Metadata**: IDs, modification dates, download status

### Performance Benchmarking
- **Response Time**: End-to-end inference speed
- **Tokens Per Second**: Throughput measurements
- **Performance Rating**: Excellent/Good/Slow/Very Slow classification
- **Comparative Analysis**: Performance across different models

## 📊 Sample Output

### Quick Status
```
━━━ Quick Stats ━━━
[ℹ] System: AMD Ryzen 9 5900X, 32GB RAM
[ℹ] GPU: NVIDIA GeForce RTX 3080
[ℹ] Ollama: 5 models installed
[✓] Ollama: Responding normally
[ℹ] GPU VRAM: 2847 MB used
```

### GPU Information
```
━━━ GPU Information ━━━
┌─ GPU Information
│ ✓ NVIDIA GPU detected
│ GPU: NVIDIA GeForce RTX 3080
│ VRAM: 2847 MB / 10240 MB used
│ Utilization: 15%
│ ✓ CUDA 12.0 available
```

### Model Analysis
```
━━━ Installed Models ━━━
┌─ Installed Models
│ ✓ qwen2.5-coder:14b (9.0 GB) - 🔧 Code/Chat
│ ID: 9ec8897f747e
│ Modified: 7 hours ago

│ ✓ mistral:7b-instruct (4.1 GB) - 💬 Chat
│ ID: 3944fe81ec14
│ Modified: About an hour ago

│ Total models: 2
│ Total size: 13.1 GB
```

### Performance Benchmark
```
━━━ Benchmarking qwen2.5-coder:14b ━━━
┌─ Benchmarking qwen2.5-coder:14b
│ ✓ Response time: 2.34 seconds
│ ✓ Tokens per second: 18.5
│ Response: Sure! Here are the numbers from 1 to 10: 1, 2...
│ ◦ Performance: Good
```

## 🛠 Advanced Features

### GPU Acceleration Testing
The script actively tests GPU usage by:
1. Measuring baseline VRAM usage
2. Running a test inference
3. Measuring VRAM increase during inference
4. Determining if GPU acceleration is actually working

### Smart Recommendations
Based on your system, it suggests:
- **RAM Upgrades**: For better large model performance
- **GPU Drivers**: Installation recommendations
- **Model Selection**: Best models for your hardware
- **Optimization Tips**: Performance tuning advice

### Model Categorization
Automatically categorizes models by purpose:
- **Coding Models**: qwen2.5-coder, codegemma, etc.
- **Chat Models**: llama, mistral, etc.
- **Specialized**: Vision, embedding, etc.

## 🚨 Troubleshooting

### Common Issues

**"Ollama not installed"**
```fish
curl -fsSL https://ollama.ai/install.sh | sh
```

**"Ollama service not running"**
```fish
ollama serve
```

**"No models installed"**
```fish
ollama pull llama3.2:3b
ollama pull qwen2.5-coder:7b
```

**"GPU not detected"**
- Install NVIDIA drivers: Check your distro's instructions
- Install CUDA: `sudo apt install nvidia-cuda-toolkit`
- Verify: `nvidia-smi`

**"Poor performance"**
- Check available RAM: Close other applications
- Monitor GPU usage: Ensure GPU acceleration is working
- Try smaller models: qwen2.5-coder:7b instead of :14b

### Debug Mode
For detailed diagnostics:
```fish
# Add debug output to any command
DEBUG=1 ./ai-health.fish gpu
```

## 🎯 Hardware Recommendations

### Minimum Requirements
- **RAM**: 8GB (for 7B models)
- **Storage**: 10GB free space
- **CPU**: Modern multi-core processor

### Recommended Setup
- **RAM**: 16GB+ (for 14B+ models)
- **GPU**: NVIDIA RTX 3060+ or equivalent
- **Storage**: SSD with 50GB+ free space
- **CPU**: Recent AMD/Intel with 8+ cores

### Optimal Setup
- **RAM**: 32GB+ (for multiple large models)
- **GPU**: NVIDIA RTX 4070+ with 12GB+ VRAM
- **Storage**: NVMe SSD with 100GB+ free space
- **CPU**: High-end AMD Ryzen or Intel Core

## 📈 Performance Expectations

### Model Size vs Performance
- **1B-3B models**: 50+ tokens/sec (CPU), 100+ tokens/sec (GPU)
- **7B models**: 10-30 tokens/sec (CPU), 50+ tokens/sec (GPU)
- **14B+ models**: 5-15 tokens/sec (CPU), 20+ tokens/sec (GPU)

### GPU vs CPU Performance
- **GPU Acceleration**: 3-10x faster than CPU
- **VRAM Requirements**: Model size + 2-4GB overhead
- **Memory Bandwidth**: Critical for large models

## 🤝 Contributing

Contributions welcome! Areas for improvement:
- Additional GPU vendor support (Intel Arc, etc.)
- More model benchmarks
- Advanced performance profiling
- Container support (Docker, Podman)

### Development
Key functions:
- `check_gpu()` - GPU detection and monitoring
- `check_ollama_service()` - Ollama health checks
- `benchmark_model()` - Performance testing
- `health_recommendations()` - Smart suggestions

## 📄 License

This script is provided as-is for personal and educational use.

---

**Keep your AI healthy! 🤖💪**