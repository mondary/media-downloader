# Landing PKMediaDownloader

Source : `store/index.html`. FR/EN, sans dépendance réseau pour la traduction.

| Section | Promesse | Preuve | Mouvement / mobile |
|---|---|---|---|
| Hero | vidéos à portée de main | capture de la vraie vue avec historique fictif | statique, une colonne |
| Parcours | lien → fichier → extrait | fonctions présentes dans le code | trois étapes empilées |
| Détails | raccourci, historique, Cobalt externe | réglages et liens réels | lecture linéaire |
| Installation | DMG et cask réels | URL de release, commande brew, limites de signature | code scrollable |

Deux vues réelles sont désormais capturées hors écran (`01-app-history.png`,
`02-settings.png`) depuis le code SwiftUI, avec historique et préférences fictifs.
La vidéo historique reste iconographique : ne pas l'appeler démo d'interface.
La bannière et la card sont générées de la capture native par
`store/media-kit/generate-stills.py`. À produire avant une campagne/release :
GIF large/compact issus d'une démo fidèle et vidéo montrant l'usage réel.

Critères : FR/EN complet, clavier, mobile 390/768 et desktop 1440/1920,
réduction du mouvement, liens DMG/cask vérifiés après publication.
