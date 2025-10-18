# GitHub Actions Workflow - TODO List
**Created:** October 18, 2025  
**Status:** In Progress

---

## 🔴 CRITICAL PRIORITY (P0) - Must Fix Immediately

- [x] **TODO-001**: Fix cache paths - Currently caching `/opt/pi-gen/work` instead of `build/pi-gen-work`
  - **Location:** Line 72-82, `.github/workflows/build-release.yml`
  - **Impact:** Cache never works, wastes 30-40 min per build
  - **Fix:** Change paths to `build/pi-gen-work/work` and `build/pi-gen-work/deploy`
  - **Status:** ✅ COMPLETE - Also improved cache key to include build/** and assets/**

- [x] **TODO-002**: Add git pull before README push
  - **Location:** Line 422, `.github/workflows/build-release.yml`
  - **Impact:** Will fail on second release when logs already pushed
  - **Fix:** Add `git pull --rebase origin main` before `git push`
  - **Status:** ✅ COMPLETE - Added with fallback to merge and force-with-lease

- [x] **TODO-003**: Add git pull before log push (successful builds)
  - **Location:** Line 214-221, `.github/workflows/build-release.yml`
  - **Impact:** Race condition if concurrent builds
  - **Fix:** Add `git pull --rebase origin main` before push
  - **Status:** ✅ COMPLETE - Added proper error handling

- [x] **TODO-004**: Fix stat command syntax (first instance)
  - **Location:** Line 198, `.github/workflows/build-release.yml`
  - **Impact:** Always uses fallback, inefficient
  - **Fix:** Use `stat -c%s` (Linux syntax) instead of `stat -f%z` (macOS)
  - **Status:** ✅ COMPLETE

---

## 🟠 HIGH PRIORITY (P1) - Fix Soon

- [x] **TODO-005**: Improve permission handling after build
  - **Location:** Line 108, `.github/workflows/build-release.yml`
  - **Impact:** Log file may be unreadable if build fails early
  - **Fix:** Change entire directory ownership, add error handling
  - **Status:** ✅ COMPLETE - Now changes entire directory with error handling

- [x] **TODO-006**: Fix deploy directory permission handling
  - **Location:** Line 252, `.github/workflows/build-release.yml`
  - **Impact:** Silent failure if chown fails
  - **Fix:** Add error handling: `|| exit 1`
  - **Status:** ✅ COMPLETE

- [x] **TODO-007**: Fix image file finding logic
  - **Location:** Line 260, `.github/workflows/build-release.yml`
  - **Impact:** Fails if directory names have spaces
  - **Fix:** Use `find` instead of unquoted glob pattern
  - **Status:** ✅ COMPLETE - Now uses find with proper quoting

- [x] **TODO-008**: Improve failed build log push
  - **Location:** Line 427-438, `.github/workflows/build-release.yml`
  - **Impact:** Silent failures, no way to know if push succeeded
  - **Fix:** Add proper error handling, check if commits exist
  - **Status:** ✅ COMPLETE - Added commit checking and proper error handling

---

## 🟡 MEDIUM PRIORITY (P2) - Important Improvements

- [x] **TODO-009**: Fix stat command syntax (second instance)
  - **Location:** Line 467, `.github/workflows/build-release.yml`
  - **Impact:** Same as TODO-004
  - **Fix:** Use `stat -c%s` for Linux
  - **Status:** ✅ COMPLETE

- [x] **TODO-010**: Add default value for BUILD_EXIT_CODE
  - **Location:** Line 103, `.github/workflows/build-release.yml`
  - **Impact:** Variable may be empty if step fails early
  - **Fix:** Add `BUILD_EXIT_CODE="${BUILD_EXIT_CODE:-1}"`
  - **Status:** ✅ COMPLETE

- [x] **TODO-011**: Fix README update logic
  - **Location:** Line 388-410, `.github/workflows/build-release.yml`
  - **Impact:** Only adds section once, never updates for new versions
  - **Fix:** Replace section instead of checking existence
  - **Status:** ✅ COMPLETE - Now properly replaces section

- [x] **TODO-012**: Improve cache key specificity
  - **Location:** Line 77, `.github/workflows/build-release.yml`
  - **Impact:** Cache doesn't invalidate when custom stages change
  - **Fix:** Include `build/**` and `assets/**` in hash
  - **Status:** ✅ COMPLETE - Fixed as part of TODO-001

---

## 🟢 LOW PRIORITY (P3) - Nice to Have

- [x] **TODO-013**: Add step-specific timeouts
  - **Location:** Build step, `.github/workflows/build-release.yml`
  - **Impact:** Entire job times out if one step hangs
  - **Fix:** Add `timeout-minutes: 90` to build step
  - **Status:** ✅ COMPLETE

- [x] **TODO-014**: Improve error message accuracy
  - **Location:** Line 118, `.github/workflows/build-release.yml`
  - **Impact:** Says "log will be uploaded" even if it doesn't exist
  - **Fix:** Add conditional message based on file existence
  - **Status:** ✅ COMPLETE

- [x] **TODO-015**: Document required environment variables
  - **Location:** Line 102, `.github/workflows/build-release.yml`
  - **Impact:** `sudo -E` preserves all vars, some might cause issues
  - **Fix:** Add comment documenting which vars are needed
  - **Status:** ✅ COMPLETE

---

## 📊 PROGRESS TRACKER

**Total Issues:** 15
- **P0 (Critical):** 4 issues
- **P1 (High):** 4 issues  
- **P2 (Medium):** 4 issues
- **P3 (Low):** 3 issues

**Completed:** 15/15 (100%) ✅
**In Progress:** 0/15
**Remaining:** 0/15

---

## 🎯 COMPLETION CHECKLIST

- [x] All P0 issues fixed ✅
- [x] All P1 issues fixed ✅
- [x] All P2 issues fixed ✅
- [x] All P3 issues fixed ✅
- [ ] Changes tested (will test in next build)
- [x] Documentation updated ✅
- [ ] Committed and pushed (in progress)

---

## 📝 SUMMARY OF CHANGES

### Critical Fixes (P0):
1. Fixed cache paths - Now caches correct directory, saves 30-40 min per build
2. Added git pull before README push - Prevents conflicts on subsequent releases
3. Added git pull before log push - Handles concurrent builds properly
4. Fixed stat command syntax - Uses Linux-compatible command

### High Priority Fixes (P1):
5. Improved permission handling - Changes entire directory ownership with error handling
6. Fixed deploy directory permissions - Added error handling for chown failures
7. Fixed image file finding - Uses find command with proper quoting
8. Improved failed build log push - Checks for commits, proper error handling

### Medium Priority Fixes (P2):
9. Fixed second stat command - Consistent Linux syntax
10. Added default BUILD_EXIT_CODE - Prevents empty variable issues
11. Fixed README update logic - Now actually updates section for new releases
12. Improved cache key - Includes build/** and assets/** for better invalidation

### Low Priority Fixes (P3):
13. Added build step timeout - 90-minute limit prevents hanging
14. Improved error messages - Accurate based on actual file existence
15. Documented environment variables - Clear comment about sudo -E requirements

---

**Last Updated:** October 18, 2025 - ALL ISSUES FIXED ✅
