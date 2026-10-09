//
//  ThreadView.swift
//  Sucro - Take Care of Diabetes
//
//  The thread: glucose as one continuous line, with "now" at the right
//  edge, the past to the left and upcoming reminders just past now. Meals,
//  doses and site changes sit on the line where they happened. Pinch or
//  pick a zoom level to go from hours to weeks. Whatever is on screen is
//  the "view", and the summary under the thread describes it.
//

import SwiftUI
import Charts

/// How much time the thread shows at once.
enum ThreadZoom: Int, CaseIterable, Identifiable, Comparable {
    case sixHours, day, threeDays, week, twoWeeks

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .sixHours: return "6H"
        case .day: return "1D"
        case .threeDays: return "3D"
        case .week: return "1W"
        case .twoWeeks: return "2W"
        }
    }

    var spokenLabel: String {
        switch self {
        case .sixHours: return "6 hours"
        case .day: return "1 day"
        case .threeDays: return "3 days"
        case .week: return "1 week"
        case .twoWeeks: return "2 weeks"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .sixHours: return 6 * 3600
        case .day: return 24 * 3600
        case .threeDays: return 3 * 24 * 3600
        case .week: return 7 * 24 * 3600
        case .twoWeeks: return 14 * 24 * 3600
        }
    }

    /// Event icons only fit when zoomed in; further out they become ticks.
    var showsEventIcons: Bool { self <= .day }

    /// From a week out, the thread winds into rings, one per day.
    var showsRings: Bool { self >= .week }

    static func < (lhs: ThreadZoom, rhs: ThreadZoom) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// The visible stretch of the thread.
struct ThreadWindow: Equatable {
    var start: Date
    var end: Date

    func contains(_ date: Date) -> Bool { date >= start && date <= end }
}

