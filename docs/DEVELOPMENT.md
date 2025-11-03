# Development Guide

This guide is for developers who want to build the Raspberry Pi HDMI Tester image from source, customize the build process, or contribute to the project.

## Development Environment

### Recommended Setup: GitHub Codespaces

**GitHub Codespaces is the primary supported development environment** for this project. It provides a pre-configured, consistent build environment accessible from any computer.

#### Why Codespaces?

- ✅ **Pre-configured environment** - All tools pre-installed
- ✅ **Consistent builds** - Same environment for everyone
- ✅ **32GB disk space** - Plenty for building images
- ✅ **No local setup** - Works from any computer
- ✅ **Free tier available** - 60 hours/month for free accounts

#### Getting Started with Codespaces

1. **Fork or clone the repository**:
   - Navigate to: https://github.com/benpaddlejones/Raspberry_HDMI_Tester
   - Click **"Fork"** (to contribute) or **"Use this template"**

2. **Create a Codespace**:
   - Click the green **"Code"** button
   - Select **"Codespaces"** tab
   - Click **"Create codespace on main"**

3. **Wait for initialization** (~2-3 minutes first time):
   - Dev container builds automatically
   - All dependencies are installed
   - VS Code interface opens when ready

4. **Verify setup**:
   ```bash
   # Check required tools
   which qemu-arm-static
   which kpartx
   which debootstrap
   ls -la /opt/pi-gen
   ```

### Alternative Development Options

⚠️ **Important**: These methods are **not officially supported**. GitHub Codespaces is the recommended environment.

#### Option 1: VS Code Dev Containers (Experimental)

1. **Prerequisites**:
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh

   # Install VS Code with Dev Containers extension
   code --install-extension ms-vscode-remote.remote-containers
   ```

2. **Clone and open**:
   ```bash
   git clone https://github.com/benpaddlejones/Raspberry_HDMI_Tester.git
   cd Raspberry_HDMI_Tester
   code .
   # Click "Reopen in Container" when prompted
   ```

#### Option 2: Native Linux (Advanced Users Only)

1. **Install dependencies** (Ubuntu/Debian):
   ```bash
   sudo apt update
   sudo apt install -y \
     git \
     qemu-user-static \
     qemu-utils \
     debootstrap \
     kpartx \
     build-essential \
     libarchive-tools \
     coreutils \
     quilt \
     parted \
     dosfstools \
     zip \
     unzip \
     curl \
     wget
   ```

2. **Clone pi-gen**:
   ```bash
   sudo mkdir -p /opt
   sudo git clone https://github.com/RPi-Distro/pi-gen.git /opt/pi-gen
   ```

3. **Clone repository**:
   ```bash
   git clone https://github.com/benpaddlejones/Raspberry_HDMI_Tester.git
   cd Raspberry_HDMI_Tester
   ```

## Project Structure

```
Raspberry_HDMI_Tester/
├── .devcontainer/              # Codespaces/Dev Container config
│   ├── devcontainer.json       # Container configuration
│   └── Dockerfile              # Container image definition
│
├── .github/                    # GitHub-specific files
│   ├── copilot-instructions.md # AI assistant guidance
│   └── workflows/              # CI/CD pipelines (future)
│
├── assets/                     # Media files for the image
│   ├── image.png               # Test pattern (1920x1080)
│   └── audio.mp3               # Test audio (infinite loop)
│
├── build/                      # Build configuration
│   ├── config                  # pi-gen configuration file
│   ├── stage3/                 # Skip desktop environment
│   │   └── SKIP
│   ├── stage4/                 # Skip recommended apps
│   │   └── SKIP
│   ├── stage5/                 # Skip extras
│   │   └── SKIP
│   └── stage-custom/           # Our custom build stages
│       ├── SKIP_IMAGES         # Don't build stage images
│       ├── 00-install-packages/    # Install system packages
│       │   ├── 00-packages         # Package list
│       │   └── 00-run-chroot.sh    # Installation script
│       ├── 01-test-image/          # Deploy test pattern
│       │   ├── 00-run.sh           # Copy script
│       │   └── files/              # Asset files
│       │       └── image.png
│       ├── 02-audio-test/          # Deploy audio file
│       │   ├── 00-run.sh
│       │   └── files/
│       │       └── audio.mp3
│       ├── 03-autostart/           # systemd services
│       │   ├── 00-run.sh
│       │   └── files/
│       │       ├── hdmi-display.service
│       │       └── hdmi-audio.service
│       └── 04-boot-config/         # HDMI configuration
│           └── 00-run.sh
│
├── scripts/                    # Build and utility scripts
│   ├── build-image.sh          # Main build orchestrator
│   ├── configure-boot.sh       # Boot configuration helper
│   ├── logging-utils.sh        # Logging functions
│   ├── analyze-logs.sh         # Log analysis tool
│   └── compare-logs.sh         # Log comparison tool
│
├── tests/                      # Testing scripts
│   ├── qemu-test.sh            # QEMU emulation testing
│   └── validate-image.sh       # Image validation
│
├── logs/                       # Build logs (auto-generated)
│   ├── successful-builds/      # Successful build logs
│   └── failed-builds/          # Failed build logs
│
├── docs/                       # Documentation
│   ├── BUILDING.md             # Build instructions
│   ├── FLASHING-Windows.md     # Windows flashing guide
│   ├── FLASHING-macOS.md       # macOS flashing guide
│   ├── FLASHING-Linux.md       # Linux flashing guide
│   ├── CUSTOMIZATION.md        # Customization options
│   ├── TROUBLESHOOTING-BUILD.md  # Build troubleshooting guide
│   ├── TROUBLESHOOTING-USER.md   # User troubleshooting guide
│   └── DEVELOPMENT.md          # This file
│
├── README.md                   # User-facing documentation
└── notes.txt                   # Development notes
```

## Building the Image

### Quick Build

```bash
# Build with default settings
./scripts/build-image.sh
```

### Build Options

```bash
# Clean build (remove previous work directory)
./scripts/build-image.sh --clean

