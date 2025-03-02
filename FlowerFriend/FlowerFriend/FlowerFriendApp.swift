//
//  FlowerFriendApp.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI

@main
struct FlowerFriendApp: App {
    // State objects shared across the app
    @StateObject private var flowerInventory = FlowerInventory()
    @StateObject private var broadcastService = BroadcastService()
    
    // Lazily initialize the detector
    private let flowerDetector = FlowerDetector()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(flowerInventory)
                .environmentObject(broadcastService)
                .onAppear {
                    setupBroadcastService()
                }
        }
    }
    
    private func setupBroadcastService() {
        // Set up callback for new frames
        broadcastService.onNewFrame = { [weak flowerInventory] image in
            // Process the frame when received
            self.processFrame(image, inventory: flowerInventory)
        }
    }
    
    private func processFrame(_ image: UIImage, inventory: FlowerInventory?) {
        // Use detector to find flowers in the image
        flowerDetector.detectFlowers(in: image) { results in
            // Add detected flowers to inventory
            results.forEach { result in
                if result.confidence >= self.flowerDetector.confidenceThreshold {
                    inventory?.addFlower(result.flower)
                }
            }
        }
    }
}
