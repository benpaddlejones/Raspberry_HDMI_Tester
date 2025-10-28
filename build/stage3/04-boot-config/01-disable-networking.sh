#!/bin/bash -e
# Disable all networking (Ethernet and WiFi) for security

echo "🔒 Disabling networking for security..."

# Blacklist network drivers to prevent them from loading
echo "  📝 Blacklisting network drivers..."

cat > "${ROOTFS_DIR}/etc/modprobe.d/blacklist-networking.conf" << 'EOF'
# Disable all networking for security (HDMI tester doesn't need network)

# Ethernet drivers
blacklist lan78xx      # USB Ethernet (Pi 3B+, Pi 4)
blacklist smsc95xx     # USB Ethernet (Pi 3B and earlier)
blacklist r8152        # Realtek USB Ethernet
blacklist asix         # ASIX USB Ethernet
blacklist ax88179_178a # ASIX USB 3.0 Ethernet
blacklist cdc_ether    # CDC Ethernet
blacklist cdc_ncm      # CDC NCM
blacklist cdc_mbim     # CDC MBIM

# WiFi drivers
blacklist brcmfmac     # Broadcom WiFi (Pi 3/4/5)
blacklist brcmutil     # Broadcom WiFi utility
blacklist cfg80211     # Generic WiFi configuration
blacklist mac80211     # Generic WiFi MAC

# Additional network protocols
blacklist ipv6         # IPv6 protocol
EOF

chmod 644 "${ROOTFS_DIR}/etc/modprobe.d/blacklist-networking.conf"
echo "  ✅ Network drivers blacklisted"

# Disable network-related services
echo "  📝 Disabling network services..."

# Function to safely disable a service (using symlink manipulation for chroot)
disable_network_service() {
    local service="$1"
    local description="$2"
    
    local service_file="${ROOTFS_DIR}/lib/systemd/system/${service}"
    local alt_service_file="${ROOTFS_DIR}/usr/lib/systemd/system/${service}"
    
    if [ -f "${service_file}" ] || [ -f "${alt_service_file}" ]; then
        # Create mask symlink
        mkdir -p "${ROOTFS_DIR}/etc/systemd/system"
        ln -sf /dev/null "${ROOTFS_DIR}/etc/systemd/system/${service}"
        echo "    ✅ Disabled: ${description}"
    else
        echo "    ℹ️  Not found: ${description}"
    fi
}

disable_network_service "networking.service" "Networking service"
disable_network_service "dhcpcd.service" "DHCP client daemon"
disable_network_service "wpa_supplicant.service" "WiFi WPA supplicant"
disable_network_service "NetworkManager.service" "Network Manager"
disable_network_service "systemd-networkd.service" "systemd network daemon"
disable_network_service "systemd-networkd.socket" "systemd network socket"
disable_network_service "ifup@.service" "Interface up service"

echo "  ✅ Network services disabled"

# Remove network configuration files
echo "  📝 Removing network configuration..."

# Clear network interfaces configuration
if [ -f "${ROOTFS_DIR}/etc/network/interfaces" ]; then
    cat > "${ROOTFS_DIR}/etc/network/interfaces" << 'EOF'
# Network interfaces disabled for security
# This HDMI tester does not require network connectivity
auto lo
iface lo inet loopback
EOF
    echo "    ✅ /etc/network/interfaces cleared (loopback only)"
fi

# Remove wpa_supplicant configurations
rm -f "${ROOTFS_DIR}/etc/wpa_supplicant/wpa_supplicant.conf" 2>/dev/null || true
rm -f "${ROOTFS_DIR}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf" 2>/dev/null || true
echo "    ✅ WiFi configurations removed"

# Remove DHCP client configurations
rm -f "${ROOTFS_DIR}/etc/dhcpcd.conf" 2>/dev/null || true
echo "    ✅ DHCP configurations removed"

# Disable IPv6 at kernel level
echo "  📝 Disabling IPv6 at kernel level..."
cat >> "${ROOTFS_DIR}/etc/sysctl.d/99-disable-ipv6.conf" << 'EOF'
# Disable IPv6 for security (not needed for HDMI tester)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
chmod 644 "${ROOTFS_DIR}/etc/sysctl.d/99-disable-ipv6.conf"
echo "    ✅ IPv6 disabled"

echo "✅ Networking completely disabled (Ethernet and WiFi)"
echo "  ℹ️  SSH over USB-OTG may still work if enabled"
echo ""
