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
        
        init(_ parent: ImageDrawingView) {
            self.parent = parent
        }
        
        @objc func handleMouseDown(_ event: NSEvent) {
            guard let imageView = imageView,
                  let image = imageView.image,
                  let windowPoint = imageView.window?.convertPoint(fromScreen: event.locationInWindow),
                  let viewPoint = imageView.convert(windowPoint, from: nil) as NSPoint? else {
                return
            }
            
            // Convert view coordinates to image coordinates
            let imageFrame = imageView.imageFrame()
            if !imageFrame.contains(viewPoint) {
                return
            }
            
            // Calculate point relative to the image
            let imagePoint = NSPoint(
                x: (viewPoint.x - imageFrame.minX) * (image.size.width / imageFrame.width),
                y: (viewPoint.y - imageFrame.minY) * (image.size.height / imageFrame.height)
            )
            
            startPoint = imagePoint
            // Use Task to call the actor-isolated method
            Task { @MainActor in
                parent.viewModel.startDrawing(at: CGPoint(x: imagePoint.x, y: imagePoint.y))
            }
        }
        
        @objc func handleMouseDragged(_ event: NSEvent) {
            guard let imageView = imageView,
                  let image = imageView.image,
                  let startPoint = startPoint,
                  let windowPoint = imageView.window?.convertPoint(fromScreen: event.locationInWindow),
                  let viewPoint = imageView.convert(windowPoint, from: nil) as NSPoint? else {
                return
            }
            
            // Get image frame
            let imageFrame = imageView.imageFrame()
            
            // Calculate dragged point relative to the image
            let imagePoint = NSPoint(
                x: (viewPoint.x - imageFrame.minX) * (image.size.width / imageFrame.width),
                y: (viewPoint.y - imageFrame.minY) * (image.size.height / imageFrame.height)
            )
            
            // Update the rectangle - use Task to call actor-isolated method
            Task { @MainActor in
                parent.viewModel.updateDrawing(
                    to: CGPoint(x: imagePoint.x, y: imagePoint.y),
                    from: CGPoint(x: startPoint.x, y: startPoint.y)
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
            
            // Log the layer-backing status
            print("DEBUG: Layer-backed view: \(self.wantsLayer)")
            print("DEBUG: Layer: \(self.layer != nil ? "exists" : "nil")")
        }
        
        override func layout() {
            super.layout()
            // Ensure the image is properly scaled whenever the view size changes
            print("DEBUG: DraggableImageView layout called - view size changed to: \(self.bounds.size)")
            self.needsDisplay = true
        }
        
        // Add a frameDidChange handler to respond to parent resize events
        override func setFrameSize(_ newSize: NSSize) {
            super.setFrameSize(newSize)
            if newSize.width > 0 && newSize.height > 0 {
                print("DEBUG: Frame size changed to \(newSize.width) x \(newSize.height)")
                self.needsDisplay = true
            }
        }
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            print("DEBUG: DraggableImageView moved to window")
            // Force a layout update when the view appears in a window
            if self.window != nil {
                self.needsLayout = true
                self.needsDisplay = true
            }
        }
        
        override func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)
            delegate?.handleMouseDown(event)
        }
        
        override func mouseDragged(with event: NSEvent) {
            super.mouseDragged(with: event)
            delegate?.handleMouseDragged(event)
        }
        
        override func mouseUp(with event: NSEvent) {
            super.mouseUp(with: event)
            delegate?.handleMouseUp(event)
        }
        
        // Draw rectangles
        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            
            guard let delegate = delegate,
                  let viewModel = delegate.parent.viewModel as ImageAnnotationViewModel?,
                  let image = self.image else { return }
            
            // Only proceed if the current index is valid
            guard viewModel.imageURLs.indices.contains(viewModel.currentImageIndex) else { return }
            
            let currentIndex = viewModel.currentImageIndex
            let imageFrame = self.imageFrame()
            
            // Log actual drawing dimensions for debugging
            print("DEBUG: Drawing image at: \(imageFrame.origin.x), \(imageFrame.origin.y), \(imageFrame.width) x \(imageFrame.height)")
            
            let xScale = imageFrame.width / image.size.width
            let yScale = imageFrame.height / image.size.height
            
            // Draw saved annotations
            let annotations = viewModel.imageAnnotations[currentIndex].annotations
            for annotation in annotations {
                let rect = annotation.rect.toCGRect(in: image.size)
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
                    drawRect = NSRect(
                        x: imageFrame.minX + (rect.minX * xScale),
                        y: imageFrame.minY + (rect.minY * yScale),
                        width: rect.width * xScale,
                        height: rect.height * yScale
                    )
                } else if let tempAnnotation = viewModel.tempAnnotation {
                    // Draw the temporary annotation
                    let rect = tempAnnotation.rect.toCGRect(in: image.size)
                    drawRect = NSRect(
                        x: imageFrame.minX + (rect.minX * xScale),
                        y: imageFrame.minY + (rect.minY * yScale),
                        width: rect.width * xScale,
                        height: rect.height * yScale
                    )
                } else {
                    return
                }
                
                NSColor.yellow.withAlphaComponent(0.3).setFill()
                NSBezierPath(rect: drawRect).fill()
                NSColor.yellow.setStroke()
                NSBezierPath(rect: drawRect).stroke()
            }
        }
        
        // Enhanced helper to get the frame of the image within the view
        func imageFrame() -> NSRect {
            guard let image = self.image else { return .zero }
            
            // Get the actual bounds of our view
            let viewSize = self.bounds.size
            
            // Ensure view has proper dimensions - return centered but zero-sized rect if view is not yet sized
            if viewSize.width <= 0 || viewSize.height <= 0 {
                print("DEBUG: View has invalid dimensions: \(viewSize). Deferring image scaling.")
                return NSRect(x: self.bounds.midX, y: self.bounds.midY, width: 0, height: 0)
            }
            
            let imageSize = image.size
            
            // Ensure we're dealing with valid image dimensions
            guard imageSize.width > 0, imageSize.height > 0 else {
                print("DEBUG: Invalid image dimensions: \(imageSize)")
                return .zero
            }
            
            // Add padding to ensure some margin around the image
            let padding: CGFloat = 20
            let availableWidth = viewSize.width - (padding * 2)
            let availableHeight = viewSize.height - (padding * 2)
            
            print("DEBUG: Available space: \(availableWidth) x \(availableHeight)")
            
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
            
            print("DEBUG: Image scaling - view: \(viewSize.width)x\(viewSize.height), " +
                  "image: \(imageSize.width)x\(imageSize.height), " +
                  "scaled: \(scaledWidth)x\(scaledHeight), " +
                  "ratio: \(scaleFactor), " +
                  "position: (\(xOffset), \(yOffset))")
            
            return drawingRect
        }
    }
}