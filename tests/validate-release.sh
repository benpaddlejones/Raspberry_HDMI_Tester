#!/bin/bash
# Validate Raspberry Pi HDMI Tester release image
#
# This script downloads the latest release and validates its contents
# without attempting to boot it (which is unreliable in QEMU for RPi images)

set -e
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Source validation utilities
if [ ! -f "${PROJECT_ROOT}/scripts/validation-utils.sh" ]; then
    echo "❌ Error: validation-utils.sh not found"
    exit 1
fi

# shellcheck source=../scripts/validation-utils.sh
source "${PROJECT_ROOT}/scripts/validation-utils.sh"

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

    # Check prerequisites
    if ! check_gh_auth; then
        return 1
    fi

    if ! check_network; then
        echo "❌ Error: No network connectivity"
        return 1
    fi

    # Get latest release tag
    local latest_tag
    latest_tag=$(get_latest_release_tag)
    local tag_exit=$?
    if [ ${tag_exit} -ne 0 ] || [ -z "${latest_tag}" ]; then
        return 1
    fi

    echo "📦 Latest release: ${latest_tag}"

    # Create test directory
    mkdir -p "${TEST_DIR}" || {
        echo "❌ Error: Failed to create test directory"
        return 1
    }

    cd "${TEST_DIR}" || {
        echo "❌ Error: Failed to change to test directory"
        return 1
    }

    # Check disk space (need ~4GB for download + extraction)
    if ! check_disk_space "${TEST_DIR}" 4096; then
        return 1
    fi

    # Download the image
    echo "⬇️  Downloading image..."
    if ! gh release download "${latest_tag}" -p "*.img.zip" --clobber; then
        echo "❌ Error: Download failed"
        return 1
    fi

    # Find the downloaded ZIP file
    local zip_file
    zip_file=$(find "${TEST_DIR}" -maxdepth 1 -name "*.img.zip" -type f | head -1)

    if [ -z "${zip_file}" ] || [ ! -f "${zip_file}" ]; then
        echo "❌ Error: Downloaded file not found"
        return 1
    fi

    track_temp_file "${zip_file}"

    # Extract the image
    echo "📂 Extracting image..."
    if ! unzip -o "${zip_file}"; then
        echo "❌ Error: Extraction failed"
        return 1
    fi

    # Find the extracted .img file
    local image_file
    image_file=$(find "${TEST_DIR}" -maxdepth 1 -name "*.img" -type f | head -1)

    if [ -z "${image_file}" ] || [ ! -f "${image_file}" ]; then
        echo "❌ Error: No .img file found after extraction"
        return 1
    fi

    # Get absolute path
    image_file=$(readlink -f "${image_file}")
    track_temp_file "${image_file}"

    echo "✅ Image ready: ${image_file}"
    echo "${image_file}"
    return 0
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
    # Get absolute path
    IMAGE_FILE=$(readlink -f "${IMAGE_FILE}")
fi

# Check prerequisites
echo "🔍 Checking prerequisites..."
if ! check_root_or_sudo; then
    exit 1
fi

if ! check_required_commands losetup mount umount mountpoint grep awk unzip; then
    exit 1
fi

if [ ${AUTO_DOWNLOAD} -eq 1 ]; then
    if ! check_required_commands gh jq; then
        exit 1
    fi
fi

echo ""

# Setup cleanup traps
setup_traps

# Download if requested
if [ ${AUTO_DOWNLOAD} -eq 1 ]; then
    IMAGE_FILE=$(download_latest_release)
    DL_EXIT=$?
    if [ ${DL_EXIT} -ne 0 ] || [ -z "${IMAGE_FILE}" ]; then
        exit 1
    fi
fi

echo ""
echo "=================================================="
echo "Validating Raspberry Pi HDMI Tester Image"
echo "=================================================="
echo ""
echo "Image: ${IMAGE_FILE}"
echo ""

# Initialize report
mkdir -p "$(dirname "${REPORT_FILE}")"
{
    echo "=================================================="
    echo "Raspberry Pi HDMI Tester - Image Validation Report"
    echo "=================================================="
    echo "Date: $(date)"
    echo "Image: ${IMAGE_FILE}"
    echo "Image Size: $(du -h "${IMAGE_FILE}" | cut -f1)"
    echo ""
} > "${REPORT_FILE}"

VALIDATION_WARNINGS=0
VALIDATION_ERRORS=0

# Setup loop device
echo "🔧 Setting up loop device..."
LOOP_DEVICE=$(setup_loop_device "${IMAGE_FILE}")
LOOP_EXIT=$?
if [ ${LOOP_EXIT} -ne 0 ] || [ -z "${LOOP_DEVICE}" ]; then
    echo "❌ Failed to setup loop device" | tee -a "${REPORT_FILE}"
    exit 1
