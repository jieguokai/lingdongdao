#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="CodexLobsterIsland"
DIST_DIR="${DIST_DIR:-$ROOT/dist}"
APP_PATH="$DIST_DIR/${APP_NAME}.app"
FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"

VERSION="0.1.0"
BUILD_NUMBER="1"
BUNDLE_IDENTIFIER="com.codex.lobsterisland"
MINIMUM_SYSTEM_VERSION="14.0"
IDENTITY="${APPLE_DEVELOPER_IDENTITY:-}"
NOTARY_PROFILE="${APPLE_NOTARY_PROFILE:-}"
ENTITLEMENTS_PATH="$ROOT/Config/Release/DeveloperID.entitlements"
DOWNLOAD_BASE_URL="${DOWNLOAD_BASE_URL:-}"
APPCAST_URL="${APPCAST_URL:-}"
RELEASE_NOTES_URL="${RELEASE_NOTES_URL:-}"
RELEASE_NOTES_MARKDOWN="${RELEASE_NOTES_MARKDOWN:-}"
RELEASE_NOTES_OUTPUT_DIR="${RELEASE_NOTES_OUTPUT_DIR:-$DIST_DIR/release-notes}"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"
SPARKLE_PRIVATE_ED_KEY_FILE="${SPARKLE_PRIVATE_ED_KEY_FILE:-}"
SPARKLE_ED_SIGNATURE="${SPARKLE_ED_SIGNATURE:-}"
RELEASE_NOTES_ED_SIGNATURE="${RELEASE_NOTES_ED_SIGNATURE:-}"
FEED_OUTPUT_DIR="${FEED_OUTPUT_DIR:-$DIST_DIR/feed}"
SKIP_SIGN=false
SKIP_NOTARIZE=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --version <value>           CFBundleShortVersionString (default: $VERSION)
  --build <value>             CFBundleVersion (default: $BUILD_NUMBER)
  --bundle-id <value>         CFBundleIdentifier (default: $BUNDLE_IDENTIFIER)
  --minimum-system <value>    LSMinimumSystemVersion (default: $MINIMUM_SYSTEM_VERSION)
  --identity <value>          Developer ID Application identity
  --notary-profile <value>    notarytool keychain profile name
  --entitlements <path>       entitlements plist path
  --download-base-url <url>   base URL for hosted release archives
  --appcast-url <url>         hosted appcast XML URL
  --release-notes-url <url>   hosted release notes URL
  --release-notes-markdown <p>
                              local markdown file to render as release notes html
  --release-notes-output-dir <path>
                              output directory for generated release notes html
  --sparkle-public-ed-key <k> SUPublicEDKey value to embed in Info.plist
  --sparkle-private-ed-key-file <path>
                              private Ed25519 key file for signing archives and release notes
  --sparkle-ed-signature <s>  sparkle:edSignature for the generated appcast item
  --feed-output-dir <path>    output directory for generated feed files
  --skip-sign                 build unsigned app and zip only
  --skip-notarize             skip notarization
  --help                      show help

Environment:
  APPLE_DEVELOPER_IDENTITY    default for --identity
  APPLE_NOTARY_PROFILE        default for --notary-profile
  DOWNLOAD_BASE_URL           default for --download-base-url
  APPCAST_URL                 default for --appcast-url
  RELEASE_NOTES_URL           default for --release-notes-url
  RELEASE_NOTES_MARKDOWN      default for --release-notes-markdown
  SPARKLE_PUBLIC_ED_KEY       default for --sparkle-public-ed-key
  SPARKLE_PRIVATE_ED_KEY_FILE default for --sparkle-private-ed-key-file
  SPARKLE_ED_SIGNATURE        default for --sparkle-ed-signature
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --build)
      BUILD_NUMBER="$2"
      shift 2
      ;;
    --bundle-id)
      BUNDLE_IDENTIFIER="$2"
      shift 2
      ;;
    --minimum-system)
      MINIMUM_SYSTEM_VERSION="$2"
      shift 2
      ;;
    --identity)
      IDENTITY="$2"
      shift 2
      ;;
    --notary-profile)
      NOTARY_PROFILE="$2"
      shift 2
      ;;
    --entitlements)
      ENTITLEMENTS_PATH="$2"
      shift 2
      ;;
    --download-base-url)
      DOWNLOAD_BASE_URL="$2"
      shift 2
      ;;
    --appcast-url)
      APPCAST_URL="$2"
      shift 2
      ;;
    --release-notes-url)
      RELEASE_NOTES_URL="$2"
      shift 2
      ;;
    --release-notes-markdown)
      RELEASE_NOTES_MARKDOWN="$2"
      shift 2
      ;;
    --release-notes-output-dir)
      RELEASE_NOTES_OUTPUT_DIR="$2"
      shift 2
      ;;
    --sparkle-public-ed-key)
      SPARKLE_PUBLIC_ED_KEY="$2"
      shift 2
      ;;
    --sparkle-private-ed-key-file)
      SPARKLE_PRIVATE_ED_KEY_FILE="$2"
      shift 2
      ;;
    --sparkle-ed-signature)
      SPARKLE_ED_SIGNATURE="$2"
      shift 2
      ;;
    --feed-output-dir)
      FEED_OUTPUT_DIR="$2"
      shift 2
      ;;
    --skip-sign)
      SKIP_SIGN=true
      shift
      ;;
    --skip-notarize)
      SKIP_NOTARIZE=true
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$SKIP_SIGN" == true && "$SKIP_NOTARIZE" == false ]]; then
  echo "Notarization requires signing. Use --skip-notarize together with --skip-sign." >&2
  exit 1
