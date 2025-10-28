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
# Returns: "--vvv" if debug enabled, "" otherwise
get_vlc_flags() {
    if is_debug_enabled; then
        echo "--vvv"
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
