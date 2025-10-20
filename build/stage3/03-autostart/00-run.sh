#!/bin/bash -e
# Install and enable systemd services

# Validate ROOTFS_DIR is set and exists
if [ -z "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR not set"
    exit 1
fi

if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR does not exist: ${ROOTFS_DIR}"
    exit 1
fi

# Install services
install -m 644 files/hdmi-display.service "${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/hdmi-audio.service "${ROOTFS_DIR}/etc/systemd/system/"

# Install troubleshooting script
install -m 755 files/troubleshoot-audio.sh "${ROOTFS_DIR}/usr/local/bin/"

# Install comprehensive audio test script
install -m 755 files/audio-test-comprehensive.sh "${ROOTFS_DIR}/opt/hdmi-tester/"

# Install audio verification script (copy from scripts directory)
install -m 755 "${PWD}/../../scripts/verify-audio.sh" "${ROOTFS_DIR}/usr/local/bin/"

# Enable services
on_chroot << EOF
systemctl enable hdmi-display.service
systemctl enable hdmi-audio.service
EOF

# Configure auto-login for user pi
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
cat > "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/autologin.conf" << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF

# Auto-start X on login
cat >> "${ROOTFS_DIR}/home/pi/.bashrc" << 'EOF'

# Auto-start X server on login (tty1 only)
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec startx
fi
EOF

# Create minimal .xinitrc
cat > "${ROOTFS_DIR}/home/pi/.xinitrc" << 'EOF'
#!/bin/sh
# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Set background to black
xsetroot -solid black

# Window manager not needed - services handle display
exec sleep infinity
EOF

chmod +x "${ROOTFS_DIR}/home/pi/.xinitrc"
chown 1000:1000 "${ROOTFS_DIR}/home/pi/.xinitrc"
