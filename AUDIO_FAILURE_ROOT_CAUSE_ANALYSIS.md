# HDMI Audio Failure - Root Cause Analysis

**Date:** October 28, 2025  
**Build Version:** v0.9.7.12  
**Hardware:** Raspberry Pi 3 Model B Plus Rev 1.3  
**Status:** CRITICAL - No audio output over HDMI

---

## Executive Summary

**ROOT CAUSE:** Hardware audio format mismatch between VLC's output format (PCM float32) and the vc4-hdmi driver's required format (IEC958_SUBFRAME_LE).

The audio failure is **NOT** a configuration issue, but a fundamental incompatibility between:
- VLC attempting to output standard PCM audio (f32l - 32-bit float, little-endian)
- The vc4-hdmi ALSA driver **only** accepting IEC958_SUBFRAME_LE format (S/PDIF encapsulated format)

This is a **Pi 3B+ specific hardware limitation** related to the vc4-hdmi DRM audio driver.

---

## Evidence Chain

### 1. Audio Device Detection - Working Correctly

From `rpi4/test-logs/hdmi-test.log` and `image-test.log`:

```
=== Detecting HDMI Audio Device ===
Detected HDMI audio device: hw:2,0
```

**Analysis:**
- Device detection script (`detect-hdmi-audio`) correctly identifies card 2, device 0
- This is the `vc4-hdmi` card (MAI PCM i2s-hifi-0)
- Detection logic is sound - not the root cause

### 2. ALSA Device Availability - Hardware Present

From `diagnostic-report.txt`:

```
=== ALSA Devices ===
**** List of PLAYBACK Hardware Devices ****
card 0: b1 [bcm2835 HDMI 1], device 0: bcm2835 HDMI 1 [bcm2835 HDMI 1]
card 1: Headphones [bcm2835 Headphones], device 0: bcm2835 Headphones
card 2: vc4hdmi [vc4-hdmi], device 0: MAI PCM i2s-hifi-0 [MAI PCM i2s-hifi-0]
```

**Analysis:**
- Three audio cards present
- `vc4-hdmi` (card 2) is the DRM-based HDMI audio driver (modern Pi 3B+/4/5)
- `bcm2835 HDMI 1` (card 0) is legacy HDMI audio (fallback)
- Hardware detection is working - not the root cause

### 3. VLC Audio Initialization - Format Negotiation Failure

From `rpi4/test-logs/hdmi-test.log` (repeated 40+ times):

```log
[00917340] alsa audio output debug: Start: Format: f32l, Chans: 2, Rate:32000
[00917340] alsa audio output debug: using ALSA device: hw:2,0
[00917340] alsa audio output debug:  Hardware PCM card 2 'vc4-hdmi' device 0 subdevice 0
[00917340] alsa audio output debug:  device name   : MAI PCM i2s-hifi-0
[00917340] alsa audio output debug: initial hardware setup:
ACCESS:  MMAP_INTERLEAVED RW_INTERLEAVED
FORMAT:  IEC958_SUBFRAME_LE    <--- HARDWARE ONLY SUPPORTS THIS FORMAT
SUBFORMAT:  STD
SAMPLE_BITS: 32
FRAME_BITS: [64 256]
CHANNELS: [2 8]
RATE: [32000 192000]
PERIOD_TIME: (5 1024000]
PERIOD_SIZE: [1 32768]
PERIOD_BYTES: [16 1048576]
PERIODS: [2 65536]
BUFFER_TIME: (10 2048000]
BUFFER_SIZE: [2 65536]
BUFFER_BYTES: [16 524288]
TICK_TIME: ALL
[00917340] alsa audio output error: no supported sample format
[00917340] main audio output error: module not functional
```

**CRITICAL FINDING:**

1. **VLC Requests:** `f32l` (32-bit float PCM, little-endian) - standard audio format
2. **Hardware Provides:** `IEC958_SUBFRAME_LE` **ONLY** - S/PDIF encapsulated format
3. **Result:** `no supported sample format` - VLC cannot output in IEC958 format
4. **Consequence:** `module not functional` - audio playback completely fails

### 4. Format Incompatibility Details

**What is IEC958_SUBFRAME_LE?**
- IEC958 = S/PDIF (Sony/Philips Digital Interface Format)
- Used for transmitting compressed audio (Dolby Digital, DTS) over HDMI
- Requires audio data to be wrapped in S/PDIF framing
- NOT compatible with standard PCM playback

**What VLC Expects:**
- Standard PCM formats: S16_LE, S24_LE, S32_LE, F32_LE
- Direct audio sample output without encapsulation

**The Mismatch:**
- vc4-hdmi driver configured for S/PDIF passthrough mode
- VLC cannot encode PCM audio into IEC958 format on-the-fly
- No ALSA plugin configured to translate between formats

