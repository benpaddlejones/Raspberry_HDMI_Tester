#!/bin/bash -e
# Install HDMI tester scripts (manual execution mode for testing)

# Validate ROOTFS_DIR is set and exists
if [ -z "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR not set"
    exit 1
fi

# MEDIUM PRIORITY FIX #8: Safety check - ensure ROOTFS_DIR is not /
ROOTFS_REAL=$(realpath "${ROOTFS_DIR}" 2>/dev/null || echo "${ROOTFS_DIR}")
if [ "${ROOTFS_REAL}" = "/" ] || [ "${ROOTFS_DIR}" = "/" ]; then
    echo "❌ Error: ROOTFS_DIR cannot be root directory (/)"
    echo "   This would install files to the host system!"
    echo "   Current ROOTFS_DIR: ${ROOTFS_DIR}"
    exit 1
fi

if [[ "${ROOTFS_DIR}" =~ ^/(bin|boot|dev|etc|home|lib|opt|root|sbin|srv|sys|usr|var)$ ]]; then
    echo "❌ Error: ROOTFS_DIR appears to be a system directory: ${ROOTFS_DIR}"
    echo "   This looks like a host system path, not a build chroot!"
    exit 1
fi

if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR does not exist: ${ROOTFS_DIR}"
    exit 1
fi

echo "✅ ROOTFS_DIR validated: ${ROOTFS_DIR}"

echo "🔧 Installing HDMI tester scripts (manual execution mode)..."

# Validate source files exist
SCRIPTS=("test-image-loop-vlc" "test-color-fullscreen-vlc" "test-both-loop-vlc" "hdmi-diagnostics")
for script in "${SCRIPTS[@]}"; do
    if [ ! -f "files/${script}" ]; then
        echo "❌ Error: ${script} script not found"
        exit 1
    fi
done

# Install test scripts to /usr/local/bin (in PATH)
echo "Installing test scripts..."
for script in "${SCRIPTS[@]}"; do
    install -m 755 "files/${script}" "${ROOTFS_DIR}/usr/local/bin/"
    if [ ! -f "${ROOTFS_DIR}/usr/local/bin/${script}" ]; then
        echo "❌ Error: Failed to install ${script}"
        exit 1
    fi
    echo "  • ${script} installed"
done

echo "✅ Test scripts installed successfully"

# Install systemd service files (for future use, but NOT enabled)
echo "Installing systemd service files (disabled)..."
mkdir -p "${ROOTFS_DIR}/etc/systemd/system"

# Install test services based on test commands (VLC only)
SERVICES=("hd-audio-test-vlc.service" "pixel-audio-test-vlc.service" "full-test-vlc.service")
for service in "${SERVICES[@]}"; do
    if [ -f "files/${service}" ]; then
        install -m 644 "files/${service}" "${ROOTFS_DIR}/etc/systemd/system/"
        echo "  • ${service} installed (not enabled)"
    else
        echo "⚠️  Warning: ${service} not found"
    fi
done

echo "✅ Systemd services installed but NOT enabled"
echo "   (Services are available for future enablement)"

# NOTE: Services are intentionally NOT enabled for manual testing phase
# To enable services later, run on the Pi:
#   sudo systemctl enable hd-audio-test-vlc.service       # Image loop test (VLC)
#   sudo systemctl enable pixel-audio-test-vlc.service    # Color fullscreen test (VLC)
#   sudo systemctl enable full-test-vlc.service           # Both videos in sequence (VLC)

# Configure auto-login for user pi on tty1
echo "Configuring auto-login..."
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
echo "✅ Auto-login configured for user 'pi'"

# Create welcome message with instructions
echo "Creating welcome message..."
cat > "${ROOTFS_DIR}/home/pi/.bash_profile" << 'WELCOME_EOF'
# HDMI Tester Welcome Message
echo ""
echo "========================================="
echo "   Raspberry Pi HDMI Tester"
echo "========================================="
echo ""
echo "Available test commands:"
echo ""
echo "  test-image-loop-vlc        - Loop image-test.webm"
echo "  test-color-fullscreen-vlc  - Play color_test.webm fullscreen"
echo "  test-both-loop-vlc         - Play both videos in sequence"
echo ""
echo "Diagnostic tools:"
echo ""
echo "  hdmi-diagnostics           - Capture complete system diagnostics"
echo "                               (Creates timestamped .tar.gz bundle)"
echo ""
echo "Available systemd services (not enabled by default):"
echo ""
echo "  hd-audio-test-vlc.service      - Auto-run test-image-loop-vlc on boot"
echo "  pixel-audio-test-vlc.service   - Auto-run test-color-fullscreen-vlc on boot"
echo "  full-test-vlc.service          - Auto-run test-both-loop-vlc on boot"
echo ""
echo "To enable auto-start:"
echo "  sudo systemctl enable hd-audio-test-vlc.service"
echo "  sudo systemctl start hd-audio-test-vlc.service"
echo ""
echo "Examples:"
echo "  test-image-loop-vlc          # Loop image test video"
echo "  test-color-fullscreen-vlc    # Fullscreen color test"
echo "  test-both-loop-vlc           # Play both videos in sequence"
echo ""
echo "Troubleshooting:"
echo "  hdmi-diagnostics             # Collect all logs and system info"
echo "                               # Creates /tmp/hdmi-diagnostics-*.tar.gz"
echo ""
echo "Press Ctrl+C to stop any test"
echo "========================================="
echo ""
WELCOME_EOF

# Set correct ownership
chown -R 1000:1000 "${ROOTFS_DIR}/home/pi"

echo "✅ HDMI tester scripts installed (manual testing mode)"
