//
//  LearnView.swift
//  Sucro - Take Care of Diabetes
//
//  The Learn tab: a searchable diabetes glossary, by topic and A–Z.
//

import SwiftUI

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
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Learn")
        .searchable(text: $query, prompt: "Search \(glossary.terms.count) terms")
        .glossaryDestinations()
    }

    @ViewBuilder
    private var browseSections: some View {
        if !savedTerms.isEmpty {
            Section("Saved") {
                ForEach(savedTerms) { term in
                    GlossaryTermRow(term: term)
                }
            }
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

        Section {
            NavigationLink(value: GlossaryDestination.allTerms) {
                Label("All Terms A–Z", systemImage: "textformat.abc")
            }
        } footer: {
            GlossaryDisclaimer()
                .padding(.top, 8)
        }
    }
}

#Preview {
    NavigationStack {
        LearnView()
    }
    .environment(SettingsStore())
}
