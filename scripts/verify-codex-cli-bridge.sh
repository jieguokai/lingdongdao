#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

grep -q 'case \.codexCLI' "$ROOT/Sources/CodexLobsterIsland/Domain/CodexProviderKind.swift"
grep -q 'CodexCLIBridgeProvider' "$ROOT/Sources/CodexLobsterIsland/Services/CodexProviderFactory.swift"
[[ -f "$ROOT/Sources/CodexLobsterIsland/Services/CodexCLIBridgeProvider.swift" ]]
[[ -f "$ROOT/scripts/codex-bridge.py" ]]
[[ -f "$ROOT/scripts/codex-island.sh" ]]
grep -q 'Codex CLI Bridge' "$ROOT/README.md"

TMP_DIR="$(mktemp -d)"
PORT=45631
LOG_FILE="$TMP_DIR/codex-events.jsonl"
ACTION_DIR="$TMP_DIR/actions"
CAPTURE_FILE="$TMP_DIR/socket-lines.txt"
CAPTURE_FILE_WRAPPER="$TMP_DIR/socket-lines-wrapper.txt"
FAKE_CODEX="$TMP_DIR/fake-codex.sh"
ARGS_FILE="$TMP_DIR/fake-codex-args.txt"
APPROVAL_CAPTURE="$TMP_DIR/approval-input.txt"

cleanup() {
  kill "${LISTENER_PID:-}" 2>/dev/null || true
  kill "${BRIDGE_PID:-}" 2>/dev/null || true
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cat > "$FAKE_CODEX" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "${FAKE_CODEX_ARGS_FILE:-/dev/null}"

if [[ " $* " != *" --json "* ]]; then
  echo "fake codex running"
  exit 0
fi

printf '%s\n' '{"type":"thread.started","thread_id":"native-thread-123"}'
printf '%s\n' '{"type":"turn.started"}'
printf '%s\n' '{"type":"error","message":"Reconnecting... retrying websocket"}'

if [[ "${FAKE_CODEX_REQUIRE_APPROVAL:-0}" == "1" ]]; then
  printf '%s\n' '{"type":"approval.required","reason":"需要确认是否继续修改文件","actions":[{"id":"approve","label":"继续","role":"approve","actionPayload":"{\"decision\":\"approve\"}"},{"id":"reject","label":"取消","role":"reject","actionPayload":"{\"decision\":\"reject\"}"}]}'
  IFS= read -r approval_line
  printf '%s\n' "$approval_line" > "${FAKE_CODEX_APPROVAL_CAPTURE:-/dev/null}"
  if [[ "$approval_line" == *'"approve"'* ]]; then
    printf '%s\n' '{"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"Native bridge reply"}}'
    printf '%s\n' '{"type":"turn.completed","usage":{"input_tokens":12,"output_tokens":7}}'
    exit 0
  fi
  printf '%s\n' '{"type":"error","message":"Approval rejected by user"}'
  exit 2
fi

printf '%s\n' '{"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"Native bridge reply"}}'
printf '%s\n' '{"type":"turn.completed","usage":{"input_tokens":12,"output_tokens":7}}'
exit 0
EOF
chmod +x "$FAKE_CODEX"

start_listener() {
  local capture_path="$1"
  python3 - "$PORT" "$capture_path" <<'PY' &
import socket
import sys
import time

port = int(sys.argv[1])
capture_path = sys.argv[2]

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("127.0.0.1", port))
server.listen(8)
server.settimeout(0.5)
data = b""
end = time.time() + 8
while time.time() < end:
    try:
        conn, _ = server.accept()
    except socket.timeout:
        continue
    while True:
        chunk = conn.recv(4096)
        if not chunk:
            break
        data += chunk
    conn.close()
server.close()
with open(capture_path, "wb") as handle:
    handle.write(data)
PY
  LISTENER_PID=$!
  sleep 0.2
}

wait_for_log_text() {
  local needle="$1"
  for _ in {1..50}; do
    if [[ -f "$LOG_FILE" ]] && grep -q "$needle" "$LOG_FILE"; then
      return 0
    fi
    sleep 0.1
  done
  echo "Timed out waiting for $needle in bridge log" >&2
  return 1
}

start_listener "$CAPTURE_FILE"

CODEX_LOBSTER_CODEX_BIN="$FAKE_CODEX" \
CODEX_LOBSTER_BRIDGE_PORT="$PORT" \
CODEX_LOBSTER_BRIDGE_LOG_PATH="$LOG_FILE" \
CODEX_LOBSTER_BRIDGE_ACTION_DIR="$ACTION_DIR" \
FAKE_CODEX_ARGS_FILE="$ARGS_FILE" \
FAKE_CODEX_REQUIRE_APPROVAL=1 \
FAKE_CODEX_APPROVAL_CAPTURE="$APPROVAL_CAPTURE" \
python3 "$ROOT/scripts/codex-bridge.py" exec "hello from codex bridge" >/dev/null &
BRIDGE_PID=$!

wait_for_log_text '"state":"awaiting_approval"'
mkdir -p "$ACTION_DIR"
printf '%s\n' '{"id":"approve","label":"继续","role":"approve","actionPayload":"{\"decision\":\"approve\"}"}' > "$ACTION_DIR/native-thread-123.jsonl"

wait "$BRIDGE_PID"
BRIDGE_PID=
wait "$LISTENER_PID"
LISTENER_PID=

