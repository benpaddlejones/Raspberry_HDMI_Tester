# Flashing the HDMI Tester Image to SD Card

This guide shows you how to flash the Raspberry Pi HDMI Tester image to an SD card after building it in GitHub Codespaces.

## Prerequisites

### Built Image File
- You've completed the build in GitHub Codespaces
- Downloaded `RaspberryPi_HDMI_Tester.img.zip` to your local computer
- Extracted the `.img` file from the ZIP archive

### Hardware Requirements
- **SD Card**: 4GB minimum, 8GB or larger recommended
- **SD Card Reader**: USB or built-in card reader
- **Raspberry Pi**: Any model with HDMI output (Pi 3, 4, 5, Zero 2 W)

### Software Requirements
Choose one of these flashing tools for your operating system:
- **Raspberry Pi Imager** (recommended, easiest, works on Windows/macOS/Linux)
- **Balena Etcher** (cross-platform alternative)
- **dd command** (Linux/macOS only, advanced users)
- **Win32 Disk Imager** (Windows alternative)

## ⚠️ Important Warnings

- **All data on the SD card will be erased!**
- **Double-check device names** - writing to the wrong device can destroy your data
- **Backup any important data** from the SD card before proceeding

## Method 1: Raspberry Pi Imager (Recommended)

### Step 1: Download Raspberry Pi Imager
- **Windows/macOS**: https://www.raspberrypi.com/software/
- **Linux**:
  ```bash
  sudo apt install rpi-imager
  ```

### Step 2: Flash the Image
1. Insert SD card into your SD card reader
2. Open Raspberry Pi Imager
3. Click "Choose OS" → "Use custom" → Select your extracted `.img` file
4. Click "Choose Storage" → Select your SD card
5. Click "Write"
6. Wait for completion (5-10 minutes)
7. Click "Continue" when done

### Step 3: Verify
The imager will verify the write automatically. When it shows "Write Successful", your card is ready!

## Method 2: Balena Etcher

### Step 1: Download and Install
1. Download from: https://www.balena.io/etcher/
2. Run the installer: `balenaEtcher-Setup-x.x.x.exe`
3. Follow the installation wizard
4. Launch **balenaEtcher**

### Step 2: Flash the Image
1. **Insert SD card** into your Windows 11 PC
2. **Open balenaEtcher**
3. Click **"Flash from file"** → Browse to your extracted `.img` file
4. Click **"Select target"** → Choose your SD card (verify drive letter!)
5. Click **"Flash!"**
6. Click **"Yes"** when User Account Control prompts for permission
7. **Wait for completion** (5-10 minutes)
   - Shows progress and speed
   - Validates automatically after flashing
8. Click **"Flash another"** or close when done

### Step 3: Safely Remove
1. **Close** balenaEtcher
2. **Right-click** the SD card in File Explorer
3. Select **"Eject"**
4. **Remove the SD card**

## Method 3: Win32 Disk Imager (Classic Tool)

### Step 1: Download and Install
1. Download from: https://sourceforge.net/projects/win32diskimager/
2. Extract the ZIP file
3. Run **Win32DiskImager.exe** as Administrator

### Step 2: Flash the Image
1. **Insert SD card** into your Windows 11 PC
2. **Run Win32 Disk Imager as Administrator**
   - Right-click → "Run as administrator"
3. Click the **folder icon** → Browse to your `.img` file
4. Select your SD card **drive letter** from the dropdown (e.g., E:, F:)
5. **Double-check** the drive letter is correct!
6. Click **"Write"**
7. Click **"Yes"** to confirm
8. **Wait for completion** (5-15 minutes)
9. Click **"OK"** when you see "Write Successful"

### Step 3: Safely Remove
1. **Close** Win32 Disk Imager
2. **Right-click** the SD card in File Explorer
3. Select **"Eject"**
4. **Remove the SD card**

## After Flashing

### Step 1: Insert into Raspberry Pi
1. **Remove SD card** from your Windows 11 PC
2. **Insert** into Raspberry Pi SD card slot
3. **Connect HDMI cable** to your display
4. **Connect power supply**
5. **Pi will boot automatically!**

### Step 2: Expected Behavior

After powering on:

1. **Boot time**: 20-30 seconds
2. **Display**: Test pattern appears fullscreen at 1920x1080
3. **Audio**: Test audio plays continuously through HDMI
4. **LED**: Green activity LED blinks during boot, then steady

✅ **Success!** Your HDMI tester is now running.

## Troubleshooting (Windows 11)

### SD Card Not Showing in Imager/Etcher

**Symptoms**: Can't see SD card in the flashing tool

**Solutions**:
1. **Check File Explorer** - Does Windows see the drive?
2. **Try a different USB port** - Some ports may not work
3. **Check Disk Management**:
   - Press `Win + X` → "Disk Management"
   - Look for your SD card (check size)
   - If it has partitions, they should show up
4. **Try a different SD card reader**

### "Access Denied" or "Permission Error"

**Symptoms**: Can't write to SD card

**Solutions**:
1. **Run as Administrator**:
   - Right-click the program
   - Select "Run as administrator"
2. **Close File Explorer windows** showing the SD card
3. **Disable write protection**:
   - Check physical lock switch on SD card adapter
   - Slide to unlocked position

### "Not Enough Space" Error

**Cause**: SD card is too small (< 4GB)

**Solution**: Use a 4GB or larger SD card

### Flash Completes but Pi Won't Boot

**Symptoms**: Red LED on, no display

**Solutions**:
1. **Re-flash the image** - May have been corrupted
2. **Try a different SD card** - Card may be faulty
3. **Check SD card compatibility**:
   - Some cards don't work well with Raspberry Pi
   - Try a name-brand card (SanDisk, Samsung, Kingston)
4. **Verify the image file**:
   - Re-download from Codespaces if corrupted
   - Check file size matches expected (~1.5-2GB)

### Windows Shows "You Need to Format the Disk" After Flashing

**This is NORMAL!**

Windows cannot read Linux filesystems. The SD card is properly formatted for Raspberry Pi.

**Solutions**:
- **Click "Cancel"** - Don't format!
- **Safely eject** the SD card
- **Insert into Raspberry Pi** - It will work fine

### Write Protected SD Card

**Symptoms**: "Disk is write protected" error

**Solutions**:
1. **Check the lock switch** on the SD card adapter
   - Slide it to the **unlocked** position (opposite from "LOCK")
2. **Try a different SD card** - Some cards have built-in write protection

## SD Card Recommendations (For Windows 11 Users)

### Recommended Brands
- **SanDisk Ultra** (good performance/price, widely compatible)
- **Samsung EVO** (very reliable)
- **Kingston Canvas Select** (budget-friendly)

### Avoid
- No-name/generic cards (often slower or unreliable)
- Very old cards (may not be compatible with modern Pi models)

### Size Recommendations
- **4GB**: Minimum (tight fit, not recommended)
- **8GB**: Recommended (room for logs, $5-10)
- **16GB+**: Overkill but works fine (often same price as 8GB)

### Speed Class
- **Class 10** or **U1** minimum
- **U3** or **A1** for best performance (faster boot times)

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
- **Windows 11 Help**: https://support.microsoft.com/windows
