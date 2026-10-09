//
//  InsulinOnBoardLabel.swift
//  Sucro - Take Care of Diabetes
//
//  "x U active (estimate)" under the glucose on Today.
//

import SwiftUI

struct InsulinOnBoardLabel: View {
    let units: Double

    var body: some View {
        Label {
            Text("\(units, format: .number.precision(.fractionLength(1))) U active (estimate)")
        } icon: {
            Image(systemName: "syringe")
        }
        .font(Theme.readout(.caption))
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Estimated insulin on board: \(units, format: .number.precision(.fractionLength(1))) units")
    }
}

#Preview {
    InsulinOnBoardLabel(units: 2.5)
}
