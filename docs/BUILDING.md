# Building the Raspberry Pi HDMI Tester Image

This guide walks you through building the Raspberry Pi HDMI Tester image from source.

## Prerequisites

### System Requirements
- **OS**: Ubuntu 24.04 LTS (or compatible Linux distribution)
- **RAM**: 4GB minimum, 8GB recommended
- **Disk Space**: 10GB free space minimum
- **Architecture**: x86_64 (uses QEMU for ARM emulation)

### Required Tools
All required tools are pre-installed in the development container. If building outside the container, you need:

- `qemu-arm-static` - ARM emulation
- `debootstrap` - Debian bootstrapping
- `kpartx` - Partition management
- `parted` - Disk partitioning
- `git` - Version control
- `docker` - Containerization (optional)
- `python3` - Build scripts

To verify tools are installed:
```bash
./scripts/check-deps
```

## Quick Start

### Option 1: Using GitHub Codespaces (Recommended)
1. Open the repository in GitHub Codespaces
2. Wait for the dev container to build (automatic)
3. Run the build:
   ```bash
   ./scripts/build-image.sh
   ```

### Option 2: Using VS Code Dev Containers
1. Clone the repository:
   ```bash
   git clone https://github.com/benpaddlejones/Raspberry_HDMI_Tester.git
   cd Raspberry_HDMI_Tester
   ```
2. Open in VS Code with Dev Containers extension
3. Reopen in container (VS Code will prompt)
4. Run the build:
   ```bash
   ./scripts/build-image.sh
   ```

### Option 3: Local Build (Advanced)
1. Install all prerequisites
2. Clone the repository
3. Run the build:
   ```bash
   ./scripts/build-image.sh
   ```

## Build Process

### What the Build Does
The `build-image.sh` script:
1. **Checks prerequisites** - Verifies all required tools are available
2. **Prepares workspace** - Creates a clean pi-gen working directory
3. **Copies custom stages** - Installs all 5 custom build stages
4. **Deploys assets** - Copies test pattern and audio files
5. **Runs pi-gen** - Executes the official Raspberry Pi OS builder
6. **Creates image** - Produces a bootable `.img` file

### Build Stages
The build process uses these custom stages:

1. **00-install-packages** - Installs X11, feh, mpv, audio utilities
2. **01-test-image** - Deploys test pattern (1920x1080 PNG)
3. **02-audio-test** - Deploys audio file (MP3)
4. **03-autostart** - Configures systemd services for auto-boot
5. **04-boot-config** - Sets HDMI to 1920x1080@60Hz

### Build Time
- **First build**: 45-60 minutes (downloads packages)
- **Subsequent builds**: 30-45 minutes (uses cached packages)

### Build Output
After successful build, you'll find:
```
build/pi-gen-work/deploy/
├── RaspberryPi_HDMI_Tester.img          # Bootable image file
├── RaspberryPi_HDMI_Tester.img.zip      # Compressed image
└── build.log                             # Build log
```

## Troubleshooting

### Build Fails with "qemu-arm-static not found"
**Solution**: The dev container should have this pre-installed. If building locally:
```bash
sudo apt-get update
sudo apt-get install qemu-user-static
```

### Build Fails with "Permission denied"
**Solution**: The build script needs sudo for some operations:
```bash
# pi-gen requires privileged access for chroot operations
# The script will prompt for sudo password when needed
```

### Build Fails with "No space left on device"
**Solution**:
1. Check disk space: `df -h`
2. Clean old builds:
   ```bash
   sudo rm -rf build/pi-gen-work
   ```
3. Docker cleanup (if using containers):
   ```bash
   docker system prune -a
   ```

### Build Hangs or Takes Too Long
**Possible causes**:
- Slow internet connection (downloading packages)
- Insufficient RAM (increase if using VM)
- Docker resource limits (increase in Docker settings)

**Solution**: Be patient on first build. Check `build/pi-gen-work/work.log` for progress.

### Build Succeeds but Image is Too Large
**Expected size**: ~1.5-2GB for minimal image

**If larger**:
- Check `build/config` - ensure `ENABLE_REDUCE_DISK_USAGE=1`
- Verify stage3, stage4, stage5 are skipped (check SKIP files)

## Validating the Built Image

After building, validate the image:

```bash
sudo ./tests/validate-image.sh build/pi-gen-work/deploy/*.img
```

This checks:
- ✅ Test pattern file exists (1920x1080)
- ✅ Audio file exists
- ✅ Systemd services are present
- ✅ HDMI configuration is correct
- ✅ Services are enabled

## Advanced Configuration

### Customizing the Image

**Change hostname:**
Edit `build/config`:
```bash
TARGET_HOSTNAME="my-hdmi-tester"
```

**Change default password:**
Edit `build/config`:
```bash
FIRST_USER_PASS="mypassword"
```

**Add additional packages:**
Edit `build/stage-custom/00-install-packages/00-packages`:
```
xserver-xorg
xinit
feh
mpv
alsa-utils
pulseaudio
your-package-here
```

**Replace test pattern:**
Replace `assets/image.png` with your own 1920x1080 PNG image, then rebuild.

**Replace audio file:**
Replace `assets/audio.mp3` with your own audio file, then rebuild.

### Build Configuration Reference

Key settings in `build/config`:

| Setting | Default | Description |
|---------|---------|-------------|
| `IMG_NAME` | `RaspberryPi_HDMI_Tester` | Output image filename |
| `RELEASE` | `bookworm` | Debian version (12) |
| `TARGET_HOSTNAME` | `hdmi-tester` | System hostname |
| `FIRST_USER_NAME` | `pi` | Default username |
| `FIRST_USER_PASS` | `raspberry` | Default password |
| `ENABLE_SSH` | `0` | SSH disabled (not needed) |
| `ENABLE_REDUCE_DISK_USAGE` | `1` | Minimize image size |

## Clean Build

To start fresh:

```bash
# Remove all build artifacts
sudo rm -rf build/pi-gen-work

# Rebuild
./scripts/build-image.sh
```

## Next Steps

After building:
1. **Validate**: `sudo ./tests/validate-image.sh build/pi-gen-work/deploy/*.img`
2. **Test in QEMU** (optional): `./tests/qemu-test.sh build/pi-gen-work/deploy/*.img`
3. **Flash to SD card**: See [FLASHING.md](FLASHING.md)

## Getting Help

- **Build logs**: Check `build/pi-gen-work/work.log`
- **Pi-gen documentation**: https://github.com/RPi-Distro/pi-gen
- **Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **GitHub Issues**: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
