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
SCRIPTS=("hdmi-test" "pixel-test" "full-test" "audio-test" "hdmi-diagnostics" "image-test" "hdmi-tester-config")
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

# Install configuration library
echo "Installing configuration library..."
mkdir -p "${ROOTFS_DIR}/usr/local/lib/hdmi-tester"
install -m 644 "files/config-lib.sh" "${ROOTFS_DIR}/usr/local/lib/hdmi-tester/"
echo "  ✓ Configuration library installed"

# Create log directory for runtime test logs
echo "Creating /logs directory for runtime test logs..."
mkdir -p "${ROOTFS_DIR}/logs"
chmod 777 "${ROOTFS_DIR}/logs"  # Allow all users to write logs

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

    # Create relative symlink in /usr/local/bin for PATH convenience
    # Use relative path so symlink works when filesystem is mounted elsewhere
    # From /usr/local/bin/ we need to go up 3 levels (../../../) to reach root
    ln -sf "../../../opt/hdmi-tester/${script}" "${ROOTFS_DIR}/usr/local/bin/${script}"

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
SERVICES=("hdmi-test.service" "pixel-test.service" "audio-test.service" "full-test.service" "image-test.service")
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

echo "✅ HDMI tester services and scripts installed."

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
# Prevent restart loop - keep session alive
Type=idle
TTYVHangup=no
TTYReset=no
AUTOLOGIN_EOF

# Verify autologin was configured
if [ ! -f "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/autologin.conf" ]; then
    echo "❌ Error: Failed to create autologin configuration"
    exit 1
fi
echo "✅ Auto-login configured for user 'pi'"

# Create welcome message with instructions and auto-start logic
echo "Creating welcome message with auto-start capability..."
cat > "${ROOTFS_DIR}/home/pi/.bash_profile" << 'WELCOME_EOF'
# HDMI Tester Welcome Message and Auto-Start Logic

# Only run auto-start on interactive shell (not for ssh, etc.)
if [[ $- == *i* ]] && [ -z "$SSH_CONNECTION" ]; then
    # Source configuration library if available
    if [ -f "/usr/local/lib/hdmi-tester/config-lib.sh" ]; then
        source /usr/local/lib/hdmi-tester/config-lib.sh

        # Check for default service to auto-start
        DEFAULT_SERVICE=$(get_default_service 2>/dev/null)

        if [ -n "${DEFAULT_SERVICE}" ] && [ "${DEFAULT_SERVICE}" != "" ]; then
            echo ""
            echo "========================================="
            echo "   Raspberry Pi HDMI Tester"
            echo "========================================="
            echo ""
            echo "Auto-starting default service: ${DEFAULT_SERVICE}"
            echo "Press Ctrl+C to stop and return to config menu"
            echo ""
            echo "To change default service, run: hdmi-tester-config"
            echo "========================================="
            echo ""

            # Auto-start the default service
            case "${DEFAULT_SERVICE}" in
                "hdmi-test")
                    /usr/local/bin/hdmi-test
                    ;;
                "audio-test")
                    /usr/local/bin/audio-test
                    ;;
                "image-test")
                    /usr/local/bin/image-test
                    ;;
                "pixel-test")
                    /usr/local/bin/pixel-test
                    ;;
                "full-test")
                    /usr/local/bin/full-test
                    ;;
                "hdmi-diagnostics")
                    echo "Running system diagnostics..."
                    sudo /usr/local/bin/hdmi-diagnostics
                    ;;
                *)
                    echo "Warning: Unknown default service '${DEFAULT_SERVICE}'"
                    echo "Please run 'hdmi-tester-config' to fix this."
                    ;;
            esac

            # After service exits (user pressed Ctrl+C or service ended), show config menu
            echo ""
            echo "Service stopped. Opening configuration menu..."
            /usr/local/bin/hdmi-tester-config
        else
            # No default service - show welcome message and wait for user input
            echo ""
            echo "========================================="
            echo "   Raspberry Pi HDMI Tester"
            echo "========================================="
            echo ""
            echo "Configuration:"
            echo ""
            echo "  hdmi-tester-config         - Interactive configuration menu"
            echo "                               (Set debug mode, default service)"
            echo ""
            echo "Available test commands:"
            echo ""
            echo "  hdmi-test                  - Loop image-test.webm"
            echo "  pixel-test                 - Play color-test.webm fullscreen"
            echo "  image-test                 - Rotate through color test images (10s each)"
            echo "  full-test                  - Play both videos in sequence"
            echo "  audio-test                 - Loop stereo and 5.1 surround audio"
            echo ""
            echo "Diagnostic tools:"
            echo ""
            echo "  hdmi-diagnostics           - Capture complete system diagnostics"
            echo "                               (Creates timestamped .tar.gz bundle)"
            echo ""
            echo "Configuration file: /boot/firmware/hdmi-tester.conf"
            echo "  (Accessible from Windows/Mac when SD card is mounted)"
            echo ""
            echo "Press Ctrl+C to stop any test and return to config menu"
            echo "========================================="
            echo ""
        fi
    else
        # Config library not available - show basic message
        echo ""
        echo "========================================="
        echo "   Raspberry Pi HDMI Tester"
        echo "========================================="
        echo ""
        echo "Configuration system not yet available."
        echo "Please wait for system to finish setup or run: hdmi-tester-config"
        echo "========================================="
        echo ""
    fi
fi
WELCOME_EOF

# Set correct ownership
chown -R 1000:1000 "${ROOTFS_DIR}/home/pi"

echo "✅ HDMI tester scripts installed with configuration system"
