# Flashing on Linux

This guide shows you how to flash the Raspberry Pi HDMI Tester image to an SD card on **Linux** (Ubuntu, Debian, Fedora, Arch, etc.).

## Prerequisites

### What You Need
- **Downloaded Image**: `RaspberryPi_HDMI_Tester.img.zip` from [GitHub Releases](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/releases)
- **SD Card**: 4GB minimum, 8GB+ recommended
- **SD Card Reader**: USB or built-in
- **Linux Distribution**: Any modern distro

### Step 1: Extract the Image

```bash
# Navigate to Downloads folder
cd ~/Downloads

# Extract the image
unzip RaspberryPi_HDMI_Tester.img.zip

# Verify extraction
ls -lh *.img
```

## Method 1: Raspberry Pi Imager (Recommended)

### Installation

**Ubuntu/Debian/Raspberry Pi OS**:
```bash
sudo apt update
sudo apt install rpi-imager
```

**Fedora**:
```bash
sudo dnf install rpi-imager
```

**Arch Linux**:
```bash
sudo pacman -S rpi-imager
```

**Other Distros** (using Snap):
```bash
sudo snap install rpi-imager
```

**Manual Download**:
- Visit: https://www.raspberrypi.com/software/
- Download the `.deb` or `.rpm` package for your distro

### Flashing the Image

1. **Insert your SD card** into the card reader

2. **Open Raspberry Pi Imager**:
   ```bash
   rpi-imager
   ```
   Or search for "Raspberry Pi Imager" in your application menu

3. Click **"Choose OS"** → Scroll down → **"Use custom"**

4. **Navigate** to your extracted `.img` file and select it

5. Click **"Choose Storage"** → Select your SD card
   - ⚠️ **Verify the device name and size match your SD card!**

6. Click **"Write"**

7. **Enter your sudo password** when prompted

8. Click **"Yes"** to confirm (all data will be erased)

9. **Wait for the process to complete** (5-10 minutes)
   - Writing image...
   - Verifying...

10. Click **"Continue"** when you see **"Write Successful"**

11. **Close** Raspberry Pi Imager

### Safely Remove SD Card

```bash
# Option 1: Using udisksctl
udisksctl unmount -b /dev/sdX1
udisksctl unmount -b /dev/sdX2
udisksctl power-off -b /dev/sdX

# Option 2: Using eject
sudo eject /dev/sdX

# Option 3: Using sync
sync
```

Replace `sdX` with your SD card device (e.g., `sdb`).

## Method 2: Balena Etcher

### Installation

**Download AppImage** (Universal):
```bash
# Download latest version
cd ~/Downloads
wget https://github.com/balena-io/etcher/releases/download/v1.18.11/balenaEtcher-1.18.11-x64.AppImage

# Make executable
chmod +x balenaEtcher-*.AppImage

# Run
./balenaEtcher-*.AppImage
```

**Ubuntu/Debian** (via repository):
```bash
curl -1sLf 'https://dl.cloudsmith.io/public/balena/etcher/setup.deb.sh' | sudo -E bash
sudo apt-get update
sudo apt-get install balena-etcher-electron
```

**Fedora** (via repository):
```bash
curl -1sLf 'https://dl.cloudsmith.io/public/balena/etcher/setup.rpm.sh' | sudo -E bash
sudo dnf install -y balena-etcher-electron
```

**Arch Linux** (AUR):
```bash
yay -S balena-etcher
```

### Flashing the Image

1. **Insert your SD card** into the card reader

2. **Open Balena Etcher**:
   ```bash
   balena-etcher-electron
   # Or run the AppImage
   ./balenaEtcher-*.AppImage
   ```

3. Click **"Flash from file"**

4. **Navigate** to your extracted `.img` file and select it

5. Click **"Select target"**

6. **Choose your SD card** from the list
   - ⚠️ **Double-check the device name and size!**

7. Click **"Flash!"**

8. **Enter your sudo password** when prompted

9. **Wait for the process to complete** (5-10 minutes)
   - Flashing...
   - Validating...

10. Click **"Flash another"** or close when done

