//
//  LogView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct LogView: View {
    @Environment(LogViewModel.self) private var viewModel
    @Environment(SettingsStore.self) private var settings
    @Environment(\.managedObjectContext) private var viewContext
    @State private var filter: Filter = .all
    @State private var pendingDelete: LogRow?

    enum Filter: String, CaseIterable {
        case all = "All"
        case glucose = "Glucose"
        case carbs = "Carbs"
        case insulin = "Insulin"
        case activity = "Activity"
    }

    var body: some View {
        List {
            Section {
                DayPicker(
                    date: Bindable(viewModel).selectedDate,
                    canGoForward: !viewModel.isShowingToday,
                    onMove: viewModel.moveDay(by:)
                )
                Picker("Show", selection: $filter) {
                    ForEach(Filter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

            if rows.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label(emptyTitle, systemImage: "list.bullet.clipboard")
                    } description: {
                        Text("Tap \(Image(systemName: "plus")) to add an entry.")
                    } actions: {
                        if hiddenHealthCount > 0 {
                            Button("Show \(hiddenHealthCount) Apple Health Readings") { filter = .glucose }
                        }
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ReceiptHeader(date: viewModel.selectedDate)
                    ForEach(rows) { row in
                        Button {
                            viewModel.edit(row.object)
                        } label: {
                            LogRowView(row: row)
                        }
                        .foregroundStyle(.primary)
                        .swipeActions(edge: .trailing) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                pendingDelete = row
                            }
                        }
                        .contextMenu {
                            Button("Edit", systemImage: "pencil") { viewModel.edit(row.object) }
                            Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = row }
                        }
                        .accessibilityHint("Edits this entry")
                        .accessibilityAction(named: "Delete") { pendingDelete = row }
                    }
                    ReceiptTotals(
                        carbs: viewModel.carbEntries.reduce(0) { $0 + $1.grams },
                        insulin: viewModel.insulinEntries.reduce(0) { $0 + $1.units },
                        summary: summary
                    )
                }
                .listRowBackground(Theme.card)
                .listRowSeparatorTint(Theme.rule)
            }
        }
        .listStyle(.insetGrouped)
        .instrumentBackground()
        .navigationTitle("Log")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Add Entry", systemImage: "plus") {
                    Button("Add Glucose", systemImage: "drop") { viewModel.showAddGlucose = true }
                    Button("Add Carbs", systemImage: "fork.knife") { viewModel.showAddCarbs = true }
                    Button("Add Insulin", systemImage: "syringe") { viewModel.showAddInsulin = true }
                    Button("Add Activity", systemImage: "figure.walk") { viewModel.showAddActivity = true }
                }
                .accessibilityIdentifier("addEntryMenu")
            }
        }
        .onAppear { viewModel.fetchEntriesForDate(viewModel.selectedDate) }
        .onChange(of: viewModel.selectedDate) { _, date in
            viewModel.fetchEntriesForDate(date)
        }
        // Entries change from other screens too (notes and edits on Today,
        // Health imports), so refetch whenever the store's context changes.
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext)) { _ in
            viewModel.fetchEntriesForDate(viewModel.selectedDate)
        }
        .confirmationDialog(
            "Delete \(pendingDelete?.title ?? "Entry")?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { row in
            Button("Delete", role: .destructive) { viewModel.deleteEntry(row.object) }
        } message: { _ in
            Text("This can't be undone.")
        }
        .sheet(isPresented: Bindable(viewModel).showAddGlucose) {
            AddGlucoseView()
                .environment(viewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showAddCarbs) {
            AddCarbView()
                .environment(viewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showAddInsulin) {
            AddInsulinView()
                .environment(viewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showAddActivity) {
            AddActivityView()
                .environment(viewModel)
        }
        .sheet(item: Bindable(viewModel).editOperation) { operation in
            EntryEditorView(operation: operation)
        }
    }

    private var emptyTitle: String {
        let kind = filter == .all ? "Entries" : filter.rawValue
        return viewModel.isShowingToday ? "No \(kind) Today" : "No \(kind) This Day"
    }

    /// Everything logged on the selected day, newest first.
    private var rows: [LogRow] {
        _ = viewModel.revision
        var rows: [LogRow] = []
        if filter == .all || filter == .glucose {
            // A CGM sends hundreds of readings a day; in All they'd bury
            // meals and doses, so only Health readings with a note show there.
            let readings = filter == .all ? viewModel.glucoseReadings.filter { !hidesInAll($0) } : viewModel.glucoseReadings
            rows += readings.map { reading in
                LogRow(
                    object: reading,
                    timestamp: reading.timestamp,
                    icon: "drop.fill",
                    color: settings.zone(for: reading.value).color,
                    title: settings.formattedGlucose(reading.value),
                    detail: [reading.isFromHealth ? "Apple Health" : nil, reading.context]
                        .compactMap { $0 }.joined(separator: " · "),
                    notes: reading.notes
                )
            }
        }
        if filter == .all || filter == .carbs {
            rows += viewModel.carbEntries.map { entry in
                LogRow(
                    object: entry,
                    timestamp: entry.timestamp,
                    icon: "fork.knife",
                    color: .orange,
                    title: "\(entry.grams.formatted(.number.precision(.fractionLength(0...1))))g carbs",
                    detail: [MealType(stored: entry.mealType)?.rawValue ?? entry.mealType, entry.foodItems]
                        .compactMap { $0 }.joined(separator: " · "),
                    notes: entry.notes
                )
            }
        }
        if filter == .all || filter == .insulin {
            rows += viewModel.insulinEntries.map { entry in
                LogRow(
                    object: entry,
                    timestamp: entry.timestamp,
                    icon: "syringe.fill",
                    color: .green,
                    title: "\(entry.units.formatted(.number.precision(.fractionLength(0...2)))) U",
                    detail: [InsulinType(stored: entry.type)?.displayName, DeliveryMethod(stored: entry.deliveryMethod)?.rawValue]
                        .compactMap { $0 }.joined(separator: " · "),
                    notes: entry.notes
                )
            }
        }
        if filter == .all || filter == .activity {
            rows += viewModel.activityEntries.map { entry in
                LogRow(
                    object: entry,
                    timestamp: entry.timestamp,
                    icon: "figure.walk",
                    color: .blue,
                    title: entry.type ?? "Activity",
                    detail: [Optional("\(entry.duration) min"), entry.intensity].compactMap { $0 }.joined(separator: " · "),
                    notes: entry.notes
                )
            }
        }
        return rows.sorted { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }
    }

    private var summary: String {
        let count = rows.count
        let entries = "\(count) \(count == 1 ? "entry" : "entries")"
        guard filter == .all else { return entries }
        let hidden = hiddenHealthCount
        guard hidden > 0 else { return entries }
        return "\(entries). \(hidden) Apple Health \(hidden == 1 ? "reading is" : "readings are") under Glucose."
    }

    /// Health readings left out of All on this day.
    private var hiddenHealthCount: Int {
        filter == .all ? viewModel.glucoseReadings.count(where: hidesInAll) : 0
    }

    private func hidesInAll(_ reading: GlucoseReading) -> Bool {
        reading.isFromHealth && (reading.notes ?? "").isEmpty
    }
}

struct LogRow: Identifiable {
    let object: NSManagedObject
    let timestamp: Date?
    let icon: String
    let color: Color
    let title: String
    let detail: String?
    let notes: String?

    var id: NSManagedObjectID { object.objectID }
}

/// One line of the day's receipt: time, what, a dotted leader, the kind.
private struct LogRowView: View {
    let row: LogRow

    private var kind: String {
        switch row.icon {
        case "drop.fill": "GLUCOSE"
        case "fork.knife": "CARBS"
        case "syringe.fill": "INSULIN"
        case "figure.walk": "ACTIVITY"
        default: "ENTRY"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let timestamp = row.timestamp {
                    Text(timestamp, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                        .font(Theme.mono(.subheadline))
                        .foregroundStyle(Theme.soft)
                        .frame(width: 50, alignment: .leading)
                }
                Text(row.title)
                    .font(Theme.mono(.body, weight: .semibold))
                    .foregroundStyle(row.icon == "drop.fill" ? row.color : Theme.ink)
                DottedLeader()
                Text(kind)
                    .font(Theme.mono(.caption, weight: .medium))
                    .foregroundStyle(Theme.soft)
            }
            if let detail = row.detail, !detail.isEmpty {
                Text(detail)
                    .font(.system(.subheadline, design: .serif).italic())
                    .foregroundStyle(Theme.soft)
                    .padding(.leading, 58)
            }
            if let notes = row.notes, !notes.isEmpty {
                Text("“\(notes)”")
                    .font(.system(.footnote, design: .serif).italic())
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .padding(.leading, 58)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([row.title, row.detail, row.notes, row.timestamp?.formatted(date: .omitted, time: .shortened)]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", "))
    }
}

/// Dots that fill the space between a label and its value.
struct DottedLeader: View {
    var body: some View {
        Line()
            .stroke(Theme.rule, style: StrokeStyle(lineWidth: 1.5, dash: [1.5, 3]))
            .frame(height: 1.5)
            .frame(minWidth: 12)
            .alignmentGuide(.firstTextBaseline) { d in d[.bottom] + 3 }
            .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}

/// A torn paper edge: a row of small teeth in the page color.
private struct TornEdge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tooth: CGFloat = 8
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        var x = rect.minX
        var down = true
        while x < rect.maxX {
            x += tooth / 2
            path.addLine(to: CGPoint(x: min(x, rect.maxX), y: down ? rect.maxY : rect.minY))
            down.toggle()
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

/// The top of the receipt: a torn edge and the date.
private struct ReceiptHeader: View {
    let date: Date

    var body: some View {
        VStack(spacing: 2) {
            Text("DIABETESCARE · DAY LOG")
                .font(Theme.mono(.footnote, weight: .semibold))
                .tracking(2)
            Text(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()).uppercased())
                .font(Theme.mono(.footnote))
                .foregroundStyle(Theme.soft)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .overlay(alignment: .top) {
            TornEdge().fill(Theme.paper).frame(height: 5).padding(.horizontal, -20).offset(y: -12)
        }
        .listRowSeparatorTint(Theme.ink)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The bottom of the receipt: the day's totals and a torn edge.
private struct ReceiptTotals: View {
    let carbs: Double
    let insulin: Double
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            line("CARBS", "\(carbs.formatted(.number.precision(.fractionLength(0)))) g")
            line("INSULIN", "\(insulin.formatted(.number.precision(.fractionLength(0...1)))) U")
            Text(summary)
                .font(.system(.footnote, design: .serif).italic())
                .foregroundStyle(Theme.soft)
                .padding(.top, 4)
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            TornEdge().fill(Theme.paper).rotationEffect(.degrees(180)).frame(height: 5).padding(.horizontal, -20).offset(y: 12)
        }
    }

    private func line(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(Theme.mono(.subheadline, weight: .semibold))
            DottedLeader()
            Text(value).font(Theme.mono(.subheadline, weight: .semibold))
        }
        .accessibilityElement(children: .combine)
    }
}

/// Previous/next day buttons around a compact date picker.
private struct DayPicker: View {
    @Binding var date: Date
    let canGoForward: Bool
    let onMove: (Int) -> Void

    var body: some View {
        HStack {
            Button("Previous Day", systemImage: "chevron.left") { onMove(-1) }
                .labelStyle(.iconOnly)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
            Spacer()
            DatePicker("Day", selection: $date, in: ...Date.now, displayedComponents: .date)
                .labelsHidden()
            Spacer()
            Button("Next Day", systemImage: "chevron.right") { onMove(1) }
                .labelStyle(.iconOnly)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
                .disabled(!canGoForward)
        }
        .buttonStyle(.borderless)
        .font(.title3.weight(.semibold))
    }
}

#Preview {
    NavigationStack {
        LogView()
    }
    .environment(LogViewModel(context: PersistenceController.preview.container.viewContext))
    .environment(SettingsStore())
    .environment(HealthGlucoseImporter())
}
