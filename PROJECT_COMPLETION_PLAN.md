# Raspberry Pi HDMI Tester - Complete Project Completion Plan

**Date Created**: October 17, 2025
**Current Status**: Development environment configured, basic structure in place, core implementation needed
**Estimated Time to Completion**: 8-12 hours of focused work

---

## 📊 Current State Assessment

### ✅ COMPLETED (What Works)
1. **Documentation Framework**
   - ✅ Main README.md with comprehensive project overview
   - ✅ Copilot instructions (project-specific, general, and codespaces)
   - ✅ Dev container README and quickstart guide
   - ✅ Project structure defined

2. **Development Environment**
   - ✅ Dev container configuration (devcontainer.json)
   - ✅ Dockerfile with Ubuntu 24.04 base
   - ✅ Post-create script for initialization
   - ✅ pi-gen installed at `/opt/pi-gen`
   - ✅ QEMU ARM emulation available
   - ✅ All build dependencies installed

3. **Test Assets**
   - ✅ Test pattern image: `assets/image.png` (1920x1080, PNG, 367KB) - **Resolution fixed!**
   - ✅ Test audio file: `assets/audio.mp3` (MP3, 96kbps, 32kHz, Stereo)

4. **Project Structure**
   - ✅ All directories created (build/, scripts/, tests/, docs/, assets/)
   - ✅ Custom stage directories: 00-install-packages through 04-boot-config (5 stages)

### ❌ MISSING (What Needs to be Built)

1. **Build Configuration** (CRITICAL)
   - ✅ `build/config` - pi-gen configuration file
   - ✅ Stage skip files to control which stages run

2. **Custom Build Stages** (CORE FUNCTIONALITY)
   - ✅ `00-install-packages/` - Package list and installation scripts
   - ✅ `01-test-image/` - Deploy test pattern to image
   - ✅ `02-audio-test/` - Deploy audio file to image
   - ✅ `03-autostart/` - systemd services for auto-start
   - ✅ `04-boot-config/` - HDMI 1920x1080@60Hz configuration

3. **Build Scripts** (CRITICAL)
   - ✅ `scripts/build-image.sh` - Main build orchestrator
   - ✅ `scripts/configure-boot.sh` - Boot configuration (config.txt, cmdline.txt)
   - ❌ `scripts/setup-autostart.sh` - systemd service creation helper (optional)

4. **Testing Scripts**
   - ✅ `tests/qemu-test.sh` - QEMU emulation testing
   - ✅ `tests/validate-image.sh` - Image validation

5. **Documentation**
   - ❌ `docs/BUILDING.md` - Detailed build instructions
   - ❌ `docs/FLASHING.md` - SD card flashing guide
   - ❌ `docs/CUSTOMIZATION.md` - Customization guide
   - ❌ `docs/TROUBLESHOOTING.md` - Common issues and solutions

6. **Container Build Issue**
   - ⚠️ Dockerfile user creation fixed but not committed
   - ⚠️ Container needs rebuild to apply fixes

---

## 🎯 Complete Implementation Plan

### Phase 1: Fix Container and Commit Changes (30 minutes)

#### Task 1.1: Commit Dockerfile Fix ✅ COMPLETE
- **File**: `.devcontainer/Dockerfile`
- **Status**: ✅ Committed (0a689ce) and pushed to GitHub
- **Action**: ✅ GID/UID fix for Ubuntu 24.04 compatibility committed

