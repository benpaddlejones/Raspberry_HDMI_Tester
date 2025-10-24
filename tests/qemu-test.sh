#!/bin/bash
# Test Raspberry Pi image in QEMU emulator
#
# This script can automatically download the latest release from GitHub
# and run comprehensive boot tests with detailed reporting.
#
# Usage:
#   ./qemu-test.sh              # Download latest release and test
#   ./qemu-test.sh --latest     # Download latest release and test
#   ./qemu-test.sh <image.img>  # Test a specific image file
#   ./qemu-test.sh --help       # Show this help

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

TEST_DIR="${PROJECT_ROOT}/build/qemu-testing"
REPORT_FILE="${TEST_DIR}/qemu-test-report.txt"
BOOT_LOG="${TEST_DIR}/boot.log"
TIMEOUT_SECONDS=120

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [IMAGE_FILE]"
    echo ""
    echo "Test Raspberry Pi HDMI Tester image in QEMU emulator"
    echo ""
    echo "Options:"
    echo "  --latest, -l    Download latest release from GitHub and test"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Arguments:"
    echo "  IMAGE_FILE      Path to .img file to test (optional)"
    echo ""
    echo "Examples:"
    echo "  $0                          # Download and test latest release"
    echo "  $0 --latest                 # Same as above"
    echo "  $0 my-image.img             # Test specific image"
    echo ""
    echo "Output:"
    echo "  - Test report: build/qemu-testing/qemu-test-report.txt"
    echo "  - Boot log: build/qemu-testing/boot.log"
    echo ""
    echo "⚠️  Note: QEMU has significant limitations for Raspberry Pi:"
    echo "  - No framebuffer emulation (HDMI services will fail)"
    echo "  - Limited hardware emulation"
    echo "  - Boot test only verifies kernel/init system"
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

    # Check disk space
    if ! check_disk_space "${TEST_DIR}" 4096; then
        return 1
    fi

    # Download the image
    echo "⬇️  Downloading image..."
    if ! gh release download "${latest_tag}" -p "*.img.zip" --clobber; then
        echo "❌ Error: Download failed"
        return 1
    fi

    # Find and extract
    local zip_file
    zip_file=$(find "${TEST_DIR}" -maxdepth 1 -name "*.img.zip" -type f | head -1)

    if [ -z "${zip_file}" ] || [ ! -f "${zip_file}" ]; then
        echo "❌ Error: Downloaded file not found"
        return 1
    fi

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
        echo ""
        echo "Run '$0 --help' for usage information"
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

if ! check_required_commands qemu-system-arm losetup mount umount; then
    exit 1
fi

if [ ${AUTO_DOWNLOAD} -eq 1 ]; then
    if ! check_required_commands gh jq unzip; then
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

echo "=================================================="
echo "Testing Raspberry Pi Image in QEMU"
echo "=================================================="
echo ""
echo "Image: ${IMAGE_FILE}"
echo "Report: ${REPORT_FILE}"
echo ""
echo "⚠️  Note: QEMU limitations:"
echo "   - HDMI output won't be visible (no framebuffer emulation)"
echo "   - Audio won't play"
echo "   - This only tests if the system boots"
echo ""

# Initialize report
mkdir -p "${TEST_DIR}"
{
    echo "=================================================="
    echo "QEMU Boot Test Report"
    echo "=================================================="
    echo "Date: $(date)"
    echo "Image: ${IMAGE_FILE}"
    echo "Image Size: $(du -h "${IMAGE_FILE}" | cut -f1)"
    echo "Test Timeout: ${TIMEOUT_SECONDS} seconds"
    echo ""
} > "${REPORT_FILE}"

# Setup loop device and mount
echo "🔧 Setting up loop device..."
LOOP_DEVICE=$(setup_loop_device "${IMAGE_FILE}")
LOOP_EXIT=$?
if [ ${LOOP_EXIT} -ne 0 ] || [ -z "${LOOP_DEVICE}" ]; then
    echo "❌ Failed to setup loop device" | tee -a "${REPORT_FILE}"
    exit 1
fi

echo "✅ Loop device ready: ${LOOP_DEVICE}"
echo ""

# Verify boot partition
BOOT_PARTITION=$(verify_partition "${LOOP_DEVICE}" 1)
BOOT_EXIT=$?
if [ ${BOOT_EXIT} -ne 0 ] || [ -z "${BOOT_PARTITION}" ]; then
    echo "❌ Boot partition not found" | tee -a "${REPORT_FILE}"
    exit 1
