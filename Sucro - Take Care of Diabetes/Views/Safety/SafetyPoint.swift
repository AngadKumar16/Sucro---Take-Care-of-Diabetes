//
//  SafetyPoint.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// One line of the safety notice: an icon and a sentence.
struct SafetyPoint: View {
    let icon: String
    let text: String

    var body: some View {
        Label {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.tint)
        }
    }
}
