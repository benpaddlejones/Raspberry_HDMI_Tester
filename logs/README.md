# Build Logs Directory

This directory contains comprehensive build logs from GitHub Actions builds.

## Directory Structure

```
logs/
├── successful-builds/          # Logs from successful builds
│   └── build-YYYY-MM-DD_HH-MM-SS_vX.X.X.log
├── failed-builds/              # Logs from failed builds
│   └── build-YYYY-MM-DD_HH-MM-SS_FAILED.log
└── README.md                   # This file
```

## Log File Naming Convention

- **Successful builds**: `build-YYYY-MM-DD_HH-MM-SS_vX.X.X.log`
  - Example: `build-2025-10-17_14-30-45_v1.0.0.log`

- **Failed builds**: `build-YYYY-MM-DD_HH-MM-SS_FAILED.log`
  - Example: `build-2025-10-17_15-22-10_FAILED.log`

## Log Contents

Each log file contains:

### 1. Build Environment Information
- Timestamp and build ID
- GitHub workflow run details
- System resources (CPU, memory, disk space)
- OS and kernel version
- Installed tool versions (qemu, debootstrap, etc.)
- Environment variables

### 2. Build Configuration
- pi-gen configuration settings
- Custom stage configuration
- Asset checksums (test pattern, audio file)

### 3. Stage-by-Stage Build Output
- **Stage 0**: Bootstrap (debootstrap, basic system)
- **Stage 1**: Core Raspberry Pi OS components
- **Stage 2**: Networking and utilities
- **Stage Custom**: HDMI tester installation
  - 00-install-packages
  - 01-test-image
  - 02-audio-test
  - 03-autostart
  - 04-boot-config

### 4. Resource Monitoring
- Disk space usage before/during/after each stage
- Memory usage tracking
- Build timing for each stage
- CPU usage statistics

### 5. Validation and Checksums
- File integrity checks
- Image file checksums
- Asset verification
- Deployment artifact sizes

### 6. Error Context (if applicable)
- Error messages with surrounding context
- Stack traces
- Failed command details
- Suggestions for resolution

## Using the Logs

### Finding Logs

**Latest successful build**:
```bash
ls -t logs/successful-builds/ | head -n 1
```

**Latest failed build**:
```bash
ls -t logs/failed-builds/ | head -n 1
```

### Analyzing Logs

Use the provided analysis scripts:

```bash
# Extract errors and warnings
./scripts/analyze-logs.sh logs/failed-builds/build-2025-10-17_15-22-10_FAILED.log

# Compare two builds
./scripts/compare-logs.sh \
  logs/successful-builds/build-2025-10-17_14-30-45_v1.0.0.log \
  logs/failed-builds/build-2025-10-17_15-22-10_FAILED.log
```

### Debugging Build Issues

1. **Find the failed build log** in `logs/failed-builds/`
2. **Search for "ERROR"** or "FAILED" sections
3. **Check the error context** - logs include surrounding lines
4. **Review resource usage** - was there a disk/memory issue?
5. **Compare with successful build** - what changed?

### Download Logs from GitHub Actions

Logs are also available as GitHub Actions artifacts:

1. Go to the workflow run in GitHub Actions
2. Scroll to "Artifacts" section
3. Download `build-logs-YYYY-MM-DD_HH-MM-SS`

Artifacts are retained for 90 days.

## Log Retention

- **Repository logs**: Kept indefinitely in git history
- **GitHub Artifacts**: Retained for 90 days
- **Old logs**: Can be archived or removed as needed

To archive old logs:
```bash
# Create archive of logs older than 30 days
find logs/ -name "*.log" -mtime +30 -exec tar -czf old-logs-$(date +%Y%m%d).tar.gz {} +
```

## Troubleshooting

### "Log file is too large"

GitHub has file size limits. If a log exceeds limits:
- The workflow will compress it before committing
- Original uncompressed log is always in artifacts

### "Cannot find log for specific build"

- Check both `successful-builds/` and `failed-builds/`
- Check GitHub Actions artifacts (retained for 90 days)
- Log filename includes timestamp from when build started

### "Log is truncated"

This shouldn't happen with the new logging system, but if it does:
- Download the artifact from GitHub Actions
- The artifact contains the complete uncompressed log

## Contributing

When modifying the build system:
- Ensure logs capture your changes
- Add new sections for new build stages
- Include relevant debugging information
- Test that logs are created correctly

---

**Last Updated**: October 17, 2025
