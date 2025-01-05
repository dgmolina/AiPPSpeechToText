//
//  ContentView.swift
//  AiPPSpeechToText
//
//  Created by Daniel Molina on 05/01/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel

    init() {
        let geminiService = GeminiService()
        let transcriptionAgent = GeminiTranscriptionAgent(geminiService: geminiService)
        let textCleaningAgent = GeminiTextCleaningAgent(geminiService: geminiService)
        let viewModel = ContentViewModel(
            transcriptionAgent: transcriptionAgent,
            textCleaningAgent: textCleaningAgent
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            if let result = viewModel.transcriptionResult {
                Text("Original: \(result.originalText)")
                    .font(.headline)
                    .padding()
                Text("Cleaned: \(result.cleanedText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Press the button to start recording")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.startRecording()
                }) {
                    Text("Start Recording")
                        .padding()
                        .background(viewModel.isRecordingEnabled ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!viewModel.isRecordingEnabled) // Disable button if permissions are not granted

                Button(action: {
                    Task {
                        await viewModel.stopRecording()
                    }
                }) {
                    Text("Stop Recording")
                        .padding()
                        .background(viewModel.isRecordingEnabled ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!viewModel.isRecordingEnabled) // Disable button if permissions are not granted
            }
            .padding()
        }
        .padding()
        .onAppear {
            print("ContentView appeared")
        }
        .onDisappear {
            print("ContentView disappeared")
        }
    }
}

#Preview {
    ContentView()
}
