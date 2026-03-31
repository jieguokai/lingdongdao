#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
README="$ROOT/README.md"

[[ -f "$ROOT/scripts/generate-sparkle-keys.sh" ]]
[[ -f "$ROOT/scripts/export-release-secrets.sh" ]]

grep -q 'generate-sparkle-keys.sh' "$README"
grep -q 'export-release-secrets.sh' "$README"

echo "verify-release-credential-tools passed"
