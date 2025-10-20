#!/bin/bash
# HDMI Audio Troubleshooting Script
# This script helps diagnose audio issues on the Raspberry Pi

echo "=== HDMI Audio Troubleshooting ==="
echo ""

echo "1. Checking ALSA devices:"
aplay -l || echo "⚠️  aplay command failed"
echo ""

echo "2. Checking ALSA configuration:"
if [ -f /etc/asound.conf ]; then
    cat /etc/asound.conf
else
    echo "⚠️  /etc/asound.conf not found"
fi
echo ""

echo "3. Testing audio playback (5 seconds):"
speaker-test -t sine -f 1000 -c 2 -l 1 || echo "⚠️  speaker-test failed"
echo ""

echo "4. Checking systemd service status:"
systemctl status hdmi-audio.service --no-pager || echo "⚠️  Service status check failed"
echo ""

echo "5. Checking recent service logs:"
journalctl -u hdmi-audio.service -n 50 --no-pager || echo "⚠️  Journal check failed"
echo ""

echo "6. Testing mpv directly:"
if [ -f /opt/hdmi-tester/audio.mp3 ]; then
    timeout 10 mpv --loop=1 --no-video --ao=alsa /opt/hdmi-tester/audio.mp3 || echo "⚠️  mpv playback failed"
else
    echo "❌ /opt/hdmi-tester/audio.mp3 not found!"
fi
echo ""

echo "7. Checking audio file:"
if [ -f /opt/hdmi-tester/audio.mp3 ]; then
    ls -lh /opt/hdmi-tester/audio.mp3
    file /opt/hdmi-tester/audio.mp3
else
    echo "❌ /opt/hdmi-tester/audio.mp3 missing"
fi
echo ""

echo "=== Troubleshooting Complete ==="
