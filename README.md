# Universal Container App Store

Formerly **Open WebUI Installer**, this project is evolving into a **Universal Container App Store**. The goal is to provide a streamlined way to install and manage containerized applications—including Open WebUI—through a single interface.

**Platform Support**: The new App Store application is currently macOS only. The command‑line installer continues to work on macOS and Linux, while a native Windows version is on the backlog.


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

On Linux, add `--add-host host.docker.internal:host-gateway` so the container can reach your local Ollama instance.

Then access: **http://localhost:3000**

### Optional CLI Installation (Homebrew or pip)

Install the CLI if you prefer managing Open WebUI via commands (macOS and Linux supported today, Windows coming soon):

```bash
# macOS via Homebrew
brew tap open-webui/tap
brew install openwebui-installer

# install via pipx or pip (experimental on other platforms)
pipx install openwebui-installer  # pip install openwebui-installer works too

openwebui-installer install
```

The CLI is actively maintained for macOS and Linux users. Native Windows support is planned for a later release.

The CLI runs the same Docker command shown above.

## ⚙️ Environment Configuration

Copy `.env.example` to `.env` and update the variables as needed. For a
development environment, you can create `.env.dev` the same way:

```bash
cp .env.example .env
# Optionally prepare a development file
cp .env.example .env.dev
# Edit .env and set OLLAMA_BASE_URL, OLLAMA_API_BASE_URL,
# WEBUI_SECRET_KEY and DEBUG
```
## 📋 Prerequisites

- Docker Desktop installed and running
- Web browser
- Optional for running tests: `docker` and `requests` Python packages (`pip install docker requests`)
- If Docker is not installed, run `./setup-codex.sh` which installs Docker and Docker Compose using the official script (requires sudo)

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
If you prefer a helper CLI you can install it via Homebrew or pip (macOS and Linux supported; Windows support is planned):

```bash
# macOS via Homebrew
brew tap open-webui/tap
brew install openwebui-installer

# install via pipx or pip (experimental on other platforms)
pipx install openwebui-installer
```
The CLI continues to support macOS and Linux. Native Windows support is planned for a future update.

Start Open WebUI using the CLI:

```bash
openwebui-installer install
brew upgrade openwebui-installer # upgrade when new versions are released
```

The CLI executes the same Docker command as shown in the quick start.

To upgrade later, run:

```bash
brew update
brew upgrade openwebui-installer
```

### Method 3: Docker Compose

Download the preconfigured compose file and start the stack:

```bash
curl -O https://raw.githubusercontent.com/STEALTHTEMP1/openwebui-installer/main/docker-compose.working.yml
docker-compose -f docker-compose.working.yml up -d
```

The compose file contains a single **open-webui** service that exposes the UI on
port `3000` and connects to your local Ollama instance via the
`OLLAMA_BASE_URL` environment variable. Use the optional `WEBUI_SECRET_KEY`
variable to require a password for the web UI. Data is stored in the
`open-webui` volume and the container restarts automatically if it stops. A
simple health check verifies that the service is reachable on startup.

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

### CLI Management

The installer provides commands to control the container without using raw Docker commands:

```bash
openwebui-installer start      # Start Open WebUI
openwebui-installer stop       # Stop the container
openwebui-installer restart    # Restart the container
openwebui-installer status     # Show current status
```

## 📖 Documentation

- [Working Setup Guide](WORKING_SETUP.md) - Detailed troubleshooting and setup notes
- [Release Notes](CHANGELOG.md) - Version history and changes
- [Codex Setup](CODEX_SETUP.md) - Local development environment instructions

## 🧑‍💻 Development and Testing

Install the development requirements (which include `python-dotenv`) and Qt dependencies before running tests.

```bash
pip install -r requirements-dev.txt  # installs python-dotenv for pytest
sudo apt-get update && sudo apt-get install -y libegl1
QT_QPA_PLATFORM=offscreen pytest tests/
```

---

# Private Repository Setup for Open WebUI Installer

This directory contains everything you need to set up automated releases for your private Open WebUI Installer repository.

> **Note**: The overall project is transitioning into the **Universal Container App Store**, but these release scripts continue to work for Open WebUI-specific deployments.

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
- **`codex-setup.sh`** - Headless testing and dependency setup for Codex
- **`README.md`** - This file
- **`install.py`** - Compatibility wrapper that calls `openwebui-installer`

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

## 🔑 Required Secrets

Set the following secrets in your environment or as Docker secrets:

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `HUGGINGFACE_TOKEN`
- `WEBUI_SECRET_KEY`
- `GH_AUTOMATION_TOKEN`

These are automatically passed to the container by the installer.

## 🔐 GitHub Token for Automation

The auto-merge workflow uses the GitHub CLI to open and merge pull requests for branches pushed to `develop` and `phase-*`. To enable these operations, you must provide a personal access token (PAT) with the following scopes:

- `repo`
- `workflow`

Create the PAT in your GitHub account settings and save it as a repository secret named **either** `GH_PR_TOKEN` **or** `GH_AUTOMATION_TOKEN`. The workflow will export this secret as `GH_TOKEN` for use by the `gh` CLI commands. 

Using a PAT allows the automation to create and merge pull requests even when the default `GITHUB_TOKEN` lacks sufficient permissions.



## 🔒 Security & Privacy

- **Your main repository stays private** - Only releases are public
- **No sensitive data** is included in releases (see exclusions above)
- **Workflow runs in GitHub's secure environment**
- **Uses GitHub's built-in secrets** for authentication
- [Security policy](SECURITY.md) – how to report vulnerabilities

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

## 🗂️ Docker Image Caching

GitHub Actions builds development images and pushes them to GitHub Container Registry. These cached images can dramatically reduce setup time. See [DevOps/REGISTRY_CACHING.md](DevOps/REGISTRY_CACHING.md) for details on using the registry and overriding image tags with environment variables.

## 🤖 Automated PR Merging

When you push to `develop` or any `phase-*` branch, `.github/workflows/auto-pr-merge.yml` automatically creates a pull request if one does not already exist. After all required checks pass, the PR is merged and the branch is deleted.

The workflow authenticates using the `GH_AUTOMATION_TOKEN` secret described above.

---

**Ready to get started?** Run `./setup.sh` and follow the prompts!
