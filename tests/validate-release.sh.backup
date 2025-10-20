#!/bin/bash
# Validate Raspberry Pi HDMI Tester release image
#
# This script downloads the latest release and validates its contents
# without attempting to boot it (which is unreliable in QEMU for RPi images)

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
TEST_DIR="${PROJECT_ROOT}/build/release-validation"
REPORT_FILE="${TEST_DIR}/validation-report.txt"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [IMAGE_FILE]"
    echo ""
    echo "Validate Raspberry Pi HDMI Tester image contents"
    echo ""
    echo "Options:"
    echo "  --latest, -l    Download latest release from GitHub and validate"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Arguments:"
    echo "  IMAGE_FILE      Path to .img file to validate (optional)"
    echo ""
    echo "Examples:"
    echo "  $0                          # Download and validate latest release"
    echo "  $0 --latest                 # Same as above"
    echo "  $0 my-image.img             # Validate specific image"
    echo ""
    exit 0
}

# Function to download latest release
download_latest_release() {
    echo "🔍 Fetching latest release from GitHub..."

    # Get latest release tag
    LATEST_TAG=$(gh release list --limit 1 --json tagName --jq '.[0].tagName')

    if [ -z "${LATEST_TAG}" ]; then
        echo "❌ Error: No releases found"
        exit 1
    fi

    echo "📦 Latest release: ${LATEST_TAG}"

    # Create test directory
    mkdir -p "${TEST_DIR}"
    cd "${TEST_DIR}"

    # Download the image
    echo "⬇️  Downloading image..."
    gh release download "${LATEST_TAG}" -p "*.img.zip" --clobber

    # Extract the image
    echo "📂 Extracting image..."
    unzip -o *.img.zip

    # Find the extracted .img file
    IMAGE_FILE=$(find . -name "*.img" -type f | head -1)

    if [ -z "${IMAGE_FILE}" ]; then
        echo "❌ Error: No .img file found after extraction"
        exit 1
    fi

    echo "✅ Image ready: ${IMAGE_FILE}"
    echo "${IMAGE_FILE}"
}

# Parse arguments
AUTO_DOWNLOAD=0
IMAGE_FILE=""

