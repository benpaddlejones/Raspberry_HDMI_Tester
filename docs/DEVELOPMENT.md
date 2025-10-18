# Development Guide

This guide is for developers who want to build the Raspberry Pi HDMI Tester image from source, customize the build process, or contribute to the project.

## Development Environment

### Prerequisites

- **GitHub Account** with Codespaces access
- **Git** knowledge (basic commands)
- **Linux/Bash** familiarity
- **Docker** understanding (optional, for local development)

### Recommended Setup: GitHub Codespaces

The project is optimized for GitHub Codespaces with a pre-configured development container.

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

### Alternative: Local Development

#### Option 1: Dev Container (VS Code)

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

#### Option 2: Native Linux

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
│   ├── TROUBLESHOOTING.md      # Troubleshooting guide
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
# Image naming
IMG_NAME="RaspberryPi_HDMI_Tester"

# Target Raspberry Pi OS release
RELEASE="bookworm"

# Localization
LOCALE_DEFAULT="en_US.UTF-8"
TIMEZONE_DEFAULT="America/New_York"

# Networking
ENABLE_SSH=0  # Disabled for security
HOSTNAME="hdmi-tester"

# User configuration
FIRST_USER_NAME="pi"
FIRST_USER_PASS="raspberry"  # Change for production!

# Build stages to include
STAGE_LIST="stage0 stage1 stage2 stage-custom"

# Compression
COMPRESSION="zip"  # zip, xz, or none
```

### Custom Build Stages

The project uses 5 custom stages:

#### Stage 00: Install Packages

**Purpose**: Install required system packages

**Files**:
- `00-packages`: List of apt packages (one per line)
- `00-run-chroot.sh`: Runs inside chroot, installs packages

**Packages installed**:
- `xserver-xorg` - X11 display server
- `xinit` - X initialization
- `feh` - Lightweight image viewer
- `mpv` - Media player with loop support
- `alsa-utils` - Audio utilities
- `pulseaudio` - Sound server

#### Stage 01: Test Image

**Purpose**: Deploy test pattern image

**Files**:
- `00-run.sh`: Copy script (runs on host)
- `files/image.png`: Test pattern (1920x1080)

**What it does**:
- Creates `/opt/hdmi-tester/` directory
- Copies `image.png` to target
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
- `hdmi-display.service`: Launches feh with test pattern
- `hdmi-audio.service`: Plays audio with mpv --loop=inf

**What it does**:
- Copies service files to `/etc/systemd/system/`
- Enables services with systemctl
- Configures auto-start on boot

#### Stage 04: Boot Configuration

**Purpose**: Configure HDMI output and auto-login

**Files**:
- `00-run.sh`: Configuration script

**Modifications**:
- `/boot/config.txt`: HDMI settings (1920x1080@60Hz, audio enabled)
- `/etc/systemd/system/getty@tty1.service.d/autologin.conf`: Auto-login
- `/home/pi/.bashrc`: Auto-start X server

## Technical Architecture

### Build System

**Base**: Raspberry Pi OS Lite (Debian 12 Bookworm)
- Minimal footprint (~1.5-2GB image)
- No desktop environment by default
- X11 added in custom stage

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
2. **Kernel loads** with optimized parameters
3. **systemd starts** system services
4. **Auto-login** on tty1 (user: `pi`)
5. **.bashrc executes** → Starts X server
6. **X server launches** (no window manager)
7. **systemd services start**:
   - `hdmi-display.service` → Displays test pattern (feh)
   - `hdmi-audio.service` → Plays audio (mpv --loop=inf)
8. **Display shows** test pattern at 1920x1080@60Hz
9. **Audio plays** continuously through HDMI

### HDMI Configuration

Configured in `/boot/config.txt`:

```ini
# Force HDMI output
hdmi_force_hotplug=1

# Enable HDMI audio
hdmi_drive=2

# Set resolution to 1920x1080@60Hz
hdmi_group=1
hdmi_mode=16

# GPU memory allocation
gpu_mem=128
```

### systemd Services

**hdmi-display.service**:
```ini
[Unit]
Description=HDMI Test Pattern Display
After=graphical.target
Wants=graphical.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
ExecStart=/usr/bin/feh --fullscreen --hide-pointer --no-fehbg /opt/hdmi-tester/image.png
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
```

**hdmi-audio.service**:
```ini
[Unit]
Description=HDMI Audio Test
After=sound.target
Wants=sound.target

[Service]
Type=simple
User=pi
ExecStart=/usr/bin/mpv --no-video --loop=inf /opt/hdmi-tester/audio.mp3
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

## Testing

### QEMU Testing

Test the image in an emulator before hardware:

```bash
# Test built image
./tests/qemu-test.sh build/output/RaspberryPi_HDMI_Tester.img

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
./tests/validate-image.sh build/output/RaspberryPi_HDMI_Tester.img
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

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for comprehensive troubleshooting.

## Customization

### Change Test Pattern

Replace `assets/image.png` with your own:

```bash
# Requirements:
# - Resolution: 1920x1080 or 3840x2160
# - Format: PNG or JPEG
# - Size: < 5MB recommended

cp /path/to/your/image.png assets/image.png
```

### Change Audio File

Replace `assets/audio.mp3`:

```bash
# Requirements:
# - Format: MP3, WAV, or OGG
# - Duration: Any (will loop infinitely)
# - Size: < 10MB recommended

cp /path/to/your/audio.mp3 assets/audio.mp3
```

### Modify HDMI Settings

Edit `build/stage-custom/04-boot-config/00-run.sh`:

```bash
# Change resolution
hdmi_group=1    # 1=CEA (HDTV), 2=DMT (monitors)
hdmi_mode=16    # 16=1920x1080@60Hz

# Available modes:
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
- [feh Image Viewer](https://feh.finalrewind.org/)
- [mpv Media Player](https://mpv.io/)
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

[Choose appropriate license - MIT, GPL, etc.]

---

**Happy Building!** 🚀
