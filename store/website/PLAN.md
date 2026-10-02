# Website courant — contraste sombre inspiré de Cap

`store/website/` est **la version courante**, éditable et déployable.
`store/v1/`, `store/v2/` et `store/v3/` sont des archives. Prochaine refonte :
déplacer `website/` vers `v4/`, puis créer le nouveau `website/`.

Référence demandée : `.inspi/.inspi/library/cap-clone.html` (Cap). La
correction demandée inverse le contraste : page graphite/noire pour faire
ressortir l'interface principale claire de PKMediaDownloader. Repris de Cap :
pilules d'annonce, titre sans-serif serré, chapô serif, boutons clairs doux,
cadre pastel autour de la preuve produit, onglets d'aperçu, cartes à étapes,
bandeau, installation en deux cartes, CTA final. L'interface est la capture
SwiftUI elle-même : aucun traffic light ni barre macOS décorative (il n'y en a
pas dans la fenêtre de l'app). Les réglages réellement sombres sont montrés
fidèlement. Pas de tarifs, témoignages ou logos inventés.

| Section | Preuve | Interaction |
|---|---|---|
| Héro | vraie capture native (historique) dans fenêtre macOS ; onglets Historique/Réglages | onglets + clavier ←/→ |
| Bandeau | noms de sites pris en charge (yt-dlp) | défilement CSS, figé si `reduced-motion` |
| Parcours | 3 cartes Coller/Garder/Découper, étapes issues du code réel | lecture, pilules de contexte |
| Dans l'app | capture native des réglages + faits ⌘⇧6 / pkmd / yt-dlp / cobalt | lecture |
| Installation | commande cask copiable, DMG v1.2026.12, avertissement Gatekeeper | copie explicite |
| Final + pied | DMG, GitHub, projet original, Ko-fi | liens réels |

Captures : vues SwiftUI réelles avec données fictives (`screenshots/`).
Aucune fausse interface : la découpe n'est pas simulée sur le site.
Les entrées d'historique de la capture utilisent les vraies miniatures YouTube
de Big Buck Bunny (`aqz-KE-bpKQ`), Sintel (`eRsGyueVLvQ`) et Tears of Steel
(`R6MlUcmOul8`), trois films ouverts de Blender Foundation. L'image de
l'interface est détourée par son alpha et posée directement
sur le fond noir : ni dalle claire ajoutée par la page ni cadre pastel autour.

FR/EN dans la même page (`data-fr`/`data-en`), FR lisible sans JavaScript,
persistance `pkmd-language`, `prefers-reduced-motion` respecté.
`script/website.sh` vérifie les fichiers ; aucun upload implicite.
