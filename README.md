# Open WebUI Installer

Easy installer and manager for Open WebUI - User-friendly AI Interface

## 🎯 Quick Start (Docker)

Run the official container on macOS or Linux:

```bash
docker run -d -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

Then access: **http://localhost:3000**

### Optional CLI (Homebrew or pip)

Install the CLI if you prefer managing Open WebUI via commands:

```bash
# macOS via Homebrew
brew tap open-webui/tap
brew install openwebui-installer

# or cross-platform via pipx/pip
pipx install openwebui-installer  # pip install openwebui-installer works too

openwebui-installer install
```

The CLI runs the same Docker command shown above.

## 📋 Prerequisites

- Docker Desktop installed and running
- Web browser

## ⚠️ Important Note About Large Files

**Bundled Runtime Components**: The native macOS app includes large bundled runtime files (Podman binary ~41MB, OpenWebUI container image ~1.5GB) that are **not included in this git repository** due to GitHub's 100MB file size limit.

**To build the native app, you must run:**
```bash
cd OpenWebUI-Desktop/Scripts
./bundle-resources.sh
```

This will download the required runtime components locally before building.

## 🚀 Installation Options

The Docker command in the quick start section is the recommended way to run Open WebUI on any platform.
If you prefer a helper CLI you can install it via Homebrew or pip:

```bash
# macOS via Homebrew
brew tap open-webui/tap
brew install openwebui-installer

# or cross-platform via pipx/pip
pipx install openwebui-installer
```

Start Open WebUI using the CLI:

```bash
openwebui-installer install
```

The CLI executes the same Docker command as shown in the quick start.

## 🔧 Container Management

```bash
# Check status
docker ps | grep open-webui

# View logs
docker logs open-webui

# Stop container
docker stop open-webui

# Start container
docker start open-webui

# Remove container
docker rm open-webui
```

## 📖 Documentation

- [Working Setup Guide](WORKING_SETUP.md) - Detailed troubleshooting and setup notes
- [Release Notes](CHANGELOG.md) - Version history and changes
- [Codex Setup](CODEX_SETUP.md) - Prepare the environment for automated tests

---

# Private Repository Setup for Open WebUI Installer

This directory contains everything you need to set up automated releases for your private Open WebUI Installer repository.

## 🚀 Quick Setup

### Option 1: Automated Setup (Recommended)

1. **Copy this entire directory** to your private repository:
   ```bash
   # In your private repository
   cp -r /path/to/openwebuiinstaller/private-repo-setup/* .
   cp -r /path/to/openwebuiinstaller/private-repo-setup/.github .
   ```

2. **Run the setup script**:
   ```bash
   ./setup.sh
   ```

3. **Follow the prompts** and next steps shown by the script.

### Option 2: Manual Setup

1. **Create the GitHub Actions workflow**:
   ```bash
   mkdir -p .github/workflows
   cp .github/workflows/release.yml .github/workflows/
   ```

2. **Customize your project** (add your installer files, README, etc.)

3. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add automated release workflow"
   git push origin main
   ```

## 📦 Creating Your First Release

Once the workflow is set up:

1. **Tag your release**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Watch the workflow run**:
   - Go to your GitHub repository
   - Click "Actions" tab
   - Watch the "Create Release" workflow

3. **Copy the SHA256 hash** from the workflow logs

4. **Update your Homebrew formula** with the new hash

## 🍺 Homebrew Integration

After each release, you'll need to update your public Homebrew tap:

1. **Go to your `homebrew-openwebui-installer` repository**

2. **Update the formula** with the new version and SHA256:
   ```ruby
   url "https://github.com/STEALTHTEMP1/openwebui-installer/archive/refs/tags/v1.0.0.tar.gz"
   sha256 "your-sha256-hash-here"
   ```

3. **Or use the update script**:
   ```bash
   ./update-formula.sh v1.0.0
   ```

## 📁 What's Included

- **`.github/workflows/release.yml`** - Automated release workflow
- **`setup.sh`** - Interactive setup script
- **`README.md`** - This file
- **Sample files** - Created if not present (README.md, install.py, LICENSE)

## 🔧 Workflow Features

The automated workflow:

- ✅ **Triggers on git tags** (v1.0.0, v1.1.0, etc.)
- ✅ **Creates release archives** automatically
- ✅ **Uploads to GitHub Releases** with detailed descriptions
- ✅ **Calculates SHA256 hashes** for Homebrew
- ✅ **Provides clear next steps** in the workflow summary
- ✅ **Excludes sensitive files** (.env, .git, logs, etc.)
- ✅ **Professional release notes** with installation instructions

## 🛠️ Customization

### Modify the Workflow

Edit `.github/workflows/release.yml` to:

- **Change file exclusions** in the `rsync` command
- **Add build steps** if your installer needs compilation
- **Modify release notes** template
- **Add additional assets** to the release

### Project Structure

The workflow works with any project structure. It automatically includes all files except:

- `.git/` - Git metadata
- `.github/` - GitHub workflows
- `node_modules/` - Node.js dependencies
- `__pycache__/` - Python cache
- `*.pyc` - Python bytecode
- `.DS_Store` - macOS metadata
- `release/` - Temporary release directory
- `.env` - Environment files
- `*.log` - Log files

## 🔒 Security & Privacy

- **Your main repository stays private** - Only releases are public
- **No sensitive data** is included in releases (see exclusions above)
- **Workflow runs in GitHub's secure environment**
- **Uses GitHub's built-in secrets** for authentication

## 🆘 Troubleshooting

### Workflow Fails

1. **Check the Actions tab** for error details
2. **Common issues**:
   - Missing files the workflow tries to copy
   - Permissions issues
   - GitHub token problems

### Release Not Created

1. **Verify tag format**: Must be `v1.2.3` (with 'v' prefix)
2. **Check workflow triggers**: Tags must be pushed to trigger
3. **Review workflow permissions**: Ensure `contents: write` permission

### SHA256 Mismatch

1. **Download the exact release archive** from GitHub
2. **Calculate hash locally**:
   ```bash
   curl -L -o temp.tar.gz "https://github.com/STEALTHTEMP1/openwebui-installer/archive/refs/tags/v1.0.0.tar.gz"
   shasum -a 256 temp.tar.gz
   ```
3. **Use the exact hash** in your Homebrew formula

## 📞 Support

- **Workflow issues**: Check GitHub Actions logs
- **Homebrew issues**: Test with `brew audit --strict`
- **General questions**: Create issues in your repository

## 🎯 Next Steps

1. **Set up the workflow** (run `./setup.sh`)
2. **Create your first release** (`git tag v1.0.0 && git push origin v1.0.0`)
3. **Set up your Homebrew tap** (see main project documentation)
4. **Test the complete flow** end-to-end

---

**Ready to get started?** Run `./setup.sh` and follow the prompts!