//
//  ProgressView.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI

struct FlowerProgressView: View {
    @EnvironmentObject private var flowerInventory: FlowerInventory
    
    var body: some View {
        NavigationView {
            List {
                // Progress summary section
                Section(header: Text("Collection Summary")) {
                    ProgressSummaryCard(flowerInventory: flowerInventory)
                }
                
                // Flower types progress
                Section(header: Text("Species Collection")) {
                    ForEach(FlowerSpecies.allCases) { species in
                        speciesProgressRow(species)
                    }
                }
                
                // Color varieties progress
                Section(header: Text("Color Collection")) {
                    ForEach(FlowerColor.allCases) { color in
                        colorProgressRow(color)
                    }
                }
                
                // Rarity progress
                Section(header: Text("Rarity Collection")) {
                    ForEach(FlowerRarity.allCases) { rarity in
                        rarityProgressRow(rarity)
                    }
                }
                
                // Placeholder for achievements
                Section(header: Text("Achievements")) {
                    placeholderAchievementRow("Flower Enthusiast", description: "Collect 10 different flowers", progress: 0.7)
                    placeholderAchievementRow("Color Expert", description: "Collect flowers in all colors", progress: 0.4)
                    placeholderAchievementRow("Rare Collector", description: "Find a legendary flower", progress: 0.0)
                }
            }
            .navigationTitle("Progress")
        }
    }
    
    // MARK: - Helper Views
    
    private func speciesProgressRow(_ species: FlowerSpecies) -> some View {
        let count = flowerInventory.flowers.filter { $0.species == species }.count
        
        return HStack {
            Text(species.icon)
                .font(.title3)
            
            Text(species.displayName)
            
            Spacer()
            
            Text("\(count)")
                .foregroundColor(.secondary)
        }
    }
    
    private func colorProgressRow(_ color: FlowerColor) -> some View {
        let count = flowerInventory.flowers.filter { $0.color == color }.count
        
        return HStack {
            Circle()
                .fill(color.color)
                .frame(width: 16, height: 16)
            
            Text(color.displayName)
            
            Spacer()
            
            Text("\(count)")
                .foregroundColor(.secondary)
        }
    }
    
    private func rarityProgressRow(_ rarity: FlowerRarity) -> some View {
        let count = flowerInventory.flowers.filter { $0.rarity == rarity }.count
        
        return HStack {
            Text(rarity.displayName)
                .foregroundColor(rarity.color)
            
            Spacer()
            
            Text("\(count)")
                .foregroundColor(.secondary)
        }
    }
    
    private func placeholderAchievementRow(_ title: String, description: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: progress >= 1.0 ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(progress >= 1.0 ? .green : .gray)
                
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            SwiftUI.ProgressView(value: progress)
                .tint(progress >= 1.0 ? .green : .blue)
            
            Text("\(Int(progress * 100))% complete")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ProgressSummaryCard: View {
    let flowerInventory: FlowerInventory
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                VStack {
                    Text("\(flowerInventory.flowers.count)")
                        .font(.system(size: 32, weight: .bold))
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(uniqueSpeciesCount)")
                        .font(.system(size: 32, weight: .bold))
                    Text("Species")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(uniqueColorCount)")
                        .font(.system(size: 32, weight: .bold))
                    Text("Colors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(totalQuantity)")
                        .font(.system(size: 32, weight: .bold))
                    Text("Quantity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Collection progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Collection Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(collectionProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                SwiftUI.ProgressView(value: collectionProgress)
                    .tint(.green)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // Computed properties for stats
    private var uniqueSpeciesCount: Int {
        Set(flowerInventory.flowers.map { $0.species }).count
    }
    
    private var uniqueColorCount: Int {
        Set(flowerInventory.flowers.map { $0.color }).count
    }
    
    private var totalQuantity: Int {
        flowerInventory.flowers.reduce(0) { $0 + $1.quantity }
    }
    
    // Total progress is a placeholder calculation - this would be customized later
    private var collectionProgress: Double {
        let totalPossibleSpecies = FlowerSpecies.allCases.count
        let totalPossibleColors = FlowerColor.allCases.count
        
        let speciesRatio = Double(uniqueSpeciesCount) / Double(totalPossibleSpecies)
        let colorRatio = Double(uniqueColorCount) / Double(totalPossibleColors)
        
        return (speciesRatio + colorRatio) / 2
    }
}

struct FlowerProgressView_Previews: PreviewProvider {
    static var previews: some View {
        FlowerProgressView()
            .environmentObject(FlowerInventory())
    }
} 