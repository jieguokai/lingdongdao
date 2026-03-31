#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$(mktemp -d)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$DIST_DIR" "$TMP_DIR"' EXIT

KEY_INFO="$(swift -e 'import CryptoKit; let key = Curve25519.Signing.PrivateKey(); print(key.rawRepresentation.base64EncodedString()); print(key.publicKey.rawRepresentation.base64EncodedString())')"
PRIVATE_KEY="$(printf '%s\n' "$KEY_INFO" | sed -n '1p')"
PUBLIC_KEY="$(printf '%s\n' "$KEY_INFO" | sed -n '2p')"
PRIVATE_KEY_FILE="$TMP_DIR/private-ed25519.key"
NOTES_MD="$TMP_DIR/release-notes.md"

printf '%s\n' "$PRIVATE_KEY" > "$PRIVATE_KEY_FILE"
cat > "$NOTES_MD" <<'EOF'
# Codex Lobster Island 0.1.0

- Added Sparkle updater integration
- Added signed appcast generation
- Improved release packaging
EOF

DIST_DIR="$DIST_DIR" \
SPARKLE_PUBLIC_ED_KEY="$PUBLIC_KEY" \
"$ROOT/scripts/release-app.sh" \
  --skip-sign \
  --skip-notarize \
  --version 0.1.0 \
  --build 1 \
  --download-base-url "https://downloads.example.com/codex-lobster-island" \
  --appcast-url "https://downloads.example.com/codex-lobster-island/appcast.xml" \
  --release-notes-markdown "$NOTES_MD" \
  --sparkle-private-ed-key-file "$PRIVATE_KEY_FILE"

[[ -f "$DIST_DIR/release-notes/0.1.0.html" ]]
[[ -f "$DIST_DIR/feed/appcast.xml" ]]
[[ -f "$DIST_DIR/feed/release-metadata.json" ]]
[[ -f "$ROOT/scripts/publish-github-release.sh" ]]

python3 - <<'PY' "$DIST_DIR/feed/appcast.xml" "$DIST_DIR/feed/release-metadata.json"
import json
import pathlib
import sys
import xml.etree.ElementTree as ET

SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ns = {"sparkle": SPARKLE_NS}

appcast_path = pathlib.Path(sys.argv[1])
metadata_path = pathlib.Path(sys.argv[2])
metadata = json.loads(metadata_path.read_text(encoding="utf-8"))

assert metadata["archive"]["sparkle_ed_signature"]
assert metadata["release_notes"]["sparkle_ed_signature"]
assert metadata["release_notes"]["filename"] == "0.1.0.html"

tree = ET.parse(appcast_path)
item = tree.getroot().find("./channel/item")
assert item is not None
enclosure = item.find("enclosure")
assert enclosure is not None
assert enclosure.attrib[f"{{{SPARKLE_NS}}}edSignature"]
release_notes = item.find(f"{{{SPARKLE_NS}}}releaseNotesLink")
assert release_notes is not None
assert release_notes.attrib[f"{{{SPARKLE_NS}}}edSignature"]
assert release_notes.attrib["length"]
print("verify-release-publishing passed")
PY
