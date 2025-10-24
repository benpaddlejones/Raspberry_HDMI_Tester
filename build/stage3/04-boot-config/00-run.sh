#!/bin/bash -e
# Configure HDMI boot settings for 1920x1080 output

# Validate ROOTFS_DIR is set and exists
if [ -z "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR not set"
    exit 1
fi

# MEDIUM PRIORITY FIX #8: Safety check - ensure ROOTFS_DIR is not /
ROOTFS_REAL=$(realpath "${ROOTFS_DIR}" 2>/dev/null || echo "${ROOTFS_DIR}")
if [ "${ROOTFS_REAL}" = "/" ] || [ "${ROOTFS_DIR}" = "/" ]; then
    echo "❌ Error: ROOTFS_DIR cannot be root directory (/)"
    echo "   This would modify host system boot configuration!"
    echo "   Current ROOTFS_DIR: ${ROOTFS_DIR}"
    exit 1
fi

if [[ "${ROOTFS_DIR}" =~ ^/(bin|boot|dev|etc|home|lib|opt|root|sbin|srv|sys|usr|var)$ ]]; then
    echo "❌ Error: ROOTFS_DIR appears to be a system directory: ${ROOTFS_DIR}"
    echo "   This looks like a host system path, not a build chroot!"
    exit 1
fi

if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR does not exist: ${ROOTFS_DIR}"
    exit 1
fi

echo "✅ ROOTFS_DIR validated: ${ROOTFS_DIR}"

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

    # Check if configuration already exists
    if grep -q "HDMI Tester Configuration" "${CONFIG_FILE}"; then
        echo "  ⚠️  Configuration already exists in ${CONFIG_FILE}, skipping..."
        continue
    fi

    # Append configuration (dtparam=audio=on is already in base image, so we skip it)
    cat >> "${CONFIG_FILE}" << 'EOF'

# HDMI Tester Configuration - Auto-detect Display Resolution
# Force HDMI output even if no display detected
hdmi_force_hotplug=1

# Use HDMI audio (not 3.5mm jack)
hdmi_drive=2

# Auto-detect HDMI mode (allows flexibility for different displays)
# hdmi_group=0 and hdmi_mode=0 let the Pi negotiate with the display
# This supports: 720p, 1080p, 1440p, 4K, and non-standard resolutions
hdmi_group=0
hdmi_mode=0

# GPU memory for video playback (minimum 256MB for smooth VP9 decoding)
gpu_mem=256

# Disable rainbow splash screen
disable_splash=1

# Reduce boot delay
boot_delay=0

# Conservative overclock for faster boot and better performance
arm_freq=1000

# Audio configuration for both outputs (dtparam=audio=on already set in base image)
dtparam=audio_pwm_mode=2
EOF

    # Verify configuration was added
    if ! grep -q "HDMI Tester Configuration" "${CONFIG_FILE}"; then
        echo "❌ Error: Failed to write HDMI configuration to ${CONFIG_FILE}"
        exit 1
    fi
done

echo "✅ HDMI configuration added to all config.txt files"

# Configure cmdline.txt for audio support
CMDLINE_FILES=()

if [ -f "${ROOTFS_DIR}/boot/firmware/cmdline.txt" ]; then
    CMDLINE_FILES+=("${ROOTFS_DIR}/boot/firmware/cmdline.txt")
    echo "Found: /boot/firmware/cmdline.txt"
fi

if [ -f "${ROOTFS_DIR}/boot/cmdline.txt" ]; then
    CMDLINE_FILES+=("${ROOTFS_DIR}/boot/cmdline.txt")
    echo "Found: /boot/cmdline.txt"
fi

if [ ${#CMDLINE_FILES[@]} -eq 0 ]; then
    echo "❌ Error: No cmdline.txt found in /boot or /boot/firmware"
    exit 1
fi

echo "Adding audio parameters to ${#CMDLINE_FILES[@]} cmdline.txt file(s)..."

for CMDLINE_FILE in "${CMDLINE_FILES[@]}"; do
    echo "  Configuring: ${CMDLINE_FILE}"

    # Validate file is writable
    if [ ! -w "${CMDLINE_FILE}" ]; then
        echo "❌ Error: cmdline.txt not writable: ${CMDLINE_FILE}"
        exit 1
    fi

    # Remove ALL existing audio parameters to avoid conflicts
    # Must remove ALL instances, including duplicates and conflicting values
    # Using global replacement to catch all occurrences
    sed -i 's/snd_bcm2835\.enable_hdmi=[0-9]//g' "${CMDLINE_FILE}"
    sed -i 's/snd_bcm2835\.enable_headphones=[0-9]//g' "${CMDLINE_FILE}"
    sed -i 's/noswap//g' "${CMDLINE_FILE}"
    sed -i 's/quiet//g' "${CMDLINE_FILE}"
    sed -i 's/splash//g' "${CMDLINE_FILE}"
    sed -i 's/loglevel=[0-9]//g' "${CMDLINE_FILE}"
    sed -i 's/fastboot//g' "${CMDLINE_FILE}"

    # Remove cgroup_disable=memory (causes issues with modern kernels)
    sed -i 's/cgroup_disable=memory//g' "${CMDLINE_FILE}"

    # Remove ALL extra spaces (multiple passes to collapse all duplicate spaces)
    sed -i 's/  */ /g' "${CMDLINE_FILE}"
    sed -i 's/  */ /g' "${CMDLINE_FILE}"

    # Trim leading/trailing spaces
    sed -i 's/^ *//;s/ *$//' "${CMDLINE_FILE}"

    # Append audio parameters and boot optimizations (on same line, space-separated)
    sed -i 's/$/ snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1 noswap quiet splash loglevel=1 fastboot/' "${CMDLINE_FILE}"

    # Verify parameters were added
    if ! grep -q "snd_bcm2835.enable_hdmi=1" "${CMDLINE_FILE}"; then
        echo "❌ Error: Failed to add audio parameters to ${CMDLINE_FILE}"
        exit 1
    fi

    if ! grep -q "noswap" "${CMDLINE_FILE}"; then
        echo "❌ Error: Failed to add noswap parameter to ${CMDLINE_FILE}"
        exit 1
    fi

    if ! grep -q "quiet" "${CMDLINE_FILE}"; then
        echo "❌ Error: Failed to add quiet parameter to ${CMDLINE_FILE}"
        exit 1
    fi

    if ! grep -q "loglevel=1" "${CMDLINE_FILE}"; then
        echo "❌ Error: Failed to add loglevel=1 parameter to ${CMDLINE_FILE}"
        exit 1
    fi

    if ! grep -q "fastboot" "${CMDLINE_FILE}"; then
        echo "❌ Error: Failed to add fastboot parameter to ${CMDLINE_FILE}"
        exit 1
    fi
done

echo "✅ Audio parameters and boot optimizations (quiet splash loglevel=1 noswap fastboot) added to all cmdline.txt files"

