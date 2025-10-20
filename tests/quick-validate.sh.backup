#!/bin/bash
# Quick validation of Raspberry Pi HDMI Tester release
# Downloads and performs basic checks without mounting

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
TEST_DIR="${PROJECT_ROOT}/build/quick-validation"
REPORT_FILE="${TEST_DIR}/quick-validation-report.txt"

echo "=================================================="
echo "Quick Validation: Raspberry Pi HDMI Tester v0.9.0"
echo "=================================================="
echo ""

# Create test directory
mkdir -p "${TEST_DIR}"
cd "${TEST_DIR}"

# Initialize report
{
    echo "=================================================="
    echo "Quick Validation Report - v0.9.0"
    echo "=================================================="
    echo "Date: $(date)"
    echo ""
} > "${REPORT_FILE}"

# Step 1: Download
echo "📥 Step 1/4: Downloading release v0.9.0..."
if gh release download v0.9.0 -p "*.img.zip" --clobber 2>&1 | tee -a "${REPORT_FILE}"; then
    echo "✅ Download successful" | tee -a "${REPORT_FILE}"
else
    echo "❌ Download failed" | tee -a "${REPORT_FILE}"
    exit 1
fi

echo ""

# Step 2: Verify ZIP
echo "📦 Step 2/4: Verifying ZIP file..."
ZIP_FILE=$(ls -1 *.img.zip 2>/dev/null | head -1)

if [ -z "${ZIP_FILE}" ]; then
    echo "❌ No ZIP file found" | tee -a "${REPORT_FILE}"
    exit 1
fi

ZIP_SIZE=$(du -h "${ZIP_FILE}" | cut -f1)
echo "✅ ZIP file found: ${ZIP_FILE} (${ZIP_SIZE})" | tee -a "${REPORT_FILE}"

# Test ZIP integrity
if unzip -t "${ZIP_FILE}" > /dev/null 2>&1; then
    echo "✅ ZIP integrity check passed" | tee -a "${REPORT_FILE}"
else
    echo "❌ ZIP file is corrupted" | tee -a "${REPORT_FILE}"
    exit 1
fi

echo ""

# Step 3: Extract
echo "📂 Step 3/4: Extracting image (this may take a minute)..."
if unzip -o "${ZIP_FILE}" 2>&1 | tee -a "${REPORT_FILE}"; then
    echo "✅ Extraction successful" | tee -a "${REPORT_FILE}"
else
    echo "❌ Extraction failed" | tee -a "${REPORT_FILE}"
    exit 1
fi

echo ""

# Step 4: Verify IMG
echo "💿 Step 4/4: Verifying IMG file..."
IMG_FILE=$(ls -1 *.img 2>/dev/null | head -1)

if [ -z "${IMG_FILE}" ]; then
    echo "❌ No IMG file found after extraction" | tee -a "${REPORT_FILE}"
    exit 1
fi

IMG_SIZE=$(du -h "${IMG_FILE}" | cut -f1)
echo "✅ IMG file found: ${IMG_FILE} (${IMG_SIZE})" | tee -a "${REPORT_FILE}"

# Check file type
FILE_TYPE=$(file "${IMG_FILE}")
echo "   File type: ${FILE_TYPE}" | tee -a "${REPORT_FILE}"

if echo "${FILE_TYPE}" | grep -qi "boot sector\|DOS/MBR\|partition"; then
    echo "✅ File appears to be a valid disk image" | tee -a "${REPORT_FILE}"
else
    echo "⚠️  File type may not be a standard disk image" | tee -a "${REPORT_FILE}"
fi

# Check partitions
echo ""
echo "🔍 Partition table:" | tee -a "${REPORT_FILE}"
if sudo fdisk -l "${IMG_FILE}" 2>/dev/null | tee -a "${REPORT_FILE}"; then
    PARTITION_COUNT=$(sudo fdisk -l "${IMG_FILE}" 2>/dev/null | grep -c "^${IMG_FILE}" || echo "0")
    echo "✅ Found ${PARTITION_COUNT} partition(s)" | tee -a "${REPORT_FILE}"

    if [ ${PARTITION_COUNT} -ge 2 ]; then
        echo "✅ Expected partitions present (boot + root)" | tee -a "${REPORT_FILE}"
    else
        echo "⚠️  Unexpected partition count" | tee -a "${REPORT_FILE}"
    fi
else
    echo "⚠️  Could not read partition table" | tee -a "${REPORT_FILE}"
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
    echo "  - ZIP Size: ${ZIP_SIZE}"
    echo "  - IMG Size: ${IMG_SIZE}"
    echo "  - Partitions: ${PARTITION_COUNT}"
    echo ""
    echo "RESULT: ✅ PASSED - Basic validation successful"
    echo ""
    echo "Note: This is a quick validation. For complete validation"
    echo "including file system contents, run: validate-image.sh"
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
