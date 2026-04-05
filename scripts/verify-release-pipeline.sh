#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$(mktemp -d)"
APP_PATH="$DIST_DIR/CodexLobsterIsland.app"
ZIP_PATH="$DIST_DIR/CodexLobsterIsland-0.1.0+1-macos.zip"
EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/CodexLobsterIsland"
FRAMEWORK_PATH="$APP_PATH/Contents/Frameworks/Sparkle.framework"

trap 'rm -rf "$DIST_DIR"' EXIT

DIST_DIR="$DIST_DIR" \
"$ROOT/scripts/release-app.sh" \
  --skip-sign \
  --skip-notarize \
  --version 0.1.0 \
  --build 1

[[ -d "$APP_PATH" ]]
[[ -f "$ZIP_PATH" ]]
[[ -d "$FRAMEWORK_PATH" ]]
[[ -d "$APP_PATH/Contents/Resources/Audio" ]]

AUDIO_FILES=(
  typing.wav
  running.wav
  awaitingReply.wav
  approval.wav
  success.wav
  error.wav
)

for audio_file in "${AUDIO_FILES[@]}"; do
  [[ -f "$APP_PATH/Contents/Resources/Audio/$audio_file" ]]
done

APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
APP_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")"

[[ "$APP_VERSION" == "0.1.0" ]]
[[ "$APP_BUILD" == "1" ]]

for audio_file in "${AUDIO_FILES[@]}"; do
  SOURCE_SHA="$(shasum -a 256 "$ROOT/Sources/CodexLobsterIsland/Resources/Audio/$audio_file" | awk '{print $1}')"
  PACKAGED_SHA="$(shasum -a 256 "$APP_PATH/Contents/Resources/Audio/$audio_file" | awk '{print $1}')"
  [[ "$SOURCE_SHA" == "$PACKAGED_SHA" ]]
done

SIGNATURE_INFO="$(codesign -dv --verbose=4 "$APP_PATH" 2>&1)"
if [[ "$SIGNATURE_INFO" != *"Signature=adhoc"* ]]; then
  echo "Expected ad-hoc signature when --skip-sign is used" >&2
  exit 1
fi

"$EXECUTABLE_PATH" >/dev/null 2>"$DIST_DIR/launch.stderr" &
APP_PID=$!
sleep 2
kill "$APP_PID" >/dev/null 2>&1 || true
APP_STATUS=0
wait "$APP_PID" || APP_STATUS=$?
if [[ "$APP_STATUS" -ne 0 && "$APP_STATUS" -ne 143 ]]; then
  cat "$DIST_DIR/launch.stderr" >&2
  exit 1
fi

echo "verify-release-pipeline passed"
