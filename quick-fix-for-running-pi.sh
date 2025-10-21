#!/bin/bash
# Quick fix to apply to a running Raspberry Pi
# This updates the labwc autostart to launch the display and audio apps
#
# Usage on Pi:
#   ssh pi@<IP_ADDRESS> 'bash -s' < quick-fix-for-running-pi.sh
#
# Or copy and run directly on Pi:
#   scp quick-fix-for-running-pi.sh pi@<IP_ADDRESS>:~/
#   ssh pi@<IP_ADDRESS>
#   chmod +x quick-fix-for-running-pi.sh
#   ./quick-fix-for-running-pi.sh
#   sudo reboot

set -e

echo "=== Applying Quick Fix to Raspberry Pi HDMI Tester ==="
echo ""

# Check we're running on the Pi
if [ ! -d /opt/hdmi-tester ]; then
    echo "❌ Error: /opt/hdmi-tester not found. Are you on the Pi?"
    exit 1
fi

# Backup existing autostart
if [ -f ~/.config/labwc/autostart ]; then
    echo "📦 Backing up existing autostart..."
    cp ~/.config/labwc/autostart ~/.config/labwc/autostart.backup.$(date +%Y%m%d_%H%M%S)
fi

# Create updated autostart
echo "✏️  Creating new autostart script..."
cat > ~/.config/labwc/autostart << 'EOF'
#!/bin/sh
# Wait for compositor to be fully ready
sleep 2

# Disable screen blanking
wlr-randr --output HDMI-A-1 --on 2>/dev/null || true

# Start image display in background
imv -f -n /opt/hdmi-tester/image.png &

# Wait a moment for display to start
sleep 1

# Start audio playback in background
mpv --loop=inf --no-video --ao=pipewire --volume=100 /opt/hdmi-tester/audio.mp3 &

# Keep compositor running
wait
EOF

chmod +x ~/.config/labwc/autostart

echo "✅ Autostart updated successfully"
echo ""

# Disable the systemd services if they're enabled
echo "🔧 Disabling systemd services (apps launch from autostart instead)..."
if systemctl is-enabled hdmi-display.service 2>/dev/null; then
    sudo systemctl disable hdmi-display.service
    echo "   Disabled hdmi-display.service"
fi
if systemctl is-enabled hdmi-audio.service 2>/dev/null; then
    sudo systemctl disable hdmi-audio.service
    echo "   Disabled hdmi-audio.service"
fi

echo ""
echo "=== Fix Applied Successfully ==="
echo ""
echo "Next steps:"
echo "  1. Reboot the Pi: sudo reboot"
echo "  2. After reboot, you should see:"
echo "     - Test pattern image displayed fullscreen"
echo "     - Audio playing through HDMI"
echo ""
echo "To verify without rebooting, you can manually run:"
echo "  pkill labwc"
echo "  (it will restart automatically via systemd)"
