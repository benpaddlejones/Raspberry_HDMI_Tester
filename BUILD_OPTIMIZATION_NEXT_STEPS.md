# Build Optimization - Next Steps

## Recently Completed (v0.9.7.4+)

✅ **QEMU Kernel Path Fix** - Unblocks automated boot tests
- Downloads kernel from dhruvvyas90/qemu-rpi-kernel repo
- Installs to `/usr/share/qemu/qemu-arm-kernel`
- **Impact**: QEMU tests now functional

✅ **Stage2 Package Exclusions** - 400MB+ reduction, 5-10 min savings
- Created `00-packages-nr` exclusion list (44 packages)
- Removes: bluez, avahi-daemon, rpi-connect-lite, build tools, unused utilities
- **Impact**: 400-500MB smaller images, faster builds

✅ **APT Update Caching** - Prevents 3× redundant updates
- GitHub Actions cache for APT packages
- **Impact**: ~30 seconds saved per build

✅ **Faster Compression (pigz)** - 8-10 min savings
- Switched from ZIP to parallel gzip (pigz -9)
- Compression time: ~10 min → ~2 min (80% faster)
- Output format: .img.gz instead of .img.zip
- **Impact**: 8-10 minutes saved, Raspberry Pi Imager compatible

✅ **Early Image Deduplication (zerofree)** - 1-2 min savings
- Runs zerofree on root partition after build, before compression
- Zeros free space in ext4 filesystem (20-50MB reduction)
- Speeds up subsequent compression step
- **Impact**: 1-2 minutes saved, smaller final image

✅ **Disk Space Monitoring & Alerts** - Prevents build failures
- Background monitoring checks disk usage every 5 minutes
- Warns at 85%, aborts at 90% to prevent catastrophic failures
- Logs all checks with timestamps for post-build analysis
- **Impact**: Early warning system prevents late-stage failures (89% usage observed previously)

✅ **Build Time Breakdown Metrics** - Visibility into build performance
- Extracts stage timing data from build logs
- Displays formatted breakdown in GitHub Actions summary
- Shows duration and status for each build stage
- **Impact**: Better visibility into where time is spent, aids future optimization

✅ **Multiple Checksum Formats** - Enhanced security and compatibility
- Generates SHA256, SHA1, MD5, and BLAKE2 checksums
- All formats uploaded to GitHub releases
- Updated verification instructions support all formats
- **Impact**: Better security (SHA256/BLAKE2), legacy tool compatibility (SHA1/MD5)

**Current Status**: 8 optimization tasks completed
**Build Time**: 61 min → 39-41 min (33% faster)
**Image Size**: ~400-500MB reduction
**Reliability**: Disk monitoring prevents 90%+ failures

---

## Implementation Progress Summary

### Completed (8/13 total items)
1. ✅ QEMU Kernel Path Fix
2. ✅ Stage2 Package Exclusions
3. ✅ APT Update Caching
4. ✅ Faster Compression (pigz)
5. ✅ Early Image Deduplication (zerofree)
6. ✅ Disk Space Monitoring & Alerts
7. ✅ Build Time Breakdown Metrics
8. ✅ Multiple Checksum Formats

### Remaining High-Value Items (2)
- Parallel Package Installation (2-3 min savings)
- Stage-Specific APT Cache (30-60s savings)

### Total Potential Remaining Savings: 2.5-4 minutes

---

## High Priority - Next Phase

### 1. Parallel Package Installation
**Estimated Savings**: 2-3 minutes
**Complexity**: Medium

Current state: Packages install sequentially in each stage.

**Implementation**:
```bash
# In stage run scripts, replace sequential apt-get with parallel
# Use apt-fast or custom parallel wrapper
apt-get install -y $(cat 00-packages) --download-only
apt-get install -y $(cat 00-packages) -o APT::Install-Recommends=0
```

**Files to modify**:
- `build/stage*/*/00-run.sh` or `00-run-chroot.sh`
- Consider using `apt-fast` package for parallel downloads

**Risks**: Network bandwidth limitations, dependency conflicts

---

## Medium Priority

### 5. Stage-Specific APT Cache
**Estimated Savings**: 30-60 seconds
**Complexity**: Medium

Current: Global APT cache for all stages

**Implementation**:
```yaml
# Separate caches per stage to avoid cache invalidation
- name: Cache stage0 packages
  uses: actions/cache@v3
  with:
    path: /var/cache/apt/stage0/
    key: apt-stage0-${{ hashFiles('build/stage0/**/00-packages*') }}
```

**Files to modify**:
- `.github/workflows/build-release.yml`
- pi-gen configuration to use stage-specific cache dirs

---

### 6. Incremental Build Support
**Estimated Savings**: 40-50 minutes (for rebuilds)
**Complexity**: High

Current: Every build starts from scratch

**Implementation**:
- Cache stage outputs (stage0.img, stage1.img, etc.)
- Only rebuild changed stages
- Requires hash-based change detection

**Risks**: Stale cache issues, complex invalidation logic

---

## Low Priority / Future

### 7. Parallel Stage Execution
**Estimated Savings**: 10-15 minutes
**Complexity**: Very High

Some stages could run in parallel if dependencies allow.

**Challenges**:
- Stage dependencies are complex
- pi-gen not designed for parallel execution
- High risk of build failures

---

### 8. Local Build Cache Server
**Estimated Savings**: 2-3 minutes
**Complexity**: High

Set up apt-cacher-ng or similar for package caching across builds.

**Requirements**:
- Persistent cache server
- Network configuration
- Additional infrastructure

---

## Recommended Implementation Order

1. ~~**Faster Compression**~~ ✅ **COMPLETED** (saves 8-10 min)
2. ~~**Early Deduplication**~~ ✅ **COMPLETED** (saves 1-2 min)
3. ~~**Disk Space Monitoring**~~ ✅ **COMPLETED** (prevents failures)
4. ~~**Build Time Breakdown**~~ ✅ **COMPLETED** (improves visibility)
5. ~~**Multiple Checksums**~~ ✅ **COMPLETED** (security improvement)
6. **Parallel Package Installation** (Medium complexity, medium impact: 2-3 min)
7. **Stage-Specific APT Cache** (Medium complexity, minor impact: 30-60s)

**Total Potential Savings**: 2.5-4 additional minutes (on top of 22 min already saved)

**Final Target**: 61 min → 36-37 min (40% faster builds)

**Progress**: 8/13 optimization items completed (62%)

---

## Testing Strategy

For each optimization:

1. **Local Testing**: Test in dev container first
2. **Single Build**: Run one GitHub Actions build
3. **Validation**: Verify image quality (QEMU test, checksums)
4. **Time Comparison**: Compare against baseline
5. **Stability**: Run 2-3 builds to ensure consistency

---

## Monitoring & Metrics

Track these metrics for each optimization:

- **Build Time**: Total and per-stage
- **Image Size**: Uncompressed and compressed
- **Disk Usage**: Peak during build
- **Network Usage**: Package downloads
- **Failure Rate**: Builds failed vs succeeded

---

## References

- Original build time: ~61 minutes (v0.9.7.3)
- Current build time: ~39-41 minutes (v0.9.7.6+ with optimizations)
- Target build time: <38 minutes
- Image size: 2.8GB uncompressed, ~600-700MB compressed (.gz)
- Disk usage: 50GB → 64GB (89% peak)

---

**Last Updated**: October 25, 2025
**Version**: Post-v0.9.7.6 optimizations
**Completion**: 8/13 items (62%)
**Time Saved**: 22 minutes (33% faster)
**Next Milestone**: Parallel package installation
