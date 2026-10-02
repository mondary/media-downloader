# Changelog

Toutes les modifications notables de ce projet sont documentées ici.
Format basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/)
(Added / Changed / Fixed).

## [v1.2026.21] - 2026-10-02

### Changed
- Vignettes recadrées en 4:3 sans bandes noires, au format des vignettes dans l'interface native.
- Emojis des boutons de soutien remplacés par le logomark officiel Ko-fi téléchargé depuis son CDN.

## [v1.2026.20] - 2026-10-02

### Added
- Bouton Ko-fi rouge avec café et cœur dans la barre supérieure persistante et dans l'appel à l'action final.

## [v1.2026.19] - 2026-10-02

### Changed
- Remplacement des illustrations de miniatures par les vraies miniatures YouTube de Big Buck Bunny, Sintel et Tears of Steel ; URLs et noms des entrées promo alignés sur les vidéos réelles.
- Ajout du script de récupération des miniatures originales dans le kit média.

## [v1.2026.18] - 2026-10-02

### Changed
- Capture de l'app sans dalle/frame ajoutée par la landing : alpha natif directement sur fond noir. Historique SwiftUI illustré par trois miniatures synthétiques.

## [v1.2026.17] - 2026-10-02

### Fixed
- Direction visuelle corrigée après revue : landing sombre contrastant avec l'interface claire ; retrait des faux traffic lights et de la barre de fenêtre. Capture native recadrée, réglages capturés dans leur apparence sombre réelle.
- Bannière et card régénérées pour la palette sombre.

## [v1.2026.16] - 2026-10-02

### Added
- Nouvelle landing claire inspirée de Cap (référence `.inspi`) dans `store/website/` : héro papier avec fenêtre macOS et onglets de captures natives, parcours en trois cartes, faits réels, installation DMG/Homebrew.

### Changed
- La landing « table de montage » est archivée dans `store/v3/`, après `v1/` et `v2/`. README et bannière synchronisés. La dernière release binaire demeure `v1.2026.12`.

## [v1.2026.15] - 2026-10-02

### Added
- Nouvelle landing « table de montage » FR/EN : parcours scrollable à trois temps, commandes clavier, frise explicative et preuves natives, directement dans `store/website/`.

### Changed
- Convention du store : `store/website/` est la version courante ; l'ancienne landing est archivée sous `store/v2/` après `store/v1/`. README et kit média synchronisés. La dernière release binaire demeure `v1.2026.12`.

## [v1.2026.14] - 2026-10-02

### Fixed
- Une seule page éditable et déployable dans `store/website/` ; suppression du doublon à la racine et correction des chemins documentaires.

### Changed
- `script/website.sh` vérifie les assets locaux sans recopier la page. La dernière release binaire reste `v1.2026.12`.

## [v1.2026.13] - 2026-10-02

### Added
- Première landing éditoriale bilingue et kit média v2 (réorganisés ensuite dans `store/website/`).

### Changed
- Ancien store conservé sous `store/v1/` ; nouvelle source média sous `store/v2/`. Les liens README FR/EN et la documentation pointent sur cette structure. La dernière release binaire reste `v1.2026.12`.

## [v1.2026.12] - 2026-10-02

### Added
- Liens externes vers Cobalt et son dépôt comme solution de secours après un échec, dans les réglages et la documentation.
- Landing promotionnelle bilingue et proposition de rangement du dépôt.
- Deux captures de vues natives hors écran avec données fictives, bannière et card issues de la vraie interface.
- DMG Apple Silicon signé ad hoc publié sur GitHub et cask Homebrew généré depuis cet asset avec SHA-256 vérifié.

### Changed
- Script de release unifié avec le packager et version lue dans ce changelog.

## [v1.2026.11] - 2026-09-30

### Changed
- `pkmd` devient un binaire indépendant : découpage du package en `MediaDownloaderCore` (moteur partagé) + cibles exécutables `PKMediaDownloader` et `pkmd` — le CLI ne lance plus l'app et démarre instantanément

## [v1.2026.10] - 2026-09-29

### Added
- CLI `pkmd` embarqué dans l'app (même moteur, même historique) : `pkmd <url>`, `list`, `engines`, `update-engine` — lanceur `Contents/MacOS/pkmd`

## [v1.2026.9] - 2026-09-29

### Fixed
- Raccourci global par défaut réellement Cmd+Shift+6 (keycode 22) au lieu de Cmd+Shift+8 — mis en évidence par le premier build CI

## [v1.2026.8] - 2026-09-29

### Added
- Workflow GitHub Actions « build » : tests + build + DMG/ZIP ad-hoc signés en artefact (mode `CI_UNSIGNED=1` dans `package_macos.sh`, signature Developer ID inchangée quand les secrets sont présents)

## [v1.2026.7] - 2026-09-29

### Fixed
- « Check for Updates » vérifie les releases du dépôt fork (mondary/media-downloader) au lieu du projet amont

## [v1.2026.6] - 2026-09-29

### Added
- Réglages → Download Engine : version yt-dlp affichée et bouton de mise à jour (Homebrew ou self-update selon l'installation)

## [v1.2026.5] - 2026-09-29

### Fixed
- `.gitignore` ignore le fichier `Icon?` parasite généré par les icônes de dossiers macOS (Manila/Finder)

## [v1.2026.4] - 2026-09-29

### Added
- Dossier `store/` : kit promotionnel (bannière 1544x500, card 1200x675, capture, vidéo de démo, descriptions FR/EN)

## [v1.2026.3] - 2026-09-29

### Added
- Historique playlist item par item : chaque vidéo d'une playlist apparaît dans l'historique dès qu'elle est terminée (parsing `after_move:completed:`, nouveau modèle `CompletedDownload`, callback `onItemCompleted`)
- Panneau historique redimensionnable (glisser la poignée) avec en-tête, compteur et bouton « Vider »
- Test unitaire du parsing des items de playlist terminés

### Fixed
- Rejeu de la sortie du processus à la fin d'un téléchargement rapide : la progression finale et l'entrée d'historique ne sont plus perdues

## [v1.2026.2] - 2026-09-29

### Fixed
- Lien GitHub des réglages pointant vers le dépôt du fork (mondary/media-downloader)
