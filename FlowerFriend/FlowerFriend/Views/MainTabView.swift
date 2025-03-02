//
//  MainTabView.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var broadcastService: BroadcastService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Screen Recording Tab
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "camera")
                }
                .tag(0)
            
            // Inventory Tab
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "list.bullet")
                }
                .tag(1)
            
            // Progress Tab
            FlowerProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            // Planning Tab
            PlanningView()
                .tabItem {
                    Label("Planning", systemImage: "lightbulb")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .overlay(
            // Show recording indicator when active
            Group {
                if broadcastService.status == .active || broadcastService.status == .paused {
                    recordingIndicator
                }
            }
        )
    }
    
    // Recording indicator that appears when recording is active
    private var recordingIndicator: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(broadcastService.status == .active ? .red : .yellow)
                            .frame(width: 8, height: 8)
                        
                        Text(broadcastService.status.displayText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                }
                .padding(.trailing, 8)
                .padding(.top, 4)
            }
            
            Spacer()
        }
    }
} 