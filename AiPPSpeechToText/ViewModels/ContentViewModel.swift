//
//  ContentViewModel.swift
//  AiPPSpeechToText
//
//  Created by Daniel Molina on 05/01/25.
//

import Foundation
import AVFoundation

class ContentViewModel: ObservableObject {
    @Published var transcriptionResult: TranscriptionResult?
    private let transcriptionAgent: TranscriptionAgent
    private let textCleaningAgent: TextCleaningAgent
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?

    init(transcriptionAgent: TranscriptionAgent, textCleaningAgent: TextCleaningAgent) {
        self.transcriptionAgent = transcriptionAgent
        self.textCleaningAgent = textCleaningAgent
        setupAudioSession()
    }

    func startRecording() {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.record()
        } catch {
            print("Error starting recording: \(error)")
        }
    }

    func stopRecording() async {
        audioRecorder?.stop()
        guard let audioURL = audioRecorder?.url else {
            print("Error: No audio URL found")
            return
        }

        do {
            let audioData = try Data(contentsOf: audioURL)
            let transcribedText = try await transcriptionAgent.transcribe(audioData: audioData)
            let cleanedText = try await textCleaningAgent.cleanText(text: transcribedText)
            DispatchQueue.main.async {
                self.transcriptionResult = TranscriptionResult(originalText: transcribedText, cleanedText: cleanedText)
            }
        } catch {
            print("Error processing audio: \(error)")
        }
    }

    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.record, mode: .default, options: [])
            try audioSession?.setActive(true)
            audioSession?.requestRecordPermission { granted in
                if granted {
                    print("Audio permission granted")
                } else {
                    print("Audio permission denied")
                }
            }
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
}
