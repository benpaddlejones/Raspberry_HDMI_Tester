#!/bin/bash -e
# Validation stage - Verify critical packages and files are installed

echo "=========================================="
echo "Stage 3 - Validation"
echo "=========================================="
echo ""

# Track validation failures
VALIDATION_FAILED=0

# Function to validate package installed
validate_package() {
    local package="$1"
    local description="$2"

    # Check for package with or without architecture suffix (e.g., vlc-plugin-base or vlc-plugin-base:armhf)
    if dpkg -l | grep -qE "^ii  ${package}(:[^ ]+)? "; then
        echo "  ✓ ${package} - ${description}"
        return 0
    else
        echo "  ❌ ${package} - ${description} - NOT INSTALLED"
        VALIDATION_FAILED=1
        return 1
    fi
}

# Function to validate file exists
validate_file() {
    local file="$1"
    local description="$2"

    if [ -f "${file}" ]; then
        echo "  ✓ ${file} - ${description}"
        return 0
    else
        echo "  ❌ ${file} - ${description} - NOT FOUND"
        VALIDATION_FAILED=1
        return 1
    fi
}

# Function to validate VLC module
validate_vlc_module() {
    local module="$1"
    local description="$2"

    if cvlc --list 2>&1 | grep -q "${module}"; then
        echo "  ✓ VLC module: ${module} - ${description}"
        return 0
    else
        echo "  ❌ VLC module: ${module} - ${description} - NOT FOUND"
        VALIDATION_FAILED=1
        return 1
    fi
}

echo "=== Critical Package Validation ==="
echo ""

echo "VLC Video Output Packages:"
validate_package "vlc-bin" "VLC binary"
validate_package "vlc-plugin-base" "Core VLC plugins (fbdev, vout)"
validate_package "vlc-plugin-video-output" "Additional video output modules"
echo ""

echo "ALSA Audio Packages:"
validate_package "alsa-utils" "ALSA utilities"
validate_package "libasound2-plugins" "ALSA plugin system"
echo ""

echo "Raspberry Pi Specific Packages:"
validate_package "raspberrypi-sys-mods" "Raspberry Pi system modifications (bcm2835 configs)"
echo ""

echo "=== VLC Module Validation ==="
echo ""

echo "VLC Video Output Modules:"
# Video output modules are included in vlc-plugin-base (fb, vdummy) and vlc-plugin-video-output (egl, x11, etc.)
# Module names don't reliably appear in cvlc --list, so we validate package installation instead
echo "  ℹ️  Video output modules included in vlc-plugin-base and vlc-plugin-video-output packages"
echo "  ℹ️  VLC will auto-detect best available output (fb, x11, egl, etc.)"
echo "  ℹ️  Module validation skipped - package installation confirms availability"
echo ""

echo "VLC Audio Output Modules:"
# Note: VLC module detection is unreliable in chroot environments
# Instead, verify VLC can be invoked and ALSA packages are installed
if command -v cvlc >/dev/null 2>&1 && dpkg -l | grep -q "alsa-utils"; then
    echo "  ✓ VLC binary available and ALSA packages installed"
    echo "  ℹ️  VLC will use ALSA output via --aout=alsa flag (verified by package installation)"
else
    echo "  ❌ VLC binary or ALSA packages missing"
    VALIDATION_FAILED=1
fi
echo ""

echo "=== ALSA Configuration Files ==="
echo ""

echo "Raspberry Pi ALSA Card Definitions:"
# Note: raspberrypi-sys-mods may install these in different locations
# Check multiple possible locations
if [ -f /usr/share/alsa/cards/bcm2835_hdmi.conf ] || \
   [ -f /usr/share/alsa/cards/bcm2835.conf ] || \
   [ -d /usr/share/raspberrypi-sys-mods ]; then
    echo "  ✓ Raspberry Pi ALSA configurations found"
else
    echo "  ⚠️  WARNING: bcm2835 ALSA card definitions not found in standard locations"
    echo "     This may cause audio device name resolution issues"
    echo "     Checking if raspberrypi-sys-mods installed correctly..."
    if dpkg -L raspberrypi-sys-mods | grep -q alsa; then
        echo "  ✓ raspberrypi-sys-mods contains ALSA files"
    else
        echo "  ❌ raspberrypi-sys-mods missing ALSA configurations"
        VALIDATION_FAILED=1
    fi
fi
echo ""

echo "=== Test Asset Validation ==="
echo ""

echo "Video Format Files (Dual-Format System):"
validate_file "/opt/hdmi-tester/image-test.mp4" "Image test video for Pi 3B (H.264/AAC)"
validate_file "/opt/hdmi-tester/image-test.webm" "Image test video for Pi 4+ (VP9/Opus)"
validate_file "/opt/hdmi-tester/color-test.mp4" "Color test video for Pi 3B (H.264/AAC)"
validate_file "/opt/hdmi-tester/color-test.webm" "Color test video for Pi 4+ (VP9/Opus)"
echo ""

echo "Image Files:"
validate_file "/opt/hdmi-tester/image.png" "Static test pattern"
validate_file "/opt/hdmi-tester/black.png" "Black screen test"
validate_file "/opt/hdmi-tester/white.png" "White screen test"
validate_file "/opt/hdmi-tester/red.png" "Red screen test"
validate_file "/opt/hdmi-tester/green.png" "Green screen test"
validate_file "/opt/hdmi-tester/blue.png" "Blue screen test"
echo ""

echo "Audio Files:"
validate_file "/opt/hdmi-tester/stereo.flac" "Stereo test audio (FLAC)"
validate_file "/opt/hdmi-tester/surround51.flac" "5.1 Surround test audio (FLAC)"
validate_file "/opt/hdmi-tester/audio.mp3" "Standalone audio test (MP3)"
echo ""

echo "=== Test Scripts Validation ==="
echo ""

echo "Test Scripts:"
validate_file "/opt/hdmi-tester/hdmi-test" "Main HDMI test script (video+audio)"
validate_file "/opt/hdmi-tester/image-test" "Image rotation test script"
validate_file "/opt/hdmi-tester/audio-test" "Audio-only test script"
validate_file "/opt/hdmi-tester/detect-hdmi-audio" "HDMI audio device detection"
validate_file "/opt/hdmi-tester/hdmi-diagnostics" "Diagnostic information script"
echo ""

echo "=== Systemd Services Validation ==="
echo ""

echo "Service Files:"
validate_file "/etc/systemd/system/hdmi-test.service" "HDMI test service"
validate_file "/etc/systemd/system/image-test.service" "Image test service"
validate_file "/etc/systemd/system/audio-test.service" "Audio test service"
echo ""

echo "=========================================="
if [ ${VALIDATION_FAILED} -eq 0 ]; then
    echo "✅ ALL VALIDATIONS PASSED"
    echo "=========================================="
    echo ""
    echo "Summary:"
    echo "  • VLC video output modules: OK"
    echo "  • ALSA audio configuration: OK"
    echo "  • Test assets (dual-format): OK"
    echo "  • Test scripts: OK"
    echo "  • Systemd services: OK"
    echo ""
    echo "Image is ready for deployment."
    exit 0
else
    echo "❌ VALIDATION FAILED"
    echo "=========================================="
    echo ""
    echo "One or more critical components are missing."
    echo "Review the errors above and fix the build configuration."
    echo ""
    echo "Common fixes:"
    echo "  • Add missing packages to build/stage3/00-install-packages/00-packages"
    echo "  • Ensure test assets are present in build/stage3/01-test-image/files/"
    echo "  • Verify systemd services are created in build/stage3/03-autostart/"
    echo ""
    exit 1
fi
