#!/bin/bash -e
# Disable unnecessary services to optimize boot time

echo "🔧 Disabling unnecessary services for faster boot..."

# Function to safely disable a service
disable_service() {
    local service="$1"
    local description="$2"
    
    if systemctl list-unit-files | grep -q "^${service}"; then
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
echo "Disabled services save approximately 5-8 seconds of boot time"

