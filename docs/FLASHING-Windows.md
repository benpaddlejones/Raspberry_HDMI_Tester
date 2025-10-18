# Flashing on Windows

This guide shows you how to flash the Raspberry Pi HDMI Tester image to an SD card on **Windows 10/11**.

## Prerequisites

### What You Need
- **Downloaded Image**: `RaspberryPi_HDMI_Tester.img.zip` from [GitHub Releases](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/releases)
- **SD Card**: 4GB minimum, 8GB+ recommended
- **SD Card Reader**: USB or built-in
- **Extraction Tool**: Windows 11 (built-in), 7-Zip, or WinRAR

### Step 1: Extract the Image

1. **Locate the downloaded ZIP file** (usually in `Downloads` folder)
2. **Right-click** on `RaspberryPi_HDMI_Tester.img.zip`
3. Select **"Extract All..."**
4. Choose a destination folder
5. Click **"Extract"**
6. You should now have a `.img` file

## Method 1: Raspberry Pi Imager (Recommended)

### Installation

1. **Download Raspberry Pi Imager**:
   - Visit: https://www.raspberrypi.com/software/
   - Click **"Download for Windows"**
   - Run `imager_latest.exe`

2. **Install the application**:
   - Follow the installation wizard
   - Launch **Raspberry Pi Imager**

### Flashing the Image

1. **Insert your SD card** into the card reader
2. **Open Raspberry Pi Imager**
3. Click **"Choose OS"** → Scroll down → **"Use custom"**
4. **Browse** to your extracted `.img` file and select it
5. Click **"Choose Storage"** → Select your SD card
   - ⚠️ **Verify the drive letter and size match your SD card!**
6. Click **"Write"**
7. Click **"Yes"** to confirm (all data will be erased)
8. **Wait for the process to complete** (5-10 minutes)
   - Writing image...
   - Verifying...
9. Click **"Continue"** when you see **"Write Successful"**
10. **Close** Raspberry Pi Imager

### Safely Remove SD Card

1. Click the **system tray** (bottom-right corner)
2. Click the **USB icon** → Select your SD card → **"Eject"**
3. Wait for **"Safe to Remove Hardware"** notification
4. **Remove the SD card**

## Method 2: Balena Etcher

### Installation

1. **Download Balena Etcher**:
   - Visit: https://www.balena.io/etcher/
   - Click **"Download for Windows"**
   - Run `balenaEtcher-Setup-x.x.x.exe`

2. **Install the application**:
   - Follow the installation wizard
   - Launch **balenaEtcher**

### Flashing the Image

1. **Insert your SD card** into the card reader
2. **Open balenaEtcher**
3. Click **"Flash from file"**
4. **Browse** to your extracted `.img` file and select it
5. Click **"Select target"**
6. **Choose your SD card** from the list
   - ⚠️ **Double-check the drive letter and size!**
7. Click **"Flash!"**
8. Click **"Yes"** when User Account Control prompts for permission
9. **Wait for the process to complete** (5-10 minutes)
   - Flashing...
   - Validating...
10. Click **"Flash another"** or close when done

### Safely Remove SD Card

1. **Close** balenaEtcher
2. **Right-click** the SD card drive in **File Explorer**
3. Select **"Eject"**
4. **Remove the SD card**

## Method 3: Win32 Disk Imager (Classic)

### Installation

1. **Download Win32 Disk Imager**:
   - Visit: https://sourceforge.net/projects/win32diskimager/
   - Download the latest version
   - **Extract the ZIP** file

2. **Run as Administrator**:
   - Right-click **Win32DiskImager.exe**
   - Select **"Run as administrator"**

### Flashing the Image

1. **Insert your SD card** into the card reader
2. Click the **blue folder icon** → Browse to your `.img` file
3. Select your **SD card drive letter** from the dropdown (e.g., E:, F:)
   - ⚠️ **Verify this is your SD card, not your main hard drive!**
4. Click **"Write"**
5. Click **"Yes"** to confirm
6. **Wait for completion** (5-15 minutes)
7. Click **"OK"** when you see **"Write Successful"**
8. Click **"Exit"**

### Safely Remove SD Card

1. **Right-click** the SD card in **File Explorer**
2. Select **"Eject"**
3. **Remove the SD card**

## Using the Flashed SD Card

1. **Remove SD card** from your Windows PC
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

**Problem**: Windows doesn't show the SD card

**Solutions**:
1. **Try a different USB port** (use USB 3.0 if available)
2. **Check Disk Management**:
   - Press `Win + X` → **"Disk Management"**
   - Look for your SD card (check the size)
   - If it shows, note the drive letter
3. **Try a different card reader**
4. **Restart your computer** with the SD card inserted

### "You Need to Format the Disk" Message

**Problem**: Windows shows this popup after flashing

**This is NORMAL!** Windows cannot read Linux filesystems.

**Solution**:
- ⚠️ **Click "Cancel"** - Do NOT format!
- The SD card is correctly formatted for Raspberry Pi
- Simply eject and use it

### Write Protected SD Card

**Problem**: "The disk is write-protected" error

**Solutions**:
1. **Check the physical lock switch** on the SD card adapter:
   - Slide it to the **unlocked position** (away from "LOCK")
2. **Try removing and reinserting** the card
3. **Try a different SD card** (some have permanent write protection)

### "Access Denied" or "Permission Error"

**Problem**: Can't write to the SD card

**Solutions**:
1. **Run the application as Administrator**:
   - Right-click the program
   - Select **"Run as administrator"**
2. **Close any File Explorer windows** showing the SD card
3. **Close any applications** that might be accessing the SD card
4. **Disable antivirus temporarily** (may block disk writes)

### "Not Enough Space" Error

**Problem**: Image won't fit on SD card

**Cause**: SD card is too small (< 4GB)

**Solution**: Use a 4GB or larger SD card

### Flash Completes But Pi Won't Boot

**Problem**: Only red LED, no display

**Solutions**:
1. **Re-flash the image** (may have been corrupted):
   - Delete the extracted `.img` file
   - Re-extract from the ZIP file
   - Flash again
2. **Try a different SD card**:
   - Some cards are incompatible with Raspberry Pi
   - Use a branded card (SanDisk, Samsung, Kingston)
3. **Check SD card speed class**:
   - Should be **Class 10** or higher
   - **U1** or **A1** rating recommended
4. **Verify the image file**:
   - Check file size (should be ~1.5-2GB)
   - Re-download if corrupt

### Very Slow Flashing Speed

**Problem**: Taking more than 20 minutes

**Solutions**:
1. **Use a USB 3.0 port** (blue port, not black)
2. **Try a faster SD card** (Class 10, U3, or A1)
3. **Close other applications** to free up system resources
4. **Be patient** - cheap/slow cards can take longer

### Raspberry Pi Imager Crashes

**Problem**: Application closes unexpectedly

**Solutions**:
1. **Update Raspberry Pi Imager** to the latest version
2. **Run as Administrator**
3. **Disable antivirus temporarily**
4. **Try Balena Etcher instead** (alternative tool)

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

## Additional Help

- **Can't find the image file?** Check your `Downloads` folder
- **Still having issues?** See main [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Need to customize?** See [CUSTOMIZATION.md](CUSTOMIZATION.md)
- **Want to build from source?** See [DEVELOPMENT.md](DEVELOPMENT.md)

## Next Steps

Once you've successfully flashed the SD card:

1. Insert into Raspberry Pi
2. Connect HDMI to display
3. Power on and enjoy!

For customization options, see [CUSTOMIZATION.md](CUSTOMIZATION.md).
