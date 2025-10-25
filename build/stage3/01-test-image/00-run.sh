#!/bin/bash -e
# Deploy test videos (WebM format)

# Source common validation function
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
STAGE3_DIR="$(dirname "${SCRIPT_DIR}")"
source "${STAGE3_DIR}/00-common/validate-rootfs.sh"

# Validate ROOTFS_DIR using common function
validate_rootfs_dir || exit 1

# Validate source files exist
TEST_VIDEOS=("image-test.webm" "color-test.webm" "image-test.mp4" "color-test.mp4")
TEST_IMAGES=("black.png" "blue.png" "green.png" "red.png" "white.png" "image.png")
TEST_AUDIO=("audio.mp3")

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

for image in "${TEST_IMAGES[@]}"; do
    if [ ! -f "files/${image}" ]; then
        echo "❌ Error: Source file not found: files/${image}"
        exit 1
    fi
    if [ ! -s "files/${image}" ]; then
        echo "❌ Error: Source file is empty: files/${image}"
        exit 1
    fi
    echo "  ✓ Found: ${image} ($(stat -c%s "files/${image}") bytes)"
done

for audio in "${TEST_AUDIO[@]}"; do
    if [ ! -f "files/${audio}" ]; then
        echo "❌ Error: Source file not found: files/${audio}"
        exit 1
    fi
    if [ ! -s "files/${audio}" ]; then
        echo "❌ Error: Source file is empty: files/${audio}"
        exit 1
    fi
    echo "  ✓ Found: ${audio} ($(stat -c%s "files/${audio}") bytes)"
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

echo "Deploying test images..."
for image in "${TEST_IMAGES[@]}"; do
    install -m 644 -o 1000 -g 1000 "files/${image}" "${ROOTFS_DIR}/opt/hdmi-tester/"
    if [ ! -f "${ROOTFS_DIR}/opt/hdmi-tester/${image}" ]; then
        echo "❌ Error: Failed to copy ${image} to target"
        exit 1
    fi
    echo "  • ${image} deployed"
done

echo "Deploying test audio..."
for audio in "${TEST_AUDIO[@]}"; do
    install -m 644 -o 1000 -g 1000 "files/${audio}" "${ROOTFS_DIR}/opt/hdmi-tester/"
    if [ ! -f "${ROOTFS_DIR}/opt/hdmi-tester/${audio}" ]; then
        echo "❌ Error: Failed to copy ${audio} to target"
        exit 1
    fi
    echo "  • ${audio} deployed"
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

for image in "${TEST_IMAGES[@]}"; do
    target_file="${ROOTFS_DIR}/opt/hdmi-tester/${image}"

    if [ ! -f "${target_file}" ]; then
        echo "❌ Error: Deployed file not found: ${image}"
        exit 1
    fi

    if [ ! -s "${target_file}" ]; then
        echo "❌ Error: Deployed file is empty: ${image}"
        exit 1
    fi

    source_size=$(stat -c%s "files/${image}")
    target_size=$(stat -c%s "${target_file}")

    if [ "${source_size}" -ne "${target_size}" ]; then
        echo "❌ Error: File size mismatch for ${image}"
        echo "   Source: ${source_size} bytes"
        echo "   Target: ${target_size} bytes"
        exit 1
    fi

    echo "  ✓ Validated: ${image} (${target_size} bytes)"
done

for audio in "${TEST_AUDIO[@]}"; do
    target_file="${ROOTFS_DIR}/opt/hdmi-tester/${audio}"

    if [ ! -f "${target_file}" ]; then
        echo "❌ Error: Deployed file not found: ${audio}"
        exit 1
    fi

    if [ ! -s "${target_file}" ]; then
        echo "❌ Error: Deployed file is empty: ${audio}"
        exit 1
    fi

    source_size=$(stat -c%s "files/${audio}")
    target_size=$(stat -c%s "${target_file}")

    if [ "${source_size}" -ne "${target_size}" ]; then
        echo "❌ Error: File size mismatch for ${audio}"
        echo "   Source: ${source_size} bytes"
        echo "   Target: ${target_size} bytes"
        exit 1
    fi

    echo "  ✓ Validated: ${audio} (${target_size} bytes)"
done

echo "✅ All test videos, images, and audio deployed and validated successfully"
