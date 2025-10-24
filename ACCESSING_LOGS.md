# Accessing Logs and Diagnostics

This guide explains how to access logs and diagnostic information from the Raspberry Pi HDMI Tester.

## Quick Access Summary

All logs are stored in `/tmp/` on the Raspberry Pi:

| Log File | Description | Quick View |
|----------|-------------|------------|
| `/tmp/hdmi-test.log` | HDMI test (image loop) | `less /tmp/hdmi-test.log` |
| `/tmp/pixel-test.log` | Pixel test (color fullscreen) | `less /tmp/pixel-test.log` |
| `/tmp/audio-test.log` | Audio test (MP3 loop) | `less /tmp/audio-test.log` |
| `/tmp/full-test.log` | Full test (both videos) | `less /tmp/full-test.log` |
| `/tmp/hdmi-diagnostics-*.tar.gz` | Complete diagnostic bundle | See below |

---

## Test Script Logs

Each test script automatically logs everything to `/tmp/` with comprehensive details.

### Viewing Test Logs

```bash
# View the most recent test log
less /tmp/test-*.log

# View specific test log
less /tmp/test-image-loop.log

# View live updates (follow mode)
tail -f /tmp/test-image-loop.log

# Search for errors in logs
grep -i error /tmp/test-*.log
```

### What's in Test Logs

Each test log contains:
- ✅ Complete system information (CPU, memory, GPU)
- ✅ Raspberry Pi hardware details (temperature, voltage, throttling)
- ✅ Boot configuration (HDMI settings)
- ✅ Display information (connected displays, HDMI status)
- ✅ DRM devices and permissions
- ✅ Audio device configuration
- ✅ Video file validation and metadata
- ✅ Player (VLC) capabilities
- ✅ System resources before playback
- ✅ Complete verbose output from video player
- ✅ Timestamps for all operations

---

## Complete Diagnostic Bundle

For comprehensive troubleshooting, use the `hdmi-diagnostics` command.

### Creating Diagnostic Bundle

```bash
# Run diagnostic collection
hdmi-diagnostics

# This creates:
# /tmp/hdmi-diagnostics-YYYYMMDD_HHMMSS.tar.gz
```

### What's in the Diagnostic Bundle

```
hdmi-diagnostics-YYYYMMDD_HHMMSS/
├── diagnostic-report.txt       # Complete system report (all sections below)
├── README.txt                  # Usage instructions
│
├── test-logs/                  # Test script execution logs
│   ├── hdmi-test.log
│   ├── pixel-test.log
│   ├── audio-test.log
│   └── full-test.log
│
├── system-logs/                # System log files
│   ├── syslog                  # General system log
│   ├── kern.log                # Kernel messages
│   ├── daemon.log              # Daemon messages
│   └── messages                # System messages
│
├── boot-logs/                  # Boot and kernel logs
│   ├── dmesg.txt               # Kernel ring buffer
│   └── dmesg-timestamp.txt     # Kernel ring buffer with timestamps
│
├── journals/                   # Systemd journal exports
│   ├── current-boot.log        # Full journal from current boot
│   ├── previous-boot.log       # Full journal from previous boot
│   ├── kernel.log              # Kernel messages only
│   ├── errors-current-boot.log # Errors from current boot
│   ├── warnings-current-boot.log # Warnings from current boot
│   ├── hdmi-test-service.log # Individual service logs
│   ├── pixel-test-service.log
│   ├── audio-test-service.log
│   ├── full-test-service.log
│   └── last-1000-lines.log     # Most recent journal entries
│
└── configs/                    # Configuration files
    ├── config.txt              # Boot configuration
    ├── cmdline.txt             # Kernel command line
    └── *.service               # Systemd service files
```

### Viewing the Diagnostic Bundle

```bash
# Extract the archive
cd /tmp
tar -xzf hdmi-diagnostics-*.tar.gz

# View the main report
less hdmi-diagnostics-*/diagnostic-report.txt

# Browse all files
cd hdmi-diagnostics-*/
ls -lR
```

---

## Accessing Logs Remotely

If you need to retrieve logs from the Raspberry Pi to another computer:

### Method 1: USB Drive

```bash
# 1. Insert USB drive into Raspberry Pi
# 2. Mount the drive
sudo mount /dev/sda1 /mnt

# 3. Copy logs
sudo cp /tmp/hdmi-diagnostics-*.tar.gz /mnt/
# Or copy individual logs
sudo cp /tmp/test-*.log /mnt/

# 4. Unmount
sudo umount /mnt

# 5. Remove USB drive and access on another computer
```

### Method 2: Network Transfer (SSH/SCP)

If SSH is enabled and the Pi is on the network:

```bash
# From another computer, copy the diagnostic bundle
scp pi@raspberrypi.local:/tmp/hdmi-diagnostics-*.tar.gz ./

# Or copy individual logs
scp pi@raspberrypi.local:/tmp/test-*.log ./

# Default password is 'raspberry' (change this!)
```

### Method 3: Direct Serial Console

If you have a serial console connected:

```bash
# View logs directly on serial console
cat /tmp/test-image-loop.log

# Or use the diagnostic command
hdmi-diagnostics
```

---

## Systemd Service Logs

If running tests via systemd services (auto-start), view service logs:

### View Service Status

```bash
# Check service status
sudo systemctl status hdmi-test.service
sudo systemctl status pixel-test.service
sudo systemctl status audio-test.service
sudo systemctl status full-test.service
```

# Follow live logs (Ctrl+C to exit)
sudo journalctl -u hdmi-test.service -f

