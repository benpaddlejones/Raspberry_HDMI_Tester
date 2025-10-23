# Video Format Requirements

## Required Format: WebM

The HDMI tester requires video files in **WebM format** for maximum compatibility with Raspberry Pi hardware.

### Required Files

Place these files in `build/stage3/01-test-image/files/`:
- `image-test.webm` - Image quality test video
- `color_test.webm` - Color test video (fullscreen)

## Converting MP4 to WebM

### Using FFmpeg (Recommended)

```bash
# High quality conversion (VP9 codec)
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus output.webm

# Faster conversion (VP8 codec)
ffmpeg -i input.mp4 -c:v libvpx -crf 10 -b:v 1M -c:a libvorbis output.webm

# For specific resolution (e.g., 1920x1080)
ffmpeg -i input.mp4 -vf scale=1920:1080 -c:v libvpx-vp9 -crf 30 -c:a libopus output.webm
```

### Codec Details

**Video Codecs:**
- VP9 (libvpx-vp9) - Better quality, slower encoding
- VP8 (libvpx) - Faster encoding, good compatibility

**Audio Codecs:**
- Opus (libopus) - Modern, efficient
- Vorbis (libvorbis) - Older but universal

### Required Packages on Raspberry Pi

The build automatically installs:
- `ffmpeg` - Media framework
- `libavcodec-extra` - Extra codec support
- `libvpx7` - VP8/VP9 video decoder
- `libvorbis0a` - Vorbis audio decoder
- `libopus0` - Opus audio decoder
- `mpv` - Video player

## Why WebM?

1. **Open source** - No licensing issues
2. **Better embedded support** - More reliable on ARM/Linux
3. **Software decoding** - Works without GPU acceleration
4. **Smaller file sizes** - More efficient compression
5. **Raspberry Pi optimized** - Native support in Linux kernel

## Testing

Test WebM playback on your current build:

```bash
# Test with verbose output
mpv -v --hwdec=no --vo=drm /opt/hdmi-tester/image-test.webm

# Test with production flags
mpv --loop=inf --no-osd-bar --osd-level=0 \
    --hwdec=no --vo=drm --drm-connector=HDMI-A-1 \
    --cache=yes --demuxer-max-bytes=100M --no-config \
    /opt/hdmi-tester/image-test.webm
```
