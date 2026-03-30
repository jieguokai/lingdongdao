# Codex Lobster Island

Codex Lobster Island is a native macOS floating status island plus menu bar utility for visualizing Codex work state.

## Run

```bash
./scripts/run-app.sh
```

## Package as .app

```bash
./scripts/package-app.sh
open dist/CodexLobsterIsland.app
```

## Current status sources

- `Mock`: built-in demo flow
- `Process Watcher`: placeholder for future local-process integration
- `Log Parser`: placeholder for future log-driven integration
- `Socket Event`: placeholder for future event-stream integration

## Notes

- Launch at login is best-effort when running from `swift run`.
- For stable launch-at-login registration, use the packaged `.app` bundle from `scripts/package-app.sh`.
