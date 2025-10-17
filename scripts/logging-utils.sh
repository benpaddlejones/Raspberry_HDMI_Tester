#!/bin/bash
# Logging utilities for build system
# Provides structured logging, resource monitoring, and timing functions

# Initialize logging system
# Usage: init_logging <log_file>
init_logging() {
    local log_file="$1"

    # Export for use by other functions
    export BUILD_LOG_FILE="${log_file}"
    export BUILD_START_TIME=$(date +%s)
    export LAST_STAGE_TIME=$(date +%s)

    # Create log file with header
    {
        echo "=================================================================="
        echo "  RASPBERRY PI HDMI TESTER - BUILD LOG"
        echo "=================================================================="
        echo ""
        echo "Build Started: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "Build ID: ${GITHUB_RUN_ID:-LOCAL}"
        echo "Build Number: ${GITHUB_RUN_NUMBER:-N/A}"
        echo "Commit: ${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo 'N/A')}"
        echo "Branch: ${GITHUB_REF_NAME:-$(git branch --show-current 2>/dev/null || echo 'N/A')}"
        echo ""
    } > "${BUILD_LOG_FILE}"
}

# Log a section header
# Usage: log_section "Section Name"
log_section() {
    local section_name="$1"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

    {
        echo ""
        echo "=================================================================="
        echo "  ${section_name}"
        echo "=================================================================="
        echo "Timestamp: ${timestamp}"
        echo ""
    } | tee -a "${BUILD_LOG_FILE}"
}

# Log a subsection
# Usage: log_subsection "Subsection Name"
log_subsection() {
    local subsection_name="$1"

    {
        echo ""
        echo "--- ${subsection_name} ---"
        echo ""
    } | tee -a "${BUILD_LOG_FILE}"
}

# Log information (verbose - file only)
# Usage: log_info "message"
log_info() {
    local message="$1"
    echo "[INFO] ${message}" >> "${BUILD_LOG_FILE}"
}

# Log event (shown on terminal and in file)
# Usage: log_event "🎯" "message"
log_event() {
    local emoji="$1"
    local message="$2"
    echo "${emoji} ${message}" | tee -a "${BUILD_LOG_FILE}"
}

# Log command execution
# Usage: log_command "description" command args...
log_command() {
    local description="$1"
    shift

    log_info "Executing: $*"
    log_info "Description: ${description}"

    # Execute command and capture output
    local start_time=$(date +%s)
    local exit_code=0

    "$@" >> "${BUILD_LOG_FILE}" 2>&1 || exit_code=$?

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ ${exit_code} -eq 0 ]; then
        log_info "✓ Completed in ${duration}s"
    else
        log_info "✗ Failed with exit code ${exit_code} after ${duration}s"
    fi

    return ${exit_code}
}

# Capture system environment
# Usage: capture_environment
capture_environment() {
    log_section "Build Environment"

    {
        echo "=== System Information ==="
        echo "Hostname: $(hostname)"
        echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo ""

        echo "=== CPU Information ==="
        echo "Processor: $(grep "model name" /proc/cpuinfo | head -n1 | cut -d: -f2 | xargs)"
        echo "CPU Cores: $(nproc)"
        echo "CPU Architecture: $(lscpu | grep Architecture | awk '{print $2}')"
        echo ""

        echo "=== Memory Information ==="
        free -h
        echo ""

        echo "=== Disk Space ==="
        df -h
        echo ""

        echo "=== Available Disk Space in Working Directory ==="
        df -h . | tail -n1
        echo ""

        echo "=== Tool Versions ==="
        echo "Git: $(git --version)"
        echo "QEMU ARM: $(qemu-arm-static --version | head -n1)"
        echo "Debootstrap: $(debootstrap --version 2>&1 | head -n1)"
        echo "Kpartx: $(kpartx -v 2>&1 | head -n1 || echo 'kpartx installed')"
        echo "Parted: $(parted --version | head -n1)"
        echo "Zip: $(zip -v 2>&1 | head -n2 | tail -n1)"
        echo "JQ: $(jq --version)"
        echo "Bash: ${BASH_VERSION}"
        echo ""

        echo "=== Environment Variables ==="
        echo "USER: ${USER}"
        echo "HOME: ${HOME}"
        echo "SHELL: ${SHELL}"
        echo "PATH: ${PATH}"
        echo "PWD: ${PWD}"
        echo "GITHUB_WORKSPACE: ${GITHUB_WORKSPACE:-N/A}"
        echo "GITHUB_ACTOR: ${GITHUB_ACTOR:-N/A}"
        echo "GITHUB_WORKFLOW: ${GITHUB_WORKFLOW:-N/A}"
        echo ""
    } >> "${BUILD_LOG_FILE}"

    log_event "✅" "Environment captured"
}

