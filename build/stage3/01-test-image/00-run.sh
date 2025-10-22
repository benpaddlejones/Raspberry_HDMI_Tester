#!/bin/bash -e
# Deploy test pattern image

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

# Validate source file exists
if [ ! -f "files/image.png" ]; then
    echo "❌ Error: Source file not found: files/image.png"
    exit 1
fi

# Create directory and install file
install -d "${ROOTFS_DIR}/opt/hdmi-tester"
install -m 644 -o 1000 -g 1000 files/image.png "${ROOTFS_DIR}/opt/hdmi-tester/"

# Verify file was copied successfully
if [ ! -f "${ROOTFS_DIR}/opt/hdmi-tester/image.png" ]; then
    echo "❌ Error: Failed to copy image.png to target"
    exit 1
fi

echo "✅ Test pattern image deployed successfully"
