//
//  BolusPreset.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


import Foundation

struct BolusPreset: Identifiable, Codable {
    let id = UUID()
    var name: String
    var units: Double
    var carbs: Double?
    var notes: String?
    var isFavorite: Bool
    var createdAt: Date
    
    init(name: String, units: Double, carbs: Double? = nil, notes: String? = nil, isFavorite: Bool = false) {
        self.name = name
        self.units = units
        self.carbs = carbs
        self.notes = notes
        self.isFavorite = isFavorite
        self.createdAt = Date()
    }
}
