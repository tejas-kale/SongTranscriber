//
//  SettingsView.swift
//  SongTranscriber
//
//  Created by Tejas Kale on 05/01/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("geminiAPIKey") private var apiKey = ""
    @AppStorage("defaultLanguage") private var selectedLanguage = "English"
    @State private var showAPIKeyField = false

    private let supportedLanguages = [
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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if showAPIKeyField {
                        SecureField("Enter API Key", text: $apiKey)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                    } else {
                        HStack {
                            Text("API Key")
                            Spacer()
                            if apiKey.isEmpty {
                                Text("Not Set")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("••••••••")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Button(showAPIKeyField ? "Done" : "Edit") {
                        showAPIKeyField.toggle()
                    }
                } header: {
                    Text("Gemini API Key")
                } footer: {
                    Text("Get your API key from Google AI Studio (https://aistudio.google.com)")
                }

                Section {
                    Picker("Default Language", selection: $selectedLanguage) {
                        ForEach(supportedLanguages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                } header: {
                    Text("Recording Settings")
                } footer: {
                    Text("This language will be pre-selected when recording new songs")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Bundle ID")
                        Spacer()
                        Text("com.songtranscriber.app")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
