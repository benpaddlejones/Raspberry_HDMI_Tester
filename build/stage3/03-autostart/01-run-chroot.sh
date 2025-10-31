#!/bin/bash -e

echo "Enabling HDMI audio services..."

# Enable the service that prepares the ALSA config
systemctl enable hdmi-audio-ready.service

# Enable the main audio test service
systemctl enable audio-test.service

# Also enable the image test service as a default
systemctl enable image-test.service

echo "✅ Default services (hdmi-audio-ready, audio-test, image-test) enabled."
