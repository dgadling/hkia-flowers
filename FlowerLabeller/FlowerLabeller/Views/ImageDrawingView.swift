import SwiftUI

struct ImageDrawingView: NSViewRepresentable {
    @ObservedObject var viewModel: ImageAnnotationViewModel
    
    func makeNSView(context: Context) -> NSImageView {
        print("DEBUG: Creating NSImageView in ImageDrawingView")
        let imageView = DraggableImageView()
        
        // Set image scaling mode
        imageView.imageScaling = .scaleProportionallyDown
        imageView.imageAlignment = .alignCenter
        
        // Enable high-quality image scaling for better display
        imageView.wantsLayer = true
        imageView.layer?.contentsGravity = .resizeAspect
        
        // Critical: Disable autoresizing behavior that would allow the view to expand
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        // Don't allow the image to determine the view's intrinsic content size
        imageView.autoresizingMask = [.width, .height]
        imageView.translatesAutoresizingMaskIntoConstraints = true
        
        // Set up delegate
        imageView.delegate = context.coordinator
        context.coordinator.imageView = imageView
        
        // Add tracking area for mouse events
        let trackingArea = NSTrackingArea(
            rect: imageView.bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved, .enabledDuringMouseDrag],
            owner: imageView,
            userInfo: nil
        )
        imageView.addTrackingArea(trackingArea)
        
        return imageView
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        guard let imageView = nsView as? DraggableImageView else { return }
        
        let oldImage = imageView.image
        let newImage = viewModel.currentImage
        
        // Only update if the image has changed to avoid unnecessary redraws
        if oldImage != newImage {
            imageView.image = newImage
            
            // Log image dimensions for debugging
            if let image = newImage {
                print("DEBUG: Image updated in NSView - dimensions: \(image.size.width) x \(image.size.height)")
            } else {
                print("DEBUG: Image cleared in NSView")
            }
        }
        
        // Always redraw in case annotations have changed
        imageView.needsDisplay = true
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ImageDrawingView
        var startPoint: NSPoint?
        weak var imageView: DraggableImageView?
        // Add a local cache for the original image size to avoid actor isolation issues
        private var cachedOriginalImageSize: CGSize = .zero
        
        init(_ parent: ImageDrawingView) {
            self.parent = parent
            print("DEBUG: Coordinator initialized")
            super.init()
            // Initialize cached size after all properties are initialized
            Task { @MainActor in
                self.cachedOriginalImageSize = parent.viewModel.originalImageSize
            }
        }
        
        // Add a method to update the cached original image size
        func updateCachedImageSize() {
            Task { @MainActor in
                self.cachedOriginalImageSize = parent.viewModel.originalImageSize
            }
        }
        
        @objc func handleMouseDown(_ event: NSEvent) {
            // Reduce verbosity by limiting debug output to essential information
            
            guard let imageView = imageView,
                  imageView.image != nil else {
                print("DEBUG: handleMouseDown - imageView or image is nil")
                return
            }
            
            // Update cached size before using it
            updateCachedImageSize()
            
            // Get location directly in the view's coordinate system
            let viewPoint = imageView.convert(event.locationInWindow, from: nil)
            
            // Convert view coordinates to image coordinates
            let imageFrame = imageView.imageFrame()
            
            if !imageFrame.contains(viewPoint) {
                return
            }
            
            // Calculate point relative to the image
            let relativeX = (viewPoint.x - imageFrame.minX) / imageFrame.width
            let relativeY = (viewPoint.y - imageFrame.minY) / imageFrame.height
            
            // Use the cached original image size
            let originalSize = cachedOriginalImageSize
            // Calculate point using original image dimensions instead of potentially downsampled image
            let imagePoint = NSPoint(
                x: relativeX * originalSize.width,
                y: relativeY * originalSize.height
            )
            
            print("DEBUG: Mouse down at image point: \(imagePoint) (original image coordinates)")
            
            startPoint = viewPoint // Store the view point
            
            // Use Task to call the actor-isolated method
            Task { @MainActor in
                parent.viewModel.startDrawing(at: CGPoint(x: imagePoint.x, y: imagePoint.y))
            }
        }
        
