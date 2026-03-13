//
//  Reminder.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation

struct Reminder: Identifiable, Codable {
    let id = UUID()
    let title: String
    let time: Date
    let type: ReminderType
    let isCompleted: Bool
    let notes: String?
    
    init(title: String, time: Date, type: ReminderType, isCompleted: Bool = false, notes: String? = nil) {
        self.title = title
        self.time = time
        self.type = type
        self.isCompleted = isCompleted
        self.notes = notes
    }
    
    var isOverdue: Bool {
        !isCompleted && time < Date()
    }
    
    var timeRemaining: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: time, relativeTo: Date())
    }
}
