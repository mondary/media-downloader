# Kit média — website courant

- `../screenshots/01-app-history.png` et `02-settings.png` sont des captures
  hors écran des vues SwiftUI de production, avec historique et préférences
  fictifs. Aucun presse-papiers ou historique utilisateur n'est lu.
- Rafraîchir les miniatures YouTube (maxres, repli sur hq, suppression des
  bandes de letterbox et recadrage 4:3 pour les vrais emplacements de l'app) :
  `python3 store/website/media-kit/fetch-youtube-thumbnails.py`.
- Rafraîchir le logo Ko-fi officiel depuis son CDN :
  `python3 store/website/media-kit/fetch-kofi-logo.py`.
- Régénérer les captures :
  `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk swift build --product PKMediaDownloader`
  puis `./.build/debug/PKMediaDownloader --capture-promo store/website/screenshots`,
  puis copier vers `../assets/` (`app-history.png`, `settings.png`).
- Les fichiers `thumb-*.jpg` sont les vraies miniatures YouTube des trois
  courts-métrages Blender Foundation (Big Buck Bunny, Sintel, Tears of Steel),
  sans bandes noires et recadrées au format 4:3 natif, chargées dans les vraies lignes SwiftUI
  uniquement pour la capture promo.
  IDs vidéo et sources listés dans `../PLAN.md`.
- `assets/kofi-logomark.png` est le logomark officiel Ko-fi, récupéré depuis
  `https://storage.ko-fi.com/cdn/logomarkLogo.png` avec referer Ko-fi.
- Régénérer la bannière et la card (Pillow) :
  `python3 store/website/media-kit/generate-stills.py`.
- Assets de la landing dans `store/website/assets/` : `app-history.png`,
  `settings.png`, `icon.png`, `social-card.png`, `banner-1544x500.png`.
  Fichiers locaux, sans symlink.
- Pas de GIF ni MP4 d'usage réel : le MP4 dans `store/v1/` ne montre que
  l'icône. Ne pas le présenter comme une démo de l'app.
