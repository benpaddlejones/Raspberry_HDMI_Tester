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
BUILD_ARCHIVED_LOG="${BUILD_LOG_DIR}/build-${BUILD_TIMESTAMP}.log"

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

log_asset_validation "${PROJECT_ROOT}/build/stage3/01-test-image/files/image-test.webm" "Image Test Video"
log_asset_validation "${PROJECT_ROOT}/build/stage3/01-test-image/files/color-test.webm" "Color Test Video"

if [ ! -f "${PROJECT_ROOT}/build/stage3/01-test-image/files/image-test.webm" ]; then
    log_event "❌" "Image test video not found at ${PROJECT_ROOT}/build/stage3/01-test-image/files/image-test.webm"
    end_stage_timer "Asset Validation" 1
    finalize_log "failure" "Missing image-test.webm"
    exit 1
fi

if [ ! -f "${PROJECT_ROOT}/build/stage3/01-test-image/files/color-test.webm" ]; then
    log_event "❌" "Color test video not found at ${PROJECT_ROOT}/build/stage3/01-test-image/files/color-test.webm"
    end_stage_timer "Asset Validation" 1
    finalize_log "failure" "Missing color-test.webm"
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

# MEDIUM PRIORITY FIX: Check disk space before starting build
log_info "Checking disk space for build directory..."
BUILD_DIR_SPACE_REQUIRED_MB=10240  # 10GB minimum for pi-gen build

WORK_DIR_AVAILABLE_KB=$(df "${PROJECT_ROOT}/build" | tail -1 | awk '{print $4}')
WORK_DIR_AVAILABLE_MB=$((WORK_DIR_AVAILABLE_KB / 1024))

log_info "Build directory: ${PROJECT_ROOT}/build"
log_info "Available space: ${WORK_DIR_AVAILABLE_MB}MB"
log_info "Required space: ${BUILD_DIR_SPACE_REQUIRED_MB}MB"

if [ ${WORK_DIR_AVAILABLE_MB} -lt ${BUILD_DIR_SPACE_REQUIRED_MB} ]; then
    log_event "❌" "Insufficient disk space for build"
    log_info "Required: ${BUILD_DIR_SPACE_REQUIRED_MB}MB (10GB)"
    log_info "Available: ${WORK_DIR_AVAILABLE_MB}MB"
    log_info "Free up space or use a different build location"
    end_stage_timer "Prerequisites Check" 1
    finalize_log "failure" "Insufficient disk space in build directory"
    exit 1
fi
log_info "✓ Sufficient disk space for build"

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

# HIGH PRIORITY FIX: Validate asset files (WebM and MP4 videos with embedded audio)
log_subsection "Validating Asset Files"
IMAGE_TEST_WEBM="${PROJECT_ROOT}/build/stage3/01-test-image/files/image-test.webm"
COLOR_TEST_WEBM="${PROJECT_ROOT}/build/stage3/01-test-image/files/color-test.webm"
IMAGE_TEST_MP4="${PROJECT_ROOT}/build/stage3/01-test-image/files/image-test.mp4"
COLOR_TEST_MP4="${PROJECT_ROOT}/build/stage3/01-test-image/files/color-test.mp4"

# Validate WebM files (used by Pi 4+)
log_info "Checking WebM test videos (Pi 4+ format)..."
if [ ! -f "${IMAGE_TEST_WEBM}" ]; then
    log_event "❌" "Image test video not found: ${IMAGE_TEST_WEBM}"
    end_stage_timer "Prerequisites Check" 1
    finalize_log "failure" "Missing image-test.webm"
    exit 1
fi
log_info "✓ image-test.webm exists ($(stat -c%s "${IMAGE_TEST_WEBM}" | numfmt --to=iec-i --suffix=B))"

if [ ! -f "${COLOR_TEST_WEBM}" ]; then
    log_event "❌" "Color test video not found: ${COLOR_TEST_WEBM}"
    end_stage_timer "Prerequisites Check" 1
    finalize_log "failure" "Missing color-test.webm"
    exit 1
fi
log_info "✓ color-test.webm exists ($(stat -c%s "${COLOR_TEST_WEBM}" | numfmt --to=iec-i --suffix=B))"

