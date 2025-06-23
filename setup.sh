#!/bin/bash

# setup.sh - Setup script for your private repository
# This script helps you set up the automated release workflow

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_banner() {
    echo "================================================"
    echo "🚀 Open WebUI Installer - Private Repo Setup"
    echo "================================================"
    echo ""
}

show_help() {
    cat << EOF
Private Repository Setup Script

This script sets up automated releases for your private Open WebUI Installer repository.

Usage: $0 [OPTIONS]

Options:
  -h, --help     Show this help message
  -f, --force    Force overwrite existing files
  -d, --dry-run  Show what would be done without making changes

What this script does:
1. Creates the .github/workflows directory
2. Sets up the automated release workflow
3. Creates a sample project structure (if needed)
4. Provides next steps for creating your first release

Requirements:
- Git repository initialized
- GitHub repository created (can be private)

Examples:
  $0              # Setup with prompts
  $0 --force      # Overwrite existing files
  $0 --dry-run    # Show what would be done
EOF
}

check_requirements() {
    log_info "Checking requirements..."

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository. Please run 'git init' first."
        exit 1
    fi

    # Check if git is configured
    if ! git config user.name > /dev/null 2>&1; then
        log_warning "Git user.name not configured. Consider running:"
        echo "  git config user.name 'Your Name'"
    fi

    if ! git config user.email > /dev/null 2>&1; then
        log_warning "Git user.email not configured. Consider running:"
        echo "  git config user.email 'your.email@example.com'"
    fi

    log_success "Requirements check passed"
}

