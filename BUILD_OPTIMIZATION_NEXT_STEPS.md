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

**Expected Total Impact**: 61 min → 48-49 min (21% faster), 400-500MB smaller

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

### 2. Faster Compression Algorithm
**Estimated Savings**: 8-10 minutes  
**Complexity**: Low

Current: ZIP with single-threaded deflate (~10 min for 2.8GB image)

**Implementation Options**:
```bash
# Option A: pigz (parallel gzip) - fastest
pigz -9 -k image.img  # Creates image.img.gz

# Option B: zip with lower compression
zip -1 image.zip image.img  # Fast compression (5:1 ratio)

# Option C: zstd (best balance)
zstd -19 image.img -o image.img.zst  # Fast + excellent compression
```

**Files to modify**:
- `.github/workflows/build-release.yml` (line ~890 in "Prepare release assets")
- Update release notes to reflect new compression format

**Recommendation**: Use `pigz` for maximum speed (70% compression in ~2 min)

---

### 3. Early Image Deduplication
**Estimated Savings**: 1-2 minutes during export  
**Complexity**: Low

Current: Deduplication happens during export-image (20-24MB saved)

**Implementation**:
```bash
# Run zerofree earlier in build process (after each stage)
# In build-image.sh, add after each stage:
if [ -f "${STAGE_DIR}/EXPORT_IMAGE" ]; then
    log_event "🔧" "Running early deduplication..."
    zerofree -v "${ROOT_PARTITION}"
fi
```

**Files to modify**:
- `scripts/build-image.sh` (add zerofree after stage2, stage3)

**Impact**: Smaller intermediate images, faster final export

---

### 4. Disk Space Monitoring & Alerts
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

### 5. Build Time Breakdown Metrics
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

### 6. Multiple Checksum Formats
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

### 7. Stage-Specific APT Cache
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

### 8. Incremental Build Support
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

### 9. Parallel Stage Execution
**Estimated Savings**: 10-15 minutes  
**Complexity**: Very High

Some stages could run in parallel if dependencies allow.

**Challenges**:
- Stage dependencies are complex
- pi-gen not designed for parallel execution
- High risk of build failures

---

### 10. Local Build Cache Server
**Estimated Savings**: 2-3 minutes  
**Complexity**: High

Set up apt-cacher-ng or similar for package caching across builds.

**Requirements**:
- Persistent cache server
- Network configuration
- Additional infrastructure

---

## Recommended Implementation Order

1. **Faster Compression** (Low complexity, high impact: 8-10 min)
2. **Parallel Package Installation** (Medium complexity, medium impact: 2-3 min)
3. **Disk Space Monitoring** (Low complexity, prevents failures)
4. **Build Time Breakdown** (Low complexity, improves visibility)
5. **Early Deduplication** (Low complexity, small impact: 1-2 min)
6. **Multiple Checksums** (Low complexity, security improvement)

**Total Potential Savings**: 11-15 additional minutes (on top of 12-13 min already saved)

**Final Target**: 61 min → 35-38 min (40% faster builds)

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

- Current build time: ~61 minutes (v0.9.7.3)
- Target build time: <40 minutes
- Image size: 2.8GB uncompressed, 857MB compressed
- Disk usage: 50GB → 64GB (89% peak)

---

**Last Updated**: October 25, 2025  
**Version**: Post-v0.9.7.4 optimizations  
**Next Review**: After implementing items 1-3
