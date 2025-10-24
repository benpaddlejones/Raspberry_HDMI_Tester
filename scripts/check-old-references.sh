#!/bin/bash
# Script to check for old service and file name references

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

echo "=========================================="
echo "Checking for Old Service/Script References"
echo "=========================================="
echo ""

# Define old names to search for
OLD_NAMES=(
    "hd-audio-test-vlc"
    "pixel-audio-test-vlc"
    "full-test-vlc"
    "test-image-loop-vlc"
    "test-color-fullscreen-vlc"
    "test-both-loop-vlc"
    "color_test.webm"
)

# Directories to exclude from search
EXCLUDE_DIRS=(
    ".git"
    "logs"
    "node_modules"
    ".devcontainer"
    "rpi4"
)

# Build exclude parameters for grep
EXCLUDE_PARAMS=""
for dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_PARAMS="${EXCLUDE_PARAMS} --exclude-dir=${dir}"
done

FOUND_REFERENCES=false
TOTAL_MATCHES=0

echo "Searching for old references (excluding: ${EXCLUDE_DIRS[*]})..."
echo ""

# Search for each old name
for old_name in "${OLD_NAMES[@]}"; do
    echo "Checking for: ${old_name}"

    # Search recursively, excluding binary files and specified directories
    MATCHES=$(grep -r -I -n ${EXCLUDE_PARAMS} "${old_name}" "${PROJECT_ROOT}" 2>/dev/null || true)

    if [ -n "${MATCHES}" ]; then
        FOUND_REFERENCES=true
        COUNT=$(echo "${MATCHES}" | wc -l)
        TOTAL_MATCHES=$((TOTAL_MATCHES + COUNT))

        echo "  ❌ Found ${COUNT} reference(s):"
        echo "${MATCHES}" | while IFS= read -r line; do
            echo "     ${line}"
        done
        echo ""
    else
        echo "  ✅ No references found"
        echo ""
    fi
done

echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""

if [ "${FOUND_REFERENCES}" = true ]; then
    echo "❌ Found ${TOTAL_MATCHES} total reference(s) to old names"
    echo ""
    echo "These references should be updated to the new naming convention:"
    echo "  - hd-audio-test-vlc → hdmi-test"
    echo "  - pixel-audio-test-vlc → pixel-test"
    echo "  - full-test-vlc → full-test"
    echo "  - test-image-loop-vlc → hdmi-test"
    echo "  - test-color-fullscreen-vlc → pixel-test"
    echo "  - test-both-loop-vlc → full-test"
    echo "  - color_test.webm → color-test.webm"
    echo ""
    exit 1
else
    echo "✅ No references to old names found!"
    echo "All files have been updated to the new naming convention."
    echo ""
    exit 0
fi
