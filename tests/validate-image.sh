#!/bin/bash
# Validate built image has required files and configuration
# This script performs comprehensive validation of HDMI Tester images

set -e
set -u
set -o pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Source validation utilities
if [ ! -f "${PROJECT_ROOT}/scripts/validation-utils.sh" ]; then
    echo "❌ Error: validation-utils.sh not found"
    exit 1
fi

# shellcheck source=../scripts/validation-utils.sh
source "${PROJECT_ROOT}/scripts/validation-utils.sh"

# Show usage
show_usage() {
    echo "Usage: $0 <image_file.img>"
    echo ""
    echo "This script validates that the HDMI Tester image contains all required files."
    echo ""
    echo "Example: $0 build/pi-gen-work/deploy/image.img"
    exit 1
}

# Check arguments
if [ $# -lt 1 ]; then
    show_usage
fi

IMAGE_FILE="$1"

# Validate image file exists
if [ ! -f "${IMAGE_FILE}" ]; then
    echo "❌ Error: Image file not found: ${IMAGE_FILE}"
    exit 1
fi

# Get absolute path for cleanup
IMAGE_FILE=$(readlink -f "${IMAGE_FILE}")

echo "=================================================="
echo "Validating HDMI Tester Image"
echo "=================================================="
echo ""
echo "Image: ${IMAGE_FILE}"
echo "Size: $(du -h "${IMAGE_FILE}" | cut -f1)"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."
if ! check_root_or_sudo; then
    exit 1
fi

if ! check_required_commands losetup mount umount mountpoint grep awk; then
    exit 1
fi

echo ""

# CRITICAL: Setup cleanup traps BEFORE creating any resources
# This ensures proper cleanup even if script exits unexpectedly
setup_traps

# Setup loop device
echo "📁 Setting up loop device..."
LOOP_DEVICE=$(setup_loop_device "${IMAGE_FILE}")
LOOP_EXIT=$?
if [ ${LOOP_EXIT} -ne 0 ] || [ -z "${LOOP_DEVICE}" ]; then
    echo "❌ Failed to setup loop device (exit code: ${LOOP_EXIT})"
    exit 1
fi

echo "✅ Loop device ready: ${LOOP_DEVICE}"

# Wait for partition devices to be created by the kernel
# Replace brittle sleep/partprobe with proper wait loop
echo "⏳ Waiting for partition devices to be created..."
PARTITION_WAIT_MAX=10  # Maximum seconds to wait
PARTITION_WAIT_COUNT=0

# Try to probe partitions
sudo partprobe "${LOOP_DEVICE}" 2>/dev/null || true

# Wait for udev to settle if available
if command -v udevadm &>/dev/null; then
    sudo udevadm settle 2>/dev/null || true
fi

# Determine partition naming convention (loop0p1 vs loop0_1)
BOOT_PARTITION_EXPECTED="${LOOP_DEVICE}p1"
if [ ! -e "${BOOT_PARTITION_EXPECTED}" ]; then
    # Some systems use loop0_1 instead of loop0p1
    BOOT_PARTITION_EXPECTED="${LOOP_DEVICE}_1"
fi

# Wait loop: check every 0.5 seconds for partition device to appear
while [ ${PARTITION_WAIT_COUNT} -lt $((PARTITION_WAIT_MAX * 2)) ]; do
    if [ -e "${BOOT_PARTITION_EXPECTED}" ]; then
        break
    fi
    sleep 0.5
    PARTITION_WAIT_COUNT=$((PARTITION_WAIT_COUNT + 1))
done

# Verify we actually found the partition
if [ ! -e "${BOOT_PARTITION_EXPECTED}" ]; then
    echo "❌ Partition devices not created after ${PARTITION_WAIT_MAX}s wait"
    echo "   Expected: ${BOOT_PARTITION_EXPECTED}"
    echo "   Available loop devices:"
    ls -la /dev/loop* 2>/dev/null || echo "   (none found)"
    exit 1
fi

echo "✅ Partition devices ready (waited $((PARTITION_WAIT_COUNT / 2)).$((PARTITION_WAIT_COUNT % 2 * 5))s)"
echo ""

# Verify boot partition exists
echo "🔍 Verifying partitions..."
BOOT_PARTITION=$(verify_partition "${LOOP_DEVICE}" 1)
BOOT_EXIT=$?
if [ ${BOOT_EXIT} -ne 0 ] || [ -z "${BOOT_PARTITION}" ]; then
    echo "❌ Error: Boot partition not found"
    exit 1
fi
echo "  ✅ Boot partition: ${BOOT_PARTITION}"

# Verify root partition exists
ROOT_PARTITION=$(verify_partition "${LOOP_DEVICE}" 2)
ROOT_EXIT=$?
if [ ${ROOT_EXIT} -ne 0 ] || [ -z "${ROOT_PARTITION}" ]; then
    echo "❌ Error: Root partition not found"
    exit 1
fi
echo "  ✅ Root partition: ${ROOT_PARTITION}"
echo ""

# Mount root partition
MOUNT_POINT=$(create_temp_dir "/tmp" "hdmi-tester-mount")
MOUNT_EXIT=$?
if [ ${MOUNT_EXIT} -ne 0 ] || [ -z "${MOUNT_POINT}" ]; then
    echo "❌ Failed to create mount point (exit code: ${MOUNT_EXIT})"
    exit 1
fi

# Validate MOUNT_POINT is a safe absolute path before using it
if [[ ! "${MOUNT_POINT}" =~ ^/tmp/.+ ]]; then
    echo "❌ Invalid mount point path: ${MOUNT_POINT}"
    echo "   Expected path under /tmp/"
    exit 1
fi

# Verify directory exists and is writable
if [ ! -d "${MOUNT_POINT}" ] || [ ! -w "${MOUNT_POINT}" ]; then
    echo "❌ Mount point not accessible: ${MOUNT_POINT}"
    exit 1
fi

echo "📂 Mounting root partition..."
if ! mount_partition "${ROOT_PARTITION}" "${MOUNT_POINT}" "ext4" "rw"; then
    echo "❌ Failed to mount root partition"
    exit 1
fi

echo "✅ Root partition mounted at ${MOUNT_POINT}"
echo ""

# Track variables for validation
ALL_OK=true
MISSING_FILES=()
VALIDATION_ERRORS=()

# Check for required files
echo "🔍 Checking required files..."
echo ""

FILES_TO_CHECK=(
    "/opt/hdmi-tester/image-test.webm|Image Test Video"
    "/opt/hdmi-tester/color-test.webm|Color Test Video"
    "/opt/hdmi-tester/stereo.flac|Stereo FLAC Audio"
    "/opt/hdmi-tester/surround51.flac|5.1 Surround FLAC Audio"
    "/opt/hdmi-tester/image.png|Default Test Image"
    "/opt/hdmi-tester/black.png|Black Test Image"
    "/opt/hdmi-tester/blue.png|Blue Test Image"
    "/opt/hdmi-tester/green.png|Green Test Image"
    "/opt/hdmi-tester/red.png|Red Test Image"
    "/opt/hdmi-tester/white.png|White Test Image"
    "/opt/hdmi-tester/hdmi-test|HDMI Test Script"
    "/opt/hdmi-tester/pixel-test|Pixel Test Script"
    "/opt/hdmi-tester/image-test|Image Rotation Test Script"
    "/opt/hdmi-tester/full-test|Full Test Script"
    "/opt/hdmi-tester/audio-test|Audio Test Script"
    "/opt/hdmi-tester/hdmi-diagnostics|HDMI Diagnostics Script"
    "/opt/hdmi-tester/detect-hdmi-audio|Detect HDMI Audio Script"
    "/usr/local/bin/hdmi-tester-config|Configuration TUI Tool"
    "/usr/local/bin/hdmi-auto-launcher|Auto-Launcher Script"
    "/usr/local/lib/hdmi-tester/config-lib.sh|Configuration Library"
    "/boot/firmware/hdmi-tester.conf|Configuration File"
    "/etc/systemd/system/hdmi-test.service|HDMI Test Service"
    "/etc/systemd/system/pixel-test.service|Pixel Test Service"
    "/etc/systemd/system/image-test.service|Image Rotation Test Service"
    "/etc/systemd/system/audio-test.service|Audio Test Service"
    "/etc/systemd/system/full-test.service|Full Test Service"
)

for file_entry in "${FILES_TO_CHECK[@]}"; do
    IFS='|' read -r file description <<< "${file_entry}"
    full_path="${MOUNT_POINT}${file}"

    if validate_file_readable "${full_path}"; then
        size=$(du -h "${full_path}" 2>/dev/null | cut -f1 || echo "?")
        echo "  ✅ ${description}: ${file} (${size})"
    else
        echo "  ❌ ${description}: MISSING or UNREADABLE: ${file}"
        MISSING_FILES+=("${file}")
        VALIDATION_ERRORS+=("Missing or unreadable file: ${file}")
        ALL_OK=false
    fi
done

echo ""

# Check for auto-start configuration
echo "🔍 Checking auto-start configuration (Console Mode)..."
echo ""

# Check for auto-login on tty1
if [ -f "${MOUNT_POINT}/etc/systemd/system/getty@tty1.service.d/autologin.conf" ]; then
    echo "  ✅ Auto-login config: /etc/systemd/system/getty@tty1.service.d/autologin.conf found"

    # Validate it contains autologin for pi user
    if grep -q "autologin pi" "${MOUNT_POINT}/etc/systemd/system/getty@tty1.service.d/autologin.conf" 2>/dev/null; then
        echo "      ✅ Auto-login configured for user 'pi'"
    else
        echo "      ⚠️  Auto-login config exists but may not be configured correctly"
        VALIDATION_ERRORS+=("Auto-login not configured for pi user")
        ALL_OK=false
    fi
else
    echo "  ❌ Auto-login configuration not found"
    VALIDATION_ERRORS+=("Auto-login not configured")
    ALL_OK=false
fi

echo ""

# Check HDMI boot configuration
echo "🔍 Checking HDMI boot configuration..."
echo ""

# Define configuration files to check (both old and new locations)
CONFIG_PATHS=(
    "${MOUNT_POINT}/boot/config.txt"
    "${MOUNT_POINT}/boot/firmware/config.txt"
)

CONFIG_FOUND=false

# Required HDMI settings to check (uncommented)
REQUIRED_SETTINGS=(
    "hdmi_force_hotplug=1|HDMI Force Hotplug"
    "hdmi_drive=2|HDMI Audio"
    "hdmi_group=0|HDMI Group (Auto-detect)"
    "hdmi_mode=0|HDMI Mode (Auto-detect)"
)

for config_path in "${CONFIG_PATHS[@]}"; do
    if [ -f "${config_path}" ]; then
        CONFIG_FOUND=true
        echo "  📝 Found: ${config_path##${MOUNT_POINT}}"

        # Check each required setting
        for setting_entry in "${REQUIRED_SETTINGS[@]}"; do
            IFS='|' read -r pattern description <<< "${setting_entry}"

            if validate_config_setting "${config_path}" "^[[:space:]]*${pattern}"; then
                echo "      ✅ ${description}: Configured"
            else
                echo "      ❌ ${description}: NOT CONFIGURED or commented"
                VALIDATION_ERRORS+=("Missing HDMI setting: ${description}")
                ALL_OK=false
            fi
        done

        echo ""
        # Only check first config file found
        break
    fi
done

if [ "${CONFIG_FOUND}" = false ]; then
    echo "  ❌ config.txt not found in /boot or /boot/firmware"
    VALIDATION_ERRORS+=("config.txt not found")
    ALL_OK=false
fi

echo ""

# Check if services are enabled
echo "🔍 Checking systemd service availability..."
echo ""

SERVICES_TO_CHECK=(
    "hdmi-test.service|HDMI Test Service|multi-user.target"
    "pixel-test.service|Pixel Test Service|multi-user.target"
    "image-test.service|Image Rotation Test Service|multi-user.target"
    "audio-test.service|Audio Test Service|multi-user.target"
    "full-test.service|Full Test Service|multi-user.target"
)

for service_entry in "${SERVICES_TO_CHECK[@]}"; do
    IFS='|' read -r service description target <<< "${service_entry}"

    # Check if service file exists
    service_file="${MOUNT_POINT}/etc/systemd/system/${service}"
    if [ ! -f "${service_file}" ]; then
        echo "  ❌ ${description}: Service file not found"
        VALIDATION_ERRORS+=("Service file not found: ${service}")
        ALL_OK=false
        continue
    fi

    # Check if service is enabled via symlink
    symlink_path="${MOUNT_POINT}/etc/systemd/system/${target}.wants/${service}"
    if verify_symlink "${symlink_path}"; then
        echo "  ✅ ${description}: Enabled in ${target}"
    else
        echo "  ⚠️  ${description}: Not enabled in ${target} (may use alternative method)"
    fi
done

echo ""

# Check test script contents for correct VLC flags
echo "🔍 Checking test script contents (VLC fixes)..."
echo ""

SCRIPT_CONTENT_CHECKS=(
    "/opt/hdmi-tester/hdmi-test|HDMI Test Script|source.*config-lib.sh|Config library sourcing"
    "/opt/hdmi-tester/hdmi-test|HDMI Test Script|get_vlc_flags|VLC flags from config"
    "/opt/hdmi-tester/pixel-test|Pixel Test Script|source.*config-lib.sh|Config library sourcing"
    "/opt/hdmi-tester/pixel-test|Pixel Test Script|get_vlc_flags|VLC flags from config"
    "/opt/hdmi-tester/image-test|Image Test Script|source.*config-lib.sh|Config library sourcing"
    "/opt/hdmi-tester/image-test|Image Test Script|get_vlc_flags|VLC flags from config"
    "/opt/hdmi-tester/full-test|Full Test Script|source.*config-lib.sh|Config library sourcing"
    "/opt/hdmi-tester/full-test|Full Test Script|get_vlc_flags|VLC flags from config"
    "/opt/hdmi-tester/audio-test|Audio Test Script|source.*config-lib.sh|Config library sourcing"
    "/opt/hdmi-tester/audio-test|Audio Test Script|get_vlc_flags|VLC flags from config"
)

for check_entry in "${SCRIPT_CONTENT_CHECKS[@]}"; do
    IFS='|' read -r script_path script_name pattern description <<< "${check_entry}"
    full_path="${MOUNT_POINT}${script_path}"

    if [ ! -f "${full_path}" ]; then
        echo "  ⚠️  ${script_name}: File not found, skipping content check"
        continue
    fi

    if grep -qE -- "${pattern}" "${full_path}" 2>/dev/null; then
        echo "  ✅ ${script_name}: ${description} configured correctly"
    else
        echo "  ❌ ${script_name}: Missing ${description} (expected pattern '${pattern}')"
        VALIDATION_ERRORS+=("${script_name}: Missing ${description}")
        ALL_OK=false
    fi
done

# Check that OLD broken flags are NOT present
echo ""
echo "🔍 Checking for deprecated/broken flags..."
echo ""

BAD_FLAG_CHECKS=(
    "/opt/hdmi-tester/hdmi-test|HDMI Test Script|-vvv|hardcoded -vvv (should use config)"
    "/opt/hdmi-tester/pixel-test|Pixel Test Script|-vvv|hardcoded -vvv (should use config)"
    "/opt/hdmi-tester/image-test|Image Test Script|-vvv|hardcoded -vvv (should use config)"
    "/opt/hdmi-tester/full-test|Full Test Script|-vvv|hardcoded -vvv (should use config)"
    "/opt/hdmi-tester/audio-test|Audio Test Script|-vvv|hardcoded -vvv (should use config)"
)

for check_entry in "${BAD_FLAG_CHECKS[@]}"; do
    IFS='|' read -r script_path script_name pattern description <<< "${check_entry}"
    full_path="${MOUNT_POINT}${script_path}"

    if [ ! -f "${full_path}" ]; then
        continue  # Already reported as missing above
    fi

    if grep -qF -- "${pattern}" "${full_path}" 2>/dev/null; then
        echo "  ❌ ${script_name}: Still contains ${description} - NOT FIXED!"
        VALIDATION_ERRORS+=("${script_name}: Contains deprecated ${description}")
        ALL_OK=false
    else
        echo "  ✅ ${script_name}: No deprecated ${description}"
    fi
done

echo ""

# Check configuration system
echo "🔍 Checking configuration system..."
echo ""

# Check config file exists and has correct defaults
CONFIG_FILE="${MOUNT_POINT}/boot/firmware/hdmi-tester.conf"
if [ -f "${CONFIG_FILE}" ]; then
    echo "  ✅ Configuration file exists: /boot/firmware/hdmi-tester.conf"

    # Check for required config keys
    if grep -q "^DEBUG_MODE=" "${CONFIG_FILE}" 2>/dev/null; then
        DEBUG_VALUE=$(grep "^DEBUG_MODE=" "${CONFIG_FILE}" | cut -d'=' -f2)
        if [ "${DEBUG_VALUE}" = "true" ]; then
            echo "      ✅ DEBUG_MODE=true (verbose logging enabled by default)"
        else
            echo "      ⚠️  DEBUG_MODE=${DEBUG_VALUE} (expected 'true' by default)"
        fi
    else
        echo "      ❌ DEBUG_MODE not found in config"
        VALIDATION_ERRORS+=("DEBUG_MODE missing from config file")
        ALL_OK=false
    fi

    if grep -q "^DEFAULT_SERVICE=" "${CONFIG_FILE}" 2>/dev/null; then
        DEFAULT_VALUE=$(grep "^DEFAULT_SERVICE=" "${CONFIG_FILE}" | cut -d'=' -f2)
        if [ -z "${DEFAULT_VALUE}" ]; then
            echo "      ✅ DEFAULT_SERVICE is empty (boot to terminal by default)"
        else
            echo "      ⚠️  DEFAULT_SERVICE=${DEFAULT_VALUE} (expected empty by default)"
        fi
    else
        echo "      ❌ DEFAULT_SERVICE not found in config"
        VALIDATION_ERRORS+=("DEFAULT_SERVICE missing from config file")
        ALL_OK=false
    fi
else
    echo "  ❌ Configuration file not found: /boot/firmware/hdmi-tester.conf"
    VALIDATION_ERRORS+=("Configuration file missing")
    ALL_OK=false
fi

# Check config library
if [ -f "${MOUNT_POINT}/usr/local/lib/hdmi-tester/config-lib.sh" ]; then
    echo "  ✅ Configuration library exists"

    # Check for key functions
    if grep -q "get_vlc_flags()" "${MOUNT_POINT}/usr/local/lib/hdmi-tester/config-lib.sh" 2>/dev/null; then
        echo "      ✅ get_vlc_flags() function defined"
    else
        echo "      ❌ get_vlc_flags() function missing"
        VALIDATION_ERRORS+=("get_vlc_flags() missing from config library")
        ALL_OK=false
    fi
else
    echo "  ❌ Configuration library not found"
    VALIDATION_ERRORS+=("Configuration library missing")
    ALL_OK=false
fi

# Check TUI tool
if [ -f "${MOUNT_POINT}/usr/local/bin/hdmi-tester-config" ] && [ -x "${MOUNT_POINT}/usr/local/bin/hdmi-tester-config" ]; then
    echo "  ✅ Configuration TUI tool exists and is executable"
else
    echo "  ❌ Configuration TUI tool missing or not executable"
    VALIDATION_ERRORS+=("Configuration TUI missing or not executable")
    ALL_OK=false
fi

# Check auto-launcher
if [ -f "${MOUNT_POINT}/usr/local/bin/hdmi-auto-launcher" ] && [ -x "${MOUNT_POINT}/usr/local/bin/hdmi-auto-launcher" ]; then
    echo "  ✅ Auto-launcher exists and is executable"
else
    echo "  ❌ Auto-launcher missing or not executable"
    VALIDATION_ERRORS+=("Auto-launcher missing or not executable")
    ALL_OK=false
fi

# Check bashrc integration
if [ -f "${MOUNT_POINT}/home/pi/.bashrc" ]; then
    if grep -q "hdmi-auto-launcher" "${MOUNT_POINT}/home/pi/.bashrc" 2>/dev/null; then
        echo "  ✅ Auto-launcher integrated into .bashrc"
    else
        echo "  ❌ Auto-launcher not integrated into .bashrc"
        VALIDATION_ERRORS+=("Auto-launcher not in .bashrc")
        ALL_OK=false
    fi
else
    echo "  ⚠️  /home/pi/.bashrc not found"
fi

echo ""

# Check for required packages
echo "🔍 Checking for required packages..."
echo ""

# Verify dpkg database is accessible
if [ ! -f "${MOUNT_POINT}/var/lib/dpkg/status" ]; then
    echo "❌ Error: dpkg status file not found at ${MOUNT_POINT}/var/lib/dpkg/status"
    VALIDATION_ERRORS+=("dpkg database missing")
    ALL_OK=false
else
    echo "  ℹ️  dpkg database found: $(wc -l < "${MOUNT_POINT}/var/lib/dpkg/status") lines"
fi

# Check if we can use chroot (need qemu-user-static for ARM binaries on x86_64)
CAN_CHROOT=false
if [ -f "${MOUNT_POINT}/usr/bin/dpkg-query" ]; then
    # Check if qemu-arm-static is available and binfmt is configured
    if [ -f "/usr/bin/qemu-arm-static" ] && [ -f "/proc/sys/fs/binfmt_misc/qemu-arm" ]; then
        echo "  ℹ️  Preparing chroot environment with pseudo-filesystems..."

        # Mount and track pseudo-filesystems atomically
        # CRITICAL: Track BEFORE mounting so cleanup works even if mount fails partway
        
        # Mount /proc
        if ! mountpoint -q "${MOUNT_POINT}/proc" 2>/dev/null; then
            track_mount "${MOUNT_POINT}/proc"
            if sudo mount -t proc proc "${MOUNT_POINT}/proc" 2>/dev/null; then
                echo "     ✅ Mounted /proc"
            else
                echo "     ⚠️  Failed to mount /proc - chroot may not work"
                # Remove from tracking since mount failed
                CLEANUP_MOUNTS=("${CLEANUP_MOUNTS[@]/${MOUNT_POINT}\/proc}")
            fi
        fi

        # Mount /dev
        if ! mountpoint -q "${MOUNT_POINT}/dev" 2>/dev/null; then
            track_mount "${MOUNT_POINT}/dev"
            if sudo mount --bind /dev "${MOUNT_POINT}/dev" 2>/dev/null; then
                echo "     ✅ Mounted /dev"
            else
                echo "     ⚠️  Failed to mount /dev - chroot may not work"
                CLEANUP_MOUNTS=("${CLEANUP_MOUNTS[@]/${MOUNT_POINT}\/dev}")
            fi
        fi

        # Mount /sys
        if ! mountpoint -q "${MOUNT_POINT}/sys" 2>/dev/null; then
            track_mount "${MOUNT_POINT}/sys"
            if sudo mount --bind /sys "${MOUNT_POINT}/sys" 2>/dev/null; then
                echo "     ✅ Mounted /sys"
            else
                echo "     ⚠️  Failed to mount /sys - chroot may not work"
                CLEANUP_MOUNTS=("${CLEANUP_MOUNTS[@]/${MOUNT_POINT}\/sys}")
            fi
        fi

        # Ensure qemu-arm-static is available in chroot
        if [ ! -f "${MOUNT_POINT}/usr/bin/qemu-arm-static" ]; then
            echo "  ℹ️  Copying qemu-arm-static to chroot..."
            if sudo cp /usr/bin/qemu-arm-static "${MOUNT_POINT}/usr/bin/" 2>/dev/null; then
                track_temp_file "${MOUNT_POINT}/usr/bin/qemu-arm-static"
                echo "     ✅ qemu-arm-static copied"
            else
                echo "     ⚠️  Failed to copy qemu-arm-static"
            fi
        fi

        # Test if chroot actually works with a simple command
        echo "  ℹ️  Testing chroot functionality..."
        if timeout 5 sudo chroot "${MOUNT_POINT}" /bin/true 2>/dev/null; then
            CAN_CHROOT=true
            echo "  ✅ Chroot environment ready and functional"
        else
            echo "  ⚠️  Chroot test failed - will use fallback binary checks"
            echo "     (This is normal on some systems and doesn't affect validation)"
        fi
    else
        echo "  ℹ️  ARM emulation not available (qemu-user-static not configured)"
        echo "     Will use fallback binary checks instead"
    fi
else
    echo "  ⚠️  dpkg-query not found in image"
fi

REQUIRED_PACKAGES=(
    "alsa-utils|ALSA Utilities"
)

for pkg_entry in "${REQUIRED_PACKAGES[@]}"; do
    IFS='|' read -r package description <<< "${pkg_entry}"

    PKG_INSTALLED=false
    
    # Try chroot method if available
    if [ "${CAN_CHROOT}" = true ]; then
        # Chroot already tested and working, so no timeout needed here
        if sudo chroot "${MOUNT_POINT}" dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep -q 'install ok installed'; then
            PKG_INSTALLED=true
        fi
    fi

    # Fallback: Check for key binaries directly in filesystem
    if [ "${PKG_INSTALLED}" = false ]; then
        case "${package}" in
            alsa-utils)
                if [ -f "${MOUNT_POINT}/usr/bin/aplay" ] && [ -x "${MOUNT_POINT}/usr/bin/aplay" ]; then
                    PKG_INSTALLED=true
                fi
                ;;
        esac
    fi

    # Report results
    if [ "${PKG_INSTALLED}" = true ]; then
        echo "  ✅ ${description}: Installed"
    else
        echo "  ❌ ${description}: NOT INSTALLED"
        VALIDATION_ERRORS+=("Package not installed: ${package}")
        ALL_OK=false
    fi
done

echo ""
echo "=================================================="

# Final result
if [ "${ALL_OK}" = true ]; then
    echo "✅ VALIDATION PASSED!"
    echo ""
    echo "The image contains all required components:"
    echo "  • Test pattern and audio files"
    echo "  • Systemd services"
    echo "  • HDMI configuration"
    echo "  • Required packages"
    echo ""
    echo "The image is ready to flash to an SD card!"
    exit 0
else
    echo "❌ VALIDATION FAILED!"
    echo ""
    echo "Found ${#VALIDATION_ERRORS[@]} error(s):"
    echo ""

    for error in "${VALIDATION_ERRORS[@]}"; do
        echo "  - ${error}"
    done

    echo ""
    echo "Please review the build process and try again."
    echo "Check the build logs for errors during stage execution."
    exit 1
fi
