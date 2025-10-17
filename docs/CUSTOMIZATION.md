# Customizing the HDMI Tester

This guide shows you how to customize the Raspberry Pi HDMI Tester in GitHub Codespaces.

## Table of Contents
- [Replacing the Test Pattern](#replacing-the-test-pattern)
- [Replacing the Audio File](#replacing-the-audio-file)
- [Changing HDMI Resolution](#changing-hdmi-resolution)
- [Modifying Boot Behavior](#modifying-boot-behavior)
- [Adding Additional Packages](#adding-additional-packages)
- [Customizing Services](#customizing-services)
- [Advanced Modifications](#advanced-modifications)

## Replacing the Test Pattern

### Requirements
- **Resolution**: 1920x1080 (Full HD) recommended
- **Format**: PNG or JPEG
- **Size**: < 10MB recommended
- **Color**: Any (RGB, RGBA)

### Steps in Codespaces

1. **Upload your image to Codespaces**:
   - Drag and drop your image into the file explorer
   - Or use the upload button in VS Code

2. **Prepare your image** (optional - resize if needed):
   ```bash
   # Resize to 1920x1080 if needed
   convert your-image.png -resize 1920x1080! assets/image.png
   ```

3. **Replace the existing file**:
   ```bash
   cp your-image.png assets/image.png
   ```

4. **Rebuild the image in Codespaces**:
   ```bash
   ./scripts/build-image.sh
   ```

5. **Download the new image**:
   - Navigate to `build/pi-gen-work/deploy/`
   - Download the `.img.zip` file
   - Flash to SD card on Windows 11

## Replacing the Audio File

### Requirements
- **Format**: MP3, WAV, or OGG
- **Duration**: Any (will loop infinitely)
- **Recommended**: Short loops (5-30 seconds) for smaller file size
- **Size**: < 10MB recommended

### Steps in Codespaces

1. **Upload your audio file to Codespaces**:
   - Drag and drop into the file explorer
   - Or use the upload button in VS Code

2. **Prepare your audio** (optional - convert if needed):
   ```bash
   # Convert to MP3 if needed (ffmpeg is available in Codespaces)
   ffmpeg -i your-audio.wav -b:a 96k assets/audio.mp3
   ```

3. **Replace the existing file**:
   ```bash
   cp your-audio.mp3 assets/audio.mp3
   ```

4. **Rebuild the image in Codespaces**:
   ```bash
   ./scripts/build-image.sh
   ```

5. **Download and flash** the new image

### Audio Recommendations

**For testing purposes**:
- 1kHz sine wave (tests audio output)
- Frequency sweep (tests full range)
- Pink noise (tests speakers)

**For demo purposes**:
- Music loops
- Spoken announcements
- Brand jingles

## Changing HDMI Resolution

### Supported Resolutions

The Pi supports many CEA and DMT modes. Common ones:

| Mode | Resolution | Refresh | Type |
|------|------------|---------|------|
| CEA 4 | 1280x720 | 60Hz | HDTV 720p |
| CEA 16 | 1920x1080 | 60Hz | HDTV 1080p60 |
| CEA 31 | 1920x1080 | 50Hz | HDTV 1080p50 |
| CEA 34 | 1920x1080 | 30Hz | HDTV 1080p30 |
| DMT 82 | 1920x1080 | 60Hz | Monitor |

### Change Resolution (Before Building)

Edit `build/stage-custom/04-boot-config/00-run.sh`:

```bash
# For 720p @ 60Hz
hdmi_group=1
hdmi_mode=4

# For 1080p @ 50Hz
hdmi_group=1
hdmi_mode=31

# For monitor mode (DMT)
hdmi_group=2
hdmi_mode=82
```

Then rebuild:
```bash
./scripts/build-image.sh
```

### Change Resolution (After Building)

1. **Mount SD card** boot partition
2. **Edit** `config.txt` or `firmware/config.txt`
3. **Modify** these lines:
   ```
   hdmi_group=1
   hdmi_mode=16
   ```
4. **Save** and unmount
5. **Boot** Raspberry Pi

### Finding Your Mode

To list all available modes:
```bash
# On a running Raspberry Pi
tvservice -m CEA  # List CEA modes (TVs)
tvservice -m DMT  # List DMT modes (Monitors)
```

## Modifying Boot Behavior

### Change Boot Delay

Edit `build/stage-custom/04-boot-config/00-run.sh`:

```bash
# Faster boot (no delay)
boot_delay=0

# Slower boot (wait for display)
boot_delay=1
```

### Disable Auto-Login

Edit `build/stage-custom/03-autostart/00-run.sh` and remove or comment out:

```bash
# Configure auto-login for user pi
# mkdir -p "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
# cat > "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/autologin.conf" << EOF
# ...
```

### Disable Auto-Start X11

Edit `build/stage-custom/03-autostart/00-run.sh` and remove:

```bash
# Auto-start X on login
# cat >> "${ROOTFS_DIR}/home/pi/.bashrc" << 'EOF'
# ...
```

## Adding Additional Packages

### Add Packages to Build

Edit `build/stage-custom/00-install-packages/00-packages`:

```
xserver-xorg
xinit
feh
mpv
alsa-utils
pulseaudio
your-package-here
another-package
```

Rebuild:
```bash
./scripts/build-image.sh
```

### Install Packages on Running System

If you need to access the Pi:

1. **Connect keyboard** to Pi
2. **Press** Ctrl+Alt+F2 (switch to console)
3. **Login** as `pi` / `raspberry`
4. **Install**:
   ```bash
   sudo apt update
   sudo apt install package-name
   ```

## Customizing Services

### Modify Display Service

Edit `build/stage-custom/03-autostart/files/hdmi-display.service`:

```ini
[Service]
# Change delay before starting
ExecStartPre=/bin/sleep 5    # Change this number

# Use different viewer
ExecStart=/usr/bin/eog --fullscreen /opt/hdmi-tester/test-pattern.png

# Add options
ExecStart=/usr/bin/feh --fullscreen --hide-pointer --slideshow-delay 5 /path/to/images/
```

### Modify Audio Service

Edit `build/stage-custom/03-autostart/files/hdmi-audio.service`:

```ini
[Service]
# Change audio device
ExecStart=/usr/bin/mpv --loop=inf --no-video --audio-device=pulse /opt/hdmi-tester/test-audio.mp3

# Adjust volume
ExecStartPre=/usr/bin/amixer set Master 80%

# Play once (no loop)
ExecStart=/usr/bin/mpv --no-video /opt/hdmi-tester/test-audio.mp3
```

### Add New Service

1. **Create service file** in `build/stage-custom/03-autostart/files/`:
   ```ini
   [Unit]
   Description=My Custom Service
   After=network.target

   [Service]
   Type=simple
   User=pi
   ExecStart=/path/to/your/script.sh
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

2. **Install in** `build/stage-custom/03-autostart/00-run.sh`:
   ```bash
   install -m 644 files/my-service.service "${ROOTFS_DIR}/etc/systemd/system/"
   on_chroot << EOF
   systemctl enable my-service.service
   EOF
   ```

3. **Rebuild** the image

## Advanced Modifications

### Change Hostname

Edit `build/config`:
```bash
TARGET_HOSTNAME="my-custom-name"
```

### Change Default Password

Edit `build/config`:
```bash
FIRST_USER_PASS="newsecurepassword"
```

### Enable SSH

Edit `build/config`:
```bash
ENABLE_SSH=1
```

**Warning**: If enabling SSH, change the default password!

### Add WiFi Credentials

Create `build/stage-custom/05-wifi/00-run.sh`:

```bash
#!/bin/bash -e
# Configure WiFi

cat > "${ROOTFS_DIR}/etc/wpa_supplicant/wpa_supplicant.conf" << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="YourNetworkName"
    psk="YourPassword"
}
EOF

chmod 600 "${ROOTFS_DIR}/etc/wpa_supplicant/wpa_supplicant.conf"
```

### GPU Memory Allocation

Edit `build/stage-custom/04-boot-config/00-run.sh`:

```bash
# Default (sufficient for 1080p)
gpu_mem=128

# For 4K or heavy graphics
gpu_mem=256

# Minimal (if not using display)
gpu_mem=64
```

### Overscan/Underscan

If image doesn't fit screen, edit `build/stage-custom/04-boot-config/00-run.sh`:

```bash
# Disable overscan compensation
disable_overscan=1

# Or adjust manually
overscan_left=16
overscan_right=16
overscan_top=16
overscan_bottom=16
```

## Testing Customizations

Always test after customization:

1. **Build** the image
2. **Validate**:
   ```bash
   sudo ./tests/validate-image.sh build/pi-gen-work/deploy/*.img
   ```
3. **Flash** to SD card
4. **Test** on actual hardware

## Reverting Changes

To start fresh:

```bash
# Revert to clean repository state
git reset --hard origin/main

# Remove build artifacts
sudo rm -rf build/pi-gen-work

# Rebuild
./scripts/build-image.sh
```

## Best Practices

1. **Test incrementally** - Make one change at a time
2. **Keep backups** - Save working configurations
3. **Document changes** - Note what you modified
4. **Use version control** - Commit working states
5. **Validate builds** - Always run validate-image.sh

## Getting Help

- **Raspberry Pi Config**: https://www.raspberrypi.com/documentation/computers/config_txt.html
- **systemd Services**: `man systemd.service`
- **GitHub Issues**: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
- **Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
