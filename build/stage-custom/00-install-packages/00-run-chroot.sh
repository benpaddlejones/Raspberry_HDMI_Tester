#!/bin/bash -e
# Install packages for HDMI testing

# Update package lists
apt-get update

# Install required packages for HDMI testing
# Using explicit list to ensure all dependencies are clear
apt-get install -y --no-install-recommends \
    xserver-xorg \
    xinit \
    feh \
    mpv \
    alsa-utils \
    pulseaudio

# Clean up to reduce image size
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "✅ HDMI tester packages installed successfully"