        @objc func handleMouseDragged(_ event: NSEvent) {
            // Less verbose logging for mouse dragging
            
            guard let imageView = imageView,
                  imageView.image != nil,
                  let startPoint = startPoint else {
                return
            }
            
            // Get location directly in the view's coordinate system
            let viewPoint = imageView.convert(event.locationInWindow, from: nil)
            
            // Get image frame
            let imageFrame = imageView.imageFrame()
            
            // Use the cached original image size
            let originalSize = cachedOriginalImageSize
            
            // Calculate initial image point based on stored startPoint
            let startRelativeX = (startPoint.x - imageFrame.minX) / imageFrame.width
            let startRelativeY = (startPoint.y - imageFrame.minY) / imageFrame.height
            let startImagePoint = CGPoint(
                x: startRelativeX * originalSize.width,
                y: startRelativeY * originalSize.height
            )
            
            // Calculate current image point
            let currentRelativeX = (viewPoint.x - imageFrame.minX) / imageFrame.width
            let currentRelativeY = (viewPoint.y - imageFrame.minY) / imageFrame.height
            let currentImagePoint = CGPoint(
                x: currentRelativeX * originalSize.width,
                y: currentRelativeY * originalSize.height
            )
            
            // Update the rectangle - use Task to call actor-isolated method
            Task { @MainActor in
                parent.viewModel.updateDrawing(
                    to: currentImagePoint,
                    from: startImagePoint
                )
            }
            
            // Redraw
            imageView.needsDisplay = true
        }
        
