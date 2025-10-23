#!/bin/bash -e
# Deploy test videos (WebM format)

# Validate ROOTFS_DIR is set and exists
if [ -z "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR not set"
    exit 1
fi

if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR does not exist: ${ROOTFS_DIR}"
    exit 1
fi

# Validate ROOTFS_DIR is writable
if [ ! -w "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR is not writable: ${ROOTFS_DIR}"
    exit 1
fi

# Validate source files exist
TEST_VIDEOS=("image-test.webm" "color_test.webm")

for video in "${TEST_VIDEOS[@]}"; do
    if [ ! -f "files/${video}" ]; then
        echo "❌ Error: Source file not found: files/${video}"
        exit 1
    fi
done

# Create directory and install files
install -d "${ROOTFS_DIR}/opt/hdmi-tester"

echo "Deploying test videos..."
for video in "${TEST_VIDEOS[@]}"; do
    install -m 644 -o 1000 -g 1000 "files/${video}" "${ROOTFS_DIR}/opt/hdmi-tester/"
    if [ ! -f "${ROOTFS_DIR}/opt/hdmi-tester/${video}" ]; then
        echo "❌ Error: Failed to copy ${video} to target"
        exit 1
    fi
    echo "  • ${video} deployed"
done

echo "✅ All test videos deployed successfully"
