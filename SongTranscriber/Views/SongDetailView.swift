//
//  SongDetailView.swift
//  SongTranscriber
//
//  Created by Tejas Kale on 05/01/26.
//

import SwiftUI
import SwiftData

struct SongDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var song: Song
    
    @State private var showShareSheet = false
    @State private var showEditSong = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                titleSection
                metadataSection
                if !song.tags.isEmpty {
                    tagsDisplaySection
                }
                if !song.notes.isEmpty {
                    notesDisplaySection
                }
                lyricsSection
                if let translation = song.translation, !translation.isEmpty {
                    translationDisplaySection(translation: translation)
                }
            }
            .padding()
        }
        .navigationTitle("Song Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Menu {
                        Button(action: { showEditSong = true }) {
                            Label("Edit Song", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Delete Song", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        .sheet(isPresented: $showEditSong) {
            EditSongView(song: song, isPresented: $showEditSong)
        }
        .alert("Delete Song", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSong()
            }
        } message: {
            Text("Are you sure you want to delete '\(song.title)'? This action cannot be undone and will delete the audio recording.")
        }
    }

    private var titleSection: some View {
        Text(song.title)
            .font(.title2)
            .fontWeight(.semibold)
    }

    private var metadataSection: some View {
        HStack {
            Label(song.language, systemImage: "globe")
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .cornerRadius(8)

            Label(song.displayDate, systemImage: "calendar")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    private var tagsDisplaySection: some View {
        FlowLayout(spacing: 8) {
            ForEach(song.tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
            }
        }
    }

    private var notesDisplaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(song.notes)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private var lyricsSection: some View {
        Text(song.lyrics)
            .font(.body)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }

    private func translationDisplaySection(translation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("English Translation")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(translation)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private var shareText: String {
        var text = "🎵 \(song.title)\n\n"
        text += "Language: \(song.language)\n"
        text += "Date: \(song.displayDate)\n\n"

        if !song.tags.isEmpty {
            text += "Tags: \(song.tags.map { "#\($0)" }.joined(separator: " "))\n\n"
        }

        if !song.notes.isEmpty {
            text += "Notes:\n\(song.notes)\n\n"
        }

        text += "Lyrics:\n\(song.lyrics)"
        
        if let translation = song.translation, !translation.isEmpty {
            text += "\n\nEnglish Translation:\n\(translation)"
        }

        return text
    }
    
    private func deleteSong() {
        // Delete audio file if it exists
        if let audioFileName = song.audioFileName {
            let fileManager = FileManager.default
            if let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let audioURL = documentsPath.appendingPathComponent(audioFileName)
                try? fileManager.removeItem(at: audioURL)
            }
        }
        
        // Delete from SwiftData
        modelContext.delete(song)
        dismiss()
    }
}

struct TagView: View {
    let tag: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.subheadline)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.15))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var result: [CGPoint] = []
        var currentPosition = CGPoint.zero
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let proposalWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentPosition.x + size.width > proposalWidth && currentPosition.x > 0 {
                currentPosition.x = 0
                currentPosition.y += lineHeight + spacing
                lineHeight = 0
            }

            result.append(currentPosition)
            currentPosition.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentPosition.x)
        }

        return (CGSize(width: maxWidth, height: currentPosition.y + lineHeight), result)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    @Previewable @State var song = Song(
        title: "Sample Song",
        lyrics: "These are the lyrics to a sample song.\nWith multiple lines.\nAnd some more content.",
        language: "English",
        tags: ["Rock", "Pop", "Indie"],
        notes: "This is a note about the song."
    )

    NavigationStack {
        SongDetailView(song: song)
    }
    .modelContainer(for: Song.self, inMemory: true)
}
