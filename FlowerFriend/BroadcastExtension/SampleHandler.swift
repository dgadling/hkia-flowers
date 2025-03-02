//
//  SampleHandler.swift
//  BroadcastExtension
//
//  Created by David Gadling on 3/2/25.
//

import ReplayKit
import CoreImage
import UIKit
import os.log

// Create a logger for debugging
private let logger = Logger(subsystem: "com.toasterwaffles.FlowerFriend.BroadcastExtension", category: "SampleHandler")

class SampleHandler: RPBroadcastSampleHandler {
    
    private var frameCounter = 0
    private var processedFrameCount = 0
    private let frameProcessingInterval = 30 // Process every 30th frame (adjust as needed)
    private let containerURL: URL
    private let developerModeKey = "developerMode"
    
    // Track processed frames for rate limiting
    private var lastProcessedTime: CFTimeInterval = 0
    private let minTimeBetweenFrames: CFTimeInterval = 1.0 // 1 second between processed frames
    
    // For tracking errors
    private var lastErrorLoggingTime: CFTimeInterval = 0
    
    override init() {
        // Get a usable directory for storing files
        // Using a shared container for communication with the main app
        if let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.toasterwaffles.FlowerFriend") {
            self.containerURL = appGroupContainer
            logger.info("✅ BroadcastExtension initialized with app group container: \(self.containerURL.path)")
            
            // Initialize shared user defaults with default values
            if let sharedDefaults = UserDefaults(suiteName: "group.com.toasterwaffles.FlowerFriend") {
                // Register default values to prevent "detaching from cfprefsd" errors
                sharedDefaults.register(defaults: [
                    "broadcastStatusTimestamp": 0.0,
                    "latestFrameTimestamp": 0.0,
                    "developerMode": false
                ])
            }
        } else {
            // Fallback to temp directory if app group container is not available
            self.containerURL = FileManager.default.temporaryDirectory
            logger.warning("⚠️ App group container not available, using temporary directory instead: \(self.containerURL.path)")
        }
        
        super.init()
        
