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

    # Remove legacy vc4-kms overlay entries before writing the new block
    sed -i '/^dtoverlay=vc4-kms-v3d$/d' "${CONFIG_FILE}"
    sed -i '/^dtoverlay=vc6-kms-v3d$/d' "${CONFIG_FILE}"

    # Skip when V2 block already present, otherwise clean out older block
    if grep -q "HDMI Tester Configuration V2" "${CONFIG_FILE}"; then
        echo "  ✓ HDMI Tester Configuration V2 already present"
        continue
    fi

    if grep -q "HDMI Tester Configuration" "${CONFIG_FILE}"; then
        tmp_file="${CONFIG_FILE}.tmp"
        awk '
            /^# HDMI Tester Configuration/ {skip=1; next}
            skip && /^$/ {skip=0; next}
            skip {next}
            {print}
        ' "${CONFIG_FILE}" > "${tmp_file}"
        mv "${tmp_file}" "${CONFIG_FILE}"
        echo "  ℹ️  Removed legacy HDMI configuration block"
    fi

    # Append configuration (dtparam=audio=on is already in base image, so we skip it)
    cat >> "${CONFIG_FILE}" << 'EOF'

# --- HDMI Tester Configuration V2 ---
# This version includes critical fixes for HDMI audio failures (ENODEV -19)
# on Raspberry Pi 3B+ and some Pi 4 models.

# --- Display & Audio Driver Configuration ---
# Use the FKMS (Fake KMS) driver instead of the full KMS driver.
# This is the primary fix for the vc4-hdmi audio bug where the audio device
# fails to register. FKMS is more compatible with a wider range of displays.
dtoverlay=vc4-fkms-v3d

# Force the kernel to read EDID audio data, even if the display reports none.
# This resolves issues where displays have faulty EDID information.
hdmi_force_edid_audio=1

# Force HDMI output even if no display is detected on boot.
hdmi_force_hotplug=1

# Use HDMI for audio output (instead of the 3.5mm jack).
hdmi_drive=2

# --- Resolution & Performance ---
# Auto-detect HDMI mode to support 720p, 1080p, 4K, etc.
hdmi_group=0
hdmi_mode=0

# Allocate sufficient GPU memory for smooth 1080p/4K video playback.
gpu_mem=256

# --- Boot Experience ---
# Disable the rainbow splash screen.
disable_splash=1

# Reduce boot delay to 0 seconds.
boot_delay=0

# Hide low voltage and overtemperature warning overlays (field deployments often lack pristine power).
avoid_warnings=1

# --- Overclocking (Conservative) ---
# Model-specific overclocks for faster boot and better performance.
# These are mild and safe for continuous operation.
# Pi 5 (BCM2712): Default 2400MHz, overclock to 2600MHz (+8%)
# Pi 4 (BCM2711): Default 1500MHz, overclock to 1800MHz (+20%)
# Pi 3 (BCM2837): Default 1200MHz, overclock to 1350MHz (+12.5%)
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

# --- Final Audio Settings ---
# Ensure PWM audio mode is set correctly.
dtparam=audio_pwm_mode=2

# --- Security Hardening ---
# Disable onboard WiFi and Bluetooth to ensure the tester remains offline.
dtoverlay=disable-wifi
dtoverlay=disable-bt
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
    # and introduce audio overrides that we now manage via modprobe defaults.
    #
    # Firmware parameters that cause problems:
    # - coherent_pool=1M       : DMA pool (kernel default is fine)
    # - 8250.nr_uarts=0        : Disables 8250 UART (breaks serial console on some models)
    # - cgroup_disable=memory  : Disables memory cgroup (not needed, causes issues)
    # - vc_mem.mem_base/size   : VideoCore memory (kernel auto-detects correctly)
    # - snd_bcm2835.enable_*   : Firmware audio overrides that conflict with vc4/vc6
    sed -i \
        -e 's/coherent_pool=[^ ]*//g' \
        -e 's/8250\.nr_uarts=[^ ]*//g' \
        -e 's/cgroup_disable=[^ ]*//g' \
        -e 's/vc_mem\.mem_base=[^ ]*//g' \
        -e 's/vc_mem\.mem_size=[^ ]*//g' \
        -e 's/snd_bcm2835\.enable_hdmi=[^ ]*//g' \
        -e 's/snd_bcm2835\.enable_headphones=[^ ]*//g' \
        -e 's/snd_bcm2835\.enable_compat_alsa=[^ ]*//g' \
        -e 's/vc4\.force_hotplug=[^ ]*//g' \
        -e 's/noswap//g' \
        -e 's/quiet//g' \
        -e 's/splash//g' \
        -e 's/loglevel=[^ ]*//g' \
        -e 's/fastboot//g' \
        -e 's/  */ /g' \
        -e 's/^ *//;s/ *$//' \
        "${CMDLINE_FILE}"

    # Append clean parameters ONCE to the single line (using line-specific anchor)
    # Firmware may inject parameters at the START of cmdline, so we append at the END
    # Kernel processes parameters left-to-right, LAST value wins
    sed -i '1 s/$/ noswap quiet splash loglevel=1 fastboot vc4.force_hotplug=3/' "${CMDLINE_FILE}"

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

    if ! grep -q "vc4.force_hotplug=3" "${CMDLINE_FILE}"; then
        echo "❌ Error: Failed to add vc4.force_hotplug=3 to ${CMDLINE_FILE}"
        exit 1
    fi

    echo "  ✅ Validated: Single line with boot optimizations and no firmware conflicts"
