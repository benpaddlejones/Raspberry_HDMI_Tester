#!/bin/bash
# Fix cmdline.txt - ROBUST cleanup of duplicates and conflicts
# This runs ONCE after first boot to clean up firmware/resize modifications
#
# PROBLEM: Raspberry Pi OS firmware and resize scripts modify cmdline.txt AFTER our
# image builds, adding duplicates, conflicts, and unwanted parameters
#
# SOLUTION: Complete rebuild of cmdline.txt with ONLY required parameters

set -e

LOG_FILE="/var/log/fix-cmdline.log"
MARKER_FILE="/var/lib/hdmi-tester/cmdline-fixed"

# Log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

# Check if already run - but verify cmdline is actually clean
if [ -f "${MARKER_FILE}" ]; then
    # Check if cmdline has conflicts despite marker existing
    CMDLINE_FILE=""
    if [ -f "/boot/firmware/cmdline.txt" ]; then
        CMDLINE_FILE="/boot/firmware/cmdline.txt"
    elif [ -f "/boot/cmdline.txt" ]; then
        CMDLINE_FILE="/boot/cmdline.txt"
    fi

    if [ -n "${CMDLINE_FILE}" ]; then
        CURRENT=$(cat "${CMDLINE_FILE}")
        LINE_COUNT=$(grep -c "." "${CMDLINE_FILE}" || echo "0")
        
        # Check for conflicts or multi-line corruption
        if echo "${CURRENT}" | grep -q "snd_bcm2835.enable_hdmi=0" || \
           echo "${CURRENT}" | grep -q "cgroup_disable=memory" || \
           echo "${CURRENT}" | grep -q "8250.nr_uarts=0" || \
           [ "$(echo "${CURRENT}" | grep -o "snd_bcm2835.enable_hdmi" | wc -l)" -gt 1 ] || \
           [ "${LINE_COUNT}" -gt 1 ]; then
            log "⚠️  WARNING: Marker exists but cmdline has issues (conflicts or multi-line) - re-running"
            log "   Line count: ${LINE_COUNT} (should be 1)"
            log "   First 200 chars: $(echo "${CURRENT}" | head -c 200)"
            rm -f "${MARKER_FILE}"
        else
            log "cmdline.txt already fixed and verified clean, skipping"
            exit 0
        fi
    else
        log "cmdline.txt already fixed (marker exists), skipping"
        exit 0
    fi
fi

log "=========================================="
log "CMDLINE.TXT ROBUST CLEANUP - START"
log "=========================================="

# Find cmdline.txt (handle both old and new Pi OS layouts)
CMDLINE_FILE=""
if [ -f "/boot/firmware/cmdline.txt" ]; then
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
elif [ -f "/boot/cmdline.txt" ]; then
    CMDLINE_FILE="/boot/cmdline.txt"
else
    log "❌ ERROR: No cmdline.txt found!"
    exit 1
fi

log "📁 Using: ${CMDLINE_FILE}"

# Create backup with timestamp
BACKUP_FILE="${CMDLINE_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
cp "${CMDLINE_FILE}" "${BACKUP_FILE}"
log "💾 Backup created: ${BACKUP_FILE}"

# Read current content (handles multi-line corruption)
CURRENT=$(cat "${CMDLINE_FILE}")
log "📝 Current content (RAW):"
log "   ${CURRENT}"
log ""

# Count lines (should be 1, but firmware sometimes creates 2+)
# Need to count actual lines, not just newline chars
LINE_COUNT=$(grep -c "." "${CMDLINE_FILE}" || echo "0")
log "📊 Line count: ${LINE_COUNT}"
if [ "${LINE_COUNT}" -gt 1 ]; then
    log "⚠️  WARNING: cmdline.txt has multiple lines (corrupt!)"
fi

