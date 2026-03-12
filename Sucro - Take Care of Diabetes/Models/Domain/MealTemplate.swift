//
//  MealTemplate.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//
//

import Foundation

struct MealTemplate: Identifiable, Codable {
    let id = UUID()
    var name: String
    var carbs: Double
    var protein: Double?
    var fat: Double?
    var fiber: Double?
    var typicalBolus: Double?
    var notes: String?
    var isFavorite: Bool
    var photoData: Data?
    var createdAt: Date
    
    init(name: String, carbs: Double, protein: Double? = nil, fat: Double? = nil,
         fiber: Double? = nil, typicalBolus: Double? = nil, notes: String? = nil,
         isFavorite: Bool = false, photoData: Data? = nil) {
        self.name = name
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.fiber = fiber
        self.typicalBolus = typicalBolus
        self.notes = notes
        self.isFavorite = isFavorite
        self.photoData = photoData
        self.createdAt = Date()
    }
}
