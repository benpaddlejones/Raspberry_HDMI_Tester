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

# Drop the stock KMS overlay; the model-specific block below replaces it
sed -i '/^dtoverlay=vc4-kms-v3d$/d' "${CONFIG_FILE}"

# Append HDMI configuration
cat >> "${CONFIG_FILE}" << 'EOF'

# HDMI Tester Configuration
# Force HDMI output even if no display detected
hdmi_force_hotplug=1

# Force audio through HDMI, even if EDID data says it's not supported
hdmi_force_edid_audio=1

# Use HDMI audio (not 3.5mm jack)
hdmi_drive=2

# Auto-detect HDMI mode (flexible for all displays and Pi models)
hdmi_group=0

# Auto-detect resolution (supports 720p, 1080p, 4K, etc.)
hdmi_mode=0

# GPU memory allocation (256MB for video playback)
gpu_mem=256

# Disable rainbow splash screen
disable_splash=1

# Reduce boot delay
boot_delay=0

# Hide low voltage and overtemperature warning overlays
avoid_warnings=1

# Pi 0-4: FKMS for broad compatibility. Pi 5 has no firmware display stack
# and must use full KMS, otherwise there is no HDMI video or audio.
[pi0]
dtoverlay=vc4-fkms-v3d
[pi1]
dtoverlay=vc4-fkms-v3d
[pi2]
dtoverlay=vc4-fkms-v3d
[pi3]
dtoverlay=vc4-fkms-v3d
[pi4]
dtoverlay=vc4-fkms-v3d
[pi5]
dtoverlay=vc4-kms-v3d
[all]
EOF

echo "✅ Boot configuration complete"
echo ""
echo "HDMI Settings Applied:"
echo "  • Resolution: auto-detect"
echo "  • Audio: HDMI (not 3.5mm)"
echo "  • Force hotplug: Enabled"
echo "  • GPU memory: 256MB"
echo "  • Graphics: vc4-fkms-v3d (Pi 0-4), vc4-kms-v3d (Pi 5)"
