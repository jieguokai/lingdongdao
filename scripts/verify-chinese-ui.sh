#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

patterns=(
  'Hide Island'
  'Show Island'
  'Mute Sounds'
  'Enable Animations'
  'Launch at Login'
  'Status Source'
  'Copy Source Info'
  'Next Mock State'
  'Refresh Source'
  'Clear History'
  'Set Mock State'
  'Settings…'
  'Quit Codex Lobster Island'
  'Preview'
  'Behavior'
  'Show floating island'
  'Enable animations'
  'Mute sounds'
  'Launch at login'
  'Provider'
  'Active Source'
  'Connection'
  'Refresh Current Source'
  'Mock State Controls'
  'Advance to Next Mock State'
  'History'
  'Recent States'
  'Source'
  'Idle'
  'Running'
  'Success'
  'Error'
  'Calm breathing'
  'Looping motion'
  'Celebration ping'
  'Warning shake'
  'Mock'
  'Process Watcher'
  'Log Parser'
  'Socket Event'
)

>"${TMPDIR:-/tmp}/codex-lobster-ui-english.txt"

for pattern in "${patterns[@]}"; do
  if rg -n -F "\"$pattern\"" Sources/CodexLobsterIsland >>"${TMPDIR:-/tmp}/codex-lobster-ui-english.txt"; then
    :
  fi
done

if [[ -s "${TMPDIR:-/tmp}/codex-lobster-ui-english.txt" ]]; then
  echo "Found remaining English UI strings:"
  cat "${TMPDIR:-/tmp}/codex-lobster-ui-english.txt"
  exit 1
fi

echo "No tracked English UI strings found."