### Safely Remove SD Card

```bash
sync
sudo eject /dev/sdX
```

Replace `sdX` with your SD card device.

## Method 3: Command Line (dd)

⚠️ **Advanced users only!** This method can destroy data if you select the wrong disk.

### Find Your SD Card

1. **Before inserting SD card**, list existing devices:
   ```bash
   lsblk
   ```

2. **Insert your SD card**

3. **List devices again** to identify the new device:
   ```bash
   lsblk
   ```

4. **Identify your SD card** (look for the size that matches):
   - Example: `/dev/sdb` (8GB card)
   - ⚠️ **Do NOT use sda** (that's usually your system drive!)
   - Look for something like:
     ```
     sdb           8:16   1   7.4G  0 disk
     ├─sdb1        8:17   1   256M  0 part
     └─sdb2        8:18   1   7.2G  0 part
     ```

### Unmount All Partitions

```bash
# Unmount all partitions on the SD card
sudo umount /dev/sdX*

# Or use this to unmount all partitions automatically
sudo umount /dev/sdX?*
```

Replace `sdX` with your SD card device (e.g., `sdb`).

### Flash the Image

1. **Navigate to the image location**:
   ```bash
   cd ~/Downloads
   ```

2. **Flash the image** (this will take 5-15 minutes):
   ```bash
   sudo dd if=RaspberryPi_HDMI_Tester.img of=/dev/sdX bs=4M status=progress conv=fsync
   ```

   **Important**:
   - Replace `sdX` with your SD card device
   - Use the **disk device** (`/dev/sdb`), NOT a partition (`/dev/sdb1`)
   - `status=progress` shows progress
   - `conv=fsync` ensures all data is written before completion

3. **Wait for completion**:
   - Progress will be shown in real-time
   - Can take 5-15 minutes depending on card speed

4. **Sync the disk** (ensure all data is written):
   ```bash
   sync
   ```

### Alternative: Using pv for Progress

For better progress visualization:

```bash
# Install pv if not already installed
sudo apt install pv  # Ubuntu/Debian
sudo dnf install pv  # Fedora
sudo pacman -S pv    # Arch

# Flash with progress bar
sudo dd if=RaspberryPi_HDMI_Tester.img | pv | sudo dd of=/dev/sdX bs=4M conv=fsync
```

### Safely Remove SD Card

```bash
# Sync and eject
sync
sudo eject /dev/sdX
```

## Using the Flashed SD Card

1. **Remove SD card** from your Linux PC
2. **Insert into Raspberry Pi** SD card slot
3. **Connect HDMI cable** to your display
4. **Connect power supply** to the Pi
5. **Wait 20-30 seconds** for boot

### Expected Behavior

- ✅ **Green LED** blinks (activity)
- ✅ **Test pattern** appears on display (1920x1080)
- ✅ **Audio** plays through HDMI continuously

## Troubleshooting

### SD Card Not Detected

**Problem**: Linux doesn't show the SD card

**Solutions**:
1. **Check dmesg logs**:
   ```bash
   sudo dmesg | tail -20
   ```
   Look for messages about new USB device or SD card

2. **Try a different USB port**

3. **Check lsusb**:
   ```bash
   lsusb
   ```
   Look for your card reader

4. **Try a different card reader**

5. **Check for driver issues**:
   ```bash
   lsmod | grep usb
   ```

### "Target is Busy" Error

**Problem**: Can't unmount or write to SD card

**Solutions**:
1. **Check what's using the device**:
   ```bash
   sudo lsof | grep /dev/sdX
   sudo fuser -m /dev/sdX
   ```

2. **Force unmount all partitions**:
   ```bash
   sudo umount -f /dev/sdX*
   ```

3. **Close file manager** (Nautilus, Dolphin, etc.)

4. **Kill any processes** using the device:
   ```bash
   sudo fuser -km /dev/sdX
   ```

### "Permission Denied" Error

**Problem**: dd command fails with permission error

**Solutions**:
1. **Use sudo** with the dd command
2. **Ensure you're in the disk group**:
   ```bash
   sudo usermod -a -G disk $USER
   ```
   Log out and back in for changes to take effect

3. **Check device permissions**:
   ```bash
   ls -l /dev/sdX
   ```

### "No Space Left on Device" Error

**Problem**: Image won't fit on SD card

**Cause**: SD card is too small (< 4GB)

**Solution**: Use a 4GB or larger SD card

### "Invalid Argument" or "Input/Output Error"

**Problem**: dd command fails with I/O error

**Solutions**:
1. **Try a different SD card** (current one may be faulty)
2. **Try a different card reader**
3. **Check for hardware issues**:
   ```bash
   sudo badblocks -v /dev/sdX
   ```
4. **Reduce block size**:
   ```bash
   sudo dd if=image.img of=/dev/sdX bs=1M status=progress conv=fsync
   ```

### Flash Completes But Pi Won't Boot

**Problem**: Only red LED, no display

**Solutions**:
1. **Verify the write**:
   ```bash
   # Check if partitions are visible
   lsblk /dev/sdX

   # Mount and check files
   sudo mount /dev/sdX1 /mnt
   ls -la /mnt
   sudo umount /mnt
   ```

2. **Re-flash the image** (may have been corrupted)

3. **Try a different SD card**:
   - Some cards are incompatible with Raspberry Pi
   - Use a branded card (SanDisk, Samsung, Kingston)

4. **Check SD card speed class**:
   - Should be **Class 10** or higher
   - **U1** or **A1** rating recommended

5. **Verify the image file**:
   ```bash
   # Check file size
   ls -lh RaspberryPi_HDMI_Tester.img

   # Verify integrity (if checksum provided)
   sha256sum RaspberryPi_HDMI_Tester.img
   ```

### Very Slow Flashing Speed

**Problem**: Taking more than 20 minutes

**Solutions**:
1. **Use larger block size**:
   ```bash
   sudo dd if=image.img of=/dev/sdX bs=16M status=progress conv=fsync
   ```

2. **Use a faster SD card** (Class 10, U3, or A1)

3. **Use a USB 3.0 port** (blue port)

4. **Check system load**:
   ```bash
   top
   htop
   ```

## SD Card Recommendations

### Recommended Brands
- **SanDisk Ultra** - Reliable, good price
- **Samsung EVO/EVO Plus** - Very reliable
- **Kingston Canvas Select** - Budget-friendly

### Recommended Sizes
- **4GB** - Minimum (tight fit)
- **8GB** - Recommended ($5-10)
- **16GB+** - More than needed but works fine

### Speed Requirements
- **Minimum**: Class 10
- **Recommended**: U1 (UHS-I)
- **Best**: U3 or A1 (faster boot times)

### Cards to Avoid
- No-name/generic cards
- Cards over 5 years old
- Cards slower than Class 10

## GUI Alternative: GNOME Disks

For users who prefer a GUI:

1. **Open GNOME Disks**:
   ```bash
   gnome-disks
   ```

2. **Select your SD card** from the left panel

3. Click the **⋮** menu → **"Restore Disk Image..."**

4. **Browse** to your `.img` file

5. Click **"Start Restoring..."**

6. **Enter your password** when prompted

7. **Wait for completion**

## Additional Help

- **Can't find the image file?** Check your `Downloads` folder
- **Still having issues?** See main [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Need to customize?** See [CUSTOMIZATION.md](CUSTOMIZATION.md)
- **Want to build from source?** See [DEVELOPMENT.md](DEVELOPMENT.md)

## Quick Reference

```bash
# Find SD card
lsblk

# Unmount all partitions
sudo umount /dev/sdX*

# Flash image (with progress)
sudo dd if=RaspberryPi_HDMI_Tester.img of=/dev/sdX bs=4M status=progress conv=fsync

# Sync and eject
sync
sudo eject /dev/sdX
```

## Next Steps

Once you've successfully flashed the SD card:

1. Insert into Raspberry Pi
2. Connect HDMI to display
3. Power on and enjoy!

For customization options, see [CUSTOMIZATION.md](CUSTOMIZATION.md).