# Specify custom config file
./scripts/build-image.sh --config path/to/custom-config

# Build only specific stages
./scripts/build-image.sh --stage 2

# Verbose output
./scripts/build-image.sh --verbose
```

### Build Configuration

Edit `build/config` to customize:

```bash
```bash
# Example build/config for HDMI Tester
IMG_NAME="RPi_HDMI_Tester_PiOS"

# Target Raspberry Pi OS release
RELEASE="bookworm"

# Networking
ENABLE_SSH=0  # Disabled by default for security
TARGET_HOSTNAME="hdmi-tester"

# User configuration
FIRST_USER_NAME="pi"
FIRST_USER_PASS="raspberry"  # Change for production!

# Build stages to include
STAGE_LIST="stage0 stage1 stage2 stage3"

# Compression
DEPLOY_COMPRESSION="zip"  # zip or xz
```
```

### Custom Build Stages

The project uses custom stages in `build/stage3/`:

#### Stage3/00: Install Packages

**Purpose**: Install required system packages

**Files**:
- `00-packages`: List of apt packages (one per line)

**Packages installed**:
- `vlc` - Audio/video player with hardware acceleration
- `ffmpeg` - Multimedia framework for codec support
- `edid-decode` - HDMI EDID troubleshooting utility
- `read-edid` - EDID reading tools
- `libdrm-tests` - GPU diagnostics
- `mesa-utils` - OpenGL utilities
- `vulkan-tools` - Vulkan diagnostics
- `sysstat` - System resource monitoring

#### Stage3/01: Test Image

**Purpose**: Deploy test videos and images

**Files**:
- `00-run.sh`: Copy script (runs on host)
- `files/`: Test pattern images and videos (WebM/MP4 formats)

**What it does**:
- Creates `/opt/hdmi-tester/` directory
- Copies test videos (image-test.webm, image-test.mp4, color-test.webm, color-test.mp4)
- Copies test images (image.png, black.png, white.png, red.png, green.png, blue.png)
- Sets proper permissions

#### Stage 02: Audio Test

**Purpose**: Deploy audio test file

**Files**:
- `00-run.sh`: Copy script
- `files/audio.mp3`: Test audio (infinite loop)

**What it does**:
- Copies `audio.mp3` to `/opt/hdmi-tester/`
- Sets proper permissions

#### Stage 03: Autostart Services

**Purpose**: Create systemd services for auto-start

**Files**:
- `00-run.sh`: Service installation script
- `files/hdmi-display.service`: Display service
- `files/hdmi-audio.service`: Audio service

**Services created**:
- `hdmi-display.service`: Displays test pattern using VLC (console mode)
- `hdmi-audio.service`: Plays audio using VLC (ALSA, console mode)

**What it does**:
- Copies service files to `/etc/systemd/system/`
- Enables services with systemctl
- Configures auto-start on boot (no desktop environment required)

#### Stage 04: Boot Configuration

**Purpose**: Configure HDMI output and auto-login

**Files**:
- `00-run.sh`: Configuration script

**Modifications**:
- `/boot/config.txt` or `/boot/firmware/config.txt`: HDMI settings (1920x1080@60Hz, audio enabled)
- `/boot/cmdline.txt` or `/boot/firmware/cmdline.txt`: Audio kernel parameters
- GPU memory set to 64MB (minimal, console mode doesn't need GPU acceleration)
- No desktop environment or compositor - pure framebuffer mode

## Technical Architecture

### Build System

**Base**: Raspberry Pi OS Lite (Debian 12 Bookworm)
- Minimal footprint (~1.5-2GB image)
- No desktop environment (console mode only)
- Direct display access via VLC, no compositor needed

**Builder**: pi-gen
- Official Raspberry Pi image builder
- Multi-stage build process
- Pre-installed at `/opt/pi-gen`

**Emulation**: QEMU
- Enables x86_64 hosts to build ARM images
- `qemu-arm-static` for chroot operations
- Transparent ARM binary execution

### Boot Flow

1. **Raspberry Pi boots** from SD card
2. **Kernel loads** with audio parameters (ALSA HDMI enabled)
3. **systemd starts** system services (including ALSA)
4. **Console mode** - no desktop environment or compositor
5. **systemd services start automatically**:
   - `hdmi-display.service` → Displays test pattern via VLC
   - `hdmi-audio.service` → Plays audio via VLC (ALSA direct output)
6. **Display shows** test pattern at 1920x1080@60Hz
7. **Audio plays** continuously through HDMI via ALSA

### HDMI Configuration

Configured in `/boot/config.txt`:

```ini
# Force HDMI output
hdmi_force_hotplug=1

