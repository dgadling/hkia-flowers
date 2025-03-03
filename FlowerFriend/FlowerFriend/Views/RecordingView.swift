//
//  RecordingView.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI
import ReplayKit
import os.log

struct RecordingView: View {
    @EnvironmentObject private var broadcastService: BroadcastService
    @EnvironmentObject private var flowerInventory: FlowerInventory
    
    @State private var detectionMode: DetectionMode = .auto
    @State private var showBroadcastPicker = false
    @State private var showDevOptions = false
    @State private var newDetections: [FlowerDetector.DetectionResult] = []
    @State private var navigateToFrameView = false
    @State private var showFileManager = false
    
    private let logger = Logger(subsystem: "com.toasterwaffles.FlowerFriend", category: "RecordingView")
    
    enum DetectionMode {
        case auto // Automatically add detected flowers
        case manual // Requires confirmation before adding
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Status header
                statusHeader
                
                // Preview of latest frame
                framePreviewSection
                
                // Instructions
                instructionsSection
                
                // Control buttons
                controlButtonsSection
                
                // File management button
                Button(action: {
                    showFileManager = true
                }) {
                    HStack {
                        Image(systemName: "folder.badge.gearshape")
                        Text("Manage Captured Files")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Developer mode options
                if broadcastService.isDeveloperMode {
                    developerOptionsSection
                }
            }
            .padding()
            .navigationTitle("Screen Recording")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            logger.debug("Toggling developer mode: \(!broadcastService.isDeveloperMode)")
                            broadcastService.isDeveloperMode.toggle()
                        }
                    }) {
                        Label("Developer Mode", systemImage: broadcastService.isDeveloperMode ? "hammer.fill" : "hammer")
                    }
                }
            }
            .sheet(isPresented: $showBroadcastPicker) {
                BroadcastPickerRepresentable()
                    .frame(width: 60, height: 60)
                    .padding(.top, 100)
            }
            .sheet(isPresented: $showFileManager) {
                FileManagerView()
            }
            .onAppear {
                logger.debug("RecordingView appeared - status: \(broadcastService.status.displayText)")
            }
            .navigationDestination(isPresented: $navigateToFrameView) {
                DeveloperFrameView()
            }
        }
    }
    
    // MARK: - View Components
    
    private var statusHeader: some View {
        HStack {
            Image(systemName: broadcastService.status.icon)
                .foregroundColor(broadcastService.status.color)
                .imageScale(.large)
            
            Text(broadcastService.status.displayText)
                .font(.headline)
            
            Spacer()
            
            Text("Detection Mode:")
                .font(.subheadline)
            
            Picker("Mode", selection: $detectionMode) {
                Text("Auto").tag(DetectionMode.auto)
                Text("Manual").tag(DetectionMode.manual)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 150)
        }
        .padding(.vertical)
    }
    
    private var framePreviewSection: some View {
        VStack {
            if let latestFrame = broadcastService.latestFrame {
                ZStack {
                    Image(uiImage: latestFrame)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                    
                    // Overlay detection boxes
                    detectionBoxesOverlay
                }
                .frame(height: 300)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(
                        VStack {
                            Text("No frames received yet")
                                .foregroundColor(.gray)
                            
                            if broadcastService.status == .active {
                                Text("Broadcasting is active but no frames are being received.")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                            }
                        }
                    )
            }
        }
    }
    
    private var detectionBoxesOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw boxes for each detection
                ForEach(0..<newDetections.count, id: \.self) { index in
                    let detection = newDetections[index]
                    let box = detection.boundingBox
                    
                    // Convert normalized coordinates to view coordinates
                    let viewBox = CGRect(
                        x: box.origin.x * geometry.size.width,
                        y: box.origin.y * geometry.size.height,
                        width: box.width * geometry.size.width,
                        height: box.height * geometry.size.height
                    )
                    
                    Rectangle()
                        .strokeBorder(detection.flower.color.color.opacity(0.8), lineWidth: 2)
                        .frame(width: viewBox.width, height: viewBox.height)
                        .position(x: viewBox.midX, y: viewBox.midY)
                    
                    // Label with flower type
                    Text(detection.flower.displayName)
                        .font(.caption)
                        .padding(4)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .position(x: viewBox.midX, y: viewBox.minY - 10)
                }
            }
        }
    }
    
    private var instructionsSection: some View {
        Group {
            if broadcastService.status == .inactive {
                instructionsInactive
            } else {
                instructionsActive
            }
        }
        .font(.callout)
        .foregroundColor(.secondary)
        .padding(.vertical)
    }
    
    private var instructionsInactive: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("To start recording your flower collection:")
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "1.circle.fill")
                Text("Press the \"Start Recording\" button below")
            }
            
            HStack {
                Image(systemName: "2.circle.fill")
                Text("Select this app in the broadcast picker")
            }
            
            HStack {
                Image(systemName: "3.circle.fill")
                Text("Open HKIA and navigate to your flower collection")
            }
        }
    }
    
    private var instructionsActive: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recording in progress:")
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Flower detection is active")
            }
            
            HStack {
                Image(systemName: "hand.point.right.fill")
                Text("Slowly browse through your flowers in HKIA")
            }
            
            HStack {
                Image(systemName: "eye.fill")
                Text("Make sure each flower is clearly visible")
            }
        }
    }
    
    private var controlButtonsSection: some View {
        HStack {
            if broadcastService.status == .inactive {
                // Start button
                Button(action: { 
                    logger.debug("Start Recording button tapped - showing broadcast picker")
                    showBroadcastPicker = true 
                }) {
                    HStack {
                        Image(systemName: "record.circle")
                        Text("Start Recording")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                // Stop button
                Button(action: {
                    logger.debug("Stop Recording button tapped")
                    
                    // Fix: Use the RPScreenRecorder to stop the broadcast
                    RPScreenRecorder.shared().stopRecording() { previewViewController, error in
                        if let error = error {
                            logger.error("❌ Error finishing broadcast: \(error.localizedDescription)")
                        } else {
                            logger.debug("Successfully stopped recording")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "stop.circle")
                        Text("Stop Recording")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private var developerOptionsSection: some View {
        VStack(spacing: 12) {
            Divider()
            
            Button(action: {
                withAnimation {
                    showDevOptions.toggle()
                    logger.debug("Developer options toggle: \(showDevOptions)")
                }
            }) {
                HStack {
                    Text("Developer Options")
                    Spacer()
                    Image(systemName: showDevOptions ? "chevron.up" : "chevron.down")
                }
                .padding(.horizontal)
            }
            
            if showDevOptions {
                VStack(alignment: .leading, spacing: 12) {
                    let frameCount = broadcastService.getSavedFrames().count
                    Text("Captured frames: \(frameCount)")
                        .font(.subheadline)
                    
                    HStack {
                        Button("View Saved Frames") {
                            logger.debug("View Saved Frames button tapped")
                            navigateToFrameView = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Clear Saved Frames") {
                            logger.debug("Clear Saved Frames button tapped")
                            broadcastService.clearSavedFrames()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    
                    Text("Use these frames to train the ML model in the FlowerLabeler app.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - UIKit Broadcast Picker

struct BroadcastPickerRepresentable: UIViewRepresentable {
    private let logger = Logger(subsystem: "com.toasterwaffles.FlowerFriend", category: "BroadcastPicker")
    
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        logger.debug("Creating broadcast picker view")
        let pickerView = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        pickerView.preferredExtension = "com.toasterwaffles.FlowerFriend.BroadcastExtension"
        pickerView.showsMicrophoneButton = false
        
        // Try to get the button to customize it
        if let button = pickerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.imageView?.tintColor = .systemRed
            logger.debug("Successfully customized broadcast picker button")
        } else {
            logger.warning("Could not find broadcast picker button to customize")
        }
        
        return pickerView
    }
    
    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {
        // No updates needed
    }
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
            .environmentObject(BroadcastService())
            .environmentObject(FlowerInventory())
    }
}

// New view that encapsulates our file manager functionality
struct FileManagerView: View {
    @StateObject private var fileManager = FileManagerService()
    @State private var isRefreshing = false
    @State private var showFileReport = false
    @State private var fileReport = ""
    @State private var showDeleteConfirmation = false
    @State private var showDeletionReport = false
    @State private var deletionReport = ""
    @Environment(\.dismiss) private var dismiss
    
    private let logger = Logger(subsystem: "com.toasterwaffles.FlowerFriend", category: "FileManagerView")
    
    var body: some View {
        NavigationView {
            VStack {
                // File path diagnostic info
                Group {
                    Text("File System Info")
                        .font(.headline)
                        .padding(.top)
                    
                    Text(fileManager.diagnosticInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)
                }
                
                // Action buttons
                HStack(spacing: 20) {
                    // Import files button
                    Button(action: importAllFiles) {
                        HStack {
                            Image(systemName: "arrow.down.doc")
                            Text("Import Files")
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 160)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isRefreshing)
                    
                    // Delete files button
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All")
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 160)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isRefreshing || fileManager.capturedFrames.isEmpty)
                }
                .padding(.bottom, 20)
                
                if fileManager.capturedFrames.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No captured frames yet")
                            .font(.headline)
                        
                        Text("Use the Import Files button to locate images")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section(header: Text("Captured Frames")) {
                            ForEach(fileManager.capturedFrames, id: \.absoluteString) { fileURL in
                                VStack(alignment: .leading) {
                                    Text(fileURL.lastPathComponent)
                                        .font(.headline)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    
                                    Text("Path: \(fileURL.path)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("File Manager")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        refreshData()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        openFilesApp()
                    } label: {
                        Label("Files", systemImage: "folder")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Sync when the view appears
                refreshData()
            }
            .sheet(isPresented: $showFileReport) {
                NavigationView {
                    ScrollView {
                        Text(fileReport)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .navigationTitle("File Import Report")
                    .navigationBarItems(
                        trailing: Button("Done") {
                            showFileReport = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showDeletionReport) {
                NavigationView {
                    ScrollView {
                        Text(deletionReport)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .navigationTitle("File Deletion Report")
                    .navigationBarItems(
                        trailing: Button("Done") {
                            showDeletionReport = false
                        }
                    )
                }
            }
            .alert("Delete All Files", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllFiles()
                }
            } message: {
                Text("Are you sure you want to delete all \(fileManager.capturedFrames.count) files? This cannot be undone.")
            }
        }
    }
    
    private func refreshData() {
        isRefreshing = true
        
        // Create a background task to perform the sync
        DispatchQueue.global(qos: .userInitiated).async {
            // Sync from app group container
            fileManager.syncFromAppGroupContainer()
            
            // Refresh captured frames list
            fileManager.refreshCapturedFrames()
            
            // Update UI on main thread
            DispatchQueue.main.async {
                isRefreshing = false
            }
        }
    }
    
    private func importAllFiles() {
        isRefreshing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Run the comprehensive file finder that now moves files
            let report = fileManager.findAndMoveAllImages()
            
            // Update UI on main thread
            DispatchQueue.main.async {
                fileReport = report
                showFileReport = true
                isRefreshing = false
            }
        }
    }
    
    private func deleteAllFiles() {
        isRefreshing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Delete all captured frames
            let report = fileManager.deleteAllCapturedFrames()
            
            // Update UI on main thread
            DispatchQueue.main.async {
                deletionReport = report
                showDeletionReport = true
                isRefreshing = false
            }
        }
    }
    
    private func openFilesApp() {
        // Construct a URL to the Files app
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = URL(string: "shareddocuments://\(documentsDirectory.path)")
            
            if let url = url, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                logger.error("Failed to open Files app")
            }
        }
    }
} 
