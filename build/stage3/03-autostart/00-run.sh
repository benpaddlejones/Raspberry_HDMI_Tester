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

# Validate source files exist before attempting to install
if [ ! -f "files/hdmi-display.service" ]; then
    echo "❌ Error: hdmi-display.service not found"
    exit 1
fi

if [ ! -f "files/hdmi-audio.service" ]; then
    echo "❌ Error: hdmi-audio.service not found"
    exit 1
fi

if [ ! -f "files/troubleshoot-audio.sh" ]; then
    echo "❌ Error: troubleshoot-audio.sh not found"
    exit 1
fi

if [ ! -f "files/audio-test-comprehensive.sh" ]; then
    echo "❌ Error: audio-test-comprehensive.sh not found"
    exit 1
fi

if [ ! -f "files/verify-audio.sh" ]; then
    echo "❌ Error: verify-audio.sh not found"
    exit 1
fi

# Ensure target directories exist
mkdir -p "${ROOTFS_DIR}/etc/systemd/system"
mkdir -p "${ROOTFS_DIR}/usr/local/bin"
mkdir -p "${ROOTFS_DIR}/opt/hdmi-tester"

# Install systemd services
install -m 644 files/hdmi-display.service "${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/hdmi-audio.service "${ROOTFS_DIR}/etc/systemd/system/"

# Install troubleshooting scripts (keep for diagnostics)
install -m 755 files/troubleshoot-audio.sh "${ROOTFS_DIR}/usr/local/bin/"
install -m 755 files/audio-test-comprehensive.sh "${ROOTFS_DIR}/opt/hdmi-tester/"
install -m 755 files/verify-audio.sh "${ROOTFS_DIR}/usr/local/bin/"

# Enable services to start on boot
on_chroot << 'EOF'
systemctl enable hdmi-display.service
systemctl enable hdmi-audio.service
EOF

# Verify services were enabled successfully
if ! on_chroot systemctl is-enabled hdmi-display.service >/dev/null 2>&1; then
    echo "❌ Error: Failed to enable hdmi-display.service"
    exit 1
fi

if ! on_chroot systemctl is-enabled hdmi-audio.service >/dev/null 2>&1; then
    echo "❌ Error: Failed to enable hdmi-audio.service"
    exit 1
fi

# Configure auto-login for user pi on tty1
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
cat > "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/autologin.conf" << 'AUTOLOGIN_EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
AUTOLOGIN_EOF

# Verify autologin was configured
if [ ! -f "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/autologin.conf" ]; then
    echo "❌ Error: Failed to create autologin configuration"
    exit 1
fi

# Set correct ownership
chown -R 1000:1000 "${ROOTFS_DIR}/home/pi"

echo "✅ HDMI tester services installed and enabled (console mode)"