# Enable HDMI audio
hdmi_drive=2

# Auto-detect display resolution (flexible for all displays and Pi models)
hdmi_group=0
hdmi_mode=0

# GPU memory allocation (256MB for video playback)
gpu_mem=256

# Enable audio on both HDMI and 3.5mm
dtparam=audio=on
```

### systemd Services

**hdmi-display.service**:
```ini
[Unit]
Description=HDMI Test Pattern Display (Framebuffer)
After=local-fs.target

[Service]
Type=simple
User=root
# Use VLC to display image
ExecStart=/usr/bin/vlc --loop --fullscreen --no-video-title-show --vout=drm --drm-vout-no-modeset /opt/hdmi-tester/image.png
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**hdmi-audio.service**:
```ini
[Unit]
Description=HDMI Audio Test - ALSA Output
After=sound.target
Wants=sound.target
After=multi-user.target

[Service]
Type=simple
User=pi
Group=audio
# Use ALSA for direct audio output with auto device selection
ExecStart=/bin/bash -c 'export AUDIODEV=default && /usr/bin/vlc --loop --no-video --aout=alsa --volume 512 --quiet /opt/hdmi-tester/audio.mp3'
Restart=always
RestartSec=15
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

## Testing

### QEMU Testing

Test the image in an emulator before hardware:

```bash
# Test built image
./tests/qemu-test.sh build/pi-gen-work/deploy/RPi_HDMI_Tester_PiOS.img

# Test with custom options
./tests/qemu-test.sh --ram 1024 --cpu cortex-a53 image.img
```

**Limitations**:
- HDMI output won't work in QEMU (no GPU emulation)
- Audio may not work
- Useful for testing boot process and systemd services

### Image Validation

Validate the image before distribution:

```bash
./tests/validate-image.sh build/pi-gen-work/deploy/RPi_HDMI_Tester_PiOS.img
```

**Checks**:
- Image file exists and is correct size
- Partitions are valid
- Boot files are present
- Custom files are deployed
- systemd services are enabled

### Hardware Testing

1. **Flash to SD card** (see platform-specific flashing guides)
2. **Insert into Raspberry Pi**
3. **Connect HDMI to display**
4. **Connect power supply**
5. **Verify**:
   - ✅ Boot time < 30 seconds
   - ✅ Test pattern displays at 1920x1080
   - ✅ Audio plays continuously
   - ✅ No errors on screen
   - ✅ Green LED blinks (activity)

## Logging and Debugging

### Build Logs

The build system uses a comprehensive two-tier logging system:

**Terminal (User-facing)**:
- Major milestones only
- Progress indicators
- Error highlights

**Log File (Debugging)**:
- Complete build environment capture
- All stdout/stderr output
- Stage timing information
- Resource usage monitoring
- File checksums
- Error context

**Log Locations**:
- **During build**: `build/pi-gen-work/build-detailed.log`
- **After build**: `logs/successful-builds/` or `logs/failed-builds/`
- **GitHub Actions**: Artifacts (90-day retention)

### Log Analysis

**Analyze a single log**:
```bash
./scripts/analyze-logs.sh logs/failed-builds/build-2025-10-18_14-30-00_FAILED.log
```

**Compare two logs**:
```bash
./scripts/compare-logs.sh \
  logs/successful-builds/build-2025-10-17_10-00-00_v1.0.0.log \
  logs/failed-builds/build-2025-10-18_14-30-00_FAILED.log
