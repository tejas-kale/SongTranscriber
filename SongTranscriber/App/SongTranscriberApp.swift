//
//  SongTranscriberApp.swift
//  SongTranscriber
//
//  Created by Tejas Kale on 05/01/26.
//

import SwiftUI
import SwiftData

@main
struct SongTranscriberApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Song.self)
    }
}
