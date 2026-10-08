//
//  HomeView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData
import Charts

struct HomeView: View {
    @Environment(HomeViewModel.self) private var viewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(HealthGlucoseImporter.self) private var healthImporter
    @Environment(\.managedObjectContext) private var viewContext

    /// Switches to the Log tab.
    let onShowAllActivity: () -> Void
    /// Switches to the Trends tab.
    let onShowTrends: () -> Void

    // The glucose and carb forms need a LogViewModel; Home only has a
    // HomeViewModel, so it keeps one for them.
    @State private var logViewModel = LogViewModel(
        context: PersistenceController.shared.container.viewContext
    )

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let criticalAlert = viewModel.criticalAlert {
                    CriticalAlertBanner(
                        alert: criticalAlert,
                        onDismiss: viewModel.dismissCriticalAlert,
                        onAction: viewModel.handleCriticalAlertAction
                    )
                }

                GlucoseHeroView(
                    glucoseReading: viewModel.latestGlucoseReading,
                    insulinOnBoard: viewModel.insulinOnBoard,
                    onTap: onShowTrends,
                    onLogGlucose: viewModel.logGlucose
                )

                QuickActionButtonsView(
                    onLogMeal: viewModel.logMeal,
                    onQuickBolus: viewModel.quickBolus,
                    onChangeSite: viewModel.changeSite,
                    onLogPreset: viewModel.logMeal(preset:)
                )

                TodaySummaryView(
                    insulinUnits: viewModel.todayInsulinTotal,
                    carbGrams: viewModel.todayCarbTotal,
                    readingCount: viewModel.todayReadingCount
                )

                MiniTimelineView(
                    glucoseReadings: viewModel.recentReadings,
                    events: viewModel.timelineEvents,
                    window: HomeViewModel.chartWindow,
                    onExpand: onShowTrends
                )

                RecentTimelineCardsView(
                    events: viewModel.timelineEvents,
                    onShowAll: onShowAllActivity,
                    onEventTap: viewModel.showEventDetails,
                    onEventEdit: viewModel.editEvent,
                    onEventDelete: viewModel.deleteEvent,
                    onAddNote: viewModel.showAddNote(for:)
                )

                RemindersView(
                    reminders: viewModel.upcomingReminders,
                    suggestion: viewModel.smartSuggestion,
                    onSnooze: viewModel.snoozeReminder,
                    onComplete: viewModel.completeReminder
                )

                SiteSnapshotView(
                    lastSiteChange: viewModel.lastSiteChange,
                    onChangeSite: viewModel.changeSite
                )
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Today")
        .onAppear(perform: viewModel.fetchLatestData)
        .refreshable {
            await healthImporter.sync()
            viewModel.fetchLatestData()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.fetchLatestData() }
        }
        // Entries also change from Log, the edit sheets and Health imports.
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext)) { _ in
            viewModel.fetchLatestData()
        }
        .task {
            await viewModel.refreshWhileVisible()
        }
        // MARK: - Sheets
        .sheet(isPresented: Bindable(viewModel).showAddGlucoseSheet, onDismiss: viewModel.fetchLatestData) {
            AddGlucoseView()
                .environment(logViewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showAddCarbSheet, onDismiss: viewModel.fetchLatestData) {
            AddCarbView()
                .environment(logViewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showQuickBolusSheet) {
            QuickBolusView()
                .environment(viewModel)
        }
        .sheet(isPresented: Bindable(viewModel).showAddSiteChangeSheet) {
            AddSiteChangeView()
                .environment(viewModel)
        }
        .sheet(item: Bindable(viewModel).detailEvent) { event in
            EventDetailView(
                event: event,
                onEdit: { viewModel.editEvent(event) },
                onDelete: { viewModel.deleteEvent(event) },
                onAddNote: {
                    viewModel.detailEvent = nil
                    viewModel.showAddNote(for: event)
                }
            )
        }
        .sheet(isPresented: Bindable(viewModel).showNoteInput) {
            NoteInputView(eventTitle: viewModel.noteEventTitle, onSave: viewModel.saveNote)
        }
        .sheet(item: Bindable(viewModel).editOperation) { operation in
            EntryEditorView(operation: operation)
        }
        // MARK: - Alert Sheets
        .sheet(isPresented: Bindable(viewModel).showKetoneInfoSheet) {
            KetoneInfoView()
        }
        .sheet(isPresented: Bindable(viewModel).showTroubleshootingSheet) {
            DeviceTroubleshootingView()
        }
    }
}

/// Today's totals: insulin, carbs and how many readings were logged.
struct TodaySummaryView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let insulinUnits: Double
    let carbGrams: Double
    let readingCount: Int

    var body: some View {
        // Side by side normally; stacked at accessibility text sizes so
        // the numbers never wrap mid-word.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 0))
        layout {
            SummaryTile(
                value: insulinUnits.formatted(.number.precision(.fractionLength(0...1))),
                unit: "U",
                label: "Insulin"
            )
            Divider()
            SummaryTile(
                value: carbGrams.formatted(.number.precision(.fractionLength(0))),
                unit: "g",
                label: "Carbs"
            )
            Divider()
            SummaryTile(value: "\(readingCount)", unit: nil, label: readingCount == 1 ? "Reading" : "Readings")
        }
        .card(padding: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today: \(insulinUnits.formatted(.number.precision(.fractionLength(0...1)))) units of insulin, \(Int(carbGrams)) grams of carbs, \(readingCount) glucose readings")
    }
}

private struct SummaryTile: View {
    let value: String
    let unit: String?
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .monospacedDigit()
                if let unit {
                    Text(unit)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    NavigationStack {
        HomeView(onShowAllActivity: {}, onShowTrends: {})
    }
    .environment(HomeViewModel(context: context))
    .environment(SettingsStore())
    .environment(HealthGlucoseImporter())
}
