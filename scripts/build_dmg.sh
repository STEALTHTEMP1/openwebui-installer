#!/usr/bin/env bash
set -euo pipefail

APP_NAME="OpenWebUIInstaller"
VERSION="${VERSION:-0.1.0}"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

BUILD_DIR="dist"
APP_PATH="$BUILD_DIR/${APP_NAME}.app"

function build_app() {
    python -m pip install --upgrade pip
    pip install pyinstaller
    pyinstaller --noconfirm --windowed --name "$APP_NAME" openwebui_installer/gui.py
}

function sign_app() {
    codesign --deep --force --options runtime \
        --sign "$CODESIGN_IDENTITY" "$APP_PATH"
}

function create_dmg() {
    brew install create-dmg || true
    create-dmg --overwrite --volname "$APP_NAME" "$APP_PATH" "$BUILD_DIR/$DMG_NAME"
}

function notarize_dmg() {
    xcrun notarytool submit "$BUILD_DIR/$DMG_NAME" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_PASSWORD" \
        --wait
    xcrun stapler staple "$BUILD_DIR/$DMG_NAME"
}

if [[ "$(uname)" != "Darwin" ]]; then
    echo "DMG build only supported on macOS" >&2
    exit 1
fi

mkdir -p "$BUILD_DIR"

build_app
sign_app
create_dmg
notarize_dmg

echo "Created notarized DMG: $BUILD_DIR/$DMG_NAME"
