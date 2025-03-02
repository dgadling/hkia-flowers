//
//  InventoryView.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI

struct InventoryView: View {
    @EnvironmentObject private var flowerInventory: FlowerInventory
    
    @State private var searchText = ""
    @State private var sortOption: FlowerInventory.SortOption = .name
    @State private var showFilters = false
    @State private var selectedSpecies: FlowerSpecies? = nil
    @State private var selectedColor: FlowerColor? = nil
    @State private var selectedPattern: FlowerPattern? = nil
    @State private var selectedRarity: FlowerRarity? = nil
    @State private var showFavoritesOnly = false
    @State private var showAddFlowerSheet = false
    @State private var selectedFlower: Flower? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter bar
                searchAndFilterBar
                
                // Active filters indicators
                if hasActiveFilters {
                    activeFiltersBar
                }
                
                // Flower list
                flowerList
            }
            .navigationTitle("Flower Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddFlowerSheet = true }) {
                        Label("Add Flower", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Sort by", selection: $sortOption) {
                            Text("Name").tag(FlowerInventory.SortOption.name)
                            Text("Species").tag(FlowerInventory.SortOption.species)
                            Text("Color").tag(FlowerInventory.SortOption.color)
                            Text("Rarity").tag(FlowerInventory.SortOption.rarity)
                            Text("Newest").tag(FlowerInventory.SortOption.dateNewest)
                            Text("Oldest").tag(FlowerInventory.SortOption.dateOldest)
                            Text("Quantity").tag(FlowerInventory.SortOption.quantity)
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView(
                    selectedSpecies: $selectedSpecies,
                    selectedColor: $selectedColor,
                    selectedPattern: $selectedPattern,
                    selectedRarity: $selectedRarity,
                    showFavoritesOnly: $showFavoritesOnly
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showAddFlowerSheet) {
                AddFlowerView(isPresented: $showAddFlowerSheet)
            }
            .sheet(item: $selectedFlower) { flower in
                FlowerDetailView(flower: flower, isPresented: Binding(
                    get: { selectedFlower != nil },
                    set: { if !$0 { selectedFlower = nil } }
                ))
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredAndSortedFlowers: [Flower] {
        let filtered = flowerInventory.filteredFlowers(
            by: selectedSpecies,
            color: selectedColor,
            pattern: selectedPattern,
            rarity: selectedRarity,
            favoritesOnly: showFavoritesOnly,
            searchText: searchText
        )
        
        return flowerInventory.sortedFlowers(filtered, by: sortOption)
    }
    
    private var hasActiveFilters: Bool {
        selectedSpecies != nil || 
        selectedColor != nil || 
        selectedPattern != nil || 
        selectedRarity != nil || 
        showFavoritesOnly
    }
    
    // MARK: - View Components
    
    private var searchAndFilterBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search flowers", text: $searchText)
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
            
            Button(action: {
                showFilters = true
            }) {
                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .foregroundColor(hasActiveFilters ? .blue : .primary)
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if let species = selectedSpecies {
                    filterPill(species.displayName, icon: species.icon) {
                        selectedSpecies = nil
                    }
                }
                
                if let color = selectedColor {
                    filterPill(color.displayName, colorDot: color.color) {
                        selectedColor = nil
                    }
                }
                
                if let pattern = selectedPattern {
                    filterPill(pattern.displayName) {
                        selectedPattern = nil
                    }
                }
                
                if let rarity = selectedRarity {
                    filterPill(rarity.displayName, colorDot: rarity.color) {
                        selectedRarity = nil
                    }
                }
                
                if showFavoritesOnly {
                    filterPill("Favorites", icon: "heart.fill") {
                        showFavoritesOnly = false
                    }
                }
                
                if hasActiveFilters {
                    Button("Clear All") {
                        clearAllFilters()
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private func filterPill(_ text: String, icon: String? = nil, colorDot: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Text(icon)
                        .font(.caption)
                }
                
                if let color = colorDot {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                
                Text(text)
                    .font(.caption)
                
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(15)
        }
    }
    
    private var flowerList: some View {
        Group {
            if filteredAndSortedFlowers.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredAndSortedFlowers) { flower in
                        FlowerRow(flower: flower)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFlower = flower
                            }
                            .contextMenu {
                                FlowerContextMenu(flower: flower)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    flowerInventory.deleteFlower(flower)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    if var updatedFlower = flowerInventory.flowers.first(where: { $0.id == flower.id }) {
                                        updatedFlower.favorite.toggle()
                                        flowerInventory.updateFlower(updatedFlower)
                                    }
                                } label: {
                                    Label(flower.favorite ? "Unfavorite" : "Favorite", 
                                          systemImage: flower.favorite ? "heart.slash" : "heart")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    flowerInventory.incrementQuantity(for: flower)
                                } label: {
                                    Label("Add", systemImage: "plus")
                                }
                                .tint(.green)
                                
                                Button {
                                    flowerInventory.decrementQuantity(for: flower)
                                } label: {
                                    Label("Remove", systemImage: "minus")
                                }
                                .tint(.orange)
                            }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(hasActiveFilters || !searchText.isEmpty ? 
                 "No flowers match your filters" :
                 "Your flower collection is empty")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if hasActiveFilters || !searchText.isEmpty {
                Button("Clear Filters") {
                    clearAllFilters()
                    searchText = ""
                }
                .buttonStyle(.bordered)
            } else {
                Button("Add Your First Flower") {
                    showAddFlowerSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding(.top, 60)
    }
    
    private func clearAllFilters() {
        selectedSpecies = nil
        selectedColor = nil
        selectedPattern = nil
        selectedRarity = nil
        showFavoritesOnly = false
    }
}

// MARK: - Supporting Views

struct FlowerRow: View {
    let flower: Flower
    
    var body: some View {
        HStack {
            // Flower icon and color indicator
            ZStack {
                Circle()
                    .fill(flower.color.color)
                    .frame(width: 36, height: 36)
                
                Text(flower.species.icon)
                    .font(.title3)
            }
            
            // Flower details
            VStack(alignment: .leading) {
                HStack {
                    Text(flower.displayName)
                        .font(.headline)
                    
                    if flower.favorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Text(flower.rarity.displayName)
                    .font(.caption)
                    .foregroundColor(flower.rarity.color)
            }
            
            Spacer()
            
            // Quantity
            Text("x\(flower.quantity)")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(15)
        }
        .padding(.vertical, 4)
    }
}

struct FlowerContextMenu: View {
    @EnvironmentObject private var flowerInventory: FlowerInventory
    let flower: Flower
    
    var body: some View {
        Button {
            if var updatedFlower = flowerInventory.flowers.first(where: { $0.id == flower.id }) {
                updatedFlower.favorite.toggle()
                flowerInventory.updateFlower(updatedFlower)
            }
        } label: {
            Label(flower.favorite ? "Remove from Favorites" : "Add to Favorites", 
                  systemImage: flower.favorite ? "heart.slash" : "heart")
        }
        
        Button {
            flowerInventory.incrementQuantity(for: flower)
        } label: {
            Label("Increase Quantity", systemImage: "plus.circle")
        }
        
        Button {
            flowerInventory.decrementQuantity(for: flower)
        } label: {
            Label("Decrease Quantity", systemImage: "minus.circle")
        }
        
        Divider()
        
        Button(role: .destructive) {
            flowerInventory.deleteFlower(flower)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

struct FilterView: View {
    @Binding var selectedSpecies: FlowerSpecies?
    @Binding var selectedColor: FlowerColor?
    @Binding var selectedPattern: FlowerPattern?
    @Binding var selectedRarity: FlowerRarity?
    @Binding var showFavoritesOnly: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Species")) {
                    Picker("Species", selection: $selectedSpecies) {
                        Text("Any").tag(FlowerSpecies?.none)
                        ForEach(FlowerSpecies.allCases) { species in
                            Text("\(species.icon) \(species.displayName)").tag(FlowerSpecies?.some(species))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Color")) {
                    Picker("Color", selection: $selectedColor) {
                        Text("Any").tag(FlowerColor?.none)
                        ForEach(FlowerColor.allCases) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 10, height: 10)
                                Text(color.displayName)
                            }
                            .tag(FlowerColor?.some(color))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Pattern")) {
                    Picker("Pattern", selection: $selectedPattern) {
                        Text("Any").tag(FlowerPattern?.none)
                        ForEach(FlowerPattern.allCases) { pattern in
                            Text(pattern.displayName).tag(FlowerPattern?.some(pattern))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Rarity")) {
                    Picker("Rarity", selection: $selectedRarity) {
                        Text("Any").tag(FlowerRarity?.none)
                        ForEach(FlowerRarity.allCases) { rarity in
                            Text(rarity.displayName)
                                .foregroundColor(rarity.color)
                                .tag(FlowerRarity?.some(rarity))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Toggle("Show Favorites Only", isOn: $showFavoritesOnly)
                }
                
                Section {
                    Button("Reset Filters") {
                        selectedSpecies = nil
                        selectedColor = nil
                        selectedPattern = nil
                        selectedRarity = nil
                        showFavoritesOnly = false
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filter Flowers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InventoryView_Previews: PreviewProvider {
    static var previews: some View {
        InventoryView()
            .environmentObject(FlowerInventory())
    }
} 