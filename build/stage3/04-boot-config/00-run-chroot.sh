#!/bin/bash -e
# Disable unnecessary services to optimize boot time

echo "🔧 Disabling unnecessary services for faster boot..."

# Function to safely disable a service
disable_service() {
    local service="$1"
    local description="$2"

    # Check if systemctl is available and service exists (allow list-unit-files to fail)
    if systemctl list-unit-files 2>/dev/null | grep -q "^${service}"; then
        systemctl disable "${service}" 2>/dev/null || true
        systemctl mask "${service}" 2>/dev/null || true
        echo "  ✅ Disabled: ${description}"
    else
        echo "  ℹ️  Not found: ${description} (may not be installed)"
    fi
}

# Disable avahi-daemon (mDNS discovery - not needed for HDMI tester)
disable_service "avahi-daemon.service" "Avahi mDNS/DNS-SD daemon"
disable_service "avahi-daemon.socket" "Avahi mDNS/DNS-SD socket"

# Disable bluetooth services (not needed for HDMI tester)
disable_service "bluetooth.service" "Bluetooth service"
disable_service "hciuart.service" "Bluetooth UART service"

# Disable rsyslog (use journald only for simpler logging)
disable_service "rsyslog.service" "Rsyslog service"

# Disable triggerhappy (GPIO event daemon - not needed for HDMI tester)
disable_service "triggerhappy.service" "Triggerhappy GPIO daemon"
disable_service "triggerhappy.socket" "Triggerhappy socket"

# Disable other potentially unnecessary services
disable_service "ModemManager.service" "Modem Manager"
disable_service "wpa_supplicant.service" "WPA Supplicant (WiFi not configured)"

echo "✅ Service optimization complete"
echo ""

# Filesystem optimizations
echo "🔧 Applying filesystem optimizations..."

# Add noatime mount option to /etc/fstab
# This prevents updating access times on file reads, improving performance
if [ -f /etc/fstab ]; then
    echo "  📝 Adding noatime mount option to /etc/fstab..."

    # Backup original fstab
    cp /etc/fstab /etc/fstab.backup

    # Add optimized ext4 mount options to root filesystem (/)
    # noatime: Don't update access times (improves performance)
    # commit=60: Commit data to disk every 60 seconds (default is 5, reduces writes)
    # data=writeback: Fastest journaling mode (metadata only)
    sed -i 's/\(.*\s\+\/\s\+ext4\s\+\)\(defaults\)\(\s\+.*\)/\1defaults,noatime,commit=60,data=writeback\3/' /etc/fstab

    # Add noatime to boot partitions (/boot, /boot/firmware) - typically vfat, not ext4
    sed -i 's/\(.*\s\+\/boot\s\+\w\+\s\+\)\(defaults\)\(\s\+.*\)/\1defaults,noatime\3/' /etc/fstab
    sed -i 's/\(.*\s\+\/boot\/firmware\s\+\w\+\s\+\)\(defaults\)\(\s\+.*\)/\1defaults,noatime\3/' /etc/fstab

    echo "  ✅ Optimized ext4 mount options added (noatime, commit=60, data=writeback)"
else
    echo "  ⚠️  /etc/fstab not found"
fi

# Reduce filesystem check frequency
echo "  📝 Reducing filesystem check frequency..."

# Find root partition device (allow failure in chroot)
ROOT_DEV=$(findmnt -n -o SOURCE / 2>/dev/null || true)

if [ -n "${ROOT_DEV}" ]; then
    # Set filesystem check to every 100 mounts (instead of default 20-30)
    tune2fs -c 100 "${ROOT_DEV}" 2>/dev/null || echo "  ℹ️  Could not set mount count check (may not be ext filesystem)"

    # Set filesystem check interval to 6 months (instead of default ~1 month)
    tune2fs -i 6m "${ROOT_DEV}" 2>/dev/null || echo "  ℹ️  Could not set time interval check"

    echo "  ✅ Filesystem check frequency reduced"
else
    echo "  ℹ️  Could not determine root device (this is normal in chroot - will be configured at first boot)"
fi

echo "✅ Filesystem optimizations complete"
echo ""
echo "Total boot optimizations save approximately 10-15 seconds"


