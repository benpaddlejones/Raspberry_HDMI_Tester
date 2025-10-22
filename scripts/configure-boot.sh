#!/bin/bash
# Configure Raspberry Pi boot settings for HDMI output

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <mount_point>"
    echo ""
    echo "This script configures HDMI settings in an already-mounted boot partition."
    echo "For new builds, HDMI configuration is handled by stage3/04-boot-config."
    echo ""
    echo "Example: $0 /mnt/boot"
    exit 1
fi

BOOT_MOUNT="$1"

if [ ! -d "${BOOT_MOUNT}" ]; then
    echo "❌ Error: Mount point ${BOOT_MOUNT} not found"
    exit 1
fi

echo "⚙️  Configuring boot settings at ${BOOT_MOUNT}..."

# Check for config.txt (try both locations)
CONFIG_FILE=""
if [ -f "${BOOT_MOUNT}/config.txt" ]; then
    CONFIG_FILE="${BOOT_MOUNT}/config.txt"
elif [ -f "${BOOT_MOUNT}/firmware/config.txt" ]; then
    CONFIG_FILE="${BOOT_MOUNT}/firmware/config.txt"
else
    echo "❌ Error: config.txt not found in ${BOOT_MOUNT}"
    exit 1
fi

echo "📝 Found config.txt at: ${CONFIG_FILE}"

# Backup original config.txt
if [ -f "${CONFIG_FILE}" ]; then
    cp "${CONFIG_FILE}" "${CONFIG_FILE}.backup"
    echo "✅ Backup created: ${CONFIG_FILE}.backup"
fi

# Append HDMI configuration
cat >> "${CONFIG_FILE}" << 'EOF'

# HDMI Tester Configuration - Force 1920x1080 @ 60Hz with Wayland
# Force HDMI output even if no display detected
hdmi_force_hotplug=1

# Use HDMI audio (not 3.5mm jack)
hdmi_drive=2

# Set HDMI mode to CEA (consumer electronics)
hdmi_group=1

# 1920x1080 @ 60Hz (CEA mode 16)
hdmi_mode=16

# GPU memory allocation (increased for Wayland compositing)
gpu_mem=256

# Disable rainbow splash screen
disable_splash=1

# Reduce boot delay
boot_delay=0

# Enable vc4-kms-v3d for Wayland (Mesa GPU driver)
dtoverlay=vc4-kms-v3d
EOF

echo "✅ Boot configuration complete"
echo ""
echo "HDMI Settings Applied:"
echo "  • Resolution: 1920x1080 @ 60Hz"
echo "  • Audio: HDMI (not 3.5mm)"
echo "  • Force hotplug: Enabled"
echo "  • GPU memory: 256MB (Wayland)"
echo "  • Graphics: vc4-kms-v3d (Mesa)"
