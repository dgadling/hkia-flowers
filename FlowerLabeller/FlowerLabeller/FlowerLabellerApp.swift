//
//  FlowerLabellerApp.swift
//  FlowerLabeller
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI
import Metal

@main
struct FlowerLabellerApp: App {
    @StateObject private var keyboardHandler = KeyboardHandler()
    
    init() {
        // Debug Metal configuration on startup
        checkMetalAvailability()
        
        // Check temp and cache directories
        checkDirectories()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(keyboardHandler)
                .onAppear {
                    // Set a reasonable window size
                    if let window = NSApp.windows.first {
                        window.setFrame(NSRect(x: 0, y: 0, width: 1200, height: 800), display: true)
                        window.center()
                    }
                    
                    // Additional app startup diagnostics
                    print("DEBUG: App window initialized")
                }
        }
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
    
    private func checkMetalAvailability() {
        print("DEBUG: Checking Metal availability...")
        
        // Check if Metal is available on this device
        guard MTLCreateSystemDefaultDevice() != nil else {
            print("DEBUG: ❌ Metal is not available on this device")
            return
        }
        
        print("DEBUG: ✅ Metal is available on this device")
        
        // Try to find default.metallib
        let possiblePaths: [String?] = [
            Bundle.main.bundleURL.appendingPathComponent("default.metallib").path,
            Bundle.main.resourceURL?.appendingPathComponent("default.metallib").path,
            Bundle.main.bundlePath + "/Contents/Resources/default.metallib"
        ]
        
        print("DEBUG: Checking for Metal library at possible locations:")
        for path in possiblePaths {
            if let path = path {
                let exists = FileManager.default.fileExists(atPath: path)
                print("DEBUG: - \(path): \(exists ? "✅ EXISTS" : "❌ NOT FOUND")")
            } else {
                print("DEBUG: - Path is nil")
            }
        }
    }
    
    private func checkDirectories() {
        // Check temp directory
        let tempDir = FileManager.default.temporaryDirectory
        print("DEBUG: Temporary directory: \(tempDir.path)")
        
        // Check if the app has write access to temp directory
        do {
            let testFile = tempDir.appendingPathComponent("test_write.txt")
            try "test".write(to: testFile, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testFile)
            print("DEBUG: ✅ App has write access to temporary directory")
        } catch {
            print("DEBUG: ❌ App does not have write access to temporary directory: \(error.localizedDescription)")
        }
        
        // Check cache directory
        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            print("DEBUG: Cache directory: \(cacheDir.path)")
            
            // Check if the app has write access to cache directory
            do {
                let testFile = cacheDir.appendingPathComponent("test_write.txt")
                try "test".write(to: testFile, atomically: true, encoding: .utf8)
                try FileManager.default.removeItem(at: testFile)
                print("DEBUG: ✅ App has write access to cache directory")
            } catch {
                print("DEBUG: ❌ App does not have write access to cache directory: \(error.localizedDescription)")
            }
        }
    }
}
