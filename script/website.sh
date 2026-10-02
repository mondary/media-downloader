#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/store/website"
mkdir -p "$DEST/assets" "$DEST/screenshots"
cp "$ROOT/store/index.html" "$DEST/index.html"
cp "$ROOT/store/assets/icon.png" "$DEST/assets/icon.png"
cp "$ROOT/store/assets/card-1200x630.png" "$DEST/assets/card-1200x630.png"
cp "$ROOT/store/screenshots/01-app-history.png" "$DEST/screenshots/01-app-history.png"
echo "Bundle prêt à servir : $DEST (déposer son contenu, pas le dossier website)."
