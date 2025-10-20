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

# Install audio verification script
install -m 755 files/verify-audio.sh "${ROOTFS_DIR}/usr/local/bin/"

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

# Auto-start Wayland compositor on login
cat >> "${ROOTFS_DIR}/home/pi/.bashrc" << 'EOF'

# Auto-start Wayland compositor on login (tty1 only)
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    export XDG_RUNTIME_DIR=/run/user/1000
    export WLR_BACKENDS=drm
    export WLR_RENDERER=gles2
    export WLR_DRM_NO_MODIFIERS=1
    # Start a minimal Wayland compositor
    exec labwc
fi
EOF

# Create labwc configuration directory
mkdir -p "${ROOTFS_DIR}/home/pi/.config/labwc"

# Create minimal labwc configuration
cat > "${ROOTFS_DIR}/home/pi/.config/labwc/rc.xml" << 'EOF'
<?xml version="1.0"?>
<labwc_config>
  <core>
    <decoration>no</decoration>
    <gap>0</gap>
  </core>
  <theme>
    <name>none</name>
  </theme>
  <keyboard>
    <default />
  </keyboard>
  <mouse>
    <default />
  </mouse>
</labwc_config>
EOF

# Create autostart for labwc
cat > "${ROOTFS_DIR}/home/pi/.config/labwc/autostart" << 'EOF'
#!/bin/sh
# Disable screen blanking
wlr-randr --output HDMI-A-1 --on

# Keep compositor running
sleep infinity &
EOF

chmod +x "${ROOTFS_DIR}/home/pi/.config/labwc/autostart"
chown -R 1000:1000 "${ROOTFS_DIR}/home/pi/.config"

# Setup PipeWire for the pi user
mkdir -p "${ROOTFS_DIR}/home/pi/.config/systemd/user/default.target.wants"
on_chroot << EOF
# Enable PipeWire services for user pi
systemctl --user --global enable pipewire.service
systemctl --user --global enable pipewire-pulse.service
systemctl --user --global enable wireplumber.service
EOF
