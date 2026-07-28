# SongTranscriber

SongTranscriber records songs and transcribes their lyrics using Google's Gemini model through OpenRouter. It is a **Progressive Web App (PWA)** that can be installed on iPhone directly from Safari — no App Store required.

## Features

- **Audio Recording**: Record song ideas directly in the browser.
- **AI Transcription**: Automatically transcribe lyrics and generate song titles with `google/gemini-3.5-flash` through OpenRouter.
- **English Translation**: Automatically provides English translations for songs recorded in other languages.
- **Searchable Journal**: Store and organize songs with titles, lyrics, tags, and notes.
- **Local Persistence**: All data (API key, transcripts) stored locally in `localStorage` — nothing sent to any server other than OpenRouter.
- **Audio Playback**: Listen back to your recordings before transcribing.

## Quick Start

### Install on iPhone

1. Host the `web/` directory from any static web host (GitHub Pages, Netlify, etc.), or open `web/index.html` in a browser.
2. On iPhone: open the URL in **Safari**, tap the **Share** button, then **Add to Home Screen**.
3. Enter your OpenRouter API key in the **Settings** tab (stored in `localStorage` — never leaves your device).

### Prerequisites
- iPhone with iOS 14.3+ (Safari supports `MediaRecorder` from iOS 14.3)
- An [OpenRouter API key](https://openrouter.ai/keys)

## Project Structure (`web/`)

| File | Purpose |
|------|---------|
| `index.html` | Complete single-file PWA (HTML + CSS + JavaScript) |
| `manifest.json` | PWA manifest for "Add to Home Screen" |
| `sw.js` | Service worker — caches app shell for offline use |
| `icon.png` | App icon |

## Data Persistence

All data is stored locally on the device:

| Key | Value |
|-----|-------|
| `openrouterAPIKey` | Your OpenRouter API key |
| `songs` | JSON array of all transcribed songs |
| `defaultLanguage` | Selected recording language |

## License

This project is licensed under the MIT License.

