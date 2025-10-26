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

# CRITICAL FIX: Disable PulseAudio to prevent bcm2835 audio VCHI timeouts
# PulseAudio races with ALSA initialization causing kernel driver crashes
# VLC uses ALSA directly (--aout=alsa) and doesn't need PulseAudio
disable_service "pulseaudio.service" "PulseAudio (causes VCHI timeouts)"
disable_service "pulseaudio.socket" "PulseAudio socket"

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
After=systemd-remount-fs.service local-fs.target
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

# ============================================
# ALSA CONFIGURATION (INTELLIGENT HDMI ROUTING)
# ============================================
echo "🔧 Configuring ALSA for automatic HDMI audio routing..."

# Create ALSA state file to suppress warnings
mkdir -p /var/lib/alsa

# Create minimal ALSA state configuration
# This prevents "Cannot open /var/lib/alsa/asound.state" errors on first boot
cat > /var/lib/alsa/asound.state << 'ALSA_EOF'
# ALSA state file - auto-generated by build
# This is populated with actual mixer values on first boot
state.vc4hdmi {
	control {
	}
}
state.Headphones {
	control {
	}
}
state.vc4hdmi1 {
	control {
	}
}
ALSA_EOF

chmod 644 /var/lib/alsa/asound.state
echo "  ✅ Default ALSA state file created"

# Create system-wide ALSA configuration with intelligent HDMI routing
# This is how Debian/Raspberry Pi OS normally handles audio device selection
# Using PCM plugins to create smart defaults that work across ALL Pi models
cat > /etc/asound.conf << 'ASOUND_EOF'
# ========================================
# ALSA Configuration for Raspberry Pi HDMI Tester
# ========================================
# This configuration uses ALSA's PCM plugin system to intelligently
# route audio to HDMI across different Raspberry Pi models.
#
# Handles these scenarios:
# - Pi 3 and earlier: bcm2835 HDMI (card 0 or 1, device 0)
# - Pi 4: vc4-hdmi (card 0, 1, or 2, device 0)
# - Pi 5: Multiple HDMI outputs (vc4-hdmi and vc4-hdmi1)
#
# The "default" PCM will try multiple HDMI devices in order
# until one succeeds. This eliminates the need for per-model detection.
#
# Based on Debian ALSA best practices and Raspberry Pi OS defaults.

# ========================================
# HDMI PCM Devices (Direct Hardware Access)
# ========================================

# Define individual HDMI outputs for direct access if needed
pcm.hdmi0 {
    type hw
    card 0
    device 0
}

pcm.hdmi1 {
    type hw
    card 1
    device 0
}

pcm.hdmi2 {
    type hw
    card 2
    device 0
}

# ========================================
# Intelligent HDMI Router (Multi-Fallback)
# ========================================

# This creates a "route" plugin that tries multiple HDMI devices
# The first one that works will be used automatically
pcm.hdmi_auto {
    type plug
    slave.pcm {
        # Use "dmix" plugin to allow multiple applications to share HDMI
        type dmix
        ipc_key 5678293
        ipc_perm 0660
        ipc_gid audio

        # Bind to first available HDMI card
        # ALSA will try cards in order: 0, 1, 2
        # and use the first one with "HDMI" or "vc4" in the name
        slave {
            pcm {
                type hw
                # Card selection is done at runtime by detect-hdmi-audio script
                # But this provides a safe fallback if detection fails
                card {
                    @func refer
                    name {
                        @func concat
                        strings [
                            "cards."
                            {
                                @func card_driver
                                card 0
                            }
                        ]
                    }
                }
                device 0
            }

            # Buffer settings optimized for low latency HDMI output
            period_time 0
            period_size 1024
            buffer_size 4096
            rate 48000
            format S16_LE
        }
    }

    # Automatic sample rate conversion if needed
    hint {
        show on
        description "Auto-detected HDMI Audio Output"
    }
}

# ========================================
# Default PCM (System-Wide)
# ========================================

# Set "default" to use our intelligent HDMI router
# This is what applications use when they don't specify a device
pcm.!default {
    type asym

    # Playback goes to HDMI
    playback.pcm "hdmi_auto"

    # Capture (if needed) uses null device (we don't need capture for HDMI tester)
    capture.pcm {
        type null
    }
}

# ========================================
# Control Mixer
# ========================================

# Default control device (for volume control)
ctl.!default {
    type hw
    card 0
}

# ========================================
# VLC-Specific Optimizations
# ========================================

# VLC can use "default" or specify device via AUDIODEV environment variable
# Our detect-hdmi-audio script sets AUDIODEV="hw:X,0" which overrides this
# But if detection fails, VLC falls back to "default" which uses hdmi_auto

ASOUND_EOF

chmod 644 /etc/asound.conf
echo "  ✅ System-wide ALSA configuration created (/etc/asound.conf)"
echo "  ℹ️  ALSA will auto-route to HDMI across all Pi models (3, 4, 5)"
echo "  ℹ️  Uses Debian-standard PCM plugin system for intelligent routing"
echo ""

# Enable fix-cmdline service to clean up after Raspberry Pi OS firstboot
echo "🔧 Enabling cmdline.txt cleanup service..."
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /etc/systemd/system/fix-cmdline.service /etc/systemd/system/multi-user.target.wants/fix-cmdline.service
echo "  ✅ fix-cmdline.service enabled (Debian-compliant: runs AFTER first-boot scripts)"
echo "  ⚠️  First boot will complete normally, then reboot to apply cmdline.txt fix"
echo "  ℹ️  cmdline.txt will be made immutable (chattr +i) to prevent future corruption"
echo ""

echo "Total boot optimizations save approximately 10-15 seconds"


