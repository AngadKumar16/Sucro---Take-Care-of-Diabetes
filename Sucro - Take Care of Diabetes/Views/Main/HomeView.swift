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

    /// How much of the thread is on screen, and where it starts.
    @State private var zoom: ThreadZoom = .day
    @State private var scrollStart = ThreadView.start(showing: .day, at: Date())

    var body: some View {
        ScrollView {
            // Re-render each minute so "now", ages and stale styling keep up.
            TimelineView(.periodic(from: .now, by: 60)) { context in
                content(now: context.date)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .instrumentBackground()
        .navigationTitle("Today")
        .onAppear(perform: viewModel.fetchLatestData)
        // A new reading moves the thread along if it was showing now.
        .onChange(of: viewModel.latestGlucoseReading?.timestamp) { _, _ in
            let now = Date()
            if scrollStart.addingTimeInterval(zoom.duration) >= now.addingTimeInterval(-30 * 60) {
                withAnimation(.smooth) { scrollStart = ThreadView.start(showing: zoom, at: now) }
            }
        }
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

    private func content(now: Date) -> some View {
        // While the thread shows now, the view keeps up with it: anything
        // logged since the thread last moved still counts as in view.
        let visibleEnd = scrollStart.addingTimeInterval(zoom.duration)
        let followsNow = visibleEnd >= now.addingTimeInterval(-30 * 60)
        // `now` ticks once a minute, so reach past it to include an entry
        // logged a few seconds ago.
        let window = ThreadWindow(start: scrollStart, end: followsNow ? now.addingTimeInterval(ThreadView.future) : visibleEnd)
        let visibleEvents = viewModel.threadEvents.filter { window.contains($0.timestamp) }

        return VStack(spacing: 16) {
            if case .lowGlucose(let mgdl) = viewModel.criticalAlert {
                LowTreatmentCard(
                    mgdl: mgdl,
                    recheckAt: viewModel.lowRecheckAt,
                    treatedGrams: viewModel.lowTreatmentGrams,
                    onLogTreatment: viewModel.logFastCarbs(grams:),
                    onLogCarbs: viewModel.handleCriticalAlertAction,
                    onLogGlucose: viewModel.logGlucose,
                    onDismiss: viewModel.dismissCriticalAlert
                )
            } else if let criticalAlert = viewModel.criticalAlert {
                CriticalAlertBanner(
                    alert: criticalAlert,
                    onDismiss: viewModel.dismissCriticalAlert,
                    onAction: viewModel.handleCriticalAlertAction
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                if let reading = viewModel.latestGlucoseReading {
                    // Tapping the latest reading brings the thread back to now.
                    Button {
                        withAnimation(.smooth) { scrollStart = ThreadView.start(showing: zoom, at: now) }
                    } label: {
                        ReadingRingCard(reading: reading, insulinOnBoard: viewModel.insulinOnBoard, now: now)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Shows now on the thread")
                } else {
                    noReadings
                }
                ThreadView(
                    samples: viewModel.threadSamples,
                    events: viewModel.threadEvents,
                    reminders: viewModel.upcomingReminders,
                    now: now,
                    zoom: $zoom,
                    scrollStart: $scrollStart
                )
            }
            .card()

            InViewSummary(window: window, samples: viewModel.threadSamples, events: viewModel.threadEvents)

            QuickActionButtonsView(
                onLogMeal: viewModel.logMeal,
                onQuickBolus: viewModel.quickBolus,
                onChangeSite: viewModel.changeSite,
                onLogPreset: viewModel.logMeal(preset:)
            )

            // The events list follows the thread: it shows what's in view.
            RecentTimelineCardsView(
                events: Array(visibleEvents.prefix(20)),
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
                history: viewModel.siteHistory,
                onChangeSite: viewModel.changeSite
            )
        }
    }

    private var noReadings: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("No Readings Yet")
                    .font(.headline)
                Text("Log a fingerstick reading to start the thread.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Log Glucose", systemImage: "plus", action: viewModel.logGlucose)
                .buttonStyle(.borderedProminent)
                .foregroundStyle(Theme.onAccent)
        }
        // A dose can be logged before any reading; still show what's active.
        .overlay(alignment: .bottomLeading) {
            if viewModel.insulinOnBoard > 0 {
                InsulinOnBoardLabel(units: viewModel.insulinOnBoard)
                    .offset(y: 22)
            }
        }
        .padding(.bottom, viewModel.insulinOnBoard > 0 ? 22 : 0)
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
