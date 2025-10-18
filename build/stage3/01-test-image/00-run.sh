#!/bin/bash -e
# Deploy test pattern image

install -d "${ROOTFS_DIR}/opt/hdmi-tester"
install -m 644 files/test-pattern.png "${ROOTFS_DIR}/opt/hdmi-tester/"
chown -R 1000:1000 "${ROOTFS_DIR}/opt/hdmi-tester"
