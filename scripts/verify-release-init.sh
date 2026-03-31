#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
README="$ROOT/README.md"

[[ -f "$ROOT/scripts/init-release-env.sh" ]]

grep -q 'init-release-env.sh' "$README"

echo "verify-release-init passed"
