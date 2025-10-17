#!/bin/bash
# Analyze build log for errors, warnings, and key information
# Usage: ./analyze-logs.sh <log_file>

set -e
set -u

if [ $# -eq 0 ]; then
    echo "Usage: $0 <log_file>"
    echo ""
    echo "Examples:"
    echo "  $0 logs/failed-builds/build-2025-10-17_15-22-10_FAILED.log"
    echo "  $0 build/pi-gen-work/build-detailed.log"
    exit 1
fi

LOG_FILE="$1"

if [ ! -f "${LOG_FILE}" ]; then
    # Check if it's compressed
    if [ -f "${LOG_FILE}.gz" ]; then
        echo "📦 Log file is compressed, decompressing..."
        LOG_FILE="${LOG_FILE}.gz"
        TEMP_LOG=$(mktemp)
        gunzip -c "${LOG_FILE}" > "${TEMP_LOG}"
        LOG_FILE="${TEMP_LOG}"
        CLEANUP_TEMP=true
    else
        echo "❌ Error: Log file not found: ${LOG_FILE}"
        exit 1
    fi
fi

echo "=================================================================="
echo "  BUILD LOG ANALYSIS"
echo "=================================================================="
echo "Log file: ${LOG_FILE}"
echo "File size: $(ls -lh "${LOG_FILE}" | awk '{print $5}')"
echo ""

# Extract build metadata
echo "=================================================================="
echo "  BUILD METADATA"
echo "=================================================================="
grep -E "^(Build Started|Build ID|Build Number|Commit|Branch):" "${LOG_FILE}" 2>/dev/null || echo "No metadata found"
echo ""

# Check build status
echo "=================================================================="
echo "  BUILD STATUS"
echo "=================================================================="
if grep -q "Status: ✅ SUCCESS" "${LOG_FILE}"; then
    echo "✅ Build succeeded"
elif grep -q "Status: ❌ FAILED" "${LOG_FILE}"; then
    echo "❌ Build failed"
else
    echo "⚠️  Build status unknown"
fi
echo ""

# Extract build summary
if grep -q "BUILD SUMMARY" "${LOG_FILE}"; then
    echo "=================================================================="
    echo "  BUILD SUMMARY"
    echo "=================================================================="
    sed -n '/BUILD SUMMARY/,/END OF BUILD LOG/p' "${LOG_FILE}" | head -n 20
    echo ""
fi

# Count errors and warnings
echo "=================================================================="
echo "  ERROR AND WARNING SUMMARY"
echo "=================================================================="
ERROR_COUNT=$(grep -c "❌\|ERROR\|Error:" "${LOG_FILE}" 2>/dev/null || echo "0")
WARNING_COUNT=$(grep -c "⚠️\|WARNING\|Warning:" "${LOG_FILE}" 2>/dev/null || echo "0")
FAILED_COUNT=$(grep -c "FAILED\|Failed" "${LOG_FILE}" 2>/dev/null || echo "0")

echo "Errors: ${ERROR_COUNT}"
echo "Warnings: ${WARNING_COUNT}"
echo "Failed operations: ${FAILED_COUNT}"
echo ""

# Show all errors
if [ ${ERROR_COUNT} -gt 0 ]; then
    echo "=================================================================="
    echo "  ERRORS FOUND"
    echo "=================================================================="
    grep -n "❌\|ERROR\|Error:" "${LOG_FILE}" | head -n 50
    echo ""
fi

# Show stage timings
echo "=================================================================="
echo "  STAGE TIMINGS"
echo "=================================================================="
grep -E "^  STAGE:" "${LOG_FILE}" 2>/dev/null || echo "No stage information found"
grep "Duration:" "${LOG_FILE}" | tail -n 20 2>/dev/null || echo "No timing information found"
echo ""

# Show disk space progression
echo "=================================================================="
echo "  DISK SPACE PROGRESSION"
echo "=================================================================="
grep -A 2 "=== Disk Usage at:" "${LOG_FILE}" | grep -E "(=== Disk Usage|Filesystem|/dev)" | head -n 20 || echo "No disk usage information found"
echo ""

# Show memory usage
echo "=================================================================="
echo "  MEMORY USAGE"
echo "=================================================================="
grep -A 3 "=== Memory Usage at:" "${LOG_FILE}" | tail -n 10 || echo "No memory usage information found"
echo ""

# Show checksums
echo "=================================================================="
echo "  FILE CHECKSUMS"
echo "=================================================================="
grep -B 1 "SHA256:" "${LOG_FILE}" | grep -E "(Image|Audio|SHA256)" | head -n 20 || echo "No checksum information found"
echo ""

# Error context
if grep -q "ERROR CONTEXT" "${LOG_FILE}"; then
    echo "=================================================================="
    echo "  ERROR CONTEXT (CAPTURED)"
    echo "=================================================================="
    sed -n '/ERROR CONTEXT/,/==================================================================$/p' "${LOG_FILE}" | tail -n 50
    echo ""
fi

# Recommendations
echo "=================================================================="
echo "  RECOMMENDATIONS"
echo "=================================================================="

if [ ${ERROR_COUNT} -gt 0 ]; then
    echo "⚠️  Errors detected:"
    echo "   1. Review the ERRORS FOUND section above"
    echo "   2. Check ERROR CONTEXT for surrounding log lines"
    echo "   3. Verify disk space and memory availability"
    echo "   4. Check if required dependencies are installed"
fi

if grep -q "No space left on device" "${LOG_FILE}"; then
    echo "🚨 DISK SPACE ISSUE DETECTED"
    echo "   - Increase available disk space"
    echo "   - Clean up old builds: rm -rf build/pi-gen-work/*"
    echo "   - Check: df -h"
fi

if grep -q "Cannot allocate memory\|Out of memory" "${LOG_FILE}"; then
    echo "🚨 MEMORY ISSUE DETECTED"
    echo "   - Increase available memory"
    echo "   - Close other applications"
    echo "   - Check: free -h"
fi

if grep -q "E: Failed to fetch\|404 Not Found" "${LOG_FILE}"; then
    echo "🚨 NETWORK/PACKAGE ISSUE DETECTED"
    echo "   - Check internet connectivity"
    echo "   - Verify package repositories are accessible"
    echo "   - Try: apt-get update"
fi

if [ ${ERROR_COUNT} -eq 0 ] && grep -q "✅ SUCCESS" "${LOG_FILE}"; then
    echo "✅ Build completed successfully!"
    echo "   - Image file should be in build/pi-gen-work/deploy/"
    echo "   - Next: Test with QEMU or flash to SD card"
fi

echo ""
echo "=================================================================="
echo "  ANALYSIS COMPLETE"
echo "=================================================================="
echo ""
echo "For more details, view the full log:"
echo "  less ${LOG_FILE}"
echo ""
echo "To compare with another build:"
echo "  ./scripts/compare-logs.sh ${LOG_FILE} <other_log_file>"
echo ""

# Cleanup temp file if created
if [ "${CLEANUP_TEMP:-false}" = "true" ]; then
    rm -f "${TEMP_LOG}"
fi
