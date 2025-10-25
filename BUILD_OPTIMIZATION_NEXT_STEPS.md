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

**Expected Total Impact**: 61 min → 39-41 min (33% faster), 400-500MB smaller

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

### 2. Disk Space Monitoring & Alerts
**Estimated Savings**: Prevents failures, not time
**Complexity**: Low

Current: Build fails if disk fills up (89% usage observed)

**Implementation**:
```yaml
# In .github/workflows/build-release.yml
- name: Monitor disk space during build
  run: |
    # Check every 5 minutes in background
    while true; do
      USAGE=$(df --output=pcent / | tail -1 | tr -d '% ')
      if [ $USAGE -gt 85 ]; then
        echo "⚠️ WARNING: Disk usage at ${USAGE}%"
      fi
      if [ $USAGE -gt 90 ]; then
        echo "❌ CRITICAL: Disk usage at ${USAGE}% - aborting"
        exit 1
      fi
      sleep 300
    done &
    MONITOR_PID=$!
```

**Files to modify**:
- `.github/workflows/build-release.yml` (new step before "Build Raspberry Pi image")

**Impact**: Early warning system, prevents late-stage failures

---

### 3. Build Time Breakdown Metrics
**Estimated Savings**: None (visibility only)
**Complexity**: Low

Current: Only total build time logged

**Implementation**:
```bash
# Already partially implemented in logging-utils.sh
# Enhance to show breakdown in GitHub Actions summary

# In scripts/build-image.sh, add summary at end:
{
  echo "## 📊 Build Time Breakdown"
  echo "| Stage | Duration |"
  echo "|-------|----------|"
  grep "Stage Timer" "${BUILD_LOG_FILE}" | awk '{print "| " $3 " | " $5 " |"}'
} >> $GITHUB_STEP_SUMMARY
```

**Files to modify**:
- `scripts/build-image.sh` (add timing summary)
- `.github/workflows/build-release.yml` (display in summary)

**Impact**: Better visibility into where time is spent

---

## Medium Priority

### 4. Multiple Checksum Formats
**Estimated Savings**: None (security improvement)
**Complexity**: Low

Current: SHA256 only

**Implementation**:
```bash
# In scripts/generate-checksums.sh
sha256sum "${IMAGE_FILE}" > "${CHECKSUM_FILE}.sha256"
sha1sum "${IMAGE_FILE}" > "${CHECKSUM_FILE}.sha1"
md5sum "${IMAGE_FILE}" > "${CHECKSUM_FILE}.md5"
b2sum "${IMAGE_FILE}" > "${CHECKSUM_FILE}.blake2"
```

**Files to modify**:
- `scripts/generate-checksums.sh`
- `.github/workflows/build-release.yml` (upload all checksum files)

---

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
3. **Parallel Package Installation** (Medium complexity, medium impact: 2-3 min)
4. **Disk Space Monitoring** (Low complexity, prevents failures)
5. **Build Time Breakdown** (Low complexity, improves visibility)
6. **Multiple Checksums** (Low complexity, security improvement)

**Total Potential Savings**: 2-3 additional minutes (on top of 22 min already saved)

**Final Target**: 61 min → 36-38 min (40% faster builds)

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
**Next Review**: After implementing items 1-3