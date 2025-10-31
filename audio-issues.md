# HDMI Audio Root Cause Analysis & Remediation Plan

A recurring misconfiguration on Raspberry Pi platforms running the vc4 KMS stack shows up when the boot firmware injects legacy `snd_bcm2835.enable_hdmi=0` while Hot-Plug Detect never asserts, so the DRM driver never negotiates a display mode and ALSA never exposes an HDMI sink; to restore audio, confirm the lack of HPD with `kmsprint`, add `vc4.force_hotplug=<mask>` to `/boot/firmware/cmdline.txt` (forcing the relevant connector(s)), reboot and validate the link with `kmsprint`/`kmstest`, and only then retest audio routing once the connector reports as `connected`.

**Status (2025-10-31):** Further analysis of on-device diagnostic logs (`rpi4/diagnostic-report.txt`) has revealed the true root cause. While the `detect-hdmi-audio` script correctly identifies and instructs VLC to use the `hdmi_auto` PCM, ALSA rejects this with an `Invalid argument` error.

The core issues are:
1.  **Hardcoded ALSA Configuration:** The `hdmi_dmix` plugin, which `hdmi_auto` depends on, is hardcoded to use `card 0`. On the failing device, `card 0` is the analog headphone jack (`bcm2835 Headphones`), while the correct HDMI output is `card 1` (`vc4-hdmi`). The configuration is attempting to apply HDMI settings to the wrong device.
2.  **Conflicting Kernel Parameter:** The kernel is booting with `snd_bcm2835.enable_hdmi=0`. This legacy parameter, intended for older drivers, is likely interfering with the modern `vc4-kms-v3d` driver's ability to correctly and consistently manage HDMI audio devices, contributing to the card index confusion.

**Next Steps:**
1.  The `hdmi_dmix` ALSA configuration must be made dynamic. It needs to be modified at boot time to target the correct card number identified by the `detect-hdmi-audio` script.
2.  The `fix-cmdline.service` needs to be verified to ensure it is effectively removing the conflicting `snd_bcm2835.enable_hdmi=0` parameter on the first boot.
3.  The `detect-hdmi-audio` script will be updated to dynamically generate a small ALSA configuration snippet (`/run/hdmi-card.conf`) that points the `hdmi_dmix` slave to the correct card, and the main `/etc/asound.conf` will be updated to include this dynamic configuration.
