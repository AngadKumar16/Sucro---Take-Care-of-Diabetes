//
//  WeeklyRecapView.swift
//  DiabetesCare
//
//  "Your week": time in range against the week before, the steadiest day,
//  how many days were logged, and each day in a sentence. The summary card
//  can be shared as an image with family.
//

import SwiftUI

struct WeeklyRecapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(SettingsStore.self) private var settings
    @Environment(\.displayScale) private var displayScale

    @State private var week: Story.Week?
    @State private var days: [Story.Day] = []
    @State private var shareImage: Image?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let week {
                    RecapCard(week: week, name: settings.userName)
                    if let shareImage {
                        ShareLink(item: shareImage, preview: SharePreview(String(localized: "My week"), image: shareImage)) {
                            Label("Share My Week", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.soft)
                        .accessibilityIdentifier("shareWeek")
                    }
                    CardHeader("Day by day")
                    ForEach(days, id: \.interval.start) { day in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(day.interval.start.formatted(.dateTime.weekday(.wide).month().day()))
                                .friendlyLabel()
                            Text(Story.sentence(for: day, glucose: settings.formattedGlucose))
                                .font(.subheadline)
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            InRangeBar(percent: day.inRangePercent)
                        }
                        .card()
                    }
                } else {
                    ContentUnavailableView(
                        "No Readings This Week",
                        systemImage: "calendar",
                        description: Text("Your week shows up here once you've logged some glucose.")
                    )
                }
            }
            .padding()
        }
        .instrumentBackground()
        .navigationTitle("Your Week")
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
    }

    private func load() {
        week = StoryService.week(context: viewContext, settings: settings)
        days = StoryService.days(context: viewContext, settings: settings)
        if let week {
            let renderer = ImageRenderer(content:
                RecapCard(week: week, name: settings.userName)
                    .frame(width: 360)
                    .padding(20)
                    .background(Theme.paper)
                    .environment(settings)
            )
            renderer.scale = displayScale
            if let image = renderer.uiImage {
                shareImage = Image(uiImage: image)
            }
        }
    }
}

/// The week at a glance; also what gets shared as an image.
struct RecapCard: View {
    @Environment(SettingsStore.self) private var settings
    let week: Story.Week
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? String(localized: "Your week") : String(localized: "\(name)'s week"))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("\(week.interval.start.formatted(.dateTime.month().day())) – \(week.interval.end.formatted(.dateTime.month().day()))")
                    .font(.subheadline)
                    .foregroundStyle(Theme.soft)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(Int(week.inRangePercent.rounded()))%")
                    .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("in range")
                        .font(.headline)
                    if let previous = week.previousInRangePercent {
                        let change = Int((week.inRangePercent - previous).rounded())
                        Label(change == 0 ? String(localized: "same as last week") : String(localized: "\(abs(change)) points \(change > 0 ? String(localized: "more") : String(localized: "less")) than last week"),
                              systemImage: change > 0 ? "arrow.up.right" : change < 0 ? "arrow.down.right" : "equal")
                            .font(.subheadline)
                            .foregroundStyle(Theme.soft)
                    }
                }
            }
            InRangeBar(percent: week.inRangePercent)
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    fact("calendar.badge.checkmark", String(localized: "Logged \(week.loggedDays) of 7 days"))
                    fact("arrow.down.circle", week.lows == 0 ? String(localized: "No lows") : String(localized: "\(week.lows) lows"))
                }
                GridRow {
                    fact("drop", String(localized: "Average \(settings.formattedGlucose(week.average))"))
                    if let steadiest = week.steadiestDay {
                        fact("water.waves", String(localized: "Steadiest: \(steadiest.formatted(.dateTime.weekday(.wide)))"))
                    }
                }
            }
        }
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("recapCard")
    }

    private func fact(_ symbol: String, _ text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.subheadline)
            .foregroundStyle(Theme.ink)
    }
}
