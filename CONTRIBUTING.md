# Contributing to Codex Lobster Island

Thanks for contributing.

## Development setup

1. Use a recent macOS version with Xcode Command Line Tools installed.
2. Clone the repository.
3. Build locally:

```bash
swift build
```

4. Run the app:

```bash
./scripts/run-app.sh
```

## Project structure

- `Sources/CodexLobsterIsland/App`: app bootstrap and dependency wiring
- `Sources/CodexLobsterIsland/Domain`: models and protocols
- `Sources/CodexLobsterIsland/Services`: providers, sound, settings, release helpers
- `Sources/CodexLobsterIsland/UI`: menu bar, floating island, settings, shared UI
- `Config`: release configuration templates
- `scripts`: verification, packaging, and release tooling

## Contribution rules

1. Keep the app macOS-native and SwiftUI-first.
2. Prefer small focused files over large multi-purpose files.
3. Do not commit build artifacts, packaged apps, or private release credentials.
4. Keep mock-provider support working unless the change is explicitly about replacing it.
5. Preserve the provider-based architecture for future Codex integrations.

## Before opening a pull request

Run the relevant checks for your change. At minimum:

```bash
swift build -c release
./scripts/verify-open-source-ready.sh
```

If you touched release automation, also run:

```bash
./scripts/verify-release-preflight.sh
./scripts/verify-release-workflow.sh
```

## Pull request notes

- Describe the user-facing behavior change.
- List the verification commands you ran.
- Mention any mocked behavior or unfinished release dependencies.
