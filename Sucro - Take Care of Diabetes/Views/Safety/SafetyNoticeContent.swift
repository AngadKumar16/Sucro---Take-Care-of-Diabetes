//
//  SafetyNoticeContent.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// What the app is and isn't. Shown once before first use and again from
/// Help whenever the user wants to reread it.
struct SafetyNoticeContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SafetyPoint(
                icon: "cross.case",
                text: "This app helps you log and review your diabetes data. It is not a medical device and hasn't been reviewed by any health authority."
            )
            SafetyPoint(
                icon: "syringe",
                text: "Don't use it to decide how much insulin to take. The insulin on board figure is a rough estimate."
            )
            SafetyPoint(
                icon: "bell.slash",
                text: "Alerts can arrive late or not at all. Keep the alerts on your CGM, pump or meter switched on."
            )
            SafetyPoint(
                icon: "stethoscope",
                text: "Talk to your care team before changing your treatment."
            )
            SafetyPoint(
                icon: "phone",
                text: "In an emergency, call your local emergency number."
            )
        }
    }
}
