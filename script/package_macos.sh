#!/usr/bin/env bash
set -euo pipefail

APP_NAME="PKMediaDownloader"
BUNDLE_ID="${BUNDLE_ID:-com.pkmediadownloader.app}"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
APP_VERSION="${APP_VERSION:-$(sed -n 's/^## \[\(v[^]]*\)\].*/\1/p' CHANGELOG.md | head -1)}"
[[ -n "$APP_VERSION" ]] || { echo 'error: no versioned CHANGELOG entry' >&2; exit 1; }
BUILD_CHANNEL="release"
if [[ "${PK_DEV_BUILD:-0}" == "1" ]]; then
  BUILD_CHANNEL="dev"
  APP_BUILD="$(date +%s)"
  APP_VERSION="${APP_VERSION#v}-dev.$(date -u +%H%M)"
else
  APP_BUILD="${APP_BUILD:-${APP_VERSION#v}}"
fi

if [[ -f ".env" ]]; then
  set -a
  source ".env"
  set +a
fi

DEVELOPER_ID="${MEDIA_DOWNLOADER_DEVELOPER_ID:-${ELECTROBUN_DEVELOPER_ID:-}}"
APPLE_API_KEY_ID_RESOLVED="${APPLE_API_KEY_ID:-${ELECTROBUN_APPLEAPIKEY:-}}"
APPLE_API_ISSUER_ID_RESOLVED="${APPLE_API_ISSUER_ID:-${ELECTROBUN_APPLEAPIISSUER:-}}"
APPLE_API_KEY_PATH_RESOLVED="${APPLE_API_KEY_PATH:-${ELECTROBUN_APPLEAPIKEYPATH:-}}"

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