        @objc func handleMouseUp(_ event: NSEvent) {
            startPoint = nil
            // Use Task to call actor-isolated method
            Task { @MainActor in
                parent.viewModel.endDrawing()
            }
            imageView?.needsDisplay = true
        }
    }
    
    // Custom NSImageView that handles drawing rectangles
    class DraggableImageView: NSImageView {
        var delegate: Coordinator?
        private var trackingArea: NSTrackingArea?
        
        // Override intrinsicContentSize to prevent the image from influencing the view's size
        override var intrinsicContentSize: NSSize {
            // Return a zero size to prevent the image's size from being used as the intrinsic size
            return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
        }
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setup()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }
        
        private func setup() {
            print("DEBUG: Setting up DraggableImageView")
            self.wantsLayer = true
            
            // Disable intrinsic sizing
            self.imageScaling = .scaleProportionallyDown
            self.imageAlignment = .alignCenter
            
            // Set the background color to help distinguish the image area
            if self.layer == nil {
                let layer = CALayer()
                layer.backgroundColor = NSColor.darkGray.cgColor
                self.layer = layer
                print("DEBUG: Explicitly created CALayer for DraggableImageView")
            } else {
                self.layer?.backgroundColor = NSColor.darkGray.cgColor
                print("DEBUG: Using existing layer for DraggableImageView")
            }
            
            // Enable mouse tracking
            self.isEnabled = true  // Enable user interaction
            // We don't need to set acceptsFirstResponder directly as we've overridden the property
            
            // Log the layer-backing status
            print("DEBUG: Layer-backed view: \(self.wantsLayer)")
            print("DEBUG: Layer: \(self.layer != nil ? "exists" : "nil")")
            print("DEBUG: isEnabled: \(self.isEnabled), acceptsFirstResponder: \(self.acceptsFirstResponder)")
            
            updateTrackingAreas()
        }
        
        // Make view first responder when it appears
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            print("DEBUG: DraggableImageView moved to window")
            
            // Force a layout update when the view appears in a window
            if let window = self.window {
                print("DEBUG: Window exists, making view first responder")
                window.makeFirstResponder(self)
                self.needsLayout = true
                self.needsDisplay = true
                updateTrackingAreas()
            } else {
                print("DEBUG: No window found")
            }
        }
        
        // Maintain tracking areas when the view resizes
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            
            // Remove existing tracking area
            if let trackingArea = self.trackingArea {
                self.removeTrackingArea(trackingArea)
            }
            
            // Create a new tracking area covering the entire view
            let options: NSTrackingArea.Options = [
                .activeAlways,
                .mouseEnteredAndExited,
                .mouseMoved,
                .enabledDuringMouseDrag
            ]
            
            let trackingArea = NSTrackingArea(
                rect: self.bounds,
                options: options,
                owner: self,
                userInfo: nil
            )
            
            self.addTrackingArea(trackingArea)
            self.trackingArea = trackingArea
            
            print("DEBUG: Updated tracking area to \(self.bounds)")
        }
        
        // Override to make sure we can become first responder
        override var acceptsFirstResponder: Bool {
            return true
        }
        
        // Ensure this view can receive mouse events
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            return true
        }
        
        override func layout() {
            super.layout()
            // Ensure the image is properly scaled whenever the view size changes
            print("DEBUG: DraggableImageView layout called - view size changed to: \(self.bounds.size)")
            self.needsDisplay = true
            updateTrackingAreas()
        }
        
        // Add a frameDidChange handler to respond to parent resize events
        override func setFrameSize(_ newSize: NSSize) {
            super.setFrameSize(newSize)
            if newSize.width > 0 && newSize.height > 0 {
                print("DEBUG: Frame size changed to \(newSize.width) x \(newSize.height)")
                self.needsDisplay = true
                updateTrackingAreas()
            }
        }
        
        // Mouse event callbacks
        override func mouseEntered(with event: NSEvent) {
            super.mouseEntered(with: event)
            print("DEBUG: Mouse entered view")
        }
        
        override func mouseExited(with event: NSEvent) {
            super.mouseExited(with: event)
            print("DEBUG: Mouse exited view")
        }
        
        override func mouseMoved(with event: NSEvent) {
            super.mouseMoved(with: event)
            // Uncomment if you want to see mouse movements (can be verbose)
            // print("DEBUG: Mouse moved in view: \(event.locationInWindow)")
        }
        
        // Mouse event handling
        override func mouseDown(with event: NSEvent) {
            // Remove verbose logging
            super.mouseDown(with: event)
            delegate?.handleMouseDown(event)
        }
        
        override func mouseDragged(with event: NSEvent) {
            // Remove verbose logging
            super.mouseDragged(with: event)
            delegate?.handleMouseDragged(event)
        }
        
        override func mouseUp(with event: NSEvent) {
            // Remove verbose logging
            super.mouseUp(with: event)
            delegate?.handleMouseUp(event)
        }
        
        // Draw rectangles
        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            
            guard let delegate = delegate,
                  let viewModel = delegate.parent.viewModel as ImageAnnotationViewModel?,
                  self.image != nil else { 
                return
            }
            
            // Only proceed if the current index is valid
            guard viewModel.imageURLs.indices.contains(viewModel.currentImageIndex) else {
                return
            }
            
            let currentIndex = viewModel.currentImageIndex
            let imageFrame = self.imageFrame()
            
            // Check if we have a valid image frame
            if imageFrame.width <= 0 || imageFrame.height <= 0 {
                return
            }
            
            // Use the originalImageSize for coordinate conversion
            let originalImageSize = viewModel.originalImageSize
            
            // Calculate the scale factors
            let xScale = imageFrame.width / originalImageSize.width
            let yScale = imageFrame.height / originalImageSize.height
            
            // Draw saved annotations
            let annotations = viewModel.imageAnnotations[currentIndex].annotations
            if !annotations.isEmpty {
                print("DEBUG: Drawing \(annotations.count) saved annotations")
            }
            for annotation in annotations {
                // Convert using the original image size
                let rect = annotation.rect.toCGRect(in: originalImageSize)
                let viewRect = NSRect(
                    x: imageFrame.minX + (rect.minX * xScale),
                    y: imageFrame.minY + (rect.minY * yScale),
                    width: rect.width * xScale,
                    height: rect.height * yScale
                )
                
                NSColor.green.withAlphaComponent(0.3).setFill()
                NSBezierPath(rect: viewRect).fill()
                NSColor.green.setStroke()
                NSBezierPath(rect: viewRect).stroke()
                
                // Draw the label
                let labelText = annotation.label
                let attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: NSColor.white,
                    .backgroundColor: NSColor.green.withAlphaComponent(0.7),
                    .font: NSFont.boldSystemFont(ofSize: 10)
                ]
                
                labelText.draw(at: NSPoint(x: viewRect.minX + 2, y: viewRect.maxY - 12), withAttributes: attributes)
            }
            
            // Draw current rectangle
            if viewModel.isDrawing || viewModel.tempAnnotation != nil {
                var drawRect: NSRect
                
                if viewModel.isDrawing {
                    // Convert the current rect to view coordinates
                    let rect = viewModel.currentRect
                    
                    // Skip empty rectangles
                    if rect.width <= 0 || rect.height <= 0 {
                        return
                    }
                    
                    drawRect = NSRect(
                        x: imageFrame.minX + (rect.minX * xScale),
                        y: imageFrame.minY + (rect.minY * yScale),
                        width: rect.width * xScale,
                        height: rect.height * yScale
                    )
                } else if let tempAnnotation = viewModel.tempAnnotation {
                    // Draw the temporary annotation using the original image size
                    let rect = tempAnnotation.rect.toCGRect(in: originalImageSize)
                    drawRect = NSRect(
                        x: imageFrame.minX + (rect.minX * xScale),
                        y: imageFrame.minY + (rect.minY * yScale),
                        width: rect.width * xScale,
                        height: rect.height * yScale
                    )
                } else {
                    return
                }
                
                // Ensure the rectangle is valid before drawing
                if drawRect.width <= 0 || drawRect.height <= 0 {
                    return
                }
                
                // Draw with a more visible color
                NSColor.yellow.withAlphaComponent(0.5).setFill()
                NSBezierPath(rect: drawRect).fill()
                NSColor.yellow.setStroke()
                let path = NSBezierPath(rect: drawRect)
                path.lineWidth = 2.0
                path.stroke()
            }
        }
        
        // Enhanced helper to get the frame of the image within the view
        func imageFrame() -> NSRect {
            guard let image = self.image else { return .zero }
            
            // Get the actual bounds of our view
            let viewSize = self.bounds.size
            
            // Ensure view has proper dimensions - return centered but zero-sized rect if view is not yet sized
            if viewSize.width <= 0 || viewSize.height <= 0 {
                return NSRect(x: self.bounds.midX, y: self.bounds.midY, width: 0, height: 0)
            }
            
            let imageSize = image.size
            
            // Ensure we're dealing with valid image dimensions
            guard imageSize.width > 0, imageSize.height > 0 else {
                return .zero
            }
            
            // Add padding to ensure some margin around the image
            let padding: CGFloat = 20
            let availableWidth = viewSize.width - (padding * 2)
            let availableHeight = viewSize.height - (padding * 2)
            
            // Calculate the scaling factors to fit within available space
            let widthRatio = availableWidth / imageSize.width
            let heightRatio = availableHeight / imageSize.height
            
            // Use the smaller ratio to ensure the image fits entirely within the view
            // Never scale up beyond original size (1.0)
            let scaleFactor = min(widthRatio, heightRatio, 1.0)
            
            // Calculate the scaled dimensions
            let scaledWidth = imageSize.width * scaleFactor
            let scaledHeight = imageSize.height * scaleFactor
            
            // Center the image in the available space
            let xOffset = (viewSize.width - scaledWidth) / 2
            let yOffset = (viewSize.height - scaledHeight) / 2
            
            // Create the rect where the image will be drawn
            let drawingRect = NSRect(
                x: xOffset,
                y: yOffset,
                width: scaledWidth,
                height: scaledHeight
            )
            
            return drawingRect
        }
    }
}
