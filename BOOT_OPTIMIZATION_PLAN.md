# Boot Time Optimization Plan for Raspberry Pi HDMI Tester

## Overview

This document outlines a comprehensive plan to optimize the boot time of the Raspberry Pi HDMI Tester. The current boot time is estimated at 45-60 seconds, and with these optimizations, we aim to reduce it to 15-25 seconds.

## Optimization Table

| **Optimization** | **Overall Impact** | **Expected Time Savings** | **Implementation Complexity** |
|------------------|-------------------|---------------------------|-------------------------------|
| **1. Reduce service startup delays** | **High** | **15-20 seconds** | Low |
| - Reduce display service sleep from 5s to 2s | Medium | 3 seconds | Very Low |
| - Reduce audio service sleep from 20s to 8s | High | 12 seconds | Low |
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
| **5. GPU/Memory optimizations** | **Low** | **2-5 seconds** | Low |
| - Reduce GPU memory from 128MB to 64MB | Low | 1-2 seconds | Very Low |
| - Add `gpu_mem_256=64` for 256MB Pi models | Low | 1 second | Very Low |
| - Add `arm_freq=1000` (conservative overclock) | Medium | 2 seconds | Low |
| **6. Advanced systemd optimizations** | **Medium** | **5-8 seconds** | High |
| - Create custom systemd target | Medium | 3-4 seconds | High |
| - Parallel service startup | Medium | 2-4 seconds | High |
| - Remove unnecessary dependencies | Low | 1-2 seconds | Medium |

## Summary

- **Total Expected Boot Time Improvement**: 25-45 seconds
- **Current estimated boot time**: 45-60 seconds
- **Optimized estimated boot time**: 15-25 seconds

## Implementation Priority

### 1. Quick Wins (5 minutes implementation)
- Service startup delays reduction
- Basic cmdline.txt optimizations
- **Expected savings**: 15-25 seconds

### 2. Medium Effort (15 minutes implementation)
- Disable unnecessary services
- Filesystem optimizations
- **Expected savings**: 8-18 seconds

### 3. Advanced Optimizations (30+ minutes implementation)
- Custom systemd targets
- Parallel service startup
- **Expected savings**: 5-8 seconds

## Current Configuration Analysis

### Key Findings

- **Major bottleneck**: 20-second sleep in `hdmi-audio.service`
- **Unnecessary delay**: 5-second sleep in `hdmi-display.service`
- **Missing optimization**: No cmdline.txt boot parameters configured
- **Unused services**: `avahi-daemon` enabled but not needed for HDMI testing
- **Opportunity**: Custom systemd target for faster parallel startup

### Current Service Delays

```bash
# hdmi-display.service
ExecStartPre=/bin/sleep 5

# hdmi-audio.service
ExecStartPre=/bin/sleep 20
```

### Current Boot Configuration

```bash
# config.txt settings
boot_delay=0          # Already optimized
disable_splash=1      # Already optimized
gpu_mem=128          # Could be reduced to 64MB
```

## Detailed Implementation Plan

### 1. Service Startup Optimization

**Files to modify**:
- `build/stage3/03-autostart/files/hdmi-display.service`
- `build/stage3/03-autostart/files/hdmi-audio.service`

**Changes**:
```bash
# Display service: 5s → 2s
ExecStartPre=/bin/sleep 2

# Audio service: 20s → 8s
ExecStartPre=/bin/sleep 8
```

**Rationale**: Original delays were conservative. Audio needs some delay for ALSA initialization, but 20s is excessive.

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

### 5. GPU Memory Optimization

**Files to modify**:
- `build/stage3/04-boot-config/00-run.sh`

**Changes**:
```bash
# Reduce from 128MB to 64MB
gpu_mem=64
gpu_mem_256=64
```

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
- [ ] Reduce hdmi-display.service sleep to 2s
- [ ] Reduce hdmi-audio.service sleep to 8s
- [ ] Add basic cmdline.txt optimizations
- [ ] Test boot success in QEMU
- [ ] **Target**: 15-20 second improvement

### Phase 2: Service Optimization
- [ ] Disable avahi-daemon
- [ ] Disable bluetooth (if not needed)
- [ ] Add filesystem mount optimizations
- [ ] Reduce GPU memory to 64MB
- [ ] Test on hardware
- [ ] **Target**: Additional 8-15 second improvement

### Phase 3: Advanced (Optional)
- [ ] Create custom systemd target
- [ ] Implement parallel service startup
- [ ] Fine-tune service dependencies
- [ ] Comprehensive hardware testing
- [ ] **Target**: Additional 5-8 second improvement

## Success Metrics

- **Primary**: Boot time from power-on to test pattern display < 25 seconds
- **Secondary**: All services start successfully without errors
- **Tertiary**: No regression in functionality (HDMI display, audio, SSH)

## Notes

- Boot time measurements must be done on actual hardware
- QEMU testing can only validate boot success, not performance
- Consider SD card speed impact (Class 10 U3 recommended)
- Some optimizations may vary by Raspberry Pi model (3B+, 4B, 5)
- Monitor system logs for any service failures after optimization

---

**Created**: October 20, 2025
**Status**: Planning Phase
**Next Step**: Implement Phase 1 optimizations
