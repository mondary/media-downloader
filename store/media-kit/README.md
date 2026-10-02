# Kit média — état actuel

- `../assets/banner-1544x500.png` et `../assets/card-1200x630.png` sont
  générés depuis `01-app-history.png` par `python3 store/media-kit/generate-stills.py`
  (Pillow requis). L'ancienne bannière a été archivée dans
  `../archive/media-kit/`.
- `../assets/card-1200x675.png` et `../videos/demo.mp4` sont des visuels
  **historiques** centrés sur l'icône, et non une démo de l'interface.
- `../screenshots/01-apercu-projet.png` est une image d'icône historique ; ne
  pas la présenter comme une capture de l'application.
- `../screenshots/01-app-history.png` et `02-settings.png` proviennent des vues
  SwiftUI de production, rendues hors écran avec un `UserDefaults` jetable et
  un historique fictif. Aucun historique réel ou presse-papiers n'est lu.
- Régénérer : `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk swift build --product PKMediaDownloader` puis
  `./.build/debug/PKMediaDownloader --capture-promo store/screenshots`.
- Les GIF d'interface demandent encore un scénario fidèle des interactions.
- `./script/website.sh` depuis la racine génère le bundle statique dans
  `store/website/` sans publier le site.
- `../assets/icon.png` est une copie ordinaire de l'icône racine, utilisée
  par la landing source et son bundle (aucun symlink de déploiement).
