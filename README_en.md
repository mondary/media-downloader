# PKMediaDownloader

[🇬🇧 EN](README_en.md) · [🇫🇷 FR](README.md)

📦 version **v1.2026.2** · ☕ [Ko-fi](https://ko-fi.com/pouark)

✨ Native macOS video downloader powered by yt-dlp — supports YouTube (playlists), Instagram, X/Twitter, TikTok and thousands more sites.

## ✅ Features

- Download from thousands of sites via [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- **YouTube playlists** — automatic playlist URL detection
- **Social media auth** — cookie support for Instagram, X/Twitter, TikTok
- Convert/merge to MP4 (H.264/AAC)
- **Auto-copy** to clipboard after download
- **History** with thumbnails and quick actions
- **Video trim** — cut, save or copy an excerpt
- **Universal keyboard shortcut** — activate the app from anywhere (Cmd+Shift+6)
- **Menubar icon** — quick access
- **Auto-paste** — clipboard URLs are detected automatically

## 🧠 Usage

1. Paste a URL (Instagram, X, TikTok, YouTube, etc.)
2. Download starts automatically
3. File is copied to clipboard
4. Trim editor opens to cut the video
5. History keeps all your videos

### YouTube Playlists
Simply paste a YouTube playlist URL — the app automatically detects `list=` in the URL and downloads the entire playlist.

### Social Media (Instagram, X, TikTok)
1. Install a "Get cookies.txt" browser extension
2. Export cookies for the desired site
3. In **Settings → Social Media Auth**, select the cookies file

## ⚙️ Settings

| Setting | Description |
|---|---|
| Download folder | Choose where to save videos |
| Auto-copy | Automatically copy to clipboard |
| Cookies | Authentication file for social media |
| Accessibility | Required for global keyboard shortcuts |
| Shortcuts | Cmd+Shift+6 (activate), Return (copy), Cmd+Return (trim) |

## 🧾 Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| **Cmd+Shift+6** | Activate app (global) |
| **Return** | Copy selected file |
| **Cmd+Return** | Open trim mode |
| **Tab** | Toggle between input and history |
| **↑↓** | Navigate history |

## 📦 Build & Run

```sh
# Requirements
xcode-select --install
brew install yt-dlp ffmpeg

# Build
swift build

# Run
swift run

# Or via script
./script/build_and_run.sh
```

## 🧾 Changelog

- **v1.2026.2**: Fixed GitHub link in settings (now points to the fork)
- **v1.2026.1**: Fork of [pixel-point/media-downloader](https://github.com/pixel-point/media-downloader) with:
  - YouTube playlist support
  - Cookie auth for Instagram/X/TikTok
  - Menubar icon
  - Clipboard auto-paste
  - Redesigned settings (SwiftUI)
  - Links to original project

## 🔗 Links

- Original project: [pixel-point/media-downloader](https://github.com/pixel-point/media-downloader)
- Fork: [PKMediaDownloader](https://github.com)
- yt-dlp: [github.com/yt-dlp/yt-dlp](https://github.com/yt-dlp/yt-dlp)

---

🇫🇷 Voir [README.md](README.md) pour la version française.
