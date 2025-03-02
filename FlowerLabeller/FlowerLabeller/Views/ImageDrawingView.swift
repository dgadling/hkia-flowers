import SwiftUI

struct ImageDrawingView: NSViewRepresentable {
    @ObservedObject var viewModel: ImageAnnotationViewModel
    
    func makeNSView(context: Context) -> NSImageView {
        let imageView = DraggableImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.delegate = context.coordinator
        context.coordinator.imageView = imageView
        return imageView
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        guard let imageView = nsView as? DraggableImageView else { return }
        imageView.image = viewModel.currentImage
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
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setup()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }
        
        private func setup() {
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor.black.cgColor
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
        
        // Helper to get the frame of the image within the view
        func imageFrame() -> NSRect {
            guard let image = self.image else { return .zero }
            
            let viewSize = self.bounds.size
            let imageSize = image.size
            
            // Calculate aspect ratios
            let viewRatio = viewSize.width / viewSize.height
            let imageRatio = imageSize.width / imageSize.height
            
            var drawingRect = NSRect.zero
            
            if imageRatio > viewRatio {
                // Image is wider than view
                let height = viewSize.width / imageRatio
                drawingRect = NSRect(
                    x: 0,
                    y: (viewSize.height - height) / 2,
                    width: viewSize.width,
                    height: height
                )
            } else {
                // Image is taller than view
                let width = viewSize.height * imageRatio
                drawingRect = NSRect(
                    x: (viewSize.width - width) / 2,
                    y: 0,
                    width: width,
                    height: viewSize.height
                )
            }
            
            return drawingRect
        }
    }
}