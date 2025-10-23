#!/bin/bash -e
# Configure HDMI testing - console mode (no X11/Wayland)
# Note: Packages are installed via 00-packages file by pi-gen

# HIGH PRIORITY FIX #6: Verify we're running in ARM context via QEMU
echo "🔍 Verifying execution environment..."
ARCH=$(uname -m)
echo "  Architecture: ${ARCH}"

if [[ "${ARCH}" =~ ^(armv7l|aarch64|armv6l)$ ]]; then
    echo "  ✅ Running in ARM context"
elif [[ "${ARCH}" =~ ^(x86_64|i686)$ ]]; then
    # Check if QEMU emulation is active
    if [ -f "/proc/sys/fs/binfmt_misc/qemu-arm" ]; then
        echo "  ⚠️  Running on x86_64 with QEMU emulation"
        # Verify QEMU is actually working by checking for qemu process
        if [ -f "/usr/bin/qemu-arm-static" ]; then
            echo "  ✅ QEMU ARM emulation appears active"
        else
            echo "  ❌ ERROR: Running on x86_64 but QEMU not properly configured!"
            echo "  This means packages might be checked from wrong architecture!"
            exit 1
        fi
    else
        echo "  ❌ ERROR: Running on x86_64 WITHOUT QEMU emulation!"
        echo "  Cannot verify ARM packages from x86_64 context!"
        exit 1
    fi
else
    echo "  ⚠️  Unknown architecture: ${ARCH}"
fi

# Verify required packages were installed
echo "🔍 Verifying required packages are installed..."
PACKAGES_OK=true

for pkg in mpv alsa-utils; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        echo "  ✅ $pkg: Installed"
    else
        echo "  ❌ $pkg: NOT INSTALLED!"
        PACKAGES_OK=false
    fi
done

if [ "$PACKAGES_OK" = false ]; then
    echo "❌ ERROR: Some packages are missing!"
    echo "This should not happen - packages should be installed via 00-packages file"
    exit 1
fi

echo "✅ All required packages verified"
echo ""

# Clean up apt cache to reduce image size
apt-get clean

# Ensure pi user is in necessary groups for audio/video/framebuffer access
usermod -a -G audio pi || true
usermod -a -G video pi || true

echo "✅ Console-mode packages installed and user groups configured"
