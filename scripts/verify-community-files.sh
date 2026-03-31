#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

[[ -f "$ROOT/CODE_OF_CONDUCT.md" ]]
[[ -f "$ROOT/.github/ISSUE_TEMPLATE/bug_report.md" ]]
[[ -f "$ROOT/.github/ISSUE_TEMPLATE/feature_request.md" ]]
[[ -f "$ROOT/.github/pull_request_template.md" ]]

grep -q 'Code of Conduct' "$ROOT/README.md"

echo "verify-community-files passed"
