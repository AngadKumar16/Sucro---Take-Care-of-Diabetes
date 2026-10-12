//
//  ErrorAlert.swift
//  DiabetesCare
//

import SwiftUI

extension View {
    /// Shows `message` in an alert while it's set, and clears it on OK.
    func errorAlert(_ message: Binding<String?>) -> some View {
        alert(
            "Something Went Wrong",
            isPresented: Binding(get: { message.wrappedValue != nil }, set: { if !$0 { message.wrappedValue = nil } }),
            presenting: message.wrappedValue
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { text in
            Text(text)
        }
    }
}
