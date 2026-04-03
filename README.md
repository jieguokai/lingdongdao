# Codex Lobster Island

Codex Lobster Island is a native macOS floating status island plus menu bar utility for visualizing Codex work state.

## Open Source

This repository is intended for public development and distribution. Build artifacts, packaged apps, private release credentials, and local machine state are excluded from version control.

Project docs:

- [License](/Users/kevin/Documents/01_开发项目/lingdongdao/LICENSE)
- [Code of Conduct](/Users/kevin/Documents/01_开发项目/lingdongdao/CODE_OF_CONDUCT.md)
- [Contributing](/Users/kevin/Documents/01_开发项目/lingdongdao/CONTRIBUTING.md)
- [Security](/Users/kevin/Documents/01_开发项目/lingdongdao/SECURITY.md)
- [GitHub Profile Suggestions](/Users/kevin/Documents/01_开发项目/lingdongdao/docs/github-repository-profile.md)

## Run

```bash
./scripts/run-app.sh
```

默认状态来源现在是 `codexCLI`。如果你希望浮窗跟着真实 Codex 状态变化，必须通过 bridge 启动 Codex，而不是直接调用 `codex`。

## Send test events

```bash
python3 ./scripts/send-socket-event.py --state running --title "Apply patch" --detail "Editing Swift files"
python3 ./scripts/append-log-event.py --state success --title "Build done" --detail "Latest task completed"
```

## Codex CLI Bridge

`Codex CLI Bridge` is the first real Codex integration path in this project. It wraps the actual `codex` CLI, prefers native JSON events when available, and feeds them back into the app through the existing local bridge.

Run the app against the bridge provider:

```bash
CODEX_LOBSTER_PROVIDER_KIND=codexCLI ./scripts/run-app.sh
```

Recommended local workflow:

1. Start the app with `CODEX_LOBSTER_PROVIDER_KIND=codexCLI`.
2. Run Codex through `./scripts/codex-island.sh ...` instead of calling `codex` directly.
3. If you need to diagnose a failed run, copy the latest session diagnostics from the menu bar or Settings panel.

Then run Codex through the bridge:

```bash
python3 ./scripts/codex-bridge.py exec "summarize the current repo"
```

Or use the shell wrapper:

```bash
./scripts/codex-island.sh exec "summarize the current repo"
```

Notes:

- `scripts/codex-bridge.py` uses `CODEX_LOBSTER_CODEX_BIN` first, then `which codex`, then `/Applications/Codex.app/Contents/Resources/codex`.
- `exec`, `resume`, and `review` prefer native JSONL output when the installed Codex subcommand supports `--json`.
- Final session summaries now fold native agent reply snippets and token usage into the bridge detail, so copied diagnostics are closer to Codex's real session output.
- Native `thread_id` is surfaced directly in bridge diagnostics, so the island can show which Codex thread the latest session belongs to.
- Events are appended to `~/.codex-lobster-island/codex-events.jsonl` by default.
- Live updates are pushed to `tcp://127.0.0.1:45541` by default.
- Each bridge invocation gets a `sessionId`, or you can provide one explicitly with `CODEX_LOBSTER_SESSION_ID`.
- If the app is not running, the bridge still records the log, and the provider restores the latest state from that log on next launch.
- The menu bar, settings panel, and expanded island now distinguish `真实 Codex 运行中` vs `最近 Codex 会话已完成/失败` vs `Codex CLI 不可用`.

Common troubleshooting:

- If the app shows `Codex CLI 不可用`, set `CODEX_LOBSTER_CODEX_BIN` to the real `codex` binary path.
- If the app shows `等待 Codex CLI 桥接`, the island is running but no bridge event has arrived yet. Run `./scripts/codex-island.sh ...`.
- If you run `codex` directly in another terminal, the island will not treat that as real-time truth. Bridge mode is the only supported real-status path.
- If a session failed, open Settings and use `复制最近会话诊断` to capture the latest session summaries.

Integration boundary:

- This project now bridges real Codex CLI lifecycle and native JSONL events for `exec`, `resume`, and `review`.
- It does not yet attach to arbitrary already-running Codex processes or consume a deeper internal Codex state API.
- `processWatcher` still exists as a coarse fallback and should be treated as process-level observation, not task-level truth.

## Package as .app

```bash
./scripts/package-app.sh
open dist/CodexLobsterIsland.app
```

## Release workflow

### 1. Local release smoke test

Build a production `.app` and a distributable zip without Developer ID signing or notarization:

```bash
./scripts/verify-release-pipeline.sh
```

### 2. Local release doctor

Check whether your machine is actually ready for a public release:

```bash
./scripts/release-doctor.sh
```

This checks local tools, signing identities, the default `codex-lobster-notary` profile, Sparkle signing availability, release notes, and optional hosting-related env vars.

If you need the exact GitHub secrets and variables list:

```bash
./scripts/print-release-secrets-template.sh
```

To import your local Developer ID certificate into Keychain:

```bash
./scripts/import-developer-id-certificate.sh \
  --p12 "/absolute/path/to/developer-id.p12" \
  --password "p12-password"
```

To create the local `notarytool` profile used by the release scripts:

```bash
./scripts/store-notary-profile.sh \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

To generate a Sparkle keypair and export the private key to a local file:

```bash
./scripts/generate-sparkle-keys.sh \
  --private-key-out ~/.config/codex-lobster-island/sparkle-private.key
```

To convert your `.p12` and Sparkle private key into GitHub Actions secret values:

```bash
./scripts/export-release-secrets.sh \
  --p12 "/absolute/path/to/developer-id.p12" \
  --sparkle-private-key ~/.config/codex-lobster-island/sparkle-private.key
