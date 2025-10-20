#!/bin/bash
# Comprehensive audio testing script for HDMI Tester
# Tests both HDMI and 3.5mm audio output

LOG_FILE="/var/log/hdmi-tester-audio.log"
AUDIO_FILE="/opt/hdmi-tester/audio.mp3"

# Logging function
log_msg() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Check if audio file exists
check_audio_file() {
    if [ ! -f "$AUDIO_FILE" ]; then
        log_msg "❌ Audio file not found: $AUDIO_FILE"
        return 1
    fi

    log_msg "✅ Audio file found: $AUDIO_FILE"
    local file_info=$(file "$AUDIO_FILE")
    log_msg "   File info: $file_info"
    return 0
}

# Test ALSA devices
test_alsa_devices() {
    log_msg "🔍 Testing ALSA devices..."

    # List all audio devices
    local devices=$(aplay -l 2>/dev/null)
    if [ $? -eq 0 ]; then
        log_msg "📋 Available audio devices:"
        echo "$devices" | while IFS= read -r line; do
            log_msg "   $line"
        done
    else
        log_msg "❌ Failed to list ALSA devices"
        return 1
    fi

    return 0
}

# Test HDMI audio specifically
test_hdmi_audio() {
    log_msg "🔊 Testing HDMI audio (Card 0, Device 1)..."

    # Try to play a short test tone to HDMI
    if timeout 5 aplay -D plughw:0,1 /dev/zero 2>/dev/null; then
        log_msg "✅ HDMI audio device responsive"
        return 0
    else
        log_msg "❌ HDMI audio device not responsive"
        return 1
    fi
}

# Test 3.5mm audio
test_analog_audio() {
    log_msg "🔊 Testing 3.5mm audio (Card 0, Device 0)..."

    # Try to play a short test tone to 3.5mm
    if timeout 5 aplay -D plughw:0,0 /dev/zero 2>/dev/null; then
        log_msg "✅ 3.5mm audio device responsive"
        return 0
    else
        log_msg "❌ 3.5mm audio device not responsive"
        return 1
    fi
}

# Set up ALSA configuration for both outputs
setup_alsa_config() {
    log_msg "⚙️  Setting up ALSA configuration..."

    # Create ALSA configuration that routes to both HDMI and 3.5mm
    cat > /etc/asound.conf << 'EOF'
# ALSA configuration for HDMI Tester
# Routes audio to both HDMI and 3.5mm jack

pcm.both {
    type plug
    slave.pcm {
        type multi
        slaves {
            a { channels 2 pcm "plughw:0,1" }  # HDMI
            b { channels 2 pcm "plughw:0,0" }  # 3.5mm
        }
        bindings {
            0 { slave a channel 0 }
            1 { slave a channel 1 }
            2 { slave b channel 0 }
            3 { slave b channel 1 }
        }
    }
    ttable [
        [ 1 0 1 0 ]
        [ 0 1 0 1 ]
    ]
}

pcm.!default {
    type plug
    slave.pcm "both"
}

ctl.!default {
    type hw
    card 0
}
EOF

    log_msg "✅ ALSA configuration created"
}

# Test audio playback with mpv
test_audio_playback() {
    log_msg "🎵 Testing audio playback with mpv..."

    # Test HDMI only first
    log_msg "   Testing HDMI output..."
    if timeout 10 mpv --no-video --ao=alsa:device=plughw:0,1 --volume=100 --length=5 "$AUDIO_FILE" >/dev/null 2>&1; then
        log_msg "✅ HDMI audio playback successful"
    else
        log_msg "❌ HDMI audio playback failed"
    fi

    # Test 3.5mm only
    log_msg "   Testing 3.5mm output..."
    if timeout 10 mpv --no-video --ao=alsa:device=plughw:0,0 --volume=100 --length=5 "$AUDIO_FILE" >/dev/null 2>&1; then
        log_msg "✅ 3.5mm audio playback successful"
    else
        log_msg "❌ 3.5mm audio playback failed"
    fi

    # Test both outputs using default (configured for both)
    log_msg "   Testing both outputs simultaneously..."
    if timeout 10 mpv --no-video --ao=alsa --volume=100 --length=5 "$AUDIO_FILE" >/dev/null 2>&1; then
        log_msg "✅ Dual audio playback successful"
        return 0
    else
        log_msg "❌ Dual audio playback failed"
        return 1
    fi
}

# Main execution
main() {
    log_msg "🚀 Starting comprehensive audio test..."

    # Initialize log
    echo "=== HDMI Tester Audio Test - $(date) ===" > "$LOG_FILE"

    # Run tests
    local tests_passed=0
    local total_tests=5

    check_audio_file && ((tests_passed++))
    test_alsa_devices && ((tests_passed++))
    setup_alsa_config && ((tests_passed++))
    test_hdmi_audio && ((tests_passed++))
    test_analog_audio && ((tests_passed++))

    log_msg "📊 Test Results: $tests_passed/$total_tests tests passed"

    if [ $tests_passed -eq $total_tests ]; then
        log_msg "✅ All audio tests passed - attempting playback test"
        if test_audio_playback; then
            log_msg "🎉 Audio system fully functional!"
            return 0
        else
            log_msg "⚠️  Audio devices work but playback failed"
            return 1
        fi
    else
        log_msg "❌ Some audio tests failed"
        return 1
    fi
}

# Run main function
main "$@"
