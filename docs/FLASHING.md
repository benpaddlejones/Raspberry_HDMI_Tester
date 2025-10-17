# Flashing the HDMI Tester Image to SD Card

This guide shows you how to flash the Raspberry Pi HDMI Tester image to an SD card.

## Prerequisites

### Hardware Requirements
- **SD Card**: 4GB minimum, 8GB or larger recommended
- **SD Card Reader**: USB or built-in card reader
- **Raspberry Pi**: Any model with HDMI output (Pi 3, 4, 5, Zero 2 W)

### Software Requirements
Choose one of these tools:
- **Raspberry Pi Imager** (recommended, easiest)
- **Balena Etcher** (cross-platform, user-friendly)
- **dd command** (Linux/macOS, advanced users)

## ⚠️ Important Warnings

- **All data on the SD card will be erased!**
- **Double-check device names** - writing to the wrong device can destroy your system
- **Backup any important data** from the SD card before proceeding

## Method 1: Raspberry Pi Imager (Recommended)

### Step 1: Download Raspberry Pi Imager
- **Windows/macOS**: https://www.raspberrypi.com/software/
- **Linux**:
  ```bash
  sudo apt install rpi-imager
  ```

### Step 2: Flash the Image
1. Insert SD card into your computer
2. Open Raspberry Pi Imager
3. Click "Choose OS" → "Use custom" → Select your `.img` file
4. Click "Choose Storage" → Select your SD card
5. Click "Write"
6. Wait for completion (5-10 minutes)
7. Click "Continue" when done

### Step 3: Verify
The imager will verify the write automatically. When it shows "Write Successful", your card is ready!

## Method 2: Balena Etcher

### Step 1: Download Etcher
Download from: https://www.balena.io/etcher/

Available for Windows, macOS, and Linux.

### Step 2: Flash the Image
1. Insert SD card into your computer
2. Open Balena Etcher
3. Click "Flash from file" → Select your `.img` file
4. Click "Select target" → Choose your SD card
5. Click "Flash!"
6. Enter admin password if prompted
7. Wait for completion (5-10 minutes)

### Step 3: Verify
Etcher validates the flash automatically. When it shows "Flash Complete!", eject the card.

## Method 3: dd Command (Linux/macOS)

### ⚠️ Advanced Users Only
Using `dd` incorrectly can destroy your system. Proceed with caution.

### Step 1: Identify SD Card Device

**Linux:**
```bash
# List all block devices
lsblk

# Example output:
# NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
# sda           8:0    0 238.5G  0 disk
# └─sda1        8:1    0 238.5G  0 part /
# mmcblk0     179:0    0  14.9G  0 disk       ← This is your SD card
# └─mmcblk0p1 179:1    0  14.9G  0 part
```

**macOS:**
```bash
# List all disks
diskutil list

# Example output:
# /dev/disk0 (internal):
# /dev/disk2 (external, physical):  ← This is your SD card
#    0: FDisk_partition_scheme *15.9 GB disk2
```

### Step 2: Unmount SD Card

**Linux:**
```bash
# Unmount all partitions (replace mmcblk0 with your device)
sudo umount /dev/mmcblk0*
```

**macOS:**
```bash
# Unmount disk (replace disk2 with your device)
sudo diskutil unmountDisk /dev/disk2
```

### Step 3: Flash Image

**Linux:**
```bash
# Flash the image (replace mmcblk0 with your device)
sudo dd if=build/pi-gen-work/deploy/RaspberryPi_HDMI_Tester.img \
        of=/dev/mmcblk0 \
        bs=4M \
        status=progress \
        conv=fsync

# Sync to ensure all data is written
sudo sync
```

**macOS:**
```bash
# Flash the image (replace disk2 with your device, use rdisk for faster writes)
sudo dd if=build/pi-gen-work/deploy/RaspberryPi_HDMI_Tester.img \
        of=/dev/rdisk2 \
        bs=4m \
        status=progress

# Sync to ensure all data is written
sudo sync
```

### Step 4: Verify (Optional)

