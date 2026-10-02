# Proposition historique — la table de montage

Cette proposition a servi à créer la version courante dans `store/website/`.
Son statut et ses chemins ci-dessous sont conservés comme notes de conception
antérieures à la réalisation ; voir le plan courant dans `../website/PLAN.md`.

**Statut : proposition, non implémentée.** La landing actuelle reste dans
`store/website/` jusqu'à validation de cette direction.

## Référence et parti pris

Dans la bibliothèque locale `.inspi/.inspi/library/`, **Frame Studio**
(`framestudio-clone.html`) est la référence principale : une grande typographie
et surtout un produit que l'on explore, plutôt qu'une image d'app inclinée.
**Tinycast** (`tinycast-clone.html`) apporte une leçon secondaire : les vraies
commandes d'installation, immédiatement accessibles, sont plus convaincantes
qu'un argumentaire abstrait. Ne copier ni leur interface, ni leurs promesses.

La v2 prend la forme d'une **table de montage macOS**. Sa métaphore n'est pas
un film générique : c'est le parcours exact d'un lien vers un fichier local,
puis un extrait. Couleurs réduites à graphite, blanc chaud et une couleur de
repère inspirée des poignées de sélection de la vraie app. Aucun panneau
bleu vif, grille de trois cartes ou faux effet « REC ».

## Séquence proposée

1. **Ouverture / le geste.** Un titre court — « Gardez ce qui compte. » —
   et une URL de démonstration clairement fictive. Au scroll, une ligne
   matérialise le trajet URL → fichier ; pas de champ prétendant télécharger
   depuis la landing. DMG et Homebrew restent visibles sans attendre le scroll.
2. **La preuve vivante.** Une capture native non déformée devient l'espace
   principal. Un curseur de lecture *sur la page* permet de parcourir trois
   états documentés (URL saisie, fichier dans l'historique, extrait sélectionné).
   Chaque état provient d'une capture réelle ou d'un clip enregistré de l'app
   avec données fictives. Tant que ces états ne sont pas disponibles, garder
   les deux captures existantes sans simuler les écrans manquants.
3. **L'extrait.** Une frise horizontale avec repères de début et fin explique
   l'outil de découpe ; le glissement se limite à l'explication et n'affirme
   jamais exporter une vidéo depuis le navigateur. Une phrase précise sous
   chaque état, pas de listes de fonctionnalités inventées.
4. **Sortie / installer.** Le fichier aboutit à un bloc d'installation compact
   avec lien direct vers le DMG publié, commande du cask copiable, conditions
   macOS 14+/Apple Silicon et avertissement ad hoc/non notarisé. Cobalt reste
   un lien externe distinct, jamais un upload silencieux.

## Mouvement et adaptation

- Desktop : une scène centrale en position `sticky` et une progression au
  scroll, pilotée par les sections et non par une vidéo qui tourne en boucle.
  La lecture peut être manuelle au clavier et à la souris ; boutons précédent/
  suivant, états décrits par du texte, aucun scroll piégé.
- Mobile : abandon du sticky et de la frise large ; séquence verticale des
  mêmes preuves, CTA toujours à portée. `prefers-reduced-motion` affiche
  directement les étapes et supprime les transitions.
- Aucun réseau ou compte nécessaire pour explorer la page ; images/vidéo
  locales optimisées, texte FR/EN synchronisé, page lisible sans JS en FR.

## Médias à produire avant réalisation

- Les deux captures actuelles (`store/v2/screenshots/`) servent de preuve de
  départ. Il faut une **capture native de l'état de découpe**, puis idéalement
  un court enregistrement du parcours avec URL et fichiers fictifs. Ni le
  MP4 v1 (icône seule), ni un mockup HTML de l'app ne sont des preuves valables.
- Contrôler les dimensions, poids et lisibilité des captures à 390 et 1440 px.
  Ne jamais intégrer un contenu tiers dont les droits ne sont pas établis.

## Critères d'acceptation

- La première vue expose le vrai produit et l'installation, sans faux service
  interactif ; trois états vérifiables, contrôle clavier, `reduced-motion`.
- FR/EN, aucun débordement à 390/768/1440/1920 px, assets chargés localement,
  CTA réels, avis Gatekeeper et Cobalt exacts.
- La source finale remplace les fichiers **dans `store/website/` uniquement** ;
  `store/v1/` demeure intact, `store/v2/` garde le plan et les médias.
