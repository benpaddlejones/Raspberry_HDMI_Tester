# Changelog

All notable changes to the Raspberry Pi HDMI Tester project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Build time reduced from 61 minutes to 39-41 minutes (33% improvement)
- Image size reduced by 400-500MB through package optimization
- Compression format changed from .img.zip to .img.gz for better compatibility

### Added
- QEMU kernel fix - enables automated boot testing
- Stage2 package exclusions - removes 44 unnecessary packages (bluez, avahi-daemon, rpi-connect-lite, build tools)
- APT update caching - prevents redundant package list updates
- Parallel gzip compression (pigz) - 80% faster compression (10 min → 2 min)
- Early image deduplication (zerofree) - optimizes filesystem before compression
- BUILD_OPTIMIZATION_NEXT_STEPS.md - roadmap for future performance improvements

### Performance
- Total build time savings: ~22 minutes (33% improvement)
- Compression time: 8-10 minutes faster
- Image size: 400-500MB smaller
- Remaining optimization target: 36-38 minutes (40% total improvement)

## [1.0.0] - 2025-10-19

### Added
- Initial release of Raspberry Pi HDMI Tester
- Auto-boot functionality with systemd services
- Full HD test pattern display (1920x1080)
- Continuous HDMI audio playback
- Custom pi-gen build stages (stage0-stage3)
- Comprehensive user documentation
- QEMU testing framework
- Build automation scripts with logging
- SSH access for troubleshooting (username: pi, password: raspberry)

### Features
- ✅ Boots automatically without user interaction
- ✅ Displays test pattern in ~30 seconds
- ✅ Infinite audio loop through HDMI
- ✅ Compatible with Pi 3, 4, 5, Zero 2 W
- ✅ Auto-detects HDMI resolution (720p, 1080p, 4K)

### Documentation
- README.md - Project overview and quick start
- FLASHING.md - Multi-platform flashing guide
- FLASHING-Windows.md - Windows-specific instructions
- FLASHING-macOS.md - macOS-specific instructions
- FLASHING-Linux.md - Linux-specific instructions
- CUSTOMIZATION.md - How to customize test pattern and audio
- TROUBLESHOOTING-USER.md - End-user troubleshooting guide
- DEVELOPMENT.md - Developer setup and contribution guide
- BUILDING.md - Build instructions from source
- TROUBLESHOOTING-BUILD.md - Build troubleshooting guide
- TESTING_GUIDE.md - Testing procedures

---

## Version Numbering

- **Major version (X.0.0)**: Breaking changes or major feature releases
- **Minor version (1.X.0)**: New features, backward compatible
- **Patch version (1.0.X)**: Bug fixes, optimizations, documentation updates

## Links

- [Latest Release](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/releases/latest)
- [All Releases](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/releases)
- [Issues](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues)
- [Pull Requests](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/pulls)

---

**Note**: Unreleased changes are in development and will be included in the next release (v1.1.0).
