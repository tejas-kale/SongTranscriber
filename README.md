# SongTranscriber

SongTranscriber records songs and transcribes their lyrics using Google's Gemini AI. It is available as both a **Progressive Web App (PWA)** installable from Safari on iPhone and as a native iOS app.

## Features

- **Audio Recording**: Record song ideas directly in the browser or app.
- **AI Transcription**: Automatically transcribe lyrics and generate song titles using the Gemini API.
- **English Translation**: Automatically provides English translations for songs recorded in other languages.
- **Searchable Journal**: Store and organize songs with titles, lyrics, tags, and notes.
- **Local Persistence**: All data (API key, transcripts) stored locally — nothing sent to any server other than the Gemini API.
- **Audio Playback**: Listen back to your recordings before transcribing.

---

## Option 1 — Progressive Web App (Safari on iPhone)

The web app lives in the `web/` directory and requires no build step or App Store installation.

### Quick Start

1. Serve the `web/` directory from any static web host (GitHub Pages, Netlify, etc.), or open `web/index.html` directly in a browser.
2. On iPhone: open the URL in **Safari**, tap the **Share** button, then **Add to Home Screen**.
3. Enter your Gemini API key in the **Settings** tab (stored in `localStorage` — never leaves your device).

### Prerequisites
- iPhone with iOS 14.3+ (Safari supports `MediaRecorder` from iOS 14.3)
- A [Google Gemini API key](https://aistudio.google.com)

### Project Structure (`web/`)
| File | Purpose |
|------|---------|
| `index.html` | Complete single-file PWA (HTML + CSS + JavaScript) |
| `manifest.json` | PWA manifest for "Add to Home Screen" |
| `sw.js` | Service worker — caches app shell for offline use |
| `icon.png` | App icon |

### Data Persistence
- **API key** → `localStorage` key `geminiAPIKey`
- **Songs / transcripts** → `localStorage` key `songs` (JSON array)
- **Default language** → `localStorage` key `defaultLanguage`

---

## Option 2 — Native iOS App (Xcode)

### Prerequisites
- Xcode 15+ (iOS 17.0+ SDK)
- Google Gemini API Key

### Setup

1. Clone the repository.
2. Open `SongTranscriber.xcodeproj` in Xcode.
3. Obtain a Gemini API key from [Google AI Studio](https://aistudio.google.com).
4. Enter your API key in the app's **Settings** tab, or set it as an environment variable `GEMINI_API_KEY`.

### Building
```bash
xcodebuild -scheme SongTranscriber -configuration Debug build
```

### Testing
```bash
xcodebuild test -scheme SongTranscriber
```

### Project Structure (`SongTranscriber/`)
- `App/`: Main entry point and SwiftData setup.
- `Models/`: SwiftData models (e.g., `Song`).
- `Services/`: Hardware access (audio) and API integration (Gemini).
- `ViewModels/`: Business logic and state management.
- `Views/`: SwiftUI user interface.

---

## License

This project is licensed under the MIT License.
