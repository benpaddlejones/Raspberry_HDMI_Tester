# Raspberry Pi HDMI Tester

> **The ultimate plug-and-play HDMI testing solution for displays, audio systems, and A/V equipment.**
>
> Professional-grade testing tools on a simple SD card - no configuration needed.

A complete HDMI testing suite that runs on Raspberry Pi. Flash it to an SD card, boot up, and instantly access professional test patterns, audio verification, and diagnostic tools. Perfect for technicians, installers, trade shows, and anyone who needs reliable HDMI testing.

## What Is This?

The Raspberry Pi HDMI Tester is a **ready-to-use testing toolkit** that:

- 🎯 **Boots in seconds** - No keyboard, mouse, or setup required
- 🖥️ **Tests video quality** - Professional test patterns for display validation
- 🔊 **Verifies audio systems** - High-quality FLAC files test stereo and surround sound
- 🔍 **Detects pixel issues** - Identify dead, stuck, or color-locked pixels
- ⚙️ **Fully configurable** - Interactive menu system for all settings
- 🚀 **Works on any Pi** - Compatible with Pi 3, 4, 5, Zero 2 W

Simply flash to an SD card, insert into a Raspberry Pi, connect HDMI, and start testing!

## Professional Testing Suite

### 🎬 HDMI Test - Video & Audio Verification
**What it does**: Loops a high-quality test video with embedded 2.1 channel audio
- ✅ **Video Quality**: Full HD test pattern with resolution overlay
- ✅ **Audio Testing**: 2.1 channel audio (stereo + subwoofer/LFE)
- ✅ **Continuous Loop**: Runs indefinitely for long-term testing
- ✅ **Perfect for**: Display connectivity, HDMI handshake verification, basic A/V sync

**Use cases**:
- Quick HDMI connection verification
- Trade show booth display testing
- Digital signage deployment validation
- A/V receiver compatibility testing

### 🔊 Audio Test - Comprehensive Audio Validation
**What it does**: Tests your audio system with high-fidelity FLAC files
- ✅ **Stereo (2.0)**: Crystal-clear stereo audio test
- ✅ **Surround 5.1**: Full 5.1 channel surround sound verification
- ✅ **Lossless Quality**: FLAC format ensures perfect audio reproduction
- ✅ **Channel Verification**: Identify individual speaker channels

**Use cases**:
- Home theater system setup and calibration
- Soundbar/speaker system verification
- HDMI audio passthrough testing
- AV receiver channel mapping validation

### 🎨 Pixel Test - Dead Pixel Detection
**What it does**: Cycles through solid colors to reveal display defects
- ✅ **Dead Pixels**: Identifies pixels that won't illuminate
- ✅ **Stuck Pixels**: Finds pixels locked in the "on" position
- ✅ **Color Issues**: Detects pixels locked to a specific color
- ✅ **Full Coverage**: Solid black, white, red, green, blue patterns

**Use cases**:
- New display quality control
- Pre-purchase display inspection
- Warranty claim documentation
- Monitor/TV return verification

### 🖼️ Image Test - Color Calibration & Resolution
**What it does**: Rotates through professional test patterns
- ✅ **Color Accuracy**: Verify true color reproduction
- ✅ **Resolution Check**: Confirm native resolution support
- ✅ **Aspect Ratio**: Validate proper scaling and geometry
- ✅ **Custom Patterns**: Easy to add your own test images

**Use cases**:
- Display calibration reference
- Multi-display uniformity testing
- Projector alignment and focus
- Video wall configuration

### 🎯 Full Test - Complete A/V System Validation
**What it does**: Runs comprehensive video and audio tests in sequence
- ✅ **End-to-End Testing**: Video quality + audio verification
- ✅ **Automated Sequence**: Runs multiple tests continuously
- ✅ **Unattended Operation**: Perfect for burn-in testing
- ✅ **Complete Coverage**: Tests all aspects of HDMI connectivity

**Use cases**:
- Complete system validation before deployment
- Burn-in testing for new equipment
- Long-term reliability testing
- Production line quality assurance

### 🔧 Diagnostics - Troubleshooting & Support
**What it does**: Captures complete system state for issue resolution
- ✅ **Auto-saves to USB**: Plug in a USB drive for instant log export
- ✅ **Comprehensive Logs**: System info, HDMI config, audio devices, boot logs
- ✅ **GitHub Integration**: Easy issue reporting with diagnostic bundle
- ✅ **Debug Mode**: Enable verbose logging for detailed troubleshooting

**Use cases**:
- Troubleshooting HDMI issues
- Technical support documentation
- Issue reporting to manufacturers
- Field service diagnostics

