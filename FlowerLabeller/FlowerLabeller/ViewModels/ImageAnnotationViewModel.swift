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
    
    init() {
        print("DEBUG: ImageAnnotationViewModel initialized")
    }
    
    // Directory selection
    func selectDirectory() async {
        print("DEBUG: selectDirectory called")
        return await withCheckedContinuation { continuation in
            // Create panel on the main thread
            DispatchQueue.main.async {
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.allowsMultipleSelection = false
                
                guard panel.runModal() == .OK, let url = panel.url else { 
                    print("DEBUG: Directory selection cancelled or failed")
                    continuation.resume(returning: ())
                    return 
                }
                
                print("DEBUG: Selected directory: \(url.path)")
                
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
                    print("DEBUG: Found \(self.imageURLs.count) JPG images")
                    
                    // Initialize empty annotations for each image
                    self.imageAnnotations = self.imageURLs.map { url in
                        ImageAnnotation(
                            filename: url.lastPathComponent,
                            annotations: []
                        )
                    }
                    
                    // Load the first image if available
                    if !self.imageURLs.isEmpty {
                        print("DEBUG: Loading first image")
                        self.loadCurrentImage()
                    } else {
                        print("DEBUG: No JPG images found in the selected directory")
                    }
                } catch {
                    print("DEBUG: Error loading directory contents: \(error.localizedDescription)")
                }
                
                continuation.resume(returning: ())
            }
        }
    }
    
    // Load the current image
    func loadCurrentImage() {
        print("DEBUG: loadCurrentImage() - index: \(currentImageIndex), urls count: \(imageURLs.count)")
        guard currentImageIndex >= 0 && currentImageIndex < imageURLs.count else {
            print("DEBUG: Invalid image index, setting currentImage to nil")
            currentImage = nil
            return
        }
        
        let url = imageURLs[currentImageIndex]
        print("DEBUG: Loading image from URL: \(url.path)")
        if let image = NSImage(contentsOf: url) {
            print("DEBUG: Image loaded successfully, size: \(image.size)")
            currentImage = image
            currentImageSize = image.size
        } else {
            print("DEBUG: Failed to load image from URL: \(url.path)")
            currentImage = nil
        }
    }
    
    // Navigation methods
    func nextImage() async {
        print("DEBUG: nextImage() called - current index: \(currentImageIndex)")
        if currentImageIndex < imageURLs.count - 1 {
            currentImageIndex += 1
            loadCurrentImage()
            clearCurrentDrawing()
        } else {
            print("DEBUG: Already at the last image")
        }
    }
    
    func previousImage() async {
        print("DEBUG: previousImage() called - current index: \(currentImageIndex)")
        if currentImageIndex > 0 {
            currentImageIndex -= 1
            loadCurrentImage()
            clearCurrentDrawing()
        } else {
            print("DEBUG: Already at the first image")
        }
    }
    
    // Rectangle drawing methods
    func startDrawing(at point: CGPoint) {
        print("DEBUG: startDrawing at point: \(point)")
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
        print("DEBUG: endDrawing - rect: \(currentRect)")
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
            print("DEBUG: Created temporary annotation")
        } else {
            print("DEBUG: Rectangle too small, clearing drawing")
            clearCurrentDrawing()
        }
    }
    
    func clearCurrentDrawing() {
        print("DEBUG: clearCurrentDrawing")
        isDrawing = false
        currentRect = .zero
        tempAnnotation = nil
        resetAnnotationForm()
    }
    
    // Save the temporary annotation
    func saveCurrentAnnotation() async {
        print("DEBUG: saveCurrentAnnotation")
        guard let tempAnnotation = tempAnnotation,
              currentImageIndex >= 0 && currentImageIndex < imageAnnotations.count else {
            print("DEBUG: Cannot save annotation - tempAnnotation is nil or invalid image index")
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
        
        print("DEBUG: Saving annotation - species: \(currentSpecies), color: \(currentColor), pattern: \(currentPattern), quantity: \(currentQuantity)")
        
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
        print("DEBUG: exportAnnotations called")
        let dataset = AnnotationDataset(from: imageAnnotations)
        
        // Convert to JSON
        guard let jsonData = try? JSONEncoder().encode(dataset) else {
            print("DEBUG: Failed to encode annotations to JSON")
            return nil
        }
        
        // Create a save panel
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "annotations.json"
        savePanel.allowedContentTypes = [UTType.json]
        
        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            print("DEBUG: Save panel cancelled or failed")
            return nil
        }
        
        print("DEBUG: Exporting annotations to: \(url.path)")
        
        // Write to file
        do {
            try jsonData.write(to: url)
            print("DEBUG: Successfully saved annotations to \(url.path)")
            return url
        } catch {
            print("DEBUG: Failed to save annotations: \(error)")
            return nil
        }
    }
} 