//
//  SafetyNoticeContent.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// What the app is and isn't. Shown once before first use and again from
/// Help whenever the user wants to reread it.
struct SafetyNoticeContent: View {
    /// Rows slide in one after another the first time they appear.
    var staggered = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    private static let points: [(icon: String, text: String)] = [
        ("cross.case", "This app helps you log and review your diabetes data. It is not a medical device and hasn't been reviewed by any health authority."),
        ("syringe", "Don't use it to decide how much insulin to take. The insulin on board figure is a rough estimate."),
        ("bell.slash", "Alerts can arrive late or not at all. Keep the alerts on your CGM, pump or meter switched on."),
        ("stethoscope", "Talk to your care team before changing your treatment."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Self.points.enumerated()), id: \.offset) { index, point in
                SafetyPoint(number: index + 1, icon: point.icon, text: point.text)
                    .modifier(Entrance(index: index, shown: shown || !staggered, animated: !reduceMotion))
            }
            SafetyEmergencyPoint(text: "In an emergency, call your local emergency number.")
                .padding(.top, 20)
                .modifier(Entrance(index: Self.points.count, shown: shown || !staggered, animated: !reduceMotion))
        }
        .onAppear {
            guard staggered, !shown else { return }
            shown = true
        }
    }

    private struct Entrance: ViewModifier {
        let index: Int
        let shown: Bool
        let animated: Bool

        func body(content: Content) -> some View {
            content
                .opacity(shown ? 1 : 0)
                .offset(y: shown ? 0 : 12)
                .animation(animated ? .smooth(duration: 0.5).delay(0.35 + Double(index) * 0.07) : nil, value: shown)
        }
    }
}
