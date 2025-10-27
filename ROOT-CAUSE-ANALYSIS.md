# Outstanding Issues - HDMI Tester

**Date**: 2025-10-27
**Current Build**: v0.9.8.0 (pending rebuild with validation fix)
**Previous Build**: v0.9.7.9 (build 81 - validation failure)

---

## Status: ✅ VALIDATION FIX APPLIED - REBUILD IN PROGRESS

Recent fix applied to validation script to handle architecture suffixes correctly. Build #81 failed because validation script couldn't detect installed ARM packages.

---

## Action Required

### 1. 🔄 Rebuild Image (2-3 hours)

```bash
./scripts/build-image.sh
```

**Why**: New packages need to be installed during build:
- `vlc-plugin-video-output` - Video output modules
- `libasound2-plugins` - ALSA plugin system
- `raspberrypi-sys-mods` - BCM2835 ALSA configs

**Validation**: Build will automatically validate all packages installed.

### 2. 🧪 Test on Raspberry Pi 3 Hardware (1 hour)

**Verification checklist:**
- [ ] Video displays on HDMI (test pattern visible)
- [ ] Audio plays through HDMI (test tone audible)
- [ ] System auto-boots into test mode (no keyboard needed)
- [ ] No VLC errors in `/logs/hdmi-test.log`
- [ ] No ALSA errors in `/logs/hdmi-test.log`
- [ ] Correct video format used (MP4 on Pi 3B, verified in logs)

**Quick Test Commands** (after boot):
```bash
# Check VLC can output video
timeout 10s cvlc --vout=drm --no-audio /opt/hdmi-tester/image-test.mp4

# Check ALSA can output audio
timeout 10s cvlc --no-video --aout=alsa /opt/hdmi-tester/stereo.flac
```

---

## What Was Fixed

### Fixed Issue #1: VLC Missing Video Output Modules
- **Problem**: VLC had no video output plugins (0 vout modules)
- **Fix**: Added `vlc-plugin-video-output` to package list
- **Location**: `build/stage3/00-install-packages/00-packages` line 4
- **Status**: ✅ Applied in commit 3baa6ba

### Fixed Issue #2: ALSA Missing BCM2835 Card Definitions
- **Problem**: ALSA couldn't resolve device names (bcm2835_hdmi not found)
- **Fix**: Added `raspberrypi-sys-mods` and `libasound2-plugins` to package list
- **Location**: `build/stage3/00-install-packages/00-packages` lines 37, 40
- **Status**: ✅ Applied in commit 3baa6ba

### Fixed Issue #3: Validation Script Architecture Suffix Bug (Build #81 Failure)
- **Problem**: Validation script failed to detect installed ARM packages
  - dpkg shows packages as `vlc-plugin-base:armhf` on ARM systems
  - Validation grep pattern only matched `vlc-plugin-base ` (without suffix)
  - Caused false negatives: packages installed but validation reported NOT INSTALLED
- **Fix**: Updated `validate_package()` function to use regex matching with optional architecture suffix
  - Pattern changed from: `^ii  ${package} `
  - Pattern changed to: `^ii  ${package}(:[^ ]+)? `
  - Now correctly matches both `vlc-plugin-base` and `vlc-plugin-base:armhf`
- **Location**: `build/stage3/05-validation/00-run-chroot.sh` line 15
- **Status**: ✅ Applied in commit 227c6f0
- **Impact**: Build will now pass validation stage and proceed to image creation

### Not an Issue: Video Format Selection
- **System working correctly**: Auto-detects Pi model and uses optimal format
  - Pi 3B and below: MP4 (H.264 hardware accelerated)
  - Pi 4 and above: WebM (VP9 hardware accelerated)

---

## Build Validation

**New validation stage**: `build/stage3/05-validation/00-run-chroot.sh`

Automatically verifies during build:
- ✅ VLC packages installed
- ✅ ALSA packages installed
- ✅ VLC modules available
- ✅ ALSA config files present
- ✅ Test assets deployed (both MP4 and WebM)
- ✅ Test scripts created
- ✅ Systemd services configured

**Build will fail** if any component missing (prevents broken images).

---

## Timeline

| Step | Status | Duration |
|------|--------|----------|
| Root cause analysis | ✅ Complete | Done |
| Package fixes applied | ✅ Complete | Done |
| Build validation created | ✅ Complete | Done |
| **Rebuild image** | 🔄 **Pending** | **2-3 hours** |
| **Hardware testing** | 🔄 **Pending** | **1 hour** |

**Total remaining**: ~3-4 hours

---

## Expected Outcome

After rebuild and deployment:
- ✅ Video will display on HDMI (test pattern loops)
- ✅ Audio will play through HDMI (test tones)
- ✅ System will auto-boot without user interaction
- ✅ All test modes will function correctly
- ✅ Logs will be clean (no plugin/config errors)

---

**Next Action**: Run `./scripts/build-image.sh` to create v0.9.8.0
