# Security Policy

## Supported versions

This project is currently maintained on the `main` branch.

## Reporting a vulnerability

Do not open public GitHub issues for suspected security vulnerabilities.

Instead:

1. Prepare a short report with:
   - affected area
   - impact
   - reproduction steps
   - suggested mitigation if known
2. Send the report privately to the repository owner through GitHub security reporting or another private channel you control.

If no private reporting channel is configured yet, contact the repository owner directly and avoid disclosing exploit details publicly until a fix is available.

## Scope notes

Current sensitive areas include:

- release signing and notarization scripts
- local credential handling helpers
- update feed and Sparkle signing flow
- any future real Codex integration provider
