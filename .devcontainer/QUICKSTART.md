# Dev Container Quick Start Guide

## 🚀 Getting Started in 3 Steps

### 1. Open in Codespaces
Click the "Code" button → "Codespaces" → "Create codespace on main"

### 2. Wait for Setup (5-10 minutes first time)
The container will automatically:
- ✅ Install all dependencies
- ✅ Set up pi-gen tools
- ✅ Create project structure
- ✅ Configure environment

### 3. Start Building!
```bash
check-deps      # Verify everything is ready
setup-pi-gen    # Initialize pi-gen workspace
```

## 📦 What's Pre-Installed

| Category | Tools |
|----------|-------|
| **Build Tools** | gcc, make, cmake, pi-gen |
| **Emulation** | QEMU (ARM support enabled) |
| **Image Building** | debootstrap, kpartx, parted |
| **Languages** | Python 3, Bash |
| **Utilities** | git, docker, ImageMagick, ffmpeg |

## 🛠️ Common Commands

```bash
# Check dependencies
check-deps

# Set up pi-gen
setup-pi-gen

# Build the image (when scripts are ready)
sudo ./scripts/build-image.sh

# Test in QEMU (when tests are ready)
./tests/qemu-test.sh build/output/hdmi-tester.img

# Check disk space
df -h /workspace

# Clean build artifacts
sudo rm -rf build/work/*
```

## 📁 Directory Structure

```
/workspaces/Raspberry_HDMI_Tester/  ← Your workspace
├── .devcontainer/                   ← Container config
├── build/                           ← Build files
├── assets/                          ← Test patterns & audio
├── scripts/                         ← Build scripts
├── docs/                            ← Documentation
└── tests/                           ← Test scripts

/opt/pi-gen/                         ← Pre-installed pi-gen
```

## 🔧 Useful Aliases

Already set up in your shell:
- `ll` → `ls -lah` (detailed file listing)
- `gs` → `git status` (quick git status)

## 📝 Environment Variables

- `$PI_GEN_BASE` → `/opt/pi-gen`
- `$SHELL` → `/bin/bash`

## 🐛 Troubleshooting

### Container won't start
```bash
# Check Docker status
docker ps

# View container logs
docker logs <container-id>
```

### Need more disk space
```bash
# Check usage
ncdu /workspace

# Clean Docker
docker system prune -a
```

### QEMU not working
```bash
# Check ARM support
update-binfmts --display qemu-arm

# Re-enable if needed
sudo update-binfmts --enable qemu-arm
```

## 💡 Pro Tips

1. **Save disk space**: Clean build/work/ between builds
2. **Speed up builds**: Keep pi-gen cache intact
3. **Use tmux**: Build in background with `tmux` or `screen`
4. **Monitor resources**: Use `htop` to check CPU/RAM usage

## 🔄 Rebuilding Container

Made changes to `.devcontainer/`?

**Codespaces:**
- Press `F1` → "Codespaces: Rebuild Container"

**VS Code Dev Containers:**
- Press `F1` → "Dev Containers: Rebuild Container"

## 📚 Documentation

- Main README: `/workspaces/Raspberry_HDMI_Tester/README.md`
- Dev Container Details: `.devcontainer/README.md`
- Building Guide: `docs/BUILDING.md` (when created)

## 🆘 Need Help?

1. Run `check-deps` to verify setup
2. Check `.devcontainer/README.md` for details
3. Review logs in the terminal
4. Open an issue on GitHub

---

**Welcome to the Raspberry Pi HDMI Tester development environment! 🎉**
