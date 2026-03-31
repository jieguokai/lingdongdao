# Codex Lobster Island latest

## Highlights

- Added Sparkle-based in-app update checks
- Added signed appcast and release metadata generation
- Added release packaging and notarization workflow templates

## Improvements

- Embedded `Sparkle.framework` in packaged release apps
- Added feed and release asset verification scripts
- Hardened release packaging against concurrent build output collisions

## Known limitations

- Public release upload still requires your own GitHub or static hosting credentials
- Real Codex state is still provider-based, not a first-party Codex protocol integration
