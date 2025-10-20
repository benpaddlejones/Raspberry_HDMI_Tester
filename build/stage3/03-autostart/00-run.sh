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
if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    # Ensure XDG_RUNTIME_DIR is set
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    # Create it if it doesn't exist (shouldn't be necessary, but safety check)
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
    
    # Set Wayland environment variables
    export WLR_BACKENDS=drm
    export WLR_RENDERER=gles2
    export WLR_DRM_NO_MODIFIERS=1
    
    # Start labwc compositor (don't use exec so we can recover from crashes)
    if command -v labwc >/dev/null 2>&1; then
        echo "Starting Wayland compositor (labwc)..."
        labwc
        # If labwc exits, log it
        echo "Wayland compositor exited with status $?"
    else
        echo "ERROR: labwc not found, cannot start Wayland compositor"
    fi
fi
EOF

# Validate .bashrc was modified successfully
if ! grep -q "labwc" "${ROOTFS_DIR}/home/pi/.bashrc"; then
    echo "❌ Error: Failed to add Wayland autostart to .bashrc"
    exit 1
fi

# Create labwc configuration directory
mkdir -p "${ROOTFS_DIR}/home/pi/.config/labwc"

# Validate directory was created
if [ ! -d "${ROOTFS_DIR}/home/pi/.config/labwc" ]; then
    echo "❌ Error: Failed to create labwc config directory"
    exit 1
fi

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

# Validate rc.xml was created
if [ ! -f "${ROOTFS_DIR}/home/pi/.config/labwc/rc.xml" ]; then
    echo "❌ Error: Failed to create labwc rc.xml"
    exit 1
fi

# Create autostart for labwc
cat > "${ROOTFS_DIR}/home/pi/.config/labwc/autostart" << 'EOF'
#!/bin/sh
# Disable screen blanking
wlr-randr --output HDMI-A-1 --on

# Keep compositor running
sleep infinity &
EOF

# Validate autostart was created
if [ ! -f "${ROOTFS_DIR}/home/pi/.config/labwc/autostart" ]; then
    echo "❌ Error: Failed to create labwc autostart"
    exit 1
fi

chmod +x "${ROOTFS_DIR}/home/pi/.config/labwc/autostart"

# Verify it's executable
if [ ! -x "${ROOTFS_DIR}/home/pi/.config/labwc/autostart" ]; then
    echo "❌ Error: Failed to set executable permission on autostart"
    exit 1
fi

chown -R 1000:1000 "${ROOTFS_DIR}/home/pi/.config"

# Setup PipeWire for the pi user
mkdir -p "${ROOTFS_DIR}/home/pi/.config/systemd/user/default.target.wants"
on_chroot << EOF
# Enable PipeWire services for user pi
systemctl --user --global enable pipewire.service
systemctl --user --global enable pipewire-pulse.service
systemctl --user --global enable wireplumber.service
EOF
