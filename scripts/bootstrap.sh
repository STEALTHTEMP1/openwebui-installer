#!/usr/bin/env bash
set -euo pipefail

# bootstrap.sh - Prepare development environment for OpenWebUI Desktop
# Installs Homebrew, Python3 and Podman if missing, syncs Bundled-Runtime,
# and opens the Xcode project on macOS.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
XCODE_DIR="$PROJECT_ROOT/OpenWebUI-Desktop"
BUNDLE_SCRIPT="$XCODE_DIR/Scripts/bundle-resources.sh"

check_brew() {
    if ! command -v brew >/dev/null 2>&1; then
        log_info "Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ "$OSTYPE" == "linux"* ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.bashrc"
        fi
    else
        log_success "Homebrew found: $(brew --version | head -1)"
    fi
}

check_python() {
    if ! command -v python3 >/dev/null 2>&1; then
        log_info "Installing Python3..."
        if command -v brew >/dev/null 2>&1; then
            brew install python
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y python3 python3-venv
        else
            log_error "No supported package manager found for installing Python3"
            exit 1
        fi
    else
        log_success "Python3 found: $(python3 --version)"
    fi
}

check_podman() {
    if ! command -v podman >/dev/null 2>&1; then
        log_info "Installing Podman..."
        if command -v brew >/dev/null 2>&1; then
            brew install podman
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y podman
        else
            log_error "No supported package manager found for installing Podman"
            exit 1
        fi
    else
        log_success "Podman found: $(podman --version)"
    fi
}

sync_runtime() {
    if [[ -x "$BUNDLE_SCRIPT" ]]; then
        log_info "Syncing Bundled-Runtime..."
        if "$BUNDLE_SCRIPT" --verify; then
            log_success "Runtime already up to date"
        else
            "$BUNDLE_SCRIPT"
        fi
    else
        log_warn "bundle-resources.sh not found, skipping runtime sync"
    fi
}

open_project() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "Opening Xcode project..."
        open "$XCODE_DIR/OpenWebUI-Desktop.xcodeproj"
    else
        log_info "Bootstrap complete. Open the Xcode project manually:"
        echo "$XCODE_DIR/OpenWebUI-Desktop.xcodeproj"
    fi
}

main() {
    echo "🚀 OpenWebUI Desktop Bootstrap"
    echo "=============================="
    check_brew
    check_python
    check_podman
    sync_runtime
    open_project
}

main "$@"
