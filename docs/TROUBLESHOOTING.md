# Troubleshooting Guide

This guide helps you diagnose and fix common issues with the Raspberry Pi HDMI Tester in GitHub Codespaces and Windows 11.

## Table of Contents
- [Using Build Logs for Debugging](#using-build-logs-for-debugging)
- [Codespaces Build Problems](#codespaces-build-problems)
- [Raspberry Pi Boot Issues](#raspberry-pi-boot-issues)
- [Display Problems](#display-problems)
- [Audio Problems](#audio-problems)
- [Performance Issues](#performance-issues)
- [Windows 11 Flashing Issues](#windows-11-flashing-issues)

---

## Using Build Logs for Debugging

The build system generates comprehensive logs that capture everything for debugging. **Always check the logs first when troubleshooting build issues.**

### Accessing Logs

#### During Build (Local/Codespaces)
The detailed log is created at:
```bash
build/pi-gen-work/build-detailed.log
```

View it in real-time:
```bash
# In another terminal while build is running
tail -f build/pi-gen-work/build-detailed.log
```

#### After Build (Repository)
Logs are automatically committed to the repository:
```bash
# Successful builds
logs/successful-builds/build-YYYY-MM-DD_HH-MM-SS_vX.X.X.log

# Failed builds
logs/failed-builds/build-YYYY-MM-DD_HH-MM-SS_FAILED.log
```

#### GitHub Actions (Cloud Builds)
Logs are available two ways:
1. **Artifacts**: Download from workflow run (retained 90 days)
   - Go to Actions → Select workflow run → Download "build-logs-..." artifact
2. **Repository**: Automatically committed to `logs/` directory

### Analyzing Logs

#### Quick Analysis
Use the analyze script to extract key information:
```bash
./scripts/analyze-logs.sh build/pi-gen-work/build-detailed.log
```

This shows:
- Build status and duration
- Error count and details
- Stage timings
- Disk space progression
- Memory usage
- File checksums
- Recommendations

#### Comparing Builds
Compare a failed build with a successful one:
```bash
./scripts/compare-logs.sh \
  logs/successful-builds/build-2025-10-17_14-30-45_v1.0.0.log \
  logs/failed-builds/build-2025-10-17_15-22-10_FAILED.log
```

This highlights:
- Metadata differences (commits, environment)
- Error differences
- Timing differences
- Resource usage differences
- Unique errors in each build

#### Manual Search
Search for specific issues:
```bash
# Find all errors
grep -i "error" build/pi-gen-work/build-detailed.log

# Find disk space issues
grep -i "no space left\|disk full" build/pi-gen-work/build-detailed.log

# Find memory issues
grep -i "out of memory\|cannot allocate" build/pi-gen-work/build-detailed.log

# Find network issues
grep -i "failed to fetch\|404\|connection" build/pi-gen-work/build-detailed.log

# View specific stage
grep -A 50 "STAGE: Asset Validation" build/pi-gen-work/build-detailed.log
```

### What the Log Contains

The detailed log includes:

1. **Build Environment**
   - System info (OS, kernel, architecture)
   - CPU and memory specs
   - Disk space availability
   - Tool versions (qemu, git, debootstrap, etc.)
   - Environment variables

2. **Build Configuration**
   - pi-gen config file contents
   - Custom stage configuration
   - Asset locations and checksums

3. **Stage-by-Stage Output**
   - Each stage has its own section
   - Timestamps for start/end
   - Duration for each stage
   - All command output
   - Resource usage checkpoints

4. **Asset Validation**
   - Test pattern image (size, dimensions, checksum)
   - Audio file (size, format, checksum)
   - File integrity verification

5. **Error Context**
   - When errors occur, surrounding log lines are captured
   - Full error messages with stack traces
   - Failed command details

6. **Build Summary**
   - Total duration
   - Success or failure status
   - Final system state (disk, memory)
   - Output file locations and sizes

### Common Log Patterns

#### Build Succeeded
```
Status: ✅ SUCCESS
Total Duration: 00:45:23 (2723s)
```

#### Build Failed
```
Status: ❌ FAILED
Error: pi-gen build.sh failed with exit code 1
```

#### Disk Space Issue
```
ERROR: No space left on device
Disk Usage at: After pi-gen Build
Filesystem      Size  Used Avail Use%
/dev/sda1        32G   32G    0G 100%
```

#### Memory Issue
```
ERROR: Cannot allocate memory
Memory Usage at: Before pi-gen Build
              total        used        free
Mem:          4.0Gi       3.9Gi       100Mi
```

#### Network/Package Issue
```
ERROR: Failed to fetch http://archive.raspberrypi.org/...
E: Unable to fetch some archives
```

### Debugging Workflow

When a build fails:

1. **Check the build log immediately**
   ```bash
   ./scripts/analyze-logs.sh build/pi-gen-work/build-detailed.log
   ```

2. **Review the error summary**
   - Look at error count and types
   - Check recommendations section

3. **Find the error context**
   - The log shows surrounding lines for each error
   - Search for "ERROR CONTEXT" section

4. **Check resource usage**
   - Was disk space running low?
   - Was memory exhausted?
   - Review checkpoints throughout build

5. **Compare with previous successful build**
   ```bash
   # Find your last successful build
   ls -t logs/successful-builds/ | head -n 1

   # Compare
   ./scripts/compare-logs.sh \
     logs/successful-builds/<successful>.log \
     logs/failed-builds/<failed>.log
   ```

6. **Look for patterns**
   - Same error every time? = Configuration issue
   - Random failures? = Resource or network issue
   - New error after code change? = Code issue

### GitHub Actions Logs

For cloud builds via GitHub Actions:

1. **Go to repository → Actions tab**
2. **Select the failed workflow run**
3. **Expand the "Build Raspberry Pi image" step** for terminal output
4. **Download the "build-logs-..." artifact** for detailed log
5. **Check the repository's `logs/` directory** for committed log

The committed log will be available even after artifacts expire (90 days).

---

## Codespaces Build Problems

### Codespaces Won't Start

**Symptoms**: Codespace fails to create or times out

**Solutions**:
1. **Check GitHub status**: https://www.githubstatus.com/
2. **Try creating a new Codespace**:
   - Delete the current Codespace
   - Create a fresh one from the repository
3. **Check your GitHub plan**:
   - Free tier has monthly hour limits
   - May need to wait until next billing cycle

### Build Fails: "qemu-arm-static not found"

**Symptoms**: Build stops with error about missing qemu-arm-static

**Cause**: Container didn't initialize properly

**Solutions**:
```bash
# Rebuild the Codespaces container:
# 1. Open Command Palette (Ctrl+Shift+P or F1)
# 2. Type "Codespaces: Rebuild Container"
# 3. Wait for rebuild to complete (2-3 minutes)
# 4. Try the build again
```

### Build Fails: "Permission denied"

**Symptoms**: Cannot create directories or files during build

**Cause**: sudo permissions issue (should not happen in Codespaces)

**Solutions**:
```bash
# In Codespaces, you have passwordless sudo
# Verify sudo works:
sudo -v

# Check ownership of build directory
ls -la build/

# Fix permissions if needed
sudo chown -R $USER:$USER build/
```

### Build Fails: "No space left on device"

**Symptoms**: Build stops with disk space error

**Cause**: 32GB Codespaces storage is full

**Solutions**:
```bash
# Check available space
df -h

# Clean old builds
sudo rm -rf build/pi-gen-work

# Check large files
du -sh build/* | sort -h

# After cleanup, check space again
df -h
```

### Build Takes Forever (> 2 hours)

**Normal time in Codespaces**: 45-60 minutes for first build

**Possible Causes**:
- Slow internet connection in Codespaces datacenter
- GitHub throttling during high usage
- Codespace is using 2-core machine (standard free tier)

**Solutions**:
```bash
# Check internet speed in Codespaces
curl -o /dev/null http://speedtest.tele2.net/10MB.zip

# Check RAM usage
free -h

# Monitor build progress
tail -f build/pi-gen-work/work.log

# Be patient - first build downloads many packages
# Subsequent builds will be faster (30-45 minutes)
```

### Build Succeeds But validate-image.sh Fails

**Symptoms**: Image built but validation reports missing files

**Solutions**:
```bash
# Check build log for errors
less build/pi-gen-work/work.log

# Look for failed stages
grep -i "error\|fail" build/pi-gen-work/work.log

# Try clean rebuild in Codespaces
sudo rm -rf build/pi-gen-work
./scripts/build-image.sh
```

### Can't Download Built Image from Codespaces

**Symptoms**: Download fails or times out

**Solutions**:
1. **Download the .zip file** instead of .img (smaller, faster)
   - Navigate to `build/pi-gen-work/deploy/`
   - Right-click `RaspberryPi_HDMI_Tester.img.zip`
   - Select "Download"

2. **Split large files** (if >2GB):
   ```bash
   # In Codespaces, split the image
   split -b 500M build/pi-gen-work/deploy/RaspberryPi_HDMI_Tester.img image_part_

   # Download each part separately
   # Rejoin on Windows 11: copy /b image_part_* complete_image.img
   ```

3. **Use GitHub CLI to upload to release**:
   ```bash
   # Create a release and upload image
   gh release create v1.0 build/pi-gen-work/deploy/*.img.zip
   ```

---

## Raspberry Pi Boot Issues

### Red LED Only, No Green Activity

**Symptoms**: Only red power LED lights up, no green activity LED

**Possible Causes**:
- SD card not properly flashed
- Corrupted image file
- Faulty SD card
- Incompatible SD card

**Solutions**:
1. **Reflash the SD card on Windows 11**:
   - Re-download image from Codespaces
   - Use Raspberry Pi Imager (recommended)
   - Select the correct drive letter

2. **Try a different SD card**:
   - Use name-brand card (SanDisk, Samsung, Kingston)
   - Minimum Class 10 speed rating

3. **Verify image file**:
   - Check file size (~1.5-2GB uncompressed)
   - Re-extract from .zip if downloaded compressed

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

**Note**: WiFi is **not configured by default**. The HDMI tester doesn't require network access.

**If you need WiFi for troubleshooting**:
1. **Before building** (in Codespaces):
   - Add WiFi configuration to build stages
   - Edit `build/stage-custom/03-autostart/00-run.sh`
   - Add wpa_supplicant configuration

2. **After flashing** (on Windows 11):
   - Not recommended - requires Linux to mount ext4 partitions
   - Easier to rebuild in Codespaces with WiFi preconfigured

---

## Windows 11 Flashing Issues

### SD Card Not Showing in Raspberry Pi Imager

**Symptoms**: Can't see SD card in the flashing tool

**Solutions**:
1. **Check Windows Disk Management**:
   - Press `Win + X` → "Disk Management"
   - Look for your SD card (check size matches)
   - Should show as "Removable" disk

2. **Try a different USB port**:
   - Use USB 2.0 port if USB 3.0 causes issues
   - Avoid USB hubs - connect directly to PC

3. **Update card reader drivers**:
   - Device Manager → Disk Drives
   - Right-click card reader → Update driver

4. **Try a different SD card reader**

### "This Disk is Write Protected" Error

**Symptoms**: Windows says disk is write protected

**Solutions**:
1. **Check physical lock switch**:
   - On the SD card adapter
   - Slide to **unlocked** position (away from "LOCK" label)

2. **Check Windows Registry** (advanced):
   ```
   Win + R → regedit
   Navigate to: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies
   Delete WriteProtect key (or set to 0)
   ```

3. **Try different SD card** - some have built-in protection

### Windows Shows "You Need to Format the Disk"

**This is NORMAL after flashing!**

Windows cannot read Linux ext4 filesystems.

**What to do**:
- **Click "Cancel"** - Do NOT format!
- **Safely eject** the SD card
- **Ignore the error** - SD card is correctly formatted for Raspberry Pi
- **Insert into Pi** - it will work fine

### Antivirus Blocking Flash Tool

**Symptoms**: Imager/Etcher blocked or deleted by Windows Defender

**Solutions**:
1. **Add exception in Windows Security**:
   - Windows Security → Virus & threat protection → Manage settings
   - Add exclusion for the flashing tool folder

2. **Download from official sources only**:
   - Raspberry Pi Imager: https://www.raspberrypi.com/software/
   - Balena Etcher: https://www.balena.io/etcher/

### Flash Succeeds but File is Corrupted

**Symptoms**: Flash completes but validation fails, or Pi won't boot

**Solutions**:
1. **Verify downloaded file**:
   - Check file size matches expected (~1.5-2GB)
   - Re-download from Codespaces if needed

2. **Re-extract from ZIP**:
   - Use Windows built-in ZIP extraction
   - Or 7-Zip: https://www.7-zip.org/

3. **Check SD card health**:
   - Try a different, known-good SD card
   - Use H2testw to test for fake/faulty cards

4. **Try different flashing method**:
   - If Imager fails, try Balena Etcher
   - Or vice versa

---

## Getting Additional Help

### Viewing Logs in Codespaces

```bash
# Check build logs in Codespaces
less build/pi-gen-work/work.log

# Search for errors
grep -i "error\|fail" build/pi-gen-work/work.log

# Check specific stage logs
ls build/pi-gen-work/stage-custom/
```

### Viewing Logs on Raspberry Pi

**Method 1: Via SSH (Easiest)**

SSH is now enabled by default for debugging. From your computer:

```bash
# Find the Pi's IP address (check your router, or try)
ping hdmi-tester.local

# Connect via SSH (default password: raspberry)
ssh pi@hdmi-tester.local
# OR
ssh pi@<ip-address>

# View display service logs
journalctl -u hdmi-display.service

# View audio service logs  
journalctl -u hdmi-audio.service

# View all system logs
journalctl -xe

# View boot messages
dmesg
```

**Method 2: Via Physical Keyboard**

If SSH doesn't work, connect a USB keyboard to the Pi:

1. Press `Ctrl + Alt + F2` to switch to console
2. Login with username `pi` password `raspberry`
3. Run the commands above
4. Press `Ctrl + Alt + F1` to return to display

**Saving Logs to File**

To save logs for attaching to GitHub issues:

```bash
# Save all logs to USB drive
# 1. Insert USB drive into Pi
# 2. Wait 5 seconds for it to mount
# 3. Run:
sudo journalctl -u hdmi-display.service > /media/pi/*/display.log
sudo journalctl -u hdmi-audio.service > /media/pi/*/audio.log
sudo journalctl -xe > /media/pi/*/system.log
sudo dmesg > /media/pi/*/boot.log

# 4. Safely eject USB
sudo umount /media/pi/*
# 5. Remove USB drive
```

Now the log files are on your USB drive and can be attached to a GitHub issue.

### Serial Console Access (Advanced)

For advanced debugging:
1. Connect USB-to-TTL serial adapter to Pi GPIO
2. Use PuTTY on Windows 11:
   - Download: https://www.putty.org/
   - Speed: 115200
   - Serial line: COM3 (or your adapter's COM port)

### Resources

- **Raspberry Pi Forums**: https://forums.raspberrypi.com/
- **Raspberry Pi Documentation**: https://www.raspberrypi.com/documentation/
- **GitHub Issues**: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
- **Pi Boot Problems**: https://www.raspberrypi.com/documentation/computers/configuration.html#boot-options-in-config-txt

### Reporting Issues

When reporting issues on GitHub, please include relevant logs to help diagnose the problem.

**What to Include:**

1. **Your Setup:**
   - Raspberry Pi model (e.g., "Raspberry Pi 4 Model B 4GB")
   - SD card brand and size (e.g., "SanDisk Ultra 32GB")
   - Display/TV model
   - HDMI cable type (standard, high-speed, etc.)

2. **The Problem:**
   - What you expected to happen
   - What actually happened
   - When it happens (always, sometimes, after X minutes)

3. **Logs** (see below for how to collect)

**How to Collect and Attach Logs:**

**Option A: SSH Method (Recommended)**

1. Connect to Pi via SSH:
   ```bash
   ssh pi@hdmi-tester.local
   # Password: raspberry
   ```

2. Save logs to a file:
   ```bash
   # Create a combined log file
   echo "=== Display Service ===" > debug.log
   journalctl -u hdmi-display.service --no-pager >> debug.log
   echo "" >> debug.log
   echo "=== Audio Service ===" >> debug.log
   journalctl -u hdmi-audio.service --no-pager >> debug.log
   echo "" >> debug.log
   echo "=== System Log (Last 100 lines) ===" >> debug.log
   journalctl -n 100 --no-pager >> debug.log
   echo "" >> debug.log
   echo "=== Boot Messages ===" >> debug.log
   dmesg >> debug.log
   ```

3. Download the log file to your computer:
   ```bash
   # On your computer (not on the Pi)
   scp pi@hdmi-tester.local:debug.log ~/Downloads/
   ```

4. The file is now in your Downloads folder - attach it to your GitHub issue

**Option B: USB Drive Method (No Network Needed)**

1. Insert a USB drive into your Raspberry Pi

2. Connect keyboard to Pi and press `Ctrl + Alt + F2`

3. Login (username: `pi`, password: `raspberry`)

4. Run these commands:
   ```bash
   # Find USB drive
   lsblk
   # Look for something like "sda1" with 8G or similar size
   
   # Mount it (replace sda1 with your drive)
   sudo mount /dev/sda1 /mnt
   
   # Save logs
   echo "=== Display Service ===" > /mnt/debug.log
   sudo journalctl -u hdmi-display.service --no-pager >> /mnt/debug.log
   echo "" >> /mnt/debug.log
   echo "=== Audio Service ===" >> /mnt/debug.log
   sudo journalctl -u hdmi-audio.service --no-pager >> /mnt/debug.log
   echo "" >> /mnt/debug.log
   echo "=== System Log (Last 100 lines) ===" >> /mnt/debug.log
   sudo journalctl -n 100 --no-pager >> /mnt/debug.log
   echo "" >> /mnt/debug.log
   echo "=== Boot Messages ===" >> /mnt/debug.log
   sudo dmesg >> /mnt/debug.log
   
   # Unmount safely
   sudo umount /mnt
   ```

5. Remove USB drive and plug into your computer

6. The file `debug.log` is now on your USB drive - attach it to your GitHub issue

**Option C: Quick Status (No File)**

If you can't get log files, at least include this info:

```bash
# On the Pi, run:
systemctl status hdmi-display.service
systemctl status hdmi-audio.service
```

Take a photo of the screen with your phone and attach to the issue.

**Creating the GitHub Issue:**

1. Go to: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
2. Click "New Issue"
3. Fill in:
   - **Title**: Short description (e.g., "No audio output on Samsung TV")
   - **Description**: Your setup, problem description, steps to reproduce
4. **Attach logs**: Drag and drop `debug.log` onto the issue text box
5. Click "Submit new issue"

---

## Still Having Problems?

Open an issue on GitHub with:
- Detailed description
- Steps to reproduce
- Expected vs actual behavior
- Any error messages
- System information

https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
