# Raspberry Pi HDMI Tester

> **A plug-and-play SD card image for instantly testing HDMI displays and audio.**
> Perfect for end-users who need a quick, reliable HDMI testing tool.

A ready-to-use Raspberry Pi image that automatically displays a test pattern and plays audio through HDMI. Perfect for quickly testing displays, troubleshooting HDMI connections, and verifying A/V equipment.

## What Is This?

This is a ready-to-use Raspberry Pi image that:
- ✅ **Boots automatically** - No keyboard, mouse, or interaction needed
- ✅ **Displays a test pattern** - Full HD 1920x1080 test image
- ✅ **Plays continuous audio** - Audio loops infinitely through HDMI
- ✅ **Boots in ~30 seconds** - Fast startup for quick testing
- ✅ **Works on any Pi** - Compatible with Pi 3, 4, 5, Zero 2 W

Simply flash it to an SD card, insert it into a Raspberry Pi, connect HDMI, and power on!

## Use Cases

- 🖥️ **Testing HDMI displays and monitors**
- 🔊 **Verifying HDMI audio output**
- 🔌 **Quick connectivity checks for A/V equipment**
- 🏢 **Trade show booth display testing**
- 📺 **Digital signage troubleshooting**
- 🛠️ **Field service HDMI diagnostics**

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
2. Download `RaspberryPi_HDMI_Tester.img.zip`
3. Extract the `.img` file from the ZIP

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
- ✅ Green LED blinks on the Pi
- ✅ Test pattern appears on screen (1920x1080)
- ✅ Audio plays continuously through HDMI

**That's it!** Your HDMI tester is working.

## What You'll See

### Test Pattern
The default test pattern displays:
- Full HD resolution (1920x1080)
- Color information
- Resolution details
- Visual reference for display testing

### Audio Output
- Continuous audio playback through HDMI
- Loops infinitely (no user interaction needed)
- Tests both HDMI video and audio simultaneously

## Customization

Want to use your own test pattern or audio? See the [Customization Guide](docs/CUSTOMIZATION.md) for:
- Replacing the test pattern image
- Using custom audio files
- Changing HDMI resolution settings
- Modifying boot behavior

## Troubleshooting

### No Display?

**Check these first**:
- ✅ HDMI cable is firmly connected
- ✅ Display is powered on and set to correct input
- ✅ Display supports 1920x1080 resolution
- ✅ Try a different HDMI cable

### No Audio?

**Common fixes**:
- ✅ Enable HDMI audio in your TV/monitor settings
- ✅ Increase volume on the display
- ✅ Some displays default to internal speakers - switch to HDMI audio
- ✅ Try a different HDMI port

### Pi Won't Boot?

**Symptoms**: Only red LED, no green activity

**Try these solutions**:
1. **Re-flash the SD card** - Image may be corrupted
2. **Try a different SD card** - Some cards are incompatible
3. **Use a quality SD card** (SanDisk, Samsung, Kingston)
4. **Verify your power supply** - Insufficient power can cause issues

### Other Issues?

See the complete [Troubleshooting Guide](docs/TROUBLESHOOTING.md) for:
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
- **Resolution**: 1920x1080 @ 60Hz (configurable)
- **Audio**: Continuous playback via mpv with infinite loop
- **Boot Time**: ~20-30 seconds
- **Image Size**: ~1.5-2GB (compressed)
- **SSH**: Enabled by default for troubleshooting (default password: `raspberry`)
  - ⚠️ **Change password if exposing to network!**
- **Network**: WiFi not configured by default (optional)

For complete technical architecture, see [Development Guide](docs/DEVELOPMENT.md).

## Development Status

**Current Version**: v1.0.0 (Released October 2025)

### ✅ Completed
- Project setup and documentation
- GitHub Codespaces development environment
- Test pattern assets (1920x1080 PNG)
- Test audio asset (MP3, infinite loop)
- pi-gen build system (5 custom stages)
- Auto-start services (systemd)
- Audio playback integration (mpv with --loop=inf)
- HDMI configuration (1920x1080@60Hz forced)
- Build and testing scripts
- QEMU testing validation
- Comprehensive logging system
- User documentation (end-user focused)

### 🚧 Future Enhancements
- Boot optimization (reduce to <20 seconds)
- Hardware testing on additional Raspberry Pi models
- CI/CD pipeline for automated builds
- Multi-resolution support (720p, 4K options)
- Web interface for configuration (optional)

## Documentation Guide

### 📚 New Users (Using the Image)
Follow this order for the best experience:

1. **Start Here**: [README.md](README.md) *(you are here)* - Overview and quick start
2. **Flash the Image**: [FLASHING.md](docs/FLASHING.md) - Choose your operating system
3. **Having Issues?** [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Fix common problems
4. **Want to Customize?** [CUSTOMIZATION.md](docs/CUSTOMIZATION.md) - Change test pattern or audio

### 🔧 Developers (Building from Source)
Follow this order to build and contribute:

1. **Start Here**: [DEVELOPMENT.md](docs/DEVELOPMENT.md) - Development environment setup
2. **Build Process**: [BUILDING.md](docs/BUILDING.md) - Step-by-step build instructions
3. **Customize**: [CUSTOMIZATION.md](docs/CUSTOMIZATION.md) - Modify the build
4. **Debug**: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Fix build issues

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
- **System Packages**: Various open-source licenses (X11, mpv, feh, etc.)

See the [LICENSE](LICENSE) file for full details.

### MIT License Summary
```
Copyright (c) 2025 Ben Paddle Jones

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies, subject to the conditions in the LICENSE file.
```

## Acknowledgments

- Built with [pi-gen](https://github.com/RPi-Distro/pi-gen) - Official Raspberry Pi OS image builder
- Powered by [Raspberry Pi OS](https://www.raspberrypi.com/software/)
- Uses [feh](https://feh.finalrewind.org/) for image display
- Uses [mpv](https://mpv.io/) for audio playback

## Resources

- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [Raspberry Pi Forums](https://forums.raspberrypi.com/)
- [HDMI Troubleshooting](https://www.raspberrypi.com/documentation/computers/configuration.html#hdmi-configuration)

---

**Note**: This project is designed for testing purposes. For production digital signage or commercial applications, consider more robust solutions with remote management capabilities.

**Made with ❤️ for the Raspberry Pi community**
