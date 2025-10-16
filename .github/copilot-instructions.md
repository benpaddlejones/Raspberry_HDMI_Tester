---
applyTo: "**"
---

# Raspberry Pi HDMI Tester - Project-Specific Copilot Instructions

## Project Overview

This is a **Raspberry Pi OS image builder project** that creates a lightweight, auto-booting HDMI testing tool. The final product is a custom Raspberry Pi OS image that:

- Automatically displays a test pattern on HDMI output
- Plays continuous audio through HDMI
- Boots without user interaction (no keyboard/mouse needed)
- Can be flashed to an SD card for portable HDMI testing

**Key Use Case:** Quick testing of HDMI displays, audio connectivity, and A/V equipment in field environments, trade shows, or troubleshooting scenarios.

---

## Project Architecture & Technical Stack

### Core Technologies

1. **pi-gen** (Raspberry Pi OS Image Builder)
   - Official tool from Raspberry Pi Foundation
   - Location: `/opt/pi-gen` (pre-installed in dev container)
   - Uses multi-stage build process (stage0 through stage5)
   - Custom stages: `build/stage-custom/`

2. **QEMU** (ARM Emulation)
   - Enables x86 systems to build ARM images
   - Pre-configured with binfmt support
   - Used for testing images before hardware deployment

3. **Debian/Linux System Building**
   - `debootstrap` - Bootstrap minimal Debian systems
   - `kpartx` - Manage partition tables
   - `parted` - Partition manipulation
   - `systemd` - Service management for auto-start

4. **Media Components** (Target Image)
   - **Display**: X11 or Wayland + feh/fbi image viewer
   - **Audio**: omxplayer or mpv for HDMI audio output
   - **Boot**: Plymouth for boot splash (optional)

### Development Environment

- **Platform**: GitHub Codespaces / VS Code Dev Containers
- **Base OS**: Ubuntu 24.04 LTS
- **Container**: Docker with privileged mode (required for loop device mounting)
- **Architecture**: x86_64 host building ARM images

---

## Directory Structure & Conventions

### Key Directories

```
/workspaces/Raspberry_HDMI_Tester/    # Main workspace
├── .devcontainer/                     # Dev container config (DO NOT MODIFY without review)
├── build/                             # Build configuration and custom stages
│   ├── config                         # pi-gen build configuration
│   └── stage-custom/                  # Custom installation stages
│       ├── 00-install-packages/       # System packages
│       ├── 01-test-image/             # Test pattern deployment
│       ├── 02-audio-test/             # Audio file deployment
│       └── 03-autostart/              # systemd services for auto-start
├── assets/                            # Media files for the image
│   ├── test-pattern.png               # HDMI test pattern (1920x1080 or 4K)
│   └── test-audio.wav                 # Audio test file (looping)
├── scripts/                           # Build and deployment scripts
│   ├── build-image.sh                 # Main build orchestrator
│   ├── configure-boot.sh              # Boot configuration (config.txt, cmdline.txt)
│   └── setup-autostart.sh             # systemd service creation
├── docs/                              # Documentation
├── tests/                             # Testing scripts
│   └── qemu-test.sh                   # QEMU emulation testing
└── /opt/pi-gen/                       # Pre-installed pi-gen (READ-ONLY)
```

### File Naming Conventions

- **Shell scripts**: `kebab-case.sh` (e.g., `build-image.sh`)
- **Configuration files**: lowercase, no extension (e.g., `config`)
- **pi-gen stages**: `XX-descriptive-name/` (e.g., `00-install-packages/`)
- **systemd services**: `kebab-case.service` (e.g., `hdmi-tester.service`)

---

## Critical Build System Rules

### pi-gen Stage System

pi-gen uses a **multi-stage build process**. Each stage builds upon the previous:

- **stage0**: Bootstrap minimal Debian
- **stage1**: Add core Raspberry Pi OS components
- **stage2**: Add networking, basic utilities
- **stage3**: Add desktop environment (we skip this)
- **stage4**: Add recommended applications (we skip this)
- **stage5**: Add extras (we skip this)
- **stage-custom**: OUR CUSTOM STAGE

