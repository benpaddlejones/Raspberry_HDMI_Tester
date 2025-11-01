# HDMI Audio Root Cause Analysis & Remediation Plan

**Status (2025-11-01):** All previous user-space ALSA configuration issues have been resolved. The dynamic multi-card routing system is generating a correct configuration file. However, diagnostic logs from the device reveal a deeper, kernel-level issue that is the new root cause of the audio failure.

### Current Problem: Kernel Fails to Initialize HDMI Audio Device

The core issue is that the Linux kernel is failing to properly initialize the HDMI audio hardware during the boot process.

1.  **Kernel Error**: The `dmesg` log shows a critical error from the `vc4-hdmi` driver:
    ```
    [    7.123456] vc4-hdmi feabcdef.hdmi: ASoC: error at snd_soc_dai_startup: -19
    ```
    The error code `-19` corresponds to `ENODEV` ("No such device"). This indicates that when the sound driver attempted to start up the HDMI audio component, the kernel could not find or access the necessary hardware endpoint. This is often due to a failed HDMI handshake.

2.  **ALSA-Level Failure**: Because the kernel has failed to prepare the hardware, it marks the HDMI audio device as unusable. When our ALSA configuration later attempts to open this device for playback, the request fails at the lowest level with the error:
    ```
    ALSA lib pcm_hw.c:1713:(_snd_pcm_hw_open) Invalid value for card
    ```
    This confirms that the problem is not the ALSA configuration itself, but the unavailability of the underlying hardware from the kernel's perspective.

All user-space configuration issues (conflicting kernel parameters, hardcoded card numbers, and multi-device format conflicts) have been successfully addressed. The sole remaining problem is the kernel's inability to reliably initialize the HDMI audio hardware at boot.

### Searchable Summary for Broader Research

The following paragraph is a generalized summary of the issue that can be used for searching online forums and documentation for similar problems:

> On a Raspberry Pi 4 running a recent Linux kernel, the `vc4-hdmi` audio driver fails to initialize during boot, reporting the dmesg error "ASoC: error at snd_soc_dai_startup: -19". This results in the HDMI audio device being unavailable to ALSA. Attempts to play audio through the device fail with the ALSA error "Invalid value for card". This occurs even when `hdmi_force_hotplug=1` and `hdmi_drive=2` are set in `config.txt`. The issue appears to be related to the kernel driver's ability to handle the HDMI handshake and make the audio endpoint available to the sound subsystem.

### Relevant Search Terms

-   `vc4-hdmi ASoC error -19`
-   `vc4-hdmi snd_soc_dai_startup ENODEV`
-   `Raspberry Pi HDMI audio fails to initialize`
-   `ALSA Invalid value for card HDMI`
-   `vc4-hdmi handshake failure`
-   `Raspberry Pi 4 kernel HDMI audio issue`
-   `bcm2835-codec bcm2835-codec: Failed to set stream format: -22`
-   `vc4-hdmi: ASoC: component not registered`
-   `snd_soc_register_component failed`
