#!/bin/bash
# Validation utilities for robust script execution
# Provides cleanup, error handling, and verification functions

# Global variables for cleanup tracking
declare -a CLEANUP_MOUNTS=()
declare -a CLEANUP_LOOP_DEVICES=()
declare -a CLEANUP_TEMP_DIRS=()
declare -a CLEANUP_TEMP_FILES=()

# Cleanup function - called on exit
cleanup_all() {
    local exit_code=$?

    # Disable exit on error during cleanup
    set +e

    echo ""
    echo "🧹 Cleaning up resources..."

    local cleanup_failed=0

    # Unmount all tracked mounts (in reverse order)
    for ((i=${#CLEANUP_MOUNTS[@]}-1; i>=0; i--)); do
        local mount="${CLEANUP_MOUNTS[i]}"
        if mountpoint -q "${mount}" 2>/dev/null; then
            echo "  Unmounting: ${mount}"
            if ! sudo umount "${mount}" 2>/dev/null; then
                echo "  ⚠️  Failed to unmount ${mount}, checking for processes..."

                # HIGH PRIORITY FIX: Check for processes using the mount
                if command -v lsof &>/dev/null; then
                    local procs=$(sudo lsof +D "${mount}" 2>/dev/null | tail -n +2 | awk '{print $2}' | sort -u || true)
                    if [ -n "${procs}" ]; then
                        echo "  ⚠️  Processes still using mount: ${procs}"
                        echo "  Terminating processes..."
                        for pid in ${procs}; do
                            sudo kill -TERM ${pid} 2>/dev/null || true
                        done
                        sleep 2

                        # Force kill if still running
                        for pid in ${procs}; do
                            if kill -0 ${pid} 2>/dev/null; then
                                sudo kill -KILL ${pid} 2>/dev/null || true
                            fi
                        done
                        sleep 1
                    fi
                fi

                # Try regular unmount again
                if ! sudo umount "${mount}" 2>/dev/null; then
                    echo "  ⚠️  Still failed, trying lazy unmount..."
                    if ! sudo umount -l "${mount}" 2>/dev/null; then
                        echo "  ❌ Failed to unmount ${mount}"
                        cleanup_failed=1
                    fi
                fi
            fi
        fi
    done

    # Detach all tracked loop devices
    for loop in "${CLEANUP_LOOP_DEVICES[@]}"; do
        if [ -e "${loop}" ]; then
            echo "  Detaching loop device: ${loop}"
            if ! sudo losetup -d "${loop}" 2>/dev/null; then
                echo "  ❌ Failed to detach ${loop}"
                cleanup_failed=1
            fi
        fi
    done

    # Also clean up any loop devices associated with IMAGE_FILE if set
    if [ -n "${IMAGE_FILE:-}" ] && [ -f "${IMAGE_FILE}" ]; then
        local abs_image_path
        abs_image_path=$(readlink -f "${IMAGE_FILE}")
        while IFS= read -r loop_line; do
            local loop_dev
            loop_dev=$(echo "${loop_line}" | awk '{print $1}')
            if [ -n "${loop_dev}" ] && [ -e "${loop_dev}" ]; then
                echo "  Detaching loop device: ${loop_dev} (associated with image)"
                sudo losetup -d "${loop_dev}" 2>/dev/null || true
            fi
        done < <(sudo losetup -l | grep "${abs_image_path}" || true)
    fi

    # Remove temporary directories
    for dir in "${CLEANUP_TEMP_DIRS[@]}"; do
        if [ -d "${dir}" ]; then
            echo "  Removing temp directory: ${dir}"
            if ! rm -rf "${dir}" 2>/dev/null; then
                echo "  ⚠️  Failed to remove ${dir}"
                cleanup_failed=1
            fi
        fi
    done

    # Remove temporary files
    for file in "${CLEANUP_TEMP_FILES[@]}"; do
        if [ -f "${file}" ]; then
            echo "  Removing temp file: ${file}"
            if ! rm -f "${file}" 2>/dev/null; then
                echo "  ⚠️  Failed to remove ${file}"
                cleanup_failed=1
            fi
        fi
    done

    if [ ${cleanup_failed} -eq 0 ]; then
        echo "✅ Cleanup complete"
    else
        echo "⚠️  Cleanup completed with some failures"
    fi

    # Re-enable exit on error if it was set
    set -e

    exit ${exit_code}
}

# Setup signal traps
setup_traps() {
    trap cleanup_all EXIT
    trap 'echo ""; echo "⚠️  Interrupted by user"; exit 130' INT
    trap 'echo ""; echo "⚠️  Terminated"; exit 143' TERM
    trap 'echo ""; echo "⚠️  Hangup signal received"; exit 129' HUP
}

# Track mount point for cleanup
track_mount() {
    local mount_point="$1"
    CLEANUP_MOUNTS+=("${mount_point}")
}

# Track loop device for cleanup
track_loop_device() {
    local loop_device="$1"
    CLEANUP_LOOP_DEVICES+=("${loop_device}")
}

# Track temp directory for cleanup
track_temp_dir() {
    local temp_dir="$1"
    CLEANUP_TEMP_DIRS+=("${temp_dir}")
}

# Track temp file for cleanup
track_temp_file() {
    local temp_file="$1"
    CLEANUP_TEMP_FILES+=("${temp_file}")
}

# Check if running as root or with sudo
check_root_or_sudo() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    fi

    if ! sudo -n true 2>/dev/null; then
        echo "❌ Error: This script requires sudo privileges"
        echo "Please run with sudo or configure passwordless sudo"
        return 1
    fi

    return 0
}

# Check required commands exist
check_required_commands() {
    local commands=("$@")
    local missing=()

    for cmd in "${commands[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            missing+=("${cmd}")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "❌ Error: Missing required commands: ${missing[*]}"
        echo ""
        echo "Please install the missing packages:"
        for cmd in "${missing[@]}"; do
            case "${cmd}" in
                kpartx)
                    echo "  sudo apt-get install kpartx"
                    ;;
                losetup|mount|umount)
                    echo "  sudo apt-get install util-linux"
                    ;;
                gh)
                    echo "  See: https://cli.github.com/manual/installation"
                    ;;
                jq)
                    echo "  sudo apt-get install jq"
                    ;;
                qemu-system-arm)
                    echo "  sudo apt-get install qemu-system-arm"
                    ;;
                *)
                    echo "  sudo apt-get install ${cmd}"
                    ;;
            esac
        done
        return 1
    fi

    return 0
}

