#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$(mktemp -d)"
FEED_DIR="$DIST_DIR/feed"
ZIP_PATH="$DIST_DIR/CodexLobsterIsland-0.1.0+1-macos.zip"

trap 'rm -rf "$DIST_DIR"' EXIT

DIST_DIR="$DIST_DIR" \
"$ROOT/scripts/release-app.sh" \
  --skip-sign \
  --skip-notarize \
  --version 0.1.0 \
  --build 1 \
  --download-base-url "https://downloads.example.com/codex-lobster-island" \
  --appcast-url "https://downloads.example.com/codex-lobster-island/appcast.xml" \
  --release-notes-url "https://downloads.example.com/codex-lobster-island/release-notes/0.1.0.html" \
  --sparkle-public-ed-key "test-public-key" \
  --feed-output-dir "$FEED_DIR"

[[ -f "$FEED_DIR/appcast.xml" ]]
[[ -f "$FEED_DIR/release-metadata.json" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :SUFeedURL' "$DIST_DIR/CodexLobsterIsland.app/Contents/Info.plist")" == "https://downloads.example.com/codex-lobster-island/appcast.xml" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$DIST_DIR/CodexLobsterIsland.app/Contents/Info.plist")" == "test-public-key" ]]

python3 - <<'PY' "$FEED_DIR/appcast.xml" "$FEED_DIR/release-metadata.json" "$ZIP_PATH"
import json
import pathlib
import sys
from urllib.parse import unquote
import xml.etree.ElementTree as ET

appcast_path = pathlib.Path(sys.argv[1])
metadata_path = pathlib.Path(sys.argv[2])
zip_path = pathlib.Path(sys.argv[3])

metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
assert metadata["version"] == "0.1.0"
assert metadata["build"] == "1"
assert metadata["archive"]["filename"] == zip_path.name
assert metadata["archive"]["size"] == zip_path.stat().st_size

ns = {"sparkle": "http://www.andymatuschak.org/xml-namespaces/sparkle"}
tree = ET.parse(appcast_path)
item = tree.getroot().find("./channel/item")
assert item is not None
assert item.findtext("{http://www.andymatuschak.org/xml-namespaces/sparkle}version") == "1"
assert item.findtext("{http://www.andymatuschak.org/xml-namespaces/sparkle}shortVersionString") == "0.1.0"
assert item.findtext("{http://www.andymatuschak.org/xml-namespaces/sparkle}minimumSystemVersion") == "14.0"
enclosure = item.find("enclosure")
assert enclosure is not None
assert unquote(enclosure.attrib["url"]).endswith(zip_path.name)
assert enclosure.attrib["length"] == str(zip_path.stat().st_size)
assert item.findtext("{http://www.andymatuschak.org/xml-namespaces/sparkle}releaseNotesLink") == "https://downloads.example.com/codex-lobster-island/release-notes/0.1.0.html"
print("verify-release-feed passed")
PY
