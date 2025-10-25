#!/bin/bash
# Generate SHA-256 checksums and verification instructions
#
# Usage: generate-checksums.sh <version> <deploy_dir>

set -e
set -u

VERSION="$1"
DEPLOY_DIR="$2"

# Convert to absolute path if relative
if [[ ! "${DEPLOY_DIR}" = /* ]]; then
    DEPLOY_DIR="$(pwd)/${DEPLOY_DIR}"
fi

# Verify directory exists before cd
if [ ! -d "${DEPLOY_DIR}" ]; then
    echo "❌ Error: Deploy directory does not exist: ${DEPLOY_DIR}"
    exit 1
fi

cd "${DEPLOY_DIR}"

VERSIONED_ZIP="RaspberryPi_HDMI_Tester_v${VERSION}.img.zip"
TESTING_REPORT="TESTING_REPORT_v${VERSION}.md"
CHECKSUM_FILE_SHA256="RaspberryPi_HDMI_Tester_v${VERSION}.sha256"
CHECKSUM_FILE_SHA1="RaspberryPi_HDMI_Tester_v${VERSION}.sha1"
CHECKSUM_FILE_MD5="RaspberryPi_HDMI_Tester_v${VERSION}.md5"
CHECKSUM_FILE_BLAKE2="RaspberryPi_HDMI_Tester_v${VERSION}.blake2"
VERIFY_FILE="VERIFY_DOWNLOAD_v${VERSION}.txt"

echo "🔐 Generating checksums (SHA256, SHA1, MD5, BLAKE2)..."

# Create SHA256 checksum file with header
cat > "${CHECKSUM_FILE_SHA256}" << 'EOF'
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
if [ ! -f "${CHECKSUM_FILE_SHA256}" ]; then
    echo "❌ Error: SHA256 checksum file was not created"
    exit 1
fi

sed -i "s/VERSION_PLACEHOLDER/${VERSION}/g" "${CHECKSUM_FILE_SHA256}"

# Add SHA256 checksums
sha256sum "${VERSIONED_ZIP}" >> "${CHECKSUM_FILE_SHA256}"

if [ -f "${TESTING_REPORT}" ]; then
    sha256sum "${TESTING_REPORT}" >> "${CHECKSUM_FILE_SHA256}"
    echo "✅ Testing report SHA256 checksum added"
fi

# Create SHA1 checksum file
cat > "${CHECKSUM_FILE_SHA1}" << 'EOF'
# SHA-1 Checksums for Raspberry Pi HDMI Tester vVERSION_PLACEHOLDER
#
# Verify downloads with:
#   sha1sum -c RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.sha1
#

EOF

sed -i "s/VERSION_PLACEHOLDER/${VERSION}/g" "${CHECKSUM_FILE_SHA1}"

sha1sum "${VERSIONED_ZIP}" >> "${CHECKSUM_FILE_SHA1}"

if [ -f "${TESTING_REPORT}" ]; then
    sha1sum "${TESTING_REPORT}" >> "${CHECKSUM_FILE_SHA1}"
fi

echo "✅ SHA1 checksums generated"

# Create MD5 checksum file
cat > "${CHECKSUM_FILE_MD5}" << 'EOF'
# MD5 Checksums for Raspberry Pi HDMI Tester vVERSION_PLACEHOLDER
#
# Verify downloads with:
#   md5sum -c RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.md5
#

EOF

sed -i "s/VERSION_PLACEHOLDER/${VERSION}/g" "${CHECKSUM_FILE_MD5}"

md5sum "${VERSIONED_ZIP}" >> "${CHECKSUM_FILE_MD5}"

if [ -f "${TESTING_REPORT}" ]; then
    md5sum "${TESTING_REPORT}" >> "${CHECKSUM_FILE_MD5}"
fi

echo "✅ MD5 checksums generated"

# Create BLAKE2 checksum file
cat > "${CHECKSUM_FILE_BLAKE2}" << 'EOF'
# BLAKE2 Checksums for Raspberry Pi HDMI Tester vVERSION_PLACEHOLDER
#
# Verify downloads with:
#   b2sum -c RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.blake2
#

EOF

sed -i "s/VERSION_PLACEHOLDER/${VERSION}/g" "${CHECKSUM_FILE_BLAKE2}"

b2sum "${VERSIONED_ZIP}" >> "${CHECKSUM_FILE_BLAKE2}"

if [ -f "${TESTING_REPORT}" ]; then
    b2sum "${TESTING_REPORT}" >> "${CHECKSUM_FILE_BLAKE2}"
fi

echo "✅ BLAKE2 checksums generated"

# Create verification instructions file
cat > "${VERIFY_FILE}" << 'EOF'
================================================================================
Download Verification Instructions
Raspberry Pi HDMI Tester vVERSION_PLACEHOLDER
================================================================================

After downloading the release files, verify their integrity to ensure they
haven't been corrupted or tampered with during download.

Multiple checksum formats are provided for compatibility:
- SHA256 (recommended): Strong cryptographic security
- SHA1: Legacy compatibility
- MD5: Legacy compatibility (less secure)
- BLAKE2: Modern cryptographic security (faster than SHA256)

--------------------------------------------------------------------------------
Method 1: Automatic Verification (Linux/macOS)
--------------------------------------------------------------------------------

1. Download files to the same directory:
   - RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip
   - One of: .sha256, .sha1, .md5, or .blake2 checksum file

2. Open Terminal and navigate to the download directory:
   cd ~/Downloads

3. Run verification (choose one):
   
   SHA256 (recommended):
   sha256sum -c RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.sha256
   
   SHA1:
   sha1sum -c RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.sha1
   
   MD5:
   md5sum -c RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.md5
   
   BLAKE2:
   b2sum -c RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.blake2

4. Expected output:
   RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip: OK
   TESTING_REPORT_vVERSION_PLACEHOLDER.md: OK

   ✅ If you see "OK" for all files, downloads are verified!
   ❌ If you see "FAILED", re-download the file.

--------------------------------------------------------------------------------
Method 2: Manual Verification (All Platforms)
--------------------------------------------------------------------------------

1. Calculate the hash of your downloaded file:

   Linux/macOS (choose one):
   sha256sum RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip
   sha1sum RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip
   md5sum RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip
   b2sum RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip

   Windows (PowerShell):
   Get-FileHash RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip -Algorithm SHA256
   Get-FileHash RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip -Algorithm SHA1
   Get-FileHash RaspberryPi_HDMI_Tester_vVERSION_PLACEHOLDER.img.zip -Algorithm MD5

2. Open the corresponding checksum file (.sha256, .sha1, .md5, or .blake2) in a text editor

3. Compare the hash output with the hash in the checksum file

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

Cryptographic hash functions create a unique "fingerprint" for each file.
Even a single bit change results in a completely different hash.

SHA256 and BLAKE2 provide strong cryptographic security.
SHA1 and MD5 are provided for legacy tool compatibility but are less secure.

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

echo "✅ Checksum files created:"
echo "   - ${CHECKSUM_FILE_SHA256}"
echo "   - ${CHECKSUM_FILE_SHA1}"
echo "   - ${CHECKSUM_FILE_MD5}"
echo "   - ${CHECKSUM_FILE_BLAKE2}"
echo "✅ Verification instructions created: ${VERIFY_FILE}"

# Display checksums
echo ""
echo "📄 SHA256 Checksums:"
cat "${CHECKSUM_FILE_SHA256}"
echo ""
echo "📄 SHA1 Checksums:"
grep -v "^#" "${CHECKSUM_FILE_SHA1}"
echo ""
echo "📄 MD5 Checksums:"
grep -v "^#" "${CHECKSUM_FILE_MD5}"
echo ""
echo "📄 BLAKE2 Checksums:"
grep -v "^#" "${CHECKSUM_FILE_BLAKE2}"
