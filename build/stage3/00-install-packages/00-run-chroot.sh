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
    alsa-utils

# Clean up to reduce image size
apt-get clean
rm -rf /var/lib/apt/lists/*

# Configure ALSA to play through BOTH HDMI and 3.5mm jack simultaneously
# This creates a virtual device that duplicates audio to both outputs
cat > /etc/asound.conf << 'EOF'
# HDMI audio output (hw:0,0)
pcm.hdmi {
    type hw
    card 0
    device 0
}

# 3.5mm headphone jack (hw:0,1)
pcm.headphones {
    type hw
    card 0
    device 1
}

# Duplicate audio to both HDMI and headphone jack
pcm.both {
    type plug
    slave.pcm {
        type multi
        slaves {
            a { channels 2 pcm "hdmi" }
            b { channels 2 pcm "headphones" }
        }
        bindings {
            0 { slave a channel 0 }
            1 { slave a channel 1 }
            2 { slave b channel 0 }
            3 { slave b channel 1 }
        }
    }
    ttable [
        [ 1 0 1 0 ]   # left channel to both outputs
        [ 0 1 0 1 ]   # right channel to both outputs
    ]
}

# Set "both" as the default device
pcm.!default {
    type plug
    slave.pcm "both"
}

ctl.!default {
    type hw
    card 0
}
EOF

# Set user-specific ALSA configuration as backup
cat > /home/pi/.asoundrc << 'EOF'
# Duplicate audio to both HDMI and headphone jack
pcm.!default {
    type plug
    slave.pcm "both"
}
EOF

chown 1000:1000 /home/pi/.asoundrc

# Set audio group permissions for pi user
usermod -a -G audio pi || true

echo "✅ HDMI tester packages installed and audio configured for HDMI output"
