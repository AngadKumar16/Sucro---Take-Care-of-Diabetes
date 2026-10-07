//
//  Reminder.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import Foundation

struct Reminder: Identifiable, Equatable {
    /// Stable for a given occurrence (for example the site change due after
    /// a specific change), and also the notification identifier.
    let id: String
    let title: String
    let time: Date
    let type: ReminderType
    let notes: String?

    init(id: String = "reminder.\(UUID().uuidString)", title: String, time: Date, type: ReminderType, notes: String? = nil) {
        self.id = id
        self.title = title
        self.time = time
        self.type = type
        self.notes = notes
    }
}
