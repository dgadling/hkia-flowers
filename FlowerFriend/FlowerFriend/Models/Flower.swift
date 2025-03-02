//
//  Flower.swift
//  FlowerFriend
//
//  Created by David Gadling on 3/2/25.
//

import Foundation
import SwiftUI

enum FlowerSpecies: String, CaseIterable, Codable, Identifiable {
    case rose
    case tulip
    case lily
    case daisy
    case sunflower
    case orchid
    // Add more species as needed
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .rose: return "Rose"
        case .tulip: return "Tulip"
        case .lily: return "Lily"
        case .daisy: return "Daisy"
        case .sunflower: return "Sunflower"
        case .orchid: return "Orchid"
        }
    }
    
    var icon: String {
        switch self {
        case .rose: return "🌹"
        case .tulip: return "🌷"
        case .lily: return "⚜️"
        case .daisy: return "🌼"
        case .sunflower: return "🌻"
        case .orchid: return "🪷"
        }
    }
}

enum FlowerColor: String, CaseIterable, Codable, Identifiable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case pink
    case white
    case black
    case mixed
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .white: return "White"
        case .black: return "Black"
        case .mixed: return "Mixed"
        }
    }
    
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .white: return .white
        case .black: return .black
        case .mixed: return .purple.opacity(0.5)
        }
    }
}

enum FlowerPattern: String, CaseIterable, Codable, Identifiable {
    case solid
    case striped
    case spotted
    case multicolor
    case gradient
    // Add more patterns as needed
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .solid: return "Solid"
        case .striped: return "Striped"
        case .spotted: return "Spotted"
        case .multicolor: return "Multicolor"
        case .gradient: return "Gradient"
        }
    }
}

enum FlowerRarity: String, CaseIterable, Codable, Identifiable {
    case common
    case uncommon
    case rare
    case legendary
    case mythical
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .legendary: return .purple
        case .mythical: return .orange
        }
    }
}

struct Flower: Identifiable, Codable {
    var id = UUID()
    var species: FlowerSpecies
    var color: FlowerColor
    var pattern: FlowerPattern
    var rarity: FlowerRarity
    var dateObtained: Date
    var quantity: Int
    var favorite: Bool
    var notes: String?
    
    // Used for ML detection confidence
    var detectionConfidence: Float?
    
    var displayName: String {
        "\(color.displayName) \(pattern == .solid ? "" : "\(pattern.displayName) ")\(species.displayName)"
    }
    
    static var example: Flower {
        Flower(
            species: .rose,
            color: .red,
            pattern: .solid,
            rarity: .common,
            dateObtained: Date(),
            quantity: 1,
            favorite: false
        )
    }
} 