# STEP 1: Flatten to single line, normalize whitespace
FLATTENED=$(echo "${CURRENT}" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
log "🔧 After flattening: ${FLATTENED}"
log ""

# STEP 2: Extract ONLY the core required parameters (first occurrence only)
# We'll rebuild the entire line from scratch to ensure no conflicts

# Extract root partition (CRITICAL - don't lose this!)
# Use POSIX-compliant grep -oE instead of -oP for compatibility
ROOT_PARAM=$(echo "${FLATTENED}" | grep -oE 'root=[^ ]+' | head -1)
if [ -z "${ROOT_PARAM}" ]; then
    log "❌ CRITICAL ERROR: Could not find root= parameter!"
    log "   This would make the system unbootable. Aborting!"
    exit 1
fi
log "✅ Root partition: ${ROOT_PARAM}"

# Extract PARTUUID if present (fallback to root=)
PARTUUID=$(echo "${ROOT_PARAM}" | grep -oE 'PARTUUID=[^ ]+' || echo "")
if [ -n "${PARTUUID}" ]; then
    log "✅ Using PARTUUID: ${PARTUUID}"
fi

# Extract rootfstype
ROOTFSTYPE=$(echo "${FLATTENED}" | grep -oE 'rootfstype=[^ ]+' | head -1)
ROOTFSTYPE=${ROOTFSTYPE:-rootfstype=ext4}  # Default to ext4 if not found
log "✅ Filesystem: ${ROOTFSTYPE}"

# Extract console settings (we want serial console for debugging)
# Match console=serial0,115200 or console=ttyS0,115200 etc.
CONSOLE_SERIAL=$(echo "${FLATTENED}" | grep -oE 'console=(serial|ttyS)[0-9]+,[0-9]+' | head -1)
CONSOLE_TTY=$(echo "${FLATTENED}" | grep -oE 'console=tty[0-9]+' | head -1)
CONSOLE_SERIAL=${CONSOLE_SERIAL:-console=serial0,115200}  # Default
CONSOLE_TTY=${CONSOLE_TTY:-console=tty1}  # Default
log "✅ Console: ${CONSOLE_SERIAL} ${CONSOLE_TTY}"

# STEP 3: Build the CORRECT cmdline from scratch
# Only include parameters we actually want, in correct order
REBUILT="${CONSOLE_SERIAL} ${CONSOLE_TTY} ${ROOT_PARAM} ${ROOTFSTYPE} fsck.repair=yes rootwait"

# Add our audio parameters (EXACTLY ONCE, no conflicts)
REBUILT="${REBUILT} snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1"

# Add boot optimization parameters
REBUILT="${REBUILT} noswap quiet splash loglevel=1 fastboot"

# Final cleanup: ensure single spaces, trim
FINAL=$(echo "${REBUILT}" | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

log ""
log "🔨 REBUILT cmdline.txt:"
log "   ${FINAL}"
log ""

# STEP 4: Validate the rebuilt line
log "🔍 Validation checks:"

# Check length (kernel cmdline limit is ~1024 chars, warn if close)
LENGTH=${#FINAL}
log "   Length: ${LENGTH} characters"
if [ "${LENGTH}" -gt 900 ]; then
    log "   ⚠️  WARNING: cmdline is long (limit ~1024 chars)"
fi

# Check for required parameters
if ! echo "${FINAL}" | grep -q "root="; then
    log "   ❌ FATAL: Missing root= parameter"
    exit 1
fi
log "   ✅ Contains root="

if ! echo "${FINAL}" | grep -q "console="; then
    log "   ⚠️  WARNING: No console= parameter"
fi
log "   ✅ Contains console="

# Check for conflicts (these should NOT exist)
CONFLICTS=0

if echo "${FINAL}" | grep -q "snd_bcm2835.enable_hdmi=0"; then
    log "   ❌ CONFLICT: Found enable_hdmi=0"
    CONFLICTS=$((CONFLICTS + 1))
fi

if echo "${FINAL}" | grep -q "cgroup_disable=memory"; then
    log "   ❌ CONFLICT: Found cgroup_disable=memory (causes issues)"
    CONFLICTS=$((CONFLICTS + 1))
fi

if echo "${FINAL}" | grep -q "8250.nr_uarts=0"; then
    log "   ❌ CONFLICT: Found 8250.nr_uarts=0 (breaks serial)"
    CONFLICTS=$((CONFLICTS + 1))
fi

# Count occurrences of critical parameters (must be exactly 1)
HDMI_COUNT=$(echo "${FINAL}" | grep -o "snd_bcm2835.enable_hdmi=1" | wc -l)
HEADPHONE_COUNT=$(echo "${FINAL}" | grep -o "snd_bcm2835.enable_headphones=1" | wc -l)

if [ "${HDMI_COUNT}" -ne 1 ]; then
    log "   ❌ ERROR: enable_hdmi=1 appears ${HDMI_COUNT} times (must be 1)"
    CONFLICTS=$((CONFLICTS + 1))
else
    log "   ✅ enable_hdmi=1 appears exactly once"
fi

if [ "${HEADPHONE_COUNT}" -ne 1 ]; then
    log "   ❌ ERROR: enable_headphones=1 appears ${HEADPHONE_COUNT} times (must be 1)"
    CONFLICTS=$((CONFLICTS + 1))
else
    log "   ✅ enable_headphones=1 appears exactly once"
fi

if [ "${CONFLICTS}" -gt 0 ]; then
    log ""
    log "❌ VALIDATION FAILED: ${CONFLICTS} conflicts found"
    log "   Aborting to prevent boot failure"
    exit 1
fi

log "   ✅ All validation checks passed"
log ""

# STEP 5: Write the corrected cmdline
log "💾 Writing corrected cmdline.txt..."
echo "${FINAL}" > "${CMDLINE_FILE}"

# STEP 6: Final verification by re-reading
VERIFY=$(cat "${CMDLINE_FILE}")
if [ "${VERIFY}" != "${FINAL}" ]; then
    log "❌ ERROR: Verification failed - file content doesn't match!"
    log "   Expected: ${FINAL}"
    log "   Got: ${VERIFY}"
    exit 1
fi

log "✅ File written and verified successfully"
log ""

# STEP 7: Create marker to prevent re-running
mkdir -p "$(dirname "${MARKER_FILE}")"
touch "${MARKER_FILE}"
log "📌 Created marker file: ${MARKER_FILE}"
log ""

# Summary
log "=========================================="
log "CMDLINE.TXT CLEANUP - COMPLETE"
log "=========================================="
log "✅ Duplicates removed"
log "✅ Conflicts resolved"
log "✅ HDMI audio enabled (snd_bcm2835.enable_hdmi=1)"
log "✅ Headphone audio enabled (snd_bcm2835.enable_headphones=1)"
log "✅ Boot optimization enabled (noswap, quiet, fastboot)"
log "✅ Serial console preserved (${CONSOLE_SERIAL})"
log ""
log "📋 Backup saved to: ${BACKUP_FILE}"
log "📋 Full log saved to: ${LOG_FILE}"
log ""
log "🔄 REBOOT WILL OCCUR AUTOMATICALLY"
log "   cmdline.txt changes require reboot to take effect"
log "   systemd will trigger reboot after this service completes"
log ""
log "   System will reboot in a few seconds..."
log ""

# Flush logs before reboot
sync

exit 0