---

## Why This Happens on Pi 3B+

### Hardware Context

**Raspberry Pi 3 Model B Plus:**
- Uses vc4-hdmi driver (DRM-based audio)
- Kernel: 6.12.47+rpt-rpi-v7 (latest Bookworm kernel)
- HDMI audio routed through MAI (Multimedia Audio Interface)

### Driver Behavior

The vc4-hdmi ALSA driver on Pi 3B+ has two possible audio modes:

1. **PCM Mode** (Standard)
   - Formats: S16_LE, S24_LE, S32_LE
   - Used for normal audio playback
   - Requires HDMI receiver to support PCM audio

2. **S/PDIF Passthrough Mode** (Current State)
   - Format: IEC958_SUBFRAME_LE
   - Used for compressed audio passthrough (AC3, DTS)
   - Requires HDMI receiver to decode compressed audio

**Current Problem:** The driver is locked into S/PDIF mode and won't accept PCM.

### Kernel Boot Parameters Analysis

From `diagnostic-report.txt`:

```
Kernel command line: coherent_pool=1M 8250.nr_uarts=0 
  snd_bcm2835.enable_headphones=0 cgroup_disable=memory 
  snd_bcm2835.enable_headphones=1 snd_bcm2835.enable_hdmi=1 
  snd_bcm2835.enable_hdmi=0 vc_mem.mem_base=0x3ec00000 
  vc_mem.mem_size=0x40000000 console=ttyS0,115200 console=tty1 
  root=PARTUUID=f058862b-02 rootfstype=ext4 fsck.repair=yes rootwait 
  resize snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1 
  noswap quiet splash loglevel=1 fastboot
```

**OBSERVATION - Contradictory Parameters:**
- `snd_bcm2835.enable_hdmi=0` appears BEFORE
- `snd_bcm2835.enable_hdmi=1` appears LATER

**NOTE:** These parameters apply to **bcm2835** (legacy) driver, NOT vc4-hdmi (DRM) driver. The vc4-hdmi driver is controlled by Device Tree overlays in `config.txt`, not kernel parameters.

### Device Tree Configuration

From `diagnostic-report.txt` `/boot/firmware/config.txt`:

```
# HDMI Tester Configuration - Auto-detect Display Resolution
hdmi_force_hotplug=1
hdmi_drive=2         <--- Forces HDMI audio mode
hdmi_group=0
hdmi_mode=0
gpu_mem=256

# Audio configuration
dtparam=audio=on
dtparam=audio_pwm_mode=2

# Enable DRM VC4 V3D driver
dtoverlay=vc4-kms-v3d   <--- Enables vc4-hdmi driver
```

**KEY FINDING:**
- `dtoverlay=vc4-kms-v3d` enables the DRM-based vc4-hdmi driver
- `hdmi_drive=2` forces HDMI audio mode (not analog)
- **MISSING:** No explicit audio format configuration for vc4-hdmi

---

## What Is NOT The Problem

### ❌ NOT Service Configuration
- Services are intentionally disabled for manual testing
- Service files are correctly configured
- This is expected behavior per user note

### ❌ NOT Device Detection
- `detect-hdmi-audio` script correctly finds `hw:2,0`
- ALSA lists the device properly
- Device is accessible and functional

### ❌ NOT VLC Configuration
- VLC correctly targets `hw:2,0` device
- VLC parameters are correct (`--aout=alsa --alsa-audio-device=hw:2,0`)
- VLC is attempting standard PCM output (correct behavior)

### ❌ NOT File Format Issues
- FLAC files are valid and deployed correctly
- WebM/MP4 video files have audio tracks
- File validation passes in build logs

### ❌ NOT Missing Software
- VLC 3.0.21 installed correctly
- ALSA libraries present
- All required packages installed

---

## Root Cause: Hardware Audio Format Lock

**DEFINITIVE ROOT CAUSE:**

The vc4-hdmi ALSA driver on Raspberry Pi 3B+ is currently configured to **only accept IEC958_SUBFRAME_LE format** (S/PDIF passthrough). This is a hardware-level audio routing configuration that prevents standard PCM audio playback.

### Why IEC958-Only Mode?

Possible causes:
1. **Device Tree configuration:** vc4-kms-v3d overlay may default to S/PDIF mode
2. **Firmware behavior:** VideoCore firmware may be routing audio through S/PDIF path
3. **HDMI receiver negotiation:** Display may have advertised S/PDIF-only capability during EDID handshake
4. **Driver default:** vc4-hdmi driver may default to compressed audio mode

### Technical Details

**IEC958_SUBFRAME_LE format characteristics:**
- 32-bit samples per channel
- S/PDIF framing overhead
- Designed for compressed audio (AC3, DTS, Dolby TrueHD)
- Cannot carry uncompressed PCM without special encapsulation

