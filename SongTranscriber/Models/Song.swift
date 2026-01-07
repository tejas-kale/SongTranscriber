//
//  Song.swift
//  SongTranscriber
//
//  Created by Tejas Kale on 05/01/26.
//

import Foundation
import SwiftData

@Model
final class Song {
    var id: UUID
    var title: String
    var lyrics: String
    var translation: String?
    var language: String
    var tags: [String]
    var notes: String
    var recordingDate: Date
    var audioFileName: String?

    init(
        id: UUID = UUID(),
        title: String = "Untitled Song",
        lyrics: String = "",
        translation: String? = nil,
        language: String = "English",
        tags: [String] = [],
        notes: String = "",
        recordingDate: Date = Date(),
        audioFileName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.lyrics = lyrics
        self.translation = translation
        self.language = language
        self.tags = tags
        self.notes = notes
        self.recordingDate = recordingDate
        self.audioFileName = audioFileName
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: recordingDate)
    }

    var tagsString: String {
        tags.joined(separator: ", ")
    }
}
