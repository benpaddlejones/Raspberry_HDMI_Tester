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

install -d "${ROOTFS_DIR}/opt/hdmi-tester"
install -m 644 files/image.png "${ROOTFS_DIR}/opt/hdmi-tester/"
chown -R 1000:1000 "${ROOTFS_DIR}/opt/hdmi-tester"
