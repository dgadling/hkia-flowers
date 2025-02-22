import SwiftUI

@main
struct FlowerBreederApp: App {
    @StateObject private var broadcastManager = BroadcastManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(broadcastManager)
        }
    }
} 