struct ThreadView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let samples: [GlucoseSample]
    let events: [TimelineEvent]
    let reminders: [Reminder]
    let now: Date
    @Binding var zoom: ThreadZoom
    /// The leading edge of what's on screen. Updated as the thread scrolls.
    @Binding var scrollStart: Date

    @State private var selectedDate: Date?
    @State private var pinchHandled = false

    /// The thread reaches a little past now so upcoming reminders show.
    static let future: TimeInterval = 3 * 3600

    private var domain: ClosedRange<Date> {
        let earliest = samples.first?.date ?? now.addingTimeInterval(-ThreadZoom.sixHours.duration)
        let start = min(earliest, now.addingTimeInterval(-zoom.duration))
        return start...now.addingTimeInterval(Self.future)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if zoom.showsRings {
                    DayRings(samples: samples, days: ringDays, now: now, onSelectDay: unwind)
                        .frame(maxWidth: .infinity, maxHeight: 360)
                        .transition(.asymmetric(insertion: .scale(scale: 0.6).combined(with: .opacity), removal: .opacity))
                } else {
                    chart
                        .frame(height: 280)
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .smooth, value: zoom.showsRings)
            .simultaneousGesture(pinch)

            HStack {
                Picker("Zoom", selection: zoomBinding) {
                    ForEach(ThreadZoom.allCases) { level in
                        Text(level.label).tag(level)
                            .accessibilityLabel(level.spokenLabel)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("threadZoom")

                if !isShowingNow {
                    Button("Now", systemImage: "arrow.right.to.line") {
                        withAnimation(reduceMotion ? nil : .smooth) { scrollStart = Self.start(showing: zoom, at: now) }
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Back to now")
                    .transition(.opacity)
                }
            }
            .animation(.snappy, value: isShowingNow)
        }
        .sensoryFeedback(.selection, trigger: zoom)
    }

    /// Changing zoom keeps the right edge where it was, so zooming out from
    /// now still ends at now.
    private var zoomBinding: Binding<ThreadZoom> {
        Binding {
            zoom
        } set: { newZoom in
            let end = min(scrollStart.addingTimeInterval(zoom.duration), domain.upperBound)
            zoom = newZoom
            // Charts ignores a scroll position set in the same update as a
            // new visible length, so move it once the new length is in.
            Task { @MainActor in
                scrollStart = end.addingTimeInterval(-newZoom.duration)
            }
        }
    }

    /// One zoom step per pinch: spread to zoom in, pinch to zoom out.
    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                guard !pinchHandled else { return }
                if value.magnification > 1.35, let closer = ThreadZoom(rawValue: zoom.rawValue - 1) {
                    zoomBinding.wrappedValue = closer
                    pinchHandled = true
                } else if value.magnification < 0.7, let wider = ThreadZoom(rawValue: zoom.rawValue + 1) {
                    zoomBinding.wrappedValue = wider
                    pinchHandled = true
                }
            }
            .onEnded { _ in pinchHandled = false }
    }

    /// Calendar days the rings cover: every day the visible stretch touches.
    private var ringDays: [Date] {
        let calendar = Calendar.current
        let end = min(scrollStart.addingTimeInterval(zoom.duration), now)
        var day = calendar.startOfDay(for: end.addingTimeInterval(-zoom.duration))
        var days: [Date] = []
        while day <= end {
            days.append(day)
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? end.addingTimeInterval(1)
        }
        return days
    }

    /// Tapping a ring unwinds it: the thread zooms to that whole day.
    private func unwind(_ day: Date) {
        let start = Calendar.current.isDate(day, inSameDayAs: now)
            ? Self.start(showing: .day, at: now)
            : Calendar.current.startOfDay(for: day)
        withAnimation(reduceMotion ? nil : .smooth) { zoom = .day }
        Task { @MainActor in scrollStart = start }
    }

    private var isShowingNow: Bool {
        scrollStart.addingTimeInterval(zoom.duration) >= now.addingTimeInterval(-15 * 60)
    }

    /// Where the thread starts when it shows `zoom` ending just past now.
    static func start(showing zoom: ThreadZoom, at now: Date) -> Date {
        // Leave a sliver of the future in view so "now" isn't on the edge.
        now.addingTimeInterval(min(future, zoom.duration * 0.08) - zoom.duration)
    }

    // MARK: - Chart

    private var yTop: Double {
        settings.displayGlucose(max(300, (samples.map(\.mgdl).max() ?? 0) + 20))
    }

    private var yBottom: Double { settings.displayGlucose(20) }

    /// Events and reminders ride along the bottom of the thread, food on
    /// one lane and everything else on another, so a dose given just
    /// before a meal doesn't hide it.
    private var laneY: Double { settings.displayGlucose(32) }
    private var mealLaneY: Double { settings.displayGlucose(zoom.showsEventIcons ? 52 : 44) }

    private func lane(for event: TimelineEvent) -> Double {
        event.type == .meal ? mealLaneY : laneY
    }

    /// Glucose at a moment, from the nearest reading within 20 minutes.
    private func glucose(near date: Date) -> Double? {
        let nearest = samples.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
        guard let nearest, abs(nearest.date.timeIntervalSince(date)) <= 20 * 60 else { return nil }
        return nearest.mgdl
    }

    private func knotY(for event: TimelineEvent, onLine mgdl: Double) -> Double {
        let lift = (yTop - yBottom) * 0.09
        let y = settings.displayGlucose(mgdl) + (event.type == .meal ? lift : -lift)
        return min(max(y, yBottom + lift * 0.4), yTop - lift * 0.4)
    }

    private var chart: some View {
        Chart {
            RectangleMark(
                xStart: .value("Start", domain.lowerBound),
                xEnd: .value("End", domain.upperBound),
                yStart: .value("Target low", settings.displayGlucose(settings.targetLow)),
                yEnd: .value("Target high", settings.displayGlucose(settings.targetHigh))
            )
            .foregroundStyle(GlucoseZone.inRange.color.opacity(0.1))

            ForEach([settings.urgentLow, settings.urgentHigh], id: \.self) { line in
                RuleMark(y: .value("Urgent", settings.displayGlucose(line)))
                    .foregroundStyle(GlucoseZone.urgentHigh.color.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
            }

            RuleMark(x: .value("Now", now))
                .foregroundStyle(.tint)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .annotation(position: .top, alignment: .center, spacing: 2) {
                    Text("Now")
                        .instrumentLabel()
                        .foregroundStyle(.tint)
                }

            ForEach(segments, id: \.offset) { segment in
                ForEach(segment.element, id: \.date) { sample in
                    LineMark(
                        x: .value("Time", sample.date),
                        y: .value("Glucose", settings.displayGlucose(sample.mgdl)),
                        series: .value("Stretch", segment.offset)
                    )
                    .foregroundStyle(Theme.print.opacity(0.75))
                    .lineStyle(StrokeStyle(lineWidth: zoom <= .day ? 2 : 1.25, lineCap: .round))
                    .interpolationMethod(.monotone)
                }
            }

            ForEach(pointSamples, id: \.date) { sample in
                PointMark(
                    x: .value("Time", sample.date),
                    y: .value("Glucose", settings.displayGlucose(sample.mgdl))
                )
                .foregroundStyle(settings.zone(for: sample.mgdl).color)
                .symbolSize(pointSize)
            }

            ForEach(events) { event in
                if zoom.showsEventIcons {
                    // A knot tied onto the thread: food above the line,
                    // doses and the rest below, on a short tie.
                    if let onLine = glucose(near: event.timestamp) {
                        RuleMark(
                            x: .value("Time", event.timestamp),
                            yStart: .value("Line", settings.displayGlucose(onLine)),
                            yEnd: .value("Knot", knotY(for: event, onLine: onLine))
                        )
                        .foregroundStyle(Color.accentColor.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    }
                    PointMark(
                        x: .value("Time", event.timestamp),
                        y: .value("Knot", glucose(near: event.timestamp).map { knotY(for: event, onLine: $0) } ?? lane(for: event))
                    )
                        .symbol {
                            Image(systemName: event.icon)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Theme.onAccent)
                                .frame(width: 18, height: 18)
                                .background(Color.accentColor, in: .circle)
                        }
                } else {
                    RuleMark(
                        x: .value("Time", event.timestamp),
                        yStart: .value("Lane bottom", lane(for: event) - settings.displayGlucose(5)),
                        yEnd: .value("Lane top", lane(for: event) + settings.displayGlucose(5))
                    )
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
            }

            // Upcoming reminders, past now: hollow, because they haven't happened.
            ForEach(reminders.filter { $0.time > now && $0.time <= domain.upperBound }) { reminder in
                PointMark(x: .value("Time", reminder.time), y: .value("Lane", laneY))
                    .symbol {
                        Image(systemName: "bell")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.tint)
                            .frame(width: 18, height: 18)
                            .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: 1.5))
                    }
            }

            if let selected = selection {
                RuleMark(x: .value("Selected", selected.date))
                    .foregroundStyle(.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        // Annotations don't inherit the environment, so the
                        // callout gets its text ready-made.
                        SelectionCallout(
                            value: settings.formattedGlucose(selected.mgdl),
                            time: selected.date.formatted(.dateTime.weekday(.abbreviated).hour().minute()),
                            color: settings.zone(for: selected.mgdl).color
                        )
                    }
            }
        }
        .chartXScale(domain: domain)
        .chartYScale(domain: yBottom...yTop)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: zoom.duration)
        .chartScrollPosition(x: $scrollStart)
        .chartXSelection(value: $selectedDate)
        .chartXAxis { xAxis }
        .chartYAxis {
            AxisMarks(position: .trailing, values: [settings.targetLow, settings.targetHigh].map(settings.displayGlucose)) { value in
                AxisGridLine().foregroundStyle(GlucoseZone.inRange.color.opacity(0.4))
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(settings.glucoseUnit == "mmol/L" ? v.formatted(.number.precision(.fractionLength(1))) : "\(Int(v))")
                            .font(Theme.readout(.caption2))
                    }
                }
            }
        }
        .accessibilityLabel("Glucose thread")
        .accessibilityIdentifier("glucoseThread")
    }

    @AxisContentBuilder
    private var xAxis: some AxisContent {
        switch zoom {
        case .sixHours:
            AxisMarks(values: .stride(by: .hour)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        case .day:
            AxisMarks(values: .stride(by: .hour, count: 3)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        case .threeDays, .week:
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated).day())
            }
        case .twoWeeks:
            AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
    }

    private var pointSize: CGFloat {
        switch zoom {
        case .sixHours: return 40
        case .day: return 16
        case .threeDays: return 8
        case .week, .twoWeeks: return 4
        }
    }

    /// Close in, every reading gets a dot. Further out the line carries
    /// the shape, and dots mark only readings out of range or on their own
    /// (a fingerstick with no line through it).
    private var pointSamples: [GlucoseSample] {
        guard zoom > .sixHours else { return samples }
        let isolated = Set(segmentsRaw.filter { $0.count == 1 }.flatMap { $0 }.map(\.date))
        return samples.filter { settings.zone(for: $0.mgdl) != .inRange || isolated.contains($0.date) }
    }

    /// Readings split wherever there's a gap of over an hour, so the line
    /// never draws through time with no data.
    private var segments: [EnumeratedSequence<[[GlucoseSample]]>.Element] {
        Array(segmentsRaw.filter { $0.count > 1 }.enumerated())
    }

    private var segmentsRaw: [[GlucoseSample]] {
        var result: [[GlucoseSample]] = []
        var current: [GlucoseSample] = []
        for sample in samples {
            if let last = current.last, sample.date.timeIntervalSince(last.date) > 3600 {
                result.append(current)
                current = []
            }
            current.append(sample)
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    /// The reading nearest the touched time, if there's one close enough.
    private var selection: GlucoseSample? {
        guard let selectedDate else { return nil }
        let tolerance = zoom.duration / 24
        return samples.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
            .flatMap { abs($0.date.timeIntervalSince(selectedDate)) <= tolerance ? $0 : nil }
    }
}

private struct SelectionCallout: View {
    let value: String
    let time: String
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            Text(value)
                .font(Theme.readout(.subheadline, weight: .semibold))
                .foregroundStyle(color)
            Text(time)
                .font(Theme.readout(.caption2))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.panel, in: .rect(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.seam))
    }
}