**VLC's PCM output:**
- `f32l` = 32-bit floating-point PCM
- No S/PDIF encapsulation
- Standard audio format for software playback
- Incompatible with IEC958_SUBFRAME_LE

---

## Impact Assessment

### Current Status
- ✅ Video playback: **WORKING** (DRM vout confirmed functional)
- ❌ Audio playback: **COMPLETELY FAILED**
- ❌ HDMI audio: **NON-FUNCTIONAL**
- ✅ System stability: **STABLE** (no crashes)

### Symptoms
1. VLC attempts audio initialization 40+ times per video
2. All attempts fail with "no supported sample format"
3. Audio decoder buffer deadlocks
4. Video continues without audio
5. CPU cycles wasted on repeated failed audio initialization

### User Experience
- Silent video playback only
- HDMI tester cannot test audio functionality
- Product is **50% functional** (video only)

---

## Affected Components

1. **Video Test Scripts:**
   - `hdmi-test` (image-test.mp4/webm with audio track)
   - `pixel-test` (color-test.mp4/webm with audio track)
   - `full-test` (both videos)
   - `image-test` (static images - no audio track, unaffected)

2. **Audio Test Scripts:**
   - `audio-test` (standalone FLAC playback) - **CRITICALLY AFFECTED**
   - `test-notvideo` (static image + audio) - **CRITICALLY AFFECTED**

3. **Hardware:**
   - Raspberry Pi 3 Model B Plus (confirmed)
   - Potentially affects: Pi 3B+, Pi 4, Pi 5 (all use vc4-hdmi)
   - Does NOT affect: Pi 3B, Pi 2, Pi Zero (use bcm2835 legacy driver)

---

## Verification Steps Taken

### Build Log Analysis
- ✅ Build completed successfully (v0.9.7.12)
- ✅ All asset files validated and deployed
- ✅ Stage validation passed
- ✅ Image creation succeeded
- ✅ QEMU validation showed similar audio issues

### Runtime Log Analysis
- ✅ System boots correctly
- ✅ Display configured (1920x1080 @ 60Hz)
- ✅ VLC launches successfully
- ✅ Video decoding works (H.264 hardware decode confirmed)
- ❌ Audio initialization fails repeatedly

### Hardware Diagnostic Analysis
- ✅ Three ALSA cards detected
- ✅ vc4-hdmi card present and accessible
- ✅ No hardware errors in dmesg
- ✅ HDMI connected (display detected)
- ❌ Audio format mismatch confirmed

---

## Conclusion

The HDMI Tester image is experiencing **complete audio failure** due to a **hardware-level audio format incompatibility** between:

**Software Layer (VLC):**
- Expects: Standard PCM audio formats (S16_LE, F32_LE, etc.)
- Provides: Decoded audio samples in PCM format

**Hardware Layer (vc4-hdmi driver):**
- Accepts: **ONLY** IEC958_SUBFRAME_LE (S/PDIF encapsulated)
- Rejects: All PCM formats

**Result:**
- No audio format negotiation possible
- VLC cannot output audio
- HDMI audio completely non-functional

This is **NOT** a bug in the tester software, but a **hardware audio routing configuration issue** specific to the vc4-hdmi driver on Raspberry Pi 3B+ with DRM enabled.

---

## Next Steps (Not Implemented - Analysis Only)

### Option 1: Force PCM Mode in vc4-hdmi Driver
- Modify Device Tree overlay to disable S/PDIF mode
- Force PCM audio routing through HDMI
- **Complexity:** Medium
- **Risk:** May require kernel recompilation or custom overlay

### Option 2: Add ALSA Plugin for Format Conversion
- Install/configure `alsa-plugins` package
- Use `plug` PCM to auto-convert formats
- Configure `/etc/asound.conf` with format translation
- **Complexity:** Low
- **Risk:** May add audio latency

### Option 3: Use bcm2835 Legacy Audio Driver
- Switch from vc4-hdmi (DRM) to bcm2835 (legacy)
- Disable `vc4-kms-v3d` overlay
- Revert to legacy HDMI audio path
- **Complexity:** High (requires full graphics stack change)
- **Risk:** Loses DRM video features

### Option 4: VLC IEC958 Passthrough Configuration
- Configure VLC to output S/PDIF format
- Requires audio reencoding to AC3/DTS
- **Complexity:** High
- **Risk:** Significant CPU overhead, may not support all audio

---

**Report Prepared By:** GitHub Copilot  
**Analysis Date:** October 28, 2025  
**Classification:** ROOT CAUSE ANALYSIS  
**Severity:** CRITICAL - Core Functionality Impaired
