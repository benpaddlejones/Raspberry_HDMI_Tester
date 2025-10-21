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

# Find all config.txt files and write to ALL of them
# (Raspberry Pi OS versions vary: /boot/config.txt vs /boot/firmware/config.txt)
CONFIG_FILES=()

if [ -f "${ROOTFS_DIR}/boot/firmware/config.txt" ]; then
    CONFIG_FILES+=("${ROOTFS_DIR}/boot/firmware/config.txt")
    echo "Found: /boot/firmware/config.txt"
fi

if [ -f "${ROOTFS_DIR}/boot/config.txt" ]; then
    CONFIG_FILES+=("${ROOTFS_DIR}/boot/config.txt")
    echo "Found: /boot/config.txt"
fi

if [ ${#CONFIG_FILES[@]} -eq 0 ]; then
    echo "❌ Error: No config.txt found in /boot or /boot/firmware"
    exit 1
fi

echo "Writing HDMI configuration to ${#CONFIG_FILES[@]} config file(s)..."

# Append HDMI configuration to ALL config.txt files found
for CONFIG_FILE in "${CONFIG_FILES[@]}"; do
    echo "  Writing to: ${CONFIG_FILE}"

    # Validate file is writable
    if [ ! -w "${CONFIG_FILE}" ]; then
        echo "❌ Error: Config file not writable: ${CONFIG_FILE}"
        exit 1
    fi

    # Append configuration
    cat >> "${CONFIG_FILE}" << 'EOF'

# HDMI Tester Configuration - Force 1920x1080 @ 60Hz (Console Mode)
# Force HDMI output even if no display detected
hdmi_force_hotplug=1

# Use HDMI audio (not 3.5mm jack)
hdmi_drive=2

# Set HDMI mode to CEA (consumer electronics)
hdmi_group=1

# 1920x1080 @ 60Hz (CEA mode 16)
hdmi_mode=16

# Minimal GPU memory for framebuffer (console mode doesn't need GPU acceleration)
gpu_mem=64

# Disable rainbow splash screen
disable_splash=1

# Reduce boot delay
boot_delay=0

# Enable both HDMI and 3.5mm audio
dtparam=audio=on

# Audio configuration for both outputs
dtparam=audio_pwm_mode=2
EOF

    # Verify configuration was added
    if ! grep -q "HDMI Tester Configuration" "${CONFIG_FILE}"; then
        echo "❌ Error: Failed to write HDMI configuration to ${CONFIG_FILE}"
        exit 1
    fi
done

echo "✅ HDMI configuration added to all config.txt files"
