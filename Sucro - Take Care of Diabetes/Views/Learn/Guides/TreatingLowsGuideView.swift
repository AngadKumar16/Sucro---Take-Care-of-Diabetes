//
//  TreatingLowsGuideView.swift
//  Sucro - Take Care of Diabetes
//

import SwiftUI

/// The rule of 15 as a numbered timeline, with 15 g carb examples.
struct TreatingLowsGuideView: View {
    @Environment(SettingsStore.self) private var settings

    private struct Step: Identifiable {
        let symbol: String
        let title: String
        let detail: String
        var id: String { title }
    }

    private var steps: [Step] {
        let low = settings.formattedGlucose(settings.targetLow)
        return [
            Step(symbol: "drop.fill", title: "Check",
                 detail: "Confirm you're below \(low) if you can. If you can't check but feel low, treat anyway."),
            Step(symbol: "cube.fill", title: "Eat 15 g of fast carbs",
                 detail: "Something sugary that works fast. Skip chocolate and other fatty foods: fat slows it down."),
            Step(symbol: "timer", title: "Wait 15 minutes",
                 detail: "Glucose takes time to rise. Eating more right away can overshoot into a high."),
            Step(symbol: "arrow.clockwise", title: "Check again",
                 detail: "Still below \(low)? Repeat with another 15 g."),
            Step(symbol: "fork.knife", title: "Then a snack",
                 detail: "Back in range and your next meal is more than an hour away? Have a snack to stay there.")
        ]
    }

    private let examples: [(symbol: String, text: String)] = [
        ("pills.fill", "3–4 glucose tablets"),
        ("cup.and.saucer.fill", "½ cup (120 mL) juice"),
        ("waterbottle.fill", "½ cup regular soda"),
        ("cube.fill", "1 tablespoon sugar or honey")
    ]

    var body: some View {
        GuidePage(guide: .treatingLows) {
            GuideSection(title: "15 – 15") {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        StepRow(number: index + 1, step: step, isLast: index == steps.count - 1)
                    }
                }
            }

            GuideSection(title: "What 15 g Looks Like") {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(examples, id: \.text) { example in
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: example.symbol)
                                .font(.title2)
                                .foregroundStyle(Guide.treatingLows.gradient)
                                .accessibilityHidden(true)
                            Text(example.text)
                                .font(.subheadline.weight(.medium))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
                        .padding(14)
                        .printSurface()
                    }
                }
                Text("Check the label: products differ. Your care team may give you a different amount, for example for children.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            GuideSection(title: "When It's Severe") {
                Label {
                    Text("If someone is too confused to swallow safely, or passes out, don't give food or drink. Use glucagon if they have it and call emergency services.")
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "staroflife.fill")
                        .foregroundStyle(.red)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.12), in: .rect(cornerRadius: 16))
            }

            GuideRelatedTerms(termIDs: ["rule-of-15", "fast-acting-carbs", "glucagon", "hypo-unawareness"])
        }
    }

    private struct StepRow: View {
        let number: Int
        let step: Step
        let isLast: Bool

        var body: some View {
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 0) {
                    Text("\(number)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Guide.treatingLows.gradient, in: .circle)
                    Rectangle()
                        .fill(isLast ? Color.clear : Color.orange.opacity(0.4))
                        .frame(width: 3)
                        .frame(maxHeight: .infinity)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Label(step.title, systemImage: step.symbol)
                        .font(.headline)
                    Text(step.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 6)
                .padding(.bottom, isLast ? 0 : 20)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Step \(number): \(step.title). \(step.detail)")
        }
    }
}

#Preview {
    NavigationStack {
        TreatingLowsGuideView()
            .glossaryDestinations()
    }
    .environment(SettingsStore())
}
