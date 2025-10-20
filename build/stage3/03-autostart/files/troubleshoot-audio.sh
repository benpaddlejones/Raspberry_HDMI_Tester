#!/bin/bash
# HDMI Audio Troubleshooting Script
# This script helps diagnose audio issues on the Raspberry Pi

echo "=== HDMI Audio Troubleshooting ==="
echo ""

echo "1. Checking ALSA devices:"
aplay -l
echo ""

echo "2. Checking ALSA configuration:"
cat /etc/asound.conf
echo ""

echo "3. Testing audio playback (5 seconds):"
speaker-test -t sine -f 1000 -c 2 -l 1 -s 1
echo ""

echo "4. Checking systemd service status:"
systemctl status hdmi-audio.service --no-pager
echo ""

echo "5. Checking recent service logs:"
journalctl -u hdmi-audio.service -n 50 --no-pager
echo ""

echo "6. Testing mpv directly:"
mpv --loop=1 --no-video --ao=alsa /opt/hdmi-tester/audio.mp3
echo ""

echo "=== Troubleshooting Complete ==="
