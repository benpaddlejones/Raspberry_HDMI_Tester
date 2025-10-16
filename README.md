# Raspberry Pi HDMI Tester

A lightweight Raspberry Pi OS image that automatically boots and displays a test pattern with audio output. This tool is designed to quickly test HDMI displays and audio connectivity by loading from an SD card without any user interaction.

## Project Overview

This project creates a custom Raspberry Pi image that:
- Automatically boots into a graphical test pattern
- Plays continuous audio output through HDMI
- Requires no keyboard, mouse, or user interaction
- Boots quickly to facilitate rapid testing
- Can be flashed to an SD card for portable HDMI testing

## Use Cases

- Testing HDMI displays and monitors
- Verifying HDMI audio output
- Quick connectivity checks for A/V equipment
- Trade show booth display testing
- Digital signage troubleshooting

## Requirements

### Hardware
- **Raspberry Pi** (recommended: Pi 4, Pi 3B+, or newer)
  - Minimum 1GB RAM
  - HDMI output port
- **MicroSD Card** (minimum 4GB, recommended 8GB+)
- **Power Supply** (appropriate for your Pi model)
- **HDMI Cable**
- **Display with HDMI input**

### Software Dependencies

#### Development Environment
- **GitHub Codespaces** or local development machine
- **Docker** (for containerized development)
- **Git** (for version control)

#### Build Tools
- **pi-gen** - Official Raspberry Pi OS image builder
- **qemu-user-static** - For ARM emulation on x86 systems
- **debootstrap** - Debian/Ubuntu bootstrapping tool
- **kpartx** - Partition management tool
- **build-essential** - Compilation tools
- **zip/unzip** - Archive utilities

#### Runtime Components (to be included in image)
- **Raspberry Pi OS Lite** (minimal base)
- **X11** or **Wayland** - Display server
- **feh** or **fbi** - Image viewer for test patterns
- **omxplayer** or **mpv** - Audio/video player
- **Plymouth** - Boot splash (optional)
- **systemd** - Service management for auto-start

## Project Structure

```
Raspberry_HDMI_Tester/
├── .devcontainer/
│   ├── devcontainer.json       # Codespaces configuration
│   └── Dockerfile              # Development container setup
├── build/
│   ├── config                  # pi-gen configuration
│   └── stage-custom/           # Custom build stage
│       ├── 00-install-packages/
│       ├── 01-test-image/
│       ├── 02-audio-test/
│       └── 03-autostart/
├── assets/
│   ├── test-pattern.png        # HDMI test pattern image
│   └── test-audio.wav          # Audio test file
├── scripts/
│   ├── build-image.sh          # Main build script
│   ├── configure-boot.sh       # Boot configuration
│   └── setup-autostart.sh      # Auto-launch setup
├── docs/
│   ├── BUILDING.md             # Build instructions
│   ├── FLASHING.md             # SD card flashing guide
│   └── CUSTOMIZATION.md        # Customization options
├── tests/
│   └── qemu-test.sh            # QEMU testing script
├── README.md                   # This file
└── LICENSE                     # Project license

```

## Development Setup

### Option 1: GitHub Codespaces (Recommended)

1. **Create Codespace**
   - Click "Code" → "Codespaces" → "Create codespace on main"
   - Codespace will automatically configure using `.devcontainer/devcontainer.json`

2. **Wait for Container Setup**
   - Dependencies will be installed automatically
   - This may take 5-10 minutes on first launch

3. **Verify Setup**
   ```bash
   # Check required tools
   which qemu-arm-static
   dpkg --version
   docker --version
   ```

### Option 2: Local Development with Docker

1. **Prerequisites**
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   
   # Install VS Code with Dev Containers extension
   code --install-extension ms-vscode-remote.remote-containers
   ```

2. **Clone and Open**
   ```bash
   git clone https://github.com/benpaddlejones/Raspberry_HDMI_Tester.git
   cd Raspberry_HDMI_Tester
   code .
   # Use "Reopen in Container" when prompted
   ```

### Option 3: Native Linux Development

1. **Install Dependencies**
   ```bash
   # Ubuntu/Debian
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

