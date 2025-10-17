#!/bin/bash
# Main build script for Raspberry Pi HDMI Tester image

set -e
set -u

echo "=================================================="
echo "Raspberry Pi HDMI Tester - Image Builder"
echo "=================================================="
echo ""

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
PI_GEN_DIR="${PI_GEN_DIR:-/opt/pi-gen}"
WORK_DIR="${PROJECT_ROOT}/build/pi-gen-work"
CONFIG_FILE="${PROJECT_ROOT}/build/config"

# Check prerequisites
echo "🔍 Checking prerequisites..."
if ! command -v qemu-arm-static &> /dev/null; then
    echo "❌ Error: qemu-arm-static not found"
    exit 1
fi

if [ ! -d "${PI_GEN_DIR}" ]; then
    echo "❌ Error: pi-gen not found at ${PI_GEN_DIR}"
    exit 1
fi

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "❌ Error: Build config not found at ${CONFIG_FILE}"
    exit 1
fi

echo "✅ Prerequisites OK"
echo ""

# Prepare working directory
echo "📁 Preparing build directory..."
if [ -d "${WORK_DIR}" ]; then
    echo "   Removing existing work directory..."
    sudo rm -rf "${WORK_DIR}"
fi

cp -r "${PI_GEN_DIR}" "${WORK_DIR}"
echo "✅ Build directory ready"
echo ""

# Copy custom stage
echo "📦 Installing custom stage..."
cp -r "${PROJECT_ROOT}/build/stage-custom" "${WORK_DIR}/"
cp "${PROJECT_ROOT}/build/stage3/SKIP" "${WORK_DIR}/stage3/"
cp "${PROJECT_ROOT}/build/stage4/SKIP" "${WORK_DIR}/stage4/"
cp "${PROJECT_ROOT}/build/stage5/SKIP" "${WORK_DIR}/stage5/"
echo "✅ Custom stage installed"
echo ""

# Copy config
echo "⚙️  Copying build configuration..."
cp "${CONFIG_FILE}" "${WORK_DIR}/config"
echo "✅ Configuration installed"
echo ""

# Copy assets to custom stages
echo "🎨 Copying test assets..."
mkdir -p "${WORK_DIR}/stage-custom/01-test-image/files"
mkdir -p "${WORK_DIR}/stage-custom/02-audio-test/files"
cp "${PROJECT_ROOT}/assets/image.png" "${WORK_DIR}/stage-custom/01-test-image/files/test-pattern.png"
cp "${PROJECT_ROOT}/assets/audio.mp3" "${WORK_DIR}/stage-custom/02-audio-test/files/test-audio.mp3"
echo "✅ Assets copied"
echo ""

# Run build
echo "🚀 Starting pi-gen build..."
echo "   This will take 30-60 minutes..."
echo ""

cd "${WORK_DIR}"
sudo ./build.sh

echo ""
echo "=================================================="
echo "✅ Build Complete!"
echo "=================================================="
echo ""
echo "Output images are in:"
echo "  ${WORK_DIR}/deploy/"
echo ""
ls -lh "${WORK_DIR}/deploy/"*.img 2>/dev/null || echo "No .img files found"
echo ""
echo "Next steps:"
echo "  1. Test the image: ./tests/qemu-test.sh"
echo "  2. Flash to SD card: See docs/FLASHING.md"
echo ""
