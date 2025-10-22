#!/bin/bash
# Quick fix script to be run on a booted Raspberry Pi
# This script fixes the HDMI display service and audio without requiring a full rebuild

set -e

echo "🔧 Applying HDMI Tester fixes on running Raspberry Pi..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Stop services
echo "⏸️  Stopping services..."
systemctl stop hdmi-display.service || true
systemctl stop hdmi-audio.service || true

# Fix cmdline.txt for audio support
echo "� Fixing audio configuration in cmdline.txt..."
CMDLINE_FILES=()

if [ -f "/boot/firmware/cmdline.txt" ]; then
    CMDLINE_FILES+=("/boot/firmware/cmdline.txt")
fi

if [ -f "/boot/cmdline.txt" ]; then
    CMDLINE_FILES+=("/boot/cmdline.txt")
fi

for CMDLINE_FILE in "${CMDLINE_FILES[@]}"; do
    echo "  Updating: ${CMDLINE_FILE}"
    # Remove conflicting audio parameters
    sed -i 's/snd_bcm2835\.enable_hdmi=[0-9]//g' "${CMDLINE_FILE}"
    sed -i 's/snd_bcm2835\.enable_headphones=[0-9]//g' "${CMDLINE_FILE}"
    # Clean up extra spaces
    sed -i 's/  */ /g' "${CMDLINE_FILE}"
    # Add correct audio parameters
    sed -i 's/$/ snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1/' "${CMDLINE_FILE}"
done

echo "✅ Audio parameters updated in cmdline.txt"
echo "⚠️  NOTE: Audio fix requires reboot to take effect!"

# Fix the display service to use fbi
echo "🔧 Updating display service..."
cat > /etc/systemd/system/hdmi-display.service << 'EOF'
[Unit]
Description=HDMI Test Pattern Display
After=multi-user.target

[Service]
Type=simple
User=pi
Group=video
ExecStart=/usr/bin/fbi -T 1 -a --noverbose -d /opt/hdmi-tester/image.png
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
KillMode=mixed
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
echo "🔄 Reloading systemd..."
systemctl daemon-reload

# Enable services
echo "✅ Enabling services..."
systemctl enable hdmi-display.service
systemctl enable hdmi-audio.service

# Start display service (audio will work after reboot)
echo "▶️  Starting display service..."
systemctl start hdmi-display.service

# Check status
echo ""
echo "� Service Status:"
systemctl status hdmi-display.service --no-pager -l || true
echo ""
echo "Audio service status (will work after reboot):"
systemctl status hdmi-audio.service --no-pager -l || true

echo ""
echo "✅ Fix applied! Display should work now."
echo "⚠️  AUDIO REQUIRES REBOOT - Run: sudo reboot"
