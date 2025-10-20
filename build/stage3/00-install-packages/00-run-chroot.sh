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

# Configure ALSA defaults for HDMI output
# Try multiple possible HDMI device names (varies by Pi model)
cat > /etc/asound.conf << 'EOF'
# Primary HDMI output (Pi 4/5)
pcm.!default {
    type plug
    slave.pcm {
        type hw
        card 0
        device 0
    }
}

ctl.!default {
    type hw
    card 0
}
EOF

# Disable PulseAudio auto-spawn to use ALSA directly
mkdir -p /home/pi/.config/pulse
cat > /home/pi/.config/pulse/client.conf << 'EOF'
autospawn = no
daemon-binary = /bin/true
EOF

chown -R 1000:1000 /home/pi/.config

echo "✅ HDMI tester packages installed and audio configured"
