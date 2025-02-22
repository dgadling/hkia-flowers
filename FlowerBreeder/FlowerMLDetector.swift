import Vision
import CoreML
import CoreImage

class FlowerMLDetector {
    private var model: VNCoreMLModel
    
    init() throws {
        // Replace "FlowerDetector" with your trained model's name
        guard let modelURL = Bundle.main.url(forResource: "FlowerDetector", withExtension: "mlmodel") else {
            throw NSError(domain: "FlowerMLDetector", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model file not found"])
        }
        
        let compiledModelURL = try MLModel.compileModel(at: modelURL)
        let model = try MLModel(contentsOf: compiledModelURL)
        self.model = try VNCoreMLModel(for: model)
    }
    
    func detectFlowers(in image: CIImage) async throws -> [FlowerDetector.DetectedFlower] {
        var detectedFlowers: [FlowerDetector.DetectedFlower] = []

        let request = VNCoreMLRequest(model: model) { request, error in
            guard error == nil else { return }
            
            // Process results
            if let results = request.results as? [VNRecognizedObjectObservation] {
                detectedFlowers = results.map { observation in
                    FlowerDetector.DetectedFlower(
                        bounds: observation.boundingBox,
                        confidence: observation.confidence,
                        text: observation.labels.first?.identifier
                    )
                }
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        try handler.perform([request])
        
        return detectedFlowers
    }
} 
