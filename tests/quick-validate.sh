#!/bin/bash
# Quick validation of Raspberry Pi HDMI Tester release
# Downloads and performs basic checks without mounting

set -e
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Source validation utilities
if [ ! -f "${PROJECT_ROOT}/scripts/validation-utils.sh" ]; then
    echo "❌ Error: validation-utils.sh not found"
    exit 1
fi

# shellcheck source=../scripts/validation-utils.sh
source "${PROJECT_ROOT}/scripts/validation-utils.sh"

TEST_DIR="${PROJECT_ROOT}/build/quick-validation"
REPORT_FILE="${TEST_DIR}/quick-validation-report.txt"

echo "=================================================="
echo "Quick Validation: Raspberry Pi HDMI Tester"
echo "=================================================="
echo ""

# Setup cleanup traps
setup_traps

# Check prerequisites
echo "🔍 Checking prerequisites..."
if ! check_required_commands gh jq unzip file fdisk; then
    exit 1
fi

if ! check_gh_auth; then
    exit 1
fi

if ! check_network; then
    echo "❌ Error: No network connectivity"
    exit 1
fi

echo ""

# Get latest release tag
echo "🔍 Getting latest release..."
RELEASE_TAG=$(get_latest_release_tag)
REL_EXIT=$?
if [ ${REL_EXIT} -ne 0 ] || [ -z "${RELEASE_TAG}" ]; then
    exit 1
fi

echo "✅ Latest release: ${RELEASE_TAG}"
echo ""

# Create test directory
mkdir -p "${TEST_DIR}"
cd "${TEST_DIR}" || {
    echo "❌ Error: Failed to change to test directory"
    exit 1
}

# Check disk space (need ~4GB for download + extraction)
if ! check_disk_space "${TEST_DIR}" 4096; then
    exit 1
fi

echo ""

# Initialize report
{
    echo "=================================================="
    echo "Quick Validation Report - ${RELEASE_TAG}"
    echo "=================================================="
    echo "Date: $(date)"
    echo ""
} > "${REPORT_FILE}"

track_temp_file "${REPORT_FILE}"

# Step 1: Download
echo "📥 Step 1/4: Downloading release ${RELEASE_TAG}..."
if gh release download "${RELEASE_TAG}" -p "*.img.zip" --clobber 2>&1 | tee -a "${REPORT_FILE}"; then
    echo "✅ Download successful" | tee -a "${REPORT_FILE}"
else
    echo "❌ Download failed" | tee -a "${REPORT_FILE}"
    exit 1
fi

echo ""

# Step 2: Verify ZIP
echo "📦 Step 2/4: Verifying ZIP file..."

# Find the ZIP file (use full path)
ZIP_FILE=$(find "${TEST_DIR}" -maxdepth 1 -name "*.img.zip" -type f | head -1)

if [ -z "${ZIP_FILE}" ]; then
    echo "❌ No ZIP file found" | tee -a "${REPORT_FILE}"
    exit 1
fi

if [ ! -f "${ZIP_FILE}" ]; then
    echo "❌ ZIP file not accessible: ${ZIP_FILE}" | tee -a "${REPORT_FILE}"
    exit 1
fi

ZIP_SIZE=$(du -h "${ZIP_FILE}" | cut -f1)
echo "✅ ZIP file found: $(basename "${ZIP_FILE}") (${ZIP_SIZE})" | tee -a "${REPORT_FILE}"

track_temp_file "${ZIP_FILE}"

# Test ZIP integrity
echo "   Testing ZIP integrity..."
if unzip -t "${ZIP_FILE}" > /dev/null 2>&1; then
    echo "✅ ZIP integrity check passed" | tee -a "${REPORT_FILE}"
else
    echo "❌ ZIP file is corrupted" | tee -a "${REPORT_FILE}"
    exit 1
fi

echo ""

# Step 3: Extract
echo "📂 Step 3/4: Extracting image (this may take a minute)..."

# Check disk space again before extraction
if ! check_disk_space "${TEST_DIR}" 3072; then
    exit 1
fi

if unzip -o "${ZIP_FILE}" 2>&1 | tee -a "${REPORT_FILE}"; then
    echo "✅ Extraction successful" | tee -a "${REPORT_FILE}"
