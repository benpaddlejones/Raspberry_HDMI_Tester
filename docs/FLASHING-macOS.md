# Flashing on macOS

This guide shows you how to flash the Raspberry Pi HDMI Tester image to an SD card on **macOS**.

## Prerequisites

### What You Need
- **Downloaded Image**: `RaspberryPi_HDMI_Tester.img.zip` from [GitHub Releases](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/releases)
- **SD Card**: 4GB minimum, 8GB+ recommended
- **SD Card Reader**: USB or built-in (MacBook Pro/Air have built-in readers)
- **macOS**: Version 10.13 (High Sierra) or later

### Step 1: Extract the Image

1. **Locate the downloaded ZIP file** (usually in `Downloads` folder)
2. **Double-click** `RaspberryPi_HDMI_Tester.img.zip`
3. macOS will automatically extract the `.img` file
4. You should now have a `.img` file in the same folder

## Method 1: Raspberry Pi Imager (Recommended)

### Installation

1. **Download Raspberry Pi Imager**:
   - Visit: https://www.raspberrypi.com/software/
   - Click **"Download for macOS"**
   - Open the downloaded `.dmg` file

2. **Install the application**:
   - Drag **Raspberry Pi Imager** to **Applications** folder
   - Open from **Applications** folder
   - Click **"Open"** if macOS warns about unsigned developer

### Flashing the Image

1. **Insert your SD card** into the card reader
2. **Open Raspberry Pi Imager** from Applications
3. Click **"Choose OS"** → Scroll down → **"Use custom"**
4. **Navigate** to your extracted `.img` file and select it
5. Click **"Choose Storage"** → Select your SD card
   - ⚠️ **Verify the device name and size match your SD card!**
6. Click **"Write"**
7. **Enter your Mac password** when prompted (required for disk operations)
8. Click **"Yes"** to confirm (all data will be erased)
9. **Wait for the process to complete** (5-10 minutes)
   - Writing image...
   - Verifying...
10. Click **"Continue"** when you see **"Write Successful"**
11. **Close** Raspberry Pi Imager

### Safely Remove SD Card

1. **Eject the SD card**:
   - Right-click the SD card icon on Desktop → **"Eject"**
   - Or drag the SD card icon to Trash
   - Or use `diskutil eject /dev/diskN` in Terminal
2. Wait for the icon to disappear
3. **Remove the SD card**

## Method 2: Balena Etcher

### Installation

1. **Download Balena Etcher**:
   - Visit: https://www.balena.io/etcher/
   - Click **"Download for macOS"**
   - Open the downloaded `.dmg` file

2. **Install the application**:
   - Drag **balenaEtcher** to **Applications** folder
   - Open from **Applications** folder
   - Click **"Open"** if macOS warns about unsigned developer

### Flashing the Image

1. **Insert your SD card** into the card reader
2. **Open balenaEtcher** from Applications
3. Click **"Flash from file"**
4. **Navigate** to your extracted `.img` file and select it
5. Click **"Select target"**
6. **Choose your SD card** from the list
   - ⚠️ **Double-check the device name and size!**
7. Click **"Flash!"**
8. **Enter your Mac password** when prompted
9. **Wait for the process to complete** (5-10 minutes)
   - Flashing...
   - Validating...
10. Click **"Flash another"** or close when done

### Safely Remove SD Card

1. **Right-click** the SD card on Desktop → **"Eject"**
2. Wait for the icon to disappear
3. **Remove the SD card**

## Method 3: Command Line (dd)

⚠️ **Advanced users only!** This method can destroy data if you select the wrong disk.

### Find Your SD Card

1. **Open Terminal** (Applications → Utilities → Terminal)
2. **Before inserting SD card**, run:
   ```bash
   diskutil list
   ```
3. **Note the existing disks**
4. **Insert your SD card**
5. **Run again**:
   ```bash
   diskutil list
   ```
6. **Identify your SD card** (look for the size that matches):
   - Example: `/dev/disk2` (8GB card)
   - ⚠️ **Do NOT use disk0** (that's your Mac's hard drive!)

### Unmount the SD Card

```bash
diskutil unmountDisk /dev/diskN
```
Replace `N` with your disk number (e.g., `disk2`)

