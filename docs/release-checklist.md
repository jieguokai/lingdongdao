# Codex Lobster Island Release Checklist

## Goal

Ship a Developer ID signed, notarized, stapled macOS release zip for external distribution.

## One-time setup

1. Join the Apple Developer Program.
2. Create a `Developer ID Application` certificate.
3. Export the certificate as a `.p12` file if you plan to sign on CI.
4. Import the certificate into your local keychain:

```bash
./scripts/import-developer-id-certificate.sh \
  --p12 "/absolute/path/to/developer-id.p12" \
  --password "p12-password"
```

5. Generate or export your Sparkle signing key:

```bash
./scripts/generate-sparkle-keys.sh \
  --private-key-out ~/.config/codex-lobster-island/sparkle-private.key
```

6. Export CI-safe base64 values when you need to populate GitHub secrets:

```bash
./scripts/export-release-secrets.sh \
  --p12 "/absolute/path/to/developer-id.p12" \
  --sparkle-private-key ~/.config/codex-lobster-island/sparkle-private.key
```

7. Store a notarytool keychain profile locally:

```bash
./scripts/store-notary-profile.sh \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

## Local preflight

1. Verify release packaging still works without signing:

```bash
./scripts/verify-release-pipeline.sh
```

2. Run the bundled release doctor to check local tooling, signing, notary, Sparkle, and hosting configuration:

```bash
./scripts/release-doctor.sh
```

If you want a quick reminder of the GitHub secrets and variables you still need to wire up:

```bash
./scripts/print-release-secrets-template.sh
```

3. Verify your signing identity is visible:

```bash
security find-identity -v -p codesigning
```

4. Verify your notary profile exists:

```bash
xcrun notarytool history --keychain-profile "codex-lobster-notary"
```

6. Optionally print the CI secrets template if you are wiring GitHub Actions:

```bash
./scripts/print-release-secrets-template.sh
```

## Local internal test build

```bash
APPLE_DEVELOPER_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
./scripts/release-app.sh \
  --skip-notarize \
  --version 0.1.0 \
  --build 1
```

Check:

1. `codesign --verify --deep --strict --verbose=2 dist/CodexLobsterIsland.app`
2. `spctl -a -t exec -vv dist/CodexLobsterIsland.app`
3. Launch the app and verify menu bar, floating island, sound, settings, and provider switching.

## Public release build

```bash
APPLE_DEVELOPER_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
APPLE_NOTARY_PROFILE="codex-lobster-notary" \
./scripts/release-app.sh \
  --version 0.1.0 \
  --build 1
```

Expected outputs:

1. `dist/CodexLobsterIsland.app`
2. `dist/CodexLobsterIsland-0.1.0+1-macos.zip`

## Optional update feed artifacts

If you host releases on your own domain and want Sparkle-compatible feed files ready:

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

Expected extra outputs:

1. `dist/feed/appcast.xml`
2. `dist/feed/release-metadata.json`
3. `dist/release-notes/<version>.html` when `--release-notes-markdown` is provided

Notes:

1. `SUFeedURL` and `SUPublicEDKey` are embedded into `Info.plist` when provided.
2. The app now links Sparkle directly and exposes “检查更新…” plus automatic update preferences when this configuration is present.
3. If you omit `SUFeedURL` or `SUPublicEDKey`, the app still launches, but updater controls remain disabled and show the missing configuration.
4. If you provide `--sparkle-private-ed-key-file`, the archive, release notes, and appcast are signed using Sparkle's official `sign_update` tool.

## GitHub distribution

1. Prepare a markdown file in `docs/release-notes/<version>.md` or update `docs/release-notes/latest.md`.
2. On GitHub Actions, pushing a `v*` tag now publishes:
   - `dist/CodexLobsterIsland-*.zip`
   - `dist/feed/appcast.xml`
   - `dist/feed/release-metadata.json`
   - `dist/release-notes/*`
3. For local scripted publishing, install GitHub CLI and upload the built assets manually:

```bash
./scripts/publish-github-release.sh \
  --tag v0.1.0 \
  --title "Codex Lobster Island 0.1.0" \
  --notes-file docs/release-notes/latest.md \
  dist/CodexLobsterIsland-0.1.0+1-macos.zip \
  dist/feed/appcast.xml \
  dist/feed/release-metadata.json \
  dist/release-notes/0.1.0.html
```

4. The workflow expects these GitHub secrets and vars:
   - secrets: `APPLE_DEVELOPER_ID_P12_BASE64`, `APPLE_DEVELOPER_ID_P12_PASSWORD`, `APPLE_KEYCHAIN_PASSWORD`, `APPLE_NOTARY_APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_DEVELOPER_IDENTITY`, `SPARKLE_PRIVATE_ED_KEY_BASE64`, `SPARKLE_PUBLIC_ED_KEY`
   - vars: `DOWNLOAD_BASE_URL`, `APPCAST_URL`, `RELEASE_NOTES_URL`
5. For local shell-based releases, start from [release.env.example](/Users/kevin/Documents/01_开发项目/lingdongdao/Config/Release/release.env.example) and keep the real file outside git.

## Final validation

1. Download the zip onto a non-development Mac.
2. Open the zip-produced `.app`, not the local build folder copy.
3. Confirm first launch succeeds with Gatekeeper enabled.
4. Confirm menu bar icon appears and island opens without stealing focus.
5. Confirm `success` and `error` sounds still play when unmuted.
6. Confirm `Launch at Login` works from the packaged `.app`.

## Release notes minimum

1. Version
2. Build number
3. What changed
4. What remains mocked
5. Known limitations of real Codex integration
