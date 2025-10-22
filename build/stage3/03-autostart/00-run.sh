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

# Ensure target directories exist
mkdir -p "${ROOTFS_DIR}/etc/systemd/system"

# Install systemd services
install -m 644 files/hdmi-display.service "${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/hdmi-audio.service "${ROOTFS_DIR}/etc/systemd/system/"

# Enable services to start on boot
on_chroot << 'EOF'
systemctl enable hdmi-display.service
systemctl enable hdmi-audio.service
EOF

# Verify services were enabled successfully by checking for symlinks
# NOTE: We check for symlink existence instead of using `systemctl is-enabled`
# because systemd/D-Bus are not running in the chroot environment during build.
# The symlinks are what actually enable the services; if systemctl enable succeeded
# and the symlinks exist, the services are properly enabled.
if [ ! -L "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/hdmi-display.service" ]; then
    echo "❌ Error: Failed to enable hdmi-display.service (symlink not created)"
    exit 1
fi

if [ ! -L "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/hdmi-audio.service" ]; then
    echo "❌ Error: Failed to enable hdmi-audio.service (symlink not created)"
    exit 1
fi

echo "✅ Services enabled successfully (verified symlinks)"

# NOTE: Alternative verification using systemctl is-enabled (disabled for chroot):
# The following check would work on a running system but fails in chroot because
# systemd is not running and D-Bus socket is not available:
#
# if ! on_chroot systemctl is-enabled hdmi-display.service >/dev/null 2>&1; then
#     echo "❌ Error: Failed to enable hdmi-display.service"
#     exit 1
# fi
#
# This is a known limitation of systemd in chroot environments. Checking for
# symlink existence is the robust approach for build-time verification.

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