```

**Search for errors**:
```bash
grep -i "error" build/pi-gen-work/build-detailed.log
grep -i "failed" build/pi-gen-work/build-detailed.log
```

### Common Build Issues

See [TROUBLESHOOTING-BUILD.md](TROUBLESHOOTING-BUILD.md) for comprehensive troubleshooting.

## Customization

### Change Test Pattern

Replace `assets/image.png` with your own:

```bash
# Requirements:
# - Resolution: 1920x1080 or 3840x2160
# - Format: PNG or JPEG
# - Size: < 5MB recommended
# - Location: assets/image.png

cp /path/to/your/image.png assets/image.png
```

### Change Audio File

Replace `assets/audio.mp3`:

```bash
# Requirements:
# - Format: MP3, WAV, or OGG
# - Duration: Any (will loop infinitely)
# - Size: < 10MB recommended
# - Location: assets/audio.mp3

cp /path/to/your/audio.mp3 assets/audio.mp3
```

### Modify HDMI Settings

Edit `build/stage3/04-boot-config/00-run.sh`:

```bash
# Current: Auto-detect resolution (flexible for all displays)
hdmi_group=0    # 0=Auto-detect
hdmi_mode=0     # 0=Auto-detect

# To hardcode a specific resolution, use:
# hdmi_group=1    # 1=CEA (HDTV), 2=DMT (monitors)
# hdmi_mode=16    # 16=1920x1080@60Hz

# Available modes (if hardcoding):
# Mode 4: 1280x720@60Hz
# Mode 16: 1920x1080@60Hz
# Mode 82: 1080p@60Hz (DMT)
# Mode 85: 1280x720@60Hz (DMT)
```

### Add Custom Packages

Edit `build/stage-custom/00-install-packages/00-packages`:

```
# Add one package per line
vim
htop
tmux
```

### Modify Boot Behavior

Edit systemd services in `build/stage-custom/03-autostart/files/`:

```bash
# Change display behavior
nano build/stage-custom/03-autostart/files/hdmi-display.service

# Change audio behavior
nano build/stage-custom/03-autostart/files/hdmi-audio.service
```

## Contributing

We welcome contributions! Here's how to get involved:

### Reporting Issues

1. **Check existing issues** at: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
2. **Search for duplicates** before creating a new issue
3. **Create a new issue** with:
   - Clear title describing the problem
   - Detailed description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Raspberry Pi model, etc.)
   - Relevant logs (use `analyze-logs.sh`)

### Submitting Pull Requests

1. **Fork the repository**:
   - Click "Fork" on GitHub
   - Clone your fork locally

2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**:
   - Follow existing code style
   - Add comments to complex sections
   - Update documentation if needed

4. **Test your changes**:
   - Build the image
   - Test in QEMU
   - Test on hardware if possible

5. **Commit with clear messages**:
   ```bash
   git commit -m "feat: add support for 4K resolution"
   ```

   Use conventional commit format:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `refactor:` - Code refactoring
   - `test:` - Test changes
   - `chore:` - Maintenance tasks

6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create Pull Request**:
   - Go to your fork on GitHub
   - Click "New Pull Request"
   - Provide clear description of changes
   - Reference related issues

### Contribution Guidelines

- **Code Style**: Follow existing patterns
- **Documentation**: Update docs for user-facing changes
- **Logging**: Use the two-tier logging system for new scripts
- **Testing**: Test on multiple Raspberry Pi models if possible
- **Commits**: Use clear, descriptive commit messages
- **Pull Requests**: Keep them focused on a single feature/fix

## Resources

### Official Documentation
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [pi-gen GitHub](https://github.com/RPi-Distro/pi-gen)
- [Raspberry Pi config.txt](https://www.raspberrypi.com/documentation/computers/config_txt.html)
- [systemd Documentation](https://www.freedesktop.org/software/systemd/man/)

### Build Tools
- [QEMU Documentation](https://www.qemu.org/docs/master/)
- [debootstrap](https://wiki.debian.org/Debootstrap)
- [kpartx](https://linux.die.net/man/8/kpartx)

### Media Tools
- [VLC Media Player](https://www.videolan.org/vlc/)
- [ALSA Documentation](https://www.alsa-project.org/wiki/Main_Page)

### Community
- [Raspberry Pi Forums](https://forums.raspberrypi.com/)
- [pi-gen Issue Tracker](https://github.com/RPi-Distro/pi-gen/issues)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/raspberry-pi)

## Support

- **Issues**: [GitHub Issues](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues)
- **Discussions**: [GitHub Discussions](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/discussions)
- **Documentation**: See `docs/` directory

## License

This project is licensed under the MIT License with GPL components from pi-gen.

See the [LICENSE](../LICENSE) file for full details.

---

**Last Updated**: October 19, 2025
**Version**: 1.0.0
