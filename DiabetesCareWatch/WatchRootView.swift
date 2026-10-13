//
//  WatchRootView.swift
//  DiabetesCare Watch
//

import Charts
import SwiftUI

struct WatchRootView: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        NavigationStack {
            TabView {
                GlanceView()
                ActionsView()
                LowStepsView()
            }
            .tabViewStyle(.verticalPage)
        }
        .overlay(alignment: .bottom) {
            if let status = store.status {
                Text(status)
                    .font(.footnote)
                    .padding(8)
                    .background(.thinMaterial, in: .capsule)
                    .task {
                        try? await Task.sleep(for: .seconds(3))
                        store.status = nil
                    }
            }
        }
    }
}

/// The latest reading, big, with the last three hours.
struct GlanceView: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            if let snapshot = store.snapshot, let latest = snapshot.latest {
                let stale = snapshot.isStale(at: context.date)
                let color = stale ? Color.gray : snapshot.zone(latest.mgdl).color
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(snapshot.value(latest.mgdl))
                            .font(.system(size: 50, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(color)
                            .contentTransition(.numericText(value: latest.mgdl))
                        if let symbol = snapshot.trendSymbol, !stale {
                            Image(systemName: symbol)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(color)
                        }
                    }
                    Text("\(stale ? String(localized: "Last reading") : snapshot.zone(latest.mgdl).name) · \(latest.date, style: .relative)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Chart(snapshot.recent, id: \.date) { point in
                        LineMark(x: .value("Time", point.date), y: .value("Glucose", snapshot.display(point.mgdl)))
                            .foregroundStyle(color)
                            .interpolationMethod(.monotone)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 50)
                    if let recheck = snapshot.lowRecheckAt, recheck > context.date {
                        Label {
                            Text("Recheck \(recheck, style: .timer)")
                        } icon: {
                            Image(systemName: "timer")
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.orange)
                    } else if snapshot.insulinOnBoard >= 0.05 {
                        Text("\(snapshot.insulinOnBoard.formatted(.number.precision(.fractionLength(1)))) U active (estimate)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            } else {
                ContentUnavailableView("Open DiabetesCare on Your iPhone", systemImage: "iphone",
                                       description: Text("Your glucose shows up here once your phone has a reading."))
            }
        }
        .navigationTitle("Glucose")
    }
}

/// Quick logging from the wrist.
struct ActionsView: View {
    @Environment(WatchStore.self) private var store
    @State private var carbs = 30.0
    @State private var glucose = 120.0
    @State private var showCarbs = false
    @State private var showGlucose = false

    var body: some View {
        List {
            Button {
                store.send(.logFastSugar, grams: 15, done: String(localized: "Logged 15 g. Recheck in 15 min."))
            } label: {
                Label("Had 15 g Sugar", systemImage: "cube.fill")
            }
            .tint(.orange)
            Button { showGlucose = true } label: {
                Label("Log Glucose", systemImage: "drop.fill")
            }
            Button { showCarbs = true } label: {
                Label("Log Carbs", systemImage: "fork.knife")
            }
        }
        .navigationTitle("Log")
        .sheet(isPresented: $showCarbs) {
            CrownPicker(title: "Carbs", unit: "g", value: $carbs, range: 1...200, step: 1) {
                store.send(.logCarbs, grams: carbs, done: String(localized: "Logged \(Int(carbs)) g carbs."))
            }
        }
        .sheet(isPresented: $showGlucose) {
            CrownPicker(title: "Glucose", unit: store.snapshot?.unit ?? "mg/dL", value: $glucose,
                        range: store.snapshot?.isMmol == true ? 1.1...33.3 : 20...600,
                        step: store.snapshot?.isMmol == true ? 0.1 : 1) {
                let mgdl = store.snapshot?.isMmol == true ? glucose * 18.0182 : glucose
                store.send(.logGlucose, mgdl: mgdl, done: String(localized: "Logged."))
            }
        }
    }
}

/// Turn the Digital Crown to pick a number, then save.
struct CrownPicker: View {
    let title: LocalizedStringKey
    let unit: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.headline)
            Text(value.formatted(.number.precision(.fractionLength(step < 1 ? 1 : 0))))
                .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                .focusable()
                .digitalCrownRotation($value, from: range.lowerBound, through: range.upperBound, by: step, sensitivity: .medium)
            Text(unit).font(.footnote).foregroundStyle(.secondary)
            Button("Save") {
                onSave()
                dismiss()
            }
            .tint(.green)
        }
    }
}

/// The rule of 15, for a low.
struct LowStepsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Label("Feeling low?", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text("1. Have 15 g of fast sugar: juice, glucose tabs or regular soda.")
                Text("2. Wait 15 minutes, then check again.")
                Text("3. Still low? Repeat, and tell a grown-up.")
                Text("Can't swallow or passing out: call 911.")
                    .fontWeight(.semibold)
            }
            .font(.footnote)
        }
        .navigationTitle("Low Steps")
    }
}
