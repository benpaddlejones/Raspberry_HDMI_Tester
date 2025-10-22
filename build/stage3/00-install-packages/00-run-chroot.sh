#!/bin/bash -e
# Configure HDMI testing - console mode (no X11/Wayland)
# Note: Packages are installed via 00-packages file by pi-gen

# Verify required packages were installed
echo "🔍 Verifying required packages are installed..."
PACKAGES_OK=true

for pkg in fbi mpv alsa-utils; do
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
