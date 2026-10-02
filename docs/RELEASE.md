# DMG + Homebrew — état et procédure

Release PK `v1.2026.12` : DMG Apple Silicon signé ad hoc, non notarisé.
Le tap `mondary/homebrew-tap` contient `pkmedia-downloader` avec son SHA-256
vérifié. Une identité Developer ID et Xcode complet restent nécessaires pour
une future release notarisée avec tests XCTest.

## Prérequis

1. Installer un Xcode/SDK capable de compiler les macros SwiftUI du projet.
   `SDKROOT=.../MacOSX26.5.sdk swift build --product PKMediaDownloader`
   fonctionne ici ; les tests échouent car les Command Line Tools n'ont pas
   `XCTest.framework`. Un Xcode complet est requis pour une release signée.
2. Configurer une identité `Developer ID Application` et les paramètres de
   notarisation dans `.env` (voir `.env.example`, jamais suivi par Git).
3. Vérifier la licence de l'amont avant de qualifier le fork d'open source.
4. Finaliser de vraies captures d'interface avec des données fictives.

## Publication après validation

```sh
# Une fois le commit poussé sur origin/main, sans modification locale :
./script/release_macos.sh v1.2026.12

# Après vérification HTTP du DMG de cette release :
./script/generate_cask.sh v1.2026.12 arm64 /chemin/homebrew-tap/Casks/pkmedia-downloader.rb
```

Mettre à jour `CHANGELOG.md` et les README FR/EN du tap dans son propre dépôt,
valider le cask (`ruby -c`, `brew audit --cask`, `brew info --cask`), pousser
le tap, puis tester une installation propre. Ensuite seulement remplacer les
textes d'attente de la landing et des README par le lien direct du DMG et la
commande brew. Le cask dépend de `yt-dlp` et `ffmpeg`.

Le script de génération refuse un tag sans asset DMG publié et calcule le
SHA-256 des octets téléchargés, pas d'un artefact CI local. Ne pas utiliser
`sha256 :no_check` ni désactiver la quarantaine macOS pour compenser une
signature absente.

Pour contrôler localement le packaging sans publier ni prétendre qu'il est
signé/notarisé : `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk CI_UNSIGNED=1 SKIP_TESTS=1 SKIP_DMG_FINDER_LAYOUT=true ./script/package_macos.sh`.
Le contrôle du 2026-10-02 a produit `dist/release/PKMediaDownloader-v1.2026.12-macos-arm64.dmg` : checksum DMG valide, `.app` et `pkmd` arm64, version bundle `1.2026.12`, signature **ad hoc** sans Team ID. Cet artefact local est ignoré par Git et ne doit pas être utilisé comme asset publié.
