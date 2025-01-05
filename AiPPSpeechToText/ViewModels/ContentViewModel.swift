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
    @Published var isRecordingEnabled: Bool = false // Tracks if recording is allowed
    private let transcriptionAgent: TranscriptionAgent
    private let textCleaningAgent: TextCleaningAgent
    private var audioRecorder: AVAudioRecorder?
    private var captureSession: AVCaptureSession?
    private var audioInput: AVCaptureDeviceInput?
    private var audioFileOutput: AVCaptureMovieFileOutput?
    private var fileURL: URL?
    private let recordingDelegate = AudioRecordingDelegate()
    private let outputDelegate = AudioOutputDelegate()

    init(transcriptionAgent: TranscriptionAgent, textCleaningAgent: TextCleaningAgent) {
        self.transcriptionAgent = transcriptionAgent
        self.textCleaningAgent = textCleaningAgent
        super.init()
        print("ContentViewModel initialized")
        requestMicrophonePermission() // Request permissions on initialization
    }
    
    deinit {
        if let captureSession = captureSession, captureSession.isRunning {
            captureSession.stopRunning()
        }
        audioFileOutput = nil
        audioInput = nil
        captureSession = nil
        print("ContentViewModel deinitialized")
    }

    private func requestMicrophonePermission() {
        print("Requesting microphone permission...")
        DispatchQueue.main.async {
            if AVCaptureDevice.default(for: .audio) != nil {
                AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                    guard let self = self else { return }
                    if granted {
                        print("Microphone access granted")
                        self.setupAudioCapture() // Only set up audio capture if permissions are granted
                        self.isRecordingEnabled = true // Enable recording buttons
                    } else {
                        print("Microphone access denied")
                        self.isRecordingEnabled = false // Disable recording buttons
                    }
                }
            } else {
                print("Microphone is not available")
                self.isRecordingEnabled = false // Disable recording buttons
            }
        }
    }

    private func setupAudioCapture() {
        print("Setting up audio capture...")
        DispatchQueue.main.async {
            self.captureSession = AVCaptureSession()
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                print("Could not get default audio device")
                return
            }

            print("Audio device found: \(audioDevice.localizedName)")

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

    func startRecording() {
        guard isRecordingEnabled, let captureSession = captureSession, !captureSession.isRunning else {
            print("Recording is not enabled or capture session is already running")
            return
        }

        fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("recording.mov")

        if let fileURL = fileURL {
            audioFileOutput?.startRecording(to: fileURL, recordingDelegate: recordingDelegate)
            captureSession.startRunning()
        }
    }

    func stopRecording() async {
        guard isRecordingEnabled, let captureSession = captureSession, captureSession.isRunning else {
            print("Recording is not enabled or capture session is not running")
            return
        }

        await MainActor.run {
            self.audioFileOutput?.stopRecording()
            captureSession.stopRunning()
            print("Recording stopped and capture session ended")
        }

        guard let fileURL = fileURL else {
            print("Error: No audio URL found")
            return
        }

        do {
            print("Processing audio data...")
            let audioData = try Data(contentsOf: fileURL)
            let transcribedText = try await transcriptionAgent.transcribe(audioData: audioData)
            print("Transcription complete, cleaning text...")
            let cleanedText = try await textCleaningAgent.cleanText(text: transcribedText)

            await MainActor.run {
                self.transcriptionResult = TranscriptionResult(originalText: transcribedText, cleanedText: cleanedText)
                print("Transcription result updated")
            }
        } catch {
            print("Error processing audio: \(error)")
            await MainActor.run {
                self.transcriptionResult = nil
            }
        }
    }
    
}
