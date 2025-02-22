//
//  LabelingView.swift
//  FlowerLabeler
//
//  Created by David Gadling on 2/22/25.
//

import SwiftUI
import AppKit

struct LabelingView: View {
    @State private var currentImage: NSImage?
    @State private var imageFiles: [URL] = []
    @State private var currentIndex = 0
    @State private var boundingBoxes: [BoundingBox] = []
    @State private var isDrawing = false
    @State private var startPoint: CGPoint?
    @State private var currentBox: CGRect = .zero
    @State private var selectedBoxIndex: Int?
    @State private var workingDirectory: URL?
    
    struct BoundingBox: Codable, Identifiable {
        var id = UUID()
        var rect: CGRect
        var label: String
    }
    
    var body: some View {
        HSplitView {
            // Left side: Image viewer
            ZStack {
                if let image = currentImage {
                    GeometryReader { geometry in
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.1))
                            .overlay(
                                BoundingBoxesView(
                                    boxes: boundingBoxes,
                                    selectedIndex: selectedBoxIndex,
                                    imageSize: image.size,
                                    viewSize: geometry.size
                                )
                            )
                            .gesture(
                                DragGesture(minimumDistance: 2)
                                    .onChanged { value in
                                        handleDrag(value, in: geometry.size)
                                    }
                                    .onEnded { value in
                                        finishDrawing(value, in: geometry.size)
                                    }
                            )
                    }
                } else {
                    Text("Select a folder with images to begin")
                        .font(.title)
                }
            }
            .frame(minWidth: 600)
            
            // Right side: Controls
            VStack(spacing: 20) {
                Button("Select Images Folder") {
                    selectFolder()
                }
                .padding()
                
                if !imageFiles.isEmpty {
                    Text("Image \(currentIndex + 1) of \(imageFiles.count)")
                    
                    // Navigation buttons
                    HStack {
                        Button("Previous") {
                            loadPreviousImage()
                        }
                        .disabled(currentIndex == 0)
                        
                        Button("Next") {
                            saveAndLoadNext()
                        }
                        .disabled(currentIndex >= imageFiles.count - 1)
                    }
                    
                    // Bounding boxes list
                    List(boundingBoxes) { box in
                        HStack {
                            TextField("Label", text: binding(for: box))
                            Button("Delete") {
                                boundingBoxes.removeAll { $0.id == box.id }
                            }
                        }
                    }
                    .frame(height: 200)
                    
                    Button("Export Annotations") {
                        exportAnnotations()
                    }
                    .padding()
                }
            }
            .frame(width: 250)
            .padding()
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        if panel.runModal() == .OK {
            workingDirectory = panel.url
            loadImagesFromDirectory()
        }
    }
    
    private func loadImagesFromDirectory() {
        guard let directory = workingDirectory else { return }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            )
            imageFiles = files.filter { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "png" }
            if !imageFiles.isEmpty {
                currentIndex = 0
                loadCurrentImage()
            }
        } catch {
            print("Error loading directory: \(error)")
        }
    }
    
    private func loadCurrentImage() {
        guard currentIndex < imageFiles.count else { return }
        currentImage = NSImage(contentsOf: imageFiles[currentIndex])
        loadAnnotations()
    }
    
    private func handleDrag(_ value: DragGesture.Value, in size: CGSize) {
        if !isDrawing {
            isDrawing = true
            startPoint = value.startLocation
        }
        
        guard let start = startPoint else { return }
        
        let minX = min(start.x, value.location.x)
        let minY = min(start.y, value.location.y)
        let width = abs(value.location.x - start.x)
        let height = abs(value.location.y - start.y)
        
        currentBox = CGRect(x: minX, y: minY, width: width, height: height)
    }
    
    private func finishDrawing(_ value: DragGesture.Value, in size: CGSize) {
        guard isDrawing, let image = currentImage else { return }
        
        // Convert view coordinates to normalized coordinates (0-1)
        let normalizedRect = CGRect(
            x: currentBox.minX / size.width,
            y: currentBox.minY / size.height,
            width: currentBox.width / size.width,
            height: currentBox.height / size.height
        )
        
        boundingBoxes.append(BoundingBox(rect: normalizedRect, label: ""))
        
        isDrawing = false
        startPoint = nil
        currentBox = .zero
    }
    
    private func binding(for box: BoundingBox) -> Binding<String> {
        Binding(
            get: { box.label },
            set: { newValue in
                if let index = boundingBoxes.firstIndex(where: { $0.id == box.id }) {
                    boundingBoxes[index].label = newValue
                }
            }
        )
    }
    
    private func saveAndLoadNext() {
        saveAnnotations()
        currentIndex += 1
        loadCurrentImage()
    }
    
    private func loadPreviousImage() {
        saveAnnotations()
        currentIndex -= 1
        loadCurrentImage()
    }
    
    private func saveAnnotations() {
        let url = imageFiles[currentIndex].deletingPathExtension().appendingPathExtension("json")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(boundingBoxes)
            try data.write(to: url)
        } catch {
            print("Error saving annotations: \(error)")
        }
    }
    
    private func loadAnnotations() {
        let url = imageFiles[currentIndex].deletingPathExtension().appendingPathExtension("json")
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            boundingBoxes = try decoder.decode([BoundingBox].self, from: data)
        } catch {
            boundingBoxes = []
        }
    }
    
    private func exportAnnotations() {
        guard let directory = workingDirectory else { return }
        
        // Create Create ML format annotations
        var annotations: [[String: Any]] = []
        
        for (index, imageFile) in imageFiles.enumerated() {
            let boxes = boundingBoxes.map { box -> [String: Any] in
                [
                    "label": box.label,
                    "coordinates": [
                        "x": box.rect.minX,
                        "y": box.rect.minY,
                        "width": box.rect.width,
                        "height": box.rect.height
                    ]
                ]
            }
            
            let annotation: [String: Any] = [
                "image": imageFile.lastPathComponent,
                "annotations": boxes
            ]
            annotations.append(annotation)
        }
        
        // Save combined annotations file
        let annotationsURL = directory.appendingPathComponent("annotations.json")
        do {
            let data = try JSONSerialization.data(withJSONObject: annotations, options: .prettyPrinted)
            try data.write(to: annotationsURL)
            
            NSWorkspace.shared.selectFile(annotationsURL.path, inFileViewerRootedAtPath: directory.path)
        } catch {
            print("Error exporting annotations: \(error)")
        }
    }
}

struct BoundingBoxesView: View {
    let boxes: [LabelingView.BoundingBox]
    let selectedIndex: Int?
    let imageSize: CGSize
    let viewSize: CGSize
    
    var body: some View {
        ForEach(boxes) { box in
            let isSelected = selectedIndex == boxes.firstIndex(where: { $0.id == box.id })
            Rectangle()
                .stroke(isSelected ? Color.yellow : Color.green, lineWidth: 2)
                .frame(
                    width: box.rect.width * viewSize.width,
                    height: box.rect.height * viewSize.height
                )
                .position(
                    x: box.rect.midX * viewSize.width,
                    y: box.rect.midY * viewSize.height
                )
                .overlay(
                    Text(box.label)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .position(
                            x: box.rect.minX * viewSize.width,
                            y: (box.rect.minY * viewSize.height) - 10
                        )
                )
        }
    }
}
