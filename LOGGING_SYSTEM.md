# Enhanced Logging System - Summary

## Overview
Comprehensive two-tier logging system implemented for Raspberry Pi HDMI Tester builds with detailed debug capabilities.

## What Was Implemented

### 1. Two-Tier Logging System
- **Terminal Output**: Simplified, shows only major events (🚀 starting, ✅ completed, ❌ failed)
- **Detailed Log File**: Captures EVERYTHING including:
  - Complete build environment
  - All stdout/stderr output
  - Stage-by-stage timing
  - Resource monitoring (disk, memory)
  - File checksums
  - Error context with surrounding lines

### 2. Logging Infrastructure

#### Core Components
- `scripts/logging-utils.sh` - Reusable logging functions
  - `init_logging()` - Initialize log file with header
  - `log_section()` / `log_subsection()` - Structured sections
  - `log_event()` - Terminal + file output
  - `log_info()` - File-only verbose logging
  - `capture_environment()` - System info capture
  - `monitor_disk_space()` - Disk usage tracking
  - `monitor_memory()` - Memory usage tracking
  - `log_checksum()` - File integrity logging
  - `start_stage_timer()` / `end_stage_timer()` - Timing tracking
  - `capture_error_context()` - Error context extraction
  - `finalize_log()` - Build summary

#### Enhanced Build Script
- `scripts/build-image.sh` - Updated to use logging system
  - Structured logging for all operations
  - Progress tracking with timers
  - Resource monitoring at checkpoints
  - Comprehensive error reporting
  - Asset validation with checksums

### 3. GitHub Actions Integration

#### Workflow Updates (`.github/workflows/build-release.yml`)
- Simplified terminal output (major events only)
- Detailed log captured to `build/pi-gen-work/build-detailed.log`
- **Logs always uploaded as artifacts** (90-day retention)
- **Logs always committed to repository** (regardless of success/failure)
  - Success: `logs/successful-builds/build-YYYY-MM-DD_HH-MM-SS_vX.X.X.log`
  - Failure: `logs/failed-builds/build-YYYY-MM-DD_HH-MM-SS_FAILED.log`
- Automatic compression for large logs (>50MB)
- Enhanced build summary with log information

### 4. Log Analysis Tools

#### `scripts/analyze-logs.sh`
Analyzes a single build log:
- Extracts build metadata
- Counts errors/warnings
- Shows stage timings
- Displays disk/memory progression
- Lists file checksums
- Provides error context
- Offers recommendations based on detected issues

#### `scripts/compare-logs.sh`
Compares two build logs:
- Metadata comparison
- Outcome differences
- Duration analysis
- Stage timing comparison
- Error differences (unique to each build)
- Resource usage comparison
- Checksum comparison
- Tool version comparison
- Actionable recommendations

### 5. Documentation

#### `logs/README.md`
- Complete guide to log system
- Directory structure explanation
- Log file naming conventions
- Contents description
- Usage examples
- Analysis instructions

#### Updated Documentation
- `docs/BUILDING.md` - Added logging section with usage examples
- `docs/TROUBLESHOOTING.md` - Comprehensive debugging guide using logs
  - How to access logs
  - Analysis workflows
  - Common log patterns
  - Debugging procedures

## File Structure

```
Raspberry_HDMI_Tester/
├── scripts/
│   ├── logging-utils.sh          # NEW - Logging functions library
│   ├── build-image.sh             # UPDATED - Uses logging system
│   ├── analyze-logs.sh            # NEW - Single log analysis
│   └── compare-logs.sh            # NEW - Compare two logs
├── logs/                          # NEW - Log storage directory
│   ├── README.md                  # NEW - Log system documentation
│   ├── .gitkeep                   # NEW - Preserve directory
│   ├── successful-builds/         # AUTO-CREATED - Success logs
│   └── failed-builds/             # AUTO-CREATED - Failure logs
├── .github/workflows/
│   └── build-release.yml          # UPDATED - Enhanced logging
├── docs/
│   ├── BUILDING.md                # UPDATED - Added logging section
│   └── TROUBLESHOOTING.md         # UPDATED - Added debugging guide
└── build/pi-gen-work/
    └── build-detailed.log         # CREATED DURING BUILD - Main log file
```

