#!/bin/bash
# Compare two build logs to identify differences
# Usage: ./compare-logs.sh <log_file_1> <log_file_2>

set -e
set -u

if [ $# -ne 2 ]; then
    echo "Usage: $0 <log_file_1> <log_file_2>"
    echo ""
    echo "Examples:"
    echo "  # Compare successful and failed build"
    echo "  $0 logs/successful-builds/build-2025-10-17_14-30-45_v1.0.0.log \\"
    echo "     logs/failed-builds/build-2025-10-17_15-22-10_FAILED.log"
    echo ""
    echo "  # Compare two successful builds"
    echo "  $0 logs/successful-builds/build-2025-10-17_14-30-45_v1.0.0.log \\"
    echo "     logs/successful-builds/build-2025-10-18_10-15-30_v1.0.1.log"
    exit 1
fi

LOG_FILE_1="$1"
LOG_FILE_2="$2"

# Helper function to handle compressed files
get_log_file() {
    local log_path="$1"

    if [ -f "${log_path}" ]; then
        echo "${log_path}"
    elif [ -f "${log_path}.gz" ]; then
        local temp_file=$(mktemp)
        gunzip -c "${log_path}.gz" > "${temp_file}"
        echo "${temp_file}"
    else
        echo ""
    fi
}

LOG1=$(get_log_file "${LOG_FILE_1}")
LOG2=$(get_log_file "${LOG_FILE_2}")

if [ -z "${LOG1}" ]; then
    echo "❌ Error: First log file not found: ${LOG_FILE_1}"
    exit 1
fi

if [ -z "${LOG2}" ]; then
    echo "❌ Error: Second log file not found: ${LOG_FILE_2}"
    exit 1
fi

echo "=================================================================="
echo "  BUILD LOG COMPARISON"
echo "=================================================================="
echo "Log 1: ${LOG_FILE_1}"
echo "Log 2: ${LOG_FILE_2}"
echo ""

# Compare metadata
echo "=================================================================="
echo "  METADATA COMPARISON"
echo "=================================================================="
echo ""
echo "--- Log 1 Metadata ---"
grep -E "^(Build Started|Build ID|Build Number|Commit|Branch):" "${LOG1}" 2>/dev/null || echo "No metadata found"
echo ""
echo "--- Log 2 Metadata ---"
grep -E "^(Build Started|Build ID|Build Number|Commit|Branch):" "${LOG2}" 2>/dev/null || echo "No metadata found"
echo ""

# Compare build outcomes
echo "=================================================================="
echo "  BUILD OUTCOME COMPARISON"
echo "=================================================================="

LOG1_STATUS="Unknown"
LOG2_STATUS="Unknown"

if grep -q "Status: ✅ SUCCESS" "${LOG1}"; then
    LOG1_STATUS="Success"
elif grep -q "Status: ❌ FAILED" "${LOG1}"; then
    LOG1_STATUS="Failed"
fi

if grep -q "Status: ✅ SUCCESS" "${LOG2}"; then
    LOG2_STATUS="Success"
elif grep -q "Status: ❌ FAILED" "${LOG2}"; then
    LOG2_STATUS="Failed"
fi

echo "Log 1: ${LOG1_STATUS}"
echo "Log 2: ${LOG2_STATUS}"
echo ""

# Compare durations
echo "=================================================================="
echo "  BUILD DURATION COMPARISON"
echo "=================================================================="

LOG1_DURATION=$(grep "Total Duration:" "${LOG1}" | tail -n 1 | awk '{print $3, $4}' 2>/dev/null || echo "Unknown")
LOG2_DURATION=$(grep "Total Duration:" "${LOG2}" | tail -n 1 | awk '{print $3, $4}' 2>/dev/null || echo "Unknown")

echo "Log 1: ${LOG1_DURATION}"
echo "Log 2: ${LOG2_DURATION}"
echo ""

# Compare stage timings
echo "=================================================================="
echo "  STAGE TIMING COMPARISON"
echo "=================================================================="
echo ""
echo "--- Log 1 Stage Timings ---"
grep -E "^  STAGE:|^Duration:" "${LOG1}" | paste - - 2>/dev/null || echo "No stage timing found"
echo ""
echo "--- Log 2 Stage Timings ---"
grep -E "^  STAGE:|^Duration:" "${LOG2}" | paste - - 2>/dev/null || echo "No stage timing found"
echo ""

# Compare errors
echo "=================================================================="
echo "  ERROR COMPARISON"
echo "=================================================================="

LOG1_ERRORS=$(grep -c "❌\|ERROR\|Error:" "${LOG1}" 2>/dev/null || echo "0")
LOG2_ERRORS=$(grep -c "❌\|ERROR\|Error:" "${LOG2}" 2>/dev/null || echo "0")

echo "Log 1 errors: ${LOG1_ERRORS}"
echo "Log 2 errors: ${LOG2_ERRORS}"
echo ""

if [ ${LOG1_ERRORS} -gt 0 ]; then
    echo "--- Log 1 Errors ---"
    grep -n "❌\|ERROR\|Error:" "${LOG1}" | head -n 10
    echo ""
fi

if [ ${LOG2_ERRORS} -gt 0 ]; then
    echo "--- Log 2 Errors ---"
    grep -n "❌\|ERROR\|Error:" "${LOG2}" | head -n 10
    echo ""
fi

# Compare disk usage
echo "=================================================================="
echo "  DISK USAGE COMPARISON"
echo "=================================================================="
echo ""
echo "--- Log 1 Final Disk Usage ---"
grep -A 5 "=== Final System State ===" "${LOG1}" | grep -A 3 "Disk Space:" | tail -n 3 || echo "No disk usage data"
echo ""
echo "--- Log 2 Final Disk Usage ---"
grep -A 5 "=== Final System State ===" "${LOG2}" | grep -A 3 "Disk Space:" | tail -n 3 || echo "No disk usage data"
echo ""

# Compare memory usage
echo "=================================================================="
echo "  MEMORY USAGE COMPARISON"
echo "=================================================================="
echo ""
echo "--- Log 1 Final Memory ---"
grep -A 3 "=== Final System State ===" "${LOG1}" | grep -A 3 "Memory:" | tail -n 2 || echo "No memory data"
echo ""
echo "--- Log 2 Final Memory ---"
grep -A 3 "=== Final System State ===" "${LOG2}" | grep -A 3 "Memory:" | tail -n 2 || echo "No memory data"
echo ""

# Compare checksums
echo "=================================================================="
echo "  CHECKSUM COMPARISON"
echo "=================================================================="
echo ""
echo "--- Log 1 Checksums ---"
grep "SHA256:" "${LOG1}" | head -n 5 || echo "No checksums found"
echo ""
echo "--- Log 2 Checksums ---"
grep "SHA256:" "${LOG2}" | head -n 5 || echo "No checksums found"
echo ""

# Compare package versions (if available)
echo "=================================================================="
echo "  TOOL VERSION COMPARISON"
echo "=================================================================="
echo ""
echo "--- Log 1 Tool Versions ---"
sed -n '/=== Tool Versions ===/,/^$/p' "${LOG1}" | grep -v "===" || echo "No version info"
echo ""
echo "--- Log 2 Tool Versions ---"
sed -n '/=== Tool Versions ===/,/^$/p' "${LOG2}" | grep -v "===" || echo "No version info"
echo ""

# Key differences
echo "=================================================================="
echo "  KEY DIFFERENCES"
echo "=================================================================="

if [ "${LOG1_STATUS}" != "${LOG2_STATUS}" ]; then
    echo "⚠️  BUILD OUTCOME DIFFERS:"
    echo "   Log 1: ${LOG1_STATUS}"
    echo "   Log 2: ${LOG2_STATUS}"
    echo ""
fi

if [ ${LOG1_ERRORS} -ne ${LOG2_ERRORS} ]; then
    echo "⚠️  ERROR COUNT DIFFERS:"
    echo "   Log 1: ${LOG1_ERRORS} errors"
    echo "   Log 2: ${LOG2_ERRORS} errors"
    echo ""
fi

# Check for unique errors
echo "Errors unique to Log 1:"
TEMP1=$(mktemp)
TEMP2=$(mktemp)
grep "❌\|ERROR\|Error:" "${LOG1}" 2>/dev/null | sed 's/.*: //' | sort -u > "${TEMP1}" || touch "${TEMP1}"
grep "❌\|ERROR\|Error:" "${LOG2}" 2>/dev/null | sed 's/.*: //' | sort -u > "${TEMP2}" || touch "${TEMP2}"
comm -23 "${TEMP1}" "${TEMP2}" | head -n 5
rm -f "${TEMP1}" "${TEMP2}"
echo ""

echo "Errors unique to Log 2:"
TEMP1=$(mktemp)
TEMP2=$(mktemp)
grep "❌\|ERROR\|Error:" "${LOG1}" 2>/dev/null | sed 's/.*: //' | sort -u > "${TEMP1}" || touch "${TEMP1}"
grep "❌\|ERROR\|Error:" "${LOG2}" 2>/dev/null | sed 's/.*: //' | sort -u > "${TEMP2}" || touch "${TEMP2}"
comm -13 "${TEMP1}" "${TEMP2}" | head -n 5
rm -f "${TEMP1}" "${TEMP2}"
echo ""

# Recommendations
echo "=================================================================="
echo "  ANALYSIS & RECOMMENDATIONS"
echo "=================================================================="

if [ "${LOG1_STATUS}" = "Success" ] && [ "${LOG2_STATUS}" = "Failed" ]; then
    echo "📊 Log 1 succeeded but Log 2 failed"
    echo ""
    echo "Possible causes:"
    echo "  - Environment differences (disk space, memory, packages)"
    echo "  - Code/configuration changes between builds"
    echo "  - Network issues during package downloads"
    echo "  - Timing-dependent failures"
    echo ""
    echo "Next steps:"
    echo "  1. Review unique errors in Log 2 (shown above)"
    echo "  2. Compare tool versions and environment variables"
    echo "  3. Check disk/memory availability in both builds"
    echo "  4. Review git commits between the two builds"
fi

if [ "${LOG1_STATUS}" = "Failed" ] && [ "${LOG2_STATUS}" = "Success" ]; then
    echo "📊 Log 1 failed but Log 2 succeeded"
    echo ""
    echo "The issue appears to have been resolved. Possible fixes:"
    echo "  - Environment improvements (more disk/memory)"
    echo "  - Code/configuration fixes"
    echo "  - Transient network issues resolved"
    echo ""
    echo "Review what changed between builds to confirm the fix."
fi

if [ "${LOG1_STATUS}" = "Success" ] && [ "${LOG2_STATUS}" = "Success" ]; then
    echo "✅ Both builds succeeded!"
    echo ""
    echo "Compare durations and resource usage to identify optimizations."
fi

if [ "${LOG1_STATUS}" = "Failed" ] && [ "${LOG2_STATUS}" = "Failed" ]; then
    echo "❌ Both builds failed"
    echo ""
    echo "Look for common errors that appear in both logs."
    echo "This suggests a persistent issue that needs addressing."
fi

echo ""
echo "=================================================================="
echo "  COMPARISON COMPLETE"
echo "=================================================================="
echo ""
echo "For detailed analysis of individual logs:"
echo "  ./scripts/analyze-logs.sh ${LOG_FILE_1}"
echo "  ./scripts/analyze-logs.sh ${LOG_FILE_2}"
echo ""

# Cleanup temp files if created
if [[ "${LOG1}" == /tmp/* ]]; then
    rm -f "${LOG1}"
fi
if [[ "${LOG2}" == /tmp/* ]]; then
    rm -f "${LOG2}"
fi
