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
            UserDefaults(suiteName: "group.com.example.FlowerFriend")?.set(isDeveloperMode, forKey: "developerMode")
        }
    }
    
    private let containerURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.FlowerFriend")!
    private var statusObserver: AnyCancellable?
    private var frameObserver: AnyCancellable?
    private let refreshInterval: TimeInterval = 0.5 // Check for updates every 0.5 seconds
    
    // Callbacks
    var onNewFrame: ((UIImage) -> Void)?
    
    init() {
        // Check if developer mode is enabled
        if let userDefaults = UserDefaults(suiteName: "group.com.example.FlowerFriend") {
            isDeveloperMode = userDefaults.bool(forKey: "developerMode")
        }
        
        // Start observers
        startObservers()
        
        // Create directories if needed
        let imagesDir = containerURL.appendingPathComponent("captured_frames", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
    }
    
    private func startObservers() {
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
        guard let userDefaults = UserDefaults(suiteName: "group.com.example.FlowerFriend") else { return }
        
        let timestamp = userDefaults.double(forKey: "broadcastStatusTimestamp")
        if timestamp > lastStatusUpdate.timeIntervalSince1970 {
            // We have a new status update
            lastStatusUpdate = Date(timeIntervalSince1970: timestamp)
            
            // Read message file
            let messageURL = containerURL.appendingPathComponent("broadcast_status.data")
            if let data = try? Data(contentsOf: messageURL),
               let message = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data) as? [String: Any],
               let statusType = message["type"] as? String {
                
                // Update status
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
                    break
                }
            }
        }
    }
    
    private func checkForNewFrames() {
        guard status == .active else { return }
        guard let userDefaults = UserDefaults(suiteName: "group.com.example.FlowerFriend") else { return }
        
        let timestamp = userDefaults.double(forKey: "latestFrameTimestamp")
        if timestamp > lastFrameUpdate.timeIntervalSince1970 {
            // We have a new frame
            lastFrameUpdate = Date(timeIntervalSince1970: timestamp)
            
            // Read frame file
            let frameURL = containerURL.appendingPathComponent("latest_frame.data")
            if let data = try? Data(contentsOf: frameURL),
               let message = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data) as? [String: Any],
               let messageType = message["type"] as? String,
               messageType == "newFrame",
               let imageData = message["imageData"] as? Data,
               let image = UIImage(data: imageData) {
                
                // Update latest frame
                DispatchQueue.main.async { [weak self] in
                    self?.latestFrame = image
                    self?.onNewFrame?(image)
                }
            }
        }
    }
    
    // Developer mode functionality
    func getSavedFrames() -> [URL] {
        let framesDir = containerURL.appendingPathComponent("captured_frames", isDirectory: true)
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: framesDir,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }
        
        return fileURLs.filter { $0.pathExtension == "jpg" }
    }
    
    func clearSavedFrames() {
        let framesDir = containerURL.appendingPathComponent("captured_frames", isDirectory: true)
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: framesDir,
            includingPropertiesForKeys: nil
        ) else {
            return
        }
        
        for url in fileURLs {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // Access saved frames as images
    func loadSavedFrames() -> [UIImage] {
        let fileURLs = getSavedFrames()
        var images: [UIImage] = []
        
        for url in fileURLs {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        
        return images
    }
} 