#!/bin/bash -e
# Deploy test videos (WebM format)

# Validate ROOTFS_DIR is set and exists
if [ -z "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR not set"
    exit 1
fi

# MEDIUM PRIORITY FIX #8: Safety check - ensure ROOTFS_DIR is not /
# This prevents catastrophic damage if ROOTFS_DIR is misconfigured
ROOTFS_REAL=$(realpath "${ROOTFS_DIR}" 2>/dev/null || echo "${ROOTFS_DIR}")
if [ "${ROOTFS_REAL}" = "/" ] || [ "${ROOTFS_DIR}" = "/" ]; then
    echo "❌ Error: ROOTFS_DIR cannot be root directory (/)"
    echo "   This would install files to the host system!"
    echo "   Current ROOTFS_DIR: ${ROOTFS_DIR}"
    exit 1
fi

# Also check common dangerous paths
if [[ "${ROOTFS_DIR}" =~ ^/(bin|boot|dev|etc|home|lib|opt|root|sbin|srv|sys|usr|var)$ ]]; then
    echo "❌ Error: ROOTFS_DIR appears to be a system directory: ${ROOTFS_DIR}"
    echo "   This looks like a host system path, not a build chroot!"
    exit 1
fi

if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR does not exist: ${ROOTFS_DIR}"
    exit 1
fi

# Validate ROOTFS_DIR is writable
if [ ! -w "${ROOTFS_DIR}" ]; then
    echo "❌ Error: ROOTFS_DIR is not writable: ${ROOTFS_DIR}"
    exit 1
fi

echo "✅ ROOTFS_DIR validated: ${ROOTFS_DIR}"

# Validate source files exist
TEST_VIDEOS=("image-test.webm" "color-test.webm" "image-test.mp4" "color-test.mp4")

echo "Validating source files..."
for video in "${TEST_VIDEOS[@]}"; do
    if [ ! -f "files/${video}" ]; then
        echo "❌ Error: Source file not found: files/${video}"
        exit 1
    fi
    # Validate file is not empty
    if [ ! -s "files/${video}" ]; then
        echo "❌ Error: Source file is empty: files/${video}"
        exit 1
    fi
    echo "  ✓ Found: ${video} ($(stat -c%s "files/${video}") bytes)"
done

# Create directory and install files
install -d "${ROOTFS_DIR}/opt/hdmi-tester"

echo "Deploying test videos..."
for video in "${TEST_VIDEOS[@]}"; do
    install -m 644 -o 1000 -g 1000 "files/${video}" "${ROOTFS_DIR}/opt/hdmi-tester/"
    if [ ! -f "${ROOTFS_DIR}/opt/hdmi-tester/${video}" ]; then
        echo "❌ Error: Failed to copy ${video} to target"
        exit 1
    fi
    echo "  • ${video} deployed"
done

echo ""
echo "Validating deployed files..."
for video in "${TEST_VIDEOS[@]}"; do
    target_file="${ROOTFS_DIR}/opt/hdmi-tester/${video}"

    # Check file exists
    if [ ! -f "${target_file}" ]; then
        echo "❌ Error: Deployed file not found: ${video}"
        exit 1
    fi

    # Check file is not empty
    if [ ! -s "${target_file}" ]; then
        echo "❌ Error: Deployed file is empty: ${video}"
        exit 1
    fi

    # Compare sizes
    source_size=$(stat -c%s "files/${video}")
    target_size=$(stat -c%s "${target_file}")

    if [ "${source_size}" -ne "${target_size}" ]; then
        echo "❌ Error: File size mismatch for ${video}"
        echo "   Source: ${source_size} bytes"
        echo "   Target: ${target_size} bytes"
        exit 1
    fi

    echo "  ✓ Validated: ${video} (${target_size} bytes)"
done

echo "✅ All test videos deployed and validated successfully"