# Check available disk space
# Usage: check_disk_space <path> <required_mb>
check_disk_space() {
    local path="$1"
    local required_mb="$2"

    local available_kb
    available_kb=$(df "${path}" | tail -1 | awk '{print $4}')
    local available_mb=$((available_kb / 1024))

    if [ ${available_mb} -lt ${required_mb} ]; then
        echo "❌ Error: Insufficient disk space"
        echo "   Required: ${required_mb} MB"
        echo "   Available: ${available_mb} MB"
        echo "   Location: ${path}"
        return 1
    fi

    echo "✅ Disk space check passed (${available_mb} MB available)"
    return 0
}

# Setup loop device with error checking
# Usage: setup_loop_device <image_file>
# Returns: loop device path
setup_loop_device() {
    local image_file="$1"

    # Get absolute path
    image_file=$(readlink -f "${image_file}")

    if [ ! -f "${image_file}" ]; then
        echo "❌ Error: Image file not found: ${image_file}" >&2
        return 1
    fi

    # Check if already attached
    local existing_loop
    existing_loop=$(sudo losetup -l | grep "${image_file}" | awk '{print $1}' | head -n 1 || true)
    if [ -n "${existing_loop}" ]; then
        echo "⚠️  Image already attached to ${existing_loop}, using existing device" >&2
        track_loop_device "${existing_loop}"
        echo "${existing_loop}"
        return 0
    fi

    # Find free loop device
    local loop_device
    loop_device=$(sudo losetup -f)
    if [ -z "${loop_device}" ]; then
        echo "❌ Error: No free loop devices available" >&2
        return 1
    fi

    # Attach image to loop device
    if ! sudo losetup -P "${loop_device}" "${image_file}"; then
        echo "❌ Error: Failed to attach image to loop device" >&2
        return 1
    fi

    # Wait for partitions to appear (up to 5 seconds)
    local waited=0
    while [ ${waited} -lt 5 ]; do
        if [ -e "${loop_device}p1" ] || [ -e "/dev/mapper/$(basename ${loop_device})p1" ]; then
            break
        fi
        sleep 1
        waited=$((waited + 1))
    done

    track_loop_device "${loop_device}"
    echo "${loop_device}"
    return 0
}

