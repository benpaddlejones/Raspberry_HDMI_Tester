# User Troubleshooting Guide

This guide helps end users diagnose and fix issues when using the Raspberry Pi HDMI Tester.

**Audience**: End users flashing and using the HDMI Tester on Raspberry Pi hardware

**For build/development issues**: See [Build Troubleshooting Guide](TROUBLESHOOTING-BUILD.md)

## Table of Contents
- [Before You Start](#before-you-start)
- [First-Time Setup Issues](#first-time-setup-issues)
- [Raspberry Pi Won't Boot](#raspberry-pi-wont-boot)
- [Display Problems](#display-problems)
- [Audio Problems](#audio-problems)
- [Getting Help - Reporting Issues](#getting-help---reporting-issues)

---

## Before You Start

### What You Need

To use the HDMI Tester, you need:

- ✅ **Raspberry Pi** (Model 3, 4, 5, or Zero 2 W)
- ✅ **MicroSD card** (8GB or larger, Class 10 recommended)
- ✅ **Power supply** (Official Raspberry Pi power supply recommended)
- ✅ **HDMI cable** (Standard or High-Speed)
- ✅ **Display** (TV or monitor with HDMI input)
- ✅ **Computer** (To flash the SD card - Windows, Mac, or Linux)

**Optional**:
- USB keyboard (for troubleshooting)
- Ethernet cable (for SSH access)

### Test Your Equipment First

Before reporting an issue, verify your equipment works:

1. **Test HDMI Cable**:
   - Use the cable with another device (laptop, game console, etc.)
   - Try a different cable if available
   - Check for bent pins or damage

2. **Test Display**:
   - Verify display powers on
   - Try a different HDMI input port
   - Test with another HDMI device
   - Check display settings (input source, resolution)

3. **Test SD Card**:
   - Use a known-brand SD card (SanDisk, Samsung, Kingston)
   - Minimum Class 10 speed rating
   - Verify card is not write-protected (check physical switch)

4. **Test Power Supply**:
   - Use official Raspberry Pi power supply (5V, 3A minimum)
   - Avoid cheap/generic USB chargers
   - Check cable is not damaged

---

## First-Time Setup Issues

### SD Card Won't Flash

**Issue**: Can't write image to SD card on your computer

**Check**:
- ✅ SD card is not write-protected (check physical lock switch)
- ✅ Using a proper SD card reader
- ✅ SD card is formatted and recognized by computer

**Solutions**:

1. **Windows**:
   - Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
   - Select the downloaded `.img` file
   - Select your SD card (double-check drive letter!)
   - Click "Write"
   - If "write protected" error: check lock switch on SD card adapter

2. **Alternative tool**: [balenaEtcher](https://www.balena.io/etcher/)
   - More reliable for large images
   - Cross-platform (Windows/Mac/Linux)

3. **Try different SD card reader**:
   - Built-in readers sometimes fail
   - Use USB SD card reader

### Windows Says "Format This Disk"

**This is NORMAL!** Don't format the SD card.

After flashing:
- Windows cannot read Linux filesystems (ext4)
- It will ask to format the disk
- **Click "Cancel"** - Do NOT format!
- Safely eject the SD card
- The SD card is correctly formatted for Raspberry Pi

### SD Card Appears Empty After Flashing

**This is also NORMAL!**

- Windows can only see the small boot partition (~256MB)
- The main filesystem is hidden from Windows
- The Pi will see both partitions correctly
- Just eject and use the card

---

## Raspberry Pi Won't Boot

### Only Red LED, No Activity

**Symptoms**: Power LED (red) lights up, but no green activity LED

**This means**: Raspberry Pi has power but cannot read the SD card

**Check**:
1. **SD card fully inserted?**
   - Push firmly until it clicks
   - Should sit flush with the Pi

2. **SD card flashed correctly?**
   - Re-flash the SD card
   - Try a different SD card
   - Verify downloaded image is complete (not corrupted)

3. **SD card compatible?**
   - Use Class 10 or better
   - Some cheap SD cards don't work
   - Try a known-brand card

4. **Raspberry Pi model supported?**
   - Works: Pi 3, Pi 4, Pi 5, Zero 2 W
   - Might not work: Pi 1, Pi 2, original Zero

### Green LED Flashes But No Display

**Symptoms**: Activity LED (green) blinks but screen stays black

**This means**: Pi is booting but no HDMI output

**Quick Fixes**:

1. **Check HDMI cable**:
   - Firmly connected at both ends?
   - Try a different cable

2. **Check display**:
   - Powered on?
   - Correct HDMI input selected?
   - Try a different HDMI input port

3. **Try different display**:
   - Some displays don't support the default 1920x1080@60Hz
   - Try a different TV/monitor
   - Try a computer monitor instead of TV (or vice versa)

4. **Wait 60 seconds**:
   - First boot takes longer
   - Give it time to start

**Advanced Fix** (requires mounting SD card on computer):

If you have Linux or Mac:
```bash
# Mount the boot partition
# Edit config.txt
# Add this line:
hdmi_safe=1
# Save and eject
```

On Windows, use a tool like [Linux Reader](https://www.diskinternals.com/linux-reader/) to access the boot partition.

### Raspberry Pi Keeps Rebooting

**Symptoms**: Green LED blinks, then goes off, then blinks again (repeats)

**This means**: Insufficient power or corrupted image

**Solutions**:

1. **Use better power supply**:
   - Official Raspberry Pi power supply (5V, 3A)
   - Not a phone charger or generic USB adapter
   - Not powered from computer USB port

2. **Check power cable**:
   - Use the cable that came with official power supply
   - Thin/cheap cables cause voltage drops

3. **Disconnect accessories**:
   - Remove any USB devices
   - Test with just power, HDMI, and SD card

4. **Re-flash SD card**:
   - SD card might be corrupted
   - Try a different card

### Rainbow Square on Screen

**Symptoms**: Colored square in corner of screen, Pi reboots

**This means**: **Under-voltage** - power supply insufficient

**Solution**: **Use official Raspberry Pi power supply**

Generic USB chargers cannot provide enough current. The Pi detects low voltage and shows the rainbow square warning before shutting down to prevent damage.

---

## Display Problems

### No Display Output At All

**Checklist**:

1. **✅ HDMI cable connected?**
   - At both ends?
   - Try reconnecting

2. **✅ Display powered on?**
   - Check power button
   - Check power cable

3. **✅ Correct input selected?**
   - Press "Source" or "Input" button on display
   - Select the HDMI port you're using
   - Some displays have multiple HDMI inputs (HDMI 1, HDMI 2, etc.)

4. **✅ Green LED active?**
   - If only red LED: SD card problem (see above)
   - If green LED blinking: Pi is booting

5. **✅ Wait 60 seconds**
   - First boot takes longer
   - Be patient

6. **✅ Try different HDMI port**
   - On Raspberry Pi 4/5: use HDMI 0 (closest to power)
   - On display: try different input

7. **✅ Test setup with known device**
   - Connect laptop/game console to same display with same HDMI cable
   - Confirms display and cable work

### Display Shows Wrong Resolution

**Symptoms**: Image stretched, squished, or doesn't fill screen

**This is uncommon** - the tester forces 1920x1080@60Hz

**If it happens**:

You'll need to edit the SD card boot configuration:

1. **Power off Pi and remove SD card**

2. **Insert SD card into computer**

3. **Open the boot partition** (only partition Windows can see)

4. **Edit `config.txt`** (use Notepad on Windows)

5. **Find these lines**:
   ```
   hdmi_group=1
   hdmi_mode=16
   ```

6. **Try different modes**:
   ```
   # For 720p
   hdmi_group=1
   hdmi_mode=4

   # For 1080p @ 50Hz
   hdmi_group=1
   hdmi_mode=31

   # For safe mode (auto-detect)
   hdmi_safe=1
   ```

7. **Save, eject, and test**

**Reference**: [Raspberry Pi HDMI Modes](https://www.raspberrypi.com/documentation/computers/config_txt.html#hdmi-mode)

### Black Borders Around Image

**Symptoms**: Test pattern doesn't fill entire screen, black bars on edges

**Cause**: Overscan enabled (common on older TVs)

**Fix**:

1. **Remove SD card, mount on computer**
2. **Edit `config.txt`**
3. **Add this line**:
   ```
   disable_overscan=1
   ```
4. **Save, eject, test**

### Display Flickers or Has Visual Artifacts

**Possible causes**:
- HDMI cable quality
- HDMI cable too long
- Display compatibility issue
- Power supply issue

**Solutions**:

1. **Try shorter HDMI cable** (< 3 meters / 10 feet)
2. **Try high-quality HDMI cable** (certified High-Speed HDMI)
3. **Try different display**
4. **Check power supply** (use official 5V 3A adapter)
5. **Try different HDMI port on Pi** (Pi 4/5 have two ports)

---

## Audio Problems

### No Audio Through HDMI

**Important**: The display/TV must support HDMI audio!

**Check**:

1. **✅ Display has speakers?**
   - Not all monitors have built-in speakers
   - Some displays need HDMI audio enabled in their settings
   - Try a TV if using a monitor

2. **✅ Display volume not muted?**
   - Check volume on display/TV
   - Increase volume
   - Check audio settings menu

3. **✅ Correct audio input selected?**
   - Some displays have multiple audio inputs
   - Select "HDMI audio" in display settings

4. **✅ Test with another HDMI device**:
   - Connect laptop/game console to same display
   - Play audio to confirm display HDMI audio works

### Audio Still Not Working

If display supports HDMI audio but you still hear nothing:

**Use the troubleshooting script** (requires keyboard or SSH access):

1. **Connect USB keyboard to Pi**

2. **Press `Ctrl + Alt + F2`** (switch to console)

3. **Login**: username `pi`, password `raspberry`

4. **Check audio service status**:
   ```bash
   sudo systemctl status hdmi-audio.service
   journalctl -u hdmi-audio.service -n 50
   
   # Also check ALSA audio devices
   aplay -l
   ```

5. **Look for errors in output**

6. **Take photos of screen with phone** (for reporting issue)

7. **Press `Ctrl + Alt + F1`** to return to display

### Audio Plays But Sounds Bad

**Symptoms**: Audio is choppy, stuttering, or distorted

**Possible causes**:
- Slow SD card
- Insufficient power
- HDMI cable quality

**Solutions**:

1. **Use faster SD card**:
   - Class 10 minimum
   - UHS-I or better recommended

2. **Use official power supply**:
   - 5V, 3A minimum
   - Generic adapters cause issues

3. **Try different HDMI cable**:
   - Use certified High-Speed HDMI cable
   - Avoid very long cables

---

## Getting Help - Reporting Issues

If you've tried everything above and still have problems, you may have found a bug!

### How to Report an Issue

**Before reporting**, please verify:
- ✅ Tested with different HDMI cable
- ✅ Tested with different display (if possible)
- ✅ Using proper power supply
- ✅ Using known-brand SD card
- ✅ Tried re-flashing the SD card

### What to Include in Bug Report

When opening a GitHub issue, please provide:

**1. Your Hardware**:
- Raspberry Pi model (e.g., "Raspberry Pi 4 Model B 4GB")
- SD card brand and size (e.g., "SanDisk Ultra 32GB Class 10")
- Power supply specs (e.g., "Official Raspberry Pi 5V 3A adapter")
- Display/TV model
- HDMI cable type

**2. The Problem**:
- What you expected to happen
- What actually happened
- Does it happen every time or randomly?

**3. What You Tested**:
- List what you tried from this guide
- Results of each test

**4. Logs** (see below)

### How to Get Logs from the Raspberry Pi

To help diagnose issues, we need logs from your Pi. There are two ways:

#### Option A: Via SSH (Easiest)

SSH is enabled by default for troubleshooting.

**On your computer** (Windows/Mac/Linux):

1. **Connect Pi to same network as your computer**:
   - Use Ethernet cable (easiest)
   - OR configure WiFi (see section below)

2. **Open terminal/command prompt**:
   - Windows: Press `Win+R`, type `cmd`, press Enter
   - Mac: Open Terminal from Applications
   - Linux: Open Terminal

3. **Connect to Pi**:
   ```bash
   ssh pi@hdmi-tester.local
   # Password: raspberry
   ```

   If `.local` doesn't work, find Pi's IP address from your router and use:
   ```bash
   ssh pi@192.168.1.xxx
   ```

4. **Check service status**:
   ```bash
   sudo systemctl status hdmi-audio.service
   sudo systemctl status hdmi-display.service
   ```

5. **Save logs**:
   ```bash
   echo "=== Display Service ===" > debug.log
   sudo journalctl -u hdmi-display.service --no-pager >> debug.log
   echo "" >> debug.log
   echo "=== Audio Service ===" >> debug.log
   sudo journalctl -u hdmi-audio.service --no-pager >> debug.log
   echo "" >> debug.log
   echo "=== System Log ===" >> debug.log
   sudo journalctl -n 100 --no-pager >> debug.log
   echo "" >> debug.log
   echo "=== Boot Messages ===" >> debug.log
   sudo dmesg >> debug.log
   ```

6. **Download log to your computer**:
   ```bash
   # In a NEW terminal on your computer (not on Pi)
   scp pi@hdmi-tester.local:debug.log ~/Downloads/
   ```

7. **Attach `debug.log` to GitHub issue**

#### Option B: Via USB Keyboard (No Network)

**What you need**: USB keyboard

**Steps**:

1. **Connect USB keyboard to Raspberry Pi**

2. **Press `Ctrl + Alt + F2`** to switch to console

3. **Login**:
   - Username: `pi`
   - Password: `raspberry`

4. **Insert USB flash drive** into Pi

5. **Wait 5 seconds**, then run:
   ```bash
   # Find USB drive
   lsblk
   # Look for your USB drive (e.g., sda1)

   # Mount it
   sudo mount /dev/sda1 /mnt

   # Save logs
   echo "=== Display Service ===" > /mnt/debug.log
   sudo journalctl -u hdmi-display.service --no-pager >> /mnt/debug.log
   echo "" >> /mnt/debug.log
   echo "=== Audio Service ===" >> /mnt/debug.log
   sudo journalctl -u hdmi-audio.service --no-pager >> /mnt/debug.log
   echo "" >> /mnt/debug.log
   echo "=== System Log ===" >> /mnt/debug.log
   sudo journalctl -n 100 --no-pager >> /mnt/debug.log
   echo "" >> /mnt/debug.log
   echo "=== Boot Messages ===" >> /mnt/debug.log
   sudo dmesg >> /mnt/debug.log

   # Safely unmount
   sudo umount /mnt
   ```

6. **Remove USB drive** from Pi

7. **Plug USB drive into computer**

8. **File `debug.log` is now on USB drive** - attach it to GitHub issue

### Submitting the Issue

1. **Go to**: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues

2. **Click "New Issue"**

3. **Fill in**:
   - **Title**: Short description (e.g., "No HDMI audio on Samsung TV")
   - **Description**: Your hardware, problem details, what you tested

4. **Attach logs**: Drag and drop `debug.log` file onto the issue text box

5. **Click "Submit new issue"**

We'll review and respond as soon as possible!

---

## Advanced: Connecting to WiFi

WiFi is NOT configured by default. If you need it for SSH troubleshooting:

**Option 1: Ethernet** (Recommended)
- Simply plug in Ethernet cable
- No configuration needed
- Use `ssh pi@hdmi-tester.local`

**Option 2: Configure WiFi via SD card** (Raspberry Pi OS Bookworm method)

1. **Power off Pi, remove SD card**

2. **Insert SD card into computer**

3. **Open boot partition** (Windows can see this)

4. **Create file named `wpa_supplicant.conf`** (no .txt extension!)

5. **Edit with Notepad**, add:
   ```
   country=US
   ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
   update_config=1

   network={
       ssid="YourWiFiName"
       psk="YourWiFiPassword"
   }
   ```

6. **Change `country=`** to your 2-letter country code (US, GB, AU, etc.)

7. **Change `YourWiFiName`** and `YourWiFiPassword`** to your WiFi details

8. **Save, eject SD card**

9. **Insert into Pi and boot**

10. **Wait 30 seconds for WiFi to connect**

11. **Find Pi's IP address** from your router

12. **SSH using**: `ssh pi@<ip-address>`

---

## Safety & Security Notes

### Default SSH Credentials

- **Username**: `pi`
- **Password**: `raspberry`

⚠️ **Warning**: These are the default credentials for troubleshooting!

**If your Pi is on an untrusted network, change the password**:
```bash
# On the Pi
passwd
# Follow prompts to set new password
```

**If you don't need SSH, you can disable it** (requires rebuild of image).

### Power Safety

- Use official Raspberry Pi power supply
- Do not use cheap/generic USB chargers
- Under-voltage can corrupt SD card
- Under-voltage can damage the Pi

### SD Card Care

- Always safely eject before removing
- Don't remove while Pi is running (can corrupt filesystem)
- Power off Pi before removing SD card

---

## Quick Reference

### Default Credentials
- **Username**: `pi`
- **Password**: `raspberry`
- **Hostname**: `hdmi-tester.local`

### What Should Happen
1. Pi boots (green LED blinks)
2. Test pattern appears on display after ~30 seconds
3. Audio loops continuously through HDMI
4. No keyboard/mouse/interaction needed

### Boot Time
- **Normal**: 20-30 seconds
- **First boot**: Up to 60 seconds
- **If longer**: Power supply issue or SD card problem

### SSH Access
```bash
ssh pi@hdmi-tester.local
# Password: raspberry
```

### Useful Commands (via SSH or keyboard)
```bash
# Check display service (framebuffer)
systemctl status hdmi-display.service

# Check audio service (ALSA)
systemctl status hdmi-audio.service

# View audio logs
journalctl -u hdmi-audio.service -n 50

# View display logs
journalctl -u hdmi-display.service -n 50

# Check ALSA audio devices
aplay -l
amixer

# Restart services
sudo systemctl restart hdmi-audio.service
sudo systemctl restart hdmi-display.service

# Reboot
sudo reboot

# Shutdown
sudo shutdown -h now
```

---

## Additional Resources

- **Raspberry Pi Documentation**: https://www.raspberrypi.com/documentation/
- **HDMI Configuration Guide**: https://www.raspberrypi.com/documentation/computers/config_txt.html
- **Report Issues**: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues

---

**Still stuck?** Open an issue on GitHub with your logs and hardware details:
https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
