# Video Format Requirements - Pi Model Specific

## Dual-Format System for Hardware Optimization

The HDMI tester uses **different video formats** based on Raspberry Pi model to leverage hardware acceleration:

### Format Selection by Pi Model

**Raspberry Pi 3B and below:**
- **Container**: MP4
- **Video Codec**: H.264 (hardware accelerated decoder)
- **Audio Codec**: AAC
- **Files**: `image-test.mp4`, `color-test.mp4`
- **Why**: Pi 3B has H.264 hardware decoder but NO VP9 hardware support

**Raspberry Pi 4 and above:**
- **Container**: WebM
- **Video Codec**: VP9 (hardware accelerated decoder)
- **Audio Codec**: Opus
- **Files**: `image-test.webm`, `color-test.webm`
- **Why**: Pi 4+ has VP9 hardware decoder for better efficiency

### Required Files

**BOTH formats must be provided** in `build/stage3/01-test-image/files/`:
- `image-test.webm` - Image quality test video (Pi 4+)
- `image-test.mp4` - Image quality test video (Pi 3B and below)
- `color-test.webm` - Color test video (Pi 4+)
- `color-test.mp4` - Color test video (Pi 3B and below)

The build copies **both formats** to the image. At runtime, the test script detects the Pi model and selects the optimal format automatically.

### How Format Selection Works

**Build Time** (`build/stage3/01-test-image/00-run.sh`):
```bash
# Both formats copied to image (NO conversion)
TEST_VIDEOS=("image-test.webm" "color-test.webm" "image-test.mp4" "color-test.mp4")
install -m 644 "files/${video}" "${ROOTFS_DIR}/opt/hdmi-tester/"
```

**Runtime** (`build/stage3/03-autostart/files/hdmi-test`):
```bash
detect_video_format() {
    local model_info=$(cat /proc/cpuinfo | grep "Model" | head -1)

    # Pi 4+ has VP9 hardware support
    if echo "${model_info}" | grep -qE "Raspberry Pi [45678]"; then
        echo "webm"  # Pi 4+ uses WebM
    else
        echo "mp4"   # Pi 3 and earlier uses MP4
    fi
}

VIDEO_FORMAT=$(detect_video_format)
VIDEO_FILE="/opt/hdmi-tester/image-test.${VIDEO_FORMAT}"
```

## Converting Videos to Required Formats

**IMPORTANT**: Assets are **PROVIDED, not converted** during build. You must create BOTH formats before building.

### Creating MP4 (for Pi 3B and below)

```bash
# H.264/AAC MP4 conversion
ffmpeg -i input.mp4 \
  -c:v libx264 -preset medium -crf 23 -b:v 2M \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  output.mp4

# For specific resolution (e.g., 1920x1080)
ffmpeg -i input.mp4 \
  -vf scale=1920:1080 \
  -c:v libx264 -preset medium -crf 23 -b:v 2M \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  output.mp4
```

### Creating WebM (for Pi 4 and above)

```bash
# VP9/Opus WebM conversion (high quality)
ffmpeg -i input.mp4 \
  -c:v libvpx-vp9 -crf 30 -b:v 0 \
  -c:a libopus -b:a 128k \
  output.webm

# Faster conversion (VP8 codec)
ffmpeg -i input.mp4 \
  -c:v libvpx -crf 10 -b:v 1M \
  -c:a libvorbis \
  output.webm

# For specific resolution (e.g., 1920x1080)
ffmpeg -i input.mp4 \
  -vf scale=1920:1080 \
  -c:v libvpx-vp9 -crf 30 -b:v 0 \
  -c:a libopus \
  output.webm
```

### Batch Conversion Example

Create both formats from source:

```bash
SOURCE_VIDEO="source.mp4"

# Create MP4 for Pi 3B
ffmpeg -i "${SOURCE_VIDEO}" \
  -c:v libx264 -preset medium -crf 23 -b:v 2M \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  assets/image-test.mp4

# Create WebM for Pi 4+
ffmpeg -i "${SOURCE_VIDEO}" \
  -c:v libvpx-vp9 -crf 30 -b:v 0 \
  -c:a libopus -b:a 128k \
  assets/image-test.webm
```

### Codec Details

**MP4 Format (Pi 3B and below):**
- **Video**: H.264 (libx264) - Hardware accelerated on all Pi models
- **Audio**: AAC - Universal compatibility
- **Container**: MP4 with faststart flag for streaming

**WebM Format (Pi 4 and above):**
- **Video**: VP9 (libvpx-vp9) - Hardware accelerated on Pi 4+, better compression
- **Video (alternative)**: VP8 (libvpx) - Faster encoding, good compatibility
- **Audio**: Opus (libopus) - Modern, efficient
- **Audio (alternative)**: Vorbis (libvorbis) - Older but universal
- **Container**: WebM (Matroska-based)

### Hardware Acceleration Support

| Pi Model | H.264 Decode | VP9 Decode | Selected Format |
|----------|--------------|------------|-----------------|
| Pi 1, 2, 3, 3B, 3B+ | ✅ Hardware | ❌ Software only (slow) | **MP4** |
| Pi 4, 400, 5 | ✅ Hardware | ✅ Hardware (fast) | **WebM** |
| Pi Zero, Zero W | ✅ Hardware | ❌ Software only (very slow) | **MP4** |

### Required Packages on Raspberry Pi

The build automatically installs codec support for **both formats**:

**H.264/MP4 Support:**
- `libx264-164` - H.264 video decoder
- `ffmpeg` - Media framework

**VP9/WebM Support:**
- `libvpx7` - VP8/VP9 video decoder
- `libvorbis0a` - Vorbis audio decoder
- `libopus0` - Opus audio decoder

**Common:**
- `vlc` - Video player (supports both formats)
- `libavcodec-extra` - Extra codec support

## Why This Dual-Format Approach?

1. **Hardware optimization** - Each Pi uses its native hardware decoder
2. **Performance** - VP9 on Pi 4+ is more efficient than H.264
3. **Compatibility** - H.264 works on ALL Pi models (fallback)
4. **No runtime conversion** - Fast boot, no CPU overhead
5. **Automatic selection** - User doesn't need to choose manually

## Testing

Test video playback on your Pi (auto-selects correct format):

```bash
# Automatic format detection and playback
/opt/hdmi-tester/hdmi-test

# Manual testing - Pi 3B (MP4)
cvlc --loop --vout=drm --aout=alsa /opt/hdmi-tester/image-test.mp4

# Manual testing - Pi 4+ (WebM)
cvlc --loop --vout=drm --aout=alsa /opt/hdmi-tester/image-test.webm
```

Verify format selection in logs:
```bash
tail -f /logs/hdmi-test.log | grep "Video Format"
# Output: Video Format: mp4 (auto-detected)    # On Pi 3B
# Output: Video Format: webm (auto-detected)   # On Pi 4+
```
