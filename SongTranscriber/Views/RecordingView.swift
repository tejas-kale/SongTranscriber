//
//  RecordingView.swift
//  SongTranscriber
//
//  Created by Tejas Kale on 05/01/26.
//

import SwiftUI
import SwiftData

struct RecordingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RecordingViewModel()
    @State private var showPermissionAlert = false
    @State private var navigateToDetail: Song?

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                statusSection

                Spacer()

                actionButtons

                Spacer()
            }
            .padding()
            .navigationTitle("Record Song")
            .task {
                let granted = await viewModel.requestPermissions()
                if !granted {
                    showPermissionAlert = true
                }
            }
            .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enable microphone access in Settings to record songs.")
            }
            .navigationDestination(item: $navigateToDetail) { song in
                SongDetailView(song: song)
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        switch viewModel.recordingState {
        case .idle:
            idleStatus
        case .recording:
            recordingStatus
        case .recorded:
            recordedStatus
        case .transcribing:
            transcribingStatus
        case .transcribed(let song):
            transcribedStatus(song: song)
        case .error(let message):
            errorStatus(message: message)
        }
    }

    private var idleStatus: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 120))
                .foregroundColor(.red.opacity(0.8))
        }
    }

    private var recordingStatus: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .scaleEffect(viewModel.audioService.isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.audioService.isRecording)

                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 160, height: 160)
                    .scaleEffect(viewModel.audioService.isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.audioService.isRecording)

                Image(systemName: "waveform")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }

            VStack(spacing: 8) {
                Text("Recording...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                Text(viewModel.audioService.formattedRecordingTime)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .foregroundColor(.primary)
                    .monospacedDigit()
            }
        }
    }

    private var recordedStatus: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            VStack(spacing: 8) {
                Text("Recording Complete")
                    .font(.title2)
                    .fontWeight(.medium)
                Text(viewModel.audioService.formattedRecordingTime)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var transcribingStatus: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2)
            Text("Transcribing with Gemini...")
                .font(.title2)
                .fontWeight(.medium)
        }
    }

    private func transcribedStatus(song: Song) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 80))
                .foregroundColor(.green)
            VStack(spacing: 8) {
                Text("Transcription Complete!")
                    .font(.title2)
                    .fontWeight(.medium)
                Text(song.title)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func errorStatus(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            VStack(spacing: 8) {
                Text("Error")
                    .font(.title2)
                    .fontWeight(.medium)
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch viewModel.recordingState {
        case .idle:
            Button(action: { viewModel.startRecording() }) {
                Text("Start Recording")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
            }

        case .recording:
            Button(action: { viewModel.stopRecording() }) {
                Label("Stop Recording", systemImage: "stop.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

        case .recorded:
            VStack(spacing: 16) {
                Button(action: {
                    if viewModel.audioService.isPlaying {
                        viewModel.stopPlaying()
                    } else {
                        viewModel.playRecording()
                    }
                }) {
                    Label(
                        viewModel.audioService.isPlaying ? "Stop" : "Play",
                        systemImage: viewModel.audioService.isPlaying ? "stop.fill" : "play.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Button(action: { viewModel.reset() }) {
                    Label("Discard", systemImage: "trash")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: {
                    Task {
                        await viewModel.transcribeRecording(modelContext: modelContext)
                    }
                }) {
                    Label("Transcribe Song", systemImage: "waveform.badge.magnifyingglass")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

        case .transcribing:
            EmptyView()

        case .transcribed(let song):
            VStack(spacing: 12) {
                Button(action: {
                    navigateToDetail = song
                }) {
                    Label("View Transcription", systemImage: "doc.text.magnifyingglass")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: { viewModel.reset() }) {
                    Label("Record Another Song", systemImage: "plus.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

        case .error:
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await viewModel.transcribeRecording(modelContext: modelContext)
                    }
                }) {
                    Label("Retry Transcription", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: { viewModel.reset() }) {
                    Label("Start Over", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }
}

#Preview {
    RecordingView()
        .modelContainer(for: Song.self, inMemory: true)
}