fi

# Mount boot partition
BOOT_MOUNT=$(create_temp_dir "/tmp" "boot_mount")
BOOT_MOUNT_EXIT=$?
if [ ${BOOT_MOUNT_EXIT} -ne 0 ] || [ -z "${BOOT_MOUNT}" ]; then
    echo "❌ Failed to create boot mount point" | tee -a "${REPORT_FILE}"
    exit 1
fi
echo "📂 Mounting boot partition..."
if ! mount_partition "${BOOT_PARTITION}" "${BOOT_MOUNT}" "vfat"; then
    echo "❌ Failed to mount boot partition" | tee -a "${REPORT_FILE}"
    exit 1
fi

echo "✅ Boot partition mounted"
echo ""

# Extract kernel from image
echo "🔧 Extracting kernel from image..."

KERNEL_FILE="${TEST_DIR}/kernel.img"
DTB_FILE="${TEST_DIR}/device-tree.dtb"

track_temp_file "${KERNEL_FILE}"
track_temp_file "${DTB_FILE}"

# Look for various kernel versions (Pi 4/5 use kernel8, Pi 2/3 use kernel7, Pi 1 uses kernel)
KERNEL_FOUND=false
for kernel_name in kernel8.img kernel7l.img kernel7.img kernel.img; do
    if [ -f "${BOOT_MOUNT}/${kernel_name}" ]; then
        if ! sudo cp "${BOOT_MOUNT}/${kernel_name}" "${KERNEL_FILE}"; then
            echo "❌ Failed to copy kernel" | tee -a "${REPORT_FILE}"
            exit 1
        fi
        sudo chmod 644 "${KERNEL_FILE}"

        # Validate kernel was copied successfully and is readable
        if [ ! -f "${KERNEL_FILE}" ]; then
            echo "❌ Kernel file not found after copy" | tee -a "${REPORT_FILE}"
            exit 1
        fi

        if [ ! -r "${KERNEL_FILE}" ]; then
            echo "❌ Kernel file not readable" | tee -a "${REPORT_FILE}"
            exit 1
        fi

        if [ ! -s "${KERNEL_FILE}" ]; then
            echo "❌ Kernel file is empty" | tee -a "${REPORT_FILE}"
            exit 1
        fi

        # HIGH PRIORITY FIX: Validate kernel size and integrity
        KERNEL_SIZE_BYTES=$(stat -c%s "${KERNEL_FILE}")
        KERNEL_SIZE_HUMAN=$(du -h "${KERNEL_FILE}" | cut -f1)

        # Raspberry Pi kernels are typically 10-30MB
        if [ ${KERNEL_SIZE_BYTES} -lt 10000000 ]; then
            echo "⚠️  Warning: Kernel file seems too small (${KERNEL_SIZE_HUMAN})" | tee -a "${REPORT_FILE}"
            echo "   Expected size: >10MB, actual: ${KERNEL_SIZE_BYTES} bytes" | tee -a "${REPORT_FILE}"
            echo "   QEMU boot may fail due to incomplete kernel extraction" | tee -a "${REPORT_FILE}"
        elif [ ${KERNEL_SIZE_BYTES} -gt 50000000 ]; then
            echo "⚠️  Warning: Kernel file seems unusually large (${KERNEL_SIZE_HUMAN})" | tee -a "${REPORT_FILE}"
        else
            echo "✅ Kernel size validated: ${KERNEL_SIZE_HUMAN} (${KERNEL_SIZE_BYTES} bytes)"
        fi

        # Try to verify kernel is actually a kernel file (basic check)
        if command -v file &>/dev/null; then
            KERNEL_TYPE=$(file "${KERNEL_FILE}" | grep -i "kernel\|boot\|ARM\|executable" || true)
            if [ -n "${KERNEL_TYPE}" ]; then
                echo "✅ Kernel type check passed: ${KERNEL_TYPE}"
            else
                echo "⚠️  Warning: Kernel file type check inconclusive" | tee -a "${REPORT_FILE}"
            fi
        fi

        echo "✅ Extracted ${kernel_name} (${KERNEL_SIZE_HUMAN})"
        KERNEL_FOUND=true
        break
    fi
done

