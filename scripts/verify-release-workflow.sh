#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/release.yml"

grep -q 'SPARKLE_PRIVATE_ED_KEY' "$WORKFLOW"
grep -q 'release-notes' "$WORKFLOW"
grep -q 'dist/release-notes/' "$WORKFLOW"

echo "verify-release-workflow passed"
