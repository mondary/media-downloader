# PKMediaDownloader

[🇫🇷 FR](README.md) · [🇬🇧 EN](README_en.md)

📦 version **v1.2026.7** · ☕ [Ko-fi](https://ko-fi.com/pouark)

✨ Téléchargeur vidéo natif macOS basé sur yt-dlp — supporte YouTube (playlists), Instagram, X/Twitter, TikTok et des milliers d'autres sites.

## ✅ Fonctionnalités

- Téléchargement depuis des milliers de sites via [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- **Playlists YouTube** — détection automatique des URLs playlist
- **Auth social media** — support cookies pour Instagram, X/Twitter, TikTok
- Conversion/merge en MP4 (H.264/AAC)
- **Auto-copie** dans le presse-papiers après téléchargement
- **Historique** avec thumbnails et actions rapides
- **Trim vidéo** — couper, sauvegarder ou copier un extrait
- **Raccourci clavier universel** — active l'app depuis n'importe où (Cmd+Shift+6)
- **Icône menubar** — accès rapide
- **Auto-paste** — les URLs du presse-papiers sont détectées automatiquement

## 🧠 Utilisation

1. Colle une URL (Instagram, X, TikTok, YouTube, etc.)
2. Le téléchargement démarre automatiquement
3. Le fichier est copié dans le presse-papiers
4. L'éditeur de trim s'ouvre pour couper la vidéo
5. L'historique garde toutes tes vidéos

### Playlists YouTube
Colle simplement une URL de playlist YouTube — l'app détecte automatiquement `list=` dans l'URL et télécharge toute la playlist.

### Social Media (Instagram, X, TikTok)
1. Installe une extension navigateur "Get cookies.txt"
2. Exporte les cookies pour le site souhaité
3. Dans **Settings → Social Media Auth**, sélectionne le fichier cookies

## ⚙️ Réglages

| Paramètre | Description |
|---|---|
| Dossier de téléchargement | Choisir où sauvegarder les vidéos |
| Auto-copie | Copier automatiquement dans le presse-papiers |
| Cookies | Fichier d'authentification pour les réseaux sociaux |
| Accessibilité | Nécessaire pour les raccourcis clavier globaux |
| Raccourcis | Cmd+Shift+6 (activer), Return (copier), Cmd+Return (trim) |

## 🧾 Raccourcis Clavier

| Raccourci | Action |
|---|---|
| **Cmd+Shift+6** | Activer l'app (global) |
| **Return** | Copier le fichier sélectionné |
| **Cmd+Return** | Ouvrir le mode trim |
| **Tab** | basculer entre input et historique |
| **↑↓** | Naviguer dans l'historique |

## 📦 Build & Run

```sh
# Prérequis
xcode-select --install
brew install yt-dlp ffmpeg

# Build
swift build

# Lancer
swift run

# Ou via le script
./script/build_and_run.sh
```

## 🧾 Changelog

- **v1.2026.7** : « Check for Updates » vérifie le dépôt fork au lieu de l'amont
- **v1.2026.6** : Mise à jour de yt-dlp depuis les réglages (version affichée + bouton)
- **v1.2026.5** : `.gitignore` ignore le fichier `Icon?` parasite macOS
- **v1.2026.4** : Dossier `store/` avec kit promotionnel (bannière, card, capture, démo)
- **v1.2026.3** : Historique playlist item par item, panneau historique redimensionnable avec bouton « Vider »
- **v1.2026.2** : Correction du lien GitHub dans les réglages (pointe vers le fork)
- **v1.2026.1** : Fork de [pixel-point/media-downloader](https://github.com/pixel-point/media-downloader) avec :
  - Support playlists YouTube
  - Auth cookies pour Instagram/X/TikTok
  - Icône menubar
  - Auto-paste du presse-papiers
  - Settings redesignés (SwiftUI)
  - Liens vers le projet original

## 🔗 Liens

- Projet original : [pixel-point/media-downloader](https://github.com/pixel-point/media-downloader)
- Fork : [PKMediaDownloader](https://github.com)
- yt-dlp : [github.com/yt-dlp/yt-dlp](https://github.com/yt-dlp/yt-dlp)

---

🇬🇧 See [README_en.md](README_en.md) for English version.
