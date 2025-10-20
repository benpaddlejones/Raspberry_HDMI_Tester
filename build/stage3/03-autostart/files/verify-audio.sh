#!/bin/bash
# Quick audio verification script for HDMI Tester
# Run this script on the running HDMI Tester to verify audio

echo "=== HDMI Tester Audio Verification ==="
echo ""

# Check if audio file exists
AUDIO_FILE="/opt/hdmi-tester/audio.mp3"
if [ ! -f "$AUDIO_FILE" ]; then
    echo "❌ Audio file not found: $AUDIO_FILE"
    exit 1
fi

echo "✅ Audio file found: $AUDIO_FILE"
echo ""

# Check if audio services are running
echo "🔍 Checking audio service status:"
if systemctl is-active --quiet hdmi-audio.service; then
    echo "✅ hdmi-audio.service is running"
else
    echo "❌ hdmi-audio.service is not running"
    echo "   Status: $(systemctl is-active hdmi-audio.service)"
fi
echo ""

# Check if mpv process is actually running
echo "🔍 Checking for active mpv processes:"
MPV_PROCESSES=$(pgrep -f "mpv.*audio.mp3" | wc -l)
if [ "$MPV_PROCESSES" -gt 0 ]; then
    echo "✅ Found $MPV_PROCESSES mpv process(es) playing audio"
    echo "   Process details:"
    pgrep -f "mpv.*audio.mp3" | while read pid; do
        echo "   PID $pid: $(ps -p $pid -o args --no-headers)"
    done
else
    echo "❌ No mpv processes found playing audio"
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

# Check system logs for audio errors
echo "🔍 Recent audio-related log entries:"
journalctl -u hdmi-audio.service --no-pager -n 10 2>/dev/null || echo "⚠️  Unable to read service logs"
echo ""

# Summary
echo "=== Summary ==="
if [ "$MPV_PROCESSES" -gt 0 ]; then
    echo "🎵 Audio should be playing! If you can't hear it:"
    echo "   1. Check HDMI cable connection"
    echo "   2. Verify display supports audio"
    echo "   3. Check 3.5mm output with headphones"
    echo "   4. Try running: troubleshoot-audio.sh"
else
    echo "🔇 Audio is not currently playing"
    echo "   Try restarting the service: sudo systemctl restart hdmi-audio.service"
fi

echo ""
echo "For detailed troubleshooting, run: troubleshoot-audio.sh"
