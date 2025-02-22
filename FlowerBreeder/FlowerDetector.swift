import Vision
import CoreML
import CoreImage

class FlowerDetector: ObservableObject {
    @Published var detectedFlowers: [DetectedFlower] = []
    private let mlDetector: FlowerMLDetector?

    init() {
        do {
            mlDetector = try FlowerMLDetector()
        } catch {
            print("Failed to initialize ML Detector: \(error)")
        }
    }
    
    struct DetectedFlower {
        let bounds: CGRect
        let confidence: Float
        let text: String?
    }
    
    func detectFlowers(in image: CIImage) async throws -> [DetectedFlower] {
        guard let detector = mlDetector else {
            throw NSError(domain: "FlowerDetector", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "ML Detector not initialized"])
        }
        
        return try await detector.detectFlowers(in: image)
    }
} 