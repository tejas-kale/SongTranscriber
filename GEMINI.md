# SongTranscriber

## Project Overview

SongTranscriber is an iOS application designed to record songs and transcribe their lyrics using Google's Gemini API. It features a searchable journal for storing song ideas, powered by SwiftData for local persistence.

*   **Platform:** iOS 17.0+
*   **Language:** Swift
*   **UI Framework:** SwiftUI
*   **Architecture:** MVVM (Model-View-ViewModel) with a Service layer
*   **Data Persistence:** SwiftData
*   **AI Integration:** Google Gemini API (`gemini-3-flash-preview` model)

## Building and Running

### Prerequisites
*   Xcode 15+ (supporting iOS 17 SDK)
*   A Google Gemini API Key

### Build Commands

To build the project:
```bash
xcodebuild -scheme SongTranscriber -configuration Debug build
```

To run tests:
```bash
# Run all tests
xcodebuild test -scheme SongTranscriber

# Run specific test suites
xcodebuild test -scheme SongTranscriber -only-testing:SongTranscriberTests
xcodebuild test -scheme SongTranscriber -only-testing:SongTranscriberUITests
```

### Configuration
The app requires a Gemini API key to function. It checks for the key in the following order:
1.  **App Settings:** User-entered key stored in `UserDefaults` (Recommended for development/testing).
2.  **Environment Variable:** `GEMINI_API_KEY`.
3.  **Info.plist:** `GEMINI_API_KEY` entry.

## Architecture

### Directory Structure
*   `App/`: Contains the main app entry point (`SongTranscriberApp.swift`) and SwiftData container setup.
*   `Models/`: SwiftData models. `Song.swift` is the core entity.
*   `Services/`: Handles external interactions and hardware access.
    *   `AudioRecordingService.swift`: Manages `AVAudioRecorder` and `AVAudioPlayer` for recording and playback.
    *   `GeminiAPIService.swift`: Handles file uploads and content generation requests to the Gemini API.
*   `ViewModels/`: Manages state and business logic for views.
    *   `RecordingViewModel.swift`: Orchestrates the recording-to-transcription flow.
*   `Views/`: SwiftUI views.
    *   `ContentView.swift`: Main tab container.
    *   `RecordingView.swift`: Recording interface.
    *   `JournalListView.swift`: List of saved songs.
    *   `SongDetailView.swift`: Detailed view for editing and reviewing songs.

### Key Conventions

*   **SwiftData:** Used for persisting `Song` objects. The `ModelContainer` is initialized in the `App` struct.
*   **Concurrency:** Heavy use of Swift's `async`/`await` for API calls and file operations.
*   **Observable Pattern:** ViewModels and Services use the `@Observable` macro for state management.
*   **Audio Storage:** Audio files (`.m4a`) are stored in the app's Documents directory, linked to `Song` entities via filenames. They are manually managed (deleted when the Song is deleted).
*   **API Integration:** The `GeminiAPIService` performs a two-step process:
    1.  Resumable upload of the audio file to the Google Cloud.
    2.  Generation request to `gemini-3-flash-preview` with the file URI and a specific prompt for JSON output.

## Development Notes

*   **Microphone Access:** The app requires microphone permission (`NSMicrophoneUsageDescription` in `Info.plist`).
*   **Testing:** The project uses the Swift Testing framework (`@Test` macro) rather than XCTest for unit tests.
*   **UI State:** `RecordingViewModel` uses a state machine (idle, recording, transcribing, etc.) to drive the `RecordingView` UI.