test -f "$LOG_FILE"
test -f "$APPROVAL_CAPTURE"
grep -q '"decision":"approve"' "$APPROVAL_CAPTURE"
grep -q '"state":"typing"' "$LOG_FILE"
grep -q '"phase":"typing"' "$LOG_FILE"
grep -q '"state":"awaiting_approval"' "$LOG_FILE"
grep -q '"approvalReason":"需要确认是否继续修改文件"' "$LOG_FILE"
grep -q '"approvalActions":' "$LOG_FILE"
grep -q '"state":"success"' "$LOG_FILE"
grep -q '"command":"exec"' "$LOG_FILE"
grep -q '"source":"codex-cli-bridge"' "$LOG_FILE"
grep -q '"sessionId":"native-thread-123"' "$LOG_FILE"
grep -q '"phase":"completed"' "$LOG_FILE"
grep -q '"responsePreview":"Native bridge reply"' "$LOG_FILE"
grep -q '"usageSummary":"tokens in 12 · out 7"' "$LOG_FILE"
grep -q '"errorSummary":"Reconnecting... retrying websocket"' "$LOG_FILE"
grep -q '"detail":"hello from codex bridge · Native bridge reply · tokens in 12 · out 7"' "$LOG_FILE"
grep -q '"state":"typing"' "$CAPTURE_FILE"
grep -q '"state":"awaiting_approval"' "$CAPTURE_FILE"
grep -q '"approvalReason":"需要确认是否继续修改文件"' "$CAPTURE_FILE"
grep -q '"state":"success"' "$CAPTURE_FILE"
grep -q '"command":"exec"' "$CAPTURE_FILE"
grep -q '"sessionId":"native-thread-123"' "$CAPTURE_FILE"
grep -q '"phase":"thread_started"' "$CAPTURE_FILE"
grep -q '"title":"Codex 会话已建立"' "$CAPTURE_FILE"
grep -q '"detail":"线程 native-thread-123 · hello from codex bridge"' "$CAPTURE_FILE"
grep -q '"phase":"reconnecting"' "$CAPTURE_FILE"
grep -q '"errorSummary":"Reconnecting... retrying websocket"' "$CAPTURE_FILE"
grep -q '"title":"Codex 回合已完成"' "$CAPTURE_FILE"
grep -q '"phase":"turn_completed"' "$CAPTURE_FILE"

start_listener "$CAPTURE_FILE_WRAPPER"

CODEX_LOBSTER_CODEX_BIN="$FAKE_CODEX" \
CODEX_LOBSTER_BRIDGE_PORT="$PORT" \
CODEX_LOBSTER_BRIDGE_LOG_PATH="$LOG_FILE" \
CODEX_LOBSTER_SESSION_ID="bridge-wrapper-session" \
FAKE_CODEX_REQUIRE_APPROVAL=0 \
"$ROOT/scripts/codex-island.sh" exec "hello from shell wrapper" >/dev/null

wait "$LISTENER_PID"
LISTENER_PID=
grep -q '"detail":"hello from shell wrapper"' "$CAPTURE_FILE_WRAPPER"
grep -q '"sessionId":"bridge-wrapper-session"' "$CAPTURE_FILE_WRAPPER"

CODEX_LOBSTER_CODEX_BIN="$FAKE_CODEX" \
CODEX_LOBSTER_BRIDGE_LOG_PATH="$LOG_FILE" \
CODEX_LOBSTER_SESSION_ID="bridge-resume-session" \
FAKE_CODEX_ARGS_FILE="$ARGS_FILE" \
FAKE_CODEX_REQUIRE_APPROVAL=0 \
python3 "$ROOT/scripts/codex-bridge.py" resume "session-123" "follow up task" >/dev/null

grep -q '"command":"resume"' "$LOG_FILE"
grep -q '"phase":"completed"' "$LOG_FILE"
grep -q '"responsePreview":"Native bridge reply"' "$LOG_FILE"
grep -q '"usageSummary":"tokens in 12 · out 7"' "$LOG_FILE"
grep -q '"errorSummary":"Reconnecting... retrying websocket"' "$LOG_FILE"
grep -q '"detail":"恢复会话 session-123 · follow up task · Native bridge reply · tokens in 12 · out 7"' "$LOG_FILE"

CODEX_LOBSTER_CODEX_BIN="$FAKE_CODEX" \
CODEX_LOBSTER_BRIDGE_LOG_PATH="$LOG_FILE" \
FAKE_CODEX_ARGS_FILE="$ARGS_FILE" \
FAKE_CODEX_REQUIRE_APPROVAL=0 \
python3 "$ROOT/scripts/codex-bridge.py" review "target.swift" >/dev/null

grep -q '"command":"review"' "$LOG_FILE"
grep -q '"title":"Codex 审查已完成"' "$LOG_FILE"
grep -q '"phase":"completed"' "$LOG_FILE"
grep -q '"responsePreview":"Native bridge reply"' "$LOG_FILE"
grep -q '"usageSummary":"tokens in 12 · out 7"' "$LOG_FILE"
grep -q '"errorSummary":"Reconnecting... retrying websocket"' "$LOG_FILE"
grep -q '"detail":"审查 target.swift · Native bridge reply · tokens in 12 · out 7"' "$LOG_FILE"
grep -Eq '^-C .+ exec review --json target.swift$' "$ARGS_FILE"

echo "verify-codex-cli-bridge passed"
