# Release Process

This document outlines the release process for the Open WebUI Installer.

## Prerequisites

Before creating a release, ensure you have:

1. PyPI account with publishing permissions
2. GitHub account with repository write access
3. Access to repository secrets

## Required Secrets

The following secrets must be configured in GitHub repository settings:

1. `PYPI_TOKEN`: API token for PyPI publishing
   - Generate at: https://pypi.org/manage/account/token/
   - Scope: Upload to project

2. `HOMEBREW_TAP_TOKEN`: GitHub Personal Access Token
   - Generate at: https://github.com/settings/tokens
   - Required scopes: 
     * `repo` (Full control of private repositories)
     * `workflow` (Update GitHub Action workflows)

## Release Steps

1. **Prepare Release**
   - Update version in `openwebui_installer/__init__.py`
   - Update CHANGELOG.md
   - Commit changes:
     ```bash
     git add openwebui_installer/__init__.py CHANGELOG.md
     git commit -m "Prepare for release X.Y.Z"
     ```

2. **Create Release Tag**
   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin vX.Y.Z
   ```

3. **Monitor Workflows**
   - GitHub Actions will automatically:
     1. Run tests
     2. Build package
     3. Create GitHub Release
     4. Publish to PyPI
     5. Update Homebrew formula

4. **Verify Release**
   - Check GitHub release page
   - Verify PyPI package
   - Test Homebrew installation:
     ```bash
     brew update
     brew install openwebui-installer
     ```

## Troubleshooting

### PyPI Upload Fails
1. Check PyPI token expiration
2. Verify package version is unique
3. Check package build artifacts

### Homebrew Update Fails
1. Verify tap repository permissions
2. Check HOMEBREW_TAP_TOKEN permissions
3. Ensure formula template is valid

## Rolling Back a Release

If issues are found:

1. Delete the Git tag:
   ```bash
   git push --delete origin vX.Y.Z
   git tag -d vX.Y.Z
   ```

2. Delete GitHub release manually

3. Yank PyPI release:
   ```bash
   pip install twine
   twine yank openwebui-installer==X.Y.Z
   ```

4. Revert Homebrew formula if needed:
   ```bash
   cd homebrew-tap
   git revert HEAD
   git push
   ```

## macOS Notarization & DMG Distribution

The release workflow now builds a signed `OpenWebUI-Desktop.dmg` using the
`create-dmg` tool. To notarize and distribute this DMG:

1. **Prepare Apple Credentials**
   - Export your *Developer ID Application* certificate as a `.p12` file and
     store the base64 contents in the `MACOS_CERT_ID` secret.
   - Provide the certificate password in `MACOS_CERT_PASSWORD`.
   - Set `AC_USERNAME` and `AC_PASSWORD` for notarization.

2. **Notarize the DMG**
   ```bash
   xcrun notarytool submit OpenWebUI-Desktop.dmg \
     --apple-id "$AC_USERNAME" --password "$AC_PASSWORD" \
     --team-id YOUR_TEAM_ID --wait
   xcrun stapler staple OpenWebUI-Desktop.dmg
   ```

3. **Upload to GitHub**
   - The workflow automatically uploads the notarized DMG as a release asset.
   - Users can download it from the release page and drag the app to `/Applications`.
