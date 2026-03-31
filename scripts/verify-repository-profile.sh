#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

[[ -f "$ROOT/.github/ISSUE_TEMPLATE/config.yml" ]]
[[ -f "$ROOT/docs/github-repository-profile.md" ]]

grep -q 'GitHub Repository Profile' "$ROOT/docs/github-repository-profile.md"
grep -q 'blank_issues_enabled: false' "$ROOT/.github/ISSUE_TEMPLATE/config.yml"

echo "verify-repository-profile passed"
