//
//  ContentView.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI

// ContentView now just a wrapper around MainTabView
struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environmentObject(FlowerInventory())
        .environmentObject(BroadcastService())
}
