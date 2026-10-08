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
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
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
                } footer: {
                    Text(summary)
                }
            }
        }
        .listStyle(.insetGrouped)
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
        var rows: [LogRow] = []
        if filter == .all || filter == .glucose {
            rows += viewModel.glucoseReadings.map { reading in
                LogRow(
                    object: reading,
                    timestamp: reading.timestamp,
                    icon: "drop.fill",
                    color: settings.zone(for: reading.value).color,
                    title: settings.formattedGlucose(reading.value),
                    detail: reading.context,
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
        return "\(count) \(count == 1 ? "entry" : "entries")"
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

private struct LogRowView: View {
    let row: LogRow

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: row.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(row.color.gradient, in: .circle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.body.weight(.medium))
                if let detail = row.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let notes = row.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            if let timestamp = row.timestamp {
                Text(timestamp, format: .dateTime.hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
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
}
