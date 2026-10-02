# Website courant — table de montage *(archive v3)*

`store/website/` est **la seule version courante**, éditable et déployable.
`store/v1/` et `store/v2/` sont des archives ; la prochaine refonte doit
d'abord déplacer `website/` vers `v3/`, puis créer un nouveau `website/`.

Référence principale : `.inspi/.inspi/library/framestudio-clone.html` pour
l'idée d'un produit exploré dans un grand espace, pas pour son interface.
Référence secondaire : `tinycast-clone.html` pour l'installation visible.
Direction propre à PKMediaDownloader : papier chaud, noir charbon, jaune de
sélection inspiré de la vraie frise de découpe, typographie dense.

| Section | Preuve et promesse | Interaction | Mobile |
|---|---|---|---|
| Ouverture | DMG publié et Homebrew immédiatement visibles | CTA réels | titre et CTA sans débordement |
| Parcours | URL fictive, vraie capture d'historique, frise explicative | étapes au scroll ou boutons, fin d'extrait au curseur | boutons + étapes verticales, sans sticky |
| Détails | capture native des réglages avec données fictives | aucune fausse UI | capture pleine largeur |
| Installation | DMG arm64, cask, yt-dlp/ffmpeg, avertissement Gatekeeper | copie explicite | code horizontal scrollable |
| Secours | cobalt.tools et GitHub cobalt externes | aucun envoi automatique | liens accessibles |

Les captures dans `screenshots/` viennent des vues SwiftUI avec données
fictives. Une tentative de capture hors écran du mode découpe a produit une
surface vidéo noire (AVPlayer) : **non utilisée**. La frise HTML est signalée
comme illustration, sans faux export. Le MP4 de `v1/` ne montre que l'icône.

Page autonome en local, FR/EN, FR lisible sans JavaScript, clavier et
`prefers-reduced-motion`. `script/website.sh` vérifie les fichiers requis.
Pas d'upload implicite.
