#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
TAG="${1:-}"
VERSION="$(sed -n 's/^## \[\(v[^]]*\)\].*/\1/p' CHANGELOG.md | head -1)"
[[ -n "$TAG" && "$TAG" == "$VERSION" ]] || {
  printf 'usage: %s %s (latest CHANGELOG version)\n' "$0" "$VERSION" >&2
  exit 1
}
[[ -z "$(git status --porcelain)" ]] || { echo 'Commit changes before release.' >&2; exit 1; }
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || {
  echo 'Push the release commit to origin/main first.' >&2; exit 1;
}
gh auth status >/dev/null
[[ -n "${MEDIA_DOWNLOADER_DEVELOPER_ID:-}" || -f .env ]] || {
  echo 'A Developer ID signing identity and notarization credentials are required.' >&2; exit 1;
}

APP_VERSION="$TAG" ./script/package_macos.sh
ARCH="$(uname -m)"
DMG="dist/release/PKMediaDownloader-$TAG-macos-$ARCH.dmg"
ZIP="dist/release/PKMediaDownloader-$TAG-macos-$ARCH.zip"
[[ -f "$DMG" && -f "$ZIP" ]] || { echo 'Missing release assets.' >&2; exit 1; }

if gh release view "$TAG" -R mondary/media-downloader >/dev/null 2>&1; then
  echo "Release $TAG already exists; refusing to replace its assets." >&2
  exit 1
fi
gh release create "$TAG" "$DMG" "$ZIP" -R mondary/media-downloader \
  --target "$(git rev-parse HEAD)" --title "PKMediaDownloader $TAG" --generate-notes
echo 'Release published. Run script/generate_cask.sh to create the verified tap cask.'