```bash
# Read back from SD card and compare (Linux)
sudo dd if=/dev/mmcblk0 \
        of=/tmp/verify.img \
        bs=4M \
        count=$(stat -c%s build/pi-gen-work/deploy/RaspberryPi_HDMI_Tester.img | awk '{print int($1/4194304)+1}')

# Compare
diff build/pi-gen-work/deploy/RaspberryPi_HDMI_Tester.img /tmp/verify.img
```

## Method 4: Windows (Win32 Disk Imager)

### Step 1: Download Win32 Disk Imager
Download from: https://sourceforge.net/projects/win32diskimager/

### Step 2: Flash the Image
1. Insert SD card into your computer
2. Open Win32 Disk Imager as Administrator
3. Click folder icon → Select your `.img` file
4. Select your SD card drive letter
5. Click "Write"
6. Confirm the warning
7. Wait for completion

## After Flashing

### Step 1: Safely Eject
Always safely eject the SD card:
- **Windows**: Right-click drive → "Eject"
- **macOS**: Drag to trash or `diskutil eject /dev/disk2`
- **Linux**: `sudo eject /dev/mmcblk0`

### Step 2: Insert into Raspberry Pi
1. Remove SD card from computer
2. Insert into Raspberry Pi SD card slot
3. Connect HDMI cable to display
4. Connect power supply
5. Pi will boot automatically!

## Expected Behavior

After inserting the SD card and powering on:

1. **Boot time**: 20-30 seconds
2. **Display**: Test pattern appears fullscreen at 1920x1080
3. **Audio**: Test audio plays continuously through HDMI
4. **LED**: Green activity LED blinks during boot, then steady

## Troubleshooting

### SD Card Not Recognized by Raspberry Pi

**Symptoms**: Red LED on, no display

**Solutions**:
- Try reflashing the image
- Use a different SD card (some cards are incompatible)
- Check SD card is properly seated
- Try a different SD card reader

### "Not Enough Space" Error When Flashing

**Cause**: SD card is too small (< 4GB)

**Solution**: Use a 4GB or larger SD card

### Flash Fails or Verifies Incorrectly

**Solutions**:
1. Try a different SD card (card may be faulty)
2. Try a different card reader
3. Check the `.img` file isn't corrupted:
   ```bash
   md5sum build/pi-gen-work/deploy/RaspberryPi_HDMI_Tester.img
   ```

### "Device is Busy" Error (Linux)

**Cause**: SD card is auto-mounted

**Solution**:
```bash
# Find what's mounted
mount | grep mmcblk0

# Unmount everything
sudo umount /dev/mmcblk0*
```

### Write Protected SD Card

**Symptoms**: "Read-only file system" or "Write protected" error

**Solution**: Check the physical lock switch on the SD card adapter - slide it to unlocked position

## SD Card Recommendations

### Recommended Brands
- **SanDisk Ultra** (good performance/price)
- **Samsung EVO** (reliable)
- **Kingston Canvas Select** (budget-friendly)

### Avoid
- No-name/generic cards (often slower or unreliable)
- Very old cards (may not be compatible)

### Size Recommendations
- **4GB**: Minimum (tight fit)
- **8GB**: Recommended (room for logs)
- **16GB+**: Overkill but works fine

### Speed Class
- **Class 10** or **U1** minimum
- **U3** or **A1** for best performance

## Expanding the Filesystem (Optional)

The image is sized to fit on 4GB cards. If using a larger card:

```bash
# On the Raspberry Pi (if you need to access it)
sudo raspi-config
# Choose: Advanced Options → Expand Filesystem
# Reboot
```

**Note**: Not necessary for HDMI tester use case.

## Next Steps

1. **Insert SD card** into Raspberry Pi
2. **Connect HDMI** to display
3. **Power on** - it should just work!
4. See [CUSTOMIZATION.md](CUSTOMIZATION.md) for modifications
5. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if issues arise

## Additional Resources

- **Raspberry Pi Documentation**: https://www.raspberrypi.com/documentation/
- **SD Card Compatibility**: https://elinux.org/RPi_SD_cards
- **GitHub Issues**: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
