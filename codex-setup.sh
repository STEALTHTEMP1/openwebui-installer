#!/usr/bin/env bash

# codex-setup.sh - Setup script for Codex development environment
# Installs Qt dependencies, handles offline wheel installation,
# and starts an Xvfb display for headless PyQt tests.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

install_deps_linux() {
    if command -v apt-get >/dev/null; then
        sudo apt-get update
        sudo apt-get install -y \
            libx11-dev \
            libgl1-mesa-dev \
            libegl1 \
            libxkbcommon-x11-0 \
            libxcb-xinerama0 \
            xvfb
    fi
}

install_deps_macos() {
    if command -v brew >/dev/null; then
        brew update
        brew install qt6 xquartz || true
    else
        echo "Homebrew not found. Install from https://brew.sh/" >&2
        exit 1
    fi
}

install_python() {
    if ! pip install -r requirements.txt -r requirements-dev.txt; then
        echo "Online installation failed, trying wheelhouse..." >&2
        if [ -d "$REPO_ROOT/wheelhouse" ]; then
            pip install --no-index --find-links="$REPO_ROOT/wheelhouse" \
                -r requirements.txt -r requirements-dev.txt
        else
            echo "wheelhouse directory missing" >&2
            exit 1
        fi
    fi
}

start_xvfb() {
    if command -v Xvfb >/dev/null && ! pgrep Xvfb >/dev/null; then
        echo "Starting Xvfb display :99"
        Xvfb :99 -screen 0 1280x1024x24 > /tmp/xvfb.log 2>&1 &
        export DISPLAY=:99
    fi
    export QT_QPA_PLATFORM=offscreen
}

main() {
    case "$(uname)" in
        Linux*) install_deps_linux ;;
        Darwin*) install_deps_macos ;;
        *) echo "Unsupported OS: $(uname)" >&2; exit 1 ;;
    esac

    install_python
    start_xvfb

    echo "Codex environment ready"
}

main "$@"
