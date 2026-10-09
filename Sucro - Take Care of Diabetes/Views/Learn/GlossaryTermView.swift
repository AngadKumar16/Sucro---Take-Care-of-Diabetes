//
//  GlossaryTermView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// One glossary term: definition, more detail, where it shows up in the
/// app, and related terms.
struct GlossaryTermView: View {
    @Environment(SettingsStore.self) private var settings
    let term: GlossaryTerm
    /// The inline title appears once the big heading scrolls away.
    @State private var showsInlineTitle = false

    private var related: [GlossaryTerm] {
        Glossary.shared.related(to: term)
    }

    var body: some View {
        let isSaved = settings.isSaved(term)

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(term.category.title, systemImage: term.category.symbol)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(term.category.color)
                    Text(term.name)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    if !term.aliases.isEmpty {
                        Text("Also called \(term.aliases.formatted(.list(type: .or)))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(GlossaryTerm.unbreakable(term.summary))
                    .font(.title3.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                Text(GlossaryTerm.unbreakable(term.details))
                    .font(.body)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let inApp = term.inApp {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("In DiabetesCare")
                                .font(.subheadline.weight(.semibold))
                            Text(inApp)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } icon: {
                        Image(systemName: "iphone")
                            .foregroundStyle(.tint)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.1), in: .rect(cornerRadius: 12))
                }

                if !related.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        VStack(spacing: 0) {
                            ForEach(Array(related.enumerated()), id: \.element.id) { index, term in
                                if index > 0 { Divider().padding(.leading) }
                                NavigationLink(value: GlossaryDestination.term(term)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(term.name)
                                                .foregroundStyle(.primary)
                                            Text(term.summary)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer(minLength: 8)
                                        Image(systemName: "chevron.right")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundStyle(.tertiary)
                                            .accessibilityHidden(true)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    .contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .printSurface()
                    }
                }

                GlossaryDisclaimer()
            }
            .frame(maxWidth: 640, alignment: .leading)
            .padding()
            .frame(maxWidth: .infinity)
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > 90
        } action: { _, isPastHeading in
            withAnimation(.easeInOut(duration: 0.2)) { showsInlineTitle = isPastHeading }
        }
        .instrumentBackground()
        .navigationTitle(term.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(term.name)
                    .font(.headline)
                    .lineLimit(1)
                    .opacity(showsInlineTitle ? 1 : 0)
                    .accessibilityHidden(!showsInlineTitle)
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button(isSaved ? "Unsave" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark") {
                    settings.toggleSaved(term)
                }
                .accessibilityIdentifier("saveTerm")
                ShareLink(item: term.shareText, subject: Text(term.name))
            }
        }
        .sensoryFeedback(.selection, trigger: isSaved)
    }
}

#Preview {
    NavigationStack {
        GlossaryTermView(term: Glossary.shared.term("insulin-on-board")!)
            .glossaryDestinations()
    }
    .environment(SettingsStore())
}