# Mount partition with verification
# Usage: mount_partition <device> <mount_point> [filesystem_type] [mount_options]
mount_partition() {
    local device="$1"
    local mount_point="$2"
    local fs_type="${3:-auto}"
    local mount_opts="${4:-ro}"  # Default to read-only for safety

    # Verify device exists
    if [ ! -e "${device}" ]; then
        echo "❌ Error: Device not found: ${device}" >&2
        return 1
    fi

    # Create mount point if needed
    if [ ! -d "${mount_point}" ]; then
        if ! mkdir -p "${mount_point}"; then
            echo "❌ Error: Failed to create mount point: ${mount_point}" >&2
            return 1
        fi
    fi

    # Check if already mounted
    if mountpoint -q "${mount_point}" 2>/dev/null; then
        echo "⚠️  ${mount_point} is already mounted" >&2
        track_mount "${mount_point}"
        return 0
    fi

    # Check if device is already mounted elsewhere
    if grep -q "^${device} " /proc/mounts; then
        local existing_mount
        existing_mount=$(grep "^${device} " /proc/mounts | awk '{print $2}')
        echo "⚠️  ${device} is already mounted at ${existing_mount}" >&2
        return 1
    fi

    # Mount the device
    if [ "${fs_type}" = "auto" ]; then
        if ! sudo mount -o "${mount_opts}" "${device}" "${mount_point}"; then
            echo "❌ Error: Failed to mount ${device} at ${mount_point}" >&2
            return 1
        fi
    else
        if ! sudo mount -t "${fs_type}" -o "${mount_opts}" "${device}" "${mount_point}"; then
            echo "❌ Error: Failed to mount ${device} at ${mount_point} as ${fs_type}" >&2
            return 1
        fi
    fi

    # Verify mount succeeded
    if ! mountpoint -q "${mount_point}" 2>/dev/null; then
        echo "❌ Error: Mount verification failed for ${mount_point}" >&2
        return 1
    fi

    track_mount "${mount_point}"
    return 0
}

# Validate file exists and is readable
# Usage: validate_file_readable <file_path>
validate_file_readable() {
    local file_path="$1"

    # Check if file exists (this follows symlinks)
    if [ ! -e "${file_path}" ]; then
        return 1
    fi

    # Check if it's a regular file OR a symlink pointing to a regular file
    if [ ! -f "${file_path}" ] && [ ! -L "${file_path}" ]; then
        return 1
    fi

    # For symlinks, verify the target exists
    if [ -L "${file_path}" ]; then
        local target
        target=$(readlink -f "${file_path}")
        if [ ! -f "${target}" ]; then
            return 1
        fi
    fi

    # Check file is readable
    if [ ! -r "${file_path}" ]; then
        return 1
    fi

    # Check file is not empty (this follows symlinks)
    if [ ! -s "${file_path}" ]; then
        return 1
    fi

    return 0
}

