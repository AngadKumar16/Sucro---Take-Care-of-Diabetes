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
    @Environment(SettingsStore.self) private var settings

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
            .fontDesign(.rounded)
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

            dateline(now: now)

            if let reading = viewModel.latestGlucoseReading {
                VStack(alignment: .leading, spacing: 12) {
                    // Tapping the latest reading brings the thread back to now.
                    Button {
                        withAnimation(.smooth) { scrollStart = ThreadView.start(showing: zoom, at: now) }
                    } label: {
                        ReadingRingCard(reading: reading, insulinOnBoard: viewModel.insulinOnBoard, now: now)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Shows now on the thread")
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
            } else {
                // An empty chart says nothing; a meter to set says what to do.
                FirstReadingCard(onLog: logFirstReading, onMoreDetails: viewModel.logGlucose)
                    .overlay(alignment: .topLeading) {
                        // A dose can be logged before any reading.
                        if viewModel.insulinOnBoard > 0 {
                            InsulinOnBoardLabel(units: viewModel.insulinOnBoard)
                                .padding(12)
                        }
                    }
            }

            QuickActionButtonsView(
                onLogMeal: viewModel.logMeal,
                onQuickBolus: viewModel.quickBolus,
                onChangeSite: viewModel.changeSite,
                onLogPreset: viewModel.logMeal(preset:),
                todayCarbs: viewModel.todayCarbTotal,
                todayInsulin: viewModel.todayInsulinTotal,
                nextSite: SiteLocation.suggested(
                    current: SiteLocation(stored: viewModel.lastSiteChange?.location),
                    history: viewModel.siteHistory
                )
            )

            // The events list follows the thread: it shows what's in view.
            // Before anything is logged it would only be an empty box.
            if viewModel.latestGlucoseReading != nil || !visibleEvents.isEmpty {
                RecentTimelineCardsView(
                    events: Array(visibleEvents.prefix(20)),
                    onShowAll: onShowAllActivity,
                    onEventTap: viewModel.showEventDetails,
                    onEventEdit: viewModel.editEvent,
                    onEventDelete: viewModel.deleteEvent,
                    onAddNote: viewModel.showAddNote(for:)
                )
            }

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

    /// A hello with the person's name when they've given one, and the date.
    private func dateline(now: Date) -> some View {
        let name = settings.userName.trimmingCharacters(in: .whitespaces)
        return VStack(alignment: .leading, spacing: 2) {
            Text(name.isEmpty ? greeting(at: now) : "\(greeting(at: now)), \(name)")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.subheadline)
                .foregroundStyle(Theme.soft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func greeting(at date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        default: "Good evening"
        }
    }

    private func logFirstReading(_ mgdl: Double) {
        let now = Date()
        logViewModel.addGlucoseReading(
            value: mgdl,
            unit: "mg/dL",
            context: GlucoseContext.likely(at: now).rawValue,
            notes: nil,
            timestamp: now
        )
        withAnimation(.smooth) { viewModel.fetchLatestData() }
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
