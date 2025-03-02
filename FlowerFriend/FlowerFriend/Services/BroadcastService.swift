//
//  BroadcastService.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import Foundation
import UIKit
import Combine
import SwiftUI
import os.log

// Create a logger for debugging
private let logger = Logger(subsystem: "com.toasterwaffles.FlowerFriend", category: "BroadcastService")

enum BroadcastStatus {
    case inactive
    case starting
    case active
    case paused
    case stopping
    
    var displayText: String {
        switch self {
        case .inactive: return "Not Recording"
        case .starting: return "Starting Recording..."
        case .active: return "Recording Active"
        case .paused: return "Recording Paused"
        case .stopping: return "Stopping Recording..."
        }
    }
    
    var icon: String {
        switch self {
        case .inactive: return "play.circle"
        case .starting: return "rays"
        case .active: return "record.circle"
        case .paused: return "pause.circle"
        case .stopping: return "stop.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .inactive: return .gray
        case .starting: return .orange
        case .active: return .red
        case .paused: return .yellow
        case .stopping: return .orange
        }
    }
}

class BroadcastService: ObservableObject {
    @Published var status: BroadcastStatus = .inactive
    @Published var latestFrame: UIImage?
    @Published var lastStatusUpdate: Date = Date()
    @Published var lastFrameUpdate: Date = Date()
    @Published var isDeveloperMode: Bool = false {
        didSet {
            logger.debug("Developer mode changed: \(self.isDeveloperMode)")
            
            // Update both standard and shared UserDefaults
            UserDefaults.standard.set(isDeveloperMode, forKey: "developerMode")
            
            // Also update shared UserDefaults for the broadcast extension
            if let sharedDefaults = UserDefaults(suiteName: "group.com.toasterwaffles.FlowerFriend") {
                sharedDefaults.set(isDeveloperMode, forKey: "developerMode")
                sharedDefaults.synchronize()
                logger.debug("Updated developer mode in shared UserDefaults")
            }
        }
    }
    
    private let containerURL: URL
    private var statusObserver: AnyCancellable?
    private var frameObserver: AnyCancellable?
    private let refreshInterval: TimeInterval = 0.5 // Check for updates every 0.5 seconds
    
    // Debug tracking variables
    private var checkCount = 0
    private var lastLoggingTime = Date()
    
    // Callbacks
    var onNewFrame: ((UIImage) -> Void)?
    
    init() {
        // Use app group container for shared storage with broadcast extension
        if let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.toasterwaffles.FlowerFriend") {
            self.containerURL = appGroupContainer
            logger.info("✅ Using app group container for storage: \(self.containerURL.path)")
            
            // Initialize shared UserDefaults with default values to prevent errors
            if let sharedDefaults = UserDefaults(suiteName: "group.com.toasterwaffles.FlowerFriend") {
                // Register default values to ensure they exist
                sharedDefaults.register(defaults: [
                    "broadcastStatusTimestamp": 0.0,
                    "latestFrameTimestamp": 0.0,
                    "developerMode": false
                ])
                logger.debug("Registered default values for shared UserDefaults")
            }
        } else {
            // Fallback to Documents directory if app group container is not available
            self.containerURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            logger.warning("⚠️ App group container not available, using Documents directory instead: \(self.containerURL.path)")
        }
        
        // Note: Metal rendering errors in simulator are expected and can be ignored
        // These are common in the simulator environment and don't affect functionality
        
        // Check for developer mode in both standard and shared UserDefaults
        let standardDevMode = UserDefaults.standard.bool(forKey: "developerMode")
        let sharedDevMode = UserDefaults(suiteName: "group.com.toasterwaffles.FlowerFriend")?.bool(forKey: "developerMode") ?? false
        
        // Use either value (prefer standard UserDefaults, but if shared has it enabled, respect that)
        isDeveloperMode = standardDevMode || sharedDevMode
        logger.debug("Developer mode initialized: \(self.isDeveloperMode) (standard: \(standardDevMode), shared: \(sharedDevMode))")
        
        // Create directories if needed
        let imagesDir = containerURL.appendingPathComponent("captured_frames", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            logger.info("Created or verified captured_frames directory: \(imagesDir.path)")
        } catch {
            logger.error("❌ Failed to create captured_frames directory: \(error.localizedDescription)")
        }
        
        // Log app group contents for debugging
        logAppGroupContents()
        
