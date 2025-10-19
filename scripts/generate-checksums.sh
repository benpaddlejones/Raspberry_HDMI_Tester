#!/bin/bash
# Generate SHA-256 checksums and verification instructions
#
# Usage: generate-checksums.sh <version> <deploy_dir>

set -e
set -u

VERSION="$1"
DEPLOY_DIR="$2"

cd "${DEPLOY_DIR}"

VERSIONED_ZIP="RaspberryPi_HDMI_Tester_v${VERSION}.img.zip"
TESTING_REPORT="TESTING_REPORT_v${VERSION}.md"
CHECKSUM_FILE="RaspberryPi_HDMI_Tester_v${VERSION}.sha256"
VERIFY_FILE="VERIFY_DOWNLOAD_v${VERSION}.txt"

echo "🔐 Generating checksums..."

# Create checksum file with header
cat > "${CHECKSUM_FILE}" << 'EOF'
# SHA-256 Checksums for Raspberry Pi HDMI Tester vVERSION_PLACEHOLDER
#
# Verify downloads with:
#   sha256sum -c RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.sha256
#
# Or verify individual files:
#   sha256sum RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip
#   (compare output with hash below)
#

EOF

# Replace version placeholder
sed -i "s/VERSION_PLACEHOLDER/${VERSION}/g" "${CHECKSUM_FILE}"

# Add checksums
sha256sum "${VERSIONED_ZIP}" >> "${CHECKSUM_FILE}"

if [ -f "${TESTING_REPORT}" ]; then
    sha256sum "${TESTING_REPORT}" >> "${CHECKSUM_FILE}"
    echo "✅ Testing report checksum added"
fi

# Create verification instructions file
cat > "${VERIFY_FILE}" << 'EOF'
================================================================================
Download Verification Instructions
Raspberry Pi HDMI Tester vVERSION_PLACEHOLDER
================================================================================

After downloading the release files, verify their integrity to ensure they
haven't been corrupted or tampered with during download.

--------------------------------------------------------------------------------
Method 1: Automatic Verification (Linux/macOS)
--------------------------------------------------------------------------------

1. Download both files to the same directory:
   - RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip
   - RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.sha256

2. Open Terminal and navigate to the download directory:
   cd ~/Downloads

3. Run verification:
   sha256sum -c RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.sha256

4. Expected output:
   RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip: OK
   TESTING_REPORT_vVERSION_PLACEHOLDER.md: OK

   ✅ If you see "OK" for all files, downloads are verified!
   ❌ If you see "FAILED", re-download the file.

--------------------------------------------------------------------------------
Method 2: Manual Verification (All Platforms)
--------------------------------------------------------------------------------

1. Calculate the SHA-256 hash of your downloaded file:

   Linux/macOS:
   sha256sum RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip

   Windows (PowerShell):
   Get-FileHash RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip -Algorithm SHA256

2. Open the .sha256 file in a text editor

3. Compare the hash output with the hash in the .sha256 file

4. If they match exactly, your download is verified!

--------------------------------------------------------------------------------
Method 3: Windows with Raspberry Pi Imager (Easiest)
--------------------------------------------------------------------------------

The Raspberry Pi Imager automatically verifies the image when you flash it.
You don't need to manually verify if using this tool.

--------------------------------------------------------------------------------
Why Verify?
--------------------------------------------------------------------------------

Verification ensures:
- ✅ Complete download (no corruption during transfer)
- ✅ Authentic file (matches what was built and released)
- ✅ No tampering (file hasn't been modified)

SHA-256 is a cryptographic hash function that creates a unique "fingerprint"
for each file. Even a single bit change results in a completely different hash.

--------------------------------------------------------------------------------
Still Having Issues?
--------------------------------------------------------------------------------

If verification fails repeatedly:
1. Try downloading from a different network
2. Clear your browser cache and try again
3. Download using wget/curl instead of browser
4. Report the issue: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues

================================================================================
EOF

# Replace version placeholders
sed -i "s/VERSION_PLACEHOLDER/${VERSION}/g" "${VERIFY_FILE}"

echo "✅ Checksum file created: ${CHECKSUM_FILE}"
echo "✅ Verification instructions created: ${VERIFY_FILE}"

# Display checksums
echo ""
echo "📄 Checksums:"
cat "${CHECKSUM_FILE}"
