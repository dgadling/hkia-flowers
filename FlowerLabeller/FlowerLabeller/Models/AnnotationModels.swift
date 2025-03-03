import Foundation

// Rect structure to store annotation rectangles
struct AnnotationRect: Codable, Identifiable, Equatable {
    var id = UUID()
    // Store normalized coordinates internally for consistent storage
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    
    // Convert from image coordinates to normalized coordinates (0-1) for internal storage
    init(from rect: CGRect, in frameSize: CGSize) {
        // Ensure we're not dividing by zero
        let safeWidth = max(frameSize.width, 1)
        let safeHeight = max(frameSize.height, 1)
        
        // Store coordinates normalized to the original image size
        self.x = rect.minX / safeWidth
        self.y = rect.minY / safeHeight
        self.width = rect.width / safeWidth
        self.height = rect.height / safeHeight
    }
    
    // Convert back to CGRect for display
    func toCGRect(in frameSize: CGSize) -> CGRect {
        let rect = CGRect(
            x: x * frameSize.width,
            y: y * frameSize.height,
            width: width * frameSize.width,
            height: height * frameSize.height
        )
        
        return rect
    }
    
    // Get absolute coordinates based on image size
    func toAbsoluteCoordinates(in imageSize: CGSize) -> (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        return (
            x: x * imageSize.width,
            y: y * imageSize.height,
            width: width * imageSize.width,
            height: height * imageSize.height
        )
    }
}

// Annotation for a single bounding box
struct FlowerAnnotation: Codable, Identifiable, Equatable {
    var id = UUID()
    var species: String
    var color: String
    var pattern: String
    var quantity: Int
    var rect: AnnotationRect
    
    // Label for Create ML format (combines features)
    var label: String {
        return "\(species)_\(color)"
    }
}

// Image annotation model (for a single image)
struct ImageAnnotation: Codable, Identifiable, Equatable {
    var id = UUID()
    var filename: String
    var annotations: [FlowerAnnotation]
}

// Complete dataset for Create ML format
struct AnnotationDataset: Codable {
    var images: [CreateMLImageAnnotation]
    
    // Convert our app's annotation format to Create ML format
    @MainActor
    init(from imageAnnotations: [ImageAnnotation]) {
        self.images = imageAnnotations.map { imageAnnotation in
            CreateMLImageAnnotation(
                image: imageAnnotation.filename,
                annotations: imageAnnotation.annotations.map { annotation in
                    // Get the original image size from stored annotation
                    let originalImageSize = ImageAnnotationViewModel.shared.originalImagesSize[imageAnnotation.filename] ?? CGSize(width: 1000, height: 1000)
                    
                    // Convert normalized coordinates to absolute pixel coordinates
                    let absoluteCoords = annotation.rect.toAbsoluteCoordinates(in: originalImageSize)
                    
                    return CreateMLAnnotation(
                        label: annotation.label,
                        coordinates: CreateMLCoordinates(
                            // Use absolute pixel coordinates, not normalized
                            x: absoluteCoords.x + (absoluteCoords.width / 2),
                            y: absoluteCoords.y + (absoluteCoords.height / 2),
                            width: absoluteCoords.width,
                            height: absoluteCoords.height
                        )
                    )
                }
            )
        }
    }
}

// Create ML specific structures
struct CreateMLAnnotation: Codable {
    var label: String
    var coordinates: CreateMLCoordinates
}

struct CreateMLCoordinates: Codable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
}

struct CreateMLImageAnnotation: Codable {
    var image: String
    var annotations: [CreateMLAnnotation]
} 