# Boot Time Optimization Plan for Raspberry Pi HDMI Tester

## Overview

This document outlines a comprehensive plan to optimize the boot time of the Raspberry Pi HDMI Tester. The current boot time is estimated at 45-60 seconds, and with these optimizations, we aim to reduce it to 15-25 seconds.

## Optimization Table

| **Optimization** | **Overall Impact** | **Expected Time Savings** | **Implementation Complexity** |
|------------------|-------------------|---------------------------|-------------------------------|
| **1. Reduce service restart delays** | **Low** | **2-3 seconds** | Very Low |
| - Reduce display RestartSec from 10s to 5s | Low | 1 second | Very Low |
| - Reduce audio RestartSec from 15s to 8s | Low | 1-2 seconds | Very Low |
| **2. Add kernel boot optimizations** | **High** | **8-15 seconds** | Medium |
| - Add `quiet splash loglevel=1` to cmdline.txt | Medium | 3-5 seconds | Low |
| - Add `fastboot` parameter | Medium | 2-4 seconds | Low |
| - Add `noswap` parameter | Low | 1-2 seconds | Low |
| - Optimize systemd targets | Medium | 3-5 seconds | Medium |
| **3. Disable unnecessary services** | **Medium** | **5-10 seconds** | Medium |
| - Disable `avahi-daemon` (mDNS discovery) | Medium | 2-3 seconds | Low |
| - Disable `bluetooth` service | Low | 1-2 seconds | Low |
| - Disable `rsyslog` (use journald only) | Low | 1-2 seconds | Low |
| - Disable `triggerhappy` (GPIO events) | Low | 1 second | Low |
| **4. Optimize filesystem and storage** | **Medium** | **3-8 seconds** | Medium |
| - Add `noatime` mount option | Medium | 2-3 seconds | Low |
| - Reduce filesystem check frequency | Low | 1-2 seconds | Low |
| - Optimize ext4 mount options | Medium | 2-3 seconds | Medium |
| **5. CPU/Memory optimizations** | **Low** | **1-2 seconds** | Low |
| - GPU memory already optimized at 64MB | N/A | 0 seconds | N/A |
| - Add `arm_freq=1000` (conservative overclock) | Low | 1-2 seconds | Low |
| **6. Advanced systemd optimizations** | **Medium** | **5-8 seconds** | High |
| - Create custom systemd target | Medium | 3-4 seconds | High |
| - Parallel service startup | Medium | 2-4 seconds | High |
| - Remove unnecessary dependencies | Low | 1-2 seconds | Medium |

## Summary

- **Total Expected Boot Time Improvement**: 18-35 seconds
- **Current estimated boot time**: 30-45 seconds (already faster due to framebuffer mode)
- **Optimized estimated boot time**: 12-20 seconds
- **Architecture advantage**: No X11/Wayland/compositor overhead = faster boot

## Implementation Priority

### 1. Quick Wins (5 minutes implementation)
- Basic cmdline.txt optimizations
- Service restart delay reduction
- **Expected savings**: 10-18 seconds

### 2. Medium Effort (15 minutes implementation)
- Disable unnecessary services
- Filesystem optimizations
- **Expected savings**: 8-15 seconds

### 3. Advanced Optimizations (30+ minutes implementation)
- Custom systemd targets
- Parallel service startup
- CPU overclocking
- **Expected savings**: 3-5 seconds

**Note**: Framebuffer architecture already provides significant boot speed advantage over X11/Wayland systems.

## Current Configuration Analysis

### Key Findings

- **Architecture**: Console/framebuffer mode (no X11/Wayland/compositor overhead)
- **Display**: mpv displays image (minimal startup time)
- **Audio**: mpv with ALSA backend (direct hardware access)
- **Services**: Simple systemd services with minimal dependencies
- **Missing optimization**: No cmdline.txt boot parameters configured
- **Unused services**: `avahi-daemon`, `bluetooth` enabled but not needed
- **Opportunity**: Reduce service restart delays, optimize systemd dependencies

### Current Service Configuration

```bash
# hdmi-display.service
# - Runs as root for framebuffer access
# - RestartSec=10 (can be reduced)
# - After=local-fs.target (minimal dependency)

# hdmi-audio.service
# - Runs as user pi with audio group
# - RestartSec=15 (can be reduced)
# - After=sound.target, multi-user.target
# - StartLimitInterval=200, StartLimitBurst=5
```

### Current Boot Configuration

```bash
# config.txt settings
boot_delay=0          # Already optimized
disable_splash=1      # Already optimized
gpu_mem=64            # Already optimized for console mode
```

## Detailed Implementation Plan

### 1. Service Restart Delay Optimization

**Files to modify**:
- `build/stage3/03-autostart/files/hdmi-display.service`
- `build/stage3/03-autostart/files/hdmi-audio.service`

**Changes**:
```bash
# Display service: RestartSec=10 → 5
RestartSec=5

# Audio service: RestartSec=15 → 8
RestartSec=8
```

