#!/bin/bash
# Quick diagnostic script to run on the Raspberry Pi
# Usage: ssh pi@<IP_ADDRESS> 'bash -s' < test-pi-status.sh

echo "=== Raspberry Pi HDMI Tester Diagnostics ==="
echo ""

echo "1. Checking Wayland compositor (labwc)..."
if pgrep -x labwc > /dev/null; then
    echo "   ✅ labwc is running (PID: $(pgrep -x labwc))"
else
    echo "   ❌ labwc is NOT running"
fi
echo ""

echo "2. Checking for Wayland socket..."
if [ -S /run/user/1000/wayland-0 ]; then
    echo "   ✅ Wayland socket exists: /run/user/1000/wayland-0"
else
    echo "   ❌ Wayland socket NOT found"
    ls -la /run/user/1000/ 2>/dev/null || echo "   /run/user/1000/ does not exist"
fi
echo ""

echo "3. Checking image viewer (imv)..."
if pgrep -x imv > /dev/null; then
    echo "   ✅ imv is running (PID: $(pgrep -x imv))"
else
    echo "   ❌ imv is NOT running"
fi
echo ""

echo "4. Checking audio player (mpv)..."
if pgrep -x mpv > /dev/null; then
    echo "   ✅ mpv is running (PID: $(pgrep -x mpv))"
else
    echo "   ❌ mpv is NOT running"
fi
echo ""

echo "5. Checking PipeWire..."
if pgrep -x pipewire > /dev/null; then
    echo "   ✅ pipewire is running (PID: $(pgrep -x pipewire))"
else
    echo "   ❌ pipewire is NOT running"
fi
echo ""

echo "6. Checking systemd services..."
systemctl status hdmi-display.service --no-pager | grep -E "(Active:|Loaded:)" || echo "   Service not loaded"
systemctl status hdmi-audio.service --no-pager | grep -E "(Active:|Loaded:)" || echo "   Service not loaded"
echo ""

echo "7. Checking test assets..."
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

echo "8. Checking labwc autostart..."
if [ -f /home/pi/.config/labwc/autostart ]; then
    echo "   ✅ Autostart script exists"
    echo "   Contents:"
    cat /home/pi/.config/labwc/autostart | sed 's/^/      /'
else
    echo "   ❌ Autostart script NOT found"
fi
echo ""

echo "9. Recent journal logs (last 50 lines)..."
journalctl -n 50 --no-pager | grep -E "(labwc|imv|mpv|pipewire|wayland)" || echo "   No relevant logs found"
echo ""

echo "=== End Diagnostics ==="
