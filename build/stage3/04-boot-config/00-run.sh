#!/bin/bash -e
# Configure HDMI boot settings for 1920x1080 output

# Source common validation function
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
STAGE3_DIR="$(dirname "${SCRIPT_DIR}")"
source "${STAGE3_DIR}/00-common/validate-rootfs.sh"

# Validate ROOTFS_DIR using common function
validate_rootfs_dir || exit 1

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

# Model-specific conservative overclock for faster boot and better performance
# Pi 5 (BCM2712): Default 2400MHz, overclock to 2600MHz (+8%)
# Pi 4 (BCM2711): Default 1500MHz, overclock to 1800MHz (+20%)
# Pi 3 (BCM2837): Default 1200MHz, overclock to 1350MHz (+12.5%, safe and tested)
# Pi 2/Zero 2 (BCM2836/2837): Default 900MHz, overclock to 1000MHz (+11%)

[pi5]
arm_freq=2600

[pi4]
arm_freq=1800

[pi3]
arm_freq=1350

[pi2]
arm_freq=1000

[all]

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

    # CRITICAL FIX: Flatten multi-line cmdline.txt to single line FIRST
    # Raspberry Pi firmware/firstboot scripts may create multi-line files
    # This ensures we always work with a single-line file
    sed -i ':a;N;$!ba;s/\n/ /g' "${CMDLINE_FILE}"

    # ROOT CAUSE #2 FIX: Remove ALL firmware parameters to prevent conflicts
    # Raspberry Pi firmware adds these during boot, but they conflict with DRM/vc4
    # We remove them completely - kernel will use defaults which work better with modern drivers
    #
    # Firmware parameters that cause problems:
    # - coherent_pool=1M       : DMA pool (kernel default is fine)
    # - 8250.nr_uarts=0        : Disables 8250 UART (breaks serial console on some models)
    # - cgroup_disable=memory  : Disables memory cgroup (not needed, causes issues)
    # - vc_mem.mem_base/size   : VideoCore memory (kernel auto-detects correctly)
    # - snd_bcm2835.enable_*=0 : DISABLES AUDIO (the root cause of crashes!)
    #
    # By removing these, we ensure:
    # 1. Our audio parameters are the ONLY audio parameters
    # 2. No conflicting =0 values can override our =1 values
    # 3. Kernel defaults work better with DRM than firmware-chosen values
    sed -i \
        -e 's/coherent_pool=[^ ]*//g' \
        -e 's/8250\.nr_uarts=[^ ]*//g' \
        -e 's/cgroup_disable=[^ ]*//g' \
        -e 's/vc_mem\.mem_base=[^ ]*//g' \
        -e 's/vc_mem\.mem_size=[^ ]*//g' \
        -e 's/snd_bcm2835\.enable_hdmi=[^ ]*//g' \
        -e 's/snd_bcm2835\.enable_headphones=[^ ]*//g' \
        -e 's/snd_bcm2835\.enable_compat_alsa=[^ ]*//g' \
        -e 's/noswap//g' \
        -e 's/quiet//g' \
        -e 's/splash//g' \
        -e 's/loglevel=[^ ]*//g' \
        -e 's/fastboot//g' \
        -e 's/  */ /g' \
        -e 's/^ *//;s/ *$//' \
        "${CMDLINE_FILE}"

    # Append clean parameters ONCE to the single line (using line-specific anchor)
    # These audio parameters MUST come last to override any firmware additions
    # Firmware may inject parameters at the START of cmdline, so we append at the END
    # Kernel processes parameters left-to-right, LAST value wins
    #
    # CRITICAL: snd_bcm2835.enable_hdmi=1 MUST be the final audio parameter
    # NOTE: For DRM/vc4 systems (Pi 3B+, Pi 4, Pi 5), the vc4-hdmi driver handles audio,
    # but we keep snd_bcm2835 enabled for backward compatibility with older models
    sed -i '1 s/$/ snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1 noswap quiet splash loglevel=1 fastboot/' "${CMDLINE_FILE}"

    # Verify file is single line (critical for boot)
    LINE_COUNT=$(wc -l < "${CMDLINE_FILE}")
    if [ "${LINE_COUNT}" -gt 1 ]; then
        echo "❌ Error: ${CMDLINE_FILE} has ${LINE_COUNT} lines (must be exactly 1)"
        echo "   Content: $(head -c 200 "${CMDLINE_FILE}")"
        exit 1
    fi

    # Verify NO firmware parameters remain (they cause conflicts)
    CMDLINE_CONTENT=$(cat "${CMDLINE_FILE}")

    if echo "${CMDLINE_CONTENT}" | grep -q "coherent_pool="; then
        echo "❌ Error: coherent_pool parameter still present in ${CMDLINE_FILE}"
        echo "   This firmware parameter causes DRM conflicts"
        exit 1
    fi

    if echo "${CMDLINE_CONTENT}" | grep -q "vc_mem\."; then
        echo "❌ Error: vc_mem parameter still present in ${CMDLINE_FILE}"
        echo "   This firmware parameter causes memory conflicts"
        exit 1
    fi

    # Verify parameters were added
    if ! grep -q "snd_bcm2835.enable_hdmi=1" "${CMDLINE_FILE}"; then
        echo "❌ Error: Failed to add audio parameters to ${CMDLINE_FILE}"
        exit 1
    fi

    # CRITICAL: Verify enable_hdmi=1 comes AFTER any enable_hdmi=0
    # Extract the LAST occurrence of enable_hdmi parameter
    LAST_HDMI_VALUE=$(echo "${CMDLINE_CONTENT}" | grep -o "snd_bcm2835\.enable_hdmi=[01]" | tail -1)
    if [ "${LAST_HDMI_VALUE}" != "snd_bcm2835.enable_hdmi=1" ]; then
        echo "❌ Error: Last enable_hdmi value is not =1 in ${CMDLINE_FILE}"
        echo "   Found: ${LAST_HDMI_VALUE}"
        echo "   Audio will be disabled! Our =1 must come LAST."
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

    echo "  ✅ Validated: Single line, no firmware conflicts, enable_hdmi=1 is last"
