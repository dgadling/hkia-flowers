//
//  FlowerInventory.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import Foundation
import SwiftUI
import Combine

class FlowerInventory: ObservableObject {
    @Published var flowers: [Flower] = []
    
    private let saveKey = "flowerInventory"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadFlowers()
        
        // Save flowers when changes occur
        $flowers
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveFlowers()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Persistence
    
    private func loadFlowers() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            // Load sample data for testing if nothing exists
            if isFirstLaunch() {
                loadSampleData()
            }
            return
        }
        
        do {
            flowers = try JSONDecoder().decode([Flower].self, from: data)
        } catch {
            print("Error loading flowers: \(error)")
        }
    }
    
    private func saveFlowers() {
        do {
            let data = try JSONEncoder().encode(flowers)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Error saving flowers: \(error)")
        }
    }
    
    private func isFirstLaunch() -> Bool {
        let key = "hasLaunchedBefore"
        if UserDefaults.standard.bool(forKey: key) {
            return false
        } else {
            UserDefaults.standard.set(true, forKey: key)
            return true
        }
    }
    
    private func loadSampleData() {
        flowers = [
            Flower(
                species: .rose,
                color: .red,
                pattern: .solid,
                rarity: .common,
                dateObtained: Date(),
                quantity: 3,
                favorite: true
            ),
            Flower(
                species: .tulip,
                color: .yellow,
                pattern: .solid,
                rarity: .common,
                dateObtained: Date().addingTimeInterval(-86400),
                quantity: 2,
                favorite: false
            ),
            Flower(
                species: .lily,
                color: .white,
                pattern: .spotted,
                rarity: .uncommon,
                dateObtained: Date().addingTimeInterval(-172800),
                quantity: 1,
                favorite: true,
                notes: "Found near the waterfall"
            )
        ]
    }
    
    // MARK: - Inventory Management
    
    func addFlower(_ flower: Flower) {
        // Check if we already have this type of flower
        if let index = findMatchingFlowerIndex(flower) {
            // Update quantity of existing flower
            flowers[index].quantity += flower.quantity
        } else {
            // Add new flower
            flowers.append(flower)
        }
    }
    
    func updateFlower(_ flower: Flower) {
        if let index = flowers.firstIndex(where: { $0.id == flower.id }) {
            flowers[index] = flower
        }
    }
    
    func deleteFlower(_ flower: Flower) {
        flowers.removeAll { $0.id == flower.id }
    }
    
    func incrementQuantity(for flower: Flower) {
        if let index = flowers.firstIndex(where: { $0.id == flower.id }) {
            flowers[index].quantity += 1
        }
    }
    
    func decrementQuantity(for flower: Flower) {
        if let index = flowers.firstIndex(where: { $0.id == flower.id }) {
            if flowers[index].quantity > 1 {
                flowers[index].quantity -= 1
            } else {
                // Remove if quantity would be zero
                flowers.remove(at: index)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func findMatchingFlowerIndex(_ flower: Flower) -> Int? {
        return flowers.firstIndex(where: { existingFlower in
            existingFlower.species == flower.species &&
            existingFlower.color == flower.color &&
            existingFlower.pattern == flower.pattern
        })
    }
    
    // MARK: - Filtering and Sorting
    
    func filteredFlowers(by species: FlowerSpecies? = nil, 
                         color: FlowerColor? = nil,
                         pattern: FlowerPattern? = nil,
                         rarity: FlowerRarity? = nil,
                         favoritesOnly: Bool = false,
                         searchText: String = "") -> [Flower] {
        
        return flowers.filter { flower in
            // Apply filters
            let matchesSpecies = species == nil || flower.species == species
            let matchesColor = color == nil || flower.color == color
            let matchesPattern = pattern == nil || flower.pattern == pattern
            let matchesRarity = rarity == nil || flower.rarity == rarity
            let matchesFavorite = !favoritesOnly || flower.favorite
            
            // Apply text search
            let matchesSearch = searchText.isEmpty || 
                flower.displayName.localizedCaseInsensitiveContains(searchText) ||
                (flower.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            return matchesSpecies && matchesColor && matchesPattern && 
                   matchesRarity && matchesFavorite && matchesSearch
        }
    }
    
    enum SortOption {
        case name, species, color, rarity, dateNewest, dateOldest, quantity
    }
    
    func sortedFlowers(_ flowers: [Flower], by option: SortOption) -> [Flower] {
        switch option {
        case .name:
            return flowers.sorted { $0.displayName < $1.displayName }
        case .species:
            return flowers.sorted { $0.species.displayName < $1.species.displayName }
        case .color:
            return flowers.sorted { $0.color.displayName < $1.color.displayName }
        case .rarity:
            return flowers.sorted { $0.rarity.rawValue > $1.rarity.rawValue }
        case .dateNewest:
            return flowers.sorted { $0.dateObtained > $1.dateObtained }
        case .dateOldest:
            return flowers.sorted { $0.dateObtained < $1.dateObtained }
        case .quantity:
            return flowers.sorted { $0.quantity > $1.quantity }
        }
    }
} 