#### Stage Structure Requirements

Each stage directory must follow this pattern:

```
stage-custom/
├── 00-install-packages/
│   ├── 00-packages          # List of apt packages (one per line)
│   └── 00-run.sh            # Installation script (optional)
├── 01-test-image/
│   ├── files/               # Files to copy to image
│   │   └── test-pattern.png
│   └── 00-run.sh            # Script to install files
└── 02-audio-test/
    ├── files/
    │   └── test-audio.wav
    └── 00-run.sh
```

**CRITICAL RULES:**
1. Scripts must be named `XX-run.sh` or `XX-run-chroot.sh`
2. `00-run.sh` runs on the **build host**
3. `00-run-chroot.sh` runs **inside the chroot** (target image)
4. Files in `files/` subdirectory are available during build
5. Use `${ROOTFS_DIR}` variable to reference target filesystem root

### Build Script Guidelines

When creating or modifying build scripts:

1. **Always use `set -e`** - Exit on any error
2. **Check for required tools** before using them
3. **Use absolute paths** when referencing files
4. **Log progress** with clear echo statements
5. **Clean up** temporary files and caches

Example build script template:

```bash
#!/bin/bash
# scripts/example-script.sh

set -e  # Exit on error
set -u  # Exit on undefined variable

echo "🔧 Starting example script..."

# Check for required commands
if ! command -v required-tool &> /dev/null; then
    echo "❌ Error: required-tool not found"
    exit 1
fi

# Main logic here
echo "✅ Example script completed"
```

---

## Raspberry Pi Specific Considerations

### Boot Configuration Files

1. **`/boot/config.txt`** (Raspberry Pi firmware configuration)
   - Controls HDMI output, audio routing, GPU memory
   - Key settings for HDMI tester:
     ```
     hdmi_force_hotplug=1     # Force HDMI even if no display detected
     hdmi_drive=2             # Enable HDMI audio
     hdmi_group=1             # CEA (consumer electronics)
     hdmi_mode=16             # 1920x1080 @ 60Hz
     gpu_mem=128              # GPU memory allocation
     ```

2. **`/boot/cmdline.txt`** (Kernel boot parameters)
   - Single line, space-separated parameters
   - For silent boot: `quiet splash loglevel=0`

3. **systemd Services** (Auto-start mechanism)
   - Create service in `/etc/systemd/system/`
   - Enable with `systemctl enable service-name.service`
   - Must handle restarts and failures gracefully

### Image Size Optimization

Target image size should be:
- **Minimum**: 2GB (for 4GB SD cards)
- **Recommended**: 4GB (for 8GB SD cards)
- **Maximum**: 8GB (for larger cards)

**Optimization strategies:**
1. Use Raspberry Pi OS Lite (no desktop by default)
2. Remove unnecessary packages after installation
3. Clear apt cache: `apt-get clean`
4. Remove documentation: `rm -rf /usr/share/doc/*`
5. Minimize installed locales

---

## Code Quality & Style Guidelines

### Shell Script Standards

- **Shebang**: Always use `#!/bin/bash`
- **Error handling**: Use `set -e` and `set -u`
- **Functions**: Use for repeated logic
- **Variables**: UPPERCASE for environment/constants, lowercase for local
- **Quotes**: Always quote variables: `"${VAR}"` not `$VAR`
- **Comments**: Document why, not what

Example:

```bash
#!/bin/bash
set -e
set -u

# Configuration
readonly IMAGE_SIZE="4G"
readonly OUTPUT_DIR="build/output"

# Function to check prerequisites
check_requirements() {
    local required_tools=("qemu-arm-static" "kpartx" "parted")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "${tool}" &> /dev/null; then
            echo "❌ Error: ${tool} not found"
            return 1
        fi
    done
    
    echo "✅ All requirements met"
}

# Main execution
main() {
    check_requirements
    # Build logic here
}

main "$@"
```