done

echo "✅ Audio parameters and boot optimizations (quiet splash loglevel=1 noswap fastboot) added to all cmdline.txt files"

# Install fix-cmdline service to clean up after Raspberry Pi OS firstboot modifications
# Raspberry Pi OS firmware and resize scripts modify cmdline.txt AFTER our image boots,
# adding duplicate parameters and conflicts. This service runs ONCE after first boot to fix it.
echo "Installing fix-cmdline cleanup service..."

# Install cleanup script
install -v -m 755 "${SCRIPT_DIR}/files/fix-cmdline.sh" "${ROOTFS_DIR}/usr/local/sbin/fix-cmdline.sh" || {
    echo "❌ Error: Failed to install fix-cmdline.sh"
    exit 1
}

# Install systemd service
install -v -m 644 "${SCRIPT_DIR}/files/fix-cmdline.service" "${ROOTFS_DIR}/etc/systemd/system/fix-cmdline.service" || {
    echo "❌ Error: Failed to install fix-cmdline.service"
    exit 1
}

echo "✅ fix-cmdline cleanup service installed"

# Install audio health check diagnostic tool
echo "Installing audio health check diagnostic..."

install -v -m 755 "${SCRIPT_DIR}/files/check-audio-health" "${ROOTFS_DIR}/opt/hdmi-tester/check-audio-health" || {
    echo "❌ Error: Failed to install check-audio-health script"
    exit 1
}

install -v -m 644 "${SCRIPT_DIR}/files/audio-health.service" "${ROOTFS_DIR}/etc/systemd/system/audio-health.service" || {
    echo "❌ Error: Failed to install audio-health.service"
    exit 1
}

# Enable audio health check service
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants"
ln -sf /etc/systemd/system/audio-health.service "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/audio-health.service"

echo "✅ Audio health check diagnostic installed"

# Install HDMI Tester configuration file to boot partition
echo "Installing HDMI Tester configuration file..."

# Install to all found boot directories (same logic as config.txt above)
for CONFIG_FILE in "${CONFIG_FILES[@]}"; do
    BOOT_DIR=$(dirname "${CONFIG_FILE}")
    CONFIG_TARGET="${BOOT_DIR}/hdmi-tester.conf"

    echo "  Installing hdmi-tester.conf to: ${CONFIG_TARGET}"

    # Install the configuration file
    install -m 644 "${SCRIPT_DIR}/files/hdmi-tester.conf" "${CONFIG_TARGET}"

    # Verify installation
    if [ ! -f "${CONFIG_TARGET}" ]; then
        echo "❌ Error: Failed to install hdmi-tester.conf to ${CONFIG_TARGET}"
        exit 1
    fi

    echo "  ✓ HDMI Tester configuration installed: ${CONFIG_TARGET#${ROOTFS_DIR}}"
done

echo "✅ HDMI Tester configuration deployment complete"

