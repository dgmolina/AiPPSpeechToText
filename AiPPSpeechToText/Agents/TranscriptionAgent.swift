//
//  TranscriptionAgent.swift
//  AiPPSpeechToText
//
//  Created by Daniel Molina on 05/01/25.
//

import Foundation

protocol TranscriptionAgent {
    func transcribe(audioData: Data) async throws -> String
}