### Configuration File Standards

- **pi-gen config**: Use KEY=VALUE format, no spaces around `=`
- **systemd units**: Follow systemd.unit(5) man page conventions
- **Shell configs**: Use comments liberally

---

## Testing & Validation Requirements

### Pre-Build Validation

Before building an image, verify:

1. **All assets exist**: `test-pattern.png`, `test-audio.wav`
2. **Scripts are executable**: `chmod +x scripts/*.sh`
3. **JSON is valid**: `jq empty .devcontainer/devcontainer.json`
4. **Shell scripts pass shellcheck**: `shellcheck scripts/*.sh`

### QEMU Testing

Before deploying to hardware:

```bash
# Test image in QEMU
./tests/qemu-test.sh build/output/hdmi-tester.img

# Verify:
# - Image boots successfully
# - No kernel panics
# - Services start correctly
```

### Hardware Testing Checklist

When testing on actual Raspberry Pi:

- [ ] Image flashes successfully to SD card
- [ ] Pi boots without errors (check serial console if available)
- [ ] Test pattern appears on HDMI display
- [ ] Audio plays through HDMI
- [ ] Boot time is acceptable (< 30 seconds to display)
- [ ] System is stable (no crashes or reboots)

---

## Security & Safety Considerations

### Privileged Operations

This project requires **privileged Docker mode** for:
- Loop device mounting (`kpartx`)
- Partition creation/modification
- chroot operations

**NEVER**:
- Run untrusted code with these privileges
- Expose privileged containers to network
- Use in production environments

### SD Card Safety

When flashing images:

1. **Always verify device name** before using `dd`
2. **Use `lsblk` to confirm** target device
3. **Unmount target** before flashing
4. **Sync after write**: `sudo sync`

Wrong device can destroy host system data!

```bash
# ❌ DANGEROUS - Wrong device
sudo dd if=image.img of=/dev/sda  # This might be your system disk!

# ✅ SAFE - Verify first
lsblk  # Check device names
sudo dd if=image.img of=/dev/mmcblk0 bs=4M status=progress conv=fsync
sudo sync
```

---

## Common Tasks & Patterns

### Adding a New Package to the Image

1. Edit `build/stage-custom/00-install-packages/00-packages`
2. Add package name on new line
3. Rebuild image

### Adding a New systemd Service

1. Create service file in `build/stage-custom/03-autostart/files/`
2. Create install script in `build/stage-custom/03-autostart/00-run-chroot.sh`
3. Enable service with systemctl

Example service:

```ini
[Unit]
Description=HDMI Test Pattern Display
After=graphical.target
Wants=graphical.target

[Service]
Type=simple
User=pi
ExecStart=/usr/bin/feh --fullscreen --hide-pointer /opt/hdmi-tester/test-pattern.png
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
```

### Modifying Boot Configuration

1. Edit `scripts/configure-boot.sh`
2. Add settings to `/boot/config.txt` or `/boot/cmdline.txt`
3. Rebuild image or modify existing image

### Creating Test Assets

Test pattern requirements:
- **Resolution**: 1920x1080 (minimum), 3840x2160 (recommended)
- **Format**: PNG or JPEG
- **Content**: Color bars, resolution info, text labels
- **Size**: < 5MB

Audio file requirements:
- **Format**: WAV (uncompressed) or MP3
- **Duration**: 5-30 seconds (will loop)
- **Sample**: 1kHz tone or frequency sweep
- **Size**: < 10MB

---

## Troubleshooting Guide

### Build Failures

**Symptom**: pi-gen build fails with "command not found"
**Solution**: Check that required tools are installed in dev container

**Symptom**: "Permission denied" during build
**Solution**: Ensure container runs in privileged mode

**Symptom**: Build takes too long or hangs
**Solution**: Check disk space, increase Docker resources

### Runtime Issues

**Symptom**: No display on HDMI
**Solution**: Check `config.txt` settings, try different HDMI cable/display

