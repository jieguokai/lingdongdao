#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

[[ -f "$ROOT/.gitignore" ]]
[[ -f "$ROOT/LICENSE" ]]

grep -q '^\.build/$' "$ROOT/.gitignore"
grep -q '^dist/$' "$ROOT/.gitignore"
grep -q '^\.DS_Store$' "$ROOT/.gitignore"

if git -C "$ROOT" ls-files | rg -q '^(\.build/|dist/|\.DS_Store$)'; then
  echo "tracked build artifacts still present" >&2
  exit 1
fi

echo "verify-open-source-ready passed"