fi

if [[ "$SKIP_SIGN" == false && -z "$IDENTITY" ]]; then
  echo "Missing signing identity. Pass --identity or set APPLE_DEVELOPER_IDENTITY." >&2
  exit 1
fi

if [[ "$SKIP_NOTARIZE" == false && -z "$NOTARY_PROFILE" ]]; then
  echo "Missing notary profile. Pass --notary-profile or set APPLE_NOTARY_PROFILE." >&2
  exit 1
fi

require_command swift
require_command /usr/bin/ditto
require_command /usr/bin/xcrun
require_command python3

if [[ "$SKIP_SIGN" == false ]]; then
  require_command /usr/bin/codesign
  require_command /usr/sbin/spctl
  [[ -f "$ENTITLEMENTS_PATH" ]] || {
    echo "Entitlements file not found: $ENTITLEMENTS_PATH" >&2
    exit 1
  }
fi

if [[ -n "$SPARKLE_PRIVATE_ED_KEY_FILE" ]]; then
  [[ -f "$SPARKLE_PRIVATE_ED_KEY_FILE" ]] || {
    echo "Sparkle private key file not found: $SPARKLE_PRIVATE_ED_KEY_FILE" >&2
    exit 1
  }
fi

BUILD_CONFIGURATION=release \
APP_VERSION="$VERSION" \
APP_BUILD="$BUILD_NUMBER" \
BUNDLE_IDENTIFIER="$BUNDLE_IDENTIFIER" \
MINIMUM_SYSTEM_VERSION="$MINIMUM_SYSTEM_VERSION" \
SPARKLE_FEED_URL="$APPCAST_URL" \
SPARKLE_PUBLIC_ED_KEY="$SPARKLE_PUBLIC_ED_KEY" \
"$ROOT/scripts/package-app.sh"

ZIP_PATH="$DIST_DIR/${APP_NAME}-${VERSION}+${BUILD_NUMBER}-macos.zip"
rm -f "$ZIP_PATH"

if [[ "$SKIP_SIGN" == false ]]; then
  while IFS= read -r framework; do
    /usr/bin/codesign \
      --force \
      --timestamp \
      --sign "$IDENTITY" \
      "$framework"
  done < <(find "$FRAMEWORKS_DIR" -maxdepth 1 -type d -name '*.framework' | sort)

  /usr/bin/codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --entitlements "$ENTITLEMENTS_PATH" \
    --sign "$IDENTITY" \
    "$APP_PATH"

  /usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_PATH"
  /usr/sbin/spctl -a -t exec -vv "$APP_PATH"
fi

/usr/bin/ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

if [[ "$SKIP_NOTARIZE" == false ]]; then
  /usr/bin/xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  /usr/bin/xcrun stapler staple "$APP_PATH"
  /usr/bin/xcrun stapler validate "$APP_PATH"
  rm -f "$ZIP_PATH"
  /usr/bin/ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
fi

RELEASE_NOTES_FILE=""
if [[ -n "$RELEASE_NOTES_MARKDOWN" ]]; then
  mkdir -p "$RELEASE_NOTES_OUTPUT_DIR"
  RELEASE_NOTES_FILE="$RELEASE_NOTES_OUTPUT_DIR/${VERSION}.html"
  python3 "$ROOT/scripts/generate-release-notes.py" \
    --input "$RELEASE_NOTES_MARKDOWN" \
    --output "$RELEASE_NOTES_FILE" \
    --title "Codex Lobster Island ${VERSION}"
  if [[ -z "$RELEASE_NOTES_URL" && -n "$DOWNLOAD_BASE_URL" ]]; then
    RELEASE_NOTES_URL="${DOWNLOAD_BASE_URL%/}/release-notes/${VERSION}.html"
  fi
