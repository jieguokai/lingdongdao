# Codex Lobster Island

Codex Lobster Island is a native macOS floating status island plus menu bar utility for visualizing Codex work state.

## Run

```bash
./scripts/run-app.sh
```

## Send test events

```bash
python3 ./scripts/send-socket-event.py --state running --title "Apply patch" --detail "Editing Swift files"
python3 ./scripts/append-log-event.py --state success --title "Build done" --detail "Latest task completed"
```

## Package as .app

```bash
./scripts/package-app.sh
open dist/CodexLobsterIsland.app
```

## Current status sources

- `Mock`: built-in demo flow
- `Process Watcher`: watches local `codex` processes via `pgrep -fal codex`
- `Log Parser`: reads the latest structured event from a local log file
- `Socket Event`: listens for newline-delimited JSON events over local TCP

## Environment overrides

- `CODEX_LOBSTER_PROVIDER_KIND=mock|processWatcher|logParser|socketEvent`
- `CODEX_LOBSTER_LOG_PATH=/absolute/path/to/codex-status.log`
- `CODEX_LOBSTER_SOCKET_PORT=45540`

## Log parser format

`Log Parser` reads the last non-empty line of the configured file. Preferred format is JSONL:

```json
{"state":"running","title":"Build project","detail":"Compiling sources","timestamp":"2026-03-30T08:15:30Z"}
```

Supported states:

- `idle`
- `running`
- `success`
- `error`

## Socket event format

`Socket Event` listens on `127.0.0.1:$CODEX_LOBSTER_SOCKET_PORT` and expects one JSON object per line:

```json
{"state":"success","title":"Task finished","detail":"Codex completed the current job","timestamp":"2026-03-30T08:20:30Z"}
```

Example sender:

```bash
printf '%s\n' '{"state":"running","title":"Apply patch","detail":"Updating Swift files","timestamp":"2026-03-30T08:20:30Z"}' | nc 127.0.0.1 45540
```

## Notes

- Launch at login is best-effort when running from `swift run`.
- For stable launch-at-login registration, use the packaged `.app` bundle from `scripts/package-app.sh`.