setup_workflow() {
    log_info "Setting up GitHub Actions workflow..."

    # Create .github/workflows directory
    mkdir -p .github/workflows

    # Check if workflow already exists
    if [[ -f ".github/workflows/release.yml" && "$FORCE" != true ]]; then
        echo -n "Workflow file already exists. Overwrite? [y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Skipping workflow setup"
            return
        fi
    fi

    # Copy the workflow file
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would create: .github/workflows/release.yml"
        return
    fi

    cat > .github/workflows/release.yml << 'EOF'
name: Create Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Create release archive
      run: |
        # Create a clean directory for release
        mkdir -p release/openwebui-installer

        # Copy all files except .git and other unwanted directories
        rsync -av --exclude='.git' --exclude='.github' --exclude='node_modules' \
              --exclude='__pycache__' --exclude='*.pyc' --exclude='.DS_Store' \
              --exclude='release' --exclude='.env' --exclude='*.log' \
              ./ release/openwebui-installer/

        # Create version file
        echo "${GITHUB_REF#refs/tags/}" > release/openwebui-installer/VERSION

        # Show what we're including in the release
        echo "Release contents:"
        find release/openwebui-installer -type f | head -20
        echo "..."
        echo "Total files: $(find release/openwebui-installer -type f | wc -l)"

        # Create tarball
        cd release
        tar -czf openwebui-installer-${GITHUB_REF#refs/tags/}.tar.gz openwebui-installer/

        # Verify the archive
        echo "Archive created:"
        ls -la openwebui-installer-*.tar.gz

        # Show archive contents preview
        echo "Archive contents preview:"
        tar -tzf openwebui-installer-*.tar.gz | head -10
        echo "..."

    - name: Extract version
      id: extract_version
      run: echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT

    - name: Create Release
      id: create_release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Open WebUI Installer ${{ steps.extract_version.outputs.VERSION }}
        draft: false
        prerelease: false
        body: |
          ## Open WebUI Installer ${{ steps.extract_version.outputs.VERSION }}

          🚀 **Easy installer and manager for Open WebUI - User-friendly AI Interface**

          ### What's New in ${{ steps.extract_version.outputs.VERSION }}
          - Enhanced installation process
          - Improved error handling and user feedback
          - Better compatibility across different systems
          - Updated dependencies and security improvements

          ### Installation Methods

          #### 🍺 Via Homebrew (macOS/Linux) - **Recommended**
          ```bash
          # Add the tap
          brew tap STEALTHTEMP1/openwebui-installer

          # Install the installer
          brew install openwebui-installer

          # Install Open WebUI
          openwebui-installer install
          ```

          #### 📦 Manual Installation
          ```bash
          # Download and extract
          curl -L https://github.com/STEALTHTEMP1/openwebui-installer/archive/refs/tags/${{ steps.extract_version.outputs.VERSION }}.tar.gz | tar -xz
          cd openwebui-installer-*

          # Make executable (if needed)
          chmod +x install.py install.sh

          # Run the installer
          python3 install.py
          # OR if you have a shell script
          # ./install.sh
          ```

          ### 🎯 Features
          - **One-command installation** - Get Open WebUI running instantly
          - **Automatic updates** - Keep your installation current
          - **Service management** - Start, stop, restart Open WebUI easily
          - **Docker support** - Clean, isolated installations
          - **Platform support** - Currently macOS only (Linux and Windows planned)
          - **Configuration management** - Easy setup and customization

          ### 📋 Requirements
          - **Python 3.8+** (for Python-based components)
          - **Docker** (will be installed automatically if missing)
          - **Internet connection** (for downloading Open WebUI and models)
          - **4GB+ RAM recommended** (for AI model operations)

          ### 🚀 Quick Start
          ```bash
          # Install via Homebrew
          brew tap STEALTHTEMP1/openwebui-installer
          brew install openwebui-installer

          # Install Open WebUI
          openwebui-installer install

          # Start the service
          openwebui-installer start

          # Open in browser (usually http://localhost:3000)
          open http://localhost:3000
          ```

          ### 📖 Available Commands
          ```bash
          openwebui-installer install     # Install Open WebUI
          openwebui-installer start       # Start the service
          openwebui-installer stop        # Stop the service
          openwebui-installer restart     # Restart the service
          openwebui-installer status      # Check service status
          openwebui-installer update      # Update Open WebUI
          openwebui-installer uninstall   # Remove Open WebUI
          openwebui-installer logs        # View service logs
          openwebui-installer --help      # Show all commands
          openwebui-installer --version   # Show version info
          ```

          ### 🔧 Troubleshooting
          - **Service won't start?** Check logs with `openwebui-installer logs`
          - **Port conflicts?** Use `openwebui-installer config` to change ports
          - **Docker issues?** Ensure Docker is running and accessible
          - **Permission errors?** Try running with appropriate permissions

          ### 🆘 Support
          - **Documentation:** [README.md](https://github.com/STEALTHTEMP1/openwebui-installer)
          - **Issues:** [Report bugs and request features](https://github.com/STEALTHTEMP1/openwebui-installer/issues)
          - **Homebrew Tap:** [STEALTHTEMP1/homebrew-openwebui-installer](https://github.com/STEALTHTEMP1/homebrew-openwebui-installer)

          ### 🔐 Security & Privacy
          - All installations are local to your machine
          - No data is sent to external servers without your consent
          - Docker containers provide isolation and security
          - Open source and auditable

          ---

          ### 📊 Checksums
          **Archive:** `openwebui-installer-${{ steps.extract_version.outputs.VERSION }}.tar.gz`

          The SHA256 hash for this release is automatically calculated and will be updated in the Homebrew formula.

          For manual verification:
          ```bash
          shasum -a 256 openwebui-installer-${{ steps.extract_version.outputs.VERSION }}.tar.gz
          ```

          ### 🔄 Homebrew Formula Updates
          The SHA256 hash will be displayed in the workflow logs for updating the Homebrew formula.

    - name: Upload Release Asset
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ steps.create_release.outputs.upload_url }}
        asset_path: ./release/openwebui-installer-${{ steps.extract_version.outputs.VERSION }}.tar.gz
        asset_name: openwebui-installer-${{ steps.extract_version.outputs.VERSION }}.tar.gz
        asset_content_type: application/gzip

    - name: Generate SHA256 for Homebrew
      run: |
        cd release
        ARCHIVE_NAME="openwebui-installer-${{ steps.extract_version.outputs.VERSION }}.tar.gz"
        SHA256=$(shasum -a 256 "$ARCHIVE_NAME" | cut -d' ' -f1)

        echo "================================================"
        echo "🍺 HOMEBREW FORMULA UPDATE REQUIRED"
        echo "================================================"
        echo ""
        echo "Archive: $ARCHIVE_NAME"
        echo "SHA256: $SHA256"
        echo ""
        echo "Update your Formula/openwebui-installer.rb file with:"
        echo ""
        echo "url \"https://github.com/STEALTHTEMP1/openwebui-installer/archive/refs/tags/${{ steps.extract_version.outputs.VERSION }}.tar.gz\""
        echo "sha256 \"$SHA256\""
        echo ""
        echo "================================================"

        # Create GitHub Actions summary
        echo "## 🍺 Homebrew Formula Update Required" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "Update your \`Formula/openwebui-installer.rb\` file in the [homebrew-openwebui-installer](https://github.com/STEALTHTEMP1/homebrew-openwebui-installer) repository:" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "\`\`\`ruby" >> $GITHUB_STEP_SUMMARY
        echo "url \"https://github.com/STEALTHTEMP1/openwebui-installer/archive/refs/tags/${{ steps.extract_version.outputs.VERSION }}.tar.gz\"" >> $GITHUB_STEP_SUMMARY
        echo "sha256 \"$SHA256\"" >> $GITHUB_STEP_SUMMARY
        echo "\`\`\`" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "### Quick Update Command" >> $GITHUB_STEP_SUMMARY
        echo "If you have the update script, run:" >> $GITHUB_STEP_SUMMARY
        echo "\`\`\`bash" >> $GITHUB_STEP_SUMMARY
        echo "./update-formula.sh ${{ steps.extract_version.outputs.VERSION }}" >> $GITHUB_STEP_SUMMARY
        echo "\`\`\`" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "### Manual Steps" >> $GITHUB_STEP_SUMMARY
        echo "1. Update the formula file with the new URL and SHA256" >> $GITHUB_STEP_SUMMARY
        echo "2. Test with \`brew audit --strict Formula/openwebui-installer.rb\`" >> $GITHUB_STEP_SUMMARY
        echo "3. Commit and push the changes" >> $GITHUB_STEP_SUMMARY
        echo "4. Test installation: \`brew install STEALTHTEMP1/openwebui-installer/openwebui-installer\`" >> $GITHUB_STEP_SUMMARY

    - name: Verify Release
      run: |
        echo "✅ Release verification:"
        echo "   Tag: ${{ steps.extract_version.outputs.VERSION }}"
        echo "   Release ID: ${{ steps.create_release.outputs.id }}"
        echo "   Release URL: ${{ steps.create_release.outputs.html_url }}"
        echo "   Upload URL: ${{ steps.create_release.outputs.upload_url }}"
        echo ""
        echo "🎉 Release ${{ steps.extract_version.outputs.VERSION }} created successfully!"
        echo ""
        echo "Next steps:"
        echo "1. ✅ Release created and archive uploaded"
        echo "2. 🔄 Update Homebrew formula with the SHA256 hash above"
        echo "3. 🧪 Test the installation"
        echo "4. 📢 Announce the release!"
EOF

    log_success "Created .github/workflows/release.yml"
}

create_sample_structure() {
    log_info "Checking project structure..."

    # Create basic files if they don't exist
    local files_created=0

    if [[ ! -f "README.md" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log_info "Would create: README.md"
        else
            cat > README.md << 'EOF'
# Open WebUI Installer

Easy installer and manager for Open WebUI - A user-friendly AI interface.

## Features

- One-command installation
- Automatic updates
- Service management
- Docker support
 - Platform support: currently macOS only (Linux and Windows planned)

## Installation

### Via Homebrew (Recommended)

```bash
brew tap STEALTHTEMP1/openwebui-installer
brew install openwebui-installer
openwebui-installer install
```

### Manual Installation

```bash
# Clone or download this repository
git clone https://github.com/STEALTHTEMP1/openwebui-installer.git
cd openwebui-installer

# Run the installer
python3 install.py
# OR
# ./install.sh
```

## Usage

```bash
openwebui-installer install     # Install Open WebUI
openwebui-installer start       # Start the service
openwebui-installer stop        # Stop the service
openwebui-installer status      # Check status
openwebui-installer update      # Update Open WebUI
openwebui-installer uninstall   # Remove Open WebUI
```

## Requirements

- Python 3.8+
- Docker (will be installed if missing)
- 4GB+ RAM recommended

## License

MIT License - see LICENSE file for details.
EOF
            files_created=$((files_created + 1))
            log_success "Created README.md"
        fi
    fi

    if [[ ! -f "install.py" && ! -f "install.sh" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log_info "Would create: install.py (sample)"
        else
            cat > install.py << 'EOF'
#!/usr/bin/env python3
"""
Open WebUI Installer
Easy installer and manager for Open WebUI
"""

import sys
import argparse
import subprocess
import os

def main():
    parser = argparse.ArgumentParser(description='Open WebUI Installer')
    parser.add_argument('command', nargs='?', default='help',
                       choices=['install', 'start', 'stop', 'status', 'update', 'uninstall', 'help'],
                       help='Command to execute')
    parser.add_argument('--version', action='version', version='1.1.1')

    args = parser.parse_args()

    if args.command == 'help':
        parser.print_help()
        print("\nAvailable commands:")
        print("  install     Install Open WebUI")
        print("  start       Start Open WebUI service")
        print("  stop        Stop Open WebUI service")
        print("  status      Check service status")
        print("  update      Update Open WebUI")
        print("  uninstall   Remove Open WebUI")
    elif args.command == 'install':
        print("🚀 Installing Open WebUI...")
        # Add your installation logic here
        print("✅ Installation completed!")
    elif args.command == 'start':
        print("▶️  Starting Open WebUI...")
        # Add your start logic here
        print("✅ Open WebUI started!")
    elif args.command == 'stop':
        print("⏹️  Stopping Open WebUI...")
        # Add your stop logic here
        print("✅ Open WebUI stopped!")
    elif args.command == 'status':
        print("📊 Checking Open WebUI status...")
        # Add your status logic here
        print("✅ Open WebUI is running")
    elif args.command == 'update':
        print("🔄 Updating Open WebUI...")
        # Add your update logic here
        print("✅ Update completed!")
    elif args.command == 'uninstall':
        print("🗑️  Uninstalling Open WebUI...")
        # Add your uninstall logic here
        print("✅ Uninstall completed!")

if __name__ == '__main__':
    main()
EOF
            chmod +x install.py
            files_created=$((files_created + 1))
            log_success "Created install.py (sample)"
        fi
    fi

    if [[ ! -f "LICENSE" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log_info "Would create: LICENSE"
        else
            cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 STEALTHTEMP1

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
            files_created=$((files_created + 1))
            log_success "Created LICENSE"
        fi
    fi

    if [[ $files_created -gt 0 ]]; then
        log_info "Created $files_created sample files. Please customize them for your project."
    else
        log_info "Project structure looks good!"
    fi
}

show_next_steps() {
    echo ""
    echo "================================================"
    echo "🎉 Setup Complete!"
    echo "================================================"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. 📝 Customize your project files:"
    echo "   - Edit README.md with your project details"
    echo "   - Update install.py with your actual installer logic"
    echo "   - Add any additional files your installer needs"
    echo ""
    echo "2. 📦 Commit your changes:"
    echo "   git add ."
    echo "   git commit -m 'Initial project setup with automated releases'"
    echo "   git push origin main"
    echo ""
    echo "3. 🏷️  Create your first release:"
    echo "   git tag v1.0.0"
    echo "   git push origin v1.0.0"
    echo ""
    echo "4. 👀 Watch the magic happen:"
    echo "   - Go to your GitHub repository"
    echo "   - Click on 'Actions' tab"
    echo "   - Watch the 'Create Release' workflow run"
    echo "   - Copy the SHA256 hash from the workflow logs"
    echo ""
    echo "5. 🍺 Update your Homebrew formula:"
    echo "   - Go to your homebrew-openwebui-installer repository"
    echo "   - Update Formula/openwebui-installer.rb with the new SHA256"
    echo "   - Or use: ./update-formula.sh v1.0.0"
    echo ""
    echo "6. 🧪 Test the installation:"
    echo "   brew tap STEALTHTEMP1/openwebui-installer"
    echo "   brew install openwebui-installer"
    echo ""
    echo "📖 For more details, check the generated workflow file:"
    echo "   .github/workflows/release.yml"
    echo ""
    echo "🆘 Need help? Check the GitHub Actions logs after pushing a tag!"
}

# Parse command line arguments
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            log_error "Unknown option $1"
            show_help
            exit 1
            ;;
        *)
            log_error "Unexpected argument $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
show_banner

if [[ "$DRY_RUN" == true ]]; then
    log_warning "Running in dry-run mode - no changes will be made"
    echo ""
fi

check_requirements
setup_workflow
create_sample_structure

if [[ "$DRY_RUN" == false ]]; then
    show_next_steps
else
    echo ""
    log_info "Dry run completed. Run without --dry-run to make actual changes."
fi
