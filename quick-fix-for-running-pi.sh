#!/bin/bash
# Quick fix to patch a running Raspberry Pi to use console mode (no Wayland)
# This removes Wayland/labwc and uses systemd services directly
#
# Usage on Pi:
#   ssh pi@<IP_ADDRESS> 'bash -s' < quick-fix-for-running-pi.sh
#
# Or copy and run directly on Pi:
#   scp quick-fix-for-running-pi.sh pi@<IP_ADDRESS>:~/
#   ssh pi@<IP_ADDRESS>
#   chmod +x quick-fix-for-running-pi.sh
#   sudo ./quick-fix-for-running-pi.sh
#   sudo reboot

set -e

echo "=== Applying Console Mode Fix to Raspberry Pi HDMI Tester ==="
echo ""

# Check we're running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run as root (use sudo)"
    exit 1
fi

# Check required files exist
if [ ! -f /opt/hdmi-tester/image.png ] || [ ! -f /opt/hdmi-tester/audio.mp3 ]; then
    echo "❌ Error: HDMI tester files not found. Are you on the Pi?"
    exit 1
fi

echo "📦 Installing required packages (fbi and mpv)..."
apt-get update
apt-get install -y fbi mpv alsa-utils

echo "🔧 Stopping Wayland services..."
systemctl stop labwc 2>/dev/null || true
killall labwc 2>/dev/null || true

echo "🗑️  Removing Wayland packages..."
apt-get remove -y labwc pipewire wireplumber 2>/dev/null || true

echo "✅ Creating systemd services..."

# Create display service
cat > /etc/systemd/system/hdmi-display.service << 'EOF'
[Unit]
Description=HDMI Test Pattern Display (Framebuffer)
After=local-fs.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/fbi -T 1 -a --noverbose /opt/hdmi-tester/image.png
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create audio service
cat > /etc/systemd/system/hdmi-audio.service << 'EOF'
[Unit]
Description=HDMI Audio Test - ALSA Output
After=sound.target

[Service]
Type=simple
User=pi
Group=audio
ExecStart=/usr/bin/mpv --loop=inf --no-video --ao=alsa --audio-device=alsa/plughw:CARD=vc4hdmi,DEV=0 --volume=100 /opt/hdmi-tester/audio.mp3
Restart=always
RestartSec=15
StandardOutput=journal
StandardError=journal
KillMode=mixed
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Enabling and starting services..."
systemctl daemon-reload
systemctl enable hdmi-display.service
systemctl enable hdmi-audio.service

echo ""
echo "✅ Fix applied successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Reboot the Pi: sudo reboot"
echo "   2. After reboot, image and audio should start automatically"
echo ""
echo "🔍 Troubleshooting:"
echo "   - Check display: sudo systemctl status hdmi-display.service"
echo "   - Check audio: sudo systemctl status hdmi-audio.service"
echo "   - View logs: sudo journalctl -u hdmi-display -u hdmi-audio"
