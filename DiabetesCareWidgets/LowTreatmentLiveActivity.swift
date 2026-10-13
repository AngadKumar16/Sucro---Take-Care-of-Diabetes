//
//  LowTreatmentLiveActivity.swift
//  DiabetesCareWidgets
//
//  The countdown to the 15-minute recheck after treating a low, on the
//  Lock Screen and in the Dynamic Island.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct LowTreatmentLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LowTreatmentAttributes.self) { context in
            LowTreatmentLockScreen(attributes: context.attributes, state: context.state)
                .padding()
                .activityBackgroundTint(Color(red: 0.97, green: 0.96, blue: 0.93))
                .activitySystemActionForegroundColor(.black)
                .widgetURL(URL(string: "diabetescare://get-help"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(Int(context.attributes.grams)) g", systemImage: "cube.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let mgdl = context.state.latestMgdl {
                        Text(context.attributes.value(mgdl))
                            .font(.title2.weight(.bold).monospacedDigit())
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    PhaseLine(state: context.state)
                        .font(.headline)
                }
            } compactLeading: {
                Image(systemName: context.state.phase == .recovered ? "checkmark.circle.fill" : "cube.fill")
                    .foregroundStyle(context.state.phase == .recovered ? .green : .orange)
            } compactTrailing: {
                CompactTrailing(state: context.state)
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: context.state.phase == .recovered ? "checkmark" : "timer")
                    .foregroundStyle(context.state.phase == .recovered ? .green : .orange)
            }
            .widgetURL(URL(string: "diabetescare://get-help"))
            .keylineTint(.orange)
        }
    }
}

private struct CompactTrailing: View {
    let state: LowTreatmentAttributes.ContentState

    var body: some View {
        switch state.phase {
        case .waiting:
            Text(timerInterval: Date.now...max(Date.now, state.recheckAt), countsDown: true)
                .monospacedDigit()
                .foregroundStyle(.orange)
        case .recheck:
            Text("Check").foregroundStyle(.orange)
        case .recovered:
            Text("OK").foregroundStyle(.green)
        }
    }
}

private struct PhaseLine: View {
    let state: LowTreatmentAttributes.ContentState

    var body: some View {
        switch state.phase {
        case .waiting:
            HStack {
                Text("Check glucose again in")
                Text(timerInterval: Date.now...max(Date.now, state.recheckAt), countsDown: true)
                    .monospacedDigit()
                    .fontWeight(.bold)
            }
        case .recheck:
            Text("Time to check your glucose again")
        case .recovered:
            Text("Back in range. Nice work.")
        }
    }
}

struct LowTreatmentLockScreen: View {
    let attributes: LowTreatmentAttributes
    let state: LowTreatmentAttributes.ContentState

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: state.phase == .recovered ? "checkmark.circle.fill" : "cube.fill")
                .font(.largeTitle)
                .foregroundStyle(state.phase == .recovered ? .green : .orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(state.phase == .recovered ? "Low treated" : "Treating a low · \(Int(attributes.grams)) g")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                PhaseLine(state: state)
                    .font(.headline)
                    .foregroundStyle(.black)
            }
            Spacer(minLength: 0)
            if let mgdl = state.latestMgdl {
                VStack(alignment: .trailing) {
                    Text(attributes.value(mgdl))
                        .font(.title.weight(.bold).monospacedDigit())
                        .foregroundStyle(mgdl >= attributes.targetLow ? .green : .red)
                    Text(attributes.unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