## Usage Examples

### During Build
```bash
# Start build (logs automatically)
./scripts/build-image.sh

# Monitor in real-time (different terminal)
tail -f build/pi-gen-work/build-detailed.log
```

### After Build
```bash
# Analyze the log
./scripts/analyze-logs.sh build/pi-gen-work/build-detailed.log

# Compare with previous build
./scripts/compare-logs.sh \
  logs/successful-builds/build-2025-10-17_14-30-45_v1.0.0.log \
  logs/failed-builds/build-2025-10-17_15-22-10_FAILED.log

# Search for specific errors
grep -i "error" build/pi-gen-work/build-detailed.log

# View last 50 lines
tail -n 50 build/pi-gen-work/build-detailed.log
```

### GitHub Actions
```bash
# After workflow run:
# 1. Download artifact: "build-logs-YYYY-MM-DD_HH-MM-SS"
# 2. Or view committed log in repository: logs/successful-builds/ or logs/failed-builds/
# 3. Analyze downloaded log
./scripts/analyze-logs.sh ~/Downloads/build-detailed.log
```

## What Gets Logged

### Environment Information
- System specs (OS, kernel, CPU, memory, disk)
- Tool versions (git, qemu, debootstrap, etc.)
- Environment variables
- GitHub workflow context (if applicable)

### Build Configuration
- pi-gen config file contents
- Custom stage configurations
- Asset checksums and metadata

### Stage-by-Stage Output
- All stdout/stderr from every command
- Timing for each stage (start, end, duration)
- Resource snapshots at checkpoints
- File operations and checksums

### Error Information
- Full error messages
- Surrounding log context (configurable lines before/after)
- Exit codes
- Failed command details

### Build Summary
- Total duration
- Success/failure status
- Final resource state
- Output file information

## Benefits

### For Developers
- **Complete visibility** into build process
- **Easy debugging** with comprehensive logs
- **Performance analysis** via timing information
- **Comparison tools** to identify what changed

### For CI/CD
- **Always available logs** (artifacts + repository commits)
- **Timestamped history** of all builds
- **Failure analysis** without re-running builds
- **Audit trail** of build changes over time

### For Troubleshooting
- **Error context** automatically captured
- **Resource tracking** identifies space/memory issues
- **Pattern detection** via log comparison
- **Recommendations** based on detected issues

## Log Retention

- **GitHub Artifacts**: 90 days
- **Repository Commits**: Indefinite (in git history)
- **Local Builds**: Until manually deleted

## Advanced Features

### Automatic Compression
Logs larger than 50MB are automatically compressed before committing to repository (GitHub file size limits).

### Structured Format
Logs use clear sections with headers:
```
==================================================================
  SECTION NAME
==================================================================
Timestamp: 2025-10-17 14:30:45 UTC

... section content ...
```

### Resource Monitoring
Disk and memory tracked at key checkpoints:
- After asset validation
- Before pi-gen build
- After pi-gen build
- Before/after each custom stage

### Checksum Tracking
All important files have SHA256 checksums logged:
- Test pattern image
- Audio file
- Final image file
- Deployed assets

### Error Context
When errors occur, automatically capture surrounding lines for debugging context (default: 20 lines before, 20 after).

## Future Enhancements (Optional)

Potential improvements for future versions:
- JSON-formatted logs for machine parsing
- Integration with log aggregation services
- Automatic issue creation for failed builds
- Build metrics dashboard
- Slack/email notifications with log summaries
- Log retention policies with automatic archival

---

**Created**: October 17, 2025
**Status**: Fully Implemented
**Next Steps**: Test with actual build run
