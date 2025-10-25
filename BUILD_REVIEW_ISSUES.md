# Build Process Review - Potential Issues

**Review Date**: October 25, 2025
**Reviewer**: AI Analysis
**Status**: Pending Validation

This document contains all potential issues, oddities, duplicates, and unused components identified during a comprehensive review of the build process.

---

##  LOW PRIORITY / INFORMATIONAL

### 10. Test images (PNG files) deployed but only image.png is actively used
- **Location**: `build/stage3/01-test-image/files/` contains: black.png, blue.png, green.png, red.png, white.png, image.png
- **Issue**: 6 PNG files deployed, but only `image-test` script uses them (image.png used by test-notvideo)
- **Impact**: Each PNG ~50-200KB, total ~600KB for rarely-used test pattern rotation
- **Note**: These ARE used by `image-test` script but that service is disabled by default
- **Status**: ❓ PENDING VALIDATION

### 11. Two video formats supported but build only validates one
- **Location**: Scripts auto-detect Pi model to choose WebM (Pi 4+) vs MP4 (Pi 3)
- **Issue**: WebM validated during build, MP4 assumed to work
- **Impact**: Pi 3 users might get untested MP4 files
- **Evidence**: `scripts/build-image.sh` doesn't validate MP4 codec compatibility
- **Status**: ❓ PENDING VALIDATION

### 12. Memory limit syntax deprecation warning
- **Location**: All service files use `MemoryLimit=512M`
- **Issue**: `MemoryLimit=` is deprecated in favor of `MemoryMax=`
- **Impact**: Works but generates systemd warnings in logs
- **Fix**: Replace `MemoryLimit=` with `MemoryMax=` in all .service files
- **Status**: ❓ PENDING VALIDATION

### 13. GitHub Actions workflow duplicates image search logic
- **Location**: `.github/workflows/build-release.yml`
- **Issue**: Lines 649-668 (validation) and lines 760+ (QEMU test) have nearly identical image file search code
- **Suggestion**: Extract to reusable step or bash function
- **Status**: ❓ PENDING VALIDATION

### 14. Build cleanup happens AFTER image validation
- **Location**: `scripts/build-image.sh` lines 562-599 (cleanup) vs lines 502-530 (validation)
- **Issue**: Cleanup removes intermediate files that might be useful for debugging validation failures
- **Suggestion**: Move cleanup to end of script (after all validation)
- **Status**: ❓ PENDING VALIDATION

### 15. FLAC files in wrong directory
- **Location**: FLAC files in `assets/` AND `build/stage3/02-audio-test/files/`
- **Issue**: Duplicated storage - both locations contain stereo.flac and surround51.flac
- **Impact**: ~40MB duplicated (20MB each file x2 copies)
- **Note**: Build uses files from `build/stage3/02-audio-test/files/`, assets/ copy seems unused
- **Status**: ❓ PENDING VALIDATION

---

## 🤔 UNCLEAR / NEEDS CLARIFICATION

### 16. What is the purpose of arm_freq=1000 in config.txt?
- **Location**: `build/stage3/04-boot-config/00-run.sh` appends `arm_freq=1000`
- **Issue**: Called "conservative overclock" but 1000MHz is actually **UNDERCLOCK** for Pi 4 (default 1500MHz)
- **Question**: Is this intentional for stability or an error?
- **Status**: ❓ PENDING VALIDATION

### 17. Why are services disabled by default?
- **Location**: `build/stage3/03-autostart/00-run.sh` line 128
- **Issue**: Comment says "intentionally NOT enabled for manual testing phase"
- **Question**: Is this temporary or permanent design decision? Makes "auto-start" stage name misleading
- **Status**: ❓ PENDING VALIDATION

### 18. tune2fs deferred to first boot - will it actually run?
- **Location**: `build/stage3/04-boot-config/00-run-chroot.sh` creates `tune-filesystem.service`
- **Issue**: Service runs once on first boot to optimize filesystem
- **Question**: Has this been tested? Does the service actually trigger?
- **Impact**: If it fails silently, filesystem optimizations never applied
- **Status**: ❓ PENDING VALIDATION

### 19. Multiple logging locations
- **Issue**: Scripts log to different locations:
  - Build: `build/pi-gen-work/build-detailed.log`
  - Runtime tests: `/tmp/hdmi-test.log`, `/tmp/pixel-test.log`, etc.
  - Archived: `logs/build-TIMESTAMP.log`
- **Question**: Is this intentional organization or historical artifact?
- **Status**: ❓ PENDING VALIDATION

### 20. Stage2 packages removal list may be overly aggressive
- **Location**: `build/stage2/01-sys-tweaks/00-packages-nr`
- **Issue**: Removes 40+ packages including some that might be useful (htop, rsync, man-db)
- **Question**: Has this been tested to ensure nothing breaks? Some removed packages might be dependencies
- **Status**: ❓ PENDING VALIDATION

---

## 📦 POTENTIAL OPTIMIZATIONS

### 21. Image file duplication in assets/
- **Files in assets/**: All test videos, images, audio exist there AND in build/stage3/
- **Impact**: ~50MB duplicated data in repository
- **Suggestion**: Keep files ONLY in build/stage3/{01,02}-*/files/, remove from assets/
- **Status**: ❓ PENDING VALIDATION

### 22. Both WebM and MP4 formats increase image size
- **Impact**: Each video format pair ~2.5MB, both formats = ~5MB total
- **Question**: Could we include ONLY WebM and convert to MP4 at runtime for Pi 3? (Saves ~2.5MB)
- **Status**: ❓ PENDING VALIDATION

### 23. Validation script creates large log files
- **Location**: Test scripts use verbose VLC output (`-vv`)
- **Impact**: Log files can grow to 10MB+ during extended testing
- **Suggestion**: Add log rotation or size limits
- **Status**: ❓ PENDING VALIDATION

---

## 📋 SUMMARY BY CATEGORY

| Category | Count | Pending |
|----------|-------|---------|
| LOW (informational) | 6 | 6 |
| UNCLEAR (needs clarification) | 5 | 5 |
| OPTIMIZATIONS (optional) | 3 | 3 |

**TOTAL ISSUES REMAINING: 14**
**ALL PENDING VALIDATION** (low priority optimizations and clarifications)

---

## 🔄 VALIDATION WORKFLOW

For each issue above:
1. Review the issue description
2. Determine status:
   - ✅ **VALID ISSUE** - Needs fixing
   - ❌ **NOT AN ISSUE** - Working as intended, document why
   - ⏸️ **DEFERRED** - Valid but low priority, postpone
3. Update the status emoji in the issue

---

## 📝 NOTES

- This review was automated - human validation required
- Some "issues" may be intentional design decisions that need documentation
- Priority levels are suggestions, adjust based on project needs
- Review date: October 25, 2025
- **Last updated**: October 25, 2025 - Removed all completed fixes (8 total)
- **All critical and high-priority issues have been resolved**
- **Remaining 14 issues are low-priority optimizations and clarifications**
