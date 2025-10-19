#!/bin/bash
# Validate built image has required files and configuration

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <image_file.img>"
    echo ""
    echo "This script validates that the HDMI Tester image contains all required files."
    echo ""
    echo "Example: $0 build/pi-gen-work/deploy/image.img"
    exit 1
fi

IMAGE_FILE="$1"
MOUNT_POINT="/tmp/hdmi-tester-mount"
LOOP_DEVICE=""

if [ ! -f "${IMAGE_FILE}" ]; then
    echo "❌ Error: Image file not found: ${IMAGE_FILE}"
    exit 1
fi

echo "=================================================="
echo "Validating HDMI Tester Image"
echo "=================================================="
echo ""
echo "Image: ${IMAGE_FILE}"
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script requires sudo privileges to mount the image."
    echo "Please run: sudo $0 $@"
    exit 1
fi

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Cleaning up..."
    if mountpoint -q "${MOUNT_POINT}" 2>/dev/null; then
        umount "${MOUNT_POINT}" 2>/dev/null || true
    fi
    if [ -n "${LOOP_DEVICE}" ]; then
        kpartx -d "${IMAGE_FILE}" 2>/dev/null || true
    fi
    if [ -d "${MOUNT_POINT}" ]; then
        rmdir "${MOUNT_POINT}" 2>/dev/null || true
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Mount image
echo "📁 Mounting image..."
mkdir -p "${MOUNT_POINT}"
kpartx -av "${IMAGE_FILE}"

# Wait for device to be ready (up to 10 seconds)
echo "⏳ Waiting for loop device to be ready..."
for i in {1..10}; do
    sleep 1
    LOOP_DEVICE=$(losetup -l | grep "${IMAGE_FILE}" | awk '{print $1}' | head -n 1)
    if [ -n "${LOOP_DEVICE}" ]; then
        # Check if partition exists
        if [ -e "${LOOP_DEVICE}p2" ] || [ -e "/dev/mapper/$(basename ${LOOP_DEVICE})p2" ]; then
            echo "✅ Loop device ready: ${LOOP_DEVICE}"
            break
        fi
    fi

    if [ $i -eq 10 ]; then
        echo "❌ Error: Loop device not ready after 10 seconds"
        exit 1
    fi
done

# Find the loop device (should be set from above loop)
LOOP_DEVICE=$(losetup -l | grep "${IMAGE_FILE}" | awk '{print $1}' | head -n 1)
if [ -z "${LOOP_DEVICE}" ]; then
    echo "❌ Error: Could not find loop device for image"
    exit 1
fi

# Mount root partition (usually partition 2)
ROOT_PARTITION="${LOOP_DEVICE}p2"
if [ ! -e "${ROOT_PARTITION}" ]; then
    # Try alternative naming
    ROOT_PARTITION="/dev/mapper/$(basename ${LOOP_DEVICE})p2"
fi

if [ ! -e "${ROOT_PARTITION}" ]; then
    echo "❌ Error: Could not find root partition"
    exit 1
fi

mount "${ROOT_PARTITION}" "${MOUNT_POINT}"
echo "✅ Image mounted at ${MOUNT_POINT}"
echo ""

# Check for required files
echo "🔍 Checking required files..."
echo ""

FILES_TO_CHECK=(
    "/opt/hdmi-tester/image.png"
    "/opt/hdmi-tester/audio.mp3"
    "/etc/systemd/system/hdmi-display.service"
    "/etc/systemd/system/hdmi-audio.service"
    "/home/pi/.xinitrc"
)

ALL_OK=true
MISSING_FILES=()

for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "${MOUNT_POINT}${file}" ]; then
        SIZE=$(du -h "${MOUNT_POINT}${file}" | cut -f1)
        echo "  ✅ ${file} (${SIZE})"
    else
        echo "  ❌ MISSING: ${file}"
        MISSING_FILES+=("${file}")
        ALL_OK=false
    fi
done

echo ""

# Check HDMI boot configuration
echo "🔍 Checking HDMI boot configuration..."
echo ""

CONFIG_FILES=(
    "/boot/config.txt"
    "/boot/firmware/config.txt"
)

CONFIG_FOUND=false
HDMI_MODE_OK=false
HDMI_DRIVE_OK=false

# Check ALL config files that exist (both legacy and new locations)
for config in "${CONFIG_FILES[@]}"; do
    if [ -f "${MOUNT_POINT}${config}" ]; then
        CONFIG_FOUND=true
        echo "  📝 Found: ${config}"

        # Check this specific file for HDMI settings
        HAS_MODE=false
        HAS_DRIVE=false

        if grep -q "^[[:space:]]*hdmi_mode=16" "${MOUNT_POINT}${config}"; then
            HAS_MODE=true
            HDMI_MODE_OK=true
        fi

        if grep -q "^[[:space:]]*hdmi_drive=2" "${MOUNT_POINT}${config}"; then
            HAS_DRIVE=true
            HDMI_DRIVE_OK=true
        fi

        # Report status for this file
        if [ "$HAS_MODE" = true ]; then
            echo "      ✅ hdmi_mode=16 found in this file"
        fi
        if [ "$HAS_DRIVE" = true ]; then
            echo "      ✅ hdmi_drive=2 found in this file"
        fi

        # Don't break - check all config files
    fi
done

if [ "$CONFIG_FOUND" = false ]; then
    echo "  ❌ config.txt not found in /boot or /boot/firmware"
    ALL_OK=false
fi

# Overall HDMI configuration status
echo ""
if [ "$HDMI_MODE_OK" = true ]; then
    echo "  ✅ HDMI mode configured (1920x1080@60Hz)"
else
    echo "  ❌ HDMI mode not found in any config.txt"
    ALL_OK=false
fi

if [ "$HDMI_DRIVE_OK" = true ]; then
    echo "  ✅ HDMI audio enabled"
else
    echo "  ❌ HDMI audio not configured in any config.txt"
    ALL_OK=false
fi

echo ""

# Check if services are enabled
echo "🔍 Checking systemd service links..."
echo ""

SERVICE_LINKS=(
    "/etc/systemd/system/graphical.target.wants/hdmi-display.service"
    "/etc/systemd/system/multi-user.target.wants/hdmi-audio.service"
)

for link in "${SERVICE_LINKS[@]}"; do
    if [ -L "${MOUNT_POINT}${link}" ]; then
        echo "  ✅ ${link}"
    else
        echo "  ⚠️  Not enabled: ${link}"
        # Not critical, services might still work
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
    echo "  • X11 auto-start configuration"
    echo ""
    echo "The image is ready to flash to an SD card!"
    exit 0
else
    echo "❌ VALIDATION FAILED!"
    echo ""
    echo "Some required files or configurations are missing."
    echo ""

    # List missing files explicitly for debugging
    if [ ${#MISSING_FILES[@]} -gt 0 ]; then
        echo "Missing files:"
        for file in "${MISSING_FILES[@]}"; do
            echo "  - ${file}"
        done
        echo ""
    fi

    echo "Please review the build process and try again."
    echo "Check the build logs for errors during stage execution."
    exit 1
fi
