#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-}"
[[ "$TAG" =~ ^v1\.[0-9]{4}\.[0-9]+$ ]] || {
  echo 'usage: script/generate_cask.sh v1.YYYY.PATCH [output.rb]' >&2; exit 1;
}
VERSION="${TAG#v}"
ARCH="${2:-$(uname -m)}"
[[ "$ARCH" == arm64 || "$ARCH" == x86_64 ]] || { echo 'Unsupported architecture.' >&2; exit 1; }
ASSET="PKMediaDownloader-$TAG-macos-$ARCH.dmg"
URL="https://github.com/mondary/media-downloader/releases/download/$TAG/$ASSET"
OUTPUT="${3:-Casks/pkmedia-downloader.rb}"

# A cask is generated only from a real published release, never from a local CI artifact.
gh release view "$TAG" -R mondary/media-downloader --json assets \
  --jq '.assets[].name' | grep -Fxq "$ASSET" || {
    echo "Release asset missing: $URL" >&2; exit 1;
  }
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
curl -fL --retry 2 -o "$TMP_DIR/$ASSET" "$URL"
SHA="$(shasum -a 256 "$TMP_DIR/$ASSET" | awk '{print $1}')"
mkdir -p "$(dirname "$OUTPUT")"
cat > "$OUTPUT" <<RUBY
cask "pkmedia-downloader" do
  version "$VERSION"
  sha256 "$SHA"

  url "https://github.com/mondary/media-downloader/releases/download/v#{version}/PKMediaDownloader-v#{version}-macos-$ARCH.dmg"
  name "PKMediaDownloader"
  desc "Native macOS video downloader powered by yt-dlp"
  homepage "https://github.com/mondary/media-downloader"

  depends_on macos: ">= :sonoma"
  depends_on formula: "yt-dlp"
  depends_on formula: "ffmpeg"

  app "PKMediaDownloader.app"
end
RUBY
echo "$OUTPUT — $URL — sha256 $SHA"
