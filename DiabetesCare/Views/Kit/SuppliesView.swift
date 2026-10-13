//
//  SuppliesView.swift
//  DiabetesCare
//
//  Count what's on hand, get a nudge before it runs out, and keep track of
//  when each open pen or vial expires.
//

import SwiftUI

struct SuppliesView: View {
    @State private var kit = KitStore.shared
    @State private var showOpenInsulin = false

    private var untracked: [SupplyKind] {
        SupplyKind.allCases.filter { kind in kit.supply(kind) == nil }
    }

    var body: some View {
        List {
            Section {
                if kit.supplies.isEmpty {
                    Text("Add the supplies you use and keep the counts up to date. Site changes use up sets, pods and reservoirs automatically.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ForEach(kit.supplies) { supply in
                    SupplyRow(supply: supply)
                        .swipeActions {
                            Button("Stop Tracking", systemImage: "minus.circle", role: .destructive) {
                                withAnimation { kit.stopTracking(supply.kind) }
                            }
                        }
                }
                if !untracked.isEmpty {
                    Menu {
                        ForEach(untracked) { kind in
                            Button(kind.name, systemImage: kind.symbol) {
                                withAnimation { kit.setCount(10, for: kind) }
                            }
                        }
                    } label: {
                        Label("Track a Supply", systemImage: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("trackSupply")
                }
            } header: {
                Text("On Hand")
            } footer: {
                Text("You'll get a reminder when something reaches its reorder point.")
            }
            .listRowBackground(Theme.card)

            Section {
                ForEach(kit.opened) { item in
                    OpenedRow(item: item)
                        .swipeActions {
                            Button("Done", systemImage: "checkmark", role: .destructive) {
                                withAnimation { kit.remove(item) }
                            }
                        }
                }
                Button("Opened a New Pen or Vial", systemImage: "plus.circle.fill") { showOpenInsulin = true }
                    .accessibilityIdentifier("openInsulin")
            } header: {
                Text("Open Insulin")
            } footer: {
                Text("Most insulin lasts 28 days once opened. Check the leaflet for yours. You'll get a reminder the morning it expires.")
            }
            .listRowBackground(Theme.card)
        }
        .instrumentBackground()
        .navigationTitle("Supplies")
        .sheet(isPresented: $showOpenInsulin) {
            OpenInsulinForm { name, date, days in
                kit.open(name: name, openedAt: date, lastsDays: days)
            }
        }
    }
}

private struct SupplyRow: View {
    let supply: Supply
    @State private var kit = KitStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(supply.kind.name, systemImage: supply.kind.symbol)
                    .font(.body.weight(.medium))
                Spacer()
                if supply.isLow {
                    Text("Reorder")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.card)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.amber, in: .capsule)
                }
            }
            Stepper(value: Binding(get: { supply.count }, set: { kit.setCount($0, for: supply.kind) }), in: 0...999) {
                Text("\(supply.count) left")
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(supply.count)))
            }
            Stepper(value: Binding(get: { supply.lowAt }, set: { kit.setLowAt($0, for: supply.kind) }), in: 0...200) {
                Text("Remind me at \(supply.lowAt)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.smooth, value: supply.count)
        .accessibilityElement(children: .contain)
    }
}

private struct OpenedRow: View {
    let item: OpenedInsulin

    var body: some View {
        let left = item.daysLeft()
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body.weight(.medium))
                Text("Opened \(item.openedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(left <= 0 ? String(localized: "Expired") : left == 1 ? String(localized: "1 day left") : String(localized: "\(left) days left"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(left <= 3 ? Theme.vermilion : Theme.green)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct OpenInsulinForm: View {
    let onSave: (String, Date, Int) -> Void
    @State private var name = String(localized: "Insulin pen")
    @State private var openedAt = Date()
    @State private var days = 28

    var body: some View {
        EntryForm(title: "Opened Insulin", canSave: !name.trimmingCharacters(in: .whitespaces).isEmpty, hasChanges: false) {
            onSave(name, openedAt, days)
            return true
        } content: {
            Section {
                TextField("Name", text: $name)
                DatePicker("Opened", selection: $openedAt, in: ...Date.now, displayedComponents: .date)
                Stepper("Lasts \(days) days", value: $days, in: 7...60)
            }
            .listRowBackground(Theme.card)
        }
    }
}

#Preview {
    NavigationStack { SuppliesView() }
}
