#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
GitHub Actions secrets:
  APPLE_DEVELOPER_ID_P12_BASE64
  APPLE_DEVELOPER_ID_P12_PASSWORD
  APPLE_KEYCHAIN_PASSWORD
  APPLE_NOTARY_APPLE_ID
  APPLE_TEAM_ID
  APPLE_APP_SPECIFIC_PASSWORD
  APPLE_DEVELOPER_IDENTITY
  SPARKLE_PRIVATE_ED_KEY_BASE64
  SPARKLE_PUBLIC_ED_KEY

GitHub Actions variables:
  DOWNLOAD_BASE_URL
  APPCAST_URL
  RELEASE_NOTES_URL

Suggested local env file:
  Config/Release/release.env.example

Suggested bootstrap flow:
  1. Export your Developer ID certificate to .p12
  2. Import it locally with:
     ./scripts/import-developer-id-certificate.sh --p12 "/absolute/path/to/developer-id.p12" --password "p12-password"
  3. Generate or export Sparkle keys with:
     ./scripts/generate-sparkle-keys.sh --private-key-out "/absolute/path/to/sparkle-private.key"
  4. Base64-encode release secrets with:
     ./scripts/export-release-secrets.sh --p12 "/absolute/path/to/developer-id.p12" --sparkle-private-key "/absolute/path/to/sparkle-private.key"
  5. Store notary credentials locally with:
     ./scripts/store-notary-profile.sh --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-password"
  6. Source your local release env file
  7. Run ./scripts/release-doctor.sh
EOF
