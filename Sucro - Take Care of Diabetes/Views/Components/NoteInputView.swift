//
//  NoteInputView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import SwiftUI

struct NoteInputView: View {
    let eventTitle: String
    var onSave: (String) -> Void

    @State private var noteText = ""
    @FocusState private var isFocused: Bool

    private var trimmed: String {
        noteText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        EntryForm(
            title: "Add Note",
            canSave: !trimmed.isEmpty,
            hasChanges: !trimmed.isEmpty,
            onSave: save
        ) {
            Section {
                TextField("Note", text: $noteText, axis: .vertical)
                    .lineLimit(5...12)
                    .focused($isFocused)
            } footer: {
                Text("Added to \(eventTitle).")
            }
        }
        .onAppear { isFocused = true }
    }

    private func save() -> Bool {
        onSave(trimmed)
        return true
    }
}

#Preview {
    NoteInputView(eventTitle: "Lunch") { _ in }
}
