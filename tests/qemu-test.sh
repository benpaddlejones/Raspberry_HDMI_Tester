#!/bin/bash
# Test Raspberry Pi image in QEMU emulator

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <image_file.img>"
    echo ""
    echo "This script tests the Raspberry Pi HDMI Tester image in QEMU."
    echo "Note: QEMU emulation is limited and won't show HDMI output,"
    echo "but it will verify that the image boots successfully."
    echo ""
    echo "Example: $0 build/pi-gen-work/deploy/image.img"
    exit 1
fi

IMAGE_FILE="$1"

if [ ! -f "${IMAGE_FILE}" ]; then
    echo "❌ Error: Image file not found: ${IMAGE_FILE}"
    exit 1
fi

echo "=================================================="
echo "Testing Raspberry Pi Image in QEMU"
echo "=================================================="
echo ""
echo "Image: ${IMAGE_FILE}"
echo ""
echo "⚠️  Note: QEMU limitations:"
echo "   - HDMI output won't be visible"
echo "   - Audio won't play"
echo "   - This only tests if the image boots"
echo ""
echo "Starting QEMU emulation..."
echo "Press Ctrl+C to stop"
echo ""

# Check if qemu-system-arm is available
if ! command -v qemu-system-arm &> /dev/null; then
    echo "❌ Error: qemu-system-arm not found"
    echo "Install with: sudo apt-get install qemu-system-arm"
    exit 1
fi

# Check for kernel file
KERNEL_FILE="/usr/share/qemu/qemu-arm-kernel"
if [ ! -f "${KERNEL_FILE}" ]; then
    echo "⚠️  Warning: QEMU kernel not found at ${KERNEL_FILE}"
    echo "This test may not work properly."
    echo ""
fi

# Run QEMU with Raspberry Pi emulation
qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256 \
    -kernel "${KERNEL_FILE}" \
    -hda "${IMAGE_FILE}" \
    -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw" \
    -serial stdio \
    -no-reboot \
    -nographic

echo ""
echo "QEMU emulation stopped."
