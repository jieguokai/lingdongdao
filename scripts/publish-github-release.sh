#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") --tag <tag> --title <title> --notes-file <file> [options] <asset>...

Options:
  --repo <owner/name>     Optional GitHub repository override
  --draft                 Create or update a draft release
  --prerelease            Mark release as prerelease
  --latest                Mark release as latest
  --clobber               Overwrite existing assets with the same name
  --help                  Show help
EOF
}

TAG=""
TITLE=""
NOTES_FILE=""
REPO=""
DRAFT=false
PRERELEASE=false
LATEST=false
CLOBBER=false
ASSETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      TAG="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --notes-file)
      NOTES_FILE="$2"
      shift 2
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --draft)
      DRAFT=true
      shift
      ;;
    --prerelease)
      PRERELEASE=true
      shift
      ;;
    --latest)
      LATEST=true
      shift
      ;;
    --clobber)
      CLOBBER=true
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      ASSETS+=("$1")
      shift
      ;;
  esac
done

[[ -n "$TAG" ]] || { echo "Missing --tag" >&2; exit 1; }
[[ -n "$TITLE" ]] || { echo "Missing --title" >&2; exit 1; }
[[ -n "$NOTES_FILE" ]] || { echo "Missing --notes-file" >&2; exit 1; }
[[ -f "$NOTES_FILE" ]] || { echo "Notes file not found: $NOTES_FILE" >&2; exit 1; }
[[ ${#ASSETS[@]} -gt 0 ]] || { echo "Provide at least one asset to upload." >&2; exit 1; }

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required for publishing releases." >&2
  exit 1
fi

CREATE_ARGS=("$TAG" "--title" "$TITLE" "--notes-file" "$NOTES_FILE")
UPLOAD_ARGS=("$TAG")

if [[ -n "$REPO" ]]; then
  CREATE_ARGS+=("--repo" "$REPO")
  UPLOAD_ARGS+=("--repo" "$REPO")
fi
if [[ "$DRAFT" == true ]]; then
  CREATE_ARGS+=("--draft")
fi
if [[ "$PRERELEASE" == true ]]; then
  CREATE_ARGS+=("--prerelease")
fi
if [[ "$LATEST" == true ]]; then
  CREATE_ARGS+=("--latest")
fi

gh release create "${CREATE_ARGS[@]}" "${ASSETS[@]}"

if [[ "$CLOBBER" == true ]]; then
  UPLOAD_ARGS+=("--clobber")
fi

gh release upload "${UPLOAD_ARGS[@]}" "${ASSETS[@]}"
