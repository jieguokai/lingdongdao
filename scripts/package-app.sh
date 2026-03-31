#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="CodexLobsterIsland"
DIST_DIR="${DIST_DIR:-$ROOT/dist}"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-debug}"
APP_DISPLAY_NAME="${APP_DISPLAY_NAME:-Codex Lobster Island}"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-com.codex.lobsterisland}"
APP_VERSION="${APP_VERSION:-0.1.0}"
APP_BUILD="${APP_BUILD:-1}"
MINIMUM_SYSTEM_VERSION="${MINIMUM_SYSTEM_VERSION:-14.0}"
SPARKLE_FEED_URL="${SPARKLE_FEED_URL:-}"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"
BUILD_DIR="$ROOT/.build/arm64-apple-macosx/$BUILD_CONFIGURATION"
APP_DIR="$DIST_DIR/${APP_NAME}.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
EXECUTABLE="$BUILD_DIR/$APP_NAME"
RESOURCE_BUNDLE="$BUILD_DIR/${APP_NAME}_CodexLobsterIsland.bundle"
AUDIO_SOURCE_DIR="$ROOT/Sources/CodexLobsterIsland/Resources/Audio"
ICON_BUILD_DIR="$ROOT/build/icon"
ICON_WORK_DIR="$ROOT/build/icon.$(uuidgen 2>/dev/null || date +%s%N)"
ICON_PATH="$ICON_BUILD_DIR/${APP_NAME}.icns"

cleanup() {
  rm -rf "$ICON_WORK_DIR"
}

trap cleanup EXIT

swift build -c "$BUILD_CONFIGURATION"
"$ROOT/scripts/generate-app-icon.sh" "$ICON_WORK_DIR" >/dev/null
mkdir -p "$ICON_BUILD_DIR"
cp "$ICON_WORK_DIR/${APP_NAME}.icns" "$ICON_PATH"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$RESOURCES_DIR/Audio" "$FRAMEWORKS_DIR"

cp "$EXECUTABLE" "$MACOS_DIR/$APP_NAME"
if [[ -d "$AUDIO_SOURCE_DIR" ]]; then
  ditto "$AUDIO_SOURCE_DIR" "$RESOURCES_DIR/Audio"
elif [[ -d "$RESOURCE_BUNDLE/Audio" ]]; then
  ditto "$RESOURCE_BUNDLE/Audio" "$RESOURCES_DIR/Audio"
fi
if [[ -f "$ICON_PATH" ]]; then
  cp "$ICON_PATH" "$RESOURCES_DIR/${APP_NAME}.icns"
fi

while IFS= read -r framework; do
  ditto "$framework" "$FRAMEWORKS_DIR/$(basename "$framework")"
done < <(find "$BUILD_DIR" -maxdepth 1 -type d -name '*.framework' | sort)

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_DISPLAY_NAME}</string>
  <key>CFBundleExecutable</key>
  <string>CodexLobsterIsland</string>
  <key>CFBundleIconFile</key>
  <string>CodexLobsterIsland</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_IDENTIFIER}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_DISPLAY_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleSignature</key>
  <string>CLBI</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${APP_BUILD}</string>
  <key>LSMinimumSystemVersion</key>
  <string>${MINIMUM_SYSTEM_VERSION}</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

chmod +x "$MACOS_DIR/$APP_NAME"

if [[ -n "$SPARKLE_FEED_URL" ]]; then
  /usr/libexec/PlistBuddy -c "Add :SUFeedURL string $SPARKLE_FEED_URL" "$CONTENTS_DIR/Info.plist"
fi

if [[ -n "$SPARKLE_PUBLIC_ED_KEY" ]]; then
  /usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string $SPARKLE_PUBLIC_ED_KEY" "$CONTENTS_DIR/Info.plist"
fi

echo "Packaged app at: $APP_DIR"
