# Proposition de rangement — PKMediaDownloader

Le dépôt est un **fork**. Ne pas déplacer `Package.swift`, `Sources/`, `Tests/`,
`Resources/`, `icon.png`, les README ni `CHANGELOG.md` : ce sont les points
d'entrée de SwiftPM, de la documentation et du build.

## 1. Déchets générés suivis par Git

- `graphify-out/` contient 45 fichiers de cache indexés par Git. Désormais ignoré
  pour les nouveaux fichiers, il reste suivi tant qu'une suppression de l'index
  n'a pas été validée. Après accord : `git rm -r --cached graphify-out` ; conserver
  les fichiers locaux, puis vérifier que Graphify les régénère sans dépendance.
- `.DS_Store` et `Sources/.DS_Store` sont locaux/ignorés, pas des sources.
- `dist/` et `.build/` sont déjà ignorés : ne pas y publier de sources ni de captures.

## 2. Média de racine

- `icon.png` **reste à la racine** par convention PK ; `Resources/AppIcon.icns`
  reste l'icône de build.
- `image.png` était identique à `store/v1/screenshots/01-apercu-projet.png`
  (SHA-256 vérifié). Cette image est une **icône**, pas une capture
  d'interface. Après validation des références externes, garder seulement la copie
  sous `store/v1/` ou archiver l'original ; les vraies captures d'app avec données
  fictives sont maintenant dans `store/v2/screenshots/`. L'utilisateur a déjà
  déplacé `image.png` vers `archive/` avant cette refonte : ne pas modifier ce choix.

## 3. Scripts et release

- Garder `script/` (nom actuel et chemins CI). Le script `release_macos.sh`
  réutilise désormais `package_macos.sh` au lieu d'embarquer un second packager.
- Quand un DMG signé/notarisé sera publié, générer le cask depuis **l'asset
  distant** avec `script/generate_cask.sh`, puis le déposer dans le tap
  `mondary/homebrew-tap`. Ne jamais deviner son SHA-256.
- `store/website/index.html` est la version courante éditable et déployable ;
  `script/website.sh` en vérifie les fichiers. Les anciennes versions sont
  préservées dans `store/v1/`, `store/v2/` et `store/v3/`. À la prochaine
  refonte, archiver `website/` en `v4/` avant de créer le nouveau `website/`.
  Aucun upload n'est implicite.

## Ordre recommandé

1. Vérifier les hashes et références de `image.png` et les usages de Graphify.
2. Déindexer les caches avec un commit de nettoyage isolé, sans toucher aux
   fichiers locaux ni aux autres modifications du développeur.
3. Capturer l'UI réelle avec des données fictives ; remplacer les médias qui ne
   montrent aujourd'hui que l'icône.
4. Faire une release signée, puis publier/valider le cask et activer les CTA.
