# Build & Development Troubleshooting Guide

This guide helps developers diagnose and fix issues when building, customizing, or developing the Raspberry Pi HDMI Tester image.

**Audience**: Developers building the image in GitHub Codespaces or GitHub Actions

**For end-user issues**: See [User Troubleshooting Guide](TROUBLESHOOTING-USER.md)

## Table of Contents
- [Using Build Logs for Debugging](#using-build-logs-for-debugging)
- [GitHub Codespaces Build Problems](#github-codespaces-build-problems)
- [GitHub Actions Build Problems](#github-actions-build-problems)
- [Image Build Failures](#image-build-failures)
- [Customization Issues](#customization-issues)
- [Testing & Validation Issues](#testing--validation-issues)

---

## Using Build Logs for Debugging

The build system generates comprehensive logs that capture everything for debugging. **Always check the logs first when troubleshooting build issues.**

### Accessing Logs

#### During Build (Codespaces/Local)
The detailed log is created at:
```bash
build/pi-gen-work/build-detailed.log
```

View it in real-time:
```bash
# In another terminal while build is running
tail -f build/pi-gen-work/build-detailed.log
```

#### After Build (Repository)
Logs are automatically committed to the repository:
```bash
# Successful builds
logs/successful-builds/build-YYYY-MM-DD_HH-MM-SS_vX.X.X.log

# Failed builds
logs/failed-builds/build-YYYY-MM-DD_HH-MM-SS_FAILED.log
```

#### GitHub Actions (Cloud Builds)
Logs are available two ways:
1. **Artifacts**: Download from workflow run (retained 90 days)
   - Go to Actions → Select workflow run → Download "build-logs-..." artifact
2. **Repository**: Automatically committed to `logs/` directory

### Analyzing Logs

#### Quick Analysis
Use the analyze script to extract key information:
```bash
./scripts/analyze-logs.sh build/pi-gen-work/build-detailed.log
```

This shows:
- Build status and duration
- Error count and details
- Stage timings
- Disk space progression
- Memory usage
- File checksums
- Recommendations

#### Comparing Builds
Compare a failed build with a successful one:
```bash
./scripts/compare-logs.sh \
  logs/successful-builds/build-2025-10-17_14-30-45_v1.0.0.log \
  logs/failed-builds/build-2025-10-17_15-22-10_FAILED.log
```

This highlights:
- Metadata differences (commits, environment)
- Error differences
- Timing differences
- Resource usage differences
- Unique errors in each build

#### Manual Search
Search for specific issues:
```bash
# Find all errors
grep -i "error" build/pi-gen-work/build-detailed.log

# Find disk space issues
grep -i "no space left\|disk full" build/pi-gen-work/build-detailed.log

# Find memory issues
grep -i "out of memory\|cannot allocate" build/pi-gen-work/build-detailed.log

# Find network issues
grep -i "failed to fetch\|404\|connection" build/pi-gen-work/build-detailed.log

# View specific stage
grep -A 50 "STAGE: Asset Validation" build/pi-gen-work/build-detailed.log
```

### What the Log Contains

The detailed log includes:

1. **Build Environment**
   - System info (OS, kernel, architecture)
   - CPU and memory specs
   - Disk space availability
   - Tool versions (qemu, git, debootstrap, etc.)
   - Environment variables

2. **Build Configuration**
   - pi-gen config file contents
   - Custom stage configuration
   - Asset locations and checksums

3. **Stage-by-Stage Output**
   - Each stage has its own section
   - Timestamps for start/end
   - Duration for each stage
   - All command output
   - Resource usage checkpoints

4. **Asset Validation**
   - Test pattern image (size, dimensions, checksum)
   - Audio file (size, format, checksum)
   - File integrity verification

5. **Error Context**
   - When errors occur, surrounding log lines are captured
   - Full error messages with stack traces
   - Failed command details

6. **Build Summary**
   - Total duration
   - Success or failure status
   - Final system state (disk, memory)
   - Output file locations and sizes

### Common Log Patterns

#### Build Succeeded
```
Status: ✅ SUCCESS
Total Duration: 00:45:23 (2723s)
```

#### Build Failed
```
Status: ❌ FAILED
Error: pi-gen build.sh failed with exit code 1
```

#### Disk Space Issue
```
ERROR: No space left on device
Disk Usage at: After pi-gen Build
Filesystem      Size  Used Avail Use%
/dev/sda1        32G   32G    0G 100%
```

#### Memory Issue
```
ERROR: Cannot allocate memory
Memory Usage at: Before pi-gen Build
              total        used        free
Mem:          4.0Gi       3.9Gi       100Mi
```

#### Network/Package Issue
```
ERROR: Failed to fetch http://archive.raspberrypi.org/...
E: Unable to fetch some archives
```

### Debugging Workflow

When a build fails:

1. **Check the build log immediately**
   ```bash
   ./scripts/analyze-logs.sh build/pi-gen-work/build-detailed.log
   ```

2. **Review the error summary**
   - Look at error count and types
   - Check recommendations section

3. **Find the error context**
   - The log shows surrounding lines for each error
   - Search for "ERROR CONTEXT" section

4. **Check resource usage**
   - Was disk space running low?
   - Was memory exhausted?
   - Review checkpoints throughout build

5. **Compare with previous successful build**
   ```bash
   # Find your last successful build
   ls -t logs/successful-builds/ | head -n 1

   # Compare
   ./scripts/compare-logs.sh \
     logs/successful-builds/<successful>.log \
     logs/failed-builds/<failed>.log
   ```

6. **Look for patterns**
   - Same error every time? = Configuration issue
   - Random failures? = Resource or network issue
   - New error after code change? = Code issue

---

## GitHub Codespaces Build Problems

### Codespaces Won't Start

**Symptoms**: Codespace fails to create or times out

**Solutions**:
1. **Check GitHub status**: https://www.githubstatus.com/
2. **Try creating a new Codespace**:
   - Delete the current Codespace
   - Create a fresh one from the repository
3. **Check your GitHub plan**:
   - Free tier has monthly hour limits
   - May need to wait until next billing cycle

### Build Fails: "qemu-arm-static not found"

**Symptoms**: Build stops with error about missing qemu-arm-static

**Cause**: Container didn't initialize properly

**Solutions**:
```bash
# Rebuild the Codespaces container:
# 1. Open Command Palette (Ctrl+Shift+P or F1)
# 2. Type "Codespaces: Rebuild Container"
# 3. Wait for rebuild to complete (2-3 minutes)
# 4. Try the build again
```

### Build Fails: "Permission denied"

**Symptoms**: Cannot create directories or files during build

**Cause**: sudo permissions issue (should not happen in Codespaces)

**Solutions**:
```bash
# In Codespaces, you have passwordless sudo
# Verify sudo works:
sudo -v

# Check ownership of build directory
ls -la build/

# Fix permissions if needed
sudo chown -R $USER:$USER build/
```

### Build Fails: "No space left on device"

**Symptoms**: Build stops with disk space error

**Cause**: 32GB Codespaces storage is full

**Solutions**:
```bash
# Check available space
df -h

# Clean old builds
sudo rm -rf build/pi-gen-work

# Check large files
du -sh build/* | sort -h

# After cleanup, check space again
df -h
```

### Build Takes Forever (> 2 hours)

**Normal time in Codespaces**: 45-60 minutes for first build

**Possible Causes**:
- Slow internet connection in Codespaces datacenter
- GitHub throttling during high usage
- Codespace is using 2-core machine (standard free tier)

**Solutions**:
```bash
# Check internet speed in Codespaces
curl -o /dev/null http://speedtest.tele2.net/10MB.zip

# Check RAM usage
free -h

# Monitor build progress
tail -f build/pi-gen-work/build-detailed.log

# Be patient - first build downloads many packages
# Subsequent builds will be faster (30-45 minutes)
```

### Build Succeeds But validate-image.sh Fails

**Symptoms**: Image built but validation reports missing files

**Solutions**:
```bash
# Check build log for errors
less build/pi-gen-work/build-detailed.log

# Look for failed stages
grep -i "error\|fail" build/pi-gen-work/build-detailed.log

# Try clean rebuild in Codespaces
sudo rm -rf build/pi-gen-work
./scripts/build-image.sh
```

### Can't Download Built Image from Codespaces

**Symptoms**: Download fails or times out

**Solutions**:
1. **Download the .zip file** instead of .img (smaller, faster)
   - Navigate to `build/pi-gen-work/deploy/`
   - Right-click `RaspberryPi_HDMI_Tester.img.zip`
   - Select "Download"

2. **Split large files** (if >2GB):
   ```bash
   # In Codespaces, split the image
   split -b 500M build/pi-gen-work/deploy/RaspberryPi_HDMI_Tester.img image_part_

   # Download each part separately
   # Rejoin on Windows 11: copy /b image_part_* complete_image.img
   ```

3. **Use GitHub CLI to upload to release**:
   ```bash
   # Create a release and upload image
   gh release create v1.0 build/pi-gen-work/deploy/*.img.zip
   ```

---

## GitHub Actions Build Problems

### GitHub Actions Workflow Fails

**Symptoms**: Build fails in GitHub Actions but works in Codespaces

**Common Causes**:
1. **Runner out of disk space**
2. **Network/download issues**
3. **Timeout (6-hour limit)**

**Solutions**:

1. **Check the workflow logs**:
   - Go to Actions tab
   - Click on the failed run
   - Expand the build step
   - Look for error messages

2. **Download and analyze the build log artifact**:
   - Scroll to bottom of workflow run
   - Download "build-logs-..." artifact
   - Extract and analyze the log file

3. **Check disk space in workflow**:
   - Look for "No space left on device" errors
   - Actions runners have limited disk space
   - Clean up unnecessary files in workflow

4. **Retry the workflow**:
   - Sometimes network issues are transient
   - Click "Re-run jobs" in the Actions tab

### Artifact Upload Fails

**Symptoms**: Build succeeds but artifact upload fails

**Solutions**:
1. **Check artifact size**:
   - GitHub has size limits (individual: 2GB, total: 10GB)
   - Compress images before upload

2. **Check GitHub status**:
   - https://www.githubstatus.com/
   - Artifact service may be down

3. **Use release upload instead**:
   - For large images, use GitHub Releases
   - Modify workflow to use `gh release create`

### Workflow Timeout

**Symptoms**: Build times out after 6 hours

**Causes**:
- Very slow network
- Runner performance issues
- Infinite loop in custom scripts

**Solutions**:
1. **Check build log for stuck stages**
2. **Optimize custom stages**:
   - Remove unnecessary package installations
   - Reduce asset sizes
   - Cache dependencies

---

## Image Build Failures

### pi-gen Build Fails: Stage 0/1/2

**Symptoms**: Build fails in early pi-gen stages

**Cause**: Core pi-gen issues, not customization

**Solutions**:
1. **Update pi-gen**:
   ```bash
   cd /opt/pi-gen
   sudo git pull
   ```

2. **Check Debian mirror availability**:
   ```bash
   curl -I http://deb.debian.org/debian/
   ```

3. **Check for known pi-gen issues**:
   - https://github.com/RPi-Distro/pi-gen/issues

### pi-gen Build Fails: Stage 3 (Custom Stage)

**Symptoms**: Build fails in your custom stage

**Cause**: Error in custom scripts or configuration

**Solutions**:

1. **Check which custom stage failed**:
   ```bash
   grep -i "error" build/pi-gen-work/build-detailed.log | grep "stage3"
   ```

2. **Common issues**:

   **Missing files**:
   ```bash
   # Make sure all files referenced in scripts exist
   ls -la build/stage3/*/files/
   ```

   **Script syntax errors**:
   ```bash
   # Check bash syntax
   bash -n build/stage3/*/00-run.sh
   bash -n build/stage3/*/00-run-chroot.sh
   ```

   **Missing packages**:
   ```bash
   # Verify package names
   cat build/stage3/00-install-packages/00-packages
   # Search Debian package database if unsure
   apt-cache search <package-name>
   ```

   **Permission issues**:
   ```bash
   # Ensure scripts are executable
   chmod +x build/stage3/*/00-run*.sh
   ```

3. **Test individual stage scripts**:
   ```bash
   # Run the script manually to see errors
   bash -x build/stage3/01-test-image/00-run.sh
   ```

### Asset Files Missing or Corrupt

**Symptoms**: Build complains about missing image.png or audio.mp3

**Solutions**:
```bash
# Verify assets exist
ls -lh assets/

# Check file integrity
file assets/image.png
file assets/audio.mp3

# Verify checksums
./scripts/generate-checksums.sh
```

### QEMU Errors During Build

**Symptoms**: Errors like "qemu: uncaught target signal" or chroot failures

**Solutions**:
1. **Verify QEMU is installed**:
   ```bash
   which qemu-arm-static
   ls -l /usr/bin/qemu-arm-static
   ```

2. **Check binfmt registration**:
   ```bash
   cat /proc/sys/fs/binfmt_misc/qemu-arm
   ```

3. **Restart binfmt**:
   ```bash
   sudo systemctl restart systemd-binfmt.service
   ```

---

## Customization Issues

### Added Package Won't Install

**Symptoms**: Package installation fails in custom stage

**Solutions**:

1. **Verify package name**:
   ```bash
   # Search for correct package name
   apt-cache search <package-name>
   ```

2. **Check package availability in Debian bookworm**:
   - https://packages.debian.org/bookworm/

3. **Check for dependency issues**:
   ```bash
   # Try installing locally first
   apt-cache show <package-name>
   apt-cache depends <package-name>
   ```

### Custom Script Not Running

**Symptoms**: Script exists but doesn't execute during build

**Causes**:
- Wrong filename (must be `XX-run.sh` or `XX-run-chroot.sh`)
- Not executable
- Wrong location in stage directory

**Solutions**:
```bash
# Check naming convention
ls build/stage3/*/

# Scripts must be named: 00-run.sh, 01-run.sh, 00-run-chroot.sh, etc.
# Make executable
chmod +x build/stage3/*/00-run*.sh

# Verify stage structure
tree build/stage3/
```

### Files Not Being Copied to Image

**Symptoms**: Files in `files/` subdirectory not appearing in final image

**Causes**:
- `install` command syntax error
- Wrong ROOTFS_DIR path
- Files in wrong location

**Solutions**:
```bash
# Check install command syntax
# Correct: install -m 644 files/myfile.txt "${ROOTFS_DIR}/destination/"
# Wrong: install files/myfile.txt "${ROOTFS_DIR}/destination"

# Verify files exist before install
ls -la build/stage3/*/files/

# Test install command manually
install -d /tmp/test
install -m 644 assets/image.png /tmp/test/
ls -la /tmp/test/
```

### Service Not Starting on Boot

**Symptoms**: systemd service exists but doesn't run

**Solutions**:

1. **Verify service file syntax**:
   ```bash
   # Check for syntax errors
   systemd-analyze verify build/stage3/03-autostart/files/*.service
   ```

2. **Check service is enabled**:
   ```bash
   # Look in your 00-run.sh script
   grep "systemctl enable" build/stage3/03-autostart/00-run.sh
   ```

3. **Verify WantedBy target exists**:
   ```ini
   # In service file
   [Install]
   WantedBy=graphical.target  # For display services
   WantedBy=multi-user.target # For most other services
   ```

4. **Check service dependencies**:
   ```ini
   # Ensure dependent services start first
   [Unit]
   After=graphical.target
   Wants=sound.target
   ```

---

## Testing & Validation Issues

### QEMU Test Fails

**Symptoms**: `./tests/qemu-test.sh` fails or hangs

**Solutions**:

1. **Check QEMU installation**:
   ```bash
   which qemu-system-arm
   qemu-system-arm --version
   ```

2. **Increase timeout**:
   ```bash
   # Edit qemu-test.sh, increase timeout value
   TIMEOUT=300  # 5 minutes
   ```

3. **Check kernel/DTB files**:
   ```bash
   # Verify they were extracted
   ls -lh build/qemu-testing/
   ```

4. **Run with verbose output**:
   ```bash
   bash -x ./tests/qemu-test.sh
   ```

### Validation Script Reports Errors

**Symptoms**: `./tests/validate-image.sh` fails even though image boots

**Causes**:
- Expected files moved to different locations
- Validation script out of date

**Solutions**:

1. **Check what's actually failing**:
   ```bash
   ./tests/validate-image.sh | grep "FAIL"
   ```

2. **Mount image and check manually**:
   ```bash
   # This requires loop device support
   sudo kpartx -av build/pi-gen-work/deploy/*.img
   sudo mount /dev/mapper/loop0p2 /mnt
   ls -la /mnt/opt/hdmi-tester/
   sudo umount /mnt
   sudo kpartx -dv build/pi-gen-work/deploy/*.img
   ```

3. **Update validation script** if file locations changed

---

## Performance Optimization

### Build Takes Too Long

**Normal times**:
- First build: 45-60 minutes
- Subsequent builds: 30-45 minutes

**If significantly slower**:

1. **Check disk I/O**:
   ```bash
   # During build
   iostat -x 5
   ```

2. **Check network speed**:
   ```bash
   curl -o /dev/null http://speedtest.tele2.net/100MB.zip
   ```

3. **Reduce unnecessary packages**:
   - Review `00-packages` files
   - Remove unused packages

4. **Use caching**:
   - pi-gen caches packages in `build/pi-gen-work/`
   - Don't delete this unless necessary

### Image Size Too Large

**Target size**: 1.5-2GB compressed

**If image is too large**:

1. **Check what's taking space**:
   ```bash
   # Mount image and check sizes
   sudo kpartx -av build/pi-gen-work/deploy/*.img
   sudo mount /dev/mapper/loop0p2 /mnt
   sudo du -sh /mnt/*
   sudo umount /mnt
   sudo kpartx -dv build/pi-gen-work/deploy/*.img
   ```

2. **Enable image reduction**:
   ```bash
   # In build/config
   ENABLE_REDUCE_DISK_USAGE=1
   ```

3. **Remove unnecessary files in stages**:
   ```bash
   # In 00-run-chroot.sh
   apt-get clean
   rm -rf /var/lib/apt/lists/*
   rm -rf /usr/share/doc/*
   rm -rf /usr/share/man/*
   ```

---

## Getting Help

### Reporting Build Issues

When reporting build issues on GitHub, include:

1. **Build environment**:
   - Codespaces or GitHub Actions?
   - First time or previously worked?

2. **Build log**:
   - Attach `build-detailed.log` from `logs/failed-builds/`
   - Or run analyze script and include output

3. **What changed**:
   - Recent commits
   - Configuration changes
   - New custom stages

4. **Steps to reproduce**:
   ```bash
   # Example
   1. Clone repository
   2. Open in Codespaces
   3. Run ./scripts/build-image.sh
   4. Build fails at stage3/01-test-image
   ```

### Useful Debug Commands

```bash
# Check pi-gen version
cd /opt/pi-gen && git log --oneline -1

# Check available disk space during build
watch -n 5 df -h

# Monitor build progress
tail -f build/pi-gen-work/build-detailed.log | grep "STAGE:"

# Check for errors in real-time
tail -f build/pi-gen-work/build-detailed.log | grep -i "error\|fail"

# List all installed packages in image (after mount)
sudo chroot /mnt dpkg -l
```

### Resources

- **pi-gen Documentation**: https://github.com/RPi-Distro/pi-gen
- **Debian Packages**: https://packages.debian.org/
- **Raspberry Pi Forums**: https://forums.raspberrypi.com/
- **Project Issues**: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues

---

## Common Error Messages & Solutions

| Error Message | Cause | Solution |
|--------------|-------|----------|
| `qemu-arm-static: not found` | QEMU not installed | Rebuild container |
| `No space left on device` | Disk full | Clean old builds, check df -h |
| `Failed to fetch` | Network issue | Retry build, check mirror |
| `Package not found` | Wrong package name | Check packages.debian.org |
| `Permission denied` | Missing sudo/permissions | Check file permissions |
| `command not found` | Tool not installed | Install in 00-packages |
| `systemd service failed` | Service misconfigured | Check service syntax |
| `chroot: failed to run` | QEMU issue | Restart binfmt |

---

**Still having problems?** Open an issue with your build log:
https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
