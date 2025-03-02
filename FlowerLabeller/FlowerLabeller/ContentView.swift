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
                            await viewModel.nextImage()
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
    
    var body: some View {
        VStack {
            if viewModel.imageURLs.isEmpty {
                setupView
            } else {
                workspaceView
            }
        }
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
        }
    }
    
    private var setupView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            Text("Flower Labeller")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Select a directory containing JPG images to begin annotating")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Select Directory") {
                Task {
                    await viewModel.selectDirectory()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("o", modifiers: .command)
        }
        .padding()
    }
    
    private var workspaceView: some View {
        VStack {
            HStack {
                Text(viewModel.imageURLs[viewModel.currentImageIndex].lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
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
            
            // Image with annotation overlay
            ZStack {
                // Drawing view
                ImageDrawingView(viewModel: viewModel)
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
                        .padding(.bottom)
                }
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(KeyboardHandler())
    }
}
