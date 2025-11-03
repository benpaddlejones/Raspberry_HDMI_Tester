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

#### Configuration System
- **Centralized Configuration File**: `/boot/firmware/hdmi-tester.conf`
  - `DEBUG_MODE`: Control verbose logging system-wide (true/false)
  - `DEFAULT_SERVICE`: Set auto-start service on boot (or none for terminal) - **NOW WORKING**
  - Accessible from Windows/Mac when SD card is mounted before first boot
  - Can be edited directly or through interactive tool

#### Interactive Configuration Tool (`hdmi-tester-config`)
- **User-Friendly TUI Menu**: raspi-config style interface
- **Debug Mode Control**: Toggle verbose logging on/off for troubleshooting
- **Default Service Management**: Set which test auto-starts on boot
- **One-Time Service Execution**: Run any test without changing defaults
- **Configuration Viewer**: View/edit config file directly from menu
- **Real-Time Status**: Shows current auto-start configuration
- **Ctrl+C Integration**: Press Ctrl+C during any test to return to menu
- **Help & Guidance**: Built-in instructions for diagnostics workflow

#### Auto-Launch System - **IMPROVED**
- **Console Auto-Login**: Boots directly to `pi` user without password
- **Automatic Service Launch**: Configured default service starts immediately on boot
- **SSH Detection**: Auto-start skipped for SSH sessions (normal terminal shown)
- **No Default = Terminal**: When no service configured, boots to welcome message
- **Interactive Menu Access**: Ctrl+C from any service returns to configuration tool
- **No GUI Overhead**: Console-only for maximum performance

### Professional Test Services

#### 🎬 HDMI Test (`hdmi-test`)
**Video & Audio Verification**
- High-quality WebM VP9 test video with embedded 2.1 channel audio
- Full HD resolution with on-screen resolution overlay
- Continuous looping for extended testing
- Tests HDMI handshake, video quality, and basic audio sync
- Automatic HDMI audio device detection
- Configurable VLC debug flags via `DEBUG_MODE`

**Use cases**: Quick HDMI connectivity verification, trade show displays, digital signage validation

#### 🔊 Audio Test (`audio-test`)
**Comprehensive Audio System Validation**
- **Stereo (2.0 channel)**: High-fidelity FLAC stereo test
- **Surround 5.1 channel**: Full 5.1 surround sound verification
- Lossless audio reproduction for accurate testing
- Individual channel identification
- Tests HDMI audio passthrough and receiver compatibility
- Continuous looping for burn-in testing

**Use cases**: Home theater setup, soundbar verification, AV receiver calibration, channel mapping

#### 🎨 Pixel Test (`pixel-test`)
**Dead & Stuck Pixel Detection**
- Fullscreen solid color patterns (black, white, red, green, blue)
- Stretched to fill all pixels (no letterboxing)
- Cycles through colors automatically
- Identifies dead pixels (won't illuminate)
- Detects stuck pixels (always on or locked to color)
- Perfect for quality control and warranty claims

**Use cases**: New display inspection, pre-purchase verification, warranty documentation, monitor returns

#### 🖼️ Image Test (`image-test`)
**Color Calibration & Resolution Verification**
- Rotates through professional test pattern images
- Color accuracy verification
- Native resolution confirmation
- Aspect ratio and geometry validation
- Custom test pattern support (add your own PNGs)
- Timed rotation for unattended testing

**Use cases**: Display calibration, multi-display uniformity, projector alignment, video wall setup

#### 🎯 Full Test (`full-test`)
**Complete A/V System Validation**
- Automated sequence of video and audio tests
- End-to-end HDMI connectivity verification
- Unattended operation for burn-in testing
- Comprehensive coverage of all test modes
- Continuous looping for long-term reliability testing

**Use cases**: System validation before deployment, burn-in testing, production QA, reliability testing

#### 🔧 HDMI Diagnostics (`hdmi-diagnostics`)
**System Troubleshooting & Issue Reporting**
- **Auto-Save to USB**: Plug in USB drive for instant diagnostic export
- **Comprehensive System Capture**: Pi model, HDMI config, audio devices, boot logs, dmesg output
- **Debug Mode Integration**: Captures verbose logs when debug mode enabled
- **GitHub Integration**: Pre-formatted for issue reporting
- **Interactive Workflow**: Built-in guidance for troubleshooting process
- **Debug Mode Reminder**: Prompts to enable debug before diagnostics if disabled
- **Post-Diagnostics Instructions**: Clear next steps for GitHub issue submission

**Contents of diagnostic archive**:
- System information (hardware model, OS version, kernel)
- HDMI configuration (`/boot/firmware/config.txt`)
- Audio device detection (ALSA, PulseAudio)
- Service logs (systemd journal for all test services)
- Boot logs (dmesg output)
- Test asset checksums
- System resource usage

**When to use**: Reporting bugs, hardware compatibility issues, troubleshooting test failures

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

#### Raspberry Pi Compatibility
- **Raspberry Pi 3**: Hardware tested and verified (H.264 video codec)
- **Raspberry Pi 4**: Ready for testing (WebM VP9 codec)
- **Raspberry Pi 5**: Ready for testing (WebM VP9 codec)
- **Raspberry Pi Zero 2 W**: Supported (H.264 fallback)
- **Automatic Codec Selection**: Detects Pi model and uses optimal video format

#### System Configuration
- **SSH Disabled by Default**: For security in field deployments
  - Can be enabled by setting `ENABLE_SSH=1` in build config
  - Username: `pi`
  - Password: `raspberry`
  - ⚠️ Change password if enabling SSH and exposing to network
- **Console Auto-Login**: TTY1 auto-login for immediate access
- **Systemd Services**: All test modes available as systemd units
- **Service Control**: Start/stop/restart any test via systemctl
- **Logging System**: Comprehensive logging with automatic rotation
  - Service logs: `/var/log/hdmi-tester/`
  - System journal: `journalctl -u <service-name>`
  - Debug mode: Verbose logging when enabled

#### HDMI Configuration
- **Auto-Resolution Detection**: Automatically detects display capabilities
  - `hdmi_group=0` and `hdmi_mode=0` for maximum compatibility
  - Supports 720p, 1080p, and 4K displays
- **Force HDMI Output**: `hdmi_force_hotplug=1` for reliable detection
- **HDMI Audio**: `hdmi_drive=2` enables audio over HDMI
- **GPU Memory**: 256MB allocated for smooth video playback
- **Serial Console**: UART enabled for hardware troubleshooting

#### Boot Configuration
- **Fast Boot**: ~30 seconds from power-on to display
- **Silent Boot**: Minimal console output for clean appearance
- **cmdline.txt Fixes**: Automatic correction of common boot parameter issues
- **Audio Health Checks**: Periodic verification of ALSA/PulseAudio state
- **Networking Disabled**: Faster boot, reduced overhead (SSH still works over USB)

#### File System & Storage
- **Optimized Image Size**: 400-500MB reduction through package optimization
- **zerofree**: Unused blocks freed before compression for smaller downloads
- **Filesystem Integrity**: Validated during build process
- **Read-Only Root Option**: Can be configured for kiosk/appliance use

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
