# Building the Raspberry Pi HDMI Tester Image

This guide walks you through building the Raspberry Pi HDMI Tester image using GitHub Codespaces.

## Prerequisites

### GitHub Account
- Active GitHub account with Codespaces access
- Repository: https://github.com/benpaddlejones/Raspberry_HDMI_Tester

### System Resources (Provided by Codespaces)
- **OS**: Ubuntu 24.04 LTS (pre-configured)
- **RAM**: 4GB minimum, 8GB in Codespaces
- **Disk Space**: 32GB available in Codespaces
- **Architecture**: x86_64 with QEMU for ARM emulation

### Required Tools
All required tools are **pre-installed** in the GitHub Codespaces environment:

- `qemu-arm-static` - ARM emulation
- `debootstrap` - Debian bootstrapping
- `kpartx` - Partition management
- `parted` - Disk partitioning
- `git` - Version control
- `python3` - Build scripts
- `pi-gen` - Raspberry Pi OS image builder

Everything is ready to use - no manual installation needed!

## Quick Start

### Using GitHub Codespaces
1. **Open the repository** in GitHub Codespaces:
   - Navigate to https://github.com/benpaddlejones/Raspberry_HDMI_Tester
   - Click the green **Code** button
   - Select **Codespaces** tab
   - Click **Create codespace on main**

2. **Wait for initialization** (first time only, ~2-3 minutes):
   - Codespaces will automatically build the development container
   - All tools and dependencies will be configured
   - You'll see the VS Code interface when ready

3. **Run the build**:
   ```bash
   ./scripts/build-image.sh
   ```

That's it! The build process will start automatically.

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
**Cause**: This should never happen in Codespaces - the tool is pre-installed.

**Solution**: If you see this error, the container may not have initialized properly:
```bash
# Rebuild the Codespaces container:
# Command Palette (Ctrl+Shift+P) → "Codespaces: Rebuild Container"
```

### Build Fails with "Permission denied"
**Solution**: The build script needs sudo for some operations:
```bash
# pi-gen requires privileged access for chroot operations
# The script will prompt for sudo password when needed
# In Codespaces, you can use sudo without a password
```

### Build Fails with "No space left on device"
**Solution**: Codespaces provides 32GB storage, which should be sufficient.

If you still run out of space:
1. Check disk space: `df -h`
2. Clean old builds:
   ```bash
   sudo rm -rf build/pi-gen-work
   ```
3. Check for large files:
   ```bash
   du -sh build/* | sort -h
   ```

### Build Hangs or Takes Too Long
**Normal build time in Codespaces**: 45-60 minutes (first build)

**If taking longer**:
- Check internet connection in Codespaces (status bar)
- Check `build/pi-gen-work/work.log` for progress
- Codespaces may throttle during high usage periods

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

To start fresh in Codespaces:

```bash
# Remove all build artifacts
sudo rm -rf build/pi-gen-work

# Rebuild
./scripts/build-image.sh
```

## Downloading the Built Image

After the build completes, download the image from Codespaces:

### Method 1: Download via VS Code
1. Navigate to `build/pi-gen-work/deploy/` in the file explorer
2. Right-click `RaspberryPi_HDMI_Tester.img.zip`
3. Select **Download**
4. Save to your local computer

### Method 2: Using the Terminal
```bash
# The image is located at:
ls -lh build/pi-gen-work/deploy/RaspberryPi_HDMI_Tester.img*

# You can download it through the VS Code interface
```

The `.zip` file is compressed for faster download. Extract it on your local computer before flashing.

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
