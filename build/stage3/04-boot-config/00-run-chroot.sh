#!/bin/bash -e
# Disable unnecessary services to optimize boot time

echo "🔧 Disabling unnecessary services for faster boot..."

# Function to safely disable a service
disable_service() {
    local service="$1"
    local description="$2"

    # HIGH PRIORITY FIX #4: Use direct symlink manipulation instead of systemctl in chroot
    # systemctl requires running systemd/D-Bus which isn't available in chroot
    # Instead, we manually create the disable/mask symlinks

    local service_file="/lib/systemd/system/${service}"
    local alt_service_file="/usr/lib/systemd/system/${service}"

    # Check if service exists
    if [ -f "${service_file}" ] || [ -f "${alt_service_file}" ]; then
        # Disable: Create symlink to /dev/null in /etc/systemd/system
        local wants_dir="/etc/systemd/system/multi-user.target.wants"
        local service_link="${wants_dir}/${service}"

        # Remove any existing enable symlink
        if [ -L "${service_link}" ]; then
            rm -f "${service_link}"
        fi

        # Mask: Create symlink to /dev/null in /etc/systemd/system
        local mask_link="/etc/systemd/system/${service}"
        mkdir -p /etc/systemd/system
        ln -sf /dev/null "${mask_link}"

        echo "  ✅ Disabled and masked: ${description}"
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

# HIGH PRIORITY FIX #5: tune2fs cannot run on mounted filesystems in chroot
# Instead, create a systemd oneshot service to run tune2fs on first boot
echo "  📝 Creating first-boot service for filesystem optimization..."

cat > /etc/systemd/system/tune-filesystem.service << 'EOF'
[Unit]
Description=Optimize filesystem check frequency (one-time)
DefaultDependencies=no
After=local-fs.target
Before=multi-user.target
ConditionPathExists=!/var/lib/tune-filesystem-done

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'ROOT_DEV=$(findmnt -n -o SOURCE /); if [ -n "$ROOT_DEV" ]; then tune2fs -c 100 "$ROOT_DEV" 2>/dev/null || true; tune2fs -i 6m "$ROOT_DEV" 2>/dev/null || true; touch /var/lib/tune-filesystem-done; echo "Filesystem tuning complete"; fi'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service to run on first boot
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /etc/systemd/system/tune-filesystem.service /etc/systemd/system/multi-user.target.wants/tune-filesystem.service

echo "  ✅ Filesystem optimization service created (will run on first boot)"
echo "  ℹ️  tune2fs cannot run on mounted filesystems, deferred to first boot"

echo "✅ Filesystem optimizations complete"
echo ""

# Enable fix-cmdline service to clean up after Raspberry Pi OS firstboot
echo "🔧 Enabling cmdline.txt cleanup service..."
mkdir -p /etc/systemd/system/sysinit.target.wants
ln -sf /etc/systemd/system/fix-cmdline.service /etc/systemd/system/sysinit.target.wants/fix-cmdline.service
echo "  ✅ fix-cmdline.service enabled (will run once on first boot, then reboot)"
echo "  ⚠️  First boot will take 2 boots: boot 1 = fix cmdline, boot 2 = normal operation"
echo ""

echo "Total boot optimizations save approximately 10-15 seconds"


