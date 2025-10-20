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
    echo "System ALSA config (/etc/asound.conf):"
    cat /etc/asound.conf
else
    echo "⚠️  /etc/asound.conf not found"
fi
echo ""

if [ -f ~/.asoundrc ]; then
    echo "User ALSA config (~/.asoundrc):"
    cat ~/.asoundrc
else
    echo "ℹ️  ~/.asoundrc not found (using system config)"
fi
echo ""

echo "3. Checking HDMI audio device status:"
amixer -c 0 || echo "⚠️  amixer failed"
echo ""

echo "4. Testing audio playback on HDMI (hw:0,0) - 3 seconds:"
speaker-test -D hw:0,0 -t sine -f 1000 -c 2 -l 1 || echo "⚠️  speaker-test on hw:0,0 (HDMI) failed"
echo ""

echo "5. Testing audio playback on 3.5mm jack (hw:0,1) - 3 seconds:"
speaker-test -D hw:0,1 -t sine -f 1000 -c 2 -l 1 || echo "⚠️  speaker-test on hw:0,1 (headphones) failed"
echo ""

echo "6. Testing audio on 'both' device (HDMI + 3.5mm) - 3 seconds:"
speaker-test -D both -t sine -f 1000 -c 2 -l 1 || echo "⚠️  speaker-test on 'both' device failed"
echo ""

echo "7. Checking systemd service status:"
systemctl status hdmi-audio.service --no-pager || echo "⚠️  Service status check failed"
echo ""

echo "6. Checking recent service logs:"
journalctl -u hdmi-audio.service -n 50 --no-pager || echo "⚠️  Journal check failed"
echo ""

echo "7. Testing mpv directly on BOTH outputs (default device):"
if [ -f /opt/hdmi-tester/audio.mp3 ]; then
    echo "Playing audio for 10 seconds on both HDMI and 3.5mm jack..."
    timeout 10 mpv --loop=1 --no-video --ao=alsa --volume=100 /opt/hdmi-tester/audio.mp3 || echo "⚠️  mpv playback failed"
else
    echo "❌ /opt/hdmi-tester/audio.mp3 not found!"
fi
echo ""

echo "8. Checking audio file:"
if [ -f /opt/hdmi-tester/audio.mp3 ]; then
    ls -lh /opt/hdmi-tester/audio.mp3
    file /opt/hdmi-tester/audio.mp3
else
    echo "❌ /opt/hdmi-tester/audio.mp3 missing"
fi
echo ""

echo "9. Checking user audio group membership:"
groups || echo "⚠️  groups command failed"
echo ""

echo "10. Checking boot config for HDMI audio:"
if [ -f /boot/firmware/config.txt ]; then
    echo "From /boot/firmware/config.txt:"
    grep -E "hdmi|audio" /boot/firmware/config.txt || echo "ℹ️  No HDMI/audio settings found"
elif [ -f /boot/config.txt ]; then
    echo "From /boot/config.txt:"
    grep -E "hdmi|audio" /boot/config.txt || echo "ℹ️  No HDMI/audio settings found"
else
    echo "⚠️  config.txt not found"
fi
echo ""

echo "=== Troubleshooting Complete ==="
echo ""
echo "Quick fixes to try:"
echo "  1. Restart audio service: sudo systemctl restart hdmi-audio.service"
echo "  2. Check HDMI cable is connected to HDMI0 port"
echo "  3. Check 3.5mm cable is connected to headphone jack"
echo "  4. Ensure TV/monitor is set to correct HDMI input"
echo "  5. Test HDMI only: mpv --ao=alsa:device=hw:0,0 /opt/hdmi-tester/audio.mp3"
echo "  6. Test 3.5mm only: mpv --ao=alsa:device=hw:0,1 /opt/hdmi-tester/audio.mp3"
echo "  7. Try: sudo amixer cset numid=3 2  # Force HDMI audio"
echo "  8. Try: sudo amixer cset numid=3 1  # Force 3.5mm audio"
echo "  9. Reboot the system"
