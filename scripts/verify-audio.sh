#!/bin/bash
# Quick audio verification script for HDMI Tester
# Run this script on the running HDMI Tester to verify audio

echo "=== HDMI Tester Audio Verification ==="
echo ""

# Check if video files with audio exist
VIDEO_FILE_1="/opt/hdmi-tester/image-test.webm"
VIDEO_FILE_2="/opt/hdmi-tester/color_test.webm"

if [ ! -f "$VIDEO_FILE_1" ]; then
    echo "❌ Video file not found: $VIDEO_FILE_1"
    exit 1
fi

if [ ! -f "$VIDEO_FILE_2" ]; then
    echo "❌ Video file not found: $VIDEO_FILE_2"
    exit 1
fi

echo "✅ Video files found"
echo "   - $VIDEO_FILE_1"
echo "   - $VIDEO_FILE_2"
echo ""

# Check if test services are running
echo "🔍 Checking test service status:"
for service in hd-audio-test.service pixel-audio-test.service full-test.service; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "✅ $service is running"
    fi
done
echo ""

# Check if mpv process is actually running
echo "🔍 Checking for active mpv processes:"
MPV_PROCESSES=$(pgrep -f "mpv.*webm" | wc -l)
if [ "$MPV_PROCESSES" -gt 0 ]; then
    echo "✅ Found $MPV_PROCESSES mpv process(es) playing video/audio"
    echo "   Process details:"
    pgrep -f "mpv.*webm" | while read pid; do
        echo "   PID $pid: $(ps -p $pid -o args --no-headers)"
    done
else
    echo "❌ No mpv processes found playing video"
fi
echo ""

# Check ALSA devices
echo "🔍 Available ALSA audio devices:"
aplay -l 2>/dev/null || echo "❌ Failed to list ALSA devices"
echo ""

# Test HDMI audio device
echo "🔊 Testing HDMI audio device (quick test):"
if timeout 3 aplay -D plughw:0,1 /dev/zero 2>/dev/null; then
    echo "✅ HDMI audio device is responsive"
else
    echo "❌ HDMI audio device test failed"
fi

# Test 3.5mm audio device
echo "🔊 Testing 3.5mm audio device (quick test):"
if timeout 3 aplay -D plughw:0,0 /dev/zero 2>/dev/null; then
    echo "✅ 3.5mm audio device is responsive"
else
    echo "❌ 3.5mm audio device test failed"
fi
echo ""

# Check audio levels
echo "🔍 Current audio mixer settings:"
amixer get Master 2>/dev/null || echo "⚠️  Master volume control not found"
echo ""

# Check system logs for errors
echo "🔍 Recent log entries (if services running):"
for service in hd-audio-test.service pixel-audio-test.service full-test.service; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "Logs for $service:"
        journalctl -u "$service" --no-pager -n 5 2>/dev/null || echo "  Unable to read logs"
    fi
done
echo ""

# Summary
echo "=== Summary ==="
if [ "$MPV_PROCESSES" -gt 0 ]; then
    echo "🎵 Video/Audio should be playing! If you can't hear it:"
    echo "   1. Check HDMI cable connection"
    echo "   2. Verify display supports audio"
    echo "   3. Check 3.5mm output with headphones"
    echo "   4. Check service logs: journalctl -u <service-name>"
else
    echo "🔇 No test videos currently playing"
    echo "   Run manually: test-image-loop, test-color-fullscreen, or test-both-loop"
    echo "   Or enable a service: sudo systemctl start hd-audio-test.service"
fi
