# SongTranscriber

SongTranscriber is an iOS application designed to record songs and transcribe their lyrics using Google's Gemini API. It features a searchable journal for storing song ideas, powered by SwiftData for local persistence.

## Features

- **Audio Recording**: Record song ideas with a simple, state-driven interface.
- **AI Transcription**: Automatically transcribe lyrics and generate song titles using the Gemini API.
- **English Translation**: Automatically provides English translations for songs recorded in other languages.
- **Searchable Journal**: Store and organize your songs with titles, lyrics, tags, and notes.
- **Local Persistence**: Powered by SwiftData for efficient and reliable local storage.
- **Audio Playback**: Listen back to your recordings directly within the app.

## Project Structure

- `App/`: Main entry point and SwiftData setup.
- `Models/`: SwiftData models (e.g., `Song`).
- `Services/`: Hardware access (audio) and API integration (Gemini).
- `ViewModels/`: Business logic and state management.
- `Views/`: SwiftUI user interface.

## Prerequisites

- Xcode 15+ (iOS 17.0+ SDK)
- Google Gemini API Key

## Setup

1. Clone the repository.
2. Open `SongTranscriber.xcodeproj` in Xcode.
3. Obtain a Gemini API key from [Google AI Studio](https://aistudio.google.com).
4. Enter your API key in the app's **Settings** tab, or set it as an environment variable `GEMINI_API_KEY`.

## Development

### Building
```bash
xcodebuild -scheme SongTranscriber -configuration Debug build
```

### Testing
```bash
xcodebuild test -scheme SongTranscriber
```

## License

This project is licensed under the MIT License.
