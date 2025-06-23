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

3. **macOS Signing & Notarization**
   - `MACOS_CERTIFICATE`: Base64 encoded `.p12` certificate
   - `MACOS_CERTIFICATE_PASSWORD`: Certificate password
   - `MACOS_CERT_IDENTITY`: Codesign identity
   - `NOTARIZATION_APPLE_ID`: Apple ID for notary service
   - `NOTARIZATION_TEAM_ID`: Team identifier
   - `NOTARIZATION_PASSWORD`: App-specific password

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

## macOS DMG Notarization

After the workflow builds and signs the DMG it should be notarized with Apple to
avoid Gatekeeper warnings. Ensure the notarization secrets listed above are
configured, then run:

```bash
xcrun notarytool submit openwebui-installer-X.Y.Z.dmg \
  --apple-id "$NOTARIZATION_APPLE_ID" \
  --team-id "$NOTARIZATION_TEAM_ID" \
  --password "$NOTARIZATION_PASSWORD" --wait
xcrun stapler staple openwebui-installer-X.Y.Z.dmg
```

The GitHub Actions workflow performs these steps automatically when credentials
are present.

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