# Validate MP4 files (used by Pi 3 and earlier)
log_info "Checking MP4 test videos (Pi 3 and earlier format)..."
if [ ! -f "${IMAGE_TEST_MP4}" ]; then
    log_event "❌" "Image test video not found: ${IMAGE_TEST_MP4}"
    end_stage_timer "Prerequisites Check" 1
    finalize_log "failure" "Missing image-test.mp4"
    exit 1
fi
log_info "✓ image-test.mp4 exists ($(stat -c%s "${IMAGE_TEST_MP4}" | numfmt --to=iec-i --suffix=B))"

if [ ! -f "${COLOR_TEST_MP4}" ]; then
    log_event "❌" "Color test video not found: ${COLOR_TEST_MP4}"
    end_stage_timer "Prerequisites Check" 1
    finalize_log "failure" "Missing color-test.mp4"
    exit 1
fi
log_info "✓ color-test.mp4 exists ($(stat -c%s "${COLOR_TEST_MP4}" | numfmt --to=iec-i --suffix=B))"

# Validate codecs if ffprobe is available
if command -v ffprobe &>/dev/null; then
    log_info "Validating WebM codecs (VP9/Vorbis/Opus)..."
    
    if ffprobe -v error -show_entries stream=codec_name,width,height -of default=noprint_wrappers=1 "${IMAGE_TEST_WEBM}" >> "${BUILD_LOG_FILE}" 2>&1; then
        VIDEO_INFO=$(ffprobe -v error -show_entries stream=codec_name,width,height -of default=noprint_wrappers=1:nokey=1 "${IMAGE_TEST_WEBM}" 2>/dev/null | tr '\n' ' ')
        log_info "✓ image-test.webm validated: ${VIDEO_INFO}"
    else
        log_event "⚠️" "Warning: Could not validate image-test.webm (file may be corrupted)"
        log_info "Build will continue, but runtime playback may fail on Pi 4+"
    fi

    if ffprobe -v error -show_entries stream=codec_name,width,height -of default=noprint_wrappers=1 "${COLOR_TEST_WEBM}" >> "${BUILD_LOG_FILE}" 2>&1; then
        VIDEO_INFO=$(ffprobe -v error -show_entries stream=codec_name,width,height -of default=noprint_wrappers=1:nokey=1 "${COLOR_TEST_WEBM}" 2>/dev/null | tr '\n' ' ')
        log_info "✓ color-test.webm validated: ${VIDEO_INFO}"
    else
        log_event "⚠️" "Warning: Could not validate color-test.webm (file may be corrupted)"
        log_info "Build will continue, but runtime playback may fail on Pi 4+"
    fi
    
    log_info "Validating MP4 codecs (H.264)..."
    
    if ffprobe -v error -show_entries stream=codec_name,width,height -of default=noprint_wrappers=1 "${IMAGE_TEST_MP4}" >> "${BUILD_LOG_FILE}" 2>&1; then
        VIDEO_INFO=$(ffprobe -v error -show_entries stream=codec_name,width,height -of default=noprint_wrappers=1:nokey=1 "${IMAGE_TEST_MP4}" 2>/dev/null | tr '\n' ' ')
        # Verify it's H.264
        if echo "${VIDEO_INFO}" | grep -q "h264"; then
            log_info "✓ image-test.mp4 validated: ${VIDEO_INFO}"
        else
            log_event "⚠️" "Warning: image-test.mp4 is not H.264 format (found: ${VIDEO_INFO})"
            log_info "Pi 3 and earlier may not play this file correctly"
        fi
    else
        log_event "⚠️" "Warning: Could not validate image-test.mp4 (file may be corrupted)"
        log_info "Build will continue, but runtime playback may fail on Pi 3 and earlier"
    fi
    
    if ffprobe -v error -show_entries stream=codec_name,width,height -of default=noprint_wrappers=1 "${COLOR_TEST_MP4}" >> "${BUILD_LOG_FILE}" 2>&1; then
        VIDEO_INFO=$(ffprobe -v error -show_entries stream=codec_name,width,height -of default=noprint_wrappers=1:nokey=1 "${COLOR_TEST_MP4}" 2>/dev/null | tr '\n' ' ')
        # Verify it's H.264
        if echo "${VIDEO_INFO}" | grep -q "h264"; then
            log_info "✓ color-test.mp4 validated: ${VIDEO_INFO}"
        else
            log_event "⚠️" "Warning: color-test.mp4 is not H.264 format (found: ${VIDEO_INFO})"
            log_info "Pi 3 and earlier may not play this file correctly"
        fi
    else
        log_event "⚠️" "Warning: Could not validate color-test.mp4 (file may be corrupted)"
        log_info "Build will continue, but runtime playback may fail on Pi 3 and earlier"
    fi
