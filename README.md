# Open WebUI Installer

Easy installer and manager for Open WebUI - User-friendly AI Interface

## 🎯 WORKING SETUP (Verified ✅)

**Quick Start - Direct Docker Method:**

```bash
docker run -d -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

Then access: **http://localhost:3000**

## 📋 Prerequisites

- Docker Desktop installed and running
- Web browser

## 🚀 Installation Methods

### Method 1: Direct Docker (Recommended - Verified Working)

```bash
# Install Open WebUI directly
docker run -d -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

**✅ Result**: Open WebUI accessible at http://localhost:3000

### Method 2: Homebrew (Experimental)

```bash
brew tap stealthtemp1/openwebui-installer
brew install openwebui-installer
openwebui-installer install
```

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

## 🧑‍💻 Development and Testing

Install the development requirements and Qt dependencies before running tests.

```bash
pip install -r requirements-dev.txt
sudo apt-get update && sudo apt-get install -y libegl1
QT_QPA_PLATFORM=offscreen pytest tests/
```

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
