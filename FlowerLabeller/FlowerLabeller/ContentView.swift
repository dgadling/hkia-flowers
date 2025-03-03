//
//  ContentView.swift
//  FlowerLabeller
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI
import Combine

// Create a class to handle keyboard events since we need to store cancellables
class KeyboardEventHandler: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    func setupShortcuts(keyboardHandler: KeyboardHandler, viewModel: ImageAnnotationViewModel) {
        // Clear any existing subscriptions
        cancellables.removeAll()
        
        // Monitor keyboard events
        NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)
            .sink { _ in
                // Space key for next image
                if keyboardHandler.pressedKeys.contains("space") {
                    Task { @MainActor in
                        if viewModel.tempAnnotation == nil {
                            await viewModel.nextImage()
                        }
                    }
                }
                
                // Enter key for confirming annotation (when form is visible)
                if keyboardHandler.pressedKeys.contains("return") {
                    Task { @MainActor in
                        if viewModel.tempAnnotation != nil {
                            await viewModel.saveCurrentAnnotation()
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ImageAnnotationViewModel()
    @StateObject private var keyboardEventHandler = KeyboardEventHandler()
    @EnvironmentObject private var keyboardHandler: KeyboardHandler
    @State private var exportMessage: String?
    @State private var showingExportMessage = false
    @State private var showingHelp = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: {
                    Task {
                        await viewModel.selectDirectory()
                    }
                }) {
                    Label("Select Directory", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
                
                Button(action: {
                    showingHelp = true
                }) {
                    Label("Help", systemImage: "questionmark.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut("?", modifiers: [])
                
                if !viewModel.imageURLs.isEmpty {
                    Button(action: {
                        Task {
                            if let url = await viewModel.exportAnnotations() {
                                print("Exported annotations to: \(url.path)")
                            }
                        }
                    }) {
                        Label("Export Annotations", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            
            // Empty state
            if viewModel.imageURLs.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No Images Loaded")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Select a directory to begin labelling flowers")
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        Task {
                            await viewModel.selectDirectory()
                        }
                    }) {
                        Label("Select Directory", systemImage: "folder")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut("o", modifiers: .command)
                    
                    Button(action: {
                        showingHelp = true
                    }) {
                        Label("View Help", systemImage: "questionmark.circle")
                            .font(.headline)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(.top)
                }
                .padding()
                Spacer()
            } else {
                // Workspace when images are loaded
                workspaceView
            }
            
            // Status bar
            HStack {
                Text("Draw a rectangle around each flower and annotate it. Press Space to move to next image.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if !viewModel.imageURLs.isEmpty {
                    Text("\(viewModel.imageAnnotations[viewModel.currentImageIndex].annotations.count) annotations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
        .background(Color(.windowBackgroundColor))
        .frame(minWidth: 800, minHeight: 600)
        .alert("Export Complete", isPresented: $showingExportMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            if let message = exportMessage {
                Text(message)
            }
        }
        .onAppear {
            // Set up keyboard shortcuts in our handler class
            keyboardEventHandler.setupShortcuts(keyboardHandler: keyboardHandler, viewModel: viewModel)
            
            // Debug information
            print("DEBUG: ContentView appeared")
            
            // Check view model initialization
            print("DEBUG: ViewModel state on ContentView appear:")
            print("DEBUG: - imageURLs count: \(viewModel.imageURLs.count)")
            print("DEBUG: - currentImage: \(viewModel.currentImage != nil ? "exists" : "nil")")
            
            // Check operating system version
            let osVersion = ProcessInfo.processInfo.operatingSystemVersion
            print("DEBUG: macOS version: \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)")
            
            // Check bundle resources
            if let resourcePath = Bundle.main.resourcePath {
                print("DEBUG: Bundle resource path: \(resourcePath)")
                do {
                    let resources = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                    print("DEBUG: Bundle resources: \(resources)")
                } catch {
                    print("DEBUG: Failed to list bundle resources: \(error)")
                }
            }
        }
        .sheet(isPresented: $showingHelp) {
            HelpView(isPresented: $showingHelp)
        }
    }
    
    private var workspaceView: some View {
        VStack(spacing: 8) {
            // Toolbar with filename and actions
            HStack {
                Text(viewModel.imageURLs[viewModel.currentImageIndex].lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                Button("Help") {
                    showingHelp = true
                }
                .keyboardShortcut("?", modifiers: [])
                .buttonStyle(.bordered)
                
                Button("Export Annotations") {
                    Task {
                        if let url = await viewModel.exportAnnotations() {
                            exportMessage = "Annotations saved to \(url.path)"
                            showingExportMessage = true
                        } else {
                            exportMessage = "Failed to export annotations"
                            showingExportMessage = true
                        }
                    }
                }
                .keyboardShortcut("e", modifiers: .command)
                
                Button("Select New Directory") {
                    Task {
                        await viewModel.selectDirectory()
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            .padding(.horizontal)
            
            // Main content area with image and annotation controls
            GeometryReader { geometry in
                ZStack {
                    // Drawing view with proper containment - important to use a fixed frame
                    ImageDrawingView(viewModel: viewModel)
                        .frame(
                            width: geometry.size.width - 16,  // Account for padding
                            height: geometry.size.height - 60, // Allow space for navigation controls
                            alignment: .center 
                        )
                        .fixedSize(horizontal: false, vertical: false) // Prevent image size from influencing layout
                        .clipped() // Ensure image doesn't overflow bounds
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(Color.black.opacity(0.05))
                        )
                        .layoutPriority(1)
                    
                    // Annotation form when an area is selected
                    if viewModel.tempAnnotation != nil {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                AnnotationFormView(viewModel: viewModel)
                                    .padding()
                            }
                        }
                    }
                    
                    // Navigation controls at the bottom
                    VStack {
                        Spacer()
                        NavigationControlView(viewModel: viewModel)
                            .padding(.bottom, 8)
                    }
                }
            }
            .padding(8)
            
            // Status indicator for current image
            HStack {
                Text("Image \(viewModel.currentImageIndex + 1) of \(viewModel.imageURLs.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if !viewModel.imageURLs.isEmpty {
                    Text("\(viewModel.imageAnnotations[viewModel.currentImageIndex].annotations.count) annotations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(KeyboardHandler())
    }
}
