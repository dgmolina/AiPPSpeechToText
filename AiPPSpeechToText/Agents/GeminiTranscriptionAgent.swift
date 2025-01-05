//
//  GeminiTranscriptionAgent.swift
//  AiPPSpeechToText
//
//  Created by Daniel Molina on 05/01/25.
//

import Foundation

class GeminiTranscriptionAgent: TranscriptionAgent {
    private let geminiService: GeminiService

    init(geminiService: GeminiService) {
        self.geminiService = geminiService
    }

    func transcribe(audioData: Data) async throws -> String {
        // TODO: Implement Gemini API call for transcription
        print("Transcribing audio data...")
        return "This is a transcribed text"
    }
}
