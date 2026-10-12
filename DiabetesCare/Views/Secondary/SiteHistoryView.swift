//
//  SiteHistoryView.swift
//  DiabetesCare
//
//  Site rotation at a glance: which sites have rested longest, and every
//  site change with how long it was worn.
//

import SwiftUI
import CoreData

struct SiteHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(sortDescriptors: [SortDescriptor(\SiteChange.timestamp, order: .reverse)])
    private var siteChanges: FetchedResults<SiteChange>

    @State private var editOperation: DraftOperation<NSManagedObject>?
    @State private var pendingDelete: SiteChange?
    @State private var side: BodySide = .front
    @State private var actionError: String?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            content(now: context.date)
        }
        .instrumentBackground()
        .navigationTitle("Site History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editOperation) { operation in
            EntryEditorView(operation: operation)
        }
        .confirmationDialog(
            "Delete Site Change?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { change in
            Button("Delete", role: .destructive) { delete(change) }
        } message: { _ in
            Text("This can't be undone.")
        }
        .errorAlert($actionError)
    }

    private func content(now: Date) -> some View {
        let changes = siteChanges.compactMap { change in change.rotationChange.map { (change, $0) } }
        let lastUsed = SiteRotation.lastUsed(changes.map(\.1))
        let wear = SiteRotation.wear(changes.map(\.1))
        let current = changes.first?.1.location

        return List {
            if changes.isEmpty {
                ContentUnavailableView(
                    "No Site Changes Yet",
                    systemImage: "figure.stand",
                    description: Text("Log a site change from Today and it shows up here.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    VStack(spacing: 12) {
                        Picker("Side", selection: $side) {
                            ForEach(BodySide.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        BodyMap(side: side, current: current, history: lastUsed,
                                suggested: SiteLocation.suggested(current: current, history: lastUsed), now: now)
                            .frame(height: 220)
                            .accessibilityHidden(true)
                        BodyMapKey()
                    }
                    .padding(.vertical, 6)
                    ForEach(SiteRotation.restOrder(lastUsed), id: \.self) { site in
                        LabeledContent(site.spokenName, value: restText(site, lastUsed: lastUsed, current: current, now: now))
                    }
                } header: {
                    Text("Rest")
                } footer: {
                    Text("Sites that have rested longest are at the top. Rotating gives skin time to heal.")
                }
                .listRowBackground(Theme.card)

                Section("Changes") {
                    ForEach(Array(zip(changes, wear)), id: \.0.0.objectID) { pair, wear in
                        let change = pair.0
                        Button {
                            edit(change)
                        } label: {
                            SiteHistoryRow(change: change, wear: wear, now: now)
                        }
                        .foregroundStyle(.primary)
                        .swipeActions(edge: .trailing) {
                            Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = change }
                        }
                        .contextMenu {
                            Button("Edit", systemImage: "pencil") { edit(change) }
                            Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = change }
                        }
                        .accessibilityHint("Edits this site change")
                    }
                }
                .listRowBackground(Theme.card)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func restText(_ site: SiteLocation, lastUsed: [SiteLocation: Date], current: SiteLocation?, now: Date) -> String {
        if site == current { return String(localized: "In use") }
        guard let used = lastUsed[site] else { return String(localized: "Not used yet") }
        let days = Calendar.current.dateComponents([.day], from: used, to: now).day ?? 0
        return days == 1 ? String(localized: "1 day") : String(localized: "\(days) days")
    }

    private func edit(_ change: SiteChange) {
        editOperation = DraftOperation(
            withExistingObject: change,
            inParentContext: viewContext,
            onSave: { ReminderService.shared.refresh(context: viewContext) }
        )
    }

    private func delete(_ change: SiteChange) {
        if DataService.shared.delete(change.objectID, context: viewContext) {
            ReminderService.shared.refresh(context: viewContext)
        } else {
            actionError = "This site change couldn't be deleted. Please try again."
        }
    }
}

private struct SiteHistoryRow: View {
    @ObservedObject var change: SiteChange
    let wear: SiteRotation.Wear
    let now: Date

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(wear.change.location.spokenName)
                    .font(.headline)
                Text(wear.change.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(Theme.soft)
                Text(wornText)
                    .font(.subheadline)
                    .foregroundStyle(wear.wasOverdue(now: now) ? Theme.amber : Theme.soft)
            }
            Spacer(minLength: 0)
            if let data = change.photo, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(.rect(cornerRadius: 8))
                    .accessibilityLabel("Site photo")
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var wornText: String {
        let days = wear.wornDays(now: now)
        let worn = days < 1
            ? String(localized: "\(max(1, Int((days * 24).rounded()))) h")
            : String(localized: "\(days.formatted(.number.precision(.fractionLength(0...1)))) d")
        let due = String(localized: "change every \(wear.change.location.rotationDays) d")
        return wear.endedAt == nil ? String(localized: "In use \(worn), \(due)") : String(localized: "Worn \(worn), \(due)")
    }
}

#Preview {
    NavigationStack {
        SiteHistoryView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    .environment(SettingsStore())
}
