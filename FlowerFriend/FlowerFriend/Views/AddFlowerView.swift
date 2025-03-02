//
//  AddFlowerView.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI

struct AddFlowerView: View {
    @EnvironmentObject private var flowerInventory: FlowerInventory
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isPresented: Bool
    
    @State private var species: FlowerSpecies = .rose
    @State private var color: FlowerColor = .red
    @State private var pattern: FlowerPattern = .solid
    @State private var rarity: FlowerRarity = .common
    @State private var quantity: Int = 1
    @State private var isFavorite: Bool = false
    @State private var notes: String = ""
    @State private var date: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                // Flower properties
                Section(header: Text("Flower Type")) {
                    Picker("Species", selection: $species) {
                        ForEach(FlowerSpecies.allCases) { species in
                            Text("\(species.icon) \(species.displayName)").tag(species)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Color", selection: $color) {
                        ForEach(FlowerColor.allCases) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 12, height: 12)
                                Text(color.displayName)
                            }
                            .tag(color)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Pattern", selection: $pattern) {
                        ForEach(FlowerPattern.allCases) { pattern in
                            Text(pattern.displayName).tag(pattern)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Rarity", selection: $rarity) {
                        ForEach(FlowerRarity.allCases) { rarity in
                            Text(rarity.displayName)
                                .foregroundColor(rarity.color)
                                .tag(rarity)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Inventory details
                Section(header: Text("Inventory Details")) {
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                    
                    DatePicker("Date Obtained", selection: $date, displayedComponents: .date)
                    
                    Toggle("Favorite", isOn: $isFavorite)
                }
                
                // Notes
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                // Preview
                Section(header: Text("Preview")) {
                    FlowerRow(flower: previewFlower)
                }
            }
            .navigationTitle("Add Flower")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addFlower()
                    }
                }
            }
        }
    }
    
    private var previewFlower: Flower {
        Flower(
            species: species,
            color: color,
            pattern: pattern,
            rarity: rarity,
            dateObtained: date,
            quantity: quantity,
            favorite: isFavorite,
            notes: notes.isEmpty ? nil : notes
        )
    }
    
    private func addFlower() {
        flowerInventory.addFlower(previewFlower)
        dismiss()
    }
}

struct AddFlowerView_Previews: PreviewProvider {
    static var previews: some View {
        AddFlowerView(isPresented: .constant(true))
            .environmentObject(FlowerInventory())
    }
} 