fi

echo "✅ Loop device ready: ${LOOP_DEVICE}"
echo ""

# Verify partitions
echo "🔍 Verifying partitions..."
BOOT_PARTITION=$(verify_partition "${LOOP_DEVICE}" 1)
BOOT_EXIT=$?
if [ ${BOOT_EXIT} -ne 0 ] || [ -z "${BOOT_PARTITION}" ]; then
    echo "❌ Boot partition not found" | tee -a "${REPORT_FILE}"
    exit 1
fi
echo "  ✅ Boot partition: ${BOOT_PARTITION}"

ROOT_PARTITION=$(verify_partition "${LOOP_DEVICE}" 2)
ROOT_EXIT=$?
if [ ${ROOT_EXIT} -ne 0 ] || [ -z "${ROOT_PARTITION}" ]; then
    echo "❌ Root partition not found" | tee -a "${REPORT_FILE}"
    exit 1
fi
echo "  ✅ Root partition: ${ROOT_PARTITION}"
echo ""

# Create mount points
BOOT_MOUNT=$(create_temp_dir "/tmp" "boot_mount")
BOOT_MOUNT_EXIT=$?
if [ ${BOOT_MOUNT_EXIT} -ne 0 ] || [ -z "${BOOT_MOUNT}" ]; then
    echo "❌ Failed to create boot mount point" | tee -a "${REPORT_FILE}"
    exit 1
fi

ROOT_MOUNT=$(create_temp_dir "/tmp" "root_mount")
ROOT_MOUNT_EXIT=$?
if [ ${ROOT_MOUNT_EXIT} -ne 0 ] || [ -z "${ROOT_MOUNT}" ]; then
    echo "❌ Failed to create root mount point" | tee -a "${REPORT_FILE}"
    exit 1
fi

# Mount boot partition (FAT32 - partition 1)
echo "📂 Mounting boot partition..."
if ! mount_partition "${BOOT_PARTITION}" "${BOOT_MOUNT}" "vfat"; then
    echo "❌ Failed to mount boot partition" | tee -a "${REPORT_FILE}"
    exit 1
fi
echo "✅ Boot partition mounted"

# Mount root partition (ext4 - partition 2)
echo "📂 Mounting root partition..."
if ! mount_partition "${ROOT_PARTITION}" "${ROOT_MOUNT}" "ext4"; then
    echo "❌ Failed to mount root partition" | tee -a "${REPORT_FILE}"
    exit 1
fi
echo "✅ Root partition mounted"

echo ""
echo "📋 Validating image contents..."
echo ""

# Validation function
validate_file() {
    local file="$1"
    local description="$2"

    if validate_file_readable "${file}"; then
        local size
        size=$(du -h "${file}" 2>/dev/null | cut -f1 || echo "?")
        echo "✅ ${description}: Found (${size})"
        echo "✅ ${description}: Found (${size})" >> "${REPORT_FILE}"
        return 0
    else
        echo "❌ ${description}: NOT FOUND or UNREADABLE"
        echo "❌ ${description}: NOT FOUND or UNREADABLE" >> "${REPORT_FILE}"
        ((VALIDATION_ERRORS++))
        return 1
    fi
}

validate_service() {
    local service="$1"
    local description="$2"
    local target="$3"

    local service_file="${ROOT_MOUNT}/etc/systemd/system/${service}"

    if [ ! -f "${service_file}" ]; then
        echo "❌ ${description}: Service file not found"
        echo "❌ ${description}: Service file not found" >> "${REPORT_FILE}"
        ((VALIDATION_ERRORS++))
        return 1
    fi

    echo "✅ ${description}: Installed"
    echo "✅ ${description}: Installed" >> "${REPORT_FILE}"

    # Check if enabled (via symlink)
    local symlink_path="${ROOT_MOUNT}/etc/systemd/system/${target}.wants/${service}"
    if verify_symlink "${symlink_path}"; then
        echo "   └─ Service is enabled in ${target}"
        echo "   └─ Service is enabled in ${target}" >> "${REPORT_FILE}"
    else
        echo "   └─ ⚠️  Service not enabled in ${target} (may use alternative method)"
        echo "   └─ ⚠️  Service not enabled in ${target} (may use alternative method)" >> "${REPORT_FILE}"
        ((VALIDATION_WARNINGS++))
    fi
    return 0
}

# Check boot configuration
echo "🔍 Boot Configuration:" | tee -a "${REPORT_FILE}"
validate_file "${BOOT_MOUNT}/config.txt" "config.txt"
validate_file "${BOOT_MOUNT}/cmdline.txt" "cmdline.txt"

