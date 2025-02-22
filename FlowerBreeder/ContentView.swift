import SwiftUI
import ReplayKit

struct ContentView: View {
    @EnvironmentObject private var broadcastManager: BroadcastManager
    
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
            BroadcastControlView()
                .environmentObject(broadcastManager)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BroadcastManager())
    }
} 