else
    log_info "ℹ️  ffprobe not available, skipping codec validation"
fi

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

log_subsection "Removing original stage3, stage4, stage5 and stage2 EXPORT_IMAGE"
log_info "Removing pi-gen's original stage3, stage4, stage5 directories to prevent conflicts..."
rm -rf "${WORK_DIR}/stage3"
rm -rf "${WORK_DIR}/stage4"
rm -rf "${WORK_DIR}/stage5"
log_info "✓ Original stage directories removed"

log_info "Removing stage2/EXPORT_IMAGE to prevent building unwanted lite image..."
if [ -f "${WORK_DIR}/stage2/EXPORT_IMAGE" ]; then
    rm -f "${WORK_DIR}/stage2/EXPORT_IMAGE"
    log_info "✓ stage2/EXPORT_IMAGE removed - only stage3 image will be built"
else
    log_info "⚠ stage2/EXPORT_IMAGE not found (already removed or doesn't exist)"
fi

end_stage_timer "Build Directory Setup" 0
monitor_disk_space "After Build Directory Setup"

# Copy custom stage
start_stage_timer "Custom Stage Installation"

log_subsection "Installing Custom Stages"

# CRITICAL FIX: Validate custom stage files exist before copying
log_info "Validating custom stage files..."
STAGE3_SOURCE="${PROJECT_ROOT}/build/stage3"
declare -a REQUIRED_STAGE_FILES=(
    "00-install-packages/00-packages"
    "01-test-image/00-run.sh"
    "01-test-image/files/image-test.webm"
    "01-test-image/files/color-test.webm"
    "02-audio-test/00-run.sh"
    "02-audio-test/files/stereo.flac"
    "02-audio-test/files/surround51.flac"
    "03-autostart/00-run.sh"
    "03-autostart/files/hdmi-test"
    "03-autostart/files/pixel-test"
    "03-autostart/files/full-test"
    "03-autostart/files/hdmi-diagnostics"
    "03-autostart/files/detect-hdmi-audio"
    "03-autostart/files/hdmi-test.service"
    "03-autostart/files/pixel-test.service"
    "03-autostart/files/audio-test.service"
    "03-autostart/files/full-test.service"
    "04-boot-config/00-run.sh"
)

for file in "${REQUIRED_STAGE_FILES[@]}"; do
    if [ ! -e "${STAGE3_SOURCE}/${file}" ]; then
        log_event "❌" "Missing required custom stage file: ${file}"
        capture_error_context "Custom stage validation failed: ${file} not found"
        finalize_log "failure" "Missing custom stage file: ${file}"
        exit 1
    fi
done
log_info "✓ All required custom stage files validated"

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

log_subsection "Verifying WebM Video Files"
# WebM files are already in place in stage3/01-test-image/files/
# No need to copy from assets - they're built directly in the stage directory

log_checksum "${PROJECT_ROOT}/build/stage3/01-test-image/files/image-test.webm" "Image Test Video"
log_checksum "${PROJECT_ROOT}/build/stage3/01-test-image/files/color-test.webm" "Color Test Video"

# Verify files exist
if [ ! -f "${PROJECT_ROOT}/build/stage3/01-test-image/files/image-test.webm" ]; then
    log_event "❌" "Failed to find image-test.webm"
    end_stage_timer "Asset Deployment" 1
    finalize_log "failure" "Missing image-test.webm"
    exit 1
fi

if [ ! -f "${PROJECT_ROOT}/build/stage3/01-test-image/files/color-test.webm" ]; then
    log_event "❌" "Failed to find color-test.webm"
    end_stage_timer "Asset Deployment" 1
    finalize_log "failure" "Missing color-test.webm"
    exit 1
