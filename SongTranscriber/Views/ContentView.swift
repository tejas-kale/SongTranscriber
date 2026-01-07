//
//  ContentView.swift
//  SongTranscriber
//
//  Created by Tejas Kale on 05/01/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "waveform.circle.fill")
                }

            JournalListView()
                .tabItem {
                    Label("Songs", systemImage: "music.note.list")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Song.self, inMemory: true)
}
