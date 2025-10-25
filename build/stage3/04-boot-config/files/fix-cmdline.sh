#!/bin/bash
# Fix cmdline.txt - Remove duplicates and conflicts added by Raspberry Pi OS firstboot
# This runs ONCE after first boot to clean up firmware/resize modifications

set -e

LOG_FILE="/var/log/fix-cmdline.log"

# Log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

log "=== Starting cmdline.txt cleanup ==="

# Find cmdline.txt
CMDLINE_FILE=""
if [ -f "/boot/firmware/cmdline.txt" ]; then
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
elif [ -f "/boot/cmdline.txt" ]; then
    CMDLINE_FILE="/boot/cmdline.txt"
else
    log "ERROR: No cmdline.txt found!"
    exit 1
fi

log "Found cmdline.txt: ${CMDLINE_FILE}"

# Backup original
cp "${CMDLINE_FILE}" "${CMDLINE_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
log "Created backup: ${CMDLINE_FILE}.backup-$(date +%Y%m%d-%H%M%S)"

# Read current content
CURRENT=$(cat "${CMDLINE_FILE}")
log "Current content: ${CURRENT}"

# Strategy: Extract the FIRST occurrence of core parameters, remove ALL audio/boot params, then re-add ours
# This handles the case where content is duplicated or has conflicts

# Remove ALL instances of our target parameters (including duplicates and conflicts)
CLEANED=$(echo "${CURRENT}" | sed \
    -e 's/snd_bcm2835\.enable_hdmi=[^ ]*//g' \
    -e 's/snd_bcm2835\.enable_headphones=[^ ]*//g' \
    -e 's/cgroup_disable=[^ ]*//g' \
    -e 's/coherent_pool=[^ ]*//g' \
    -e 's/8250\.nr_uarts=[^ ]*//g' \
    -e 's/vc_mem\.mem_base=[^ ]*//g' \
    -e 's/vc_mem\.mem_size=[^ ]*//g' \
    -e 's/noswap//g' \
    -e 's/quiet//g' \
    -e 's/splash//g' \
    -e 's/loglevel=[^ ]*//g' \
    -e 's/fastboot//g' \
    -e 's/  */ /g' \
    -e 's/  */ /g' \
    -e 's/^ *//;s/ *$//')

log "After removing duplicates: ${CLEANED}"

# Add our required parameters
FINAL="${CLEANED} snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_headphones=1 noswap quiet splash loglevel=1 fastboot"

log "Final content: ${FINAL}"

# Write back
echo "${FINAL}" > "${CMDLINE_FILE}"

# Verify
VERIFY=$(cat "${CMDLINE_FILE}")
log "Verification: ${VERIFY}"

# Check for conflicts
if echo "${VERIFY}" | grep -q "snd_bcm2835.enable_hdmi=0"; then
    log "ERROR: Still contains snd_bcm2835.enable_hdmi=0!"
    exit 1
fi

if echo "${VERIFY}" | grep -q "cgroup_disable="; then
    log "ERROR: Still contains cgroup_disable!"
    exit 1
fi

# Count occurrences of our parameters (should be exactly 1 each)
HDMI_COUNT=$(echo "${VERIFY}" | grep -o "snd_bcm2835.enable_hdmi=1" | wc -l)
if [ "${HDMI_COUNT}" -ne 1 ]; then
    log "WARNING: snd_bcm2835.enable_hdmi=1 appears ${HDMI_COUNT} times (expected 1)"
fi

log "=== cmdline.txt cleanup complete ==="
log "HDMI audio: ENABLED"
log "Headphone audio: ENABLED"
log "Duplicates: REMOVED"
log "Conflicts: RESOLVED"

exit 0