#### Task 1.2: Rebuild Container ✅ COMPLETE
- **Action**: ✅ Container is running Ubuntu 24.04.3 LTS
- **How**: Container was rebuilt (either manually or automatically)
- **Verification**: ✅ All critical tools verified:
  - ✓ qemu-arm-static (v8.2.2)
  - ✓ debootstrap
  - ✓ kpartx
  - ✓ parted
  - ✓ git
  - ✓ docker
  - ✓ python3
  - ⚠️ QEMU ARM binfmt not registered (minor - won't block pi-gen builds)

---

### Phase 2: Build Configuration (1 hour)

#### Task 2.1: Create pi-gen Configuration File ✅ COMPLETE
- **File**: `build/config`
- **Status**: ✅ Created and configured
- **Purpose**: Configure pi-gen build settings
- **Contents**:
  ```bash
  IMG_NAME="RaspberryPi_HDMI_Tester"
  RELEASE="bookworm"  # Debian 12
  TARGET_HOSTNAME="hdmi-tester"
  KEYBOARD_KEYMAP="us"
  KEYBOARD_LAYOUT="English (US)"
  TIMEZONE_DEFAULT="UTC"
  FIRST_USER_NAME="pi"
  FIRST_USER_PASS="raspberry"
  ENABLE_SSH=0
  STAGE_LIST="stage0 stage1 stage2 /workspaces/Raspberry_HDMI_Tester/build/stage-custom"
  ```

#### Task 2.2: Create Stage Skip Files ✅ COMPLETE
- **Files**:
  - `build/stage3/SKIP` - Skip desktop environment ✅
  - `build/stage4/SKIP` - Skip recommended packages ✅
  - `build/stage5/SKIP` - Skip extras ✅
  - `build/stage-custom/SKIP_IMAGES` - Don't create image until our stage completes ✅
- **Status**: ✅ All skip files created

---

### Phase 3: Custom Build Stages (3 hours)

#### Task 3.1: 00-install-packages Stage ✅ COMPLETE
**Purpose**: Install required packages for display and audio
**Status**: ✅ Package list and installation script created

**File**: `build/stage-custom/00-install-packages/00-packages`
```
xserver-xorg
xinit
feh
mpv
alsa-utils
pulseaudio
```

**File**: `build/stage-custom/00-install-packages/00-run-chroot.sh`
```bash
#!/bin/bash -e
# Install packages for HDMI testing
apt-get update
apt-get install -y --no-install-recommends $(cat /tmp/00-packages)
apt-get clean
rm -rf /var/lib/apt/lists/*
```

#### Task 3.2: 01-test-image Stage ✅ COMPLETE
**Purpose**: Deploy test pattern image to the OS image
**Status**: ✅ Test pattern copied and deployment script created

**Directory**: `build/stage-custom/01-test-image/files/`
- Copy `assets/image.png` → `opt/hdmi-tester/test-pattern.png` ✅

**File**: `build/stage-custom/01-test-image/00-run.sh`
```bash
#!/bin/bash -e
# Deploy test pattern image
install -d "${ROOTFS_DIR}/opt/hdmi-tester"
install -m 644 files/test-pattern.png "${ROOTFS_DIR}/opt/hdmi-tester/"
chown -R 1000:1000 "${ROOTFS_DIR}/opt/hdmi-tester"
```

#### Task 3.3: 02-audio-test Stage ✅ COMPLETE
**Purpose**: Deploy audio test file
**Status**: ✅ Audio file copied and deployment script created

**Directory**: `build/stage-custom/02-audio-test/files/`
- Copy `assets/audio.mp3` → `opt/hdmi-tester/test-audio.mp3` ✅

**File**: `build/stage-custom/02-audio-test/00-run.sh`
```bash
#!/bin/bash -e
# Deploy audio test file
install -m 644 files/test-audio.mp3 "${ROOTFS_DIR}/opt/hdmi-tester/"
chown 1000:1000 "${ROOTFS_DIR}/opt/hdmi-tester/test-audio.mp3"
```

#### Task 3.4: 03-autostart Stage ✅ COMPLETE
**Purpose**: Create systemd services for auto-start
**Status**: ✅ Both systemd services and autostart script created

**File**: `build/stage-custom/03-autostart/files/hdmi-display.service` ✅
```ini
[Unit]
Description=HDMI Test Pattern Display
After=graphical.target
Wants=graphical.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/feh --fullscreen --hide-pointer --auto-zoom /opt/hdmi-tester/test-pattern.png
Restart=always
RestartSec=10

[Install]
WantedBy=graphical.target
```

**File**: `build/stage-custom/03-autostart/files/hdmi-audio.service` ✅
```ini
[Unit]
Description=HDMI Audio Test Playback
After=sound.target
Wants=sound.target

[Service]
Type=simple
User=pi
ExecStartPre=/bin/sleep 10
ExecStart=/usr/bin/mpv --loop=inf --no-video --audio-device=alsa /opt/hdmi-tester/test-audio.mp3
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**File**: `build/stage-custom/03-autostart/00-run.sh` ✅
```bash
#!/bin/bash -e
# Install and enable systemd services

# Install services
install -m 644 files/hdmi-display.service "${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/hdmi-audio.service "${ROOTFS_DIR}/etc/systemd/system/"

# Enable services
on_chroot << EOF
systemctl enable hdmi-display.service
systemctl enable hdmi-audio.service
EOF

# Configure auto-login for user pi
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
cat > "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/autologin.conf" << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF

# Auto-start X on login
cat >> "${ROOTFS_DIR}/home/pi/.bashrc" << 'EOF'

# Auto-start X server on login (tty1 only)
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec startx
fi
EOF

# Create minimal .xinitrc
cat > "${ROOTFS_DIR}/home/pi/.xinitrc" << 'EOF'
#!/bin/sh
# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Set background to black
xsetroot -solid black

# Window manager not needed - services handle display
exec sleep infinity
EOF

chmod +x "${ROOTFS_DIR}/home/pi/.xinitrc"
chown 1000:1000 "${ROOTFS_DIR}/home/pi/.xinitrc"
```

#### Task 3.5: 04-boot-config Stage ✅ COMPLETE
**Purpose**: Configure HDMI output for 1920x1080@60Hz
**Status**: ✅ Boot configuration script created

**File**: `build/stage-custom/04-boot-config/00-run.sh` ✅
```bash
#!/bin/bash -e
# Configure HDMI boot settings for 1920x1080 output

# Append HDMI configuration to config.txt
cat >> "${ROOTFS_DIR}/boot/firmware/config.txt" << 'EOF'

# HDMI Tester Configuration - Force 1920x1080 @ 60Hz
hdmi_force_hotplug=1
hdmi_drive=2
hdmi_group=1
hdmi_mode=16
gpu_mem=128
disable_splash=1
boot_delay=0
EOF
```

---

### Phase 4: Build Scripts (2 hours)

#### Task 4.1: Main Build Script ✅ COMPLETE
**File**: `scripts/build-image.sh`
**Purpose**: Orchestrate the entire build process
**Status**: ✅ Build orchestration script created

```bash
#!/bin/bash
# Main build script for Raspberry Pi HDMI Tester image

set -e
set -u

echo "=================================================="
echo "Raspberry Pi HDMI Tester - Image Builder"
echo "=================================================="
echo ""

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
PI_GEN_DIR="${PI_GEN_DIR:-/opt/pi-gen}"
WORK_DIR="${PROJECT_ROOT}/build/pi-gen-work"
CONFIG_FILE="${PROJECT_ROOT}/build/config"

# Check prerequisites
echo "🔍 Checking prerequisites..."
if ! command -v qemu-arm-static &> /dev/null; then
    echo "❌ Error: qemu-arm-static not found"
    exit 1
fi

if [ ! -d "${PI_GEN_DIR}" ]; then
    echo "❌ Error: pi-gen not found at ${PI_GEN_DIR}"
    exit 1
fi

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "❌ Error: Build config not found at ${CONFIG_FILE}"
    exit 1
fi

echo "✅ Prerequisites OK"
echo ""

# Prepare working directory
echo "📁 Preparing build directory..."
if [ -d "${WORK_DIR}" ]; then
    echo "   Removing existing work directory..."
    rm -rf "${WORK_DIR}"
fi

cp -r "${PI_GEN_DIR}" "${WORK_DIR}"
echo "✅ Build directory ready"
echo ""

# Copy custom stage
echo "📦 Installing custom stage..."
cp -r "${PROJECT_ROOT}/build/stage-custom" "${WORK_DIR}/"
echo "✅ Custom stage installed"
echo ""

# Copy config
echo "⚙️  Copying build configuration..."
cp "${CONFIG_FILE}" "${WORK_DIR}/config"
echo "✅ Configuration installed"
echo ""

# Copy assets to custom stages
echo "🎨 Copying test assets..."
mkdir -p "${WORK_DIR}/stage-custom/01-test-image/files"
mkdir -p "${WORK_DIR}/stage-custom/02-audio-test/files"
cp "${PROJECT_ROOT}/assets/image.png" "${WORK_DIR}/stage-custom/01-test-image/files/test-pattern.png"
cp "${PROJECT_ROOT}/assets/audio.mp3" "${WORK_DIR}/stage-custom/02-audio-test/files/test-audio.mp3"
echo "✅ Assets copied"
echo ""

# Run build
echo "🚀 Starting pi-gen build..."
echo "   This will take 30-60 minutes..."
echo ""

cd "${WORK_DIR}"
sudo ./build.sh

echo ""
echo "=================================================="
echo "✅ Build Complete!"
echo "=================================================="
echo ""
echo "Output images are in:"
echo "  ${WORK_DIR}/deploy/"
echo ""
ls -lh "${WORK_DIR}/deploy/"*.img 2>/dev/null || echo "No .img files found"
echo ""
echo "Next steps:"
echo "  1. Test the image: ./tests/qemu-test.sh"
echo "  2. Flash to SD card: See docs/FLASHING.md"
echo ""
```

#### Task 4.2: Boot Configuration Script ✅ COMPLETE
**File**: `scripts/configure-boot.sh`
**Purpose**: Configure Raspberry Pi boot settings
**Status**: ✅ Boot configuration helper script created

```bash
#!/bin/bash
# Configure Raspberry Pi boot settings for HDMI output

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <mount_point>"
    exit 1
fi

BOOT_MOUNT="$1"

if [ ! -d "${BOOT_MOUNT}" ]; then
    echo "Error: Mount point ${BOOT_MOUNT} not found"
    exit 1
fi

echo "Configuring boot settings at ${BOOT_MOUNT}..."

# Backup original config.txt
if [ -f "${BOOT_MOUNT}/config.txt" ]; then
    cp "${BOOT_MOUNT}/config.txt" "${BOOT_MOUNT}/config.txt.backup"
fi

# Append HDMI configuration
cat >> "${BOOT_MOUNT}/config.txt" << 'EOF'

# HDMI Tester Configuration
# Force HDMI output even if no display detected
hdmi_force_hotplug=1

# Use HDMI audio
hdmi_drive=2

# Set HDMI mode to CEA (consumer electronics)
hdmi_group=1

# 1920x1080 @ 60Hz
hdmi_mode=16

# GPU memory (sufficient for display)
gpu_mem=128

# Disable rainbow splash
disable_splash=1

# Reduce boot time
boot_delay=0
EOF

echo "✅ Boot configuration complete"
```

---

### Phase 5: Testing Scripts (1.5 hours)

#### Task 5.1: QEMU Testing Script ✅ COMPLETE
**File**: `tests/qemu-test.sh`
**Status**: ✅ QEMU emulation test script created

```bash
#!/bin/bash
# Test Raspberry Pi image in QEMU emulator

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <image_file.img>"
    exit 1
fi

IMAGE_FILE="$1"

if [ ! -f "${IMAGE_FILE}" ]; then
    echo "Error: Image file not found: ${IMAGE_FILE}"
    exit 1
fi

echo "=================================================="
echo "Testing Raspberry Pi Image in QEMU"
echo "=================================================="
echo ""
echo "Image: ${IMAGE_FILE}"
echo ""
echo "Starting QEMU emulation..."
echo "Press Ctrl+C to stop"
echo ""

qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256 \
    -kernel /usr/share/qemu/qemu-arm-kernel \
    -hda "${IMAGE_FILE}" \
    -append "root=/dev/sda2 panic=1" \
    -serial stdio \
    -no-reboot
```

#### Task 5.2: Image Validation Script ✅ COMPLETE
**File**: `tests/validate-image.sh`
**Status**: ✅ Image validation script created

```bash
#!/bin/bash
# Validate built image has required files

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <image_file.img>"
    exit 1
fi

IMAGE_FILE="$1"
MOUNT_POINT="/tmp/hdmi-tester-mount"

echo "Validating image: ${IMAGE_FILE}"
echo ""

# Mount image
sudo mkdir -p "${MOUNT_POINT}"
sudo kpartx -av "${IMAGE_FILE}"
sleep 2

LOOP_DEVICE=$(sudo losetup -l | grep "${IMAGE_FILE}" | awk '{print $1}')
sudo mount "${LOOP_DEVICE}p2" "${MOUNT_POINT}"

# Check for required files
echo "Checking required files..."
FILES_TO_CHECK=(
    "/opt/hdmi-tester/test-pattern.png"
    "/opt/hdmi-tester/test-audio.mp3"
    "/etc/systemd/system/hdmi-display.service"
    "/etc/systemd/system/hdmi-audio.service"
)

ALL_OK=true
for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "${MOUNT_POINT}${file}" ]; then
        echo "✅ ${file}"
    else
        echo "❌ MISSING: ${file}"
        ALL_OK=false
    fi
