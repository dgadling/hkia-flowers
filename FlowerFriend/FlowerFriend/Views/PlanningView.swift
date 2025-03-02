//
//  PlanningView.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI

struct PlanningView: View {
    @EnvironmentObject private var flowerInventory: FlowerInventory
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                searchBar
                
                // Tab selector
                Picker("View Mode", selection: $selectedTab) {
                    Text("Available").tag(0)
                    Text("All Recipes").tag(1)
                    Text("Wishlist").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab content
                TabView(selection: $selectedTab) {
                    // Available breeding recipes
                    availableRecipesView
                        .tag(0)
                    
                    // All recipes
                    allRecipesView
                        .tag(1)
                    
                    // Wishlist
                    wishlistView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Flower Planning")
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search recipes", text: $searchText)
                .autocapitalization(.none)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Tab Views
    
    private var availableRecipesView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Recipes you can create with your current flowers")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Placeholder recipes
                Group {
                    sampleRecipeCard(
                        resultFlower: makeFlower(species: .rose, color: .pink),
                        parentA: makeFlower(species: .rose, color: .red),
                        parentB: makeFlower(species: .rose, color: .white),
                        chance: 0.8,
                        available: true
                    )
                    
                    sampleRecipeCard(
                        resultFlower: makeFlower(species: .tulip, color: .purple),
                        parentA: makeFlower(species: .tulip, color: .blue),
                        parentB: makeFlower(species: .tulip, color: .red),
                        chance: 0.6,
                        available: true
                    )
                    
                    sampleRecipeCard(
                        resultFlower: makeFlower(species: .lily, color: .orange, pattern: .spotted),
                        parentA: makeFlower(species: .lily, color: .yellow),
                        parentB: makeFlower(species: .lily, color: .red, pattern: .spotted),
                        chance: 0.4,
                        available: true
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private var allRecipesView: some View {
        List {
            Section(header: Text("Roses")) {
                sampleRecipeRow(
                    resultFlower: makeFlower(species: .rose, color: .pink),
                    parentA: makeFlower(species: .rose, color: .red),
                    parentB: makeFlower(species: .rose, color: .white),
                    chance: 0.8,
                    available: true
                )
                
                sampleRecipeRow(
                    resultFlower: makeFlower(species: .rose, color: .black),
                    parentA: makeFlower(species: .rose, color: .red),
                    parentB: makeFlower(species: .rose, color: .purple),
                    chance: 0.2,
                    available: false
                )
            }
            
            Section(header: Text("Tulips")) {
                sampleRecipeRow(
                    resultFlower: makeFlower(species: .tulip, color: .purple),
                    parentA: makeFlower(species: .tulip, color: .blue),
                    parentB: makeFlower(species: .tulip, color: .red),
                    chance: 0.6,
                    available: true
                )
                
                sampleRecipeRow(
                    resultFlower: makeFlower(species: .tulip, color: .green, pattern: .striped),
                    parentA: makeFlower(species: .tulip, color: .green),
                    parentB: makeFlower(species: .tulip, color: .yellow, pattern: .striped),
                    chance: 0.3,
                    available: false
                )
            }
        }
    }
    
    private var wishlistView: some View {
        List {
            Section(header: Text("Your Wishlist")) {
                if false { // In the future, this would be populated from a real wishlist
                    Text("No flowers in your wishlist")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    sampleWishlistRow(makeFlower(species: .orchid, color: .blue, rarity: .legendary))
                    sampleWishlistRow(makeFlower(species: .sunflower, color: .red, pattern: .striped, rarity: .rare))
                    sampleWishlistRow(makeFlower(species: .rose, color: .black, rarity: .rare))
                }
            }
            
            Section(header: Text("Suggested Rare Flowers")) {
                sampleWishlistRow(makeFlower(species: .lily, color: .purple, pattern: .gradient, rarity: .mythical))
                sampleWishlistRow(makeFlower(species: .daisy, color: .green, rarity: .legendary))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func makeFlower(species: FlowerSpecies, color: FlowerColor, pattern: FlowerPattern = .solid, rarity: FlowerRarity = .common) -> Flower {
        Flower(
            species: species,
            color: color,
            pattern: pattern,
            rarity: rarity,
            dateObtained: Date(),
            quantity: 1,
            favorite: false
        )
    }
    
    private func sampleRecipeCard(resultFlower: Flower, parentA: Flower, parentB: Flower, chance: Double, available: Bool) -> some View {
        VStack(spacing: 12) {
            // Result flower
            HStack {
                ZStack {
                    Circle()
                        .fill(resultFlower.color.color)
                        .frame(width: 40, height: 40)
                    
                    Text(resultFlower.species.icon)
                        .font(.title2)
                }
                
                VStack(alignment: .leading) {
                    Text(resultFlower.displayName)
                        .font(.headline)
                    
                    Text(resultFlower.rarity.displayName)
                        .font(.caption)
                        .foregroundColor(resultFlower.rarity.color)
                }
                
                Spacer()
                
                Text("\(Int(chance * 100))%")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Divider()
            
            // Parent flowers
            HStack {
                flowerRecipeParent(flower: parentA)
                
                Image(systemName: "plus")
                    .foregroundColor(.secondary)
                
                flowerRecipeParent(flower: parentB)
                
                Spacer()
                
                // Availability badge
                if available {
                    Label("Available", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("Missing", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func sampleRecipeRow(resultFlower: Flower, parentA: Flower, parentB: Flower, chance: Double, available: Bool) -> some View {
        VStack(spacing: 8) {
            // Result flower
            HStack {
                ZStack {
                    Circle()
                        .fill(resultFlower.color.color)
                        .frame(width: 24, height: 24)
                    
                    Text(resultFlower.species.icon)
                        .font(.caption)
                }
                
                Text(resultFlower.displayName)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(Int(chance * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Parent flowers
            HStack {
                flowerRecipeParentSmall(flower: parentA)
                
                Text("+")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                flowerRecipeParentSmall(flower: parentB)
                
                Spacer()
                
                // Availability badge
                if available {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .font(.caption)
        }
    }
    
    private func sampleWishlistRow(_ flower: Flower) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(flower.color.color)
                    .frame(width: 32, height: 32)
                
                Text(flower.species.icon)
                    .font(.subheadline)
            }
            
            VStack(alignment: .leading) {
                Text(flower.displayName)
                    .font(.headline)
                
                Text(flower.rarity.displayName)
                    .font(.caption)
                    .foregroundColor(flower.rarity.color)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
    }
    
    private func flowerRecipeParent(flower: Flower) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(flower.color.color)
                    .frame(width: 24, height: 24)
                
                Text(flower.species.icon)
                    .font(.caption)
            }
            
            Text(flower.displayName)
                .font(.callout)
        }
    }
    
    private func flowerRecipeParentSmall(flower: Flower) -> some View {
        HStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(flower.color.color)
                    .frame(width: 12, height: 12)
                
                Text(flower.species.icon)
                    .font(.system(size: 8))
            }
            
            Text(flower.displayName)
                .font(.caption2)
        }
    }
}

struct PlanningView_Previews: PreviewProvider {
    static var previews: some View {
        PlanningView()
            .environmentObject(FlowerInventory())
    }
} 