## Use Cases

### For Technicians & Installers
- 🏢 **Commercial Installations**: Validate displays before client sign-off
- 📺 **Home Theater Setup**: Verify audio channels and video quality
- 🎪 **Event Production**: Quick HDMI troubleshooting on-site
- 🏭 **Manufacturing QA**: Production line display testing

### For IT & Support Teams
- 💼 **Conference Room Setup**: Test presentation systems
- 🖥️ **Workstation Deployment**: Verify monitor quality
- 🎯 **Help Desk**: Quick display/audio diagnostics
- 📊 **Inventory Testing**: Check used/refurbished equipment

### For Enthusiasts & Consumers
- 🛒 **Pre-Purchase Testing**: Verify display quality before buying
- 🎮 **Gaming Setup**: Test monitor pixel response and audio
- 🎬 **Home Cinema**: Calibrate projectors and audio systems
- 📦 **Return/Warranty**: Document defects for claims

## Quick Start

### What You Need

**Hardware**:
- Raspberry Pi (any model with HDMI output)
- MicroSD card (4GB minimum, 8GB recommended)
- Power supply for your Pi
- HDMI cable
- Display with HDMI input

**Software**:
- The HDMI Tester image (download from [Releases](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/releases))
- Flashing tool (Raspberry Pi Imager recommended)

### Step 1: Download the Image

1. Go to [Releases](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/releases)
2. Download `RaspberryPi_HDMI_Tester-v0.9.8-RC.img.gz`
3. Extract if needed (some tools extract automatically)

### Step 2: Flash to SD Card

Choose your operating system for detailed instructions:

- **[Windows 10/11](docs/FLASHING-Windows.md)** - Detailed guide for Windows users
- **[macOS](docs/FLASHING-macOS.md)** - Complete macOS instructions
- **[Linux](docs/FLASHING-Linux.md)** - Linux flashing guide

**Quick method** (all platforms):
1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Click "Choose OS" → "Use custom" → Select the `.img` file
3. Click "Choose Storage" → Select your SD card
4. Click "Write"

### Step 3: Boot and Test

1. **Insert SD card** into Raspberry Pi
2. **Connect HDMI cable** to your display
3. **Connect power supply**
4. **Wait ~30 seconds** for boot

**You should see**:
- ✅ Green LED blinks on the Pi (boot activity)
- ✅ Welcome message on screen
- ✅ Configuration menu with test options

**First Time Setup**:
1. The system boots to a terminal with a welcome message
2. Run `hdmi-tester-config` to access the interactive menu
3. Choose a test mode to run, or set a default to auto-start on boot

**That's it!** You're ready to start testing.

## How to Use

### Interactive Configuration Menu

After boot, run `hdmi-tester-config` to access the easy-to-use menu:

```
╔════════════════════════════════════════════════════════════╗
║         HDMI Tester Configuration Manager                 ║
╚════════════════════════════════════════════════════════════╝

Current Configuration:
  Debug Mode:      true
  Default Service: (none - boot to terminal)

Options:
  1) Toggle Debug Mode
  2) Set Default Service (auto-start on boot)
  3) Run a Service Now (one-time)
  4) View/Edit Config File
  5) Exit to Terminal
```

### Running Tests

**Option 1: Run Once (No Auto-Start)**
1. Boot the Pi
2. At the terminal, run: `hdmi-tester-config`
3. Select option 3: "Run a Service Now"
4. Choose your test (hdmi-test, audio-test, pixel-test, etc.)
5. Press Ctrl+C to return to menu

**Option 2: Set Default Auto-Start**
1. Boot the Pi
2. Run: `hdmi-tester-config`
3. Select option 2: "Set Default Service"
4. Choose which test to run automatically on boot
5. Reboot - your chosen test starts automatically
6. Press Ctrl+C anytime to return to configuration menu

**Option 3: Run Directly from Terminal**
```bash
hdmi-test       # Video + 2.1 audio test
audio-test      # Stereo + 5.1 surround audio
pixel-test      # Solid colors for dead pixel detection
image-test      # Rotate through test patterns
full-test       # Complete A/V test sequence
```

### Debug Mode

Enable debug mode for troubleshooting:
- **ON**: Verbose VLC logging (see detailed codec info, buffering, errors)
- **OFF**: Clean minimal output

Toggle via configuration menu or edit `/boot/firmware/hdmi-tester.conf`

### Configuration File

The configuration is stored in `/boot/firmware/hdmi-tester.conf` and can be edited from any computer:

