# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SongTranscriber is an iOS application that records songs, transcribes their lyrics using Google's Gemini API, and stores them in a searchable journal with SwiftData persistence.

**Platform**: iOS 17.0+
**Language**: Swift
**UI Framework**: SwiftUI
**Data Persistence**: SwiftData
**API**: Google Gemini 3 Flash (gemini-3-flash-preview model)
**Bundle ID**: com.songtranscriber.app

## Build and Test Commands

### Building the Project
```bash
xcodebuild -scheme SongTranscriber -configuration Debug build
```

### Running Tests
```bash
# Run all tests
xcodebuild test -scheme SongTranscriber

# Run only unit tests
xcodebuild test -scheme SongTranscriber -only-testing:SongTranscriberTests

# Run only UI tests
xcodebuild test -scheme SongTranscriber -only-testing:SongTranscriberUITests
```

### Cleaning Build Artifacts
```bash
xcodebuild clean -scheme SongTranscriber
```

## Architecture

### Project Structure

```
SongTranscriber/
├── App/
│   └── SongTranscriberApp.swift       # Main app entry with SwiftData container
├── Models/
│   └── Song.swift                     # SwiftData model for song storage
├── Services/
│   ├── AudioRecordingService.swift    # AVFoundation-based audio recording/playback
│   └── GeminiAPIService.swift         # Gemini API integration for transcription
├── ViewModels/
│   └── RecordingViewModel.swift       # Recording workflow state management
├── Views/
│   ├── ContentView.swift              # Root TabView container
│   ├── RecordingView.swift            # Recording interface with state machine
│   ├── JournalListView.swift          # Song library with search
│   └── SongDetailView.swift           # Song detail/edit view with custom components
├── Assets.xcassets/
└── Info.plist
```

### Data Layer

**Song Model** (`Song.swift`):
- SwiftData `@Model` class storing: title, lyrics, language, tags, notes, recordingDate, audioFileName
- Persisted automatically by SwiftData ModelContainer
- Audio files stored separately in Documents directory with UUID.m4a naming

### Service Layer

**AudioRecordingService** (`AudioRecordingService.swift`):
- `@Observable` class managing AVAudioRecorder/AVAudioPlayer
- Records to M4A format (44.1kHz, stereo, AAC codec)
- Timer-based recording duration tracking (updates every 0.1s)
- Handles microphone permissions via AVAudioSession

**GeminiAPIService** (`GeminiAPIService.swift`):
- Two-step API flow:
  1. Upload audio file to `/files` endpoint via multipart/form-data
  2. Send generation request to `/models/gemini-3-flash:generateContent` with file URI
- API key loaded from `GEMINI_API_KEY` environment variable or Info.plist
- Returns structured `TranscriptionResult` with title and lyrics
- Parses JSON from API response, handling markdown code block wrapping

### ViewModel Layer

**RecordingViewModel** (`RecordingViewModel.swift`):
- `@Observable` class coordinating AudioRecordingService and GeminiAPIService
- State machine with 6 states: idle, recording, recorded, transcribing, transcribed, error
- Manages language selection (11 supported languages)
- Creates and persists Song objects to SwiftData ModelContext

### View Layer

**ContentView** (`ContentView.swift`):
- Root TabView with two tabs: Record and Journal

**RecordingView** (`RecordingView.swift`):
- State-driven UI showing different content/buttons per RecordingState
- Language picker (wheel style) visible only in idle state
- Permission handling with alert for denied microphone access
- Navigation to SongDetailView upon successful transcription

**JournalListView** (`JournalListView.swift`):
- SwiftData `@Query` sorted by recordingDate (descending)
- Searchable by title, lyrics, tags, and notes
- Swipe-to-delete removes both Song entity and audio file
- Custom SongRowView with language badge, lyrics preview, and tag display

**SongDetailView** (`SongDetailView.swift`):
- `@Bindable` Song editing with inline title editing
- Tag management with custom FlowLayout for wrapping
- Notes TextEditor with placeholder text
- Share functionality using UIActivityViewController
- Custom components: TagView (pill-shaped), FlowLayout (wrapping layout), ShareSheet (UIKit wrapper)

## Key Conventions

### SwiftData Patterns
- ModelContainer initialized in app entry: `.modelContainer(for: Song.self)`
- ModelContext injected via environment: `@Environment(\.modelContext)`
- Queries use `@Query` property wrapper with sort descriptors
- Two-way binding with `@Bindable` for editing persisted models

### Observable Pattern
- Use `@Observable` macro (not `ObservableObject`) for view models and services
- No need for `@Published` - all properties are automatically observable
- State updates trigger view refreshes automatically

### Audio Recording
- Audio session category: `.playAndRecord`
- Recording format: M4A (MPEG-4 AAC)
- Files stored in Documents directory: `FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]`
- Filename pattern: `UUID().uuidString + ".m4a"`

### API Integration
- Gemini API key configuration (priority order):
  1. **Settings tab** (UserDefaults: `geminiAPIKey`) - Recommended
  2. Environment variable: `GEMINI_API_KEY`
  3. Info.plist key: `GEMINI_API_KEY`
- Base URL: `https://generativelanguage.googleapis.com/v1beta`
- Model: `gemini-1.5-flash`
- Generation config: temperature=0.4, topK=32, topP=1, maxOutputTokens=8192
- API uses two-step process: File upload → Content generation
- Debug logging enabled in console for troubleshooting API responses

### Testing Framework
This project uses Swift Testing (not XCTest):
- Test functions marked with `@Test` attribute
- Assertions use `#expect(...)` instead of `XCAssert*`
- Tests are defined in structs, not classes

## Important Implementation Notes

1. **Microphone Permission**: Required for recording - declared in Info.plist with `NSMicrophoneUsageDescription`
2. **File Management**: Audio files must be manually deleted when Songs are removed (not automatic)
3. **Navigation**: Uses NavigationStack with `.navigationDestination(for: Song.self)` for type-safe navigation
4. **State Management**: RecordingViewModel state machine drives UI rendering - always update state before/after async operations
5. **Custom Layouts**: FlowLayout implements Swift's Layout protocol for tag wrapping
6. **Previews**: Use in-memory ModelContainer for SwiftUI previews: `ModelConfiguration(isStoredInMemoryOnly: true)`

## Common Development Tasks

### Adding a New Supported Language
1. Add language string to `RecordingViewModel.supportedLanguages` array
2. Language automatically appears in picker - no other changes needed

### Modifying Song Schema
1. Update `Song` model class in `Song.swift`
2. SwiftData handles migration automatically for additive changes
3. For breaking changes, implement migration logic or delete/reinstall app

### Customizing Transcription Prompt
- Edit prompt in `GeminiAPIService.generateTranscription()`
- Maintain JSON output format: `{"title": "...", "lyrics": "..."}`

### Testing API Integration
- **Recommended**: Add API key via Settings tab in the app
- Alternative: Set `GEMINI_API_KEY` environment variable before running
- Alternative: Add to Info.plist (not recommended for production/Git)
- Check Xcode console for detailed API response logs during transcription

## Troubleshooting

### Transcription Errors

**"Failed to get file URI from upload response"**
- Verify your Gemini API key is correct in Settings
- Check Xcode console for detailed API response
- Ensure API key has File API access enabled
- Check that model name is `gemini-3-flash-preview` (not `gemini-1.5-flash`)

**"API key not set"**
- Open Settings tab and enter your Gemini API key
- Get key from: https://aistudio.google.com

**Network/Upload Issues**
- Verify internet connection
- Check Xcode console for HTTP status codes
- Ensure audio file was recorded successfully (check Documents folder)
