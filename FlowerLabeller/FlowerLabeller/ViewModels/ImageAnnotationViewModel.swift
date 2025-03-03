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
            
            let processedImage: NSImage
            
            // Check if the image is extremely large and might cause performance issues
            if image.size.width > 4000 || image.size.height > 4000 {
                print("DEBUG: Image is very large (\(image.size.width) x \(image.size.height)), downsampling for better performance")
                processedImage = downsampleLargeImage(image)
                print("DEBUG: Downsampled to \(processedImage.size.width) x \(processedImage.size.height)")
            } else {
                processedImage = image
            }
            
            // Store image and its dimensions
            currentImage = processedImage
            currentImageSize = processedImage.size
            
            // Log memory usage for debugging
            let imageMemorySize = Int(processedImage.size.width * processedImage.size.height * 4) // Approximate size in bytes (4 bytes per pixel)
            let formattedSize = formatByteSize(imageMemorySize)
            print("DEBUG: Estimated image memory usage: \(formattedSize)")
        } else {
            print("DEBUG: Failed to load image from URL: \(url.path)")
            currentImage = nil
        }
    }
    
    // Downsample a large image to a more manageable size while maintaining aspect ratio
    private func downsampleLargeImage(_ image: NSImage) -> NSImage {
        // Maximum dimensions we want to allow (4000px on the longest side is usually plenty)
        let maxDimension: CGFloat = 3000
        
        // Calculate the target size maintaining aspect ratio
        let originalSize = image.size
        var targetSize = originalSize
        
        if originalSize.width > originalSize.height && originalSize.width > maxDimension {
            // Landscape orientation
            let scale = maxDimension / originalSize.width
            targetSize = CGSize(width: maxDimension, height: originalSize.height * scale)
        } else if originalSize.height > maxDimension {
            // Portrait orientation
            let scale = maxDimension / originalSize.height
            targetSize = CGSize(width: originalSize.width * scale, height: maxDimension)
        }
        
        // Create a new NSImage with the target size
        let newImage = NSImage(size: targetSize)
        
        newImage.lockFocus()
        
        // Draw the original image in the new size
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: targetSize))
        
        newImage.unlockFocus()
        
        return newImage
    }
    
    // Helper to format byte size to human-readable format
    private func formatByteSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
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
        print("DEBUG: Starting drawing at: \(point)")
        isDrawing = true
        currentRect = CGRect(origin: point, size: CGSize(width: 1, height: 1))  // Start with a 1x1 rect instead of zero
    }
    
    func updateDrawing(to point: CGPoint, from startPoint: CGPoint) {
        guard isDrawing else { 
            return 
        }
        
        let minX = min(startPoint.x, point.x)
        let minY = min(startPoint.y, point.y)
        let width = max(abs(point.x - startPoint.x), 1)  // Ensure minimum width of 1
        let height = max(abs(point.y - startPoint.y), 1)  // Ensure minimum height of 1
        
        let newRect = CGRect(x: minX, y: minY, width: width, height: height)
        
        // Only update if the rectangle has changed significantly
        if abs(newRect.width - currentRect.width) > 0.1 || abs(newRect.height - currentRect.height) > 0.1 ||
           abs(newRect.minX - currentRect.minX) > 0.1 || abs(newRect.minY - currentRect.minY) > 0.1 {
            currentRect = newRect
            // Force a redraw by setting isDrawing again
            isDrawing = true
        }
    }
    
    func endDrawing() {
        print("DEBUG: Finished drawing - rect: \(currentRect)")
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
            print("DEBUG: Rectangle too small, clearing drawing")
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