        // Log current directory contents
        logAppGroupContents()
    }
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        logger.info("📱 Broadcast started with setup info: \(setupInfo?.description ?? "nil")")
        
        // Create directories if needed
        let imagesDir = containerURL.appendingPathComponent("captured_frames", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            logger.debug("Created/verified captured_frames directory")
        } catch {
            logger.error("❌ Failed to create captured_frames directory: \(error.localizedDescription)")
        }
        
        // Check if developer mode is enabled
        // Note: In extensions, we can't easily access shared settings
        // We'll assume developer mode is enabled in the extension
        let isDeveloperMode = true
        logger.debug("Developer mode: \(isDeveloperMode) (always enabled in extension)")
        
        // Reset frame counter
        frameCounter = 0
        processedFrameCount = 0
        
        // Send notification to the app that broadcast has started
        sendMessageToApp(type: "broadcastStarted")
    }
    
    override func broadcastPaused() {
        logger.info("📱 Broadcast paused")
        sendMessageToApp(type: "broadcastPaused")
    }
    
    override func broadcastResumed() {
        logger.info("📱 Broadcast resumed")
        sendMessageToApp(type: "broadcastResumed")
    }
    
    override func broadcastFinished() {
        logger.info("📱 Broadcast finished. Processed \(self.processedFrameCount) frames")
        sendMessageToApp(type: "broadcastFinished")
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Only process every nth frame to avoid overwhelming the system
            frameCounter += 1
            if frameCounter % frameProcessingInterval != 0 {
                return
            }
            
            // Rate limit processing to avoid too many frames
            let currentTime = CACurrentMediaTime()
            if currentTime - lastProcessedTime < minTimeBetweenFrames {
                return
            }
            lastProcessedTime = currentTime
            
            processVideoFrame(sampleBuffer)
            
        case RPSampleBufferType.audioApp, RPSampleBufferType.audioMic:
            // We don't need audio for flower detection
            break
            
        @unknown default:
            // Handle other sample buffer types
            break
        }
    }
    
    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        // Check if valid
        guard CMSampleBufferIsValid(sampleBuffer) else {
            logErrorWithThrottling("Invalid sample buffer received")
            return
        }
        
        // Get image from sample buffer
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            logErrorWithThrottling("Failed to get image buffer from sample buffer")
            return
        }
        
        // Convert to CIImage
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            logErrorWithThrottling("Failed to create CGImage from CIImage")
            return
        }
        let uiImage = UIImage(cgImage: cgImage)
        
        logger.debug("Processing frame \(self.frameCounter): \(uiImage.size.width)x\(uiImage.size.height)")
        
        // Process the image for flower detection
        processImage(uiImage)
        processedFrameCount += 1
    }
    
    private func processImage(_ image: UIImage) {
        // In the future, this will contain ML-based flower detection
        // For now, we'll just send the frame to the app and possibly save it
        
        // Check if we're in developer mode
        let userDefaults = UserDefaults(suiteName: "group.com.toasterwaffles.FlowerFriend")
        let isDeveloperMode = userDefaults?.bool(forKey: developerModeKey) ?? false
        
        if isDeveloperMode {
            // Save image for ML training
            saveImageForTraining(image)
        }
        
        // Send frame to the main app for processing
        sendFrameToApp(image)
    }
    
    private func saveImageForTraining(_ image: UIImage) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "frame_\(timestamp)_\(UUID().uuidString).jpg"
        let fileURL = containerURL.appendingPathComponent("captured_frames").appendingPathComponent(filename)
        
        logger.debug("Saving training frame to: \(fileURL.lastPathComponent)")
        
        // Compress and save the image
        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: fileURL)
                logger.debug("Successfully saved frame: \(fileURL.lastPathComponent) (\(data.count) bytes)")
            } catch {
                logger.error("❌ Failed to save frame: \(error.localizedDescription)")
            }
        } else {
            logger.error("❌ Failed to compress image to JPEG")
        }
    }
    
    private func sendFrameToApp(_ image: UIImage) {
        // Compress image for transmission
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            logger.error("❌ Failed to compress image for transmission")
            return
        }
        
        logger.debug("Sending frame to app: \(image.size.width)x\(image.size.height) (\(imageData.count) bytes)")
        
        // Create a message to the app
        let message: [String: Any] = [
            "type": "newFrame",
            "imageData": imageData
        ]
        
        // Serialize the message
        do {
            // Create archiver with proper settings
            let data = NSMutableData()
            let archiver = NSKeyedArchiver(requiringSecureCoding: false)
            archiver.outputFormat = .binary
            archiver.encode(message, forKey: NSKeyedArchiveRootObjectKey)
            archiver.finishEncoding()
            
            // Get the archived data
            let archivedData = archiver.encodedData
            
            // Save to container directory
            let messageURL = containerURL.appendingPathComponent("latest_frame.data")
            try archivedData.write(to: messageURL)
            
            // Update timestamp in UserDefaults so main app knows to check the file
            if let userDefaults = UserDefaults(suiteName: "group.com.toasterwaffles.FlowerFriend") {
                let timestamp = Date().timeIntervalSince1970
                userDefaults.set(timestamp, forKey: "latestFrameTimestamp")
                // Force a synchronize to ensure data is written immediately
                userDefaults.synchronize()
                logger.debug("Updated latestFrameTimestamp in UserDefaults: \(timestamp)")
            } else {
                logger.error("❌ Failed to access shared UserDefaults to update timestamp")
            }
            
            // Log success
            logger.debug("Successfully saved frame data to: \(messageURL.path)")
        } catch {
            logger.error("❌ Failed to send frame to app: \(error.localizedDescription)")
        }
    }
    
    private func sendMessageToApp(type: String) {
        let message: [String: Any] = ["type": type]
        
        logger.debug("Sending message to app: \(type)")
        
        // Serialize the message
        do {
            // Create archiver with proper settings
            let data = NSMutableData()
            let archiver = NSKeyedArchiver(requiringSecureCoding: false)
            archiver.outputFormat = .binary
            archiver.encode(message, forKey: NSKeyedArchiveRootObjectKey)
            archiver.finishEncoding()
            
            // Get the archived data
            let archivedData = archiver.encodedData
            
            // Save to container directory
            let messageURL = containerURL.appendingPathComponent("broadcast_status.data")
            try archivedData.write(to: messageURL)
            
            // Update timestamp in UserDefaults so main app knows to check the file
            if let userDefaults = UserDefaults(suiteName: "group.com.toasterwaffles.FlowerFriend") {
                let timestamp = Date().timeIntervalSince1970
                userDefaults.set(timestamp, forKey: "broadcastStatusTimestamp")
                // Force a synchronize to ensure data is written immediately
                userDefaults.synchronize()
                logger.debug("Updated broadcastStatusTimestamp in UserDefaults: \(timestamp)")
            } else {
                logger.error("❌ Failed to access shared UserDefaults to update timestamp")
            }
            
            // Log success
            logger.debug("Successfully saved message data to: \(messageURL.path)")
        } catch {
            logger.error("❌ Failed to send message to app: \(error.localizedDescription)")
        }
    }
    
    // Helper to log app group contents for debugging
    private func logAppGroupContents() {
        logger.debug("📂 App group container contents:")
        do {
            let items = try FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)
            if items.isEmpty {
                logger.debug("   (empty directory)")
            } else {
                for item in items {
                    logger.debug("   - \(item.lastPathComponent)")
                }
            }
        } catch {
            logger.error("❌ Failed to list app group contents: \(error.localizedDescription)")
        }
    }
    
    // Helper to throttle error logging
    private func logErrorWithThrottling(_ message: String) {
        let currentTime = CACurrentMediaTime()
        if currentTime - lastErrorLoggingTime > 5.0 { // Log at most every 5 seconds
            logger.error("❌ \(message)")
            lastErrorLoggingTime = currentTime
        }
    }
}
