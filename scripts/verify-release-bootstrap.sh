#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
README="$ROOT/README.md"

[[ -f "$ROOT/scripts/import-developer-id-certificate.sh" ]]
[[ -f "$ROOT/scripts/store-notary-profile.sh" ]]

grep -q 'import-developer-id-certificate.sh' "$README"
grep -q 'store-notary-profile.sh' "$README"

echo "verify-release-bootstrap passed"
