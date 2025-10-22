#!/bin/bash -e
# Deploy audio test file

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
if [ ! -f "files/audio.mp3" ]; then
    echo "❌ Error: Source file not found: files/audio.mp3"
    exit 1
fi

# Ensure directory exists (in case stage01 hasn't run)
install -d "${ROOTFS_DIR}/opt/hdmi-tester"

# Install audio file with proper ownership
install -m 644 -o 1000 -g 1000 files/audio.mp3 "${ROOTFS_DIR}/opt/hdmi-tester/"

# Verify file was copied successfully
if [ ! -f "${ROOTFS_DIR}/opt/hdmi-tester/audio.mp3" ]; then
    echo "❌ Error: Failed to copy audio.mp3 to target"
    exit 1
fi

echo "✅ Test audio file deployed successfully"
