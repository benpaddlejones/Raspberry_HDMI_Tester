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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
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
        echo ""
        echo "Run '$0 --help' for usage information"
        exit 1
    fi
fi

# Download if requested
if [ ${AUTO_DOWNLOAD} -eq 1 ]; then
    IMAGE_FILE=$(download_latest_release)
fi

echo "=================================================="
echo "Testing Raspberry Pi Image in QEMU"
echo "=================================================="
echo ""
echo "Image: ${IMAGE_FILE}"
echo "Report: ${REPORT_FILE}"
echo ""
echo "⚠️  Note: QEMU limitations:"
echo "   - HDMI output won't be visible"
echo "   - Audio won't play"
echo "   - This only tests if the image boots"
echo ""

# Initialize report
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

# Check if qemu-system-arm is available
if ! command -v qemu-system-arm &> /dev/null; then
    echo "❌ Error: qemu-system-arm not found"
    echo "Install with: sudo apt-get install qemu-system-arm"
    echo "RESULT: FAILED - qemu-system-arm not installed" >> "${REPORT_FILE}"
    exit 1
fi

# Extract kernel from image if needed
KERNEL_FILE="${TEST_DIR}/kernel.img"
DTB_FILE="${TEST_DIR}/bcm2710-rpi-3-b.dtb"

echo "🔧 Extracting kernel from image..."

# Mount the boot partition to extract kernel
LOOP_DEVICE=$(sudo losetup -f)
sudo losetup -P "${LOOP_DEVICE}" "${IMAGE_FILE}"

# Create mount point
MOUNT_POINT="${TEST_DIR}/boot_mount"
mkdir -p "${MOUNT_POINT}"

# Mount boot partition (usually partition 1)
sudo mount "${LOOP_DEVICE}p1" "${MOUNT_POINT}" 2>/dev/null || {
    echo "❌ Failed to mount boot partition"
    sudo losetup -d "${LOOP_DEVICE}" 2>/dev/null || true
    echo "RESULT: FAILED - Cannot mount boot partition" >> "${REPORT_FILE}"
    exit 1
}

# Copy kernel and DTB files
if [ -f "${MOUNT_POINT}/kernel8.img" ]; then
    sudo cp "${MOUNT_POINT}/kernel8.img" "${KERNEL_FILE}"
    echo "✅ Extracted kernel8.img"
elif [ -f "${MOUNT_POINT}/kernel7.img" ]; then
    sudo cp "${MOUNT_POINT}/kernel7.img" "${KERNEL_FILE}"
    echo "✅ Extracted kernel7.img"
else
    echo "❌ No kernel found in boot partition"
    sudo umount "${MOUNT_POINT}" 2>/dev/null || true
    sudo losetup -d "${LOOP_DEVICE}" 2>/dev/null || true
    echo "RESULT: FAILED - No kernel found in image" >> "${REPORT_FILE}"
    exit 1
fi

# Copy device tree blob if available
if [ -f "${MOUNT_POINT}/bcm2710-rpi-3-b.dtb" ]; then
    sudo cp "${MOUNT_POINT}/bcm2710-rpi-3-b.dtb" "${DTB_FILE}"
    echo "✅ Extracted device tree blob"
fi

# Clean up mounts
sudo umount "${MOUNT_POINT}" 2>/dev/null || true
sudo losetup -d "${LOOP_DEVICE}" 2>/dev/null || true
rmdir "${MOUNT_POINT}" 2>/dev/null || true

# Make kernel readable
sudo chmod 644 "${KERNEL_FILE}"
[ -f "${DTB_FILE}" ] && sudo chmod 644 "${DTB_FILE}"

echo "✅ Kernel extraction complete"
echo ""

echo "🚀 Starting QEMU emulation (timeout: ${TIMEOUT_SECONDS}s)..."
echo "   Boot log: ${BOOT_LOG}"
echo ""

# Run QEMU with timeout and capture output
{
    echo "Boot started at: $(date)"
    echo "Kernel: ${KERNEL_FILE}"
    echo "=================================================="
} > "${BOOT_LOG}"

