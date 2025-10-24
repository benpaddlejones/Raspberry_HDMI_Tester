#!/bin/bash
# Quick script to update hdmi-diagnostics on a running Raspberry Pi
# Run this on your Pi to get the updated USB detection

set -e

echo "Updating hdmi-diagnostics script..."

# Backup existing script
if [ -f /opt/hdmi-tester/hdmi-diagnostics ]; then
    sudo cp /opt/hdmi-tester/hdmi-diagnostics /opt/hdmi-tester/hdmi-diagnostics.backup
    echo "✓ Backed up existing script"
fi

# Download updated script from repository
sudo curl -L https://raw.githubusercontent.com/benpaddlejones/Raspberry_HDMI_Tester/main/build/stage3/03-autostart/files/hdmi-diagnostics \
    -o /opt/hdmi-tester/hdmi-diagnostics

sudo chmod +x /opt/hdmi-tester/hdmi-diagnostics
echo "✓ Updated script with improved USB detection"

echo ""
echo "Done! You can now run: sudo /opt/hdmi-tester/hdmi-diagnostics"
