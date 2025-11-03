# Flashing the HDMI Tester Image to SD Card

This guide helps you flash the Raspberry Pi HDMI Tester image to an SD card.

**🚀 [Jump to Quick Start](#universal-method-raspberry-pi-imager-recommended)** - Start flashing immediately with Raspberry Pi Imager

---

## Choose Your Operating System

For detailed, platform-specific instructions with troubleshooting, select your operating system:

### 🪟 [Windows 10/11 Flashing Guide](FLASHING-Windows.md)
Complete guide for Windows users including:
- Raspberry Pi Imager (recommended)
- Balena Etcher
- Win32 Disk Imager
- Windows-specific troubleshooting

### 🍎 [macOS Flashing Guide](FLASHING-macOS.md)
Complete guide for macOS users including:
- Raspberry Pi Imager (recommended)
- Balena Etcher
- Command line (dd)
- macOS-specific troubleshooting

### 🐧 [Linux Flashing Guide](FLASHING-Linux.md)
Complete guide for Linux users including:
- Raspberry Pi Imager (recommended)
- Balena Etcher
- Command line (dd)
- GNOME Disks
- Linux-specific troubleshooting

---

## Quick Start (All Platforms)

### Prerequisites

- **Downloaded Image**: `RPi_HDMI_Tester_PiOS.img.zip` from [Releases](https://github.com/benpaddlejones/Raspberry_HDMI_Tester/releases)
- **SD Card**: 4GB minimum, 8GB+ recommended
- **SD Card Reader**: USB or built-in
- **Flashing Tool**: Raspberry Pi Imager (recommended)

⚠️ **Warning**: All data on the SD card will be erased!

## Universal Method: Raspberry Pi Imager (Recommended)

This method works on **Windows, macOS, and Linux**.

### Step 1: Download and Install

Visit https://www.raspberrypi.com/software/ and download Raspberry Pi Imager for your operating system.

**Installation**:
- **Windows**: Run the `.exe` installer
- **macOS**: Open the `.dmg` and drag to Applications
- **Linux**: Use your package manager (`apt install rpi-imager`) or download from the website

### Step 2: Extract the Image

1. Locate `RPi_HDMI_Tester_PiOS.img.zip` in your Downloads folder
2. Extract the `.img` file:
   - **Windows**: Right-click → "Extract All"
   - **macOS**: Double-click the ZIP file
   - **Linux**: `unzip RPi_HDMI_Tester_PiOS.img.zip`

### Step 3: Flash the Image

1. **Insert your SD card** into the card reader
2. **Open Raspberry Pi Imager**
3. Click **"Choose OS"**
4. Scroll down and select **"Use custom"**
5. **Browse** to your extracted `.img` file
6. Click **"Choose Storage"**
7. **Select your SD card** (verify the size matches!)
8. Click **"Write"**
9. **Confirm** when prompted (all data will be erased)
10. **Wait** for the process to complete (5-10 minutes)
11. Click **"Continue"** when finished

### Step 4: Use the SD Card

1. **Safely eject** the SD card
2. **Insert** into Raspberry Pi
3. **Connect HDMI** to display
4. **Power on** the Pi
5. **Wait ~30 seconds** for boot

## What Next?

- ✅ **Test pattern should appear** at 1920x1080
- ✅ **Audio should play** through HDMI continuously
- ❌ **Not working?** See the [Troubleshooting Guide](TROUBLESHOOTING.md)
- 🎨 **Want to customize?** See the [Customization Guide](CUSTOMIZATION.md)

## Platform-Specific Instructions

For more detailed instructions and platform-specific troubleshooting:

- **[Windows Guide](FLASHING-Windows.md)** - Includes Win32 Disk Imager, Balena Etcher
- **[macOS Guide](FLASHING-macOS.md)** - Includes command line (dd) method
- **[Linux Guide](FLASHING-Linux.md)** - Includes dd, GNOME Disks, and more

## Common Issues (All Platforms)

### "You need to format the disk" / "Disk not ejected properly"

**This is NORMAL!** Your computer cannot read Linux filesystems and will show warnings after flashing.

**Solution**: Ignore the message and safely eject the SD card. It's correctly formatted for Raspberry Pi.

### SD Card Not Detected

**Solutions**:
1. Try a different USB port (prefer USB 3.0)
2. Try a different SD card reader
3. Check if your SD card is working properly
4. Restart your computer with the SD card inserted

### Flashing Takes Too Long

**Normal time**: 5-10 minutes for most cards

**If longer**:
1. Use a USB 3.0 port (blue port, not black)
2. Use a faster SD card (Class 10 or higher)
3. Close other applications
4. Be patient - slower cards take longer

### Pi Won't Boot After Flashing

**Solutions**:
1. **Re-flash the image** - May have been corrupted
2. **Try a different SD card** - Some cards are incompatible
3. **Use a quality card** - SanDisk, Samsung, or Kingston
4. **Check power supply** - Insufficient power can prevent boot

## SD Card Recommendations

### Recommended Brands
- ✅ SanDisk Ultra
- ✅ Samsung EVO/EVO Plus
- ✅ Kingston Canvas Select

### Recommended Size
- **4GB** - Minimum (not recommended)
- **8GB** - Recommended ($5-10)
- **16GB+** - Works fine, room for logs

### Speed Class
- **Minimum**: Class 10
- **Better**: U1 (UHS-I)
- **Best**: U3 or A1 (faster boot)

### Avoid
- ❌ No-name/generic brands
- ❌ Cards slower than Class 10
- ❌ Very old cards (5+ years)

## Additional Help

- **Detailed platform guides**: See links at top of this page
- **Build your own image**: See [DEVELOPMENT.md](DEVELOPMENT.md)
- **Customize the image**: See [CUSTOMIZATION.md](CUSTOMIZATION.md)
- **Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

