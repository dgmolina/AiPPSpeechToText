//
//  GeminiTextCleaningAgent.swift
//  AiPPSpeechToText
//
//  Created by Daniel Molina on 05/01/25.
//

import Foundation

class GeminiTextCleaningAgent: TextCleaningAgent {
    private let geminiService: GeminiService

    init(geminiService: GeminiService) {
        self.geminiService = geminiService
    }

    func cleanText(text: String) async throws -> String {
        // TODO: Implement Gemini API call for text cleaning
        print("Cleaning text...")
        return "This is a cleaned text"
    }
}
