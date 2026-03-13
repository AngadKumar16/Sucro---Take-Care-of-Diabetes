//
//  NoteInputView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  NoteInputView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import SwiftUI

struct NoteInputView: View {
    @Environment(\.dismiss) private var dismiss
    let eventTitle: String
    var onSave: (String) -> Void
    
    @State private var noteText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Note")
                        .font(.headline)
                    Text("For: \(eventTitle)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                
                // Text Editor
                TextEditor(text: $noteText)
                    .focused($isFocused)
                    .padding()
                
                // Character count
                HStack {
                    Spacer()
                    Text("\(noteText.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // Save Button
                Button(action: {
                    onSave(noteText)
                    dismiss()
                }) {
                    Text("Save Note")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(noteText.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(noteText.isEmpty)
                .padding()
            }
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

#Preview {
    NoteInputView(eventTitle: "Lunch - 45g carbs") { note in
        print("Saved note: \(note)")
    }
}