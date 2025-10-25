#!/bin/bash
# Common ROOTFS_DIR validation function for all stage3 scripts
# This prevents catastrophic damage from misconfigured ROOTFS_DIR

validate_rootfs_dir() {
    # Check if ROOTFS_DIR is set
    if [ -z "${ROOTFS_DIR}" ]; then
        echo "❌ Error: ROOTFS_DIR not set"
        return 1
    fi

    # Safety check - ensure ROOTFS_DIR is not /
    # This prevents catastrophic damage if ROOTFS_DIR is misconfigured
    ROOTFS_REAL=$(realpath "${ROOTFS_DIR}" 2>/dev/null || echo "${ROOTFS_DIR}")
    if [ "${ROOTFS_REAL}" = "/" ] || [ "${ROOTFS_DIR}" = "/" ]; then
        echo "❌ Error: ROOTFS_DIR cannot be root directory (/)"
        echo "   This would install files to the host system!"
        echo "   Current ROOTFS_DIR: ${ROOTFS_DIR}"
        return 1
    fi

    # Check common dangerous paths
    if [[ "${ROOTFS_DIR}" =~ ^/(bin|boot|dev|etc|home|lib|opt|root|sbin|srv|sys|usr|var)$ ]]; then
        echo "❌ Error: ROOTFS_DIR appears to be a system directory: ${ROOTFS_DIR}"
        echo "   This looks like a host system path, not a build chroot!"
        return 1
    fi

    # Check if directory exists
    if [ ! -d "${ROOTFS_DIR}" ]; then
        echo "❌ Error: ROOTFS_DIR does not exist: ${ROOTFS_DIR}"
        return 1
    fi

    # Check if directory is writable
    if [ ! -w "${ROOTFS_DIR}" ]; then
        echo "❌ Error: ROOTFS_DIR is not writable: ${ROOTFS_DIR}"
        return 1
    fi

    echo "✅ ROOTFS_DIR validated: ${ROOTFS_DIR}"
    return 0
}

# If script is sourced, function is available
# If script is run directly, execute validation
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    validate_rootfs_dir
    exit $?
fi
