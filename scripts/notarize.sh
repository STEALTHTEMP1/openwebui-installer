#!/usr/bin/env bash
# notarize.sh - Sign and notarize Open WebUI installer archive
# Works on macOS; fails on other platforms
set -euo pipefail

ARCHIVE="${1:-}"
if [[ -z "$ARCHIVE" ]]; then
  echo "Usage: $0 <archive>" >&2
  exit 1
fi

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Notarization must run on macOS" >&2
  exit 1
fi

SIGN_ID="${DEVELOPER_ID_APP:?DEVELOPER_ID_APP not set}"
APPLE_ID="${APPLE_ID:?APPLE_ID not set}"
TEAM_ID="${APPLE_TEAM_ID:?APPLE_TEAM_ID not set}"
APP_PW="${APPLE_APP_SPECIFIC_PASSWORD:?APPLE_APP_SPECIFIC_PASSWORD not set}"

SIGNED="signed-$ARCHIVE"
cp "$ARCHIVE" "$SIGNED"

echo "Signing $SIGNED..."
codesign --deep --force --options runtime --sign "$SIGN_ID" "$SIGNED"

echo "Submitting $SIGNED for notarization..."
xcrun notarytool submit "$SIGNED" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_PW" \
  --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$SIGNED"

mv "$SIGNED" "notarized-$ARCHIVE"
echo "Created notarized artifact notarized-$ARCHIVE"
