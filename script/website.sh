#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/store/website"
[[ -f "$DEST/index.html" && -f "$DEST/style.css" && -f "$DEST/site.js" ]] || { echo 'Page store/website manquante.' >&2; exit 1; }
for asset in icon.png app-history.png settings.png social-card.png banner-1544x500.png thumb-bbb.jpg thumb-sintel.jpg thumb-tears.jpg kofi-logomark.png; do
  [[ -f "$DEST/assets/$asset" ]] || { echo "Asset manquant : $asset" >&2; exit 1; }
done
echo "Page prête à servir : $DEST (déposer son contenu, pas le dossier website)."
