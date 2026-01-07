//
//  GeminiAPIService.swift
//  SongTranscriber
//
//  Created by Tejas Kale on 05/01/26.
//

import Foundation

enum GeminiAPIError: Error {
    case invalidURL
    case invalidResponse
    case apiKeyNotSet
    case transcriptionFailed(String)
}

struct TranscriptionResult {
    let title: String
    let lyrics: String
    let englishTranslation: String?
}

final class GeminiAPIService {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let uploadURL = "https://generativelanguage.googleapis.com/upload/v1beta/files"
    private let model = "gemini-3-flash-preview"

    private var apiKey: String? {
        if let userDefaultsKey = UserDefaults.standard.string(forKey: "geminiAPIKey"), !userDefaultsKey.isEmpty {
            return userDefaultsKey
        }
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String, !plistKey.isEmpty {
            return plistKey
        }
        return nil
    }

    func transcribeSong(audioURL: URL, language: String) async throws -> TranscriptionResult {
        guard let apiKey = apiKey else {
            throw GeminiAPIError.apiKeyNotSet
        }

        let fileUri = try await uploadAudioFile(audioURL: audioURL, apiKey: apiKey)
        let result = try await generateTranscription(fileUri: fileUri, language: language, apiKey: apiKey)

        return result
    }

    private func uploadAudioFile(audioURL: URL, apiKey: String) async throws -> String {
        let audioData = try Data(contentsOf: audioURL)
        let fileSize = audioData.count

        // Step 1: Initialize resumable upload
        guard let initURL = URL(string: uploadURL) else {
            throw GeminiAPIError.invalidURL
        }

        var initRequest = URLRequest(url: initURL)
        initRequest.httpMethod = "POST"
        initRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        initRequest.setValue("resumable", forHTTPHeaderField: "X-Goog-Upload-Protocol")
        initRequest.setValue("start", forHTTPHeaderField: "X-Goog-Upload-Command")
        initRequest.setValue("\(fileSize)", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Length")
        initRequest.setValue("audio/aac", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Type")
        initRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let metadata: [String: Any] = [
            "file": [
                "display_name": "audio_recording.m4a"
            ]
        ]
        initRequest.httpBody = try JSONSerialization.data(withJSONObject: metadata)

        let (_, initResponse) = try await URLSession.shared.data(for: initRequest)

        guard let httpInitResponse = initResponse as? HTTPURLResponse else {
            throw GeminiAPIError.invalidResponse
        }

        print("Init Upload Response Status: \(httpInitResponse.statusCode)")

        guard httpInitResponse.statusCode == 200,
              let uploadURLString = httpInitResponse.value(forHTTPHeaderField: "x-goog-upload-url"),
              let uploadURL = URL(string: uploadURLString) else {
            throw GeminiAPIError.transcriptionFailed("Failed to get upload URL. Status: \(httpInitResponse.statusCode)")
        }

        // Step 2: Upload the actual file
        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.httpMethod = "POST"
        uploadRequest.setValue("upload, finalize", forHTTPHeaderField: "X-Goog-Upload-Command")
        uploadRequest.setValue("0", forHTTPHeaderField: "X-Goog-Upload-Offset")
        uploadRequest.httpBody = audioData

        let (uploadData, uploadResponse) = try await URLSession.shared.data(for: uploadRequest)

        guard let httpUploadResponse = uploadResponse as? HTTPURLResponse else {
            throw GeminiAPIError.invalidResponse
        }

        // Log response for debugging
        if let responseString = String(data: uploadData, encoding: .utf8) {
            print("Upload Response Status: \(httpUploadResponse.statusCode)")
            print("Upload Response Body: \(responseString)")
        }

        guard httpUploadResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: uploadData) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiAPIError.transcriptionFailed("Upload failed: \(message)")
            }
            throw GeminiAPIError.transcriptionFailed("Upload failed with status: \(httpUploadResponse.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: uploadData) as? [String: Any] else {
            throw GeminiAPIError.transcriptionFailed("Invalid JSON response from upload")
        }

        // Get the file URI from the response
        if let file = json["file"] as? [String: Any],
           let uri = file["uri"] as? String {
            print("File uploaded successfully. URI: \(uri)")
            return uri
        }

        throw GeminiAPIError.transcriptionFailed("Failed to get file URI. Response: \(json)")
    }

    private func generateTranscription(fileUri: String, language: String, apiKey: String) async throws -> TranscriptionResult {
        guard let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(apiKey)") else {
            throw GeminiAPIError.invalidURL
        }

        let prompt = """
        Transcribe this song recording in \(language). Return the result as a JSON object with the following structure:
        {
          "title": "The song title or 'Untitled Song' if unclear",
          "lyrics": "The complete song lyrics",
          "englishTranslation": "The English translation of the lyrics. Only include this field if the song is NOT in English."
        }

        Format the lyrics with one sentence per line.
        Only return the JSON, no additional text.
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "fileData": [
                                "mimeType": "audio/aac",
                                "fileUri": fileUri
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "topK": 32,
                "topP": 1,
                "maxOutputTokens": 8192
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiAPIError.invalidResponse
        }

        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Generation Response Status: \(httpResponse.statusCode)")
            print("Generation Response Body: \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiAPIError.transcriptionFailed("Generation failed: \(message)")
            }
            throw GeminiAPIError.transcriptionFailed("Generation failed with status: \(httpResponse.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiAPIError.transcriptionFailed("Invalid JSON response from generation")
        }

        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiAPIError.transcriptionFailed("Failed to parse generation response. JSON: \(json)")
        }

        return try parseTranscriptionJSON(from: text)
    }

    private func parseTranscriptionJSON(from text: String) throws -> TranscriptionResult {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if jsonString.contains("```json") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let title = json["title"] as? String,
              let lyrics = json["lyrics"] as? String else {
            throw GeminiAPIError.transcriptionFailed("Failed to parse transcription JSON")
        }
        
        let englishTranslation = json["englishTranslation"] as? String

        return TranscriptionResult(title: title, lyrics: lyrics, englishTranslation: englishTranslation)
    }
}