# View all logs
sudo journalctl -u hdmi-test.service --no-pager

# View last 100 lines
sudo journalctl -u hdmi-test.service -n 100
### View All Failed Services

```bash
# List all failed services
sudo systemctl --failed

# View logs for failed services
sudo journalctl -p err -b 0
```

---

## Real-Time Log Monitoring

Monitor logs as they're being written:

```bash
# Follow test log in real-time
tail -f /tmp/test-image-loop.log

# Follow multiple logs
tail -f /tmp/test-*.log

# Follow system journal
sudo journalctl -f

# Follow service journal
sudo journalctl -u hd-audio-test.service -f

# Follow kernel messages
sudo dmesg -w
```

---

## Common Log Analysis Commands

### Search for Errors

```bash
# Search all test logs for errors
grep -i error /tmp/test-*.log

# Search with context (5 lines before/after)
grep -i -C 5 error /tmp/test-image-loop.log

# Search for specific keywords
grep -E "error|fail|warning" /tmp/test-*.log

# Search systemd journal for errors
sudo journalctl -p err -b 0
```

### Check Hardware Issues

```bash
# Check for under-voltage (power issues)
vcgencmd get_throttled

# Check CPU temperature
vcgencmd measure_temp

# Check HDMI status
tvservice -s

# Check for kernel errors
sudo dmesg | grep -i error

# Check for USB issues
sudo dmesg | grep -i usb
```

### View Video Player Output

```bash
# Filter VLC output from log
grep "^\[" /tmp/test-image-loop.log

# Check for codec errors
grep -i codec /tmp/test-*.log

# Check for audio device issues
grep -i "audio" /tmp/test-*.log

# Check for display/DRM issues
grep -i -E "drm|display|hdmi" /tmp/test-*.log
```

---

## Log Rotation and Cleanup

Test logs are written to `/tmp/`, which is cleared on reboot.

### Manual Cleanup

```bash
# Remove all test logs
rm /tmp/test-*.log

# Remove old diagnostic bundles
rm /tmp/hdmi-diagnostics-*.tar.gz

# Keep only the latest diagnostic bundle
ls -t /tmp/hdmi-diagnostics-*.tar.gz | tail -n +2 | xargs rm
```

### Automatic Cleanup

Logs in `/tmp/` are automatically cleared on reboot. To preserve important logs:

```bash
# Copy to persistent storage before reboot
cp /tmp/test-*.log /home/pi/
cp /tmp/hdmi-diagnostics-*.tar.gz /home/pi/
```

---

## Troubleshooting Common Issues

### No Display

1. **Check HDMI configuration:**
   ```bash
   grep hdmi /boot/firmware/config.txt
   ```

2. **Check HDMI status:**
   ```bash
   tvservice -s
   ```

3. **Check DRM devices:**
   ```bash
   ls -l /dev/dri/
   ```

4. **View display-related errors:**
   ```bash
   grep -i -E "hdmi|display|drm" /tmp/test-*.log
   sudo dmesg | grep -i hdmi
   ```

### No Audio

1. **Check ALSA devices:**
   ```bash
   aplay -l
   ```

2. **Check audio configuration:**
   ```bash
   grep hdmi_drive /boot/firmware/config.txt
   ```

3. **View audio errors:**
   ```bash
   grep -i audio /tmp/test-*.log
   ```

### Service Not Starting

1. **Check service status:**
   ```bash
   sudo systemctl status hd-audio-test.service
   ```

2. **View service journal:**
   ```bash
   sudo journalctl -u hd-audio-test.service -n 50
   ```

3. **Check for permission issues:**
   ```bash
   ls -l /usr/local/bin/test-*
   ls -l /opt/hdmi-tester/
   ```

### Performance Issues

1. **Check throttling:**
   ```bash
   vcgencmd get_throttled
   ```

2. **Check temperature:**
   ```bash
   vcgencmd measure_temp
   ```

3. **Check memory:**
   ```bash
   free -h
   ```

4. **Check system load:**
   ```bash
   top
   htop  # If available
   ```

---

## Getting Help

When reporting issues or requesting help, please include:

1. **Diagnostic bundle:**
   ```bash
   hdmi-diagnostics
   # Share the resulting .tar.gz file
   ```

2. **Test logs:**
   ```bash
   # Copy the specific test log that failed
   cat /tmp/test-image-loop.log
   ```

3. **System information:**
   ```bash
   uname -a
   cat /proc/device-tree/model
   vcgencmd version
   ```

4. **Service status:**
   ```bash
   sudo systemctl status hd-audio-test.service
   ```

5. **Recent errors:**
   ```bash
   sudo journalctl -p err -b 0 | tail -50
   ```

---

## Additional Resources

- **Raspberry Pi Documentation**: https://www.raspberrypi.com/documentation/
- **HDMI Troubleshooting**: https://www.raspberrypi.com/documentation/computers/configuration.html#hdmi-configuration
- **Systemd Journal**: `man journalctl`
- **VLC Manual**: `man vlc`
- **VLC Documentation**: https://wiki.videolan.org/

---

**Quick Reference Card:**

```bash
# View test log
less /tmp/test-image-loop.log

# Create diagnostic bundle
hdmi-diagnostics

# View service status
sudo systemctl status hd-audio-test.service

# Follow service logs
sudo journalctl -u hd-audio-test.service -f

# Search for errors
grep -i error /tmp/test-*.log

# Check HDMI status
tvservice -s

# Check temperature
vcgencmd measure_temp
```