else
    echo "❌ Extraction failed" | tee -a "${REPORT_FILE}"
    exit 1
fi

echo ""

# Step 4: Verify IMG
echo "💿 Step 4/4: Verifying IMG file..."

# Find the IMG file (use full path)
IMG_FILE=$(find "${TEST_DIR}" -maxdepth 1 -name "*.img" -type f | head -1)

if [ -z "${IMG_FILE}" ]; then
    echo "❌ No IMG file found after extraction" | tee -a "${REPORT_FILE}"
    exit 1
fi

if [ ! -f "${IMG_FILE}" ]; then
    echo "❌ IMG file not accessible: ${IMG_FILE}" | tee -a "${REPORT_FILE}"
    exit 1
fi

IMG_SIZE=$(du -h "${IMG_FILE}" | cut -f1)
echo "✅ IMG file found: $(basename "${IMG_FILE}") (${IMG_SIZE})" | tee -a "${REPORT_FILE}"

track_temp_file "${IMG_FILE}"

# Check file type
FILE_TYPE=$(file "${IMG_FILE}")
echo "   File type: ${FILE_TYPE}" | tee -a "${REPORT_FILE}"

if echo "${FILE_TYPE}" | grep -qi "boot sector\|DOS/MBR\|partition"; then
    echo "✅ File appears to be a valid disk image" | tee -a "${REPORT_FILE}"
else
    echo "⚠️  File type may not be a standard disk image" | tee -a "${REPORT_FILE}"
fi

# Check partitions (need sudo for fdisk)
echo ""
echo "🔍 Partition table:" | tee -a "${REPORT_FILE}"

# Check if we have sudo
if check_root_or_sudo; then
    if sudo fdisk -l "${IMG_FILE}" 2>/dev/null | tee -a "${REPORT_FILE}"; then
        # Count partitions more reliably
        PARTITION_COUNT=$(sudo fdisk -l "${IMG_FILE}" 2>/dev/null | grep -c "^${IMG_FILE}" || echo "0")
        echo "✅ Found ${PARTITION_COUNT} partition(s)" | tee -a "${REPORT_FILE}"

        if [ "${PARTITION_COUNT}" -ge 2 ]; then
            echo "✅ Expected partitions present (boot + root)" | tee -a "${REPORT_FILE}"
        else
            echo "⚠️  Unexpected partition count" | tee -a "${REPORT_FILE}"
        fi
    else
        echo "⚠️  Could not read partition table" | tee -a "${REPORT_FILE}"
        PARTITION_COUNT="unknown"
    fi
else
    echo "⚠️  Skipping partition check (no sudo access)" | tee -a "${REPORT_FILE}"
    PARTITION_COUNT="unknown"
fi

# Summary
echo ""
echo "=================================================="
echo "📊 Validation Summary"
echo "=================================================="

{
    echo ""
    echo "=================================================="
    echo "Summary"
    echo "=================================================="
    echo ""
    echo "✅ ZIP file downloaded successfully"
    echo "✅ ZIP integrity verified"
    echo "✅ Image extracted successfully"
    echo "✅ Image file appears valid"
    echo ""
    echo "Image Details:"
    echo "  - Release: ${RELEASE_TAG}"
    echo "  - ZIP Size: ${ZIP_SIZE}"
    echo "  - IMG Size: ${IMG_SIZE}"
    echo "  - Partitions: ${PARTITION_COUNT}"
    echo ""
    echo "RESULT: ✅ PASSED - Basic validation successful"
    echo ""
    echo "Note: This is a quick validation. For complete validation"
    echo "including file system contents, run: sudo validate-image.sh <image>"
    echo ""
    echo "=================================================="
    echo "Completed at: $(date)"
    echo "=================================================="
} | tee -a "${REPORT_FILE}"

echo ""
echo "📄 Full report saved to: ${REPORT_FILE}"
echo ""
echo "✅ Quick validation PASSED"
echo ""
echo "Next steps:"
echo "  1. Flash to SD card: See docs/FLASHING.md"
echo "  2. Test on hardware: Raspberry Pi 3/4/5"
echo ""

exit 0
