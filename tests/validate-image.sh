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

# Setup cleanup traps
setup_traps

# Setup loop device
echo "📁 Setting up loop device..."
LOOP_DEVICE=$(setup_loop_device "${IMAGE_FILE}")
LOOP_EXIT=$?
if [ ${LOOP_EXIT} -ne 0 ] || [ -z "${LOOP_DEVICE}" ]; then
    echo "❌ Failed to setup loop device"
    exit 1
fi

echo "✅ Loop device ready: ${LOOP_DEVICE}"

# CRITICAL FIX: Give kernel time to create partition devices
echo "⏳ Waiting for partition devices to be created..."
sleep 2
sudo partprobe "${LOOP_DEVICE}" 2>/dev/null || true

# Additional wait for udev to settle
if command -v udevadm &>/dev/null; then
    sudo udevadm settle 2>/dev/null || true
fi
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
    echo "❌ Failed to create mount point"
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
    "/opt/hdmi-tester/audio.mp3|MP3 Audio File"
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
    "/opt/hdmi-tester/hdmi-diagnostics|HDMI Diagnostics Script"
    "/opt/hdmi-tester/detect-hdmi-audio|Detect HDMI Audio Script"
    "/etc/asound.conf|ALSA System Configuration"
    "/var/lib/alsa/asound.state|ALSA State File"
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
AUTOLOGIN_FOUND=false

if [ -f "${MOUNT_POINT}/etc/systemd/system/getty@tty1.service.d/autologin.conf" ]; then
    echo "  ✅ Auto-login config: /etc/systemd/system/getty@tty1.service.d/autologin.conf found"

    # Validate it contains autologin for pi user
    if grep -q "autologin pi" "${MOUNT_POINT}/etc/systemd/system/getty@tty1.service.d/autologin.conf" 2>/dev/null; then
        echo "      ✅ Auto-login configured for user 'pi'"
        AUTOLOGIN_FOUND=true
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
    "/opt/hdmi-tester/hdmi-test|HDMI Test Script|auto-detect|VLC auto-detect video output"
    "/opt/hdmi-tester/hdmi-test|HDMI Test Script|--alsa-audio-device|ALSA audio device flag"
    "/opt/hdmi-tester/pixel-test|Pixel Test Script|auto-detect|VLC auto-detect video output"
    "/opt/hdmi-tester/pixel-test|Pixel Test Script|--alsa-audio-device|ALSA audio device flag"
    "/opt/hdmi-tester/image-test|Image Test Script|auto-detect|VLC auto-detect video output"
    "/opt/hdmi-tester/full-test|Full Test Script|auto-detect|VLC auto-detect video output"
    "/opt/hdmi-tester/audio-test|Audio Test Script|--alsa-audio-device|ALSA audio device flag"
)

for check_entry in "${SCRIPT_CONTENT_CHECKS[@]}"; do
    IFS='|' read -r script_path script_name pattern description <<< "${check_entry}"
    full_path="${MOUNT_POINT}${script_path}"

    if [ ! -f "${full_path}" ]; then
        echo "  ⚠️  ${script_name}: File not found, skipping content check"
        continue
    fi

    if grep -qF -- "${pattern}" "${full_path}" 2>/dev/null; then
        echo "  ✅ ${script_name}: ${description} configured correctly"
    else
        echo "  ❌ ${script_name}: Missing ${description} (expected '${pattern}')"
        VALIDATION_ERRORS+=("${script_name}: Missing ${description}")
        ALL_OK=false
    fi
done

# Check that OLD broken flags are NOT present
echo ""
echo "🔍 Checking for deprecated/broken flags..."
echo ""

