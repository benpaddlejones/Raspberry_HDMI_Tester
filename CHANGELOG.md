# Changelog

All notable changes to the Raspberry Pi HDMI Tester project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.9.3] - 2025-11-03 (Release Candidate)

### Status
**Ready for testing on Raspberry Pi 4 & 5**

### Fixed in This Version
- **Auto-Start Configuration**: Fixed critical bug where default service set in `hdmi-tester-config` was not auto-starting on boot
  - Enhanced bash profile to check for and execute `DEFAULT_SERVICE` configuration
  - Added proper integration between config system and startup process
  - Auto-start now works as expected when default service is configured
- **Default Debug Mode**: Changed from `DEBUG_MODE=true` to `DEBUG_MODE=false` for optimized performance by default

### Core Features
- **Configuration System**: Centralized configuration file (`/boot/firmware/hdmi-tester.conf`)
  - `DEBUG_MODE`: Control verbose logging system-wide (true/false)
  - `DEFAULT_SERVICE`: Set auto-start service on boot (or none for terminal) - **NOW WORKING**
  - Accessible from Windows/Mac when SD card is mounted

- **Interactive Configuration Tool**: `hdmi-tester-config`
  - User-friendly TUI menu (raspi-config style)
  - Toggle debug mode on/off
  - Set default service to auto-start on boot
  - Run any service one-time without changing defaults
  - View/edit configuration file
  - Enhanced feedback showing auto-start status

- **Auto-Launch System** - **IMPROVED**
  - Boots to console with auto-login (user: pi)
  - **NEW**: Automatically launches configured default service on boot
  - **NEW**: Skips auto-start for SSH connections (shows normal terminal)
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
- **NEW**: Added configuration troubleshooting section for auto-start issues
- GitHub issue integration in diagnostics tool

### System Features
- SSH enabled by default (username: pi, password: raspberry)
- Compatible with Pi 3, 4, 5, Zero 2 W
- Console auto-login on TTY1
- Systemd services for all test modes
- Comprehensive logging with rotation

### Default Configuration
- `DEBUG_MODE=false` - Verbose logging disabled by default (optimized performance)
- `DEFAULT_SERVICE=` - No auto-start service (boots to terminal)
- User can configure via `hdmi-tester-config` tool or edit `/boot/firmware/hdmi-tester.conf`

### Testing Status
- ✅ **Build**: Successfully builds in GitHub Codespaces
- ✅ **QEMU**: Passes automated boot testing
- ✅ **Raspberry Pi 3**: Hardware tested and working
- ⏳ **Raspberry Pi 4**: Ready for testing
- ⏳ **Raspberry Pi 5**: Ready for testing
- ⏳ **Configuration System**: Needs testing on hardware

### Known Issues
- None currently identified for Pi 4/5 testing

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

**Note**: Version 0.9.9.3 is ready for testing on Raspberry Pi 4 & 5. The auto-start configuration bug has been fixed and core functionality is stable.