if [ "${KERNEL_FOUND}" = false ]; then
    echo "❌ No kernel found in boot partition" | tee -a "${REPORT_FILE}"
    echo "RESULT: FAILED - No kernel found in image" >> "${REPORT_FILE}"
    exit 1
fi

# Copy device tree blob if available (try multiple models)
DTB_FOUND=false
for dtb_name in bcm2711-rpi-4-b.dtb bcm2710-rpi-3-b-plus.dtb bcm2710-rpi-3-b.dtb bcm2709-rpi-2-b.dtb; do
    if [ -f "${BOOT_MOUNT}/${dtb_name}" ]; then
        if sudo cp "${BOOT_MOUNT}/${dtb_name}" "${DTB_FILE}"; then
            sudo chmod 644 "${DTB_FILE}"
            echo "✅ Extracted device tree: ${dtb_name}"
            DTB_FOUND=true
            break
        fi
    fi
done

if [ "${DTB_FOUND}" = false ]; then
    echo "⚠️  No device tree blob found (will boot without DTB)"
fi

echo ""

# Boot log initialization
{
    echo "Boot started at: $(date)"
    echo "Kernel: ${KERNEL_FILE}"
    if [ "${DTB_FOUND}" = true ]; then
        echo "DTB: ${DTB_FILE}"
    fi
    echo "=================================================="
} > "${BOOT_LOG}"

track_temp_file "${BOOT_LOG}"

echo "🚀 Starting QEMU emulation (timeout: ${TIMEOUT_SECONDS}s)..."
echo "   Boot log: ${BOOT_LOG}"
echo ""
echo "⚠️  Important: QEMU will likely show errors for HDMI/framebuffer services"
echo "   This is expected - we're only testing boot to login prompt"
echo ""

# Prepare QEMU command
# Note: Using versatilepb is not ideal but it's the most compatible
# Real Pi hardware would be needed for full testing
QEMU_ARGS=(
    -M versatilepb
    -cpu arm1176
    -m 256
    -kernel "${KERNEL_FILE}"
)

if [ "${DTB_FOUND}" = true ]; then
    QEMU_ARGS+=(-dtb "${DTB_FILE}")
fi

QEMU_ARGS+=(
    -drive "file=${IMAGE_FILE},format=raw,if=scsi"
    -append "root=/dev/sda2 rootfstype=ext4 rw console=ttyAMA0,115200 console=tty1 loglevel=3"
    -serial stdio
    -no-reboot
    -nographic
)

# CRITICAL FIX: Improved QEMU cleanup function
cleanup_qemu() {
    if [ -n "${QEMU_PID:-}" ] && kill -0 "${QEMU_PID}" 2>/dev/null; then
        echo "🛑 Stopping QEMU (PID: ${QEMU_PID})..."
        kill -TERM "${QEMU_PID}" 2>/dev/null || true

        # Wait up to 3 seconds for graceful shutdown
        local wait_count=0
        while [ ${wait_count} -lt 3 ] && kill -0 "${QEMU_PID}" 2>/dev/null; do
            sleep 1
            wait_count=$((wait_count + 1))
        done

        # Force kill if still running
        if kill -0 "${QEMU_PID}" 2>/dev/null; then
            echo "⚠️  QEMU still running, forcing kill..."
            kill -KILL "${QEMU_PID}" 2>/dev/null || true
            sleep 1
        fi

        echo "✅ QEMU process terminated"
    fi
}

# Run QEMU with timeout
set +e  # Disable exit on error for QEMU run
timeout ${TIMEOUT_SECONDS} qemu-system-arm "${QEMU_ARGS[@]}" 2>&1 | tee -a "${BOOT_LOG}" &
QEMU_PID=$!
set -e

# Monitor boot process
echo "⏱️  Monitoring boot process (PID: ${QEMU_PID})..."
BOOT_START=$(date +%s)
BOOT_SUCCESS=0
CHECK_INTERVAL=2

