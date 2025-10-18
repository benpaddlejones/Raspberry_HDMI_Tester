#!/bin/bash -e
# Deploy audio test file

install -m 644 files/test-audio.mp3 "${ROOTFS_DIR}/opt/hdmi-tester/"
chown 1000:1000 "${ROOTFS_DIR}/opt/hdmi-tester/test-audio.mp3"
