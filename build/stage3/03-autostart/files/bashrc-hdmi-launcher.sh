# HDMI Tester Auto-Launch
# Automatically starts the configured default service on console login
# This runs only on TTY1 (primary console) to avoid issues with SSH/other terminals

# Check if we're on TTY1 and not in a nested shell
if [ "$(tty)" = "/dev/tty1" ] && [ -z "$HDMI_LAUNCHER_RAN" ]; then
    export HDMI_LAUNCHER_RAN=1
    /usr/local/bin/hdmi-auto-launcher
fi
