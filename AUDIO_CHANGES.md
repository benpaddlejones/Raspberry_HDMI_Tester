# Audio Path Hardening Summary

These adjustments ensure the stage 3 test services produce HDMI audio on every supported Raspberry Pi model without relying on model-specific device numbering.

## What Changed

- **Service launch path** – `audio-test.service` now executes `/opt/hdmi-tester/audio-test`, which already performs device discovery, structured logging, and restart-safe startup sequencing. This replaces the embedded VLC call that depended on a manually exported `AUDIODEV` value.
- **Device detection usage** – `hdmi-test` invokes the packaged `/opt/hdmi-tester/detect-hdmi-audio` helper instead of the missing `detect_hdmi_audio` shell function. Every invocation now resolves the actual HDMI card before VLC starts.
- **ALSA target selection** – `detect-hdmi-audio` returns `plughw:<card>,0` (or `default` as a final fallback) so playback always runs through ALSA’s format-converting pipeline. This keeps the `plug` layer active for vc4-hdmi devices, eliminating the "no supported sample format" failure seen on DRM-based boards.
- **Diagnostics coverage** – `hdmi-diagnostics` captures the full ALSA environment (version info, card/PCM maps, module lists, device nodes, configs, saved state, and recent kernel log extracts) so field reports include everything needed to debug HDMI audio on any Pi revision.

## Why It Works Across Raspberry Pi Versions

- The helper script inspects live ALSA card listings, so the selected device automatically follows whichever card index the firmware assigns (Pi 3, 4, and 5 all work without special cases).
- `plughw` guarantees format conversion even if `/etc/asound.conf` changes or additional HDMI outputs appear, preventing failures when the hardware exposes S/PDIF-only formats.
- Delegating to the existing wrapper script keeps the logging, retries, and validation logic in one place, reducing the risk of regressions when new audio flows or codecs are introduced.

Rebuild the image after these updates; the stage 3 HDMI tests will bind to the correct ALSA endpoint and emit audio immediately once the services start.

## October 2025 Update – First-Boot cmdline Cleanup & Module Defaults

- **Deferred cmdline fix** – `fix-cmdline.service` now runs under a timer, eliminating the multi-user.target ordering loop so the cleanup executes once the first boot settles (and still triggers the protective reboot).
- **State directory provisioning** – `/var/lib/hdmi-tester/` is shipped in the image to satisfy the service’s `ConditionPathExists` guard without race conditions.
- **Kernel line hygiene** – We stop injecting `snd_bcm2835.*` flags into `cmdline.txt`; the fixer script rebuilds the line with only core boot knobs and rejects any legacy audio parameters left behind by firmware.
- **Modprobe-based audio enablement** – A new `hdmi-audio.conf` in `modprobe.d` keeps HDMI and headphone outputs forced on at module load, removing the need for kernel parameter overrides while still protecting against firmware toggles.
- **Validation logging** – Updated messaging highlights that audio defaults now flow through ALSA/module configuration, clarifying where to adjust behavior for future boards.
