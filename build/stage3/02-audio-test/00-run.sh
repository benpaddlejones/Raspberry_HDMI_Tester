#!/bin/bash -e
# Audio test deployment - FLAC files for audio testing

# Source common validation function
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
STAGE3_DIR="$(dirname "${SCRIPT_DIR}")"
source "${STAGE3_DIR}/00-common/validate-rootfs.sh"

# Validate ROOTFS_DIR using common function
validate_rootfs_dir || exit 1

echo "📁 Deploying FLAC audio test files..."

# Get the source directory (where this script lives, following pi-gen convention)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
FILES_DIR="${SCRIPT_DIR}/files"

# Validate source files exist in the files/ subdirectory
if [ ! -f "${FILES_DIR}/stereo.flac" ]; then
    echo "❌ Error: stereo.flac not found at ${FILES_DIR}/stereo.flac"
    exit 1
fi

if [ ! -s "${FILES_DIR}/stereo.flac" ]; then
    echo "❌ Error: stereo.flac is empty"
    exit 1
fi

if [ ! -f "${FILES_DIR}/surround51.flac" ]; then
    echo "❌ Error: surround51.flac not found at ${FILES_DIR}/surround51.flac"
    exit 1
fi

if [ ! -s "${FILES_DIR}/surround51.flac" ]; then
    echo "❌ Error: surround51.flac is empty"
    exit 1
fi

echo "  ✓ Source files validated"

# Create target directory
mkdir -p "${ROOTFS_DIR}/opt/hdmi-tester"

# Copy FLAC files
echo "  Copying stereo.flac..."
install -m 644 -o root -g root "${FILES_DIR}/stereo.flac" "${ROOTFS_DIR}/opt/hdmi-tester/"

echo "  Copying surround51.flac..."
install -m 644 -o root -g root "${FILES_DIR}/surround51.flac" "${ROOTFS_DIR}/opt/hdmi-tester/"

# Verify files were copied
if [ ! -f "${ROOTFS_DIR}/opt/hdmi-tester/stereo.flac" ]; then
    echo "❌ Error: Failed to copy stereo.flac"
    exit 1
fi

if [ ! -s "${ROOTFS_DIR}/opt/hdmi-tester/stereo.flac" ]; then
    echo "❌ Error: Deployed stereo.flac is empty"
    exit 1
fi

if [ ! -f "${ROOTFS_DIR}/opt/hdmi-tester/surround51.flac" ]; then
    echo "❌ Error: Failed to copy surround51.flac"
    exit 1
fi

if [ ! -s "${ROOTFS_DIR}/opt/hdmi-tester/surround51.flac" ]; then
    echo "❌ Error: Deployed surround51.flac is empty"
    exit 1
fi

# Verify file sizes match
stereo_source_size=$(stat -c%s "${FILES_DIR}/stereo.flac")
stereo_target_size=$(stat -c%s "${ROOTFS_DIR}/opt/hdmi-tester/stereo.flac")

if [ "${stereo_source_size}" -ne "${stereo_target_size}" ]; then
    echo "❌ Error: File size mismatch for stereo.flac"
    echo "   Source: ${stereo_source_size} bytes"
    echo "   Target: ${stereo_target_size} bytes"
    exit 1
fi

surround_source_size=$(stat -c%s "${FILES_DIR}/surround51.flac")
surround_target_size=$(stat -c%s "${ROOTFS_DIR}/opt/hdmi-tester/surround51.flac")

if [ "${surround_source_size}" -ne "${surround_target_size}" ]; then
    echo "❌ Error: File size mismatch for surround51.flac"
    echo "   Source: ${surround_source_size} bytes"
    echo "   Target: ${surround_target_size} bytes"
    exit 1
fi

echo "✅ FLAC audio test files deployed successfully"
echo "  - stereo.flac: ${stereo_target_size} bytes"
echo "  - surround51.flac: ${surround_target_size} bytes"
