#!/bin/bash
# Quick diagnostic script to run on the Raspberry Pi (Console Mode)
# Usage: ssh pi@<IP_ADDRESS> 'bash -s' < test-pi-status.sh

echo "=== Raspberry Pi HDMI Tester Diagnostics (Console Mode) ==="
echo ""

echo ""
echo "1. Checking display service (VLC for image)..."
if pgrep -x vlc > /dev/null; then
    echo "   ✅ VLC is running (PID: $(pgrep -x vlc))"
else
    echo "   ❌ VLC is NOT running"
fi
echo ""

echo "2. Checking audio player (VLC)..."
if pgrep -x vlc > /dev/null; then
    echo "   ✅ VLC is running (PID: $(pgrep -x vlc))"
else
    echo "   ❌ VLC is NOT running"
fi
echo ""

echo "3. Checking ALSA..."
if command -v aplay > /dev/null; then
    echo "   ✅ ALSA tools installed"
    aplay -l 2>/dev/null | head -3 || echo "   No audio devices found"
else
    echo "   ❌ ALSA tools NOT installed"
fi
echo ""

echo "4. Checking systemd services..."
systemctl status hdmi-display.service --no-pager | grep -E "(Active:|Loaded:)" || echo "   Service not loaded"
systemctl status hdmi-audio.service --no-pager | grep -E "(Active:|Loaded:)" || echo "   Service not loaded"
echo ""

echo "5. Checking test assets..."
if [ -f /opt/hdmi-tester/image.png ]; then
    echo "   ✅ Test image exists ($(du -h /opt/hdmi-tester/image.png | cut -f1))"
else
    echo "   ❌ Test image NOT found"
fi
if [ -f /opt/hdmi-tester/audio.mp3 ]; then
    echo "   ✅ Test audio exists ($(du -h /opt/hdmi-tester/audio.mp3 | cut -f1))"
else
    echo "   ❌ Test audio NOT found"
fi
echo ""

echo "6. Checking auto-login configuration..."
if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
    echo "   ✅ Auto-login configured"
    cat /etc/systemd/system/getty@tty1.service.d/autologin.conf | sed 's/^/      /'
else
    echo "   ❌ Auto-login NOT configured"
fi
echo ""

echo "7. Recent journal logs (last 50 lines)..."
journalctl -n 50 --no-pager | grep -E "(vlc|alsa|hdmi)" || echo "   No relevant logs found"
echo ""

echo "=== End Diagnostics ==="
