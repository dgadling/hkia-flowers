//
//  SettingsView.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI
import os

struct SettingsView: View {
    @EnvironmentObject private var broadcastService: BroadcastService
    @EnvironmentObject private var flowerInventory: FlowerInventory
    
    @State private var showResetConfirmation = false
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                // App settings
                Section(header: Text("App Settings")) {
                    Toggle("Developer Mode", isOn: $broadcastService.isDeveloperMode)
                    
                    HStack {
                        Text("Detection Confidence")
                        Spacer()
                        Text("70%") // This would be configurable in a future version
                    }
                    
                    NavigationLink(destination: Text("Notification settings would go here")) {
                        HStack {
                            Text("Notifications")
                            Spacer()
                            Text("On")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Data management
                Section(header: Text("Data Management")) {
                    Button("Export Flower Collection") {
                        showExportSheet = true
                    }
                    
                    Button("Import Flower Collection") {
                        showImportSheet = true
                    }
                    
                    Button("Reset Flower Collection") {
                        showResetConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                
                // About section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: Text("Privacy policy would go here")) {
                        Text("Privacy Policy")
                    }
                    
                    NavigationLink(destination: Text("Terms of use would go here")) {
                        Text("Terms of Use")
                    }
                    
                    NavigationLink(destination: Text("Acknowledgments would go here")) {
                        Text("Acknowledgments")
                    }
                }
                
                // Developer section
                if broadcastService.isDeveloperMode {
                    Section(header: Text("Developer Options")) {
                        HStack {
                            Text("Saved Frames")
                            Spacer()
                            Text("\(broadcastService.getSavedFrames().count)")
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Clear Saved Frames") {
                            broadcastService.clearSavedFrames()
                        }
                        .foregroundColor(.red)
                        
                        NavigationLink(destination: DeveloperFrameView()) {
                            Text("View Saved Frames")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showResetConfirmation) {
                Alert(
                    title: Text("Reset Collection?"),
                    message: Text("This will delete all flowers in your collection. This action cannot be undone."),
                    primaryButton: .destructive(Text("Reset")) {
                        resetFlowerCollection()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func resetFlowerCollection() {
        // Clear the flower inventory
        flowerInventory.flowers.removeAll()
    }
}

struct DeveloperFrameView: View {
    @EnvironmentObject private var broadcastService: BroadcastService
    @State private var selectedFrame: UIImage?
    @State private var showingFrameDetails = false
    @State private var imageLoadingError: String?
    @State private var isCheckingFrames = false
    
    private let logger = Logger(subsystem: "com.toasterwaffles.FlowerFriend", category: "DeveloperFrameView")
    
    var body: some View {
        VStack {
            if isCheckingFrames {
                ProgressView("Checking saved frames...")
                    .padding()
            } else if let error = imageLoadingError {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .padding()
                    
                    Text("Error loading frames")
                        .font(.headline)
                    
                    Text(error)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Button("Try Again") {
                        loadFrames()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if broadcastService.getSavedFrames().isEmpty {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("No saved frames")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Frames will be saved here when you record in Developer Mode.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            } else {
                if let selectedFrame = selectedFrame {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedFrame)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                        
                        Button {
                            showingFrameDetails = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .padding(8)
                        }
                    }
                    .sheet(isPresented: $showingFrameDetails) {
                        frameDetailView(selectedFrame)
                    }
                }
                
                Divider()
                
                Text("Select a frame to view:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(broadcastService.loadSavedFrames(), id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .cornerRadius(8)
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedFrame == image ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedFrame = image
                                }
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                Button("Clear All Frames") {
                    broadcastService.clearSavedFrames()
                    selectedFrame = nil
                }
                .foregroundColor(.red)
                .padding(.bottom)
            }
            
            Spacer()
            
            Text("These frames can be used to train the ML model in the FlowerLabeler app.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("Saved Frames")
        .onAppear {
            loadFrames()
        }
    }
    
    private func loadFrames() {
        imageLoadingError = nil
        isCheckingFrames = true
        
        logger.debug("DeveloperFrameView appeared - checking for saved frames")
        
        // Simulate a short delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let frameUrls = self.broadcastService.getSavedFrames()
            logger.debug("Found \(frameUrls.count) saved frame URLs")
            
            if frameUrls.isEmpty {
                logger.info("No saved frames found")
            } else {
                let frames = self.broadcastService.loadSavedFrames()
                logger.debug("Loaded \(frames.count) frames as UIImages")
                
                if frames.isEmpty && !frameUrls.isEmpty {
                    self.imageLoadingError = "Found \(frameUrls.count) frame files but couldn't load any as images"
                    logger.error("❌ \(self.imageLoadingError!)")
                } else if let firstFrame = frames.first {
                    self.selectedFrame = firstFrame
                    logger.debug("Selected first frame")
                }
            }
            
            self.isCheckingFrames = false
        }
    }
    
    private func frameDetailView(_ image: UIImage) -> some View {
        NavigationStack {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                
                List {
                    Section("Image Details") {
                        detailRow(title: "Dimensions", value: "\(Int(image.size.width)) × \(Int(image.size.height))")
                        detailRow(title: "Scale", value: String(format: "%.1f", image.scale))
                        detailRow(title: "Orientation", value: "\(image.imageOrientation.rawValue)")
                    }
                }
            }
            .navigationTitle("Frame Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFrameDetails = false
                    }
                }
            }
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(BroadcastService())
            .environmentObject(FlowerInventory())
    }
} 