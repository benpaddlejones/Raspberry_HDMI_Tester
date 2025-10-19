#!/bin/bash
# Main build script for Raspberry Pi HDMI Tester image

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Catch errors in pipes

# Error handler function
error_handler() {
    local exit_code=$?
    local line_number=$1

    echo ""
    echo "❌ ERROR: Script failed at line ${line_number} with exit code ${exit_code}"
    echo "Last command: ${BASH_COMMAND}"
    echo ""

    # If logging is initialized, capture error context
    if [ -n "${BUILD_LOG_FILE:-}" ] && [ -f "${BUILD_LOG_FILE}" ]; then
        {
            echo ""
            echo "=================================================================="
            echo "  ERROR CAPTURED"
            echo "=================================================================="
            echo "Exit Code: ${exit_code}"
            echo "Line Number: ${line_number}"
            echo "Command: ${BASH_COMMAND}"
            echo "=================================================================="
        } >> "${BUILD_LOG_FILE}"
    fi

    exit ${exit_code}
}

# Trap errors and call error handler
trap 'error_handler ${LINENO}' ERR

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
PI_GEN_DIR="${PI_GEN_DIR:-/opt/pi-gen}"
WORK_DIR="${PROJECT_ROOT}/build/pi-gen-work"
CONFIG_FILE="${PROJECT_ROOT}/build/config"

# Clean any previous build BEFORE setting up logging
# (logging file lives in WORK_DIR, so we must clean before creating it)
if [ -d "${WORK_DIR}" ]; then
    echo "🧹 Cleaning previous build directory..."
    sudo rm -rf "${WORK_DIR}"
fi

# Setup logging
BUILD_TIMESTAMP=$(date -u '+%Y-%m-%d_%H-%M-%S')
BUILD_LOG_DIR="${PROJECT_ROOT}/logs"
BUILD_LOG_FILE="${WORK_DIR}/build-detailed.log"

# Source logging utilities
source "${SCRIPT_DIR}/logging-utils.sh"

# Initialize logging system - create directories first
mkdir -p "${BUILD_LOG_DIR}"
mkdir -p "${WORK_DIR}"
init_logging "${BUILD_LOG_FILE}"

# Terminal banner (simplified for clean output)
echo "=================================================="
echo "Raspberry Pi HDMI Tester - Image Builder"
echo "=================================================="
echo ""
echo "📝 Detailed logs: ${BUILD_LOG_FILE}"
echo ""

# Capture build environment
capture_environment

# Validate that required assets exist
start_stage_timer "Asset Validation"

log_asset_validation "${PROJECT_ROOT}/assets/image.png" "Test Pattern Image"
log_asset_validation "${PROJECT_ROOT}/assets/audio.mp3" "Test Audio File"

if [ ! -f "${PROJECT_ROOT}/assets/image.png" ]; then
    log_event "❌" "Test image not found at ${PROJECT_ROOT}/assets/image.png"
    end_stage_timer "Asset Validation" 1
    finalize_log "failure" "Missing test image asset"
    exit 1
fi

if [ ! -f "${PROJECT_ROOT}/assets/audio.mp3" ]; then
    log_event "❌" "Test audio not found at ${PROJECT_ROOT}/assets/audio.mp3"
    end_stage_timer "Asset Validation" 1
    finalize_log "failure" "Missing test audio asset"
    exit 1
fi

end_stage_timer "Asset Validation" 0
monitor_disk_space "After Asset Validation"

# Check prerequisites
start_stage_timer "Prerequisites Check"

log_subsection "Checking System Resources"

# Check available disk space (need at least 10GB for build)
AVAILABLE_SPACE_KB=$(df "${PROJECT_ROOT}" | tail -1 | awk '{print $4}')
AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE_KB / 1024 / 1024))
REQUIRED_SPACE_GB=10

log_info "Available disk space: ${AVAILABLE_SPACE_GB}GB"
log_info "Required disk space: ${REQUIRED_SPACE_GB}GB"

if [ ${AVAILABLE_SPACE_GB} -lt ${REQUIRED_SPACE_GB} ]; then
    log_event "❌" "Insufficient disk space: ${AVAILABLE_SPACE_GB}GB available, ${REQUIRED_SPACE_GB}GB required"
    end_stage_timer "Prerequisites Check" 1
    finalize_log "failure" "Insufficient disk space"
    exit 1
fi
log_info "✓ Sufficient disk space available"

# Check available memory (warn if less than 2GB)
AVAILABLE_MEMORY_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
AVAILABLE_MEMORY_GB=$((AVAILABLE_MEMORY_KB / 1024 / 1024))

log_info "Available memory: ${AVAILABLE_MEMORY_GB}GB"

if [ ${AVAILABLE_MEMORY_GB} -lt 2 ]; then
    log_event "⚠️" "Low memory: ${AVAILABLE_MEMORY_GB}GB available (2GB+ recommended)"
    log_info "Build may be slower or fail due to memory constraints"
else
    log_info "✓ Sufficient memory available"
fi

