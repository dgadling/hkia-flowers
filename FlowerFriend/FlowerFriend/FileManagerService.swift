import Foundation
import os.log
import UIKit

class FileManagerService: ObservableObject {
    private let logger = Logger(subsystem: "com.toasterwaffles.FlowerFriend", category: "FileManagerService")
    
    @Published var capturedFrames: [URL] = []
    @Published var diagnosticInfo: String = ""
    
    // Directory name in Documents folder
    private let capturedFramesFolder = "captured_frames"
    
    init() {
        createRequiredDirectories()
        refreshCapturedFrames()
        logDocumentsPath()
    }
    
    /// Create necessary directories in the Documents folder
    private func createRequiredDirectories() {
        do {
            let documentsDirectory = FileManager.documentsDirectory
            let capturedFramesDirectory = documentsDirectory.appendingPathComponent(capturedFramesFolder, isDirectory: true)
            
            // Create directories if they don't exist
            if !FileManager.default.fileExists(atPath: capturedFramesDirectory.path) {
                try FileManager.default.createDirectory(at: capturedFramesDirectory, withIntermediateDirectories: true)
                logger.info("Created captured_frames directory in Documents")
            }
        } catch {
            logger.error("Failed to create directories: \(error.localizedDescription)")
        }
    }
    
    /// Get list of all captured frames from Documents directory
    func refreshCapturedFrames() {
        do {
            let documentsDirectory = FileManager.documentsDirectory
            let capturedFramesDirectory = documentsDirectory.appendingPathComponent(capturedFramesFolder, isDirectory: true)
            
            // Get all files in the captured_frames directory
            let fileURLs = try FileManager.default.contentsOfDirectory(at: capturedFramesDirectory, 
                                                                    includingPropertiesForKeys: nil)
            
            // Filter for image files
            capturedFrames = fileURLs.filter { url in
                let fileExtension = url.pathExtension.lowercased()
                return fileExtension == "jpg" || fileExtension == "jpeg" || fileExtension == "png"
            }
            
            logger.info("Found \(self.capturedFrames.count) captured frames")
        } catch {
            logger.error("Failed to get captured frames: \(error.localizedDescription)")
        }
    }
    
    /// Check app group container for new files and copy them to Documents directory
    func syncFromAppGroupContainer() {
        // Get app group container
        guard let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.toasterwaffles.FlowerFriend") else {
            logger.error("Cannot access app group container")
            return
        }
        