# Monitor disk space
# Usage: monitor_disk_space "checkpoint_name"
monitor_disk_space() {
    local checkpoint="$1"

    {
        echo ""
        echo "=== Disk Usage at: ${checkpoint} ==="
        echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        df -h
        echo ""
        echo "Working Directory Usage:"
        du -sh . 2>/dev/null || echo "N/A"
        echo ""
    } >> "${BUILD_LOG_FILE}"
}

# Monitor memory usage
# Usage: monitor_memory "checkpoint_name"
monitor_memory() {
    local checkpoint="$1"

    {
        echo ""
        echo "=== Memory Usage at: ${checkpoint} ==="
        echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        free -h
        echo ""
    } >> "${BUILD_LOG_FILE}"
}

# Calculate and log file checksum
# Usage: log_checksum "file_path" "description"
log_checksum() {
    local file_path="$1"
    local description="$2"

    if [ -f "${file_path}" ]; then
        local checksum=$(sha256sum "${file_path}" | awk '{print $1}')
        local size=$(ls -lh "${file_path}" | awk '{print $5}')

        {
            echo "${description}:"
            echo "  File: ${file_path}"
            echo "  Size: ${size}"
            echo "  SHA256: ${checksum}"
        } >> "${BUILD_LOG_FILE}"

        log_info "Checksum logged for ${file_path}"
    else
        log_info "File not found for checksum: ${file_path}"
    fi
}

# Start timing a stage
# Usage: start_stage_timer "stage_name"
start_stage_timer() {
    local stage_name="$1"
    export CURRENT_STAGE="${stage_name}"
    export STAGE_START_TIME=$(date +%s)

    {
        echo ""
        echo "=================================================================="
        echo "  STAGE: ${stage_name}"
        echo "=================================================================="
        echo "Started: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo ""
    } >> "${BUILD_LOG_FILE}"

    log_event "🚀" "Starting: ${stage_name}"
}

# End timing a stage
# Usage: end_stage_timer "stage_name" <exit_code>
end_stage_timer() {
    local stage_name="$1"
    local exit_code="${2:-0}"
    local stage_end_time=$(date +%s)
    local duration=$((stage_end_time - STAGE_START_TIME))
    local duration_formatted=$(printf '%02d:%02d:%02d' $((duration/3600)) $((duration%3600/60)) $((duration%60)))

    {
        echo ""
        echo "Completed: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "Duration: ${duration_formatted} (${duration}s)"
        if [ ${exit_code} -eq 0 ]; then
            echo "Status: ✅ SUCCESS"
        else
            echo "Status: ❌ FAILED (exit code: ${exit_code})"
        fi
        echo "=================================================================="
        echo ""
    } >> "${BUILD_LOG_FILE}"

    if [ ${exit_code} -eq 0 ]; then
        log_event "✅" "Completed: ${stage_name} (${duration_formatted})"
    else
        log_event "❌" "Failed: ${stage_name} after ${duration_formatted}"
    fi

    # Update last stage time
    export LAST_STAGE_TIME=${stage_end_time}
}

# Log build configuration
# Usage: log_build_config "config_file"
log_build_config() {
    local config_file="$1"

    log_section "Build Configuration"

    {
        echo "Configuration file: ${config_file}"
        echo ""
        echo "=== Configuration Contents ==="
        cat "${config_file}" 2>/dev/null || echo "Config file not found"
        echo ""
    } >> "${BUILD_LOG_FILE}"

    log_event "✅" "Configuration logged"
}