notarytool_args() {
  if [[ -n "$APPLE_API_KEY_ID_RESOLVED" && -n "$APPLE_API_ISSUER_ID_RESOLVED" && -n "$APPLE_API_KEY_PATH_RESOLVED" ]]; then
    [[ -f "$APPLE_API_KEY_PATH_RESOLVED" ]] || fail "APPLE_API_KEY_PATH does not exist: $APPLE_API_KEY_PATH_RESOLVED"
    printf '%s\n' "--key" "$APPLE_API_KEY_PATH_RESOLVED" "--key-id" "$APPLE_API_KEY_ID_RESOLVED" "--issuer" "$APPLE_API_ISSUER_ID_RESOLVED"
    return
  fi

  if [[ -n "${APPLE_ID:-}" && -n "${APPLE_ID_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
    printf '%s\n' "--apple-id" "$APPLE_ID" "--password" "$APPLE_ID_PASSWORD" "--team-id" "$APPLE_TEAM_ID"
    return
  fi

  fail "provide App Store Connect API key envs or Apple ID notarization envs"
}

require_command swift
require_command codesign
require_command xcrun
require_command hdiutil

SIGNED_MODE="true"
if [[ "${CI_UNSIGNED:-0}" == "1" ]]; then
  SIGNED_MODE="false"
elif [[ -z "$DEVELOPER_ID" ]]; then
  fail "MEDIA_DOWNLOADER_DEVELOPER_ID or ELECTROBUN_DEVELOPER_ID is required (or set CI_UNSIGNED=1 for an ad-hoc signed build)"
fi

ARCH="$(uname -m)"
RELEASE_DIR="$ROOT_DIR/dist/release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$ROOT_DIR/Resources/AppIcon.icns"
NOTARY_ZIP="$RELEASE_DIR/$APP_NAME-notary.zip"
RELEASE_ZIP="$RELEASE_DIR/$APP_NAME-$APP_VERSION-macos-$ARCH.zip"
RELEASE_DMG="$RELEASE_DIR/$APP_NAME-$APP_VERSION-macos-$ARCH.dmg"

if [[ "${SKIP_TESTS:-0}" == "1" ]]; then
  [[ "$SIGNED_MODE" == "false" ]] || fail "SKIP_TESTS is only allowed for an unsigned local preview"
  printf '%s\n' 'warning: XCTest skipped for unsigned local preview' >&2
else
  swift test
fi
swift build -c release
swift build -c release --product pkmd
BUILD_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"
PKMD_BINARY="$(swift build -c release --product pkmd --show-bin-path)/pkmd"
BUILD_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$RELEASE_DIR"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$PKMD_BINARY" "$APP_MACOS/pkmd"
chmod +x "$APP_MACOS/pkmd"
cp "$PKMD_BINARY" "$RELEASE_DIR/pkmd-$APP_VERSION-macos-$ARCH"
cp "$APP_ICON" "$APP_RESOURCES/AppIcon.icns"
for resource_dir in ProjectIcons ProjectScreenshots; do
  if [[ -d "$ROOT_DIR/Resources/$resource_dir" ]]; then
    cp -R "$ROOT_DIR/Resources/$resource_dir" "$APP_RESOURCES/$resource_dir"
  fi
done
if [[ -f "$ROOT_DIR/Resources/kofi-logo.png" ]]; then
  cp "$ROOT_DIR/Resources/kofi-logo.png" "$APP_RESOURCES/kofi-logo.png"
fi

# Sparkle is a SwiftPM binary framework and must live inside the assembled app.
FRAMEWORK_DIR="$APP_CONTENTS/Frameworks"
mkdir -p "$FRAMEWORK_DIR"
for framework in "$BUILD_DIR"/*.framework; do
  [[ -d "$framework" ]] || continue
  cp -R "$framework" "$FRAMEWORK_DIR/"
done
if [[ -n "$(find "$FRAMEWORK_DIR" -maxdepth 1 -name '*.framework' -print -quit)" ]]; then
  install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BINARY" 2>/dev/null || true
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION#v}</string>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD</string>
  <key>SUFeedURL</key>
  <string>https://raw.githubusercontent.com/mondary/media-downloader/main/appcast.xml</string>
  <key>SUPublicEDKey</key>
  <string>t9Zzlc7LZD17hLCepinDvSRHk51hAWGbkFc2yVjbAYs=</string>
  <key>SUEnableInstallerLauncherService</key>
  <true/>
  <key>PKMediaDownloaderBuildChannel</key>
  <string>$BUILD_CHANNEL</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ "$SIGNED_MODE" == "true" ]]; then
  codesign --force --deep --options runtime --timestamp --sign "$DEVELOPER_ID" "$APP_BUNDLE"
  codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

  /usr/bin/ditto -c -k --keepParent "$APP_BUNDLE" "$NOTARY_ZIP"
  NOTARY_ARGS=()
  while IFS= read -r arg; do
    NOTARY_ARGS+=("$arg")
  done < <(notarytool_args)
  xcrun notarytool submit "$NOTARY_ZIP" "${NOTARY_ARGS[@]}" --wait
  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler validate "$APP_BUNDLE"
  spctl -a -vvv --type exec "$APP_BUNDLE"
else
  codesign --force --deep --options runtime --sign - "$APP_BUNDLE"
fi

rm -f "$RELEASE_ZIP"
/usr/bin/ditto -c -k --keepParent "$APP_BUNDLE" "$RELEASE_ZIP"
"$ROOT_DIR/script/create_dmg.sh" "$APP_BUNDLE" "$RELEASE_DMG" "$APP_NAME"
if [[ "$SIGNED_MODE" == "true" ]]; then
  codesign --force --timestamp --sign "$DEVELOPER_ID" "$RELEASE_DMG"
  codesign --verify --verbose=2 "$RELEASE_DMG"
  xcrun notarytool submit "$RELEASE_DMG" "${NOTARY_ARGS[@]}" --wait
  xcrun stapler staple "$RELEASE_DMG"
  xcrun stapler validate "$RELEASE_DMG"
  spctl -a -vvv -t open --context context:primary-signature "$RELEASE_DMG"
fi
rm -f "$NOTARY_ZIP"

printf '%s\n' "$RELEASE_ZIP"
printf '%s\n' "$RELEASE_DMG"
