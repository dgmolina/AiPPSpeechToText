//
//  TextCleaningAgent.swift
//  AiPPSpeechToText
//
//  Created by Daniel Molina on 05/01/25.
//

import Foundation

protocol TextCleaningAgent {
    func cleanText(text: String) async throws -> String
}
