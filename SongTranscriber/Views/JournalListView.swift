//
//  JournalListView.swift
//  SongTranscriber
//
//  Created by Tejas Kale on 05/01/26.
//

import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.recordingDate, order: .reverse) private var songs: [Song]
    @State private var searchText = ""
    @State private var indexSetToDelete: IndexSet?
    @State private var showDeleteConfirmation = false

    private var filteredSongs: [Song] {
        if searchText.isEmpty {
            return songs
        }
        return songs.filter { song in
            song.title.localizedCaseInsensitiveContains(searchText) ||
            song.lyrics.localizedCaseInsensitiveContains(searchText) ||
            song.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ||
            song.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredSongs.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView(
                            "No Songs Yet",
                            systemImage: "music.note.list",
                            description: Text("Record your first song to get started")
                        )
                    } else {
                        ContentUnavailableView.search
                    }
                } else {
                    List {
                        ForEach(filteredSongs) { song in
                            NavigationLink(value: song) {
                                SongRowView(song: song)
                            }
                        }
                        .onDelete { offsets in
                            indexSetToDelete = offsets
                            showDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle("Songs")
            .searchable(text: $searchText, prompt: "Search songs...")
            .navigationDestination(for: Song.self) { song in
                SongDetailView(song: song)
            }
            .alert("Delete Song", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    indexSetToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let offsets = indexSetToDelete {
                        deleteSongs(at: offsets)
                    }
                    indexSetToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete the selected song(s)? This will also delete the audio recording(s).")
            }
        }
    }

    private func deleteSongs(at offsets: IndexSet) {
        for index in offsets {
            let song = filteredSongs[index]

            if let audioFileName = song.audioFileName {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let audioURL = documentsPath.appendingPathComponent(audioFileName)
                try? FileManager.default.removeItem(at: audioURL)
            }

            modelContext.delete(song)
        }
    }
}

struct SongRowView: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(song.title)
                    .font(.headline)
                Spacer()
                Text(song.language)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }

            Text(lyricsPreview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Text(song.displayDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !song.tags.isEmpty {
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(Array(song.tags.prefix(3)), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        if song.tags.count > 3 {
                            Text("+\(song.tags.count - 3)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var lyricsPreview: String {
        let preview = song.lyrics.prefix(100)
        return preview.count < song.lyrics.count ? "\(preview)..." : String(preview)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Song.self, configurations: config)

    let song = Song(
        title: "Test Song",
        lyrics: "This is a test song with some lyrics that will be displayed in the preview",
        language: "English",
        tags: ["Rock", "Pop", "Indie"]
    )
    container.mainContext.insert(song)

    return JournalListView()
        .modelContainer(container)
}
