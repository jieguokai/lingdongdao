#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/release.yml"

[[ -f "$ROOT/Config/Release/release.env.example" ]]
[[ -f "$ROOT/scripts/print-release-secrets-template.sh" ]]

grep -q 'Validate release configuration' "$WORKFLOW"
grep -q 'APPLE_DEVELOPER_ID_P12_BASE64' "$WORKFLOW"
grep -q 'DOWNLOAD_BASE_URL' "$WORKFLOW"
grep -q 'APPCAST_URL' "$WORKFLOW"

echo "verify-release-preflight passed"
