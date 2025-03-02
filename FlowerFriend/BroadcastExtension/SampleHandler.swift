//
//  SampleHandler.swift
//  BroadcastExtension
//
//  Created by David Gadling on 3/2/25.
//

import ReplayKit
import CoreImage
import UIKit

class SampleHandler: RPBroadcastSampleHandler {
    
    private var frameCounter = 0
    private let frameProcessingInterval = 30 // Process every 30th frame (adjust as needed)
    private let containerURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.FlowerFriend")!
    private let developerModeKey = "developerMode"
    
    // Track processed frames for rate limiting
    private var lastProcessedTime: CFTimeInterval = 0
    private let minTimeBetweenFrames: CFTimeInterval = 1.0 // 1 second between processed frames
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // Create directories if needed
        let imagesDir = containerURL.appendingPathComponent("captured_frames", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        
        // Reset frame counter
        frameCounter = 0
        
        // Send notification to the app that broadcast has started
        sendMessageToApp(type: "broadcastStarted")
    }
    
    override func broadcastPaused() {
        sendMessageToApp(type: "broadcastPaused")
    }
    
    override func broadcastResumed() {
        sendMessageToApp(type: "broadcastResumed")
    }
    
    override func broadcastFinished() {
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
            
        case RPSampleBufferType.audioApp:
            // We don't need audio for flower detection
            break
            
        case RPSampleBufferType.audioMic:
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
            return
        }
        
        // Get image from sample buffer
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Convert to CIImage
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }
        let uiImage = UIImage(cgImage: cgImage)
        
        // Process the image for flower detection
        processImage(uiImage)
    }
    
    private func processImage(_ image: UIImage) {
        // In the future, this will contain ML-based flower detection
        // For now, we'll just send the frame to the app and possibly save it
        
        // Check if we're in developer mode
        let userDefaults = UserDefaults(suiteName: "group.com.example.FlowerFriend")
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
        
        // Compress and save the image
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }
    
    private func sendFrameToApp(_ image: UIImage) {
        // Compress image for transmission
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            return
        }
        
        // Create a message to the app
        let message: [String: Any] = [
            "type": "newFrame",
            "imageData": imageData
        ]
        
        // Serialize the message
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: message, requiringSecureCoding: false) else {
            return
        }
        
        // Save to shared container
        let messageURL = containerURL.appendingPathComponent("latest_frame.data")
        try? data.write(to: messageURL)
        
        // Notify app through UserDefaults
        let userDefaults = UserDefaults(suiteName: "group.com.example.FlowerFriend")
        userDefaults?.set(Date().timeIntervalSince1970, forKey: "latestFrameTimestamp")
    }
    
    private func sendMessageToApp(type: String) {
        let message: [String: Any] = ["type": type]
        
        // Serialize the message
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: message, requiringSecureCoding: false) else {
            return
        }
        
        // Save to shared container
        let messageURL = containerURL.appendingPathComponent("broadcast_status.data")
        try? data.write(to: messageURL)
        
        // Notify app through UserDefaults
        let userDefaults = UserDefaults(suiteName: "group.com.example.FlowerFriend")
        userDefaults?.set(Date().timeIntervalSince1970, forKey: "broadcastStatusTimestamp")
    }
}
