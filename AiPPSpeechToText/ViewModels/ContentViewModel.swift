//
//  ContentViewModel.swift
//  AiPPSpeechToText
//
//  Created by Daniel Molina on 05/01/25.
//

import Foundation
import AVFoundation

class ContentViewModel: NSObject, ObservableObject {
    @Published var transcriptionResult: TranscriptionResult?
    private let transcriptionAgent: TranscriptionAgent
    private let textCleaningAgent: TextCleaningAgent
    private var audioRecorder: AVAudioRecorder?
    private var captureSession: AVCaptureSession?
    private var audioInput: AVCaptureDeviceInput?
    private var audioFileOutput: AVCaptureMovieFileOutput?
    private var fileURL: URL?
    private let recordingDelegate = AudioRecordingDelegate()
    private let outputDelegate = AudioOutputDelegate() // Retain the delegate
    init(transcriptionAgent: TranscriptionAgent, textCleaningAgent: TextCleaningAgent) {
        self.transcriptionAgent = transcriptionAgent
        self.textCleaningAgent = textCleaningAgent
        super.init()
        requestMicrophonePermission() // Request microphone access
        setupAudioCapture()
    }

    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                print("Microphone access granted")
            } else {
                print("Microphone access denied")
            }
        }
    }

    func startRecording() {
        guard let captureSession = captureSession, !captureSession.isRunning else {
            print("Capture session is not setup or already running")
            return
        }
        
        fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("recording.mov")
        
        if let fileURL = fileURL {
            audioFileOutput?.startRecording(to: fileURL, recordingDelegate: recordingDelegate)
            captureSession.startRunning()
        }
    }

    func stopRecording() async {
        guard let captureSession = captureSession, captureSession.isRunning else {
            print("Capture session is not running")
            return
        }

        DispatchQueue.main.async {
            self.audioFileOutput?.stopRecording()
            captureSession.stopRunning()
        }

        guard let fileURL = fileURL else {
            print("Error: No audio URL found")
            return
        }

        do {
            let audioData = try Data(contentsOf: fileURL)
            let transcribedText = try await transcriptionAgent.transcribe(audioData: audioData)
            let cleanedText = try await textCleaningAgent.cleanText(text: transcribedText)
            DispatchQueue.main.async {
                self.transcriptionResult = TranscriptionResult(originalText: transcribedText, cleanedText: cleanedText)
            }
        } catch {
            print("Error processing audio: \(error)")
        }
    }

    private func setupAudioCapture() {
        DispatchQueue.main.async {
            print("Setting up audio capture...")
            self.captureSession = AVCaptureSession()
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                print("Could not get default audio device")
                return
            }

            print("Audio device found: \(audioDevice.localizedName)")

            // Check if the audio device is available
            do {
                try audioDevice.lockForConfiguration()
                if audioDevice.isConnected && !audioDevice.isSuspended {
                    print("Audio device is available and connected")
                } else {
                    print("Audio device is unavailable or suspended")
                    return
                }
                audioDevice.unlockForConfiguration()
            } catch {
                print("Error checking audio device availability: \(error)")
                return
            }

            do {
                self.audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if let audioInput = self.audioInput, self.captureSession!.canAddInput(audioInput) {
                    self.captureSession!.addInput(audioInput)
                    print("Audio input added to capture session")
                } else {
                    print("Could not add audio input to capture session")
                    return
                }

                self.audioFileOutput = AVCaptureMovieFileOutput()
                if let audioFileOutput = self.audioFileOutput, self.captureSession!.canAddOutput(audioFileOutput) {
                    audioFileOutput.movieFragmentInterval = .invalid
                    audioFileOutput.delegate = self.outputDelegate
                    self.captureSession!.addOutput(audioFileOutput)
                    print("Audio output added to capture session")
                } else {
                    print("Could not add audio output to capture session")
                    return
                }
            } catch {
                print("Error setting up audio capture: \(error)")
            }
        }
    }
    
}
