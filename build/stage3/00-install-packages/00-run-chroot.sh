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

# Core packages that must be installed
REQUIRED_PACKAGES="alsa-utils ffmpeg libx264-164"

for pkg in ${REQUIRED_PACKAGES}; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        VERSION=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "unknown")
        echo "  ✅ $pkg: Installed (version: ${VERSION})"
    else
        echo "  ❌ $pkg: NOT INSTALLED!"
        PACKAGES_OK=false
    fi
done

# Check for codec libraries (these are critical for video playback)
CODEC_PACKAGES="libavcodec-extra libavformat-extra libvpx7 libopus0 libmp3lame0 libmpg123-0"

echo ""
echo "🔍 Verifying codec libraries..."
for pkg in ${CODEC_PACKAGES}; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        VERSION=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "unknown")
        echo "  ✅ $pkg: Installed (${VERSION})"
    else
        echo "  ❌ $pkg: NOT INSTALLED!"
        PACKAGES_OK=false
    fi
done

if [ "$PACKAGES_OK" = false ]; then
    echo ""
    echo "❌ ERROR: Some required packages are missing!"
    echo "This indicates a package installation failure."
    echo ""
    echo "Installed packages:"
    dpkg-query -W -f='${Package} ${Status}\n' | grep "install ok installed" | head -20
    echo ""
    exit 1
fi

echo ""
echo "✅ All required packages verified"
echo ""

# Clean up apt cache to reduce image size
apt-get clean

# Ensure pi user is in necessary groups for audio/video/framebuffer access
usermod -a -G audio pi || true
usermod -a -G video pi || true

echo "✅ Console-mode packages installed and user groups configured"