        do {
            let appGroupFramesDir = appGroupContainer.appendingPathComponent("captured_frames")
            
            // Ensure the directory exists
            if !FileManager.default.fileExists(atPath: appGroupFramesDir.path) {
                logger.info("App group captured_frames directory doesn't exist yet")
                return
            }
            
            // Get all files in the app group captured_frames directory
            let fileURLs = try FileManager.default.contentsOfDirectory(at: appGroupFramesDir, 
                                                                    includingPropertiesForKeys: nil)
            
            // Filter for image files
            let imageFiles = fileURLs.filter { url in
                let fileExtension = url.pathExtension.lowercased()
                return fileExtension == "jpg" || fileExtension == "jpeg" || fileExtension == "png"
            }
            
            // Copy each file to Documents directory
            for fileURL in imageFiles {
                let _ = FileManager.copyToDocuments(from: fileURL, toFolder: capturedFramesFolder)
            }
            
            logger.info("Copied \(imageFiles.count) images from app group container to Documents")
            
            // Refresh the list of captured frames
            refreshCapturedFrames()
        } catch {
            logger.error("Failed to sync from app group container: \(error.localizedDescription)")
        }
    }
    
    /// Create a test file in the Documents directory to verify file sharing
    func createTestFile() -> Bool {
        do {
            // Get the Documents directory
            let documentsDirectory = FileManager.documentsDirectory
            let capturedFramesDirectory = documentsDirectory.appendingPathComponent(capturedFramesFolder, isDirectory: true)
            
            // Ensure directory exists
            if !FileManager.default.fileExists(atPath: capturedFramesDirectory.path) {
                try FileManager.default.createDirectory(at: capturedFramesDirectory, withIntermediateDirectories: true)
            }
            
            // Create a timestamp for unique filename
            let timestamp = Int(Date().timeIntervalSince1970)
            let fileName = "test_file_\(timestamp).txt"
            let fileURL = capturedFramesDirectory.appendingPathComponent(fileName)
            
            // Create test content
            let testContent = "This is a test file created to verify file sharing at \(Date()).\nPath: \(fileURL.path)"
            
            // Write the file
            try testContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            logger.info("✅ Successfully created test file at: \(fileURL.path)")
            
            // Refresh the captured frames list
            refreshCapturedFrames()
            
            return true
        } catch {
            logger.error("❌ Failed to create test file: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Print the Documents directory path for debugging
    private func logDocumentsPath() {
        let documentsDirectory = FileManager.documentsDirectory
        let capturedFramesDirectory = documentsDirectory.appendingPathComponent(capturedFramesFolder, isDirectory: true)
        
        diagnosticInfo = """
        Documents path: \(documentsDirectory.path)
        Captured frames path: \(capturedFramesDirectory.path)
        """
        
        logger.info("Documents directory: \(documentsDirectory.path)")
        logger.info("Captured frames directory: \(capturedFramesDirectory.path)")
    }
    
    /// Perform a thorough file system scan and copy all found images to Documents
    func findAndCopyAllImages() -> String {
        var report = "Starting file search...\n"
        let fileManager = FileManager.default
        
        // First check app group container
        if let appGroupContainer = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.toasterwaffles.FlowerFriend") {
            report += "Found app group container at: \(appGroupContainer.path)\n"
            
            // Check both the root and captured_frames subdirectory of app group
            let directoriesToCheck = [
                appGroupContainer,
                appGroupContainer.appendingPathComponent("captured_frames")
            ]
            
            for directory in directoriesToCheck {
                report += scanAndCopyFromDirectory(directory)
            }
        } else {
            report += "❌ Could not access app group container\n"
        }
        
        // Also check app's main bundle for any pre-bundled images
        if let bundleURL = Bundle.main.resourceURL {
            report += "Checking bundle at: \(bundleURL.path)\n"
            report += scanAndCopyFromDirectory(bundleURL)
        }
        
        // Refresh the list after all copying is done
        refreshCapturedFrames()
        
        report += "File operations complete. Found \(capturedFrames.count) images in Documents directory.\n"
        logger.info("\(report)")
        return report
    }
    
    /// Scan a directory for images and copy them to Documents
    private func scanAndCopyFromDirectory(_ directory: URL) -> String {
        var report = "Scanning: \(directory.path)\n"
        
        do {
            if !FileManager.default.fileExists(atPath: directory.path) {
                return "Directory doesn't exist: \(directory.path)\n"
            }
            
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            )
            
            let imageFiles = fileURLs.filter { url in
                let fileExtension = url.pathExtension.lowercased()
                return fileExtension == "jpg" || fileExtension == "jpeg" || fileExtension == "png"
            }
            
            report += "Found \(imageFiles.count) images\n"
            
            for fileURL in imageFiles {
                if let destinationURL = FileManager.copyToDocuments(from: fileURL, toFolder: capturedFramesFolder) {
                    report += "✅ Copied: \(fileURL.lastPathComponent) to \(destinationURL.path)\n"
                } else {
                    report += "❌ Failed to copy: \(fileURL.lastPathComponent)\n"
                }
            }
            
            // Recursively check subdirectories
            for fileURL in fileURLs where fileURL.hasDirectoryPath {
                report += scanAndCopyFromDirectory(fileURL)
            }
            
        } catch {
            report += "❌ Error scanning directory: \(error.localizedDescription)\n"
        }
        
        return report
    }
} 
