#!/bin/bash -e

echo "Enabling HDMI audio services..."

# Enable the service that prepares the ALSA config
systemctl enable hdmi-audio-ready.service

# Enable the dynamic ALSA config generator service
systemctl enable hdmi-audio-config.service

# Enable the multi-card audio router
systemctl enable alsa-multi-card.service

# NOTE: Test services are intentionally NOT enabled by default
# Users should configure via hdmi-tester-config or manually enable

echo "✅ Audio configuration services enabled. Test services available but disabled by default."
