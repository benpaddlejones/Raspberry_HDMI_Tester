# HDMI Audio Root Cause Analysis & Remediation Plan

A recurring misconfiguration on Raspberry Pi platforms running the vc4 KMS stack shows up when the boot firmware injects legacy `snd_bcm2835.enable_hdmi=0` while Hot-Plug Detect never asserts, so the DRM driver never negotiates a display mode and ALSA never exposes an HDMI sink; to restore audio, confirm the lack of HPD with `kmsprint`, add `vc4.force_hotplug=<mask>` to `/boot/firmware/cmdline.txt` (forcing the relevant connector(s)), reboot and validate the link with `kmsprint`/`kmstest`, and only then retest audio routing once the connector reports as `connected`.

**Status (2025-10-30):** Analysis of diagnostic logs from a failing device confirmed that the audio test service was using a direct hardware ALSA device (e.g., `plughw:1,0`). This device does not perform automatic format conversion, causing VLC to fail with a `no supported sample format` error when playing FLAC files. The root cause was the device detection logic, which fell back to `plughw` instead of prioritizing robust, format-converting PCM aliases defined in the system's ALSA configuration.

**Remediation (2025-10-30):** The `detect-hdmi-audio` script has been updated to prioritize the `hdmi_auto` PCM alias. This custom ALSA device is specifically configured to:
1.  Automatically identify the correct HDMI output.
2.  Apply necessary sample rate, format, and channel count conversions.
3.  Provide a stable and reliable audio sink for applications like VLC.

By forcing the audio test to use `hdmi_auto`, the ALSA plugin system now correctly handles the PCM format negotiation, resolving the error and restoring audio playback. The script's logic was reordered to check for `hdmi_auto` first, ensuring it is always preferred over less reliable hardware devices.