```bash
# DEBUG_MODE: Enable verbose debugging output system-wide
DEBUG_MODE=true

# DEFAULT_SERVICE: Service to auto-launch on boot
# Options: hdmi-test, audio-test, image-test, pixel-test, full-test
DEFAULT_SERVICE=
```

Windows/Mac users can edit this file directly when the SD card is mounted!

## What You'll See

## What You'll See

### HDMI Test (Video + Audio)
- **Video**: Full HD test pattern with resolution overlay in top-right corner
- **Audio**: 2.1 channel audio (stereo + LFE/subwoofer channel)
- **Duration**: Loops infinitely
- **Resolution Detection**: Automatically detects and displays your screen resolution

### Audio Test
- **Track 1**: High-quality stereo (2.0) FLAC audio
- **Track 2**: 5.1 surround sound FLAC audio
- **Format**: Lossless FLAC for perfect reproduction
- **Playback**: Continuous loop through both tracks

### Pixel Test
Cycles through solid colors in fullscreen:
- **Black Screen**: Detect bright pixels, stuck-on pixels
- **White Screen**: Detect dead pixels, dark spots
- **Red Screen**: Identify red channel issues
- **Green Screen**: Identify green channel issues
- **Blue Screen**: Identify blue channel issues
- **Custom Images**: Test pattern with color bars and gradients

Each color displays for 10 seconds before automatically transitioning.

### Image Test
Rotates through professional test patterns:
- Color calibration charts
- Resolution and sharpness patterns
- Aspect ratio verification
- Custom test images

### Full Test
Runs the complete test sequence:
1. HDMI video test with 2.1 audio
2. Pixel test (fullscreen colors)
3. Loops continuously for extended testing

## Key Features

### Professional Grade Testing
- **High Quality Media**: WebM VP9 video (Pi 4+) or H.264 (Pi 3), lossless FLAC audio
- **Auto-Detection**: Automatically selects optimal codec based on Pi model
- **Resolution Support**: Auto-detects display capabilities (720p/1080p/4K)
- **Configurable**: Easy-to-use menu system for all settings

### Zero Configuration Required
- **No Setup**: Works out of the box - just flash and boot
- **Auto-Login**: Boots directly to terminal (user: pi)
- **Instant Access**: All tests available immediately
- **No Network Needed**: Completely offline operation

### Advanced Features
- **Debug Mode**: Toggle verbose logging for troubleshooting
- **USB Diagnostics**: Auto-save system diagnostics to USB drive
- **GitHub Integration**: Built-in guidance for issue reporting
- **SSH Access**: Remote access for advanced configuration (default password: `raspberry`)
  - ⚠️ **Change password if exposing to network!**

## Customization

Want to customize the tests? See the [Customization Guide](docs/CUSTOMIZATION.md) for:
- Adding your own test patterns
- Using custom audio files
- Changing HDMI resolution settings
- Modifying test sequences
- Creating custom test modes

**Quick customization**: Edit files in `/opt/hdmi-tester/` on the SD card or via SSH.

## Troubleshooting

### No Display?

**Check these first**:
- ✅ HDMI cable is firmly connected
- ✅ Display is powered on and set to correct HDMI input
- ✅ Try a different HDMI cable or port
- ✅ Wait full 30 seconds for boot to complete
- ✅ Check if green LED is blinking (indicates boot activity)

**Advanced troubleshooting**:
- Some displays need time to detect signal - wait up to 60 seconds
- Try forcing a specific resolution in `/boot/firmware/config.txt`
- Enable debug mode to see detailed boot logs

### No Audio?

**Common fixes**:
- ✅ Enable HDMI audio in your TV/monitor/receiver settings
- ✅ Increase volume on the display/receiver
- ✅ Some displays default to internal speakers - switch to HDMI audio input
- ✅ Try a different HDMI port (some ports are video-only)
- ✅ Verify your display supports audio over HDMI

**For audio-test specifically**:
- Stereo (2.0) should work on all HDMI devices
- Surround 5.1 requires an AV receiver or soundbar with HDMI input
- Check receiver is set to correct HDMI input channel

### Pixel Test Shows No Issues But I See Dead Pixels?

**Try this**:
- ✅ Let each color display for the full 10 seconds
- ✅ View the screen from directly in front (not at an angle)
- ✅ Ensure room is dark or reduce ambient light
- ✅ Dead pixels may only be visible on certain colors
- ✅ Run pixel-test multiple times

### Tests Run But Performance Issues?

**Check debug mode**:
- Debug mode (verbose logging) can impact performance slightly
- Disable debug mode via `hdmi-tester-config` for best performance
- Debug mode should only be enabled for troubleshooting

