#!/bin/bash -e
# Configure HDMI boot settings for 1920x1080 output

# Validate ROOTFS_DIR is set and exists
if [ -z "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR not set"
    exit 1
fi

if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR does not exist: ${ROOTFS_DIR}"
    exit 1
fi

# Append HDMI configuration to config.txt
cat >> "${ROOTFS_DIR}/boot/firmware/config.txt" << 'EOF'

# HDMI Tester Configuration - Force 1920x1080 @ 60Hz
# Force HDMI output even if no display detected
hdmi_force_hotplug=1

# Use HDMI audio (not 3.5mm jack)
hdmi_drive=2

# Set HDMI mode to CEA (consumer electronics)
hdmi_group=1

# 1920x1080 @ 60Hz (CEA mode 16)
hdmi_mode=16

# GPU memory allocation (sufficient for display)
gpu_mem=128

# Disable rainbow splash screen
disable_splash=1

# Reduce boot delay
boot_delay=0
EOF

echo "HDMI configuration added to config.txt"