if [ -f "${BOOT_MOUNT}/config.txt" ]; then
    echo ""
    echo "📝 HDMI Configuration:" | tee -a "${REPORT_FILE}"

    # Check HDMI settings (uncommented only)
    if validate_config_setting "${BOOT_MOUNT}/config.txt" "^[[:space:]]*hdmi_force_hotplug=1"; then
        echo "✅ HDMI force hotplug: Enabled" | tee -a "${REPORT_FILE}"
    else
        echo "❌ HDMI force hotplug: Not configured or commented" | tee -a "${REPORT_FILE}"
        ((VALIDATION_ERRORS++))
    fi

    if validate_config_setting "${BOOT_MOUNT}/config.txt" "^[[:space:]]*hdmi_drive=2"; then
        echo "✅ HDMI audio: Enabled" | tee -a "${REPORT_FILE}"
    else
        echo "❌ HDMI audio: Not configured or commented" | tee -a "${REPORT_FILE}"
        ((VALIDATION_ERRORS++))
    fi

    if validate_config_setting "${BOOT_MOUNT}/config.txt" "^[[:space:]]*hdmi_group=1" && \
       validate_config_setting "${BOOT_MOUNT}/config.txt" "^[[:space:]]*hdmi_mode=16"; then
        echo "✅ HDMI resolution: 1920x1080@60Hz" | tee -a "${REPORT_FILE}"
    else
        echo "⚠️  HDMI resolution: Custom or default (hdmi_group=1 and hdmi_mode=16 recommended)" | tee -a "${REPORT_FILE}"
        ((VALIDATION_WARNINGS++))
    fi
fi

echo ""
echo "🖼️  Test Assets:" | tee -a "${REPORT_FILE}"
validate_file "${ROOT_MOUNT}/opt/hdmi-tester/image.png" "Test pattern image"
validate_file "${ROOT_MOUNT}/opt/hdmi-tester/audio.mp3" "Test audio file"

echo ""
echo "⚙️  Systemd Services:" | tee -a "${REPORT_FILE}"
validate_service "hdmi-display.service" "HDMI Display Service" "multi-user.target"
validate_service "hdmi-audio.service" "HDMI Audio Service" "multi-user.target"

echo ""
echo "📦 Required Packages:" | tee -a "${REPORT_FILE}"

check_package() {
    local package="$1"
    local description="$2"

    # Check if package is installed via dpkg status
    if grep -q "^Package: ${package}$" "${ROOT_MOUNT}/var/lib/dpkg/status" 2>/dev/null && \
       grep -A 1 "^Package: ${package}$" "${ROOT_MOUNT}/var/lib/dpkg/status" 2>/dev/null | \
       grep -q "^Status:.*installed"; then
        echo "✅ ${description}: Installed" | tee -a "${REPORT_FILE}"
        return 0
    else
        echo "❌ ${description}: NOT INSTALLED" | tee -a "${REPORT_FILE}"
        ((VALIDATION_ERRORS++))
        return 1
    fi
}

check_package "mpv" "mpv (audio/video player)"
check_package "alsa-utils" "ALSA utilities"

echo ""
echo "👤 User Configuration:" | tee -a "${REPORT_FILE}"

if grep -q "^pi:" "${ROOT_MOUNT}/etc/passwd"; then
    echo "✅ User 'pi': Exists" | tee -a "${REPORT_FILE}"

    # Check auto-login (multiple possible locations)
    AUTOLOGIN_FOUND=false

    # Method 1: Getty override
    if [ -f "${ROOT_MOUNT}/etc/systemd/system/getty@tty1.service.d/autologin.conf" ] || \
       [ -f "${ROOT_MOUNT}/etc/systemd/system/getty@.service.d/autologin.conf" ]; then
        echo "✅ Auto-login: Configured (getty override)" | tee -a "${REPORT_FILE}"
        AUTOLOGIN_FOUND=true
    fi

    # Method 2: Serial getty
    if [ -f "${ROOT_MOUNT}/etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf" ]; then
        echo "✅ Auto-login: Configured (serial getty)" | tee -a "${REPORT_FILE}"
        AUTOLOGIN_FOUND=true
    fi

    # Method 3: systemd-logind
    if grep -q "NAutoVTs=1" "${ROOT_MOUNT}/etc/systemd/logind.conf" 2>/dev/null; then
        echo "✅ Auto-login: Configured (logind)" | tee -a "${REPORT_FILE}"
        AUTOLOGIN_FOUND=true
    fi

    if [ "${AUTOLOGIN_FOUND}" = false ]; then
        echo "⚠️  Auto-login: Not detected (may use alternative method)" | tee -a "${REPORT_FILE}"
        ((VALIDATION_WARNINGS++))
    fi
else
    echo "❌ User 'pi': NOT FOUND" | tee -a "${REPORT_FILE}"
    ((VALIDATION_ERRORS++))
fi

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
