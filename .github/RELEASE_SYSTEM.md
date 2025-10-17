# Release System Documentation

This document explains how the automated release system works for the Raspberry Pi HDMI Tester project.

## Overview

The release system consists of:
1. **`release-config.json`** - Human-readable configuration for releases
2. **`build-release.yml`** - GitHub Action workflow that builds and publishes releases
3. **Automatic README updates** - Links to latest release are added automatically

## Quick Start

### Creating a New Release

1. **Update the configuration** (if needed):
   ```bash
   # Edit .github/release-config.json
   nano .github/release-config.json
   ```

2. **Trigger the build**:
   - Go to: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/actions
   - Select "Build and Release" workflow
   - Click "Run workflow"
   - (Optional) Override version number or force rebuild
   - Click "Run workflow" button

3. **Wait for completion** (~45-60 minutes):
   - The action will build the image
   - Create a GitHub release
   - Upload assets (`.img.zip` and `.sha256`)
   - Update the README with download links

## Configuration File (`release-config.json`)

### Structure

```json
{
  "version": "0.9.0",              // Version number (without 'v' prefix)
  "name": "Beta Test Candidate",   // Release name/title
  "description": "...",             // Short description
  "prerelease": true,               // true = pre-release, false = full release
  "draft": false,                   // true = draft (not published)

  "assets": {
    "image": {
      "filename": "RaspberryPi_HDMI_Tester_v{version}.img.zip",
      "description": "..."
    },
    "checksum": {
      "filename": "RaspberryPi_HDMI_Tester_v{version}.sha256",
      "description": "..."
    }
  },

  "release_notes": {
    "features": [
      "Feature 1",
      "Feature 2"
    ],
    "compatibility": [
      "Raspberry Pi 4",
      "Raspberry Pi 3"
    ],
    "known_issues": [
      "Issue 1"
    ],
    "installation": "..."
  },

  "build": {
    "base_os": "Raspberry Pi OS Lite (Bookworm)",
    "build_system": "pi-gen",
    "build_time_estimate": "45-60 minutes",
    "image_size_estimate": "~1.5-2GB"
  }
}
```

### Key Fields

- **`version`**: Semantic version number (e.g., `0.9.0`, `1.0.0`, `1.2.3`)
  - Versions < 1.0.0 are automatically marked as pre-release
  - Use `prerelease: false` to override

- **`name`**: Human-readable release name
  - Examples: "Beta Test Candidate", "Initial Release", "Bug Fix Update"

- **`prerelease`**: Boolean flag
  - `true` = Pre-release/beta (yellow tag)
  - `false` = Full release (green tag)

- **`release_notes`**: Automatically formatted into release description
  - **`features`**: List of new features
  - **`compatibility`**: Supported hardware
  - **`known_issues`**: Known bugs or limitations

## Workflow Process

The GitHub Action performs these steps:

1. **Read Configuration** - Loads `release-config.json`
2. **Install Dependencies** - Sets up build environment
3. **Install pi-gen** - Clones official Raspberry Pi image builder
4. **Build Image** - Runs `./scripts/build-image.sh`
5. **Prepare Assets**:
   - Renames image with version number
   - Compresses to ZIP
   - Generates SHA256 checksum
6. **Create Release**:
   - Creates git tag (e.g., `v0.9.0`)
   - Uploads assets
   - Publishes release notes
7. **Update README** - Adds download section with links
8. **Commit Changes** - Pushes README updates

## Version Management

### Semantic Versioning

Follow semantic versioning (semver):
- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features (backward compatible)
- **Patch** (0.0.1): Bug fixes

### Pre-release Versions

Versions < 1.0.0 are considered beta/testing:
- `0.9.0` - Beta 1
- `0.9.1` - Beta 2 (bug fixes)
- `1.0.0` - First stable release

### Release Checklist

Before creating a release:

- [ ] Update `release-config.json` with new version
- [ ] Update release notes (features, known issues)
- [ ] Test build locally: `./scripts/build-image.sh`
- [ ] Review all documentation is current
- [ ] Commit all pending changes
- [ ] Trigger GitHub Action

## Manual Override

You can override the version when triggering the workflow:

1. Go to Actions → Build and Release
2. Click "Run workflow"
3. Enter version in "Release version" field (e.g., `0.9.1`)
4. Click "Run workflow"

This overrides the version in `release-config.json` but doesn't update the file.

## Asset Management

### Generated Files

Each release creates:
- **`RaspberryPi_HDMI_Tester_v0.9.0.img.zip`** (~800MB-1.2GB compressed)
- **`RaspberryPi_HDMI_Tester_v0.9.0.sha256`** (checksum file)

### Storage Limits

GitHub has limits for releases:
- **File size limit**: 2GB per file
- **Release size limit**: 10GB total per release
- **No repository storage limit** for releases

Our compressed images (~1GB) are well within limits.

## Troubleshooting

### Build Fails

**Problem**: Build fails during pi-gen stage

**Solution**:
1. Check build logs in GitHub Actions
2. Test build locally in Codespaces
3. Check for disk space issues
4. Try "Force rebuild" option to clear cache

### README Not Updated

**Problem**: README doesn't show download section

**Solution**:
1. Check if `## 📥 Download` already exists in README
2. Workflow skips update if section exists
3. Manually add/update download links if needed

### Version Conflicts

**Problem**: Tag already exists

**Solution**:
1. Delete old tag: `git push --delete origin v0.9.0`
2. Delete old release from GitHub
3. Re-run workflow

## GitHub Actions Usage

### Free Tier Limits

- **2,000 minutes/month** for free accounts
- **3,000 minutes/month** for Pro accounts
- Each build uses ~60 minutes
- Can create ~30 releases/month on free tier

### Caching

The workflow caches pi-gen downloads to speed up builds:
- First build: ~60 minutes
- Subsequent builds: ~40-50 minutes

Force rebuild to clear cache if needed.

## Examples

### Creating v1.0.0 Release

1. Update `release-config.json`:
   ```json
   {
     "version": "1.0.0",
     "name": "First Stable Release",
     "prerelease": false,
     "release_notes": {
       "features": [
         "Tested and validated on Raspberry Pi 4",
         "Boot time optimized to <20 seconds",
         "Comprehensive documentation"
       ],
       "known_issues": []
     }
   }
   ```

2. Commit changes:
   ```bash
   git add .github/release-config.json
   git commit -m "chore: Prepare v1.0.0 release"
   git push
   ```

3. Trigger workflow from GitHub Actions UI

### Creating Hotfix Release

For urgent bug fixes:

1. Create branch: `git checkout -b hotfix/0.9.1`
2. Fix bugs and commit
3. Update `release-config.json`:
   ```json
   {
     "version": "0.9.1",
     "name": "Bug Fix Update"
   }
   ```
4. Push and trigger release from branch
5. Merge back to main

## Future Enhancements

Potential improvements to consider:

- [ ] Automatic version bump on git tags
- [ ] Release on tag push (instead of manual trigger)
- [ ] Multi-architecture builds (Pi 3 vs Pi 4 optimized)
- [ ] Changelog generation from commits
- [ ] Discord/Slack notifications on release
- [ ] Download statistics tracking

## Support

For issues with the release system:
- Check GitHub Actions logs
- Review this documentation
- Open an issue: https://github.com/benpaddlejones/Raspberry_HDMI_Tester/issues
