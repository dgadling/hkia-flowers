import Foundation

// Rect structure to match Create ML format
struct AnnotationRect: Codable, Identifiable, Equatable {
    var id = UUID()
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    
    // Convert from SwiftUI coordinates to normalized coordinates (0-1)
    init(from rect: CGRect, in frameSize: CGSize) {
        self.x = rect.minX / frameSize.width
        self.y = rect.minY / frameSize.height
        self.width = rect.width / frameSize.width
        self.height = rect.height / frameSize.height
    }
    
    // Convert back to CGRect for display
    func toCGRect(in frameSize: CGSize) -> CGRect {
        return CGRect(
            x: x * frameSize.width,
            y: y * frameSize.height,
            width: width * frameSize.width,
            height: height * frameSize.height
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
    init(from imageAnnotations: [ImageAnnotation]) {
        self.images = imageAnnotations.map { imageAnnotation in
            CreateMLImageAnnotation(
                image: imageAnnotation.filename,
                annotations: imageAnnotation.annotations.map { annotation in
                    CreateMLAnnotation(
                        label: annotation.label,
                        coordinates: CreateMLCoordinates(
                            x: annotation.rect.x + (annotation.rect.width / 2),
                            y: annotation.rect.y + (annotation.rect.height / 2),
                            width: annotation.rect.width,
                            height: annotation.rect.height
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