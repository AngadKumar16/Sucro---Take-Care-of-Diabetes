//
//  LowTreatmentCard.swift
//  Sucro - Take Care of Diabetes
//
//  The low alert, built around what you actually do: tap each glucose tab
//  (or the juice) you take, log it, and the 15-minute recheck starts.
//

import SwiftUI

struct LowTreatmentCard: View {
    @Environment(SettingsStore.self) private var settings
    let mgdl: Double
    /// When the recheck is due, once a treatment was logged.
    let recheckAt: Date?
    let treatedGrams: Double
    let onLogTreatment: (Double) -> Void
    /// Opens the full carbs form.
    let onLogCarbs: () -> Void
    /// Opens the glucose form for the recheck.
    let onLogGlucose: () -> Void
    let onDismiss: () -> Void

    @State private var tabs = 0
    @State private var juice = false
    @State private var showGuide = false

    private static let gramsPerTab = 4.0
    private static let juiceGrams = 15.0

    private var grams: Double { Double(tabs) * Self.gramsPerTab + (juice ? Self.juiceGrams : 0) }
    private var isUrgent: Bool { settings.zone(for: mgdl) == .urgentLow }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let recheckAt {
                recheck(until: recheckAt)
            } else {
                Text("What did you take? Tap each one.")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                treatments
            }
            actions
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .overlay(Rectangle().strokeBorder(Theme.vermilion, lineWidth: 2))
        .background(Theme.vermilion.offset(x: 3, y: 3))
        .sensoryFeedback(.selection, trigger: grams)
        .sheet(isPresented: $showGuide) { GuideSheet(guide: .treatingLows) }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(settings.glucoseValueString(mgdl))
                .font(.system(size: 48, weight: .semibold, design: .serif).monospacedDigit())
                .foregroundStyle(Theme.vermilion)
            Image(systemName: "arrow.down.right")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.vermilion)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(isUrgent ? "URGENT LOW" : "LOW GLUCOSE")
                    .font(.system(.headline, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.vermilion)
                Text(isUrgent ? "\(settings.glucoseUnit) · don't drive" : settings.glucoseUnit)
                    .font(.footnote)
                    .foregroundStyle(Theme.soft)
            }
            Spacer(minLength: 0)
            Button("Dismiss", systemImage: "xmark", action: onDismiss)
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.vermilion)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
                .buttonStyle(.plain)
        }
    }

    private var treatments: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(0..<4, id: \.self) { index in
                let taken = index < tabs
                Button {
                    tabs = taken && index == tabs - 1 ? index : index + 1
                } label: {
                    ZStack {
                        Circle().fill(taken ? Theme.vermilion.opacity(0.22) : Theme.card)
                        Circle().strokeBorder(Theme.ink, lineWidth: 2)
                        if taken {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.ink)
                        } else {
                            Text("4 g")
                                .font(Theme.mono(.caption, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Theme.vermilion).offset(x: taken ? 2 : 0, y: taken ? 2 : 0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Glucose tablet \(index + 1), 4 grams")
                .accessibilityAddTraits(taken ? .isSelected : [])
            }
            Button {
                juice.toggle()
            } label: {
                VStack(spacing: 0) {
                    Text("juice").font(Theme.mono(.caption, weight: .semibold))
                    Text("15 g").font(Theme.mono(.caption, weight: .semibold))
                }
                .foregroundStyle(Theme.ink)
                .frame(width: 54, height: 64)
                .background(juice ? Theme.vermilion.opacity(0.22) : Theme.card)
                .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: 2))
                .overlay(alignment: .topTrailing) {
                    Rectangle().fill(Theme.ink).frame(width: 3, height: 16).rotationEffect(.degrees(14)).offset(x: -14, y: -12)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Juice box, 15 grams")
            .accessibilityAddTraits(juice ? .isSelected : [])
        }
    }

    private func recheck(until date: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, date.timeIntervalSince(context.date))
            let fraction = remaining / (15 * 60)
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(Theme.rule, lineWidth: 7)
                    Circle().trim(from: 0, to: fraction)
                        .stroke(Theme.vermilion, style: StrokeStyle(lineWidth: 7))
                        .rotationEffect(.degrees(-90))
                    Text(Duration.seconds(remaining).formatted(.time(pattern: .minuteSecond)))
                        .font(Theme.mono(.subheadline, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }
                .frame(width: 78, height: 78)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(treatedGrams.formatted(.number.precision(.fractionLength(0)))) g taken")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                    Text(remaining > 0 ? "Check again when the timer ends; you'll get a nudge." : "Time to check your glucose again.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            if recheckAt == nil {
                if grams > 0 {
                    Button("Log \(grams.formatted(.number.precision(.fractionLength(0)))) g", systemImage: "checkmark") {
                        onLogTreatment(grams)
                        tabs = 0
                        juice = false
                    }
                    .buttonStyle(.printDestructive)
                } else {
                    Button("Log Carbs", systemImage: "fork.knife", action: onLogCarbs)
                        .buttonStyle(.printDestructive)
                }
            } else {
                Button("Log glucose", systemImage: "drop", action: onLogGlucose)
                    .buttonStyle(.printDestructive)
            }
            Button("How to treat") { showGuide = true }
                .buttonStyle(.printSecondary)
        }
    }
}
