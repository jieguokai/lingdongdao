#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/release.yml"

[[ -f "$ROOT/scripts/release-doctor.sh" ]]

grep -q 'action-gh-release' "$WORKFLOW"
grep -q 'dist/release-notes/' "$WORKFLOW"
grep -q 'dist/feed/' "$WORKFLOW"

echo "verify-release-automation passed"
