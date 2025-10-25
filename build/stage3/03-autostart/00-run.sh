#!/bin/bash -e
# Install HDMI tester scripts (manual execution mode for testing)

# Source common validation function
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
STAGE3_DIR="$(dirname "${SCRIPT_DIR}")"
source "${STAGE3_DIR}/00-common/validate-rootfs.sh"

# Validate ROOTFS_DIR using common function
validate_rootfs_dir || exit 1

echo "🔧 Installing HDMI tester scripts (manual execution mode)..."

# Validate source files exist
SCRIPTS=("hdmi-test" "pixel-test" "full-test" "audio-test" "hdmi-diagnostics" "detect-hdmi-audio" "image-test" "test-notvideo")
for script in "${SCRIPTS[@]}"; do
    if [ ! -f "files/${script}" ]; then
        echo "❌ Error: ${script} script not found"
        exit 1
    fi
    # Validate file is not empty
    if [ ! -s "files/${script}" ]; then
        echo "❌ Error: ${script} script is empty"
        exit 1
    fi
done

echo "  ✓ All ${#SCRIPTS[@]} scripts validated"

# Install test scripts to /opt/hdmi-tester (canonical location)
# Create symlinks in /usr/local/bin for PATH convenience
echo "Installing test scripts to /opt/hdmi-tester..."
mkdir -p "${ROOTFS_DIR}/opt/hdmi-tester"
mkdir -p "${ROOTFS_DIR}/usr/local/bin"

for script in "${SCRIPTS[@]}"; do
    # Install to /opt/hdmi-tester (canonical location used by services)
    install -m 755 "files/${script}" "${ROOTFS_DIR}/opt/hdmi-tester/"

    # Verify installation
    if [ ! -f "${ROOTFS_DIR}/opt/hdmi-tester/${script}" ]; then
        echo "❌ Error: Failed to install ${script} to /opt/hdmi-tester"
        exit 1
    fi

    # Verify deployed file is not empty
    if [ ! -s "${ROOTFS_DIR}/opt/hdmi-tester/${script}" ]; then
        echo "❌ Error: Deployed ${script} is empty"
        exit 1
    fi

    # Verify file size matches
    source_size=$(stat -c%s "files/${script}")
    target_size=$(stat -c%s "${ROOTFS_DIR}/opt/hdmi-tester/${script}")

    if [ "${source_size}" -ne "${target_size}" ]; then
        echo "❌ Error: File size mismatch for ${script}"
        echo "   Source: ${source_size} bytes"
        echo "   Target: ${target_size} bytes"
        exit 1
    fi

    # Create symlink in /usr/local/bin for PATH convenience
    ln -sf "/opt/hdmi-tester/${script}" "${ROOTFS_DIR}/usr/local/bin/${script}"

    # Verify symlink was created
    if [ ! -L "${ROOTFS_DIR}/usr/local/bin/${script}" ]; then
        echo "❌ Error: Failed to create symlink for ${script} in /usr/local/bin"
        exit 1
    fi

    echo "  • ${script} installed (${source_size} bytes, symlinked to PATH)"
done

echo "✅ Test scripts installed to /opt/hdmi-tester with PATH symlinks"

# Install systemd service files (for future use, but NOT enabled)
echo "Installing systemd service files (disabled)..."
mkdir -p "${ROOTFS_DIR}/etc/systemd/system"

# Install test services based on test commands (VLC only)
SERVICES=("hdmi-test.service" "pixel-test.service" "audio-test.service" "full-test.service" "image-test.service" "test-notvideo.service")
for service in "${SERVICES[@]}"; do
    if [ -f "files/${service}" ]; then
        # Validate source file is not empty
        if [ ! -s "files/${service}" ]; then
            echo "❌ Error: ${service} is empty"
            exit 1
        fi

        install -m 644 "files/${service}" "${ROOTFS_DIR}/etc/systemd/system/"

        # Verify deployed service file exists
        if [ ! -f "${ROOTFS_DIR}/etc/systemd/system/${service}" ]; then
            echo "❌ Error: Failed to install ${service}"
            exit 1
        fi

        # Verify deployed file is not empty
        if [ ! -s "${ROOTFS_DIR}/etc/systemd/system/${service}" ]; then
            echo "❌ Error: Deployed ${service} is empty"
            exit 1
        fi

        # Verify file size matches
        source_size=$(stat -c%s "files/${service}")
        target_size=$(stat -c%s "${ROOTFS_DIR}/etc/systemd/system/${service}")

        if [ "${source_size}" -ne "${target_size}" ]; then
            echo "❌ Error: File size mismatch for ${service}"
            echo "   Source: ${source_size} bytes"
            echo "   Target: ${target_size} bytes"
            exit 1
        fi

        echo "  • ${service} installed and validated (${source_size} bytes)"
    else
        echo "⚠️  Warning: ${service} not found"
    fi
done

echo "✅ Systemd services installed but NOT enabled"
echo "   (Services are available for future enablement)"

# NOTE: Services are intentionally NOT enabled for manual testing phase
# To enable services later, run on the Pi:
#   sudo systemctl enable hdmi-test.service       # Image loop test
#   sudo systemctl enable pixel-test.service    # Color fullscreen test
#   sudo systemctl enable full-test.service           # Both videos in sequence

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
echo "  hdmi-test                  - Loop image-test.webm"
echo "  pixel-test                 - Play color-test.webm fullscreen"
echo "  image-test                 - Rotate through color test images (10s each)"
echo "  test-notvideo              - Display static image with looping audio"
echo "  full-test                  - Play both videos in sequence"
echo "  audio-test                 - Loop stereo and 5.1 surround audio"
echo ""
echo "Diagnostic tools:"
echo ""
echo "  hdmi-diagnostics           - Capture complete system diagnostics"
echo "                               (Creates timestamped .tar.gz bundle)"
echo ""
echo "Available systemd services (not enabled by default):"
echo ""
echo "  hdmi-test.service              - Auto-run hdmi-test on boot"
echo "  pixel-test.service             - Auto-run pixel-test on boot"
echo "  image-test.service             - Auto-run image-test on boot"
echo "  test-notvideo.service          - Auto-run test-notvideo on boot"
echo "  full-test.service              - Auto-run full-test on boot"
echo "  audio-test.service             - Auto-run audio-test on boot (MP3 only)"
echo ""
echo "To enable auto-start:"
echo "  sudo systemctl enable test-notvideo.service"
echo "  sudo systemctl start test-notvideo.service"
echo ""
echo "Examples:"
echo "  hdmi-test          # Loop image test video"
echo "  pixel-test         # Fullscreen color test"
echo "  image-test         # Rotate through color images"
echo "  test-notvideo      # Static image with audio"
echo "  full-test          # Play both videos in sequence"
echo "  audio-test         # Loop audio tests"
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