### Flash the Image

1. **Navigate to the image location**:
   ```bash
   cd ~/Downloads
   ```

2. **Flash the image** (this will take 5-15 minutes):
   ```bash
   sudo dd if=RaspberryPi_HDMI_Tester.img of=/dev/rdiskN bs=1m
   ```

   **Important**:
   - Replace `N` with your disk number
   - Use `/dev/rdisk` (with 'r') for faster writing
   - You'll need to enter your Mac password
   - **No progress indicator** - be patient!

3. **Wait for completion**:
   - Terminal will show statistics when done
   - Can take 5-15 minutes with no feedback

4. **Sync the disk**:
   ```bash
   sudo sync
   ```

### Alternative: View Progress

To see progress while flashing, use a different terminal window:

```bash
# In a new Terminal window, find the dd process
sudo pkill -INFO dd
```

This will make `dd` print progress statistics.

### Safely Remove SD Card

```bash
diskutil eject /dev/diskN
```

Replace `N` with your disk number.

## Using the Flashed SD Card

1. **Remove SD card** from your Mac
2. **Insert into Raspberry Pi** SD card slot
3. **Connect HDMI cable** to your display
4. **Connect power supply** to the Pi
5. **Wait 20-30 seconds** for boot

### Expected Behavior

- ✅ **Green LED** blinks (activity)
- ✅ **Test pattern** appears on display (1920x1080)
- ✅ **Audio** plays through HDMI continuously

## Troubleshooting

### "Disk Not Ejected Properly" Warning

**Problem**: macOS shows this warning after flashing

**This is NORMAL!** macOS cannot read Linux filesystems and ejects the volumes automatically.

**Solution**:
- **Ignore the warning**
- The SD card is correctly formatted for Raspberry Pi
- Simply remove the card physically

### SD Card Not Detected

**Problem**: macOS doesn't show the SD card

**Solutions**:
1. **Try a different USB port**
2. **Check System Information**:
   - Click  → **About This Mac** → **System Report**
   - Click **Card Reader** or **USB**
   - Look for your SD card
3. **Try a different card reader**
4. **Restart your Mac** with the SD card inserted
5. **Check for macOS updates** (may fix driver issues)

### "Resource Busy" Error

**Problem**: Can't unmount the SD card

**Solutions**:
1. **Close all Finder windows** showing the SD card
2. **Quit any applications** that might be accessing it
3. **Force unmount**:
   ```bash
   diskutil unmountDisk force /dev/diskN
   ```
4. **Check what's using the disk**:
   ```bash
   sudo lsof | grep diskN
   ```

### "Permission Denied" Error

**Problem**: dd command fails with permission error

**Solutions**:
1. **Use sudo** with the dd command
2. **Enter your Mac password** when prompted
3. **Ensure you have admin rights** on your Mac

### "No Space Left on Device" Error

**Problem**: Image won't fit on SD card

**Cause**: SD card is too small (< 4GB)

**Solution**: Use a 4GB or larger SD card

### dd Command Appears Frozen

**Problem**: No output from dd command

**This is NORMAL!** The dd command doesn't show progress by default.

**Solutions**:
1. **Be patient** - it can take 5-15 minutes
2. **Check progress** from another Terminal window:
   ```bash
   sudo pkill -INFO dd
   ```
3. **Wait for completion** - Terminal will show stats when done

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

### Raspberry Pi Imager Won't Open

**Problem**: "App can't be opened because it is from an unidentified developer"

**Solutions**:
1. **Right-click** the app → **"Open"** → **"Open"** again
2. Or: System Preferences → **Security & Privacy** → Click **"Open Anyway"**
3. Or: Remove the quarantine attribute:
   ```bash
   xattr -d com.apple.quarantine /Applications/Raspberry\ Pi\ Imager.app
   ```

### Very Slow Flashing Speed

**Problem**: Taking more than 20 minutes

**Solutions**:
1. **Use `/dev/rdisk` instead of `/dev/disk`** (much faster)
2. **Use a faster SD card** (Class 10, U3, or A1)
3. **Close other applications** to free up system resources
4. **Try a USB 3.0 port** if available

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