done

echo "✅ Boot optimizations (quiet splash loglevel=1 noswap fastboot) added to all cmdline.txt files"

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

# Install systemd timer that defers execution until the system is fully up
install -v -m 644 "${SCRIPT_DIR}/files/fix-cmdline.timer" "${ROOTFS_DIR}/etc/systemd/system/fix-cmdline.timer" || {
    echo "❌ Error: Failed to install fix-cmdline.timer"
    exit 1
}

# Ensure state directory exists for marker file used by fix-cmdline
install -d -m 755 "${ROOTFS_DIR}/var/lib/hdmi-tester"

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

# Provision user credentials to skip interactive first-boot setup
DEFAULT_USER="${FIRST_USER_NAME:-pi}"
DEFAULT_PASS="${FIRST_USER_PASS:-raspberry}"

if [ -z "${DEFAULT_USER}" ] || [ -z "${DEFAULT_PASS}" ]; then
    echo "❌ Error: FIRST_USER_NAME or FIRST_USER_PASS is undefined; cannot create userconf.txt"
    exit 1
fi

echo "Configuring userconf.txt for automatic ${DEFAULT_USER} provisioning..."

if command -v openssl >/dev/null 2>&1; then
    PASSWORD_HASH=$(openssl passwd -6 "${DEFAULT_PASS}")
elif command -v python3 >/dev/null 2>&1; then
    PASSWORD_HASH=$(python3 -c "import crypt, sys; print(crypt.crypt(sys.argv[1], crypt.mksalt(crypt.METHOD_SHA512)))" "${DEFAULT_PASS}")
else
    echo "⚠️  Warning: openssl and python3 unavailable; using precomputed SHA-512 hash"
    PASSWORD_HASH='$6$c8Cfxkwz1kn1Wmhv$hWAuKtdS6MRyOqH4SngCYNc/c240f1Qo9/upcF77M3KzyNePHbZCMFkcmCZ4Cd5djEBEuWc5bHj6u8QqNRf1s0'
fi

if [ -z "${PASSWORD_HASH}" ]; then
    echo "❌ Error: Failed to generate password hash for userconf.txt"
    exit 1
fi

for CONFIG_FILE in "${CONFIG_FILES[@]}"; do
    BOOT_DIR=$(dirname "${CONFIG_FILE}")
    USERCONF_PATH="${BOOT_DIR}/userconf.txt"

    printf '%s:%s\n' "${DEFAULT_USER}" "${PASSWORD_HASH}" > "${USERCONF_PATH}"
    chmod 600 "${USERCONF_PATH}"

    if [ ! -s "${USERCONF_PATH}" ]; then
        echo "❌ Error: Failed to create ${USERCONF_PATH}"
        exit 1
    fi

    echo "  ✓ userconf.txt created at ${USERCONF_PATH#${ROOTFS_DIR}}"
done

unset DEFAULT_PASS
unset PASSWORD_HASH

echo "✅ userconf.txt configured to bypass first-boot login prompts"

# Provide ALSA module defaults to keep HDMI audio enabled without cmdline overrides
install -v -m 644 "${SCRIPT_DIR}/files/hdmi-audio.conf" "${ROOTFS_DIR}/etc/modprobe.d/hdmi-audio.conf" || {
    echo "❌ Error: Failed to install hdmi-audio.conf"
    exit 1
}

echo "✅ ALSA module defaults installed"