fi

log_info "✓ Both WebM video files verified"

end_stage_timer "Asset Deployment" 0
monitor_disk_space "After Asset Deployment"
monitor_memory "Before pi-gen Build"

## Ensure deploy directory exists and is writable before build
DEPLOY_DIR="${WORK_DIR}/deploy"
if [ ! -d "${DEPLOY_DIR}" ]; then
    log_info "Creating deploy directory: ${DEPLOY_DIR}"
    mkdir -p "${DEPLOY_DIR}"
fi
chmod 777 "${DEPLOY_DIR}"
log_info "✓ Deploy directory ready and writable"

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

# Start progress monitor in background
# This will print periodic updates to show build is progressing
(
    sleep 60  # Wait 1 minute before first update
    while true; do
        if [ -f "${BUILD_LOG_FILE}" ]; then
            LAST_LINE=$(tail -n 1 "${BUILD_LOG_FILE}" 2>/dev/null | cut -c1-80)
            if [ -n "${LAST_LINE}" ]; then
                echo "[$(date '+%H:%M:%S')] Build in progress: ${LAST_LINE}..."
            fi
        fi
        sleep 120  # Update every 2 minutes
    done
) &
PROGRESS_PID=$!

# Optimized: Single tee writes to detailed log, redirect stdout to output file
if sudo ./build.sh 2>&1 | tee -a "${BUILD_LOG_FILE}" > "${PIGEN_OUTPUT_FILE}"; then
    SHELL_EXIT_CODE=0
else
    SHELL_EXIT_CODE=$?
fi

# Stop progress monitor
kill ${PROGRESS_PID} 2>/dev/null || true
wait ${PROGRESS_PID} 2>/dev/null || true

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

# Early deduplication - run zerofree to reduce image size before any further processing
start_stage_timer "Early Deduplication"

log_event "🔧" "Running early deduplication with zerofree..."
log_info "This optimizes the image by zeroing free space, reducing file size"
log_info "Benefits: Faster compression, smaller final archive, less disk usage"

# Check if zerofree is available
if ! command -v zerofree &> /dev/null; then
    log_event "⚠️" "zerofree not found - installing..."
    sudo apt-get update -qq 2>&1 | tee -a "${BUILD_LOG_FILE}" > /dev/null
    sudo apt-get install -y zerofree 2>&1 | tee -a "${BUILD_LOG_FILE}" > /dev/null
    log_info "✓ zerofree installed"
fi

# Setup loop device for the image
log_info "Setting up loop device for image..."
LOOP_DEVICE=$(sudo losetup -f)
log_info "Using loop device: ${LOOP_DEVICE}"

if sudo losetup -P "${LOOP_DEVICE}" "${IMAGE_FILE}" 2>&1 | tee -a "${BUILD_LOG_FILE}" > /dev/null; then
    log_info "✓ Loop device attached"
else
    log_event "⚠️" "Failed to attach loop device - skipping deduplication"
    end_stage_timer "Early Deduplication" 1
    # Non-fatal error - continue with build
    LOOP_DEVICE=""
fi

if [ -n "${LOOP_DEVICE}" ]; then
    # Find the root partition (usually partition 2)
    ROOT_PARTITION="${LOOP_DEVICE}p2"

    if [ -b "${ROOT_PARTITION}" ]; then
        log_info "Running zerofree on root partition: ${ROOT_PARTITION}"

        # Run zerofree (must be on unmounted or read-only partition)
        DEDUP_START=$(date +%s)
        if sudo zerofree -v "${ROOT_PARTITION}" 2>&1 | tee -a "${BUILD_LOG_FILE}" > /dev/null; then
            DEDUP_END=$(date +%s)
            DEDUP_TIME=$((DEDUP_END - DEDUP_START))

            log_info "✓ Deduplication complete in ${DEDUP_TIME} seconds"
            log_event "✅" "Deduplication successful - image optimized"
        else
            log_event "⚠️" "zerofree failed (non-fatal) - continuing build"
        fi
    else
        log_event "⚠️" "Root partition ${ROOT_PARTITION} not found - skipping deduplication"
    fi

    # Cleanup: detach loop device
    log_info "Detaching loop device..."
    if sudo losetup -d "${LOOP_DEVICE}" 2>&1 | tee -a "${BUILD_LOG_FILE}" > /dev/null; then
        log_info "✓ Loop device detached"
    else
        log_event "⚠️" "Failed to detach loop device (may require manual cleanup)"
    fi