**Symptom**: No audio through HDMI
**Solution**: Verify `hdmi_drive=2` in `config.txt`

**Symptom**: Service fails to start
**Solution**: Check systemd logs: `journalctl -u service-name`

### Development Environment Issues

**Symptom**: QEMU not working
**Solution**: 
```bash
# Re-enable binfmt
sudo update-binfmts --enable qemu-arm
```

**Symptom**: Out of disk space
**Solution**:
```bash
# Clean old builds
sudo rm -rf build/work/*
docker system prune -a
```

---

## Working with Copilot on This Project

### What Copilot Should Know

1. **This is an embedded Linux project** - Focus on low-level system configuration
2. **ARM architecture target** - x86 code won't work on Raspberry Pi
3. **Size matters** - Keep image minimal, every package adds bloat
4. **Auto-boot is critical** - Everything must work without user interaction
5. **HDMI/Audio focus** - Primary goal is display and audio testing

### When to Ask for Clarification

- Hardware-specific settings (model differences between Pi 3/4/5)
- Display resolution requirements (1080p vs 4K)
- Audio format preferences (test tone vs music)
- Boot time requirements (fast boot vs full services)

### Preferred Approaches

1. **Incremental changes** - Test each stage modification separately
2. **QEMU first** - Test in emulator before hardware
3. **Minimize dependencies** - Use built-in tools when possible
4. **Document everything** - Shell scripts need clear comments
5. **Follow pi-gen conventions** - Don't fight the build system

---

## Resources & References

### Official Documentation

- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [pi-gen GitHub](https://github.com/RPi-Distro/pi-gen)
- [Raspberry Pi config.txt](https://www.raspberrypi.com/documentation/computers/config_txt.html)
- [systemd Documentation](https://www.freedesktop.org/software/systemd/man/)

### Tools Documentation

- QEMU ARM emulation
- debootstrap usage
- kpartx for partition management
- feh image viewer
- mpv media player

### Community Resources

- Raspberry Pi Forums
- pi-gen issue tracker
- Raspberry Pi Stack Exchange

---

## Version Control & Contribution Guidelines

### Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

Types:
- feat: New feature (e.g., feat(build): add audio test support)
- fix: Bug fix (e.g., fix(boot): correct HDMI config)
- docs: Documentation (e.g., docs(readme): update build instructions)
- refactor: Code refactoring (e.g., refactor(scripts): simplify build logic)
- test: Testing (e.g., test(qemu): add boot time validation)
- chore: Maintenance (e.g., chore(deps): update pi-gen version)
```

### What to Commit

**DO commit:**
- Shell scripts
- Configuration files
- Documentation
- Test scripts
- Asset source files (if small)

**DON'T commit:**
- Built images (`*.img`)
- Build artifacts (`build/work/`)
- Large binary files (> 10MB)
- Temporary files

### Branch Strategy

- `main` - Stable, working builds
- `develop` - Active development
- `feature/*` - New features
- `fix/*` - Bug fixes

---

## Project Roadmap & Status

Current implementation status (check README for updates):

- [x] Project documentation created
- [x] Dev container configured
- [ ] Test pattern assets created
- [ ] Audio test file created
- [ ] pi-gen configuration complete
- [ ] Custom build stages implemented
- [ ] systemd auto-start services
- [ ] Boot optimization
- [ ] QEMU testing framework
- [ ] Hardware testing validated

---

## Final Notes for Copilot

When working on this project:

1. **Always check for existing patterns** before creating new approaches
2. **Test incrementally** - Don't make large changes without validation
3. **Respect the build system** - pi-gen has specific requirements
4. **Keep it simple** - Embedded systems value reliability over features
5. **Document your reasoning** - Future developers need context

Remember: The end goal is a **reliable, minimal, auto-booting HDMI tester** that works every time without human intervention. Prioritize stability and simplicity over complexity and features.

---

**Last Updated**: October 16, 2025
**Maintained By**: Project team
**For Questions**: See GitHub Issues or Discussions
