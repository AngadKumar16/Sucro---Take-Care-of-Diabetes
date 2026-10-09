//
//  DisclaimerView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

struct DisclaimerView: View {
    let onAccept: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Before You Start")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                SafetyNoticeContent()

                Text("You can read this again any time in Help.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onAccept) {
                Text("I Understand")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(Theme.onAccent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(.bar)
        }
    }
}

#Preview("Disclaimer") {
    DisclaimerView {}
}