if [ $# -eq 0 ]; then
    AUTO_DOWNLOAD=1
elif [ "$1" == "--latest" ] || [ "$1" == "-l" ]; then
    AUTO_DOWNLOAD=1
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_usage
else
    IMAGE_FILE="$1"
    if [ ! -f "${IMAGE_FILE}" ]; then
        echo "❌ Error: Image file not found: ${IMAGE_FILE}"
        exit 1
    fi
fi

# Download if requested
if [ ${AUTO_DOWNLOAD} -eq 1 ]; then
    IMAGE_FILE=$(download_latest_release)
fi

echo ""
echo "=================================================="
echo "Validating Raspberry Pi HDMI Tester Image"
echo "=================================================="
echo ""
echo "Image: ${IMAGE_FILE}"
echo ""

# Initialize report
{
    echo "=================================================="
    echo "Raspberry Pi HDMI Tester - Image Validation Report"
    echo "=================================================="
    echo "Date: $(date)"
    echo "Image: ${IMAGE_FILE}"
    echo "Image Size: $(du -h "${IMAGE_FILE}" | cut -f1)"
    echo ""
} > "${REPORT_FILE}"

VALIDATION_PASSED=0
VALIDATION_WARNINGS=0
VALIDATION_ERRORS=0

# Mount the image partitions
echo "🔧 Mounting image partitions..."

LOOP_DEVICE=$(sudo losetup -f)
sudo losetup -P "${LOOP_DEVICE}" "${IMAGE_FILE}"

BOOT_MOUNT="${TEST_DIR}/boot"
ROOT_MOUNT="${TEST_DIR}/root"
mkdir -p "${BOOT_MOUNT}" "${ROOT_MOUNT}"

# Mount boot partition (FAT32 - partition 1)
if sudo mount "${LOOP_DEVICE}p1" "${BOOT_MOUNT}" 2>/dev/null; then
    echo "✅ Boot partition mounted"
else
    echo "❌ Failed to mount boot partition"
    sudo losetup -d "${LOOP_DEVICE}" 2>/dev/null || true
    exit 1
fi

# Mount root partition (ext4 - partition 2)
if sudo mount "${LOOP_DEVICE}p2" "${ROOT_MOUNT}" 2>/dev/null; then
    echo "✅ Root partition mounted"
else
    echo "❌ Failed to mount root partition"
    sudo umount "${BOOT_MOUNT}" 2>/dev/null || true
    sudo losetup -d "${LOOP_DEVICE}" 2>/dev/null || true
    exit 1
fi

echo ""
echo "📋 Validating image contents..."
echo ""

# Validation function
validate_file() {
    local file="$1"
    local description="$2"

    if [ -f "${file}" ]; then
        local size=$(du -h "${file}" | cut -f1)
        echo "✅ ${description}: Found (${size})"
        echo "✅ ${description}: Found (${size})" >> "${REPORT_FILE}"
        return 0
    else
        echo "❌ ${description}: NOT FOUND"
        echo "❌ ${description}: NOT FOUND" >> "${REPORT_FILE}"
        ((VALIDATION_ERRORS++))
        return 1
    fi
}

validate_service() {
    local service="$1"
    local description="$2"

    if [ -f "${ROOT_MOUNT}/etc/systemd/system/${service}" ]; then
        echo "✅ ${description}: Installed"
        echo "✅ ${description}: Installed" >> "${REPORT_FILE}"

        # Check if enabled
        if [ -L "${ROOT_MOUNT}/etc/systemd/system/graphical.target.wants/${service}" ] || \
           [ -L "${ROOT_MOUNT}/etc/systemd/system/multi-user.target.wants/${service}" ]; then
            echo "   └─ Service is enabled"
            echo "   └─ Service is enabled" >> "${REPORT_FILE}"
        else
            echo "   └─ ⚠️  Service not enabled"
            echo "   └─ ⚠️  Service not enabled" >> "${REPORT_FILE}"
            ((VALIDATION_WARNINGS++))
        fi
        return 0
    else
        echo "❌ ${description}: NOT FOUND"
        echo "❌ ${description}: NOT FOUND" >> "${REPORT_FILE}"
        ((VALIDATION_ERRORS++))
        return 1
    fi
}

# Check boot configuration
echo "🔍 Boot Configuration:" | tee -a "${REPORT_FILE}"
validate_file "${BOOT_MOUNT}/config.txt" "config.txt"
validate_file "${BOOT_MOUNT}/cmdline.txt" "cmdline.txt"

if [ -f "${BOOT_MOUNT}/config.txt" ]; then
    echo ""
    echo "📝 HDMI Configuration:" | tee -a "${REPORT_FILE}"

    if grep -q "hdmi_force_hotplug=1" "${BOOT_MOUNT}/config.txt"; then
        echo "✅ HDMI force hotplug: Enabled" | tee -a "${REPORT_FILE}"
    else
        echo "❌ HDMI force hotplug: Not configured" | tee -a "${REPORT_FILE}"
        ((VALIDATION_ERRORS++))
    fi

    if grep -q "hdmi_drive=2" "${BOOT_MOUNT}/config.txt"; then
        echo "✅ HDMI audio: Enabled" | tee -a "${REPORT_FILE}"
    else
        echo "❌ HDMI audio: Not configured" | tee -a "${REPORT_FILE}"
        ((VALIDATION_ERRORS++))
    fi

    if grep -q "hdmi_group=1" "${BOOT_MOUNT}/config.txt" && grep -q "hdmi_mode=16" "${BOOT_MOUNT}/config.txt"; then
        echo "✅ HDMI resolution: 1920x1080@60Hz" | tee -a "${REPORT_FILE}"
    else
        echo "⚠️  HDMI resolution: Custom or default" | tee -a "${REPORT_FILE}"
        ((VALIDATION_WARNINGS++))
    fi
fi

echo ""
echo "🖼️  Test Assets:" | tee -a "${REPORT_FILE}"
validate_file "${ROOT_MOUNT}/opt/hdmi-tester/image.png" "Test pattern image"
validate_file "${ROOT_MOUNT}/opt/hdmi-tester/audio.mp3" "Test audio file"

echo ""
echo "⚙️  Systemd Services:" | tee -a "${REPORT_FILE}"
validate_service "hdmi-display.service" "HDMI Display Service"
validate_service "hdmi-audio.service" "HDMI Audio Service"

echo ""
echo "📦 Required Packages:" | tee -a "${REPORT_FILE}"

check_package() {
    local package="$1"
    local description="$2"

    if [ -f "${ROOT_MOUNT}/var/lib/dpkg/info/${package}.list" ]; then
        echo "✅ ${description}: Installed" | tee -a "${REPORT_FILE}"
        return 0
    else
        echo "❌ ${description}: NOT INSTALLED" | tee -a "${REPORT_FILE}"
        ((VALIDATION_ERRORS++))
        return 1
    fi
}

check_package "xserver-xorg" "X Server"
check_package "xinit" "X Init"
check_package "feh" "feh (image viewer)"
check_package "mpv" "mpv (media player)"

echo ""
echo "👤 User Configuration:" | tee -a "${REPORT_FILE}"

if grep -q "^pi:" "${ROOT_MOUNT}/etc/passwd"; then
    echo "✅ User 'pi': Exists" | tee -a "${REPORT_FILE}"

    # Check auto-login
    if [ -f "${ROOT_MOUNT}/etc/systemd/system/getty@tty1.service.d/autologin.conf" ]; then
        echo "✅ Auto-login: Configured" | tee -a "${REPORT_FILE}"
    else
        echo "⚠️  Auto-login: Not configured" | tee -a "${REPORT_FILE}"
        ((VALIDATION_WARNINGS++))
    fi
else
    echo "❌ User 'pi': NOT FOUND" | tee -a "${REPORT_FILE}"
    ((VALIDATION_ERRORS++))
fi

# Cleanup
echo ""
echo "🧹 Cleaning up..."
sudo umount "${BOOT_MOUNT}" 2>/dev/null || true
sudo umount "${ROOT_MOUNT}" 2>/dev/null || true
sudo losetup -d "${LOOP_DEVICE}" 2>/dev/null || true
rmdir "${BOOT_MOUNT}" "${ROOT_MOUNT}" 2>/dev/null || true

# Generate summary
echo ""
echo "=================================================="
echo "📊 Validation Summary"
echo "=================================================="

{
    echo ""
    echo "=================================================="
    echo "Validation Summary"
    echo "=================================================="
    echo ""
    echo "Errors: ${VALIDATION_ERRORS}"
    echo "Warnings: ${VALIDATION_WARNINGS}"
    echo ""

    if [ ${VALIDATION_ERRORS} -eq 0 ]; then
        echo "RESULT: ✅ PASSED"
        if [ ${VALIDATION_WARNINGS} -gt 0 ]; then
            echo "Status: Image validation passed with ${VALIDATION_WARNINGS} warning(s)"
        else
            echo "Status: Image validation passed - all checks successful"
        fi
    else
        echo "RESULT: ❌ FAILED"
        echo "Status: Image validation failed with ${VALIDATION_ERRORS} error(s)"
    fi

    echo ""
    echo "=================================================="
    echo "Validation completed at: $(date)"
    echo "=================================================="
} >> "${REPORT_FILE}"

cat "${REPORT_FILE}"

echo ""
echo "📄 Full report saved to: ${REPORT_FILE}"
echo ""

if [ ${VALIDATION_ERRORS} -eq 0 ]; then
    echo "✅ Image validation PASSED"
    exit 0
else
    echo "❌ Image validation FAILED"
    exit 1
fi
