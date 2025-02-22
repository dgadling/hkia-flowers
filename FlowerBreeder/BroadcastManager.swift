import Foundation
import ReplayKit
import CoreImage

protocol FrameProcessorDelegate: AnyObject {
    func didCaptureFrame(_ image: CIImage)
    func didFailWithError(_ error: Error)
}

class BroadcastManager: ObservableObject {
    @Published var isRecording = false
    private let recorder = RPScreenRecorder.shared()
    private let processingQueue = DispatchQueue(label: "com.flowerbreeder.frameprocessing")
    
    weak var frameDelegate: FrameProcessorDelegate?
    
    enum BroadcastError: Error {
        case captureError(String)
        case frameConversionError
        case notAuthorized
    }
    
    func startBroadcast() {
        guard !isRecording else { return }
        
        print("BroadcastManager: Starting capture...")
        
        #if targetEnvironment(simulator)
        print("BroadcastManager: Screen recording is not supported in the iOS Simulator")
        handleError(BroadcastError.captureError("Screen recording is not supported in the iOS Simulator"))
        return
        #endif
        
        // Configure recorder
        recorder.isMicrophoneEnabled = false
        recorder.isCameraEnabled = false
        
        guard recorder.isAvailable else {
            print("BroadcastManager: Recorder not available")
            handleError(BroadcastError.notAuthorized)
            return
        }
        
        recorder.startCapture { [weak self] buffer, bufferType, error in
            guard let self = self else { return }
            
            if let error = error {
                print("BroadcastManager: Capture error - \(error.localizedDescription)")
                self.handleError(BroadcastError.captureError(error.localizedDescription))
                return
            }
            
            // Only process video frames
            guard bufferType == .video else { return }
            print("BroadcastManager: Received video frame")
            
            self.processingQueue.async {
                self.processVideoFrame(buffer)
            }
            
        } completionHandler: { [weak self] error in
            if let error = error {
                print("BroadcastManager: Start capture error - \(error.localizedDescription)")
                self?.handleError(BroadcastError.captureError(error.localizedDescription))
                return
            }
            
            print("BroadcastManager: Capture started successfully")
            DispatchQueue.main.async {
                self?.isRecording = true
            }
        }
    }
    
    func stopBroadcast() {
        guard isRecording else { return }
        
        print("BroadcastManager: Stopping capture...")
        
        recorder.stopCapture { [weak self] error in
            if let error = error {
                print("BroadcastManager: Stop capture error - \(error.localizedDescription)")
                self?.handleError(BroadcastError.captureError(error.localizedDescription))
                return
            }
            
            print("BroadcastManager: Capture stopped successfully")
            DispatchQueue.main.async {
                self?.isRecording = false
            }
        }
    }
    
    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            handleError(BroadcastError.frameConversionError)
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // Notify delegate on main thread
        DispatchQueue.main.async {
            self.frameDelegate?.didCaptureFrame(ciImage)
        }
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.frameDelegate?.didFailWithError(error)
        }
    }
} 
