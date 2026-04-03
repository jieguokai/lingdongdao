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
CAPTURE_FILE="$TMP_DIR/socket-lines.txt"
FAKE_CODEX="$TMP_DIR/fake-codex.sh"
ARGS_FILE="$TMP_DIR/fake-codex-args.txt"

cat > "$FAKE_CODEX" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${FAKE_CODEX_ARGS_FILE:-/dev/null}"
if [[ " $* " == *" --json "* ]]; then
  printf '%s\n' '{"type":"thread.started","thread_id":"native-thread-123"}'
  printf '%s\n' '{"type":"turn.started"}'
  printf '%s\n' '{"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"Native bridge reply"}}'
  printf '%s\n' '{"type":"turn.completed","usage":{"input_tokens":12,"output_tokens":7}}'
else
  echo "fake codex running"
fi
exit 0
EOF
chmod +x "$FAKE_CODEX"

python3 - "$PORT" "$CAPTURE_FILE" <<'PY' &
import socket
import sys
import time

port = int(sys.argv[1])
capture_path = sys.argv[2]

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("127.0.0.1", port))
data = b""
server.listen(2)
server.settimeout(0.5)
end = time.time() + 5
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
trap 'kill $LISTENER_PID 2>/dev/null || true; rm -rf "$TMP_DIR"' EXIT
sleep 0.2

CODEX_LOBSTER_CODEX_BIN="$FAKE_CODEX" \
CODEX_LOBSTER_BRIDGE_PORT="$PORT" \
CODEX_LOBSTER_BRIDGE_LOG_PATH="$LOG_FILE" \
FAKE_CODEX_ARGS_FILE="$ARGS_FILE" \
python3 "$ROOT/scripts/codex-bridge.py" exec "hello from codex bridge" >/dev/null

wait "$LISTENER_PID"

test -f "$LOG_FILE"
grep -q '"state":"running"' "$LOG_FILE"
grep -q '"state":"success"' "$LOG_FILE"
grep -q '"command":"exec"' "$LOG_FILE"
grep -q '"source":"codex-cli-bridge"' "$LOG_FILE"
grep -q '"sessionId":"native-thread-123"' "$LOG_FILE"
grep -q '"responsePreview":"Native bridge reply"' "$LOG_FILE"
grep -q '"usageSummary":"tokens in 12 · out 7"' "$LOG_FILE"
grep -q '"detail":"hello from codex bridge · Native bridge reply · tokens in 12 · out 7"' "$LOG_FILE"
grep -q '"state":"running"' "$CAPTURE_FILE"
grep -q '"state":"success"' "$CAPTURE_FILE"
grep -q '"command":"exec"' "$CAPTURE_FILE"
grep -q '"sessionId":"native-thread-123"' "$CAPTURE_FILE"
grep -q '"title":"Codex 会话已建立"' "$CAPTURE_FILE"
grep -q '"detail":"线程 native-thread-123 · hello from codex bridge"' "$CAPTURE_FILE"
grep -q '"title":"Codex 回合已完成"' "$CAPTURE_FILE"
grep -q '"detail":"hello from codex bridge · Native bridge reply · tokens in 12 · out 7"' "$CAPTURE_FILE"

CAPTURE_FILE_WRAPPER="$TMP_DIR/socket-lines-wrapper.txt"
python3 - "$PORT" "$CAPTURE_FILE_WRAPPER" <<'PY' &
import socket
import sys
import time

port = int(sys.argv[1])
capture_path = sys.argv[2]

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("127.0.0.1", port))
server.listen(2)
server.settimeout(0.5)
data = b""
end = time.time() + 5
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

CODEX_LOBSTER_CODEX_BIN="$FAKE_CODEX" \
CODEX_LOBSTER_BRIDGE_PORT="$PORT" \
CODEX_LOBSTER_BRIDGE_LOG_PATH="$LOG_FILE" \
CODEX_LOBSTER_SESSION_ID="bridge-wrapper-session" \
"$ROOT/scripts/codex-island.sh" exec "hello from shell wrapper" >/dev/null

wait "$LISTENER_PID"
grep -q '"detail":"hello from shell wrapper"' "$CAPTURE_FILE_WRAPPER"
grep -q '"sessionId":"bridge-wrapper-session"' "$CAPTURE_FILE_WRAPPER"

CODEX_LOBSTER_CODEX_BIN="$FAKE_CODEX" \
CODEX_LOBSTER_BRIDGE_LOG_PATH="$LOG_FILE" \
CODEX_LOBSTER_SESSION_ID="bridge-resume-session" \
FAKE_CODEX_ARGS_FILE="$ARGS_FILE" \
python3 "$ROOT/scripts/codex-bridge.py" resume "session-123" "follow up task" >/dev/null

grep -q '"command":"resume"' "$LOG_FILE"
grep -q '"responsePreview":"Native bridge reply"' "$LOG_FILE"
grep -q '"usageSummary":"tokens in 12 · out 7"' "$LOG_FILE"
grep -q '"detail":"恢复会话 session-123 · follow up task · Native bridge reply · tokens in 12 · out 7"' "$LOG_FILE"

CODEX_LOBSTER_CODEX_BIN="$FAKE_CODEX" \
CODEX_LOBSTER_BRIDGE_LOG_PATH="$LOG_FILE" \
FAKE_CODEX_ARGS_FILE="$ARGS_FILE" \
python3 "$ROOT/scripts/codex-bridge.py" review "target.swift" >/dev/null

grep -q '"command":"review"' "$LOG_FILE"
grep -q '"title":"Codex 审查已完成"' "$LOG_FILE"
grep -q '"responsePreview":"Native bridge reply"' "$LOG_FILE"
grep -q '"usageSummary":"tokens in 12 · out 7"' "$LOG_FILE"
grep -q '"detail":"审查 target.swift · Native bridge reply · tokens in 12 · out 7"' "$LOG_FILE"
grep -q '^exec review --json target.swift$' "$ARGS_FILE"

echo "verify-codex-cli-bridge passed"
