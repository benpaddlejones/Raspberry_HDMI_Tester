# Troubleshooting Guide

This guide helps you diagnose and fix common issues with the Raspberry Pi HDMI Tester.

## Table of Contents
- [Build Problems](#build-problems)
- [Boot Issues](#boot-issues)
- [Display Problems](#display-problems)
- [Audio Problems](#audio-problems)
- [Performance Issues](#performance-issues)
- [Network/SSH Issues](#networkssh-issues)

---

## Build Problems

### Build Fails: "qemu-arm-static not found"

**Symptoms**: Build stops with error about missing qemu-arm-static

**Solution**:
```bash
# Check if installed
which qemu-arm-static

# If not found, install (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install qemu-user-static

# Verify installation
qemu-arm-static --version
```

### Build Fails: "Permission denied"

**Symptoms**: Cannot create directories or files during build

**Solution**:
```bash
# The build script needs sudo for some operations
# Make sure you can run sudo
sudo -v

# Check ownership of build directory
ls -la build/

# Fix permissions if needed
sudo chown -R $USER:$USER build/
```

### Build Fails: "No space left on device"

**Symptoms**: Build stops with disk space error

**Solution**:
```bash
# Check available space
df -h

# Clean old builds
sudo rm -rf build/pi-gen-work

# Clean Docker (if using containers)
docker system prune -a

# Check again
df -h
```

### Build Takes Forever (> 2 hours)

**Possible Causes**:
- Slow internet connection
- Insufficient RAM
- Docker resource limits

**Solutions**:
```bash
# Check internet speed
curl -o /dev/null http://speedtest.tele2.net/10MB.zip

# Check RAM usage
free -h

# If using Docker, increase resources:
# Docker Desktop → Settings → Resources
# - CPUs: 2+
# - Memory: 4GB+
# - Disk: 20GB+
```

### Build Succeeds But validate-image.sh Fails

**Symptoms**: Image built but validation reports missing files

**Solution**:
```bash
# Check build log for errors
less build/pi-gen-work/work.log

# Look for failed stages
grep -i "error\|fail" build/pi-gen-work/work.log

# Try clean rebuild
sudo rm -rf build/pi-gen-work
./scripts/build-image.sh
```

---

## Boot Issues

### Red LED Only, No Green Activity

**Symptoms**: Only red power LED lights up, no green activity LED

**Possible Causes**:
- SD card not properly flashed
- Corrupted image
- Faulty SD card
- Incompatible SD card

**Solutions**:
1. **Reflash the SD card**:
   ```bash
   sudo ./tests/validate-image.sh build/pi-gen-work/deploy/*.img
   # Flash again if validation passes
   ```

2. **Try a different SD card** (some cards are incompatible)

3. **Check SD card in another device** (verify it's not faulty)

4. **Use a branded SD card** (SanDisk, Samsung, Kingston)

### Green LED Blinks, No Display

**Symptoms**: Activity LED blinks but nothing appears on screen

**Possible Causes**:
- HDMI cable issue
- Display not compatible
- Wrong HDMI input selected
- Display doesn't support 1920x1080@60Hz

**Solutions**:
1. **Try a different HDMI cable**

2. **Try a different display/TV**

3. **Check display input** (switch to correct HDMI port)

4. **Try a different resolution**:
   - Mount SD card on computer
   - Edit `/boot/config.txt` or `/boot/firmware/config.txt`
   - Change to safe mode:
     ```
     hdmi_safe=1
     ```
   - Or try 720p:
     ```
     hdmi_group=1
     hdmi_mode=4
     ```

### Continuous Rebooting

**Symptoms**: Green LED blinks, display flickers, system restarts repeatedly

**Possible Causes**:
- Insufficient power supply
- Corrupted filesystem
- Hardware fault

**Solutions**:
1. **Use official Raspberry Pi power supply** (5V 3A recommended)

2. **Try different power supply/cable**

3. **Check SD card filesystem**:
   ```bash
   # On Linux, check the SD card
   sudo fsck /dev/mmcblk0p2
   ```

4. **Reflash the SD card**

### Kernel Panic on Boot

**Symptoms**: Text scrolling on screen, ends with "Kernel panic"

**Possible Causes**:
- Corrupted image
- Bad SD card
- Hardware incompatibility

**Solutions**:
1. **Rebuild the image** and reflash

2. **Try different SD card**

3. **Check Raspberry Pi model compatibility** (Pi 3, 4, 5, Zero 2 W should work)

---

## Display Problems

### No Display Output

**Quick Checks**:
- ✅ HDMI cable firmly connected?
- ✅ Display powered on?
- ✅ Correct HDMI input selected?
- ✅ Try different HDMI port (if display has multiple)?

**Advanced Solutions**:

1. **Check HDMI configuration**:
   - Mount SD card
   - Edit `/boot/config.txt`
   - Add:
     ```
     hdmi_force_hotplug=1
     hdmi_drive=2
     ```

2. **Try composite video** (if available):
   - Helps confirm Pi is booting
   - If composite works, it's HDMI config issue

3. **Check serial console** (advanced):
   ```bash
   # Connect USB-to-serial adapter
   # Use minicom or screen to view boot messages
   screen /dev/ttyUSB0 115200
   ```

### Display Shows Wrong Resolution

**Symptoms**: Image stretched, cropped, or wrong aspect ratio

**Solutions**:

1. **Check display native resolution**:
   - Most modern displays are 1920x1080
   - Some older displays may be different

2. **Adjust HDMI mode**:
   - Edit `/boot/config.txt`
   - Try different modes:
     ```
     # For 720p
     hdmi_group=1
     hdmi_mode=4

     # For 1080p @ 50Hz
     hdmi_group=1
     hdmi_mode=31
     ```

3. **Disable overscan**:
   ```
   disable_overscan=1
   ```

### Black Borders Around Image

**Symptoms**: Test pattern doesn't fill entire screen

**Solution**:
Edit `/boot/config.txt`:
```
disable_overscan=1

# Or adjust overscan manually
overscan_left=0
overscan_right=0
overscan_top=0
overscan_bottom=0
```

### Image Doesn't Fill Screen (Underscan)

**Symptoms**: Test pattern smaller than screen, black borders

**Solution**:
Edit `/boot/config.txt`:
```
# Adjust overscan (negative values)
overscan_left=-20
overscan_right=-20
overscan_top=-20
overscan_bottom=-20
```

### Display Flickers or Has Artifacts

**Possible Causes**:
- HDMI cable quality
- HDMI cable too long
- Power supply insufficient
- Display compatibility

**Solutions**:
1. **Use short, high-quality HDMI cable** (< 3m)
2. **Try different HDMI cable**
3. **Use official power supply**
4. **Reduce HDMI drive strength**:
   ```
   # In /boot/config.txt
   config_hdmi_boost=0
   ```

---

## Audio Problems

### No Audio Output

**Quick Checks**:
- ✅ HDMI audio enabled in `/boot/config.txt`? (`hdmi_drive=2`)
- ✅ Display/TV has HDMI audio capability?
- ✅ Display volume not muted?

**Solutions**:

1. **Check HDMI audio configuration**:
   ```bash
   # Mount SD card, edit /boot/config.txt
   hdmi_drive=2    # Must be set
   ```

2. **Check mpv is running**:
   ```bash
   # On Pi (connect keyboard, Ctrl+Alt+F2)
   systemctl status hdmi-audio.service
   ```

3. **Test audio manually**:
   ```bash
   # On Pi
   mpv --no-video /opt/hdmi-tester/test-audio.mp3
   ```

4. **Check ALSA**:
   ```bash
   # List audio devices
   aplay -l

   # Test audio
   speaker-test -c 2
   ```

### Audio Plays But Choppy/Stuttering

**Possible Causes**:
- SD card too slow
- Insufficient power
- Audio buffer issues

**Solutions**:
1. **Use faster SD card** (Class 10 or UHS-I)
2. **Use official power supply**
3. **Adjust audio buffer**:
   - Edit `hdmi-audio.service`
   - Add mpv options:
     ```
     ExecStart=/usr/bin/mpv --loop=inf --no-video --cache=yes --audio-buffer=1 /opt/hdmi-tester/test-audio.mp3
     ```

### Audio Doesn't Loop

**Symptoms**: Audio plays once then stops

**Solution**:
Check `hdmi-audio.service`:
```bash
# Must have --loop=inf
ExecStart=/usr/bin/mpv --loop=inf --no-video /opt/hdmi-tester/test-audio.mp3
```

### Wrong Audio Output (3.5mm instead of HDMI)

**Solution**:
Edit `/boot/config.txt`:
```
# Force HDMI audio
hdmi_drive=2

# Or set audio output explicitly
dtparam=audio=off   # Disable 3.5mm
```

---

## Performance Issues

### Slow Boot Time (> 60 seconds)

**Normal boot time**: 20-30 seconds

**Solutions**:
1. **Check boot delay**:
   ```
   # In /boot/config.txt
   boot_delay=0
   ```

2. **Disable unnecessary services**:
   ```bash
   # On Pi
   systemctl disable bluetooth
   systemctl disable avahi-daemon
   ```

3. **Use faster SD card**

### High CPU/Memory Usage

**Symptoms**: Pi feels sluggish, runs hot

**Solutions**:
```bash
# Check what's running
top

# Check memory
free -h

# Restart services
sudo systemctl restart hdmi-display.service
sudo systemctl restart hdmi-audio.service
```

### Pi Overheating

**Symptoms**: Rainbow square in corner, throttling warnings

**Solutions**:
1. **Add heatsink**
2. **Improve ventilation**
3. **Reduce GPU overclock** (if any)
4. **Check power supply**

---

## Network/SSH Issues

### Cannot SSH to Pi

**Note**: SSH is **disabled by default** for security

**To Enable SSH**:
1. **Before building**:
   - Edit `build/config`: `ENABLE_SSH=1`
   - **Important**: Also change default password!

2. **On existing image**:
   - Mount boot partition
   - Create empty file named `ssh`
   - Unmount and boot

### Cannot Connect to WiFi

**Note**: WiFi is **not configured by default**

**To Add WiFi**:
1. Mount SD card
2. Edit `/etc/wpa_supplicant/wpa_supplicant.conf`:
   ```
   network={
       ssid="YourNetwork"
       psk="YourPassword"
   }
   ```

---

## Getting Additional Help

### Viewing Logs

```bash
# On the Pi (connect keyboard)
journalctl -xe           # System log
systemctl status hdmi-display.service
systemctl status hdmi-audio.service
dmesg                    # Kernel messages
```

### Serial Console Access

For advanced debugging:
1. Connect USB-to-TTL serial adapter
2. Use minicom/screen:
   ```bash
   screen /dev/ttyUSB0 115200
   ```

### Resources

- **Raspberry Pi Forums**: https://forums.raspberrypi.com/
- **Raspberry Pi Documentation**: https://www.raspberrypi.com/documentation/
- **GitHub Issues**: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
- **Pi Boot Problems**: https://www.raspberrypi.com/documentation/computers/configuration.html#boot-options-in-config-txt

### Reporting Issues

When reporting issues, include:
1. Raspberry Pi model
2. SD card brand/size
3. Display model
4. Error messages
5. Build log (if build issue)
6. Boot log (if boot issue)

---

## Still Having Problems?

Open an issue on GitHub with:
- Detailed description
- Steps to reproduce
- Expected vs actual behavior
- Any error messages
- System information

https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
