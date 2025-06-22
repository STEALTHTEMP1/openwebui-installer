# Release Setup Instructions

This document explains how to set up public releases from your private repository so that the Homebrew formula can access the installer files.

## Overview

Since your main repository (`STEALTHTEMP1/openwebui-installer`) is private, you need to create **public releases** that contain the installer files. The Homebrew formula will download these release assets.

## Step 1: Prepare Your Release Assets

In your private repository, create a release package that contains:

1. **Main installer script** (e.g., `install.py`, `install.sh`, or executable)
2. **Configuration files** (if any)
3. **Documentation** (README, etc.)
4. **Version information**

### Example Release Structure:
```
openwebui-installer-v1.0.0/
├── install.py              # Main installer script
├── config/
│   ├── default.yaml        # Default configuration
│   └── templates/
├── scripts/
│   ├── setup.sh           # Setup utilities
│   └── uninstall.sh       # Uninstall script
├── README.md              # Installation instructions
├── LICENSE                # License file
└── VERSION                # Version information
```

## Step 2: Create a Release Archive

### Option A: Automated with GitHub Actions

Create `.github/workflows/release.yml` in your private repository:

```yaml
name: Create Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Create release archive
      run: |
        # Create a clean directory for release
        mkdir -p release/openwebui-installer
        
        # Copy necessary files (adjust paths as needed)
        cp install.py release/openwebui-installer/
        cp -r config/ release/openwebui-installer/
        cp -r scripts/ release/openwebui-installer/
        cp README.md release/openwebui-installer/
        cp LICENSE release/openwebui-installer/
        echo "${GITHUB_REF#refs/tags/}" > release/openwebui-installer/VERSION
        
        # Create tarball
        cd release
        tar -czf openwebui-installer-${GITHUB_REF#refs/tags/}.tar.gz openwebui-installer/
        
    - name: Create Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Open WebUI Installer ${{ github.ref }}
        draft: false
        prerelease: false
        body: |
          ## Changes in this Release
          
          - Add your release notes here
          
          ## Installation
          
          ### Via Homebrew (macOS/Linux)
          ```bash
          brew tap STEALTHTEMP1/openwebui-installer
          brew install openwebui-installer
          ```
          
          ### Manual Installation
          ```bash
          curl -L https://github.com/STEALTHTEMP1/openwebui-installer/archive/refs/tags/${{ github.ref }}.tar.gz | tar -xz
          cd openwebui-installer-*/
          python3 install.py
          ```

    - name: Upload Release Asset
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ steps.create_release.outputs.upload_url }}
        asset_path: ./release/openwebui-installer-${{ github.ref_name }}.tar.gz
        asset_name: openwebui-installer-${{ github.ref_name }}.tar.gz
        asset_content_type: application/gzip
```

### Option B: Manual Release Creation

1. **Create the release archive locally:**
   ```bash
   # In your private repository
   mkdir -p release/openwebui-installer
   cp install.py release/openwebui-installer/
   cp -r config/ release/openwebui-installer/
   cp README.md release/openwebui-installer/
   cd release
   tar -czf openwebui-installer-v1.0.0.tar.gz openwebui-installer/
   ```

2. **Create a release on GitHub:**
   - Go to your private repository
   - Click "Releases" → "Create a new release"
   - Tag: `v1.0.0`
   - Title: `Open WebUI Installer v1.0.0`
   - Upload your `openwebui-installer-v1.0.0.tar.gz` file
   - **Make sure the release is public**

## Step 3: Get the SHA256 Hash

After creating the release, you need to get the SHA256 hash:

```bash
# Download the release file
curl -L -o openwebui-installer-v1.0.0.tar.gz \
  https://github.com/STEALTHTEMP1/openwebui-installer/archive/refs/tags/v1.0.0.tar.gz

# Calculate SHA256
shasum -a 256 openwebui-installer-v1.0.0.tar.gz
```

## Step 4: Update the Homebrew Formula

In your public Homebrew tap repository, update `Formula/openwebui-installer.rb`:

```ruby
class OpenwebuiInstaller < Formula
  desc "Easy installer and manager for Open WebUI - User-friendly AI Interface"
  homepage "https://github.com/STEALTHTEMP1/openwebui-installer"
  url "https://github.com/STEALTHTEMP1/openwebui-installer/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256_FROM_STEP_3"
  license "MIT"
  # ... rest of the formula
end
```

## Step 5: Version Updates

For each new version:

1. **Tag your private repository:**
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```

2. **Create the release** (automatically if using GitHub Actions, or manually)

3. **Update the Homebrew formula** with the new version and SHA256

4. **Test the update:**
   ```bash
   brew uninstall openwebui-installer
   brew install openwebui-installer
   ```

## Step 6: Automation Script (Optional)

Create a script to automate formula updates:

```bash
#!/bin/bash
# update-formula.sh

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v1.0.0"
    exit 1
fi

# Download the release
URL="https://github.com/STEALTHTEMP1/openwebui-installer/archive/refs/tags/${VERSION}.tar.gz"
curl -L -o temp.tar.gz "$URL"

# Calculate SHA256
SHA256=$(shasum -a 256 temp.tar.gz | cut -d' ' -f1)

# Update the formula
sed -i '' "s|url \".*\"|url \"$URL\"|" Formula/openwebui-installer.rb
sed -i '' "s|sha256 \".*\"|sha256 \"$SHA256\"|" Formula/openwebui-installer.rb

# Clean up
rm temp.tar.gz

echo "Updated formula for version $VERSION"
echo "SHA256: $SHA256"
echo "Don't forget to commit and push the changes!"
```

## Security Considerations

1. **Keep sensitive data out of releases** - Don't include API keys, passwords, or private configuration
2. **Validate release contents** - Make sure only intended files are included
3. **Use signed releases** - Consider signing your releases for additional security
4. **Review before publishing** - Always review the release contents before making it public

## Testing Your Release

Before updating the Homebrew formula:

1. **Download and test the release manually:**
   ```bash
   curl -L https://github.com/STEALTHTEMP1/openwebui-installer/archive/refs/tags/v1.0.0.tar.gz | tar -xz
   cd openwebui-installer-v1.0.0/
   python3 install.py --help
   ```

2. **Test the Homebrew formula locally:**
   ```bash
   brew install --build-from-source Formula/openwebui-installer.rb
   ```

## Troubleshooting

### Common Issues:

1. **404 Error when downloading:**
   - Make sure the release is public
   - Check the URL format
   - Verify the tag exists

2. **SHA256 Mismatch:**
   - Recalculate the hash
   - Make sure you're downloading the same file
   - Check for any CDN caching issues

3. **Formula Installation Fails:**
   - Test the release archive manually first
   - Check file permissions
   - Verify all dependencies are listed

### Getting Help:

- Test your formula with `brew audit --strict Formula/openwebui-installer.rb`
- Check Homebrew documentation: https://docs.brew.sh/Formula-Cookbook
- Review other formula examples: https://github.com/Homebrew/homebrew-core/tree/master/Formula