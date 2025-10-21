#!/bin/bash -e
# Configure auto-start for HDMI tester (console mode, no X11/Wayland)

# Validate ROOTFS_DIR is set and exists
if [ -z "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR not set"
    exit 1
fi

if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR does not exist: ${ROOTFS_DIR}"
    exit 1
fi

echo "🔧 Installing HDMI tester services (console mode)..."

# Install systemd services
install -m 644 files/hdmi-display.service "${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/hdmi-audio.service "${ROOTFS_DIR}/etc/systemd/system/"

# Install troubleshooting scripts (keep for diagnostics)
install -m 755 files/troubleshoot-audio.sh "${ROOTFS_DIR}/usr/local/bin/"
install -m 755 files/audio-test-comprehensive.sh "${ROOTFS_DIR}/opt/hdmi-tester/"
install -m 755 files/verify-audio.sh "${ROOTFS_DIR}/usr/local/bin/"

# Enable services to start on boot
on_chroot << EOF
systemctl enable hdmi-display.service
systemctl enable hdmi-audio.service
EOF

# Configure auto-login for user pi on tty1
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
cat > "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/autologin.conf" << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF

# Set correct ownership
chown -R 1000:1000 "${ROOTFS_DIR}/home/pi"

echo "✅ HDMI tester services installed and enabled (console mode)"
