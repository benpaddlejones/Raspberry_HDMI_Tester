#!/bin/bash
#==============================================================================
# Comprehensive Audio Diagnostic Test Script
# Run from USB in sudo mode to test all audio configurations
# Each test runs ONCE only - saves full diagnostics to USB
#==============================================================================

set -u  # Exit on undefined variable (but not set -e, we want to continue on failures)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the directory where this script is located (should be USB root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/audio-test-results"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
RESULTS_FILE="${OUTPUT_DIR}/test-results-${TIMESTAMP}.txt"
FULL_LOG="${OUTPUT_DIR}/full-diagnostic-${TIMESTAMP}.log"
PROGRESS_FILE="${OUTPUT_DIR}/.test-progress"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Initialize results file
cat > "${RESULTS_FILE}" << 'EOF'
==============================================================================
AUDIO DIAGNOSTIC TEST RESULTS
==============================================================================
EOF
date >> "${RESULTS_FILE}"
echo "" >> "${RESULTS_FILE}"

# Start full diagnostic log
# Use unbuffered output to ensure data is written immediately (survives crashes)
exec > >(stdbuf -oL -eL tee -a "${FULL_LOG}") 2>&1

echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}    COMPREHENSIVE AUDIO DIAGNOSTIC TEST SUITE${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""
echo "Results will be saved to: ${OUTPUT_DIR}"
echo "Progress file: ${PROGRESS_FILE}"
echo "Test results: ${RESULTS_FILE}"
echo "Full log: ${FULL_LOG}"
echo ""

#==============================================================================
# Helper Functions
#==============================================================================

log_test_result() {
    local test_num="$1"
    local test_name="$2"
    local result="$3"
    local details="$4"

    echo "" | tee -a "${RESULTS_FILE}"
    echo "Test${test_num}: ${test_name}" | tee -a "${RESULTS_FILE}"
    echo "  Result: ${result}" | tee -a "${RESULTS_FILE}"
    echo "  Details: ${details}" | tee -a "${RESULTS_FILE}"
    echo "" | tee -a "${RESULTS_FILE}"

    # Force immediate write to disk (survives crashes)
    sync
}

mark_test_complete() {
    local test_num="$1"
    echo "${test_num}" >> "${PROGRESS_FILE}"

    # Force immediate write to disk (survives crashes)
    sync
}

is_test_complete() {
    local test_num="$1"
    if [ -f "${PROGRESS_FILE}" ]; then
        grep -q "^${test_num}$" "${PROGRESS_FILE}" && return 0
    fi
    return 1
}

run_test_with_timeout() {
    local timeout_sec="$1"
    shift
    local cmd="$@"

    timeout "${timeout_sec}" bash -c "${cmd}" &
    local pid=$!
    wait $pid
    return $?
}

#==============================================================================
# System Information Gathering
#==============================================================================

echo -e "${BLUE}>>> Gathering System Information${NC}"
echo "==================== SYSTEM INFORMATION ====================" >> "${FULL_LOG}"

# Raspberry Pi Model
echo "Raspberry Pi Model:" | tee -a "${FULL_LOG}"
cat /proc/device-tree/model 2>/dev/null || echo "Unknown" | tee -a "${FULL_LOG}"
echo "" | tee -a "${FULL_LOG}"

# Kernel Version
echo "Kernel: $(uname -r)" | tee -a "${FULL_LOG}"
echo "" | tee -a "${FULL_LOG}"

# ALSA Version
echo "ALSA Version:" | tee -a "${FULL_LOG}"
cat /proc/asound/version 2>/dev/null | tee -a "${FULL_LOG}"
echo "" | tee -a "${FULL_LOG}"

#==============================================================================
# Discover Audio Cards
#==============================================================================

echo -e "${BLUE}>>> Discovering Audio Cards${NC}"
echo "==================== AUDIO CARDS ====================" >> "${FULL_LOG}"

declare -a CARD_NUMBERS
declare -a CARD_NAMES
declare -a CARD_DEVICES

# Parse aplay -l output
while IFS= read -r line; do
    if [[ "$line" =~ ^card\ ([0-9]+):\ ([^,]+),\ device\ ([0-9]+): ]]; then
        card_num="${BASH_REMATCH[1]}"
        card_name="${BASH_REMATCH[2]}"
        device_num="${BASH_REMATCH[3]}"

        CARD_NUMBERS+=("${card_num}")
        CARD_NAMES+=("${card_name}")
        CARD_DEVICES+=("${device_num}")

        echo "Found: Card ${card_num}, Device ${device_num}: ${card_name}" | tee -a "${FULL_LOG}"
    fi
done < <(aplay -l 2>/dev/null)

echo "" | tee -a "${FULL_LOG}"
echo "Total audio devices found: ${#CARD_NUMBERS[@]}" | tee -a "${FULL_LOG}"
echo "" | tee -a "${FULL_LOG}"

# Full aplay -l output
echo "Full aplay -l output:" >> "${FULL_LOG}"
aplay -l 2>&1 >> "${FULL_LOG}"
echo "" >> "${FULL_LOG}"

# ALSA card information
echo "ALSA Cards:" >> "${FULL_LOG}"
cat /proc/asound/cards 2>&1 >> "${FULL_LOG}"
echo "" >> "${FULL_LOG}"

# PCM devices
echo "PCM Devices:" >> "${FULL_LOG}"
cat /proc/asound/pcm 2>&1 >> "${FULL_LOG}"
echo "" >> "${FULL_LOG}"

#==============================================================================
# Test Media Files
#==============================================================================

TEST_VIDEO="/opt/hdmi-tester/image-test.mp4"
TEST_FLAC_STEREO="/opt/hdmi-tester/stereo.flac"
TEST_FLAC_51="/opt/hdmi-tester/surround51.flac"
SYSTEM_WAV="/usr/share/sounds/alsa/Front_Center.wav"

echo "==================== TEST MEDIA FILES ====================" >> "${FULL_LOG}"
for file in "${TEST_VIDEO}" "${TEST_FLAC_STEREO}" "${TEST_FLAC_51}" "${SYSTEM_WAV}"; do
    if [ -f "${file}" ]; then
        echo "✓ ${file}" | tee -a "${FULL_LOG}"
        ls -lh "${file}" >> "${FULL_LOG}"
        file "${file}" >> "${FULL_LOG}"
    else
        echo "✗ ${file} NOT FOUND" | tee -a "${FULL_LOG}"
    fi
done
echo "" >> "${FULL_LOG}"

#==============================================================================
# TEST SUITE
#==============================================================================

TEST_DURATION=10  # seconds per test
TEST_NUM=0

echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}    STARTING AUDIO TESTS${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""
echo "Each test will run for ${TEST_DURATION} seconds"
echo "Tests will NOT repeat if system crashes"
echo ""

# Loop through all discovered audio devices
for i in "${!CARD_NUMBERS[@]}"; do
    CARD="${CARD_NUMBERS[$i]}"
    NAME="${CARD_NAMES[$i]}"
    DEVICE="${CARD_DEVICES[$i]}"

    echo ""
    echo -e "${YELLOW}Testing Card ${CARD}: ${NAME} (Device ${DEVICE})${NC}"
    echo ""

    #--------------------------------------------------------------------------
    # TEST 1: aplay with plughw (with format conversion)
    #--------------------------------------------------------------------------
    TEST_NUM=$((TEST_NUM + 1))
    if is_test_complete "${TEST_NUM}"; then
        echo -e "${GREEN}Test${TEST_NUM}: ALREADY COMPLETED (SKIPPED)${NC}"
    else
        echo -e "${BLUE}>>> Test${TEST_NUM}: aplay plughw:${CARD},${DEVICE} with system WAV${NC}"
        echo "==================== Test${TEST_NUM} ====================" >> "${FULL_LOG}"
        echo "Command: aplay -D plughw:${CARD},${DEVICE} ${SYSTEM_WAV}" >> "${FULL_LOG}"

        RESULT="UNKNOWN"
        DETAILS=""

        if run_test_with_timeout ${TEST_DURATION} "aplay -D plughw:${CARD},${DEVICE} ${SYSTEM_WAV} 2>&1" >> "${FULL_LOG}"; then
            RESULT="COMPLETED"
            DETAILS="Test completed without crash"
        else
            EXIT_CODE=$?
            if [ ${EXIT_CODE} -eq 124 ]; then
                RESULT="TIMEOUT"
                DETAILS="Test timed out (normal)"
            else
                RESULT="CRASHED"
                DETAILS="Exit code: ${EXIT_CODE}"
            fi
        fi

        log_test_result "${TEST_NUM}" "aplay plughw:${CARD},${DEVICE} WAV" "${RESULT}" "${DETAILS}"
        mark_test_complete "${TEST_NUM}"
        echo ""
    fi

    #--------------------------------------------------------------------------
    # TEST 2: aplay with hw (direct hardware access)
    #--------------------------------------------------------------------------
    TEST_NUM=$((TEST_NUM + 1))
    if is_test_complete "${TEST_NUM}"; then
        echo -e "${GREEN}Test${TEST_NUM}: ALREADY COMPLETED (SKIPPED)${NC}"
    else
        echo -e "${BLUE}>>> Test${TEST_NUM}: aplay hw:${CARD},${DEVICE} with system WAV${NC}"
        echo "==================== Test${TEST_NUM} ====================" >> "${FULL_LOG}"
        echo "Command: aplay -D hw:${CARD},${DEVICE} ${SYSTEM_WAV}" >> "${FULL_LOG}"

        RESULT="UNKNOWN"
        DETAILS=""

        if run_test_with_timeout ${TEST_DURATION} "aplay -D hw:${CARD},${DEVICE} ${SYSTEM_WAV} 2>&1" >> "${FULL_LOG}"; then
            RESULT="COMPLETED"
            DETAILS="Test completed without crash"
        else
            EXIT_CODE=$?
            if [ ${EXIT_CODE} -eq 124 ]; then
                RESULT="TIMEOUT"
                DETAILS="Test timed out (normal)"
            else
                RESULT="CRASHED"
                DETAILS="Exit code: ${EXIT_CODE}"
            fi
        fi

        log_test_result "${TEST_NUM}" "aplay hw:${CARD},${DEVICE} WAV" "${RESULT}" "${DETAILS}"
        mark_test_complete "${TEST_NUM}"
        echo ""
    fi

    #--------------------------------------------------------------------------
    # TEST 3: aplay with dmix (software mixing)
    #--------------------------------------------------------------------------
    TEST_NUM=$((TEST_NUM + 1))
    if is_test_complete "${TEST_NUM}"; then
        echo -e "${GREEN}Test${TEST_NUM}: ALREADY COMPLETED (SKIPPED)${NC}"
    else
        echo -e "${BLUE}>>> Test${TEST_NUM}: aplay dmix:CARD=${CARD},DEV=${DEVICE} with system WAV${NC}"
        echo "==================== Test${TEST_NUM} ====================" >> "${FULL_LOG}"
        echo "Command: aplay -D dmix:CARD=${CARD},DEV=${DEVICE} ${SYSTEM_WAV}" >> "${FULL_LOG}"

        RESULT="UNKNOWN"
        DETAILS=""

        if run_test_with_timeout ${TEST_DURATION} "aplay -D dmix:CARD=${CARD},DEV=${DEVICE} ${SYSTEM_WAV} 2>&1" >> "${FULL_LOG}"; then
            RESULT="COMPLETED"
            DETAILS="Test completed without crash"
        else
            EXIT_CODE=$?
            if [ ${EXIT_CODE} -eq 124 ]; then
                RESULT="TIMEOUT"
                DETAILS="Test timed out (normal)"
            else
                RESULT="CRASHED"
                DETAILS="Exit code: ${EXIT_CODE}"
            fi
        fi

        log_test_result "${TEST_NUM}" "aplay dmix:CARD=${CARD},DEV=${DEVICE} WAV" "${RESULT}" "${DETAILS}"
        mark_test_complete "${TEST_NUM}"
        echo ""
    fi

    #--------------------------------------------------------------------------
    # TEST 4: VLC with MP4 (video + audio) using plughw
    #--------------------------------------------------------------------------
    TEST_NUM=$((TEST_NUM + 1))
    if is_test_complete "${TEST_NUM}"; then
        echo -e "${GREEN}Test${TEST_NUM}: ALREADY COMPLETED (SKIPPED)${NC}"
    else
        echo -e "${BLUE}>>> Test${TEST_NUM}: VLC plughw:${CARD},${DEVICE} with MP4${NC}"
        echo "==================== Test${TEST_NUM} ====================" >> "${FULL_LOG}"
        echo "Command: cvlc --intf dummy --aout=alsa --alsa-audio-device=plughw:${CARD},${DEVICE} ${TEST_VIDEO}" >> "${FULL_LOG}"

        RESULT="UNKNOWN"
        DETAILS=""

        if run_test_with_timeout ${TEST_DURATION} "cvlc --intf dummy --aout=alsa --alsa-audio-device=plughw:${CARD},${DEVICE} ${TEST_VIDEO} 2>&1" >> "${FULL_LOG}"; then
            RESULT="COMPLETED"
            DETAILS="Test completed without crash"
        else
            EXIT_CODE=$?
            if [ ${EXIT_CODE} -eq 124 ]; then
                RESULT="TIMEOUT"
                DETAILS="Test timed out (normal)"
            else
                RESULT="CRASHED"
                DETAILS="Exit code: ${EXIT_CODE}"
            fi
        fi

        log_test_result "${TEST_NUM}" "VLC plughw:${CARD},${DEVICE} MP4" "${RESULT}" "${DETAILS}"
        mark_test_complete "${TEST_NUM}"
        echo ""
    fi

    #--------------------------------------------------------------------------
    # TEST 5: VLC with MP4 using hw
    #--------------------------------------------------------------------------
    TEST_NUM=$((TEST_NUM + 1))
    if is_test_complete "${TEST_NUM}"; then
        echo -e "${GREEN}Test${TEST_NUM}: ALREADY COMPLETED (SKIPPED)${NC}"
    else
        echo -e "${BLUE}>>> Test${TEST_NUM}: VLC hw:${CARD},${DEVICE} with MP4${NC}"
        echo "==================== Test${TEST_NUM} ====================" >> "${FULL_LOG}"
        echo "Command: cvlc --intf dummy --aout=alsa --alsa-audio-device=hw:${CARD},${DEVICE} ${TEST_VIDEO}" >> "${FULL_LOG}"

        RESULT="UNKNOWN"
        DETAILS=""

        if run_test_with_timeout ${TEST_DURATION} "cvlc --intf dummy --aout=alsa --alsa-audio-device=hw:${CARD},${DEVICE} ${TEST_VIDEO} 2>&1" >> "${FULL_LOG}"; then
            RESULT="COMPLETED"
            DETAILS="Test completed without crash"
        else
            EXIT_CODE=$?
            if [ ${EXIT_CODE} -eq 124 ]; then
                RESULT="TIMEOUT"
                DETAILS="Test timed out (normal)"
            else
                RESULT="CRASHED"
                DETAILS="Exit code: ${EXIT_CODE}"
            fi
        fi

        log_test_result "${TEST_NUM}" "VLC hw:${CARD},${DEVICE} MP4" "${RESULT}" "${DETAILS}"
        mark_test_complete "${TEST_NUM}"
        echo ""
    fi

    #--------------------------------------------------------------------------
    # TEST 6: VLC with stereo FLAC using plughw
    #--------------------------------------------------------------------------
    if [ -f "${TEST_FLAC_STEREO}" ]; then
        TEST_NUM=$((TEST_NUM + 1))
        if is_test_complete "${TEST_NUM}"; then
            echo -e "${GREEN}Test${TEST_NUM}: ALREADY COMPLETED (SKIPPED)${NC}"
        else
            echo -e "${BLUE}>>> Test${TEST_NUM}: VLC plughw:${CARD},${DEVICE} with Stereo FLAC${NC}"
            echo "==================== Test${TEST_NUM} ====================" >> "${FULL_LOG}"
            echo "Command: cvlc --intf dummy --aout=alsa --alsa-audio-device=plughw:${CARD},${DEVICE} ${TEST_FLAC_STEREO}" >> "${FULL_LOG}"

            RESULT="UNKNOWN"
            DETAILS=""

            if run_test_with_timeout ${TEST_DURATION} "cvlc --intf dummy --aout=alsa --alsa-audio-device=plughw:${CARD},${DEVICE} ${TEST_FLAC_STEREO} 2>&1" >> "${FULL_LOG}"; then
                RESULT="COMPLETED"
                DETAILS="Test completed without crash"
            else
                EXIT_CODE=$?
                if [ ${EXIT_CODE} -eq 124 ]; then
                    RESULT="TIMEOUT"
                    DETAILS="Test timed out (normal)"
                else
                    RESULT="CRASHED"
                    DETAILS="Exit code: ${EXIT_CODE}"
                fi
            fi

            log_test_result "${TEST_NUM}" "VLC plughw:${CARD},${DEVICE} Stereo FLAC" "${RESULT}" "${DETAILS}"
            mark_test_complete "${TEST_NUM}"
            echo ""
        fi
    fi

    #--------------------------------------------------------------------------
    # TEST 7: VLC with 5.1 FLAC using plughw
    #--------------------------------------------------------------------------
    if [ -f "${TEST_FLAC_51}" ]; then
        TEST_NUM=$((TEST_NUM + 1))
        if is_test_complete "${TEST_NUM}"; then
            echo -e "${GREEN}Test${TEST_NUM}: ALREADY COMPLETED (SKIPPED)${NC}"
        else
            echo -e "${BLUE}>>> Test${TEST_NUM}: VLC plughw:${CARD},${DEVICE} with 5.1 FLAC${NC}"
            echo "==================== Test${TEST_NUM} ====================" >> "${FULL_LOG}"
            echo "Command: cvlc --intf dummy --aout=alsa --alsa-audio-device=plughw:${CARD},${DEVICE} ${TEST_FLAC_51}" >> "${FULL_LOG}"

            RESULT="UNKNOWN"
            DETAILS=""

            if run_test_with_timeout ${TEST_DURATION} "cvlc --intf dummy --aout=alsa --alsa-audio-device=plughw:${CARD},${DEVICE} ${TEST_FLAC_51} 2>&1" >> "${FULL_LOG}"; then
                RESULT="COMPLETED"
                DETAILS="Test completed without crash"
            else
                EXIT_CODE=$?
                if [ ${EXIT_CODE} -eq 124 ]; then
                    RESULT="TIMEOUT"
                    DETAILS="Test timed out (normal)"
                else
                    RESULT="CRASHED"
                    DETAILS="Exit code: ${EXIT_CODE}"
                fi
            fi

            log_test_result "${TEST_NUM}" "VLC plughw:${CARD},${DEVICE} 5.1 FLAC" "${RESULT}" "${DETAILS}"
            mark_test_complete "${TEST_NUM}"
            echo ""
        fi
    fi

    #--------------------------------------------------------------------------
    # TEST 8: speaker-test for device
    #--------------------------------------------------------------------------
    TEST_NUM=$((TEST_NUM + 1))
    if is_test_complete "${TEST_NUM}"; then
        echo -e "${GREEN}Test${TEST_NUM}: ALREADY COMPLETED (SKIPPED)${NC}"
    else
        echo -e "${BLUE}>>> Test${TEST_NUM}: speaker-test plughw:${CARD},${DEVICE}${NC}"
        echo "==================== Test${TEST_NUM} ====================" >> "${FULL_LOG}"
        echo "Command: speaker-test -D plughw:${CARD},${DEVICE} -c 2 -t wav" >> "${FULL_LOG}"

        RESULT="UNKNOWN"
        DETAILS=""

        if run_test_with_timeout ${TEST_DURATION} "speaker-test -D plughw:${CARD},${DEVICE} -c 2 -t wav 2>&1" >> "${FULL_LOG}"; then
            RESULT="COMPLETED"
            DETAILS="Test completed without crash"
        else
            EXIT_CODE=$?
            if [ ${EXIT_CODE} -eq 124 ]; then
                RESULT="TIMEOUT"
                DETAILS="Test timed out (normal)"
            else
                RESULT="CRASHED"
                DETAILS="Exit code: ${EXIT_CODE}"
            fi
        fi

        log_test_result "${TEST_NUM}" "speaker-test plughw:${CARD},${DEVICE}" "${RESULT}" "${DETAILS}"
        mark_test_complete "${TEST_NUM}"
        echo ""
    fi
done

#==============================================================================
# Additional Diagnostic Information
#==============================================================================

echo ""
echo -e "${BLUE}>>> Collecting Additional Diagnostic Information${NC}"
echo "==================== ADDITIONAL DIAGNOSTICS ====================" >> "${FULL_LOG}"

# Mixer settings for all cards
for i in "${!CARD_NUMBERS[@]}"; do
    CARD="${CARD_NUMBERS[$i]}"
    echo "Mixer settings for Card ${CARD}:" >> "${FULL_LOG}"
    amixer -c "${CARD}" 2>&1 >> "${FULL_LOG}"
    echo "" >> "${FULL_LOG}"
done

# PCM hardware parameters (if available)
for i in "${!CARD_NUMBERS[@]}"; do
    CARD="${CARD_NUMBERS[$i]}"
    DEVICE="${CARD_DEVICES[$i]}"
    if [ -f "/proc/asound/card${CARD}/pcm${DEVICE}p/sub0/hw_params" ]; then
        echo "Hardware parameters for Card ${CARD}, Device ${DEVICE}:" >> "${FULL_LOG}"
        cat "/proc/asound/card${CARD}/pcm${DEVICE}p/sub0/hw_params" 2>&1 >> "${FULL_LOG}"
        echo "" >> "${FULL_LOG}"
    fi
done

# Kernel messages related to audio
echo "Kernel messages (dmesg audio-related):" >> "${FULL_LOG}"
dmesg | grep -iE "snd|alsa|hdmi|audio" >> "${FULL_LOG}"
echo "" >> "${FULL_LOG}"

# Module information
echo "Loaded audio modules:" >> "${FULL_LOG}"
lsmod | grep -iE "snd|alsa" >> "${FULL_LOG}"
echo "" >> "${FULL_LOG}"

#==============================================================================
# Test Summary
#==============================================================================

echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}    TEST SUITE COMPLETE${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""
echo "Total tests run: ${TEST_NUM}"
echo ""
echo "Results saved to:"
echo "  - ${RESULTS_FILE}"
echo "  - ${FULL_LOG}"
echo ""
echo -e "${YELLOW}IMPORTANT: Review the results file and report:${NC}"
echo "  Test1: no sound / sound heard / system crashed"
echo "  Test2: no sound / sound heard / system crashed"
echo "  etc."
echo ""
echo -e "${GREEN}All diagnostic information has been saved to USB${NC}"
echo ""

# Display test results summary
cat "${RESULTS_FILE}"

exit 0
