#!/bin/bash -e

echo "Disabling all HDMI audio and test services by default..."

# List of all services that should be disabled
services=(
    "image-test.service"
    "hdmi-test.service"
    "pixel-test.service"
    "audio-test.service"
    "full-test.service"
)

for service in "${services[@]}"; do
    if systemctl list-unit-files | grep -q "^${service}"; then
        echo "Disabling ${service}..."
        systemctl disable "${service}"
    else
        echo "Service ${service} not found, skipping."
    fi
done

echo "✅ All auto-start services have been disabled."
echo "The system will boot to a terminal for manual testing."
