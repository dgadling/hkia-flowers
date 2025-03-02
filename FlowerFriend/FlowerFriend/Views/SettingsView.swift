//
//  SettingsView.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var broadcastService: BroadcastService
    @EnvironmentObject private var flowerInventory: FlowerInventory
    
    @State private var showResetConfirmation = false
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    
    var body: some View {
        NavigationView {
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
    
    var body: some View {
        VStack {
            if broadcastService.getSavedFrames().isEmpty {
                Text("No saved frames")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                if let selectedFrame = selectedFrame {
                    Image(uiImage: selectedFrame)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(broadcastService.loadSavedFrames(), id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .cornerRadius(8)
                                .padding(4)
                                .onTapGesture {
                                    selectedFrame = image
                                }
                        }
                    }
                    .padding()
                }
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
            if let firstFrame = broadcastService.loadSavedFrames().first {
                selectedFrame = firstFrame
            }
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