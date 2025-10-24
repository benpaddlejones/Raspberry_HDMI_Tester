#!/bin/bash -e
# Audio test deployment - FLAC files for audio testing

# Validate ROOTFS_DIR
if [ -z "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR not set"
    exit 1
fi

if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR does not exist: ${ROOTFS_DIR}"
    exit 1
fi

echo "📁 Deploying FLAC audio test files..."

# Get the source directory (where this script lives, following pi-gen convention)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
FILES_DIR="${SCRIPT_DIR}/files"

# Validate source files exist in the files/ subdirectory
if [ ! -f "${FILES_DIR}/stereo.flac" ]; then
    echo "❌ Error: stereo.flac not found at ${FILES_DIR}/stereo.flac"
    exit 1
fi

if [ ! -f "${FILES_DIR}/surround51.flac" ]; then
    echo "❌ Error: surround51.flac not found at ${FILES_DIR}/surround51.flac"
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

if [ ! -f "${ROOTFS_DIR}/opt/hdmi-tester/surround51.flac" ]; then
    echo "❌ Error: Failed to copy surround51.flac"
    exit 1
fi

echo "✅ FLAC audio test files deployed successfully"
echo "  - stereo.flac: $(stat -c%s "${ROOTFS_DIR}/opt/hdmi-tester/stereo.flac") bytes"
echo "  - surround51.flac: $(stat -c%s "${ROOTFS_DIR}/opt/hdmi-tester/surround51.flac") bytes"
