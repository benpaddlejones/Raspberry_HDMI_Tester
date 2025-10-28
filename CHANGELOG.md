# Changelog

All notable changes to the Raspberry Pi HDMI Tester project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.8] - 2025-10-28 (Release Candidate)

### Core Features
- **Configuration System**: Centralized configuration file (`/boot/firmware/hdmi-tester.conf`)
  - `DEBUG_MODE`: Control verbose logging system-wide (true/false)
  - `DEFAULT_SERVICE`: Set auto-start service on boot (or none for terminal)
  - Accessible from Windows/Mac when SD card is mounted

- **Interactive Configuration Tool**: `hdmi-tester-config`
  - User-friendly TUI menu (raspi-config style)
  - Toggle debug mode on/off
  - Set default service to auto-start on boot
  - Run any service one-time without changing defaults
  - View/edit configuration file
  - Pre/post diagnostics guidance with GitHub issue integration

- **Auto-Launch System**
  - Boots to console with auto-login (user: pi)
  - Automatically launches configured default service
  - Ctrl+C from any service returns to configuration menu
  - No default service = boot to terminal with welcome message

### Test Services
- **hdmi-test**: Loop HDMI video test pattern with resolution overlay
- **pixel-test**: Fullscreen color test pattern (stretched to all pixels)
- **image-test**: Rotate through static color test images
- **audio-test**: Loop stereo and 5.1 surround FLAC audio
- **full-test**: Combined video and audio test sequence
- **hdmi-diagnostics**: Complete system diagnostics with USB auto-save

### Media Assets
- WebM VP9 video format (Pi 4+) with H.264 fallback (Pi 3)
- FLAC audio files (stereo + 5.1 surround)
- PNG test pattern images (black, white, red, green, blue, custom)
- Auto-detect HDMI resolution (720p, 1080p, 4K)

### Build Optimizations
- Build time: 39-41 minutes (33% improvement from baseline)
- Image size: Reduced by 400-500MB through package optimization
- Compression: Parallel gzip (pigz) - 80% faster
- QEMU kernel fix for automated boot testing
- Stage2 package exclusions (44 unnecessary packages removed)
- APT update caching to prevent redundant operations

### Performance
- Boot to display: ~30 seconds
- VLC debug flags: Configurable via DEBUG_MODE
- Dynamic HDMI audio device detection
- Optimized filesystem with zerofree before compression

### Documentation
- Complete user and developer documentation
- Multi-platform flashing guides (Windows, macOS, Linux)
- Customization guides for test patterns and audio
- Troubleshooting guides (user and build)
- GitHub issue integration in diagnostics tool

### System Features
- SSH enabled by default (username: pi, password: raspberry)
- Compatible with Pi 3, 4, 5, Zero 2 W
- Console auto-login on TTY1
- Systemd services for all test modes
- Comprehensive logging with rotation

### Default Configuration
- `DEBUG_MODE=true` - Verbose logging enabled by default
- `DEFAULT_SERVICE=` - No auto-start service (boots to terminal)
- User can configure via `hdmi-tester-config` tool or edit `/boot/firmware/hdmi-tester.conf`

---

## Version Numbering

- **Major version (X.0.0)**: Breaking changes or major feature releases
- **Minor version (0.X.0)**: New features, backward compatible
- **Patch version (0.0.X)**: Bug fixes, optimizations, documentation updates

## Links

- [Latest Release](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/releases/latest)
- [All Releases](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/releases)
- [Issues](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues)
- [Pull Requests](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/pulls)

---

**Note**: Version 0.9.8 is a release candidate. Please test and report issues before final 1.0.0 release.