        // Start observers
        startObservers()
    }
    
    private func logAppGroupContents() {
        logger.debug("📂 App group container contents:")
        do {
            let items = try FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)
            for item in items {
                logger.debug("   - \(item.lastPathComponent)")
            }
        } catch {
            logger.error("❌ Failed to list app group contents: \(error.localizedDescription)")
        }
    }
    
    private func startObservers() {
        logger.debug("Starting broadcast observers")
        
        // Observe broadcast status changes
        statusObserver = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkForBroadcastStatusUpdates()
            }
        
        // Observe new frames
        frameObserver = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkForNewFrames()
            }
    }
    
    private func checkForBroadcastStatusUpdates() {
        guard let userDefaults = UserDefaults(suiteName: "group.com.toasterwaffles.FlowerFriend") else {
            // Only log this error occasionally to avoid console spam
            if Date().timeIntervalSince(lastLoggingTime) > 10 {
                logger.error("❌ Failed to access shared UserDefaults for status update check")
                lastLoggingTime = Date()
            }
            return
        }
        
        // Get timestamp with a default value of 0 to avoid potential issues
        let timestamp = userDefaults.double(forKey: "broadcastStatusTimestamp")
        if timestamp <= 0 {
            // If timestamp is 0 or negative, it's likely not set yet
            return
        }
        
        if timestamp > lastStatusUpdate.timeIntervalSince1970 {
            // We have a new status update
            lastStatusUpdate = Date(timeIntervalSince1970: timestamp)
            logger.info("📡 New broadcast status update detected at timestamp: \(timestamp)")
            
            // Read message file
            let messageURL = containerURL.appendingPathComponent("broadcast_status.data")
            
            // Check if file exists
            if !FileManager.default.fileExists(atPath: messageURL.path) {
                logger.error("❌ Broadcast status file does not exist at: \(messageURL.path)")
                return
            }
            
            do {
                let data = try Data(contentsOf: messageURL)
                logger.debug("Read \(data.count) bytes from broadcast_status.data")
                
                // Set up unarchiver with allowed classes
                let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
                unarchiver.requiresSecureCoding = false
                unarchiver.setClass(NSDictionary.self, forClassName: "NSDictionary")
                unarchiver.setClass(NSString.self, forClassName: "NSString")
                
                guard let message = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [String: Any] else {
                    logger.error("❌ Failed to unarchive broadcast status data")
                    unarchiver.finishDecoding()
                    return
                }
                
                unarchiver.finishDecoding()
                
                logger.debug("Successfully unarchived broadcast status: \(message)")
                
                guard let statusType = message["type"] as? String else {
                    logger.error("❌ No 'type' field in broadcast status message")
                    return
                }
                
                // Update status
                let oldStatus = status
                switch statusType {
                case "broadcastStarted":
                    status = .active
                case "broadcastPaused":
                    status = .paused
                case "broadcastResumed":
                    status = .active
                case "broadcastFinished":
                    status = .inactive
                default:
                    logger.warning("⚠️ Unknown broadcast status type: \(statusType)")
                    break
                }
                
                if oldStatus != status {
                    logger.info("📢 Broadcast status changed from \(oldStatus.displayText) to \(self.status.displayText)")
                }
            } catch {
                logger.error("❌ Error reading broadcast status: \(error.localizedDescription)")
            }
        }
    }
    
    private func checkForNewFrames() {
        // Log frame check at regular intervals to avoid overwhelming the console
        checkCount += 1
        let shouldLogThisCheck = checkCount % 20 == 0
        
        guard status == .active else {
            if shouldLogThisCheck {
                logger.debug("Skipping frame check - broadcast status is \(self.status.displayText)")
            }
            return
        }
        
        guard let userDefaults = UserDefaults(suiteName: "group.com.toasterwaffles.FlowerFriend") else {
            if shouldLogThisCheck {
                logger.error("❌ Failed to access shared UserDefaults for frame check")
            }
            return
        }
        
        // Get timestamp with a default value of 0 to avoid potential issues
        let timestamp = userDefaults.double(forKey: "latestFrameTimestamp")
        if timestamp <= 0 {
            // If timestamp is 0 or negative, it's likely not set yet
            if shouldLogThisCheck {
                logger.debug("No valid frame timestamp found in UserDefaults")
            }
            return
        }
        
        if timestamp > lastFrameUpdate.timeIntervalSince1970 {
            // We have a new frame
            lastFrameUpdate = Date(timeIntervalSince1970: timestamp)
            logger.info("🖼️ New frame detected at timestamp: \(timestamp)")
            
            // Read frame file
            let frameURL = containerURL.appendingPathComponent("latest_frame.data")
            
            // Check if file exists
            if !FileManager.default.fileExists(atPath: frameURL.path) {
                logger.error("❌ Frame data file does not exist at: \(frameURL.path)")
                return
            }
            
            do {
                let data = try Data(contentsOf: frameURL)
                logger.debug("Read \(data.count) bytes from latest_frame.data")
                
                // Set up unarchiver with allowed classes
                let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
                unarchiver.requiresSecureCoding = false
                unarchiver.setClass(NSDictionary.self, forClassName: "NSDictionary")
                unarchiver.setClass(NSString.self, forClassName: "NSString")
                unarchiver.setClass(NSData.self, forClassName: "NSData")
                
                guard let message = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [String: Any] else {
                    logger.error("❌ Failed to unarchive frame data")
                    unarchiver.finishDecoding()
                    return
                }
                
                unarchiver.finishDecoding()
                
                guard let messageType = message["type"] as? String else {
                    logger.error("❌ No 'type' field in frame message")
                    return
                }
                
                guard messageType == "newFrame" else {
                    logger.warning("⚠️ Expected 'newFrame' message type but got '\(messageType)'")
                    return
                }
                
                guard let imageData = message["imageData"] as? Data else {
                    logger.error("❌ No 'imageData' field in frame message")
                    return
                }
                
                logger.debug("Successfully extracted image data of \(imageData.count) bytes")
                
                guard let image = UIImage(data: imageData) else {
                    logger.error("❌ Failed to create UIImage from frame data")
                    return
                }
                
                logger.info("✅ Successfully processed new frame: \(image.size.width)x\(image.size.height)")
                
                // Update latest frame
                DispatchQueue.main.async { [weak self] in
                    self?.latestFrame = image
                    self?.onNewFrame?(image)
                }
            } catch {
                logger.error("❌ Error reading frame data: \(error.localizedDescription)")
            }
        } else if shouldLogThisCheck {
            logger.debug("No new frames detected (last frame: \(self.lastFrameUpdate.timeIntervalSince1970), latest timestamp: \(timestamp))")
        }
    }
    
    // Developer mode functionality
    func getSavedFrames() -> [URL] {
        let framesDir = containerURL.appendingPathComponent("captured_frames", isDirectory: true)
        logger.debug("Getting saved frames from: \(framesDir.path)")
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: framesDir,
                includingPropertiesForKeys: nil
            )
            
            let jpgFiles = fileURLs.filter { $0.pathExtension == "jpg" }
            logger.info("Found \(jpgFiles.count) saved frame(s)")
            return jpgFiles
        } catch {
            logger.error("❌ Failed to list saved frames: \(error.localizedDescription)")
            return []
        }
    }
    
    func clearSavedFrames() {
        let framesDir = containerURL.appendingPathComponent("captured_frames", isDirectory: true)
        logger.info("Clearing saved frames from: \(framesDir.path)")
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: framesDir,
                includingPropertiesForKeys: nil
            )
            
            logger.debug("Found \(fileURLs.count) files to delete")
            
            for url in fileURLs {
                do {
                    try FileManager.default.removeItem(at: url)
                    logger.debug("Deleted: \(url.lastPathComponent)")
                } catch {
                    logger.error("❌ Failed to delete file \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            logger.info("✅ Finished clearing saved frames")
        } catch {
            logger.error("❌ Failed to list files for deletion: \(error.localizedDescription)")
        }
    }
    
    // Access saved frames as images
    func loadSavedFrames() -> [UIImage] {
        logger.debug("Loading saved frames as UIImages")
        let fileURLs = getSavedFrames()
        var images: [UIImage] = []
        
        for url in fileURLs {
            do {
                let data = try Data(contentsOf: url)
                if let image = UIImage(data: data) {
                    images.append(image)
                    logger.debug("Loaded image: \(url.lastPathComponent)")
                } else {
                    logger.warning("⚠️ Could not create UIImage from data: \(url.lastPathComponent)")
                }
            } catch {
                logger.error("❌ Failed to load image data from \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        logger.info("Loaded \(images.count) images from \(fileURLs.count) files")
        return images
    }
} 
