//
//  RecordingViewModel.swift
//  SongTranscriber
//
//  Created by Tejas Kale on 05/01/26.
//

import Foundation
import SwiftData

enum RecordingState {
    case idle
    case recording
    case recorded
    case transcribing
    case transcribed(Song)
    case error(String)
}

@Observable
final class RecordingViewModel {
    let audioService = AudioRecordingService()
    let geminiService = GeminiAPIService()

    var selectedLanguage: String
    var recordingState: RecordingState = .idle

    let supportedLanguages = [
        "English",
        "Spanish",
        "French",
        "German",
        "Italian",
        "Portuguese",
        "Japanese",
        "Korean",
        "Chinese",
        "Hindi",
        "Arabic"
    ]

    init() {
        self.selectedLanguage = UserDefaults.standard.string(forKey: "defaultLanguage") ?? "English"
    }

    func requestPermissions() async -> Bool {
        return await audioService.requestMicrophonePermission()
    }

    func startRecording() {
        audioService.startRecording()
        recordingState = .recording
    }

    func stopRecording() {
        audioService.stopRecording()
        recordingState = .recorded
    }

    func transcribeRecording(modelContext: ModelContext) async {
        // Refresh language from settings
        self.selectedLanguage = UserDefaults.standard.string(forKey: "defaultLanguage") ?? "English"

        guard let audioURL = audioService.currentRecordingURL else {
            recordingState = .error("No recording found")
            return
        }

        recordingState = .transcribing

        do {
            let result = try await geminiService.transcribeSong(audioURL: audioURL, language: selectedLanguage)

            let song = Song(
                title: result.title,
                lyrics: result.lyrics,
                translation: result.englishTranslation,
                language: selectedLanguage,
                audioFileName: audioURL.lastPathComponent
            )

            modelContext.insert(song)
            try modelContext.save()

            recordingState = .transcribed(song)
        } catch GeminiAPIError.apiKeyNotSet {
            recordingState = .error("Gemini API key not set. Please add your API key in Settings.")
        } catch GeminiAPIError.transcriptionFailed(let message) {
            recordingState = .error("Transcription failed: \(message)")
        } catch {
            recordingState = .error("Failed to transcribe: \(error.localizedDescription)")
        }
    }

    func reset() {
        if let url = audioService.currentRecordingURL {
            audioService.deleteRecording(url: url)
        }
        audioService.recordingTime = 0
        audioService.currentRecordingURL = nil
        recordingState = .idle
    }

    func playRecording() {
        guard let url = audioService.currentRecordingURL else { return }
        audioService.playRecording(url: url)
    }

    func stopPlaying() {
        audioService.stopPlaying()
    }
}