**Rationale**: These delays only affect restart after failure, not initial boot. Display service starts instantly, no pre-delay needed. ALSA audio initializes quickly with modern kernels.

### 2. Kernel Boot Parameters

**Files to create/modify**:
- New: `build/stage3/05-cmdline-config/00-run.sh`

**Parameters to add**:
```bash
quiet splash loglevel=1 fastboot noswap
```

**Benefits**:
- `quiet`: Reduces console output
- `splash`: Shows splash screen instead of boot messages
- `loglevel=1`: Only show critical messages
- `fastboot`: Skip some hardware detection delays
- `noswap`: Disable swap (not needed for this application)

### 3. Service Disabling

**Files to modify**:
- `build/stage3/03-autostart/00-run.sh`

**Services to disable**:
```bash
systemctl disable avahi-daemon
systemctl disable bluetooth
systemctl disable rsyslog
systemctl disable triggerhappy
```

### 4. Filesystem Optimizations

**Files to modify**:
- `build/stage3/05-cmdline-config/00-run.sh`

**fstab optimizations**:
```bash
# Add noatime,relatime options
/dev/mmcblk0p2 / ext4 defaults,noatime,relatime 0 1
```

### 5. CPU Frequency Optimization (Optional)

**Files to modify**:
- `build/stage3/04-boot-config/00-run.sh`

**Changes**:
```bash
# Conservative overclock for faster boot (optional)
arm_freq=1000
over_voltage=2
```

**Note**: GPU memory already optimized at 64MB for console/framebuffer mode.

### 6. Advanced Systemd Target (Optional)

**New files to create**:
- `build/stage3/06-systemd-optimization/00-run.sh`
- `build/stage3/06-systemd-optimization/files/hdmi-tester.target`

**Custom target for parallel startup**:
```ini
[Unit]
Description=HDMI Tester Target
Requires=basic.target
After=basic.target
AllowIsolate=yes

[Install]
Alias=default.target
```

## Risk Assessment

| **Optimization** | **Risk Level** | **Potential Issues** | **Mitigation** |
|------------------|----------------|---------------------|----------------|
| Service delays | **Low** | Services might fail if too aggressive | Test on real hardware |
| cmdline.txt params | **Low** | Boot failure if malformed | Validate syntax |
| Disable services | **Medium** | Loss of functionality | Keep SSH enabled |
| Filesystem opts | **Medium** | Potential corruption | Use safe options only |
| GPU memory | **Low** | Display issues | 64MB sufficient for 1080p |
| Custom systemd | **High** | Boot failure | Implement last, test thoroughly |

## Testing Strategy

### 1. QEMU Testing
- Boot time cannot be accurately measured in QEMU
- Focus on boot success and service startup

### 2. Hardware Testing Requirements
- **Essential**: Test on actual Raspberry Pi hardware
- **Measure**: Time from power-on to test pattern display
- **Validate**: All services start correctly
- **Monitor**: No service failures or errors

### 3. Rollback Plan
- Keep original service files as `.backup`
- Document all changes for easy reversal
- Test each optimization incrementally

## Implementation Checklist

### Phase 1: Quick Wins
- [ ] Add basic cmdline.txt optimizations (quiet, fastboot, noswap)
- [ ] Reduce hdmi-display.service RestartSec to 5s
- [ ] Reduce hdmi-audio.service RestartSec to 8s
- [ ] Test boot success in QEMU
- [ ] **Target**: 10-18 second improvement

### Phase 2: Service Optimization
- [ ] Disable avahi-daemon
- [ ] Disable bluetooth
- [ ] Disable rsyslog (use journald only)
- [ ] Add filesystem mount optimizations (noatime)
- [ ] Test on hardware
- [ ] **Target**: Additional 8-15 second improvement
- **Note**: GPU memory already at 64MB (no change needed)

### Phase 3: Advanced (Optional)
- [ ] Create custom systemd target
- [ ] Implement parallel service startup
- [ ] Fine-tune service dependencies
- [ ] Conservative CPU overclock (arm_freq=1000)
- [ ] Comprehensive hardware testing
- [ ] **Target**: Additional 3-5 second improvement

## Success Metrics

- **Primary**: Boot time from power-on to test pattern display < 20 seconds
- **Secondary**: All services start successfully without errors
- **Tertiary**: No regression in functionality (framebuffer display, ALSA audio, SSH)
- **Architecture**: Framebuffer mode provides inherent speed advantage over X11/Wayland

## Notes

- Boot time measurements must be done on actual hardware
- QEMU testing can only validate boot success, not performance
- Consider SD card speed impact (Class 10 U3 recommended)
- Some optimizations may vary by Raspberry Pi model (3B+, 4B, 5)
- Monitor system logs for any service failures after optimization
- **Architecture advantage**: Direct display mode is significantly faster than X11/Wayland systems
- **No compositor overhead**: Direct display access eliminates display server startup time
- **ALSA direct**: No PipeWire/PulseAudio initialization delay

---

**Created**: October 20, 2025
**Status**: Planning Phase
**Next Step**: Implement Phase 1 optimizations