### Pi Won't Boot?

**Symptoms**: Only red LED, no green activity

**Try these solutions**:
1. **Re-flash the SD card** - Image may be corrupted
2. **Try a different SD card** - Some cards are incompatible
3. **Use a quality SD card** (SanDisk, Samsung, Kingston)
4. **Verify your power supply** - Insufficient power can cause issues

### Other Issues?

See the [User Troubleshooting Guide](docs/TROUBLESHOOTING-USER.md) for:
- Platform-specific flashing issues
- Boot problems
- Display configuration
- Audio troubleshooting
- SD card recommendations

## Supported Hardware

### Raspberry Pi Models
- ✅ Raspberry Pi 5
- ✅ Raspberry Pi 4 (all variants)
- ✅ Raspberry Pi 3 B+
- ✅ Raspberry Pi 3 B
- ✅ Raspberry Pi Zero 2 W
- ⚠️ Pi Zero W (limited support, no HDMI connector)

### SD Card Requirements
- **Minimum**: 4GB (tight fit)
- **Recommended**: 8GB or larger
- **Speed**: Class 10 or higher (U1, U3, or A1 recommended)
- **Brands**: SanDisk, Samsung, Kingston recommended

## Technical Details

- **Base OS**: Raspberry Pi OS Lite (Debian 12 Bookworm)
- **Display**: VLC media player (fullscreen, no desktop environment)
- **Resolution**: Auto-detect (720p/1080p/4K), default 1920x1080 @ 60Hz
- **Audio**: ALSA direct output via VLC with infinite loop
- **Boot Time**: ~20-30 seconds to test display
- **Image Size**: ~1.5-2GB (compressed)
- **GPU Memory**: 64MB (minimal allocation for console mode)
- **Configuration**: `/boot/firmware/hdmi-tester.conf` (accessible from Windows/Mac)
- **SSH**: Enabled by default for remote configuration (username: `pi`, password: `raspberry`)
  - ⚠️ **Change password if exposing to network!**
- **Network**: WiFi not configured by default (offline operation)
- **Debug Mode**: Toggle verbose logging via configuration menu
- **Auto-Start**: Optional auto-boot to any test mode

### Video & Audio Codecs

**Dual-Format System** - Auto-selects based on Pi model for hardware optimization:

**Raspberry Pi 3B and below** uses **MP4** files:
- **Video Codec**: H.264 (hardware accelerated decoder)
- **Audio Codec**: AAC
- **Container**: MP4
- **Files**: `image-test.mp4`, `color-test.mp4`

**Raspberry Pi 4 and above** uses **WebM** files:
- **Video Codec**: VP9 (hardware accelerated decoder)
- **Audio Codec**: Opus
- **Container**: WebM (Matroska-based)
- **Files**: `image-test.webm`, `color-test.webm`

The system **automatically detects** the Pi model at runtime and selects the optimal format for best performance. Both formats are included in the image.

**Supported Formats** (additional codecs available):
- ✅ WebM (VP8/VP9 video, Vorbis/Opus audio)
- ✅ MP4 (H.264/H.265 video, AAC audio)
- ✅ FLV (Flash Video)
- ✅ Theora video
- ✅ AV1 video (via libaom3)

**Installed Codec Libraries**:
- `libvpx9` - VP8/VP9 video codec (WebM - Pi 4+)
- `libx264-164` - H.264 video codec (MP4 - all Pi models)
- `libopus0` - Opus audio codec (WebM)
- `libvorbis0a` - Vorbis audio codec (WebM)
- `libx265-199` - H.265/HEVC video codec
- `libtheora0` - Theora video codec
- `libaom3` - AV1 video codec
- `ffmpeg` + `libavcodec-extra` - Comprehensive codec support

For complete technical architecture, see [Development Guide](docs/DEVELOPMENT.md).

## Development Status

**Current Version**: v0.9.8 Release Candidate (RC)

### What's New in v0.9.8
- ✅ **Interactive Configuration System**: Easy-to-use menu (`hdmi-tester-config`)
- ✅ **Debug Mode Toggle**: Enable/disable verbose logging without editing files
- ✅ **Auto-Start Support**: Set any test to launch automatically on boot
- ✅ **Enhanced Diagnostics**: Auto-save system logs to USB with GitHub issue guidance
- ✅ **Improved User Experience**: Ctrl+C returns to menu, streamlined workflows
- ✅ **Multi-Channel Audio**: 2.1 audio (HDMI test) + stereo/5.1 FLAC (audio test)
- ✅ **Pixel Detection**: Dead, stuck, and color-locked pixel identification
- ✅ **Configuration File**: `/boot/firmware/hdmi-tester.conf` accessible from any OS