# Check if line is commented in config file
# Usage: is_line_commented <line>
is_line_commented() {
    local line="$1"

    # Remove leading whitespace
    line=$(echo "${line}" | sed 's/^[[:space:]]*//')

    # Check if starts with #
    if [[ "${line}" =~ ^# ]]; then
        return 0  # Is commented
    fi

    return 1  # Not commented
}

# Validate config setting exists and is uncommented
# Usage: validate_config_setting <config_file> <setting_pattern>
validate_config_setting() {
    local config_file="$1"
    local setting_pattern="$2"

    if [ ! -f "${config_file}" ]; then
        return 1
    fi

    # Find matching lines
    local found=0
    while IFS= read -r line; do
        if [[ "${line}" =~ ${setting_pattern} ]]; then
            if ! is_line_commented "${line}"; then
                found=1
                break
            fi
        fi
    done < "${config_file}"

    [ ${found} -eq 1 ]
}

# Verify symlink is valid (exists and points to existing file)
# Usage: verify_symlink <symlink_path>
verify_symlink() {
    local symlink_path="$1"

    # Check if it's a symlink
    if [ ! -L "${symlink_path}" ]; then
        return 1
    fi

    # Check if target exists
    if [ ! -e "${symlink_path}" ]; then
        return 1
    fi

    return 0
}

# Check if GitHub CLI is authenticated
check_gh_auth() {
    if ! command -v gh &> /dev/null; then
        echo "❌ Error: GitHub CLI (gh) is not installed" >&2
        return 1
    fi

    if ! gh auth status &>/dev/null; then
        echo "❌ Error: GitHub CLI is not authenticated" >&2
        echo "Please run: gh auth login" >&2
        return 1
    fi

    return 0
}

# Get latest release tag from GitHub
# Usage: get_latest_release_tag
get_latest_release_tag() {
    if ! check_gh_auth; then
        return 1
    fi

    local tag
    tag=$(gh release list --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null)

    if [ -z "${tag}" ] || [ "${tag}" = "null" ]; then
        echo "❌ Error: No releases found" >&2
        return 1
    fi

    echo "${tag}"
    return 0
}

# Create secure temp directory
# Usage: create_temp_dir <base_path> <prefix>
create_temp_dir() {
    local base_path="$1"
    local prefix="$2"

    # Ensure base_path exists
    if [ ! -d "${base_path}" ]; then
        if ! mkdir -p "${base_path}"; then
            echo "❌ Error: Failed to create base directory: ${base_path}" >&2
            return 1
        fi
    fi

    local temp_dir
    temp_dir=$(mktemp -d "${base_path}/${prefix}.XXXXXXXXXX")

    if [ ! -d "${temp_dir}" ]; then
        echo "❌ Error: Failed to create temporary directory" >&2
        return 1
    fi

    track_temp_dir "${temp_dir}"
    echo "${temp_dir}"
    return 0
}

# Verify partition exists
# Usage: verify_partition <loop_device> <partition_number>
verify_partition() {
    local loop_device="$1"
    local partition_num="$2"

    # Try direct device naming (newer kernels)
    if [ -e "${loop_device}p${partition_num}" ]; then
        echo "${loop_device}p${partition_num}"
        return 0
    fi

    # Try mapper naming with loop device basename
    local mapper_path
    mapper_path="/dev/mapper/$(basename "${loop_device}")p${partition_num}"
    if [ -e "${mapper_path}" ]; then
        echo "${mapper_path}"
        return 0
    fi

    # Try kpartx naming (kpartx may use different patterns)
    # Pattern 1: /dev/mapper/loopXpY (X=number, Y=partition)
    local loop_num
    loop_num=$(basename "${loop_device}" | sed 's/loop//')
    mapper_path="/dev/mapper/loop${loop_num}p${partition_num}"
    if [ -e "${mapper_path}" ]; then
        echo "${mapper_path}"
        return 0
    fi

    # CRITICAL FIX: Wait longer and trigger udev settle for partition devices
    sleep 2

    # Trigger udev to settle if available
    if command -v udevadm &>/dev/null; then
        udevadm settle 2>/dev/null || true
    fi

    # Try all patterns again after wait
    if [ -e "${loop_device}p${partition_num}" ]; then
        echo "${loop_device}p${partition_num}"
        return 0
    fi

    mapper_path="/dev/mapper/$(basename "${loop_device}")p${partition_num}"
    if [ -e "${mapper_path}" ]; then
        echo "${mapper_path}"
        return 0
    fi

    mapper_path="/dev/mapper/loop${loop_num}p${partition_num}"
    if [ -e "${mapper_path}" ]; then
        echo "${mapper_path}"
        return 0
    fi

    return 1
}

# Check network connectivity
check_network() {
    if ! ping -c 1 -W 2 github.com &>/dev/null; then
        echo "⚠️  Warning: No network connectivity to github.com" >&2
        return 1
    fi
    return 0
}

# Export all functions
export -f cleanup_all
export -f setup_traps
export -f track_mount
export -f track_loop_device
export -f track_temp_dir
export -f track_temp_file
export -f check_root_or_sudo
export -f check_required_commands
export -f check_disk_space
export -f setup_loop_device
export -f mount_partition
export -f validate_file_readable
export -f is_line_commented
export -f validate_config_setting
export -f verify_symlink
export -f check_gh_auth
export -f get_latest_release_tag
export -f create_temp_dir
export -f verify_partition
export -f check_network
