//
//  EditSongMetadataView.swift
//  SongTranscriber
//
//  Created by Tejas Kale on 05/01/26.
//

import SwiftUI

struct EditSongView: View {
    @Bindable var song: Song
    @Binding var isPresented: Bool
    
    @State private var newTag = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Title")) {
                    TextField("Song Title", text: $song.title)
                }
                
                Section(header: Text("Tags")) {
                    HStack {
                        TextField("Add new tag", text: $newTag)
                            .onSubmit {
                                addTag()
                            }
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if !song.tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(song.tags, id: \.self) { tag in
                                TagView(tag: tag) {
                                    removeTag(tag)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text("No tags")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $song.notes)
                        .frame(minHeight: 120)
                }
                
                Section(header: Text("Lyrics")) {
                    TextEditor(text: $song.lyrics)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !song.tags.contains(trimmed) else { return }
        song.tags.append(trimmed)
        newTag = ""
    }
    
    private func removeTag(_ tag: String) {
        song.tags.removeAll { $0 == tag }
    }
}

#Preview {
    @Previewable @State var song = Song(
        title: "Sample Song",
        tags: ["Idea", "Draft"],
        notes: "Some initial thoughts"
    )
    
    EditSongView(song: song, isPresented: .constant(true))
}