log_subsection "Checking Required Tools"
log_info "Checking for qemu-arm-static..."
if ! command -v qemu-arm-static &> /dev/null; then
    log_event "❌" "qemu-arm-static not found"
    log_info "Install with: sudo apt-get install qemu-user-static"
    end_stage_timer "Prerequisites Check" 1
    finalize_log "failure" "Missing qemu-arm-static"
    exit 1
fi
log_info "✓ qemu-arm-static found"

log_info "Checking for pi-gen directory..."
if [ ! -d "${PI_GEN_DIR}" ]; then
    log_event "❌" "pi-gen not found at ${PI_GEN_DIR}"
    log_info "Expected location: ${PI_GEN_DIR}"
    log_info "Clone with: sudo git clone https://github.com/RPi-Distro/pi-gen ${PI_GEN_DIR}"
    end_stage_timer "Prerequisites Check" 1
    finalize_log "failure" "pi-gen directory not found"
    exit 1
fi
log_info "✓ pi-gen directory found"

end_stage_timer "Prerequisites Check" 0
monitor_disk_space "After Prerequisites Check"
monitor_memory "After Prerequisites Check"

# Prepare working directory
start_stage_timer "Build Directory Setup"

log_subsection "Copying pi-gen"
log_info "Copying pi-gen from ${PI_GEN_DIR} to ${WORK_DIR}..."
# Copy contents of pi-gen directory, not the directory itself
cp -r "${PI_GEN_DIR}"/* "${WORK_DIR}/"
# Also copy hidden files (.git, .gitignore, etc.)
cp -r "${PI_GEN_DIR}"/.[!.]* "${WORK_DIR}/" 2>/dev/null || true
log_info "✓ pi-gen copied"

log_subsection "Removing original stage3, stage4, stage5"
log_info "Removing pi-gen's original stage3, stage4, stage5 directories to prevent conflicts..."
rm -rf "${WORK_DIR}/stage3"
rm -rf "${WORK_DIR}/stage4"
rm -rf "${WORK_DIR}/stage5"
log_info "✓ Original stage directories removed"

end_stage_timer "Build Directory Setup" 0
monitor_disk_space "After Build Directory Setup"

# Copy custom stage
start_stage_timer "Custom Stage Installation"

log_subsection "Installing Custom Stages"

# Override stage2 to fix Trixie-only package issues for Bookworm builds
log_info "Copying stage2 override (Bookworm compatibility fix)..."
cp -r "${PROJECT_ROOT}/build/stage2/01-sys-tweaks" "${WORK_DIR}/stage2/"
log_info "✓ stage2/01-sys-tweaks override installed (removes rpi-swap, rpi-loop-utils, rpi-usb-gadget)"

log_info "Copying stage3 (custom HDMI tester stage)..."
cp -r "${PROJECT_ROOT}/build/stage3" "${WORK_DIR}/"
log_info "✓ stage3 copied"

log_info "Skipping stages 4, 5..."
mkdir -p "${WORK_DIR}/stage4" "${WORK_DIR}/stage5"
cp "${PROJECT_ROOT}/build/stage4/SKIP" "${WORK_DIR}/stage4/"
cp "${PROJECT_ROOT}/build/stage5/SKIP" "${WORK_DIR}/stage5/"
log_info "✓ Stage skip files installed"

end_stage_timer "Custom Stage Installation" 0

# Copy config
start_stage_timer "Configuration Setup"

log_build_config "${CONFIG_FILE}"
log_info "Copying config to work directory..."
cp "${CONFIG_FILE}" "${WORK_DIR}/config"
log_info "✓ Configuration copied"

end_stage_timer "Configuration Setup" 0

# Copy assets to custom stages
start_stage_timer "Asset Deployment"

log_subsection "Creating Asset Directories"
mkdir -p "${WORK_DIR}/stage3/01-test-image/files"
mkdir -p "${WORK_DIR}/stage3/02-audio-test/files"
log_info "✓ Asset directories created"

log_subsection "Copying Test Pattern Image"
cp "${PROJECT_ROOT}/assets/image.png" "${WORK_DIR}/stage3/01-test-image/files/image.png"
log_checksum "${WORK_DIR}/stage3/01-test-image/files/image.png" "Test Pattern Image (Deployed)"
log_info "✓ Test pattern copied"

log_subsection "Copying Test Audio"
cp "${PROJECT_ROOT}/assets/audio.mp3" "${WORK_DIR}/stage3/02-audio-test/files/audio.mp3"
log_checksum "${WORK_DIR}/stage3/02-audio-test/files/audio.mp3" "Test Audio File (Deployed)"
log_info "✓ Test audio copied"

end_stage_timer "Asset Deployment" 0
monitor_disk_space "After Asset Deployment"
monitor_memory "Before pi-gen Build"

# Run build
start_stage_timer "pi-gen Build"

log_event "🚀" "Starting pi-gen build (this will take 30-60 minutes)..."
log_info "Build will download packages, bootstrap Debian, and create custom image"
log_info "Working directory: ${WORK_DIR}"

cd "${WORK_DIR}"

# Run build with full output capture
log_subsection "Executing pi-gen build.sh"
log_info "Command: sudo ./build.sh"

# Capture build output to temporary file for analysis
PIGEN_OUTPUT_FILE="${WORK_DIR}/pigen-output.log"
BUILD_EXIT_CODE=0

# Optimized: Single tee writes to detailed log, redirect stdout to output file
if sudo ./build.sh 2>&1 | tee -a "${BUILD_LOG_FILE}" > "${PIGEN_OUTPUT_FILE}"; then
    SHELL_EXIT_CODE=0
else
    SHELL_EXIT_CODE=$?
fi

# Check for failure indicators in pi-gen output
# pi-gen sometimes returns exit code 0 even when build fails internally
if grep -q "^\[[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\] Build failed" "${PIGEN_OUTPUT_FILE}"; then
    log_event "⚠️" "pi-gen reported build failure in output (despite exit code ${SHELL_EXIT_CODE})"
    BUILD_EXIT_CODE=1
    capture_error_context "pi-gen build failed (detected from output)" 50 50
elif [ ${SHELL_EXIT_CODE} -ne 0 ]; then
    log_event "⚠️" "pi-gen build.sh failed with exit code ${SHELL_EXIT_CODE}"
    BUILD_EXIT_CODE=${SHELL_EXIT_CODE}
    capture_error_context "pi-gen build.sh failed" 50 50
else
    log_info "✓ pi-gen build.sh completed successfully"
fi

# Clean up temporary output file
rm -f "${PIGEN_OUTPUT_FILE}"

end_stage_timer "pi-gen Build" ${BUILD_EXIT_CODE}
monitor_disk_space "After pi-gen Build"
monitor_memory "After pi-gen Build"

if [ ${BUILD_EXIT_CODE} -ne 0 ]; then
    log_event "❌" "Build failed - see detailed log for error context"
    finalize_log "failure" "pi-gen build failed"

    # Show last 50 lines of log to terminal for quick debugging
    echo ""
    echo "Last 50 lines of detailed log:"
    tail -n 50 "${BUILD_LOG_FILE}"

    exit 1
fi

# Validate deployment
start_stage_timer "Deployment Validation"

log_subsection "Checking Deploy Directory"
if [ ! -d "${WORK_DIR}/deploy" ]; then
    log_event "❌" "Deploy directory not found!"
    capture_error_context "Deploy directory missing" 30 10
    end_stage_timer "Deployment Validation" 1
    finalize_log "failure" "Deploy directory not created"
    exit 1
fi
log_info "✓ Deploy directory exists"

log_subsection "Listing Deploy Directory Contents"
{
    echo "Deploy directory contents:"
    ls -lah "${WORK_DIR}/deploy/"
    echo ""
} >> "${BUILD_LOG_FILE}"

# Find and validate image file (check for .img first, then .zip)
IMAGE_FILE=$(find "${WORK_DIR}/deploy/" -name "*.img" -type f 2>/dev/null | head -n 1)
if [ -z "${IMAGE_FILE}" ]; then
    log_info "No .img file found, checking for .zip files..."
    ZIP_FILE=$(find "${WORK_DIR}/deploy/" -name "*.zip" -type f 2>/dev/null | grep -v "lite" | head -n 1)

    if [ -z "${ZIP_FILE}" ]; then
        log_event "❌" "No .img or .zip file found in deploy directory!"
        end_stage_timer "Deployment Validation" 1
        finalize_log "failure" "No image file created"
        exit 1
    fi

    log_info "✓ Found ZIP file: ${ZIP_FILE}"
    log_event "📦" "Extracting image from ZIP archive..."

    # Extract the .img file from the zip
    if unzip -o "${ZIP_FILE}" -d "${WORK_DIR}/deploy/" >> "${BUILD_LOG_FILE}" 2>&1; then
        log_info "✓ ZIP extraction successful"
        IMAGE_FILE=$(find "${WORK_DIR}/deploy/" -name "*.img" -type f 2>/dev/null | head -n 1)

        if [ -z "${IMAGE_FILE}" ]; then
            log_event "❌" "No .img file found after extraction!"
            end_stage_timer "Deployment Validation" 1
            finalize_log "failure" "ZIP extraction did not produce .img file"
            exit 1
        fi
    else
        log_event "❌" "Failed to extract ZIP file!"
        end_stage_timer "Deployment Validation" 1
        finalize_log "failure" "ZIP extraction failed"
        exit 1
    fi
fi

log_info "✓ Image file found: ${IMAGE_FILE}"
log_checksum "${IMAGE_FILE}" "Final Image File"

end_stage_timer "Deployment Validation" 0

# Success!
finalize_log "success"

log_event "✅" "Build Complete!"
echo ""
echo "=================================================="
echo "📦 Output Image"
echo "=================================================="
echo "Location: ${IMAGE_FILE}"
echo "Size: $(ls -lh "${IMAGE_FILE}" | awk '{print $5}')"
echo ""
echo "📝 Detailed log: ${BUILD_LOG_FILE}"
echo ""
echo "Next steps:"
echo "  1. Test the image: ./tests/qemu-test.sh"
echo "  2. Flash to SD card: See docs/FLASHING.md"
echo ""