BAD_FLAG_CHECKS=(
    "/opt/hdmi-tester/hdmi-test|HDMI Test Script|--vout=fbdev|fbdev (deprecated)"
    "/opt/hdmi-tester/hdmi-test|HDMI Test Script|export AUDIODEV=|AUDIODEV env var (doesn't work)"
    "/opt/hdmi-tester/pixel-test|Pixel Test Script|--vout=fbdev|fbdev (deprecated)"
    "/opt/hdmi-tester/pixel-test|Pixel Test Script|export AUDIODEV=|AUDIODEV env var (doesn't work)"
    "/opt/hdmi-tester/image-test|Image Test Script|--vout=fbdev|fbdev (deprecated)"
    "/opt/hdmi-tester/full-test|Full Test Script|--vout=fbdev|fbdev (deprecated)"
    "/opt/hdmi-tester/audio-test|Audio Test Script|export AUDIODEV=|AUDIODEV env var (doesn't work)"
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
QEMU_COPIED=false
if [ -f "${MOUNT_POINT}/usr/bin/dpkg-query" ]; then
    # Check if qemu-arm-static is available and binfmt is configured
    if [ -f "/usr/bin/qemu-arm-static" ] && [ -f "/proc/sys/fs/binfmt_misc/qemu-arm" ]; then
        # CRITICAL FIX #1: Mount required pseudo-filesystems for chroot
        echo "  ℹ️  Mounting pseudo-filesystems for chroot environment..."

        # Mount /proc if not already mounted
        if ! mountpoint -q "${MOUNT_POINT}/proc" 2>/dev/null; then
            sudo mount -t proc proc "${MOUNT_POINT}/proc" || {
                echo "  ⚠️  Failed to mount /proc, chroot may not work properly"
            }
        fi

        # Mount /dev if not already mounted
        if ! mountpoint -q "${MOUNT_POINT}/dev" 2>/dev/null; then
            sudo mount --bind /dev "${MOUNT_POINT}/dev" || {
                echo "  ⚠️  Failed to mount /dev, chroot may not work properly"
            }
        fi

        # Mount /sys if not already mounted
        if ! mountpoint -q "${MOUNT_POINT}/sys" 2>/dev/null; then
            sudo mount --bind /sys "${MOUNT_POINT}/sys" || {
                echo "  ⚠️  Failed to mount /sys, chroot may not work properly"
            }
        fi

        # Track these mounts for cleanup
        track_mount "${MOUNT_POINT}/proc"
        track_mount "${MOUNT_POINT}/dev"
        track_mount "${MOUNT_POINT}/sys"

        # CRITICAL FIX #2: Track qemu-arm-static for cleanup
        # Ensure qemu-arm-static is available in chroot
        if [ ! -f "${MOUNT_POINT}/usr/bin/qemu-arm-static" ]; then
            echo "  ℹ️  Copying qemu-arm-static to chroot..."
            sudo cp /usr/bin/qemu-arm-static "${MOUNT_POINT}/usr/bin/"
            QEMU_COPIED=true
            track_temp_file "${MOUNT_POINT}/usr/bin/qemu-arm-static"
        fi

        CAN_CHROOT=true
        echo "  ✅ ARM binary execution available (qemu-user-static)"
        echo "  ✅ Chroot environment prepared with pseudo-filesystems"
    else
        echo "  ⚠️  Cannot execute ARM binaries (qemu-user-static not configured)"
        echo "      Will use fallback binary checks instead"
    fi
else
    echo "  ⚠️  dpkg-query not found in image"
fi

REQUIRED_PACKAGES=(
    "alsa-utils|ALSA Utilities"
)

for pkg_entry in "${REQUIRED_PACKAGES[@]}"; do
    IFS='|' read -r package description <<< "${pkg_entry}"

    # Try chroot method first if available
    PKG_INSTALLED=false
    if [ "${CAN_CHROOT}" = true ]; then
        # CRITICAL FIX #3: Add timeout for entire chroot operation, not just dpkg-query
        # Use timeout to prevent hangs from QEMU/binfmt issues
        if timeout 15 bash -c "sudo chroot '${MOUNT_POINT}' dpkg-query -W -f='\${Status}' '${package}' 2>/dev/null | grep -q 'install ok installed'"; then
            PKG_INSTALLED=true
        else
            CHROOT_EXIT=$?
            if [ ${CHROOT_EXIT} -eq 124 ]; then
                echo "  ⚠️  Chroot timeout for ${package} (QEMU/binfmt may be failing)"
                CAN_CHROOT=false  # Disable chroot for remaining checks
            fi
        fi
    fi

    # Fallback: Check for key binaries directly
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
