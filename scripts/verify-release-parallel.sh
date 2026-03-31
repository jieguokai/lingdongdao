#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

run_and_capture() {
  local name="$1"
  shift
  (
    "$@"
  ) >"$TMP_DIR/$name.out" 2>&1
}

run_and_capture release-pipeline "$ROOT/scripts/verify-release-pipeline.sh" &
PID_ONE=$!
run_and_capture release-feed "$ROOT/scripts/verify-release-feed.sh" &
PID_TWO=$!

wait "$PID_ONE"
wait "$PID_TWO"

cat "$TMP_DIR/release-pipeline.out"
cat "$TMP_DIR/release-feed.out"

echo "verify-release-parallel passed"
