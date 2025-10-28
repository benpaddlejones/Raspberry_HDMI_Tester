# Audio Diagnostic Test Suite

## Purpose
Comprehensive audio testing script to diagnose HDMI audio issues on Raspberry Pi.
Each test runs ONCE only - if the system crashes, the test will not repeat.

## Setup Instructions

### 1. Prepare USB Drive
```bash
# Copy this entire folder to the root of your USB drive
# Your USB should look like:
# /media/usb/
# ├── audio-diagnostic-test.sh
# └── audio-test-results/  (will be created automatically)
```

### 2. Mount USB on Raspberry Pi
```bash
# Find your USB device
lsblk

# Mount it (replace sdX1 with your device)
sudo mkdir -p /mnt/usb
sudo mount /dev/sda1 /mnt/usb

# Verify it's mounted
ls /mnt/usb
```

### 3. Run the Test
```bash
# Navigate to the mounted USB
cd /mnt/usb

# Make script executable
chmod +x audio-diagnostic-test.sh

# Run as root/sudo (REQUIRED)
sudo ./audio-diagnostic-test.sh
```

## What the Script Does

### Automatic Discovery
- Detects all audio cards on the system automatically
- Uses system-returned information (not hardcoded card names)
- Tests each discovered device comprehensively

### Test Types (per audio device)
1. **Test 1-3**: `aplay` tests with different device methods
   - plughw (with format conversion)
   - hw (direct hardware)
   - dmix (software mixing)

2. **Test 4-5**: VLC with MP4 video file
   - plughw and hw configurations
   - Tests video + audio playback

3. **Test 6-7**: VLC with FLAC audio files
   - Stereo (2.0) FLAC
   - 5.1 Surround FLAC

4. **Test 8**: speaker-test utility
   - Pink noise test tone generation

### Each Test Runs for 10 Seconds
- Tests timeout automatically
- If system crashes, test is marked as incomplete
- Progress is saved - script won't repeat completed tests

## Results

All results are saved to: `/mnt/usb/audio-test-results/`

### Files Created
- `test-results-YYYY-MM-DD_HH-MM-SS.txt` - Summary of all tests
- `full-diagnostic-YYYY-MM-DD_HH-MM-SS.log` - Complete detailed log
- `.test-progress` - Progress tracking (hidden file)

### Result Interpretation

For each test, you'll see one of these results:
- **COMPLETED**: Test ran without crashing
- **CRASHED**: System or application crashed (exit code shown)
- **TIMEOUT**: Test timed out normally (expected behavior)

### Your Feedback
After running the script, review the results file and report:
```
Test1: no sound / sound heard / system crashed
Test2: no sound / sound heard / system crashed
Test3: sound heard
Test4: system crashed
...etc
```

## Diagnostic Information Collected

The full log includes:
- Raspberry Pi model
- Kernel version
- ALSA version
- All detected audio cards and devices
- Full aplay -l output
- PCM device information
- Mixer settings for all cards
- Hardware parameters (if available)
- Kernel messages (dmesg audio-related)
- Loaded audio modules

## Troubleshooting

### Script Won't Run
```bash
# Ensure it's executable
chmod +x audio-diagnostic-test.sh

# Run with sudo
sudo ./audio-diagnostic-test.sh
```

### USB Not Mounting
```bash
# Check if USB is detected
lsblk
dmesg | tail -20

# Try different mount point
sudo mount /dev/sda1 /mnt/usb -t vfat
```

### Tests Keep Repeating
The script should never repeat tests. If this happens, delete the progress file:
```bash
rm /mnt/usb/audio-test-results/.test-progress
```

### No Test Files Found
Ensure these files exist on your Raspberry Pi:
- `/opt/hdmi-tester/image-test.mp4`
- `/opt/hdmi-tester/stereo.flac`
- `/opt/hdmi-tester/surround51.flac`
- `/usr/share/sounds/alsa/Front_Center.wav`

## Unmounting USB After Tests

```bash
# Sync to ensure all data is written
sync

# Unmount
sudo umount /mnt/usb

# You can now safely remove the USB drive
```

## Example Output

```
Test1: aplay plughw:2,0 WAV
  Result: COMPLETED
  Details: Test completed without crash

Test2: aplay hw:2,0 WAV
  Result: CRASHED
  Details: Exit code: 1

Test3: aplay dmix:CARD=2,DEV=0 WAV
  Result: TIMEOUT
  Details: Test timed out (normal)
```

Then you report which tests actually produced sound on your speakers/TV.
