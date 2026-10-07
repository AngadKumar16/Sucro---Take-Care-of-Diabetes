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
    @State private var showingMonitor = false

    // Dedicated VM for the carb-entry form presented from Home. AddCarbView
    // requires a LogViewModel in the environment; Home only has a HomeViewModel.
    @State private var carbLogViewModel = LogViewModel(
        context: PersistenceController.shared.container.viewContext
    )
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Critical Alert Banner
                if let criticalAlert = viewModel.criticalAlert {
                    CriticalAlertBanner(
                        alert: criticalAlert,
                        onDismiss: {
                            viewModel.dismissCriticalAlert()
                        },
                        onAction: {
                            viewModel.handleCriticalAlertAction()
                        }
                    )
                }
                
                // Hero Section with Glucose
                GlucoseHeroView(
                    glucoseReading: viewModel.latestGlucoseReading,
                    insulinOnBoard: viewModel.insulinOnBoard,
                    onTap: { showingMonitor = true }
                )
                
                // Mini CGM Timeline
                MiniTimelineView(
                    glucoseReadings: viewModel.recentReadings,
                    events: viewModel.timelineEvents,
                    onExpand: { showingMonitor = true },
                    onEventTap: { event in
                        viewModel.showEventDetails(event)
                    }
                )
                
                // Quick Action Buttons
                QuickActionButtonsView(
                    onLogMeal: {
                        viewModel.logMeal()
                    },
                    onQuickBolus: {
                        viewModel.quickBolus()
                    },
                    onChangeSite: {
                        viewModel.changeSite()
                    },
                    onLogPreset: { preset in
                        viewModel.logMeal(preset: preset)
                    }
                )
                
                // Recent Timeline Cards
                RecentTimelineCardsView(
                    events: viewModel.timelineEvents,
                    onEventTap: { event in
                        viewModel.showEventDetails(event)
                    },
                    onEventEdit: { event in
                        viewModel.editEvent(event)
                    },
                    onEventDelete: { event in
                        viewModel.deleteEvent(event)
                    },
                    onAddNote: { event in
                        viewModel.showAddNote(for: event)
                    }
                )
                
                // Site Snapshot
                SiteSnapshotView(
                    lastSiteChange: viewModel.lastSiteChange,
                    onChangeSite: {
                        viewModel.changeSite()
                    }
                )
                
                // Reminders & Suggestions
                RemindersView(
                    reminders: viewModel.upcomingReminders,
                    suggestion: viewModel.smartSuggestion,
                    onSnooze: { reminder, minutes in
                        viewModel.snoozeReminder(reminder, minutes: minutes)
                    },
                    onComplete: { reminder in
                        viewModel.completeReminder(reminder)
                    }
                )
                
                // Today's Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Summary")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(Int(viewModel.todayInsulinTotal))")
                                .font(.title2)
                                .bold()
                            Text("Insulin Units")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack {
                            Text("\(Int(viewModel.todayCarbTotal))g")
                                .font(.title2)
                                .bold()
                            Text("Carbs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 12))
                
                Spacer(minLength: 20)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Sucro")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.fetchLatestData()
        }
        .refreshable {
            viewModel.fetchLatestData()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.fetchLatestData() }
        }
        .task {
            await viewModel.refreshWhileVisible()
        }
        // MARK: - Sheets
        .sheet(isPresented: Bindable(viewModel).showAddCarbSheet, onDismiss: {
            viewModel.fetchLatestData()
        }) {
            AddCarbView()
                .environment(carbLogViewModel)
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
                onEdit: {
                    viewModel.editEvent(event)
                },
                onDelete: {
                    viewModel.deleteEvent(event)
                },
                onAddNote: {
                    viewModel.detailEvent = nil
                    viewModel.showAddNote(for: event)
                }
            )
        }
        .sheet(isPresented: Bindable(viewModel).showNoteInput) {
            NoteInputView(
                eventTitle: viewModel.noteEventTitle,
                onSave: { note in
                    viewModel.saveNote(note)
                }
            )
        }
        // MARK: - Edit Sheet
        .sheet(item: Bindable(viewModel).editOperation) { operation in
            DraftingView(operation: operation) { draft in
                if let carbEntry = draft as? CarbEntry {
                    EditCarbView(entry: carbEntry)
                } else if let insulinEntry = draft as? InsulinEntry {
                    EditInsulinView(entry: insulinEntry)
                } else if let siteChange = draft as? SiteChange {
                    EditSiteChangeView(entry: siteChange)
                }
            }
        }
        // MARK: - Alert Sheets
        .sheet(isPresented: Bindable(viewModel).showKetoneInfoSheet) {
            KetoneInfoView()
        }
        .sheet(isPresented: Bindable(viewModel).showTroubleshootingSheet) {
            DeviceTroubleshootingView()
        }
        .fullScreenCover(isPresented: $showingMonitor) {
            NavigationStack {
                MonitorView()
                    .doneButton()
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    HomeView()
        .environment(HomeViewModel(context: context))
        .environment(MonitorViewModel(context: context))
        .environment(SettingsStore())
}
