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

# Ensure directory exists (in case stage01 hasn't run)
install -d "${ROOTFS_DIR}/opt/hdmi-tester"

install -m 644 files/audio.mp3 "${ROOTFS_DIR}/opt/hdmi-tester/"
chown 1000:1000 "${ROOTFS_DIR}/opt/hdmi-tester/audio.mp3"
