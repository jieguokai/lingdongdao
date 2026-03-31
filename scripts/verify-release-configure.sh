#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
README="$ROOT/README.md"

[[ -f "$ROOT/scripts/configure-release-env.sh" ]]

grep -q 'configure-release-env.sh' "$README"

echo "verify-release-configure passed"
