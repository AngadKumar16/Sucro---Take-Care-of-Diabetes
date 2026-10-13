//
//  LearnView.swift
//  DiabetesCare
//
//  The Learn tab: a searchable diabetes glossary, by topic and A–Z.
//

import SwiftUI
import TipKit

struct LearnView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var query = ""

    private let glossary = Glossary.shared

    private var results: [GlossaryTerm] {
        glossary.search(query)
    }

    private var savedTerms: [GlossaryTerm] {
        settings.savedGlossaryTermIDs.compactMap(glossary.term)
    }

    var body: some View {
        List {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                browseSections
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(results) { term in
                        GlossaryTermRow(term: term, showsCategory: true)
                    }
                } header: {
                    Text("\(results.count) \(results.count == 1 ? "Term" : "Terms")")
                }
                .listRowBackground(Theme.card)
            }
        }
        .listStyle(.insetGrouped)
        .instrumentBackground()
        .navigationTitle("Learn")
        .searchable(text: $query, prompt: "Search \(glossary.terms.count) terms")
        .glossaryDestinations()
        .growthDestinations()
    }

    @ViewBuilder
    private var browseSections: some View {
        if settings.appRole == .selfCare {
            Section {
                TipView(YourPathTip())
                NavigationLink(value: GrowthDestination.path) {
                    LabeledContent {
                        Text("\(settings.completedSkills.count) of \(Skill.allCases.count)")
                            .monospacedDigit()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your Path")
                                Text("\(settings.stage.title) stage · skills that open new features")
                                    .font(.caption)
                                    .foregroundStyle(Theme.soft)
                            }
                        } icon: {
                            Image(systemName: settings.stage.symbol)
                                .foregroundStyle(Theme.green)
                        }
                    }
                }
                .accessibilityIdentifier("learnYourPath")
            }
            .listRowBackground(Theme.card)
        }

        Section("Guides") {
            GuideCarousel()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
        .listRowBackground(Theme.card)

        if !savedTerms.isEmpty {
            Section("Saved") {
                ForEach(savedTerms) { term in
                    GlossaryTermRow(term: term)
                }
            }
            .listRowBackground(Theme.card)
        }

        Section {
            ForEach(glossary.startHere) { term in
                GlossaryTermRow(term: term, isCompact: true)
            }
        } header: {
            Text("Start Here")
        } footer: {
            Text("The words you'll see most in DiabetesCare and at appointments.")
        }

        .listRowBackground(Theme.card)

        Section("Topics") {
            ForEach(GlossaryCategory.allCases, id: \.self) { category in
                NavigationLink(value: GlossaryDestination.category(category)) {
                    LabeledContent {
                        Text("\(glossary.terms(in: category).count)")
                            .monospacedDigit()
                    } label: {
                        Label {
                            Text(category.title)
                        } icon: {
                            GlossaryCategoryIcon(category: category)
                        }
                    }
                }
            }
        }

        .listRowBackground(Theme.card)

        Section {
            NavigationLink(value: GlossaryDestination.allTerms) {
                Label("All Terms A–Z", systemImage: "textformat.abc")
            }
        } footer: {
            GlossaryDisclaimer()
                .padding(.top, 8)
        }

        .listRowBackground(Theme.card)
    }
}

#Preview {
    NavigationStack {
        LearnView()
    }
    .environment(SettingsStore())
}