done

# Unmount
sudo umount "${MOUNT_POINT}"
sudo kpartx -dv "${IMAGE_FILE}"
sudo rmdir "${MOUNT_POINT}"

echo ""
if [ "${ALL_OK}" = true ]; then
    echo "✅ Validation passed!"
    exit 0
else
    echo "❌ Validation failed - missing files"
    exit 1
fi
```

---

### Phase 6: Documentation (2 hours)

#### Task 6.1: Building Guide
**File**: `docs/BUILDING.md`
- Step-by-step build instructions
- Troubleshooting common build errors
- Build time estimates
- Resource requirements

#### Task 6.2: Flashing Guide
**File**: `docs/FLASHING.md`
- SD card preparation
- Using Raspberry Pi Imager
- Using `dd` command
- Using Balena Etcher
- Verification steps

#### Task 6.3: Customization Guide
**File**: `docs/CUSTOMIZATION.md`
- Replacing test pattern
- Replacing audio file
- Changing boot settings
- Adding custom packages
- Modifying services

#### Task 6.4: Troubleshooting Guide
**File**: `docs/TROUBLESHOOTING.md`
- Build failures
- Boot issues
- Display problems
- Audio problems
- Performance issues

---

### Phase 7: Final Testing and Quality Assurance (2 hours)

#### Task 7.1: Build Test
- Execute complete build process
- Verify image is created
- Check image size (should be < 2GB)

#### Task 7.2: QEMU Test
- Boot image in QEMU
- Verify services start
- Check for errors in logs

#### Task 7.3: Hardware Test (if available)
- Flash to SD card
- Boot on real Raspberry Pi
- Verify test pattern displays
- Verify audio plays
- Measure boot time

#### Task 7.4: Documentation Review
- Verify all documentation is accurate
- Update README with final status
- Create release notes

---

## 📋 Task Checklist (For Execution)

### Immediate Tasks (Do First)
- [x] 1. Commit Dockerfile changes ✅ DONE
- [x] 2. Rebuild dev container ✅ DONE (Ubuntu 24.04.3 LTS)
- [x] 3. Verify all tools work with `check-deps` ✅ DONE
- [x] 4. Create `build/config` file ✅ DONE
- [x] 5. Create stage skip files ✅ DONE

### Core Implementation (Do Next)
- [x] 6. Implement 00-install-packages stage ✅ DONE
- [x] 7. Implement 01-test-image stage ✅ DONE
- [x] 8. Implement 02-audio-test stage ✅ DONE
- [x] 9. Implement 03-autostart stage ✅ DONE
- [x] 9b. Implement 04-boot-config stage ✅ DONE (HDMI 1920x1080@60Hz)
- [x] 10. Create build-image.sh script ✅ DONE
- [x] 11. Make all scripts executable ✅ DONE

### Testing Infrastructure
- [x] 12. Create qemu-test.sh ✅ DONE
- [x] 13. Create validate-image.sh ✅ DONE
- [x] 14. Create configure-boot.sh ✅ DONE (already created in Phase 4)

### Documentation
- [ ] 15. Write BUILDING.md ⚠️ NEXT
- [ ] 16. Write FLASHING.md
- [ ] 17. Write CUSTOMIZATION.md
- [ ] 18. Write TROUBLESHOOTING.md

### Final Steps
- [ ] 19. Run complete build test
- [ ] 20. Validate image
- [ ] 21. Update main README with results
- [ ] 22. Create GitHub release
- [ ] 23. Tag version v1.0.0

---

## ⚠️ Known Issues to Address

1. **Test Pattern Resolution**: ✅ FIXED
   - ~~Current image is 1920x1081 (should be 1920x1080)~~
   - ✅ **Fixed**: Resized to exactly 1920x1080

2. **Audio Format**: Using MP3 instead of WAV
   - **Decision**: MP3 is fine for testing, but WAV is more universal
   - **Consider**: Converting to WAV for better compatibility

3. **HDMI Configuration**: ✅ FIXED
   - ~~Need to configure HDMI output resolution~~
   - ✅ **Fixed**: Added 04-boot-config stage with 1920x1080@60Hz settings

---

## 🎯 Success Criteria

Project is complete when:
1. ✅ Image builds successfully without errors
2. ✅ Image boots on Raspberry Pi hardware
3. ✅ Test pattern displays automatically on HDMI
4. ✅ Audio plays automatically through HDMI
5. ✅ Boot time is under 30 seconds
6. ✅ No user interaction required
7. ✅ All documentation is complete and accurate
8. ✅ QEMU testing works
9. ✅ Image size is reasonable (< 2GB for 4GB SD cards)
10. ✅ Code is committed to git with proper commit messages

---

## 📈 Estimated Timeline

| Phase | Time | Dependencies |
|-------|------|--------------|
| Phase 1: Fix Container | 30 min | None |
| Phase 2: Build Config | 1 hour | Phase 1 |
| Phase 3: Custom Stages | 3 hours | Phase 2 |
| Phase 4: Build Scripts | 2 hours | Phase 3 |
| Phase 5: Testing Scripts | 1.5 hours | Phase 4 |
| Phase 6: Documentation | 2 hours | Phase 5 |
| Phase 7: QA & Testing | 2 hours | Phase 6 |
| **Total** | **12 hours** | Sequential |

**Fast Track** (minimum viable): 6-8 hours focusing on Phases 1-5 only

---

## 🚀 Quick Start Execution Order

1. **Commit current changes** (Dockerfile fix)
2. **Create build/config** (enables pi-gen)
3. **Create all 4 custom stages** (00 through 03)
4. **Create build-image.sh** (make it work!)
5. **Run the build** (test everything)
6. **Add documentation** (help users)
7. **Test on hardware** (validate it works)
8. **Release v1.0** (ship it!)

---

**Next Action**: Start with Phase 1, Task 1.1 - Commit the Dockerfile fix.
