#!/bin/bash
# HDMI Tester Configuration Library
# Provides functions to read/write /boot/firmware/hdmi-tester.conf
#
# Usage:
#   source /usr/local/lib/hdmi-tester/config-lib.sh
#   DEBUG_MODE=$(get_config_value "DEBUG_MODE")
#   set_config_value "DEFAULT_SERVICE" "hdmi-test"

readonly CONFIG_FILE="/boot/firmware/hdmi-tester.conf"
readonly CONFIG_LOCK="/var/lock/hdmi-tester-config.lock"

# Get a configuration value
# Usage: get_config_value "KEY"
# Returns: value or empty string if not found
get_config_value() {
    local key="$1"
    local value=""

    if [ -f "${CONFIG_FILE}" ]; then
        # Extract value, handling comments and whitespace
        value=$(grep "^${key}=" "${CONFIG_FILE}" | cut -d'=' -f2- | tr -d ' \t\r')
    fi

    echo "${value}"
}

# Set a configuration value
# Usage: set_config_value "KEY" "VALUE"
# Returns: 0 on success, 1 on failure
set_config_value() {
    local key="$1"
    local value="$2"

    # Acquire lock
    exec 200>"${CONFIG_LOCK}"
    flock -x 200 || return 1

    if [ ! -f "${CONFIG_FILE}" ]; then
        echo "Error: Config file not found: ${CONFIG_FILE}" >&2
        flock -u 200
        return 1
    fi

    # Create temp file
    local temp_file
    temp_file=$(mktemp) || return 1

    # Update or add the key
    if grep -q "^${key}=" "${CONFIG_FILE}"; then
        # Key exists, update it
        sed "s|^${key}=.*|${key}=${value}|" "${CONFIG_FILE}" > "${temp_file}"
    else
        # Key doesn't exist, add it before the "DO NOT EDIT" line
        sed "/^# DO NOT EDIT/i ${key}=${value}" "${CONFIG_FILE}" > "${temp_file}"
    fi

    # Validate temp file has content
    if [ -s "${temp_file}" ]; then
        # Atomic move
        sudo mv "${temp_file}" "${CONFIG_FILE}" || {
            rm -f "${temp_file}"
            flock -u 200
            return 1
        }
        sudo chmod 644 "${CONFIG_FILE}"
    else
        rm -f "${temp_file}"
        flock -u 200
        return 1
    fi

    # Release lock
    flock -u 200
    return 0
}

# Check if debug mode is enabled
# Usage: is_debug_enabled
# Returns: 0 if true, 1 if false
is_debug_enabled() {
    local debug_mode
    debug_mode=$(get_config_value "DEBUG_MODE")

    if [ "${debug_mode}" = "true" ]; then
        return 0
    else
        return 1
    fi
}

# Get the default service
# Usage: get_default_service
# Returns: service name or empty string
get_default_service() {
    get_config_value "DEFAULT_SERVICE"
}

# Validate service name
# Usage: is_valid_service "service-name"
# Returns: 0 if valid, 1 if invalid
is_valid_service() {
    local service="$1"
    local valid_services=("hdmi-test" "audio-test" "image-test" "pixel-test" "full-test" "hdmi-diagnostics")

    # Empty is valid (means no default)
    if [ -z "${service}" ]; then
        return 0
    fi

    for valid in "${valid_services[@]}"; do
        if [ "${service}" = "${valid}" ]; then
            return 0
        fi
    done

    return 1
}

# Get VLC debug flags based on config
# Usage: get_vlc_flags
# Returns: "-vvv" if debug enabled, "" otherwise
get_vlc_flags() {
    if is_debug_enabled; then
        echo "-vvv"
    else
        echo ""
    fi
}

# Get systemd logging level based on config
# Usage: get_log_level
# Returns: "debug" if debug enabled, "info" otherwise
get_log_level() {
    if is_debug_enabled; then
        echo "debug"
    else
        echo "info"
    fi
}

# Point ALSA's "default" device at the HDMI port that has a display attached.
# Only relevant on the KMS driver (Pi 5), where each HDMI port is its own
# vc4hdmiN sound card and card 0 is always HDMI0 regardless of cabling.
# On FKMS/snd_bcm2835 (Pi 0-4) the stock defaults are correct, so no override.
# Usage: configure_hdmi_audio
# Prints the selected card name (or "default")
configure_hdmi_audio() {
    local asoundrc="${HOME}/.asoundrc"
    local cards
    cards=$(grep -oE '\[vc4hdmi[0-9]+' /proc/asound/cards 2>/dev/null | tr -d '[')

    if [ -z "${cards}" ]; then
        rm -f "${asoundrc}"
        echo "default"
        return 0
    fi

    local card="" connector idx candidate
    # vc4.force_hotplug marks every port "connected", so a non-empty EDID is
    # the only reliable sign that a display is actually plugged in.
    for connector in /sys/class/drm/card*-HDMI-A-*; do
        [ -d "${connector}" ] || continue
        idx="${connector##*HDMI-A-}"
        candidate="vc4hdmi$((idx - 1))"
        echo "${cards}" | grep -qx "${candidate}" || continue
        if [ -s "${connector}/edid" ]; then
            card="${candidate}"
            break
        fi
    done
    if [ -z "${card}" ]; then
        for connector in /sys/class/drm/card*-HDMI-A-*; do
            [ -f "${connector}/status" ] || continue
            idx="${connector##*HDMI-A-}"
            candidate="vc4hdmi$((idx - 1))"
            echo "${cards}" | grep -qx "${candidate}" || continue
            if [ "$(cat "${connector}/status")" = "connected" ]; then
                card="${candidate}"
                break
            fi
        done
    fi
    [ -n "${card}" ] || card=$(echo "${cards}" | head -1)

    printf 'defaults.pcm.card %s\ndefaults.ctl.card %s\n' "${card}" "${card}" > "${asoundrc}"
    echo "${card}"
}