# Prepare QEMU command with DTB if available
QEMU_ARGS=(
    -M versatilepb
    -cpu arm1176
    -m 256
    -kernel "${KERNEL_FILE}"
)

if [ -f "${DTB_FILE}" ]; then
    QEMU_ARGS+=(-dtb "${DTB_FILE}")
fi

QEMU_ARGS+=(
    -drive "file=${IMAGE_FILE},format=raw"
    -append "root=/dev/sda2 rootfstype=ext4 rw console=ttyAMA0,115200 console=tty1"
    -serial stdio
    -no-reboot
    -nographic
)

timeout ${TIMEOUT_SECONDS} qemu-system-arm "${QEMU_ARGS[@]}" 2>&1 | tee -a "${BOOT_LOG}" &

QEMU_PID=$!

# Monitor boot process
echo "⏱️  Monitoring boot process (PID: ${QEMU_PID})..."
BOOT_START=$(date +%s)
BOOT_SUCCESS=0
CHECK_INTERVAL=2

while kill -0 ${QEMU_PID} 2>/dev/null; do
    sleep ${CHECK_INTERVAL}
    ELAPSED=$(($(date +%s) - BOOT_START))

    # Check for successful boot indicators
    if grep -qi "login:" "${BOOT_LOG}" 2>/dev/null; then
        BOOT_SUCCESS=1
        echo "✅ Boot successful! Login prompt detected after ${ELAPSED}s"
        kill ${QEMU_PID} 2>/dev/null || true
        break
    fi

    # Check for kernel panic
    if grep -qi "kernel panic" "${BOOT_LOG}" 2>/dev/null; then
        echo "❌ Kernel panic detected!"
        kill ${QEMU_PID} 2>/dev/null || true
        break
    fi

    # Check for systemd failures
    if grep -qi "systemd.*failed" "${BOOT_LOG}" 2>/dev/null; then
        echo "⚠️  systemd failures detected (may still boot)"
    fi

    # Progress indicator
    if [ $((ELAPSED % 10)) -eq 0 ]; then
        echo "   ... ${ELAPSED}s elapsed"
    fi
done

wait ${QEMU_PID} 2>/dev/null || true

# Generate report
echo ""
echo "=================================================="
echo "📊 Test Results"
echo "=================================================="

{
    echo "=================================================="
    echo "Test Results"
    echo "=================================================="
    echo ""

    if [ ${BOOT_SUCCESS} -eq 1 ]; then
        echo "RESULT: ✅ PASSED"
        echo "Status: Boot completed successfully"
        echo "Boot Time: ${ELAPSED} seconds"
    else
        echo "RESULT: ❌ FAILED"
        echo "Status: Boot did not complete within timeout"
    fi

    echo ""
    echo "Boot Log Analysis:"
    echo "----------------------------------------"

    # Check for key components
    if grep -qi "hdmi-display.service" "${BOOT_LOG}" 2>/dev/null; then
        echo "✅ hdmi-display.service detected"
    else
        echo "❌ hdmi-display.service NOT detected"
    fi

    if grep -qi "hdmi-audio.service" "${BOOT_LOG}" 2>/dev/null; then
        echo "✅ hdmi-audio.service detected"
    else
        echo "❌ hdmi-audio.service NOT detected"
    fi

    if grep -qi "kernel panic" "${BOOT_LOG}" 2>/dev/null; then
        echo "❌ Kernel panic detected"
    else
        echo "✅ No kernel panic"
    fi

    ERROR_COUNT=$(grep -ci "error" "${BOOT_LOG}" 2>/dev/null || echo "0")
    WARNING_COUNT=$(grep -ci "warning" "${BOOT_LOG}" 2>/dev/null || echo "0")
    FAILED_COUNT=$(grep -ci "failed" "${BOOT_LOG}" 2>/dev/null || echo "0")

    echo ""
    echo "Error Summary:"
    echo "  Errors: ${ERROR_COUNT}"
    echo "  Warnings: ${WARNING_COUNT}"
    echo "  Failed: ${FAILED_COUNT}"

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
    echo "✅ QEMU test PASSED"
    exit 0
else
    echo "❌ QEMU test FAILED"
    exit 1
fi
