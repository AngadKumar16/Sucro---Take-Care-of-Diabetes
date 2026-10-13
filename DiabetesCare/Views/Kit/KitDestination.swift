//
//  KitDestination.swift
//  DiabetesCare
//
//  The everyday screens reachable from Settings and Today: supplies,
//  doctor visit questions, the school card and the weekly recap.
//

import SwiftUI

enum KitDestination: Hashable {
    case supplies
    case doctorQuestions
    case schoolCard
    case weeklyRecap
    case appIcon
}

extension View {
    /// Registers the everyday screens. Apply once per navigation stack.
    func kitDestinations() -> some View {
        navigationDestination(for: KitDestination.self) { destination in
            switch destination {
            case .supplies: SuppliesView()
            case .doctorQuestions: DoctorQuestionsView()
            case .schoolCard: SchoolCardView()
            case .weeklyRecap: WeeklyRecapView()
            case .appIcon: AppIconPicker()
            }
        }
    }
}

/// Links to the everyday screens, as a Settings section.
struct EverydaySection: View {
    @State private var kit = KitStore.shared

    var body: some View {
        Section("Everyday") {
            NavigationLink(value: KitDestination.weeklyRecap) {
                Label("Your Week", systemImage: "calendar")
            }
            NavigationLink(value: KitDestination.supplies) {
                LabeledContent {
                    if !kit.lowSupplies.isEmpty {
                        Text("\(kit.lowSupplies.count) low")
                            .foregroundStyle(Theme.amber)
                    }
                } label: {
                    Label("Supplies", systemImage: "shippingbox")
                }
            }
            NavigationLink(value: KitDestination.doctorQuestions) {
                LabeledContent {
                    if !kit.openQuestions.isEmpty {
                        Text("\(kit.openQuestions.count)")
                    }
                } label: {
                    Label("Doctor Visit Questions", systemImage: "stethoscope")
                }
            }
            NavigationLink(value: KitDestination.schoolCard) {
                Label("School & Sitter Card", systemImage: "person.text.rectangle")
            }
            NavigationLink(value: KitDestination.appIcon) {
                Label("App Icon", systemImage: "app.badge")
            }
        }
        .listRowBackground(Theme.card)
    }
}
