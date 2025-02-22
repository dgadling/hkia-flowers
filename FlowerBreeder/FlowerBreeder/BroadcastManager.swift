import Foundation
import ReplayKit

class BroadcastManager: ObservableObject {
    @Published var isRecording = false
    private let recorder = RPScreenRecorder.shared()
    
    func startBroadcast() {
        guard !isRecording else { return }
        
        recorder.startCapture { [weak self] buffer, type, error in
            guard error == nil else {
                print("Error capturing screen: \(error?.localizedDescription ?? "")")
                return
            }
            
            // Process captured frame here
            // buffer contains the CMSampleBuffer for processing
            
        } completionHandler: { [weak self] error in
            if let error = error {
                print("Error starting capture: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self?.isRecording = true
            }
        }
    }
    
    func stopBroadcast() {
        guard isRecording else { return }
        
        recorder.stopCapture { [weak self] error in
            if let error = error {
                print("Error stopping capture: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self?.isRecording = false
            }
        }
    }
} 