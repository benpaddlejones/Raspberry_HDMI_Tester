#!/bin/bash -e
# Install HDMI tester scripts (manual execution mode for testing)

# Validate ROOTFS_DIR is set and exists
if [ -z "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR not set"
    exit 1
fi

if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR does not exist: ${ROOTFS_DIR}"
    exit 1
fi

echo "🔧 Installing HDMI tester scripts (manual execution mode)..."

# Validate source files exist
if [ ! -f "files/hdmi-image" ]; then
    echo "❌ Error: hdmi-image script not found"
    exit 1
fi

if [ ! -f "files/hdmi-audio" ]; then
    echo "❌ Error: hdmi-audio script not found"
    exit 1
fi

if [ ! -f "files/hdmi-test" ]; then
    echo "❌ Error: hdmi-test script not found"
    exit 1
fi

# Install test scripts to /usr/local/bin (in PATH)
echo "Installing test scripts..."
install -m 755 files/hdmi-image "${ROOTFS_DIR}/usr/local/bin/"
install -m 755 files/hdmi-audio "${ROOTFS_DIR}/usr/local/bin/"
install -m 755 files/hdmi-test "${ROOTFS_DIR}/usr/local/bin/"

# Verify scripts were installed
if [ ! -f "${ROOTFS_DIR}/usr/local/bin/hdmi-image" ]; then
    echo "❌ Error: Failed to install hdmi-image"
    exit 1
fi

if [ ! -f "${ROOTFS_DIR}/usr/local/bin/hdmi-audio" ]; then
    echo "❌ Error: Failed to install hdmi-audio"
    exit 1
fi

if [ ! -f "${ROOTFS_DIR}/usr/local/bin/hdmi-test" ]; then
    echo "❌ Error: Failed to install hdmi-test"
    exit 1
fi

echo "✅ Test scripts installed successfully"

# Install systemd service files (for future use, but NOT enabled)
echo "Installing systemd service files (disabled)..."
mkdir -p "${ROOTFS_DIR}/etc/systemd/system"

if [ -f "files/hdmi-display.service" ]; then
    install -m 644 files/hdmi-display.service "${ROOTFS_DIR}/etc/systemd/system/"
    echo "  • hdmi-display.service installed (not enabled)"
fi

if [ -f "files/hdmi-audio.service" ]; then
    install -m 644 files/hdmi-audio.service "${ROOTFS_DIR}/etc/systemd/system/"
    echo "  • hdmi-audio.service installed (not enabled)"
fi

echo "✅ Systemd services installed but NOT enabled"
echo "   (Services are available for future enablement)"

# NOTE: Services are intentionally NOT enabled for manual testing phase
# To enable services later, run on the Pi:
#   sudo systemctl enable hdmi-display.service
#   sudo systemctl enable hdmi-audio.service

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
echo "  hdmi-image     - Display test pattern"
echo "  hdmi-audio     - Play audio test (with debugging)"
echo "  hdmi-test      - Run full integration test"
echo ""
echo "Examples:"
echo "  sudo hdmi-image          # Display test pattern"
echo "  hdmi-audio               # Test audio with debug info"
echo "  sudo hdmi-test           # Run both tests together"
echo ""
echo "Press Ctrl+C to stop any test"
echo "========================================="
echo ""
WELCOME_EOF

# Set correct ownership
chown -R 1000:1000 "${ROOTFS_DIR}/home/pi"

echo "✅ HDMI tester scripts installed (manual testing mode)"