```

For local shell-based releases, copy the example env file to a private path and source it before running release commands:

```bash
cp Config/Release/release.env.example ~/.config/codex-lobster-island/release.env
source ~/.config/codex-lobster-island/release.env
```

Or use the helper to initialize it in one step:

```bash
./scripts/init-release-env.sh \
  --private-key-file ~/.config/codex-lobster-island/sparkle-private.key
source ~/.config/codex-lobster-island/release.env
```

After you have a signing identity, download host, and Sparkle public key, you can auto-fill the env file:

```bash
./scripts/configure-release-env.sh \
  --download-base-url "https://downloads.example.com/codex-lobster-island" \
  --sparkle-public-key "your-public-ed25519-key" \
  --version 0.1.0
```

### 3. Signed build for internal testing

Use your `Developer ID Application` signing identity and skip notarization:

```bash
APPLE_DEVELOPER_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
./scripts/release-app.sh \
  --skip-notarize \
  --version 0.1.0 \
  --build 1
```

### 4. Public distribution build

First store a notarytool keychain profile once:

```bash
xcrun notarytool store-credentials "codex-lobster-notary" \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

Then create the signed, notarized, stapled release zip:

```bash
APPLE_DEVELOPER_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
APPLE_NOTARY_PROFILE="codex-lobster-notary" \
./scripts/release-app.sh \
  --version 0.1.0 \
  --build 1
```

### 5. Public build with update feed artifacts

If you already have a stable download host, generate Sparkle-ready feed files alongside the release zip:

```bash
APPLE_DEVELOPER_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
APPLE_NOTARY_PROFILE="codex-lobster-notary" \
SPARKLE_PUBLIC_ED_KEY="your-public-ed25519-key" \
./scripts/release-app.sh \
  --version 0.1.0 \
  --build 1 \
  --download-base-url "https://downloads.example.com/codex-lobster-island" \
  --appcast-url "https://downloads.example.com/codex-lobster-island/appcast.xml" \
  --release-notes-url "https://downloads.example.com/codex-lobster-island/release-notes/0.1.0.html"
```

If you also want Sparkle signatures for the archive, appcast, and release notes:

```bash
SPARKLE_PUBLIC_ED_KEY="your-public-ed25519-key" \
./scripts/release-app.sh \
  --skip-sign \
  --skip-notarize \
  --version 0.1.0 \
  --build 1 \
  --download-base-url "https://downloads.example.com/codex-lobster-island" \
  --appcast-url "https://downloads.example.com/codex-lobster-island/appcast.xml" \
  --release-notes-markdown "docs/release-notes/latest.md" \
  --sparkle-private-ed-key-file "/absolute/path/to/private-ed25519.key"
```

Artifacts:

- `dist/CodexLobsterIsland.app`
- `dist/CodexLobsterIsland-<version>+<build>-macos.zip`
- `dist/feed/appcast.xml`
- `dist/feed/release-metadata.json`
- `dist/release-notes/<version>.html`

Notes:

- `scripts/package-app.sh` is the raw app packager.
- `scripts/release-app.sh` is the publish-oriented pipeline for Release build, signing, notarization, stapling, and zip creation.
- `Config/Release/DeveloperID.entitlements` is the stable entitlements path used for Developer ID signing.
- `docs/release-checklist.md` is the human release checklist.
- `.github/workflows/release.yml` is the CI template for signed and notarized builds on GitHub Actions.
- `scripts/release-doctor.sh` is the local preflight checker for release credentials and tooling.
- `scripts/generate-release-feed.py` can also be run standalone if you want to regenerate feed files for an existing archive.
- `scripts/generate-release-notes.py` renders markdown release notes to distributable HTML.
- `scripts/publish-github-release.sh` uploads release assets with `gh` when the GitHub CLI is available.
- GitHub Actions now also publishes tagged `v*` releases directly as GitHub Releases with the signed zip, feed artifacts, and rendered release notes.
- Sparkle is linked into the app binary now. When `SUFeedURL` and `SUPublicEDKey` are configured, the app exposes in-app “检查更新…” controls plus automatic update toggles in Settings.
- Without `SUFeedURL` and `SUPublicEDKey`, the updater UI remains present but disabled and reports the missing configuration instead of failing at launch.

## Current status sources

- `Mock`: built-in demo flow
- `Codex CLI Bridge`: wraps the real `codex` CLI and emits structured lifecycle events
- `Process Watcher`: watches local `codex` processes via `pgrep -fal codex`
- `Log Parser`: reads the latest structured event from a local log file
- `Socket Event`: listens for newline-delimited JSON events over local TCP

## Environment overrides

- `CODEX_LOBSTER_PROVIDER_KIND=mock|codexCLI|processWatcher|logParser|socketEvent`
- `CODEX_LOBSTER_LOG_PATH=/absolute/path/to/codex-status.log`
- `CODEX_LOBSTER_SOCKET_PORT=45540`
- `CODEX_LOBSTER_BRIDGE_LOG_PATH=/absolute/path/to/codex-events.jsonl`
- `CODEX_LOBSTER_BRIDGE_PORT=45541`
- `CODEX_LOBSTER_CODEX_BIN=/absolute/path/to/codex`
- `CODEX_LOBSTER_SESSION_ID=optional-stable-session-id`
- `CODEX_LOBSTER_BRIDGE_HEARTBEAT_SECONDS=8`

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

## License

MIT. See [LICENSE](/Users/kevin/Documents/01_开发项目/lingdongdao/LICENSE).
