//
//  FlowerLabellerApp.swift
//  FlowerLabeller
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI

@main
struct FlowerLabellerApp: App {
    @StateObject private var keyboardHandler = KeyboardHandler()
    
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
                }
        }
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