while kill -0 ${QEMU_PID} 2>/dev/null; do
    sleep ${CHECK_INTERVAL}
    ELAPSED=$(($(date +%s) - BOOT_START))

    # MEDIUM PRIORITY FIX: Check for successful boot with multiple fallback patterns
    if grep -Eqi "login:|Welcome to|Raspberry Pi|raspberrypi login:" "${BOOT_LOG}" 2>/dev/null; then
        BOOT_SUCCESS=1
        echo ""
        echo "✅ Boot successful! System reached userspace after ${ELAPSED}s"
        cleanup_qemu
        break
    fi

    # Check for kernel panic
    if grep -qi "kernel panic\|Kernel panic" "${BOOT_LOG}" 2>/dev/null; then
        echo ""
        echo "❌ Kernel panic detected!"
        cleanup_qemu
        break
    fi

    # Check for critical failures
    if grep -qi "emergency mode\|Failed to mount" "${BOOT_LOG}" 2>/dev/null; then
        echo ""
        echo "❌ Critical boot failure detected"
        cleanup_qemu
        break
    fi

    # Progress indicator
    if [ $((ELAPSED % 10)) -eq 0 ] && [ ${ELAPSED} -gt 0 ]; then
        echo "   ... ${ELAPSED}s elapsed (waiting for login prompt)"
    fi
done

# Wait for QEMU to fully terminate
wait ${QEMU_PID} 2>/dev/null || true

# Generate report
echo ""
echo "=================================================="
echo "📊 Test Results"
echo "=================================================="

{
    echo ""
    echo "=================================================="
    echo "Test Results"
    echo "=================================================="
    echo ""

    if [ ${BOOT_SUCCESS} -eq 1 ]; then
        echo "RESULT: ✅ PASSED (with limitations)"
        echo "Status: System booted to userspace successfully"
        echo "Boot Time: ${ELAPSED} seconds"
        echo ""
        echo "Note: QEMU test only validates:"
        echo "  - Kernel loads and boots"
        echo "  - Init system starts"
        echo "  - System reaches login prompt"
        echo ""
        echo "QEMU cannot test:"
        echo "  - HDMI output (no framebuffer emulation)"
        echo "  - Audio functionality"
        echo "  - Pi-specific hardware features"
        echo ""
        echo "For complete validation, test on actual Raspberry Pi hardware"
    else
        echo "RESULT: ❌ FAILED or TIMEOUT"
        echo "Status: Boot did not complete within ${TIMEOUT_SECONDS}s timeout"
        echo ""
        echo "This may indicate:"
        echo "  - Kernel incompatibility with QEMU"
        echo "  - Init system issues"
        echo "  - Image corruption"
        echo ""
        echo "Check boot log for details: ${BOOT_LOG}"
    fi

    echo ""
    echo "Boot Log Analysis:"
    echo "----------------------------------------"

    # Service detection (informational only, may fail in QEMU)
    if grep -qi "hdmi-test.service\|pixel-test.service\|audio-test.service\|full-test.service" "${BOOT_LOG}" 2>/dev/null; then
        echo "ℹ️  HDMI test service(s) mentioned (may have failed in QEMU - expected)"
    fi

    # Error analysis
    if grep -qi "kernel panic" "${BOOT_LOG}" 2>/dev/null; then
        echo "❌ Kernel panic detected"
    else
        echo "✅ No kernel panic"
    fi

    ERROR_COUNT=$(grep -ci "\[error\]\|error:" "${BOOT_LOG}" 2>/dev/null || echo "0")
    WARNING_COUNT=$(grep -ci "\[warn\]\|warning:" "${BOOT_LOG}" 2>/dev/null || echo "0")
    FAILED_COUNT=$(grep -ci "failed to start\|failed" "${BOOT_LOG}" 2>/dev/null || echo "0")

    echo ""
    echo "Message Summary:"
    echo "  Errors: ${ERROR_COUNT}"
    echo "  Warnings: ${WARNING_COUNT}"
    echo "  Failed: ${FAILED_COUNT}"
    echo ""
    echo "Note: Errors/warnings for GPU/HDMI/audio are expected in QEMU"

    echo ""
    echo "=================================================="
    echo "Test completed at: $(date)"
    echo "=================================================="

} >> "${REPORT_FILE}"

# Display report
cat "${REPORT_FILE}"

echo ""
echo "📄 Full boot log saved to: ${BOOT_LOG}"
echo "📄 Test report saved to: ${REPORT_FILE}"
echo ""

if [ ${BOOT_SUCCESS} -eq 1 ]; then
    echo "✅ QEMU test PASSED (with limitations)"
    echo ""
    echo "⚠️  Important: Test on actual Raspberry Pi hardware for complete validation"
    exit 0
else
    echo "❌ QEMU test FAILED or TIMEOUT"
    echo ""
    echo "Check the boot log for details: ${BOOT_LOG}"
    exit 1
fi
