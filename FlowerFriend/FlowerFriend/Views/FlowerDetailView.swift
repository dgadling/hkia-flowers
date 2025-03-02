//
//  FlowerDetailView.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import SwiftUI

struct FlowerDetailView: View {
    @EnvironmentObject private var flowerInventory: FlowerInventory
    @Environment(\.dismiss) private var dismiss
    
    @State private var flower: Flower
    @Binding private var isPresented: Bool
    
    @State private var isEditing = false
    @State private var notes: String
    
    init(flower: Flower, isPresented: Binding<Bool>) {
        _flower = State(initialValue: flower)
        _isPresented = isPresented
        _notes = State(initialValue: flower.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                // General info section
                Section {
                    HStack {
                        Text("Species")
                        Spacer()
                        if isEditing {
                            Picker("Species", selection: $flower.species) {
                                ForEach(FlowerSpecies.allCases) { species in
                                    Text("\(species.icon) \(species.displayName)").tag(species)
                                }
                            }
                            .pickerStyle(.menu)
                        } else {
                            Text("\(flower.species.icon) \(flower.species.displayName)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        if isEditing {
                            Picker("Color", selection: $flower.color) {
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
                        } else {
                            HStack {
                                Circle()
                                    .fill(flower.color.color)
                                    .frame(width: 12, height: 12)
                                Text(flower.color.displayName)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Pattern")
                        Spacer()
                        if isEditing {
                            Picker("Pattern", selection: $flower.pattern) {
                                ForEach(FlowerPattern.allCases) { pattern in
                                    Text(pattern.displayName).tag(pattern)
                                }
                            }
                            .pickerStyle(.menu)
                        } else {
                            Text(flower.pattern.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Rarity")
                        Spacer()
                        if isEditing {
                            Picker("Rarity", selection: $flower.rarity) {
                                ForEach(FlowerRarity.allCases) { rarity in
                                    Text(rarity.displayName)
                                        .foregroundColor(rarity.color)
                                        .tag(rarity)
                                }
                            }
                            .pickerStyle(.menu)
                        } else {
                            Text(flower.rarity.displayName)
                                .foregroundColor(flower.rarity.color)
                        }
                    }
                }
                
                // Inventory section
                Section(header: Text("Inventory")) {
                    HStack {
                        Text("Quantity")
                        Spacer()
                        if isEditing {
                            Stepper("\(flower.quantity)", value: $flower.quantity, in: 1...999)
                        } else {
                            Text("\(flower.quantity)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Date Obtained")
                        Spacer()
                        if isEditing {
                            DatePicker("", selection: $flower.dateObtained, displayedComponents: .date)
                        } else {
                            Text(dateFormatter.string(from: flower.dateObtained))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle("Favorite", isOn: $flower.favorite)
                }
                
                // Notes section
                Section(header: Text("Notes")) {
                    if isEditing {
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                    } else if let flowerNotes = flower.notes, !flowerNotes.isEmpty {
                        Text(flowerNotes)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No notes")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                // Detection confidence (if available)
                if let confidence = flower.detectionConfidence {
                    Section(header: Text("Detection")) {
                        HStack {
                            Text("Confidence")
                            Spacer()
                            Text("\(Int(confidence * 100))%")
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: confidence)
                            .tint(confidence > 0.9 ? .green : 
                                  confidence > 0.75 ? .yellow : .orange)
                    }
                }
                
                // Delete section
                if isEditing {
                    Section {
                        Button("Delete Flower") {
                            flowerInventory.deleteFlower(flower)
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(flower.displayName)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Cancel" : "Close") {
                        if isEditing {
                            // Revert changes
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            // Save changes
                            flower.notes = notes.isEmpty ? nil : notes
                            flowerInventory.updateFlower(flower)
                            isEditing = false
                        } else {
                            isEditing = true
                        }
                    }
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

struct FlowerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FlowerDetailView(
            flower: .example,
            isPresented: .constant(true)
        )
        .environmentObject(FlowerInventory())
    }
} 