# Release Assets Documentation

This document describes all files included in each GitHub Release of the Raspberry Pi HDMI Tester.

## Release Assets (4 files total)

Every release includes the following files:

### 1. **RaspberryPi_HDMI_Tester_vX.X.X.img.zip**
📦 **The Main Image File** (~900MB compressed, ~2.3GB uncompressed)

- Compressed Raspberry Pi OS image
- Ready to flash to SD card (4GB minimum)
- Contains all pre-configured software and services
- Flash with Raspberry Pi Imager or similar tool

**Usage:**
1. Extract the .img file from the ZIP
2. Flash to SD card using Raspberry Pi Imager
3. Insert SD card into Raspberry Pi
4. Power on and it boots automatically

---

### 2. **RaspberryPi_HDMI_Tester_vX.X.X.sha256**
🔐 **SHA-256 Checksum File** (~200 bytes)

- Contains cryptographic hashes for verification
- Checksums for both the image ZIP and testing report
- Use to verify download integrity

**Contents:**
```
# SHA-256 Checksums for Raspberry Pi HDMI Tester vX.X.X
#
# Verify downloads with:
#   sha256sum -c RaspberryPi_HDMI_Tester_vX.X.X.sha256
#
# Or verify individual files:
#   sha256sum RaspberryPi_HDMI_Tester_vX.X.X.img.zip
#   (compare output with hash below)
#

<hash>  RaspberryPi_HDMI_Tester_vX.X.X.img.zip
<hash>  TESTING_REPORT_vX.X.X.md
```

**Verification Commands:**

**Automatic (Linux/macOS):**
```bash
sha256sum -c RaspberryPi_HDMI_Tester_vX.X.X.sha256
```

**Manual (Linux/macOS):**
```bash
sha256sum RaspberryPi_HDMI_Tester_vX.X.X.img.zip
```

**Manual (Windows PowerShell):**
```powershell
Get-FileHash RaspberryPi_HDMI_Tester_vX.X.X.img.zip -Algorithm SHA256
```

---

### 3. **TESTING_REPORT_vX.X.X.md**
📊 **Comprehensive Testing & Validation Report** (~15-20KB)

- Detailed test results from automated CI/CD pipeline
- Proof of image reliability and quality assurance
- Static image validation results
- QEMU boot test results (with limitations noted)
- Build reproducibility certification
- Security attestation

**Contents Include:**
- ✅ Build verification status
- ✅ File system validation (all files and services present)
- ✅ HDMI configuration verification (1920x1080@60Hz)
- ✅ Package installation verification
- ✅ Service enablement verification
- ⚠️ QEMU boot test results (informational only)
- 📋 Hardware compatibility list
- 🔐 Build reproducibility information
- 🛡️ Security certification

**Purpose:**
- Demonstrates quality assurance process
- Provides transparency into testing methodology
- Offers confidence in image reliability
- Documents known limitations (QEMU can't test HDMI/audio)

---

### 4. **VERIFY_DOWNLOAD_vX.X.X.txt**
📖 **Download Verification Instructions** (~3KB)

- Step-by-step guide for verifying downloads
- Platform-specific instructions (Linux, macOS, Windows)
- Explains why verification is important
- Troubleshooting tips for failed verification

**Sections:**
1. **Method 1:** Automatic Verification (Linux/macOS)
2. **Method 2:** Manual Verification (All Platforms)
3. **Method 3:** Raspberry Pi Imager (Auto-verification)
4. **Why Verify?** - Explanation of security benefits
5. **Troubleshooting** - Common issues and solutions

**Target Audience:**
- First-time users unfamiliar with checksums
- Users who want to ensure download integrity
- Anyone concerned about file authenticity

---

## Quick Start Guide

### For Most Users (Windows):

1. **Download** `RaspberryPi_HDMI_Tester_vX.X.X.img.zip`
2. **Flash** with Raspberry Pi Imager (auto-verifies)
3. **Done!** No manual verification needed

### For Security-Conscious Users:

1. **Download** all 4 files
2. **Read** `VERIFY_DOWNLOAD_vX.X.X.txt`
3. **Verify** using `.sha256` file
4. **Review** `TESTING_REPORT_vX.X.X.md` for quality assurance
5. **Flash** the image once verified

### For Developers/Auditors:

1. **Download** all 4 files
2. **Verify** checksums match
3. **Review** testing report for build details
4. **Inspect** GitHub Actions logs (linked in report)
5. **Audit** source code and build scripts in repository

---

## File Relationships

```
RaspberryPi_HDMI_Tester_vX.X.X/
├── RaspberryPi_HDMI_Tester_vX.X.X.img.zip  ← The image (REQUIRED)
├── RaspberryPi_HDMI_Tester_vX.X.X.sha256   ← Checksums (RECOMMENDED)
├── TESTING_REPORT_vX.X.X.md                ← QA Report (INFORMATIONAL)
└── VERIFY_DOWNLOAD_vX.X.X.txt              ← How-to Guide (HELPFUL)
```

**Minimum Download:** Just the `.img.zip` file
**Recommended Download:** `.img.zip` + `.sha256`
**Complete Download:** All 4 files for full transparency

---

## Automation & CI/CD

All files are **automatically generated** by GitHub Actions on every build:

1. ✅ Image built with pi-gen
2. ✅ Image validated (filesystem inspection)
3. ✅ QEMU boot test attempted (informational)
4. ✅ Testing report generated
5. ✅ SHA-256 checksums calculated
6. ✅ Verification instructions created
7. ✅ All files uploaded to GitHub Release
8. ✅ Build logs committed to repository

**No manual steps** - Ensures consistency and reproducibility.

---

## Security & Trust

### Why 4 Files Instead of Just the Image?

1. **Transparency**: Testing report shows exactly what was tested
2. **Verification**: SHA-256 ensures file integrity
3. **Accessibility**: Verification instructions help all users
4. **Auditability**: Anyone can review the build process

### Chain of Trust

```
Source Code (GitHub)
    ↓
GitHub Actions (Automated Build)
    ↓
pi-gen (Official Raspberry Pi Tool)
    ↓
Built Image
    ↓
Validation & Testing
    ↓
SHA-256 Checksums
    ↓
GitHub Release (Signed by GitHub)
```

Every step is logged, auditable, and reproducible.

---

## Questions?

- **Issue Tracker:** https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
- **Documentation:** https://github.com/benpaddlejones/Raspberry_HDMI_Tester#readme
- **Build Logs:** Available in `logs/` directory in repository

---

**Last Updated:** 2025-10-19
**Maintained By:** GitHub Actions (Automated)
