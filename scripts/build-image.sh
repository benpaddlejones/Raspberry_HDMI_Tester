#!/bin/bash
# Main build script for Raspberry Pi HDMI Tester image

set -e
set -u

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
PI_GEN_DIR="${PI_GEN_DIR:-/opt/pi-gen}"
WORK_DIR="${PROJECT_ROOT}/build/pi-gen-work"
CONFIG_FILE="${PROJECT_ROOT}/build/config"

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

log_subsection "Checking Required Tools"
log_info "Checking for qemu-arm-static..."
if ! command -v qemu-arm-static &> /dev/null; then
    log_event "❌" "qemu-arm-static not found"
    end_stage_timer "Prerequisites Check" 1
    finalize_log "failure" "Missing qemu-arm-static"
    exit 1
fi
log_info "✓ qemu-arm-static found"

log_info "Checking for pi-gen directory..."
if [ ! -d "${PI_GEN_DIR}" ]; then
    log_event "❌" "pi-gen not found at ${PI_GEN_DIR}"
    end_stage_timer "Prerequisites Check" 1
    finalize_log "failure" "pi-gen directory not found"
    exit 1
fi
log_info "✓ pi-gen found at ${PI_GEN_DIR}"

log_info "Checking for build config..."
if [ ! -f "${CONFIG_FILE}" ]; then
    log_event "❌" "Build config not found at ${CONFIG_FILE}"
    end_stage_timer "Prerequisites Check" 1
    finalize_log "failure" "Build config file not found"
    exit 1
fi
log_info "✓ Build config found"

end_stage_timer "Prerequisites Check" 0
monitor_disk_space "After Prerequisites Check"

# Prepare working directory
start_stage_timer "Build Directory Setup"

log_subsection "Cleaning Previous Build"
if [ -d "${WORK_DIR}" ]; then
    log_info "Removing existing work directory..."
    sudo rm -rf "${WORK_DIR}"
    log_info "✓ Previous build directory removed"
fi

log_subsection "Copying pi-gen"
log_info "Copying pi-gen from ${PI_GEN_DIR} to ${WORK_DIR}..."
cp -r "${PI_GEN_DIR}" "${WORK_DIR}"
log_info "✓ pi-gen copied"

end_stage_timer "Build Directory Setup" 0
monitor_disk_space "After Build Directory Setup"

# Copy custom stage
start_stage_timer "Custom Stage Installation"

log_subsection "Installing Custom Stages"
log_info "Copying stage-custom..."
cp -r "${PROJECT_ROOT}/build/stage-custom" "${WORK_DIR}/"
log_info "✓ stage-custom copied"

log_info "Skipping stages 3, 4, 5..."
cp "${PROJECT_ROOT}/build/stage3/SKIP" "${WORK_DIR}/stage3/"
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
mkdir -p "${WORK_DIR}/stage-custom/01-test-image/files"
mkdir -p "${WORK_DIR}/stage-custom/02-audio-test/files"
log_info "✓ Asset directories created"

log_subsection "Copying Test Pattern Image"
cp "${PROJECT_ROOT}/assets/image.png" "${WORK_DIR}/stage-custom/01-test-image/files/test-pattern.png"
log_checksum "${WORK_DIR}/stage-custom/01-test-image/files/test-pattern.png" "Test Pattern Image (Deployed)"
log_info "✓ Test pattern copied"

log_subsection "Copying Test Audio"
cp "${PROJECT_ROOT}/assets/audio.mp3" "${WORK_DIR}/stage-custom/02-audio-test/files/test-audio.mp3"
log_checksum "${WORK_DIR}/stage-custom/02-audio-test/files/test-audio.mp3" "Test Audio File (Deployed)"
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

BUILD_EXIT_CODE=0
if sudo ./build.sh 2>&1 | tee -a "${BUILD_LOG_FILE}" > /dev/null; then
    log_info "✓ pi-gen build.sh completed successfully"
else
    BUILD_EXIT_CODE=$?
    log_info "✗ pi-gen build.sh failed with exit code ${BUILD_EXIT_CODE}"
    capture_error_context "pi-gen build.sh failed" 50 50
fi

end_stage_timer "pi-gen Build" ${BUILD_EXIT_CODE}
monitor_disk_space "After pi-gen Build"
monitor_memory "After pi-gen Build"

if [ ${BUILD_EXIT_CODE} -ne 0 ]; then
    log_event "❌" "Build failed - see detailed log for error context"
    finalize_log "failure" "pi-gen build.sh failed with exit code ${BUILD_EXIT_CODE}"

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

# Find and validate image file
IMAGE_FILE=$(find "${WORK_DIR}/deploy/" -name "*.img" -type f 2>/dev/null | head -n 1)
if [ -z "${IMAGE_FILE}" ]; then
    log_event "❌" "No .img file found in deploy directory!"
    end_stage_timer "Deployment Validation" 1
    finalize_log "failure" "No image file created"
    exit 1
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