fi

if [[ -n "$SPARKLE_PRIVATE_ED_KEY_FILE" ]]; then
  if [[ -z "$SPARKLE_ED_SIGNATURE" ]]; then
    SPARKLE_ED_SIGNATURE="$("$ROOT/.build/artifacts/sparkle/Sparkle/bin/sign_update" -p --ed-key-file "$SPARKLE_PRIVATE_ED_KEY_FILE" "$ZIP_PATH")"
  fi
  if [[ -n "$RELEASE_NOTES_FILE" && -z "$RELEASE_NOTES_ED_SIGNATURE" ]]; then
    RELEASE_NOTES_ED_SIGNATURE="$("$ROOT/.build/artifacts/sparkle/Sparkle/bin/sign_update" -p --ed-key-file "$SPARKLE_PRIVATE_ED_KEY_FILE" --disable-signing-warning "$RELEASE_NOTES_FILE")"
  fi
fi

if [[ -n "$DOWNLOAD_BASE_URL" || -n "$APPCAST_URL" || -n "$RELEASE_NOTES_URL" || -n "$SPARKLE_ED_SIGNATURE" ]]; then
  if [[ -z "$DOWNLOAD_BASE_URL" || -z "$APPCAST_URL" ]]; then
    echo "Generating release feed requires both --download-base-url and --appcast-url." >&2
    exit 1
  fi

  python3 "$ROOT/scripts/generate-release-feed.py" \
    --archive "$ZIP_PATH" \
    --version "$VERSION" \
    --build "$BUILD_NUMBER" \
    --download-base-url "$DOWNLOAD_BASE_URL" \
    --appcast-url "$APPCAST_URL" \
    --output-dir "$FEED_OUTPUT_DIR" \
    --minimum-system "$MINIMUM_SYSTEM_VERSION" \
    ${RELEASE_NOTES_FILE:+--release-notes-file "$RELEASE_NOTES_FILE"} \
    ${RELEASE_NOTES_ED_SIGNATURE:+--release-notes-ed-signature "$RELEASE_NOTES_ED_SIGNATURE"} \
    ${RELEASE_NOTES_URL:+--release-notes-url "$RELEASE_NOTES_URL"} \
    ${SPARKLE_ED_SIGNATURE:+--ed-signature "$SPARKLE_ED_SIGNATURE"}

  if [[ -n "$SPARKLE_PRIVATE_ED_KEY_FILE" ]]; then
    "$ROOT/.build/artifacts/sparkle/Sparkle/bin/sign_update" \
      --ed-key-file "$SPARKLE_PRIVATE_ED_KEY_FILE" \
      --disable-signing-warning \
      "$FEED_OUTPUT_DIR/appcast.xml" >/dev/null

    python3 "$ROOT/scripts/generate-release-feed.py" \
      --archive "$ZIP_PATH" \
      --version "$VERSION" \
      --build "$BUILD_NUMBER" \
      --download-base-url "$DOWNLOAD_BASE_URL" \
      --appcast-url "$APPCAST_URL" \
      --output-dir "$FEED_OUTPUT_DIR" \
      --minimum-system "$MINIMUM_SYSTEM_VERSION" \
      --appcast-signature-embedded \
      ${RELEASE_NOTES_FILE:+--release-notes-file "$RELEASE_NOTES_FILE"} \
      ${RELEASE_NOTES_ED_SIGNATURE:+--release-notes-ed-signature "$RELEASE_NOTES_ED_SIGNATURE"} \
      ${RELEASE_NOTES_URL:+--release-notes-url "$RELEASE_NOTES_URL"} \
      ${SPARKLE_ED_SIGNATURE:+--ed-signature "$SPARKLE_ED_SIGNATURE"}
  fi
fi

echo "Release app: $APP_PATH"
echo "Release archive: $ZIP_PATH"
if [[ "$SKIP_SIGN" == false ]]; then
  echo "Signed with: $IDENTITY"
fi
if [[ "$SKIP_NOTARIZE" == false ]]; then
  echo "Notarized with profile: $NOTARY_PROFILE"
fi
if [[ -n "$DOWNLOAD_BASE_URL" && -n "$APPCAST_URL" ]]; then
  echo "Release feed: $FEED_OUTPUT_DIR/appcast.xml"
  echo "Release metadata: $FEED_OUTPUT_DIR/release-metadata.json"
fi
if [[ -n "$RELEASE_NOTES_FILE" ]]; then
  echo "Release notes: $RELEASE_NOTES_FILE"
fi
