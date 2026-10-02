# PKMediaDownloader — store v2 / landing website (archive)

Ce plan décrit la landing v2 au moment où elle occupait `store/website/`.
Depuis, ses fichiers ont été archivés ici ; la source courante est
[`../website/`](../website/). Les chemins ci-dessous sont historiques.

Source unique, éditable et déployable : `store/website/index.html`.
`./script/website.sh` vérifie ses fichiers ; il ne génère plus de copie.

## Direction

Un **atelier de montage/filmstrip** plutôt qu'une vitrine SaaS : papier mat
`#f2f0e8`, encre `#142033`, bleu cobalt `#1758f5`, orange repère
`#f16a42`, blanc `#fffdf5`. Titre condensé « UN LIEN. UN FICHIER. À VOUS. »,
corps macOS lisible, timecodes en monospace. Le risque assumé : une grande
surface bleue et une fenêtre d'app en biais, cadrée comme un photogramme.
Pas de réplique HTML de l'app ni de faux état de téléchargement.

## Storyboard

| Section | Promesse / état réel | Preuve | Mouvement / interaction | Mobile |
|---|---|---|---|---|
| Hero | le lien devient fichier | capture native d'historique fictif | entrée unique de la fenêtre, CTA DMG réel | fenêtre droite, sans perspective |
| Bande de transport | coller → retrouver → découper | fonctions confirmées dans l'app | repère de progression statique | pile verticale |
| La preuve | historique et réglages | deux captures SwiftUI hors écran | aucune animation d'UI inventée | images pleine largeur |
| Secours | Cobalt est externe | liens cobalt.tools et GitHub | simple lien, aucune URL transmise | texte court |
| Installer | DMG arm64 et cask publiés | release v1.2026.12, commande Homebrew | copie presse-papiers explicite | commande scrollable |

## Sources, limites et réception

- Captures `store/v2/screenshots/` : vues de production capturées hors écran
  avec données fictives via `--capture-promo`. Copies optimisées dans
  `store/website/assets/` pour la page.
- L'ancien MP4 v1 n'est pas une démonstration produit. Ne pas le réutiliser
  comme tel. GIF/vidéo d'interface restent à produire si un scénario fidèle
  et reproductible est défini.
- FR/EN dans la même page, détection des préférences dans l'ordre, choix
  manuel prioritaire, FR sans JS ; `prefers-reduced-motion`.
- 390 / 768 / 1440 / 1920 px : pas de débordement, CTA et images lisibles,
  liens/asset réels, clavier et métadonnées FR/EN. Vérifier la page et les
  captures visuellement avant livraison.

## Vérification locale — 2026-10-02

- `./script/website.sh` : page et fichiers locaux vérifiés dans `store/website/` (704 Ko).
- Chrome headless : 390, 768, 1440, 1920 px ; aucune erreur JS ni débordement ;
  captures desktop/mobile relues visuellement, les deux images natives chargent.
- FR, EN et langue non prise en charge ; bascule, persistance, métadonnées et
  copie Homebrew vérifiées. Sans JS, FR complet lisible.
- DMG versionné : HTTP 200 ; cask `mondary/tap/pkmedia-downloader` présent.
- QA humaine du rendu et premier lancement Gatekeeper restent à faire avant
  toute publication web. Aucun upload FTP ni nouvelle release n'a été lancé.
