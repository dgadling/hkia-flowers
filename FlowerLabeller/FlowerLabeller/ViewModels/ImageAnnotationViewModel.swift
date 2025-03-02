import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
class ImageAnnotationViewModel: ObservableObject {
    // Current state
    @Published var imageURLs: [URL] = []
    @Published var currentImageIndex: Int = 0
    @Published var currentImage: NSImage?
    @Published var imageAnnotations: [ImageAnnotation] = []
    @Published var isDrawing: Bool = false
    @Published var currentRect: CGRect = .zero
    
    // Current annotation form
    @Published var currentSpecies: String = ""
    @Published var currentColor: String = ""
    @Published var currentPattern: String = ""
    @Published var currentQuantity: Int = 1
    
    // Temporary annotation for the currently drawn rectangle
    @Published var tempAnnotation: FlowerAnnotation?
    
    // Image size for calculating normalized coordinates
    @Published var currentImageSize: CGSize = .zero
    
    // Directory selection
    func selectDirectory() async {
        return await withCheckedContinuation { continuation in
            // Create panel on the main thread
            DispatchQueue.main.async {
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.allowsMultipleSelection = false
                
                guard panel.runModal() == .OK, let url = panel.url else { 
                    print("Directory selection cancelled or failed")
                    continuation.resume(returning: ())
                    return 
                }
                
                // Clear existing data
                self.imageURLs = []
                self.imageAnnotations = []
                self.currentImageIndex = 0
                
                // Load JPG files from the directory
                do {
                    let files = try FileManager.default.contentsOfDirectory(
                        at: url, 
                        includingPropertiesForKeys: [.isRegularFileKey], 
                        options: .skipsHiddenFiles
                    )
                    
                    self.imageURLs = files.filter { $0.pathExtension.lowercased() == "jpg" }
                    
                    // Initialize empty annotations for each image
                    self.imageAnnotations = self.imageURLs.map { url in
                        ImageAnnotation(
                            filename: url.lastPathComponent,
                            annotations: []
                        )
                    }
                    
                    // Load the first image if available
                    if !self.imageURLs.isEmpty {
                        self.loadCurrentImage()
                    } else {
                        print("No JPG images found in the selected directory")
                    }
                } catch {
                    print("Error loading directory contents: \(error.localizedDescription)")
                }
                
                continuation.resume(returning: ())
            }
        }
    }
    
    // Load the current image
    func loadCurrentImage() {
        guard currentImageIndex >= 0 && currentImageIndex < imageURLs.count else {
            currentImage = nil
            return
        }
        
        let url = imageURLs[currentImageIndex]
        if let image = NSImage(contentsOf: url) {
            currentImage = image
            currentImageSize = image.size
        } else {
            currentImage = nil
        }
    }
    
    // Navigation methods
    func nextImage() async {
        if currentImageIndex < imageURLs.count - 1 {
            currentImageIndex += 1
            loadCurrentImage()
            clearCurrentDrawing()
        }
    }
    
    func previousImage() async {
        if currentImageIndex > 0 {
            currentImageIndex -= 1
            loadCurrentImage()
            clearCurrentDrawing()
        }
    }
    
    // Rectangle drawing methods
    func startDrawing(at point: CGPoint) {
        isDrawing = true
        currentRect = CGRect(origin: point, size: .zero)
    }
    
    func updateDrawing(to point: CGPoint, from startPoint: CGPoint) {
        guard isDrawing else { return }
        
        let minX = min(startPoint.x, point.x)
        let minY = min(startPoint.y, point.y)
        let width = abs(point.x - startPoint.x)
        let height = abs(point.y - startPoint.y)
        
        currentRect = CGRect(x: minX, y: minY, width: width, height: height)
    }
    
    func endDrawing() {
        isDrawing = false
        // Don't create annotations for very small rectangles (likely accidental)
        if currentRect.width > 10 && currentRect.height > 10 {
            // Create a temporary annotation that will be confirmed by the user
            tempAnnotation = FlowerAnnotation(
                species: "",
                color: "",
                pattern: "",
                quantity: 1,
                rect: AnnotationRect(from: currentRect, in: currentImageSize)
            )
        } else {
            clearCurrentDrawing()
        }
    }
    
    func clearCurrentDrawing() {
        isDrawing = false
        currentRect = .zero
        tempAnnotation = nil
        resetAnnotationForm()
    }
    
    // Save the temporary annotation
    func saveCurrentAnnotation() async {
        guard let tempAnnotation = tempAnnotation,
              currentImageIndex >= 0 && currentImageIndex < imageAnnotations.count else {
            return
        }
        
        // Create the final annotation with user input
        let annotation = FlowerAnnotation(
            species: currentSpecies,
            color: currentColor,
            pattern: currentPattern,
            quantity: currentQuantity,
            rect: tempAnnotation.rect
        )
        
        // Add to the current image's annotations
        imageAnnotations[currentImageIndex].annotations.append(annotation)
        
        // Clear for next annotation
        clearCurrentDrawing()
    }
    
    // Reset the annotation form
    private func resetAnnotationForm() {
        currentSpecies = ""
        currentColor = ""
        currentPattern = ""
        currentQuantity = 1
    }
    
    // Export annotations to Create ML format
    func exportAnnotations() async -> URL? {
        let dataset = AnnotationDataset(from: imageAnnotations)
        
        // Convert to JSON
        guard let jsonData = try? JSONEncoder().encode(dataset) else {
            return nil
        }
        
        // Create a save panel
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "annotations.json"
        savePanel.allowedContentTypes = [UTType.json]
        
        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            return nil
        }
        
        // Write to file
        do {
            try jsonData.write(to: url)
            return url
        } catch {
            print("Failed to save annotations: \(error)")
            return nil
        }
    }
} 