# Log asset validation
# Usage: log_asset_validation "asset_path" "expected_type"
log_asset_validation() {
    local asset_path="$1"
    local expected_type="$2"

    {
        echo ""
        echo "=== Asset Validation: ${expected_type} ==="
        echo "Path: ${asset_path}"

        if [ -f "${asset_path}" ]; then
            echo "Status: ✅ Found"
            echo "Size: $(ls -lh "${asset_path}" | awk '{print $5}')"
            echo "Modified: $(stat -c '%y' "${asset_path}")"

            # Get file type
            echo "Type: $(file -b "${asset_path}")"

            # Get checksum
            echo "SHA256: $(sha256sum "${asset_path}" | awk '{print $1}')"

            # For images, get dimensions if possible
            if [[ "${expected_type}" == *"image"* ]] && command -v identify &> /dev/null; then
                echo "Dimensions: $(identify -format '%wx%h' "${asset_path}" 2>/dev/null || echo 'N/A')"
            fi

            # For audio, get details if possible
            if [[ "${expected_type}" == *"audio"* ]] && command -v ffprobe &> /dev/null; then
                echo "Audio Info:"
                ffprobe -v quiet -print_format json -show_format -show_streams "${asset_path}" 2>/dev/null || echo "N/A"
            fi
        else
            echo "Status: ❌ NOT FOUND"
        fi
        echo ""
    } >> "${BUILD_LOG_FILE}"
}

# Capture error context (surrounding log lines)
# Usage: capture_error_context "error_message" <lines_before> <lines_after>
capture_error_context() {
    local error_msg="$1"
    local lines_before="${2:-20}"
    local lines_after="${3:-20}"

    {
        echo ""
        echo "=================================================================="
        echo "  ERROR CONTEXT"
        echo "=================================================================="
        echo "Error: ${error_msg}"
        echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo ""
        echo "=== Log Context (${lines_before} lines before, ${lines_after} after) ==="
        echo ""

        # Get the last N lines from the log
        tail -n $((lines_before + lines_after)) "${BUILD_LOG_FILE}" 2>/dev/null || echo "No context available"

        echo ""
        echo "=================================================================="
        echo ""
    } >> "${BUILD_LOG_FILE}"
}

# Finalize log with summary
# Usage: finalize_log <success|failure> [error_message]
finalize_log() {
    local status="$1"
    local error_msg="${2:-}"
    local build_end_time=$(date +%s)
    local total_duration=$((build_end_time - BUILD_START_TIME))
    local duration_formatted=$(printf '%02d:%02d:%02d' $((total_duration/3600)) $((total_duration%3600/60)) $((total_duration%60)))

    {
        echo ""
        echo "=================================================================="
        echo "  BUILD SUMMARY"
        echo "=================================================================="
        echo "Build Completed: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "Total Duration: ${duration_formatted} (${total_duration}s)"

        if [ "${status}" == "success" ]; then
            echo "Status: ✅ SUCCESS"
        else
            echo "Status: ❌ FAILED"
            if [ -n "${error_msg}" ]; then
                echo "Error: ${error_msg}"
            fi
        fi

        echo ""
        echo "=== Final System State ==="
        echo ""
        echo "Disk Space:"
        df -h
        echo ""
        echo "Memory:"
        free -h
        echo ""

        echo "=================================================================="
        echo "  END OF BUILD LOG"
        echo "=================================================================="
    } >> "${BUILD_LOG_FILE}"
}

# Export functions for use in other scripts
export -f init_logging
export -f log_section
export -f log_subsection
export -f log_info
export -f log_event
export -f log_command
export -f capture_environment
export -f monitor_disk_space
export -f monitor_memory
export -f log_checksum
export -f start_stage_timer
export -f end_stage_timer
export -f log_build_config
export -f log_asset_validation
export -f capture_error_context
export -f finalize_log
