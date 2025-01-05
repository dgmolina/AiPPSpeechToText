import AVFoundation
import CoreMedia

class AudioOutputDelegate: NSObject, AVCaptureFileOutputDelegate {

    // Required method
    func fileOutputShouldProvideSampleAccurateRecordingStart(_ output: AVCaptureFileOutput) -> Bool {
        // Return true to enable sample-accurate recording start
        return true
    }

    // Optional method
    func fileOutput(_ output: AVCaptureFileOutput, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Implement this method if you need to process each sample buffer
        // For example, you can log the sample buffer or perform additional processing
        // print("Received sample buffer")
    }
}
