# Kit média v2

- `../screenshots/01-app-history.png` et `02-settings.png` sont des captures
  hors écran des vues SwiftUI de production, avec historique et préférences
  fictifs. Aucun presse-papiers ou historique utilisateur n'est lu.
- Régénérer les captures :
  `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk swift build --product PKMediaDownloader`
  puis `./.build/debug/PKMediaDownloader --capture-promo store/v2/screenshots`.
- Régénérer la bannière et la card (Pillow) :
  `python3 store/website/media-kit/generate-stills.py`.
- Copies pour la landing : `store/website/assets/app-history.png`, `settings.png`,
  `icon.png`, `social-card.png`. Elles sont locales et sans symlink. Copier les
  captures après régénération des sources, puis vérifier avec `./script/website.sh`.
- Pas de GIF ni MP4 d'usage réel dans cette version : le MP4 dans `store/v1/`
  ne montre que l'icône. Ne pas le présenter comme une démo de l'app.
