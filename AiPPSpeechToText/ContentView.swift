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
                Text("Cleaned: \(result.cleanedText)")
            } else {
                Text("Press the button to start recording")
            }
            HStack {
                Button("Start Recording") {
                    viewModel.startRecording()
                }
                Button("Stop Recording") {
                    Task {
                        await viewModel.stopRecording()
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
