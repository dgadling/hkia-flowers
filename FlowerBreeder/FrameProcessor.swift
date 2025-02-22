import CoreImage
import SwiftUI

class FrameProcessor: ObservableObject, FrameProcessorDelegate {
    private let context = CIContext()
    @Published var lastProcessedImage: UIImage?
    private var frameCount = 0
    private var mlDetector: FlowerMLDetector?
    
    init() {
        do {
            mlDetector = try FlowerMLDetector()
            print("ML Detector initialized successfully")
        } catch {
            print("Failed to initialize ML Detector: \(error.localizedDescription)")
        }
    }
    
    func didCaptureFrame(_ image: CIImage) {
        frameCount += 1
        print("Processing frame #\(frameCount): \(image.extent.size)")
        
        // Process the frame using ML detection
        Task {
            do {
                if let detector = mlDetector {
                    let detectedFlowers = try await detector.detectFlowers(in: image)
                    print("Detected \(detectedFlowers.count) flowers using ML model")
                    
                    // Update the preview image with detected regions
                    if let cgImage = context.createCGImage(image, from: image.extent) {
                        let uiImage = UIImage(cgImage: cgImage)
                        await drawDetectedRegions(on: uiImage, flowers: detectedFlowers)
                    }
                } else {
                    print("ML Detector not available")
                }
            } catch {
                print("Flower detection error: \(error.localizedDescription)")
            }
        }
    }
    
    private func drawDetectedRegions(on image: UIImage, flowers: [FlowerDetector.DetectedFlower]) async {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        // Draw the original image
        image.draw(at: .zero)
        
        // Draw rectangles around detected flowers with confidence scores
        for flower in flowers {
            let rect = flower.bounds
            
            // Use different colors based on confidence
            let color = UIColor(
                hue: CGFloat(min(flower.confidence, 1.0)),  // Red to Green
                saturation: 1.0,
                brightness: 1.0,
                alpha: 1.0
            )
            color.setStroke()
            
            let path = UIBezierPath(rect: rect)
            path.lineWidth = 2.0
            path.stroke()
            
            // Draw label and confidence
            let text = "\(flower.text ?? "Unknown") (\(Int(flower.confidence * 100))%)"
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .backgroundColor: UIColor.black.withAlphaComponent(0.5),
                .font: UIFont.systemFont(ofSize: 12, weight: .bold)
            ]
            text.draw(at: CGPoint(x: rect.minX, y: rect.minY - 15), withAttributes: attributes)
        }
        
        if let annotatedImage = UIGraphicsGetImageFromCurrentImageContext() {
            await MainActor.run {
                lastProcessedImage = annotatedImage
            }
        }
    }
    
    func didFailWithError(_ error: Error) {
        print("Frame processing error: \(error.localizedDescription)")
    }
} 