2. **Clone Repository**
   ```bash
   git clone https://github.com/benpaddlejones/Raspberry_HDMI_Tester.git
   cd Raspberry_HDMI_Tester
   ```

## Building the Image

### Step-by-Step Build Process

1. **Configure Build Settings**
   ```bash
   # Edit build/config to customize
   nano build/config
   ```

2. **Run Build Script**
   ```bash
   # Build the image (requires ~4GB free space)
   sudo ./scripts/build-image.sh
   ```

3. **Monitor Build Progress**
   - Build typically takes 30-60 minutes
   - Output will be in `build/output/`

4. **Locate Final Image**
   ```bash
   ls -lh build/output/*.img
   ```

### Quick Build Commands

```bash
# Full clean build
sudo ./scripts/build-image.sh --clean

# Build with custom config
sudo ./scripts/build-image.sh --config custom-config

# Build specific stage only
sudo ./scripts/build-image.sh --stage 2
```

## Flashing to SD Card

### Using Raspberry Pi Imager (Easiest)

1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Select "Use custom" image
3. Choose your built `.img` file
4. Select SD card
5. Write

### Using `dd` (Linux/Mac)

```bash
# Find SD card device
lsblk

# Flash image (replace /dev/sdX with your SD card)
sudo dd if=build/output/hdmi-tester.img of=/dev/sdX bs=4M status=progress conv=fsync

# Safely eject
sudo sync
sudo eject /dev/sdX
```

### Using Balena Etcher

1. Download [Balena Etcher](https://www.balena.io/etcher/)
2. Select image file
3. Select target SD card
4. Flash!

## Testing

### QEMU Testing (Before Hardware)

```bash
# Test image in emulator
./tests/qemu-test.sh build/output/hdmi-tester.img
```

### Hardware Testing

1. Insert SD card into Raspberry Pi
2. Connect HDMI cable to display
3. Connect power supply
4. Verify:
   - Test pattern appears on screen
   - Audio plays through HDMI
   - Boot time is acceptable

## Customization

### Custom Test Pattern

Replace `assets/test-pattern.png` with your own image:
- Recommended resolution: 1920x1080 or 3840x2160
- Format: PNG, JPEG
- Include color bars, resolution info, etc.

### Custom Audio

Replace `assets/test-audio.wav` with your own audio:
- Format: WAV, MP3, or FLAC
- Recommended: 1kHz tone or sweep
- Duration: 5-30 seconds (loops automatically)

### Boot Configuration

Edit `scripts/configure-boot.sh` to modify:
- Boot splash screen
- Auto-login settings
- Display resolution
- Audio output routing

## Troubleshooting

### Build Issues

- **Out of disk space**: Ensure at least 4GB free
- **Permission denied**: Use `sudo` for build commands
- **Missing dependencies**: Run `sudo apt update && sudo apt install -y <package>`

### Runtime Issues

- **No display**: Check HDMI cable, try different resolution in `config.txt`
- **No audio**: Verify HDMI audio in `config.txt`: `hdmi_drive=2`
- **Slow boot**: Disable unnecessary services in build configuration

## Development Roadmap

- [x] Project setup and documentation
- [ ] Dev container configuration
- [ ] Create test pattern assets
- [ ] Configure pi-gen build system
- [ ] Implement auto-start service
- [ ] Audio playback integration
- [ ] Boot optimization
- [ ] QEMU testing framework
- [ ] CI/CD pipeline for automated builds
- [ ] Multi-resolution support
- [ ] Web interface for configuration (optional)

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

[Choose appropriate license - MIT, GPL, etc.]

## Resources

- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [pi-gen GitHub](https://github.com/RPi-Distro/pi-gen)
- [Raspberry Pi OS Customization](https://www.raspberrypi.com/documentation/computers/os.html#customising-raspberry-pi-os)

## Support

- **Issues**: [GitHub Issues](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues)
- **Discussions**: [GitHub Discussions](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/discussions)

---

**Note**: This project is designed for testing purposes. For production digital signage, consider more robust solutions with remote management capabilities.