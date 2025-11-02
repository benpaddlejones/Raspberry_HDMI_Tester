# Raspberry Pi OS Migration Plan

This document outlines the plan to migrate the Raspberry Pi HDMI Tester project from a Debian Bookworm base to the official Raspberry Pi OS. The primary goals are to simplify the build process, improve hardware compatibility, and streamline the audio/video configuration.

## Phase 1: Analysis and Initial Setup

- [x] **Analyze Existing Build Scripts:** Reviewed scripts in `build/stage3/` and `scripts/` to understand functionality.
- [x] **Identify Redundant Scripts:** Pinpointed and removed complex audio configuration scripts.
- [x] **Update `pi-gen` Configuration:** Modified `build/config` - updated IMG_NAME to "RPi_HDMI_Tester_PiOS", confirmed RELEASE="bookworm" for Raspberry Pi OS base.
- [ ] **Establish Baseline Build:** Perform an initial build with the new configuration to identify immediate failures.

## Phase 2: Core System Migration

- [x] **Migrate `stage2`:** Adapted `stage2/01-sys-tweaks` for Raspberry Pi OS - added console autologin via `raspi-config nonint do_boot_behaviour B2`.
- [x] **Review Package Lists:** Simplified `stage3/00-install-packages/00-packages` - now using `vlc` metapackage instead of individual codec libraries, keeping only essential diagnostic tools.
- [x] **Update `prerun.sh`:** Verified `prerun.sh` is standard pi-gen script, compatible with new environment.

## Phase 3: Audio and Video Simplification

- [x] **Decommission Old Audio Scripts:** Removed the complex audio scripting from `stage3/03-autostart/files`. This includes:
    - `alsa-multi-card.service`
    - `asound.conf`
    - `detect-hdmi-audio`
    - `generate-asound-conf`
    - `hdmi-audio-config.service`
    - `generate-multi-card-asound`
- [x] **Implement Simplified A/V Playback:**
    - Modified all test scripts (`hdmi-test`, `audio-test`, etc.) to rely on VLC's automatic audio device detection, removing calls to `detect-hdmi-audio`.
- [x] **Simplify Test Assets:** Test assets are properly organized in `stage3/01-test-image/files` (videos with embedded audio: WebM for Pi 4+, MP4 for Pi 3) and `stage3/02-audio-test/files` (standalone audio: FLAC files for stereo and surround testing).

## Phase 4: Boot and Autostart

- [x] **Refactor Autostart Logic:** Replaced the `bashrc-hdmi-launcher.sh` with a systemd-based approach.
    - **Requirement:** All services are explicitly disabled by default to ensure the system boots to a clean terminal for manual testing.
- [x] **Update Boot Configuration:** `stage3/04-boot-config` already properly configured for Raspberry Pi OS with HDMI settings in `/boot/config.txt` and `/boot/cmdline.txt`. Handles both `/boot/firmware/` (modern) and `/boot/` (legacy) locations.
- [x] **Enable Console Autologin:** Configured in `stage2/01-sys-tweaks/01-run.sh` using `raspi-config nonint do_boot_behaviour B2` - automatically logs in the `pi` user on console without starting any tests.

## Phase 5: Validation and Testing

- [ ] **Update QEMU Testing:** Modify `tests/qemu-test.sh` to work with the new image.
- [ ] **Perform Hardware Testing:** Test the migrated image on target Raspberry Pi hardware (e.g., Pi 3B+, Pi 4).
- [ ] **Validate Audio/Video Output:** Confirm that the test pattern and audio play correctly over HDMI.
- [ ] **Run Validation Scripts:** Execute `tests/validate-image.sh` to ensure the image integrity.

## Phase 6: Documentation and Cleanup

**NOTE: This phase is ON HOLD. Do not perform these tasks until explicitly instructed.**

- [ ] **Update `README.md`:** Reflect the changes in the build process and architecture.
- [ ] **Update Build and Flashing Docs:** Revise the documentation in the `docs/` directory.
- [ ] **Remove Obsolete Files:** Delete all decommissioned scripts and configuration files.
- [ ] **Create Final Image:** Build the release-ready image and generate checksums.
