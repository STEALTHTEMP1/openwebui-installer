#!/usr/bin/env bash
# codex-setup.sh - Prepare Codex environment for Open WebUI Installer
# Installs Qt dependencies, Python packages and starts Xvfb for headless testing.

set -euo pipefail

install_qt_deps() {
    echo "Installing Qt dependencies..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y
        sudo apt-get install -y libx11-dev libgl1-mesa-dev xvfb
    elif command -v brew >/dev/null 2>&1; then
        brew update
        brew install qt xorg-server || true
    else
        echo "Unsupported OS. Install libx11, mesa, and Xvfb manually." >&2
    fi
}

install_python_packages() {
    echo "Installing Python packages..."
    if pip install -r requirements.txt -r requirements-dev.txt; then
        return 0
    fi
    echo "Online install failed, attempting offline install from wheelhouse/"
    if [ -d wheelhouse ]; then
        pip install wheelhouse/*.whl
    else
        echo "wheelhouse directory not found. Cannot perform offline install." >&2
        exit 1
    fi
}

start_xvfb() {
    if pgrep Xvfb >/dev/null 2>&1; then
        return
    fi
    echo "Starting Xvfb on :99..."
    Xvfb :99 -screen 0 1024x768x24 &
    export DISPLAY=:99
}

install_qt_deps
install_python_packages
start_xvfb

echo "Codex environment ready."