fi

monitor_disk_space "After Early Deduplication"
end_stage_timer "Early Deduplication" 0

# Aggressive cleanup of intermediate build artifacts
start_stage_timer "Build Cleanup"

log_event "🧹" "Cleaning up intermediate build artifacts..."
log_info "This will free up 3-5GB of disk space"

# Optimized cleanup: Single find command for efficiency
log_subsection "Cleaning build artifacts"
if [ -d "${WORK_DIR}/work" ]; then
    # Count items before deletion for reporting
    APT_COUNT=$(find "${WORK_DIR}/work" -path "*/rootfs/var/cache/apt/*" -type f 2>/dev/null | wc -l)
    TMP_COUNT=$(find "${WORK_DIR}/work" -path "*/rootfs/tmp/*" -type f 2>/dev/null | wc -l)
    DEB_COUNT=$(find "${WORK_DIR}/work" -name "*.deb" -type f 2>/dev/null | wc -l)

    log_info "Found ${APT_COUNT} apt cache files, ${TMP_COUNT} temp files, ${DEB_COUNT} .deb packages"

    # Single find with multiple conditions for efficiency
    # Removes: apt cache, tmp files, and .deb packages in one pass
    find "${WORK_DIR}/work" \( \
        -path "*/rootfs/var/cache/apt/*" -o \
        -path "*/rootfs/tmp/*" -o \
        -name "*.deb" \
    \) -type f -delete 2>/dev/null || true

    log_info "✓ Build artifacts cleaned (${APT_COUNT} + ${TMP_COUNT} + ${DEB_COUNT} files)"
else
    log_info "⚠️  No work directory found to clean"
fi

# Monitor disk space savings
monitor_disk_space "After Build Cleanup"

log_event "✅" "Cleanup complete - build artifacts removed"

end_stage_timer "Build Cleanup" 0

# Generate build time breakdown for GitHub Actions summary
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    log_info "Generating build time breakdown for GitHub Actions summary..."

    {
        echo "## 📊 Build Time Breakdown"
        echo ""
        echo "| Stage | Duration | Status |"
        echo "|-------|----------|--------|"

        # Extract stage timing from build log
        # Format: STAGE line followed by Duration line a few lines later
        awk '
            /^  STAGE:/ {
                stage = substr($0, index($0, "STAGE:") + 7)
                gsub(/^[ \t]+|[ \t]+$/, "", stage)  # Trim whitespace
            }
            /^Duration:/ && stage != "" {
                duration = $2
                getline  # Read next line for status
                if ($0 ~ /SUCCESS/) {
                    status = "✅"
                } else if ($0 ~ /FAILED/) {
                    status = "❌"
                } else {
                    status = "⏸️"
                }
                printf "| %s | %s | %s |\n", stage, duration, status
                stage = ""
            }
        ' "${BUILD_LOG_FILE}"

        echo ""
    } >> "${GITHUB_STEP_SUMMARY}"

    log_info "✓ Build time breakdown added to GitHub Actions summary"
fi

# Success!
finalize_log "success"

# Archive the detailed log with timestamp for future reference
if [ -f "${BUILD_LOG_FILE}" ]; then
    cp "${BUILD_LOG_FILE}" "${BUILD_ARCHIVED_LOG}"
    log_info "Build log archived to: ${BUILD_ARCHIVED_LOG}"
fi

log_event "✅" "Build Complete!"
echo ""
echo "=================================================="
echo "📦 Output Image"
echo "=================================================="
echo "Location: ${IMAGE_FILE}"
echo "Size: $(ls -lh "${IMAGE_FILE}" | awk '{print $5}')"
echo ""
echo "📝 Detailed log: ${BUILD_LOG_FILE}"
echo "📝 Archived log: ${BUILD_ARCHIVED_LOG}"
echo ""
echo "Next steps:"
echo "  1. Test the image: ./tests/qemu-test.sh"
echo "  2. Flash to SD card: See docs/FLASHING.md"
echo ""
