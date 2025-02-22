import CoreImage
import SwiftUI

class FrameProcessor: ObservableObject, FrameProcessorDelegate {
    private let context = CIContext()
    @Published var lastProcessedImage: UIImage?
    
    func didCaptureFrame(_ image: CIImage) {
        // Example processing - you can add your flower detection logic here
        if let cgImage = context.createCGImage(image, from: image.extent) {
            lastProcessedImage = UIImage(cgImage: cgImage)
            
            // Add your frame analysis here
            analyzeFrame(image)
        }
    }
    
    func didFailWithError(_ error: Error) {
        print("Frame processing error: \(error.localizedDescription)")
    }
    
    private func analyzeFrame(_ image: CIImage) {
        // Example frame analysis
        // You can implement flower detection/recognition here
        print("Processing frame: \(image.extent.size)")
    }
} 