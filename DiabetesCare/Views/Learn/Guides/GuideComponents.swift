//
//  GuideComponents.swift
//  DiabetesCare
//
//  Building blocks shared by the guide pages: the printed card that
//  opens a guide, the carousel of cards, the page scaffold and its hero.
//

import SwiftUI

/// A printed tile that names a guide.
struct GuideCard: View {
    @Environment(SettingsStore.self) private var settings
    let guide: Guide

    private var hasSticker: Bool { settings.guideStickers.contains(guide.rawValue) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: guide.symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.card)
                .frame(width: 44, height: 44)
                .background(Theme.green)
            Spacer(minLength: 8)
            Text(guide.title)
                .font(.system(.headline, design: .serif, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(guide.subtitle)
                .font(.caption)
                .opacity(0.85)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(Theme.ink)
        .padding(14)
        .frame(width: 168, height: 168, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            if hasSticker {
                GuideSticker(guide: guide, size: 34)
                    .padding(8)
                    .accessibilityLabel("Sticker collected")
            }
        }
        .background(alignment: .bottomTrailing) {
            // An oversized faded symbol gives each card its own texture.
            Image(systemName: guide.symbol)
                .font(.system(size: 96, weight: .bold))
                .foregroundStyle(Theme.green.opacity(0.10))
                .rotationEffect(.degrees(-12))
                .offset(x: 24, y: 20)
                .accessibilityHidden(true)
        }
        .background(Theme.card)
        .clipped()
        .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: 1.5))
        .background(Theme.offset.offset(x: 3, y: 3))
        .contentShape(.rect)
    }
}

/// A horizontal row of guide cards. Each opens its guide in a sheet, so it
/// works anywhere, inside or outside a navigation stack.
struct GuideCarousel: View {
    var guides: [Guide] = Guide.allCases
    @State private var presented: Guide?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(guides) { guide in
                    Button { presented = guide } label: {
                        GuideCard(guide: guide)
                    }
                    .buttonStyle(GuideCardButtonStyle())
                    .accessibilityLabel(guide.title)
                    .accessibilityHint(guide.subtitle)
                    .accessibilityIdentifier("guide.\(guide.rawValue)")
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .sheet(item: $presented) { guide in
            GuideSheet(guide: guide)
        }
    }
}

struct GuideCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// A guide in its own sheet, with glossary links and other guides
/// reachable inside it.
struct GuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    let guide: Guide

    var body: some View {
        NavigationStack {
            guide.content
                .glossaryDestinations()
                .guideDestinations()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

/// The scrolling page every guide uses: a printed hero, then sections.
struct GuidePage<Content: View>: View {
    let guide: Guide
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                GuideHero(guide: guide)
                content
                GuideStickerButton(guide: guide)
                GlossaryDisclaimer()
            }
            .frame(maxWidth: 640, alignment: .leading)
            .padding()
            .frame(maxWidth: .infinity)
        }
        .instrumentBackground()
        .navigationTitle(guide.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GuideHero: View {
    let guide: Guide

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: guide.symbol)
                .font(.title.weight(.semibold))
                .frame(width: 56, height: 56)
                .foregroundStyle(Theme.card)
                .background(Theme.green)
                .accessibilityHidden(true)
            Spacer(minLength: 12)
            Text(guide.title)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Text(guide.subtitle)
                .font(.headline)
                .opacity(0.9)
        }
        .foregroundStyle(Theme.ink)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .leading)
        .background(alignment: .topTrailing) {
            Image(systemName: guide.symbol)
                .font(.system(size: 150, weight: .bold))
                .foregroundStyle(Theme.green.opacity(0.10))
                .rotationEffect(.degrees(-12))
                .offset(x: 30, y: -10)
                .accessibilityHidden(true)
        }
        .background(Theme.card)
        .clipped()
        .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: 1.5))
        .background(Theme.offset.offset(x: 3, y: 3))
    }
}

/// A titled block inside a guide.
struct GuideSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

/// A glossary term shown as a tappable row inside a guide.
struct GuideTermLink: View {
    let termID: String

    var body: some View {
        if let term = Glossary.shared.term(termID) {
            NavigationLink(value: GlossaryDestination.term(term)) {
                HStack {
                    GlossaryCategoryIcon(category: term.category)
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
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}

/// "Read more" glossary terms at the end of a guide.
struct GuideRelatedTerms: View {
    let termIDs: [String]

    var body: some View {
        GuideSection(title: "Read More") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(termIDs, id: \.self) { id in
                    GuideTermLink(termID: id)
                }
            }
            .card()
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            GuideCarousel()
        }
    }
    .environment(SettingsStore())
}

/// A round sticker for a finished guide.
struct GuideSticker: View {
    let guide: Guide
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: guide.symbol)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(guide.gradient, in: .circle)
            .overlay(Circle().strokeBorder(.white, lineWidth: size * 0.06))
            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
            .rotationEffect(.degrees(-8))
    }
}

/// "I read this" at the end of a guide: collects its sticker.
struct GuideStickerButton: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let guide: Guide

    private var collected: Bool { settings.guideStickers.contains(guide.rawValue) }

    var body: some View {
        HStack(spacing: 14) {
            GuideSticker(guide: guide)
                .saturation(collected ? 1 : 0)
                .opacity(collected ? 1 : 0.45)
                .scaleEffect(collected ? 1 : 0.9)
                .symbolEffect(.bounce, value: reduceMotion ? false : collected)
            VStack(alignment: .leading, spacing: 4) {
                Text(collected ? "Sticker collected" : "Finished reading?")
                    .font(.headline)
                if collected {
                    Text("It's on Your Path.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.soft)
                } else {
                    Button("Collect the Sticker") {
                        withAnimation(.bouncy) { _ = settings.guideStickers.insert(guide.rawValue) }
                    }
                    .font(.subheadline.weight(.semibold))
                    .accessibilityIdentifier("collectSticker")
                }
            }
            Spacer(minLength: 0)
        }
        .softPanel(border: collected ? Theme.green : Theme.rule)
        .sensoryFeedback(.success, trigger: collected) { old, new in !old && new }
    }
}

/// Every guide's sticker, collected or not, for Your Path.
struct StickerBook: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Stickers")
                    .font(.headline)
                Spacer()
                Text("\(settings.guideStickers.count) of \(Guide.allCases.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.soft)
            }
            HStack(spacing: 12) {
                ForEach(Guide.allCases) { guide in
                    let has = settings.guideStickers.contains(guide.rawValue)
                    GuideSticker(guide: guide, size: 48)
                        .saturation(has ? 1 : 0)
                        .opacity(has ? 1 : 0.3)
                        .accessibilityLabel("\(guide.title): \(has ? "collected" : "not yet")")
                }
            }
            Text("Read a guide in Learn to the end to collect its sticker.")
                .font(.footnote)
                .foregroundStyle(Theme.soft)
        }
        .softPanel()
        .accessibilityElement(children: .contain)
    }
}
