# HDMI Tester - Manual Testing Mode

## Overview

The image now boots to a terminal with three test commands available for manual execution. This allows you to test each component individually before enabling automatic startup.

## What Changed

### ✅ Installed Components
1. **Test Scripts** (in `/usr/local/bin/`, available in PATH):
   - `hdmi-image` - Display test pattern on framebuffer
   - `hdmi-audio` - Play audio with comprehensive debugging
   - `hdmi-test` - Integration test (runs both)

2. **Auto-login**: User `pi` automatically logs in to terminal
3. **Welcome Message**: Instructions displayed on login
4. **Systemd Services**: Installed but NOT enabled (for future use)

### ❌ Disabled Components
- Automatic test execution on boot (services not enabled)
- No X11/Wayland (using framebuffer directly)

## Testing Workflow

### Test 1: Image Display
```bash
sudo hdmi-image
```

**Expected Output:**
- ✓ Checks for test pattern file
- ✓ Checks framebuffer device
- ✓ Displays image on screen
- Stays running until Ctrl+C

**If it fails:**
- Check `/opt/hdmi-tester/image.png` exists
- Check `/dev/fb0` exists
- Check you're running as root (sudo)

### Test 2: Audio Playback
```bash
hdmi-audio
```

**Expected Output:**
- ✓ Lists all available audio devices
- ✓ Detects HDMI audio (if available)
- ✓ Shows device selection logic
- ✓ Attempts playback with debugging info
- Loops forever until Ctrl+C

**If it fails:**
- Output shows detailed device detection
- Shows which device was attempted
- Shows fallback attempts
- All output visible in terminal for debugging

### Test 3: Integration Test
```bash
sudo hdmi-test
```

**Expected Output:**
- ✓ Starts image display in background
- ✓ Starts audio playback in background
- ✓ Shows PIDs of both processes
- ✓ Logs to `/tmp/hdmi-image.log` and `/tmp/hdmi-audio.log`
- Both run until Ctrl+C

**This is what will run in the final automatic solution.**

## Troubleshooting

### View logs from integration test:
```bash
tail -f /tmp/hdmi-image.log
tail -f /tmp/hdmi-audio.log
```

### Check if test files exist:
```bash
ls -lh /opt/hdmi-tester/
```

### Check framebuffer:
```bash
ls -la /dev/fb*
fbset -s
```

### Check audio devices:
```bash
aplay -l
aplay -L
```

### Test audio manually with speaker-test:
```bash
speaker-test -t sine -f 1000 -c 2
```

## Next Steps: Enabling Automatic Startup

Once manual testing confirms everything works:

1. **Enable services:**
   ```bash
   sudo systemctl enable hdmi-display.service
   sudo systemctl enable hdmi-audio.service
   sudo systemctl start hdmi-display.service
   sudo systemctl start hdmi-audio.service
   ```

2. **Check service status:**
   ```bash
   sudo systemctl status hdmi-display.service
   sudo systemctl status hdmi-audio.service
   ```

3. **View service logs:**
   ```bash
   sudo journalctl -u hdmi-display.service -f
   sudo journalctl -u hdmi-audio.service -f
   ```

4. **Reboot to test automatic startup:**
   ```bash
   sudo reboot
   ```

## File Locations

- Test scripts: `/usr/local/bin/hdmi-{image,audio,test}`
- Test assets: `/opt/hdmi-tester/{image.png,audio.mp3}`
- Service files: `/etc/systemd/system/hdmi-{display,audio}.service`
- Integration logs: `/tmp/hdmi-{image,audio}.log`

## Build Commands

To rebuild the image with these changes:
```bash
cd /workspaces/Raspberry_HDMI_Tester
./scripts/build-image.sh
```

The build will:
1. Install packages (fbi, mpv, alsa-utils)
2. Copy test assets to /opt/hdmi-tester/
3. Install test scripts to /usr/local/bin/
4. Configure auto-login
5. Create welcome message
6. NOT enable automatic startup (manual testing mode)
