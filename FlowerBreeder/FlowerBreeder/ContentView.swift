import SwiftUI
import ReplayKit

struct ContentView: View {
    @StateObject private var broadcastManager = BroadcastManager()
    
    var body: some View {
        TabView {
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "leaf")
                }
            
            BreedingSuggestionsView()
                .tabItem {
                    Label("Breeding", systemImage: "arrow.triangle.branch")
                }
        }
        .overlay(
            BroadcastControlView(isRecording: $broadcastManager.isRecording)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        )
    }
} 