### Roadmap
- ⏳ Hardware testing on additional Pi models (ongoing)
- ⏳ Boot time optimization (target: <20 seconds)
- ⏳ Multi-resolution support refinement
- 📋 CI/CD pipeline for automated builds
- 📋 Community-submitted test patterns

See [CHANGELOG.md](CHANGELOG.md) for complete version history.

## Documentation Guide

### 📚 New Users (Using the Image)
Follow this order for the best experience:

1. **Start Here**: [README.md](README.md) *(you are here)* - Overview and quick start
2. **Flash the Image**: [FLASHING.md](docs/FLASHING.md) - Choose your operating system
3. **Having Issues?** [TROUBLESHOOTING-USER.md](docs/TROUBLESHOOTING-USER.md) - Fix common problems
4. **Want to Customize?** [CUSTOMIZATION.md](docs/CUSTOMIZATION.md) - Change test pattern or audio

### 🔧 Developers (Building from Source)
Follow this order to build and contribute:

1. **Start Here**: [DEVELOPMENT.md](docs/DEVELOPMENT.md) - Development environment setup
2. **Build Process**: [BUILDING.md](docs/BUILDING.md) - Step-by-step build instructions
3. **Customize**: [CUSTOMIZATION.md](docs/CUSTOMIZATION.md) - Modify the build
4. **Debug**: [TROUBLESHOOTING-BUILD.md](docs/TROUBLESHOOTING-BUILD.md) - Fix build issues

### 📄 Complete Documentation List

**For End Users**:
- [Flashing Guide - Windows](docs/FLASHING-Windows.md) - Flash SD card on Windows 10/11
- [Flashing Guide - macOS](docs/FLASHING-macOS.md) - Flash SD card on macOS
- [Flashing Guide - Linux](docs/FLASHING-Linux.md) - Flash SD card on Linux
- [Customization Guide](docs/CUSTOMIZATION.md) - Customize test pattern and audio
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Fix common issues

**For Developers**:
- [Development Guide](docs/DEVELOPMENT.md) - Build from source, contribute
- [Building Guide](docs/BUILDING.md) - Detailed build instructions

## Contributing

We welcome contributions! You can help by:

### Reporting Issues

Found a bug or have a feature request?

1. **Check existing issues** first: [GitHub Issues](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues)
2. **Create a new issue** if it doesn't exist:
   - Use a clear, descriptive title
   - Describe the problem or feature request in detail
   - Include your Raspberry Pi model and OS version
   - Attach relevant logs or screenshots
   - Mention steps to reproduce (if reporting a bug)

### Contributing Code

Want to add features or fix bugs?

1. **Fork this repository** on GitHub
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes** and test thoroughly
4. **Commit with clear messages**: `git commit -m "feat: add 4K resolution support"`
5. **Push to your fork**: `git push origin feature/your-feature-name`
6. **Open a Pull Request** with a detailed description

See the [Development Guide](docs/DEVELOPMENT.md) for:
- Setting up your development environment
- Understanding the project structure
- Build system details
- Testing procedures
- Code contribution guidelines

## Support

- **Questions?** Open a [Discussion](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/discussions)
- **Bug reports?** Create an [Issue](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues)
- **Documentation**: See the `docs/` directory

## License

This project is licensed under the MIT License with additional GPL components:

- **Project Code**: MIT License - Free to use, modify, and distribute
- **Pi-gen Components**: GPL (from Raspberry Pi Foundation)
- **System Packages**: Various open-source licenses (VLC, ALSA, etc.)

See the [LICENSE](LICENSE) file for full details.

### MIT License Summary
```
Copyright (c) 2025 Ben Jones

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies, subject to the conditions in the LICENSE file.
```

## Acknowledgments

- Built with [pi-gen](https://github.com/RPi-Distro/pi-gen) - Official Raspberry Pi OS image builder
- Powered by [Raspberry Pi OS](https://www.raspberrypi.com/software/)
- Uses [VLC](https://www.videolan.org/vlc/) for video and audio playback
- Uses [ALSA](https://www.alsa-project.org/) for audio output

## Resources

- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [Raspberry Pi Forums](https://forums.raspberrypi.com/)
- [HDMI Troubleshooting](https://www.raspberrypi.com/documentation/computers/configuration.html#hdmi-configuration)

---

**Note**: This project is designed for testing purposes. For production digital signage or commercial applications, consider more robust solutions with remote management capabilities.

**Made with ❤️ for the Raspberry Pi community**
