import AVFoundation

class AudioRecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, 
                   didFinishRecordingTo outputFileURL: URL, 
                   from connections: [AVCaptureConnection], 
                   error: Error?) {
        if let error = error {
            print("Recording finished with error: \(error.localizedDescription)")
            return
        }
        print("Successfully finished recording to: \(outputFileURL)")
    }
}
