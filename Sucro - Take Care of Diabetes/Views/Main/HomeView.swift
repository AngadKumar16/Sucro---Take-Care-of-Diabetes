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
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var showingMonitor = false
    
    var body: some View {
        NavigationView {
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
                        batteryLevel: viewModel.batteryLevel,
                        lastSyncTime: viewModel.lastSyncTime,
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
                        onSnooze: { reminder in
                            viewModel.snoozeReminder(reminder)
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
                                    .fontWeight(.bold)
                                Text("Insulin Units")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack {
                                Text("\(Int(viewModel.todayCarbTotal))g")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Carbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
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
            // MARK: - Sheets
            .sheet(isPresented: $viewModel.showAddCarbSheet) {
                AddCarbView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $viewModel.showQuickBolusSheet) {
                QuickBolusView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $viewModel.showAddSiteChangeSheet) {
                AddSiteChangeView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $viewModel.showEventDetail) {
                if let event = viewModel.selectedEvent {
                    EventDetailView(
                        event: event,
                        onEdit: {
                            viewModel.editEvent(event)
                            viewModel.showEventDetail = false
                        },
                        onDelete: {
                            viewModel.deleteEvent(event)
                            viewModel.showEventDetail = false
                        },
                        onAddNote: {
                            viewModel.showEventDetail = false
                            viewModel.showAddNote(for: event)
                        }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showNoteInput) {
                NoteInputView(
                    eventTitle: viewModel.noteEventTitle,
                    onSave: { note in
                        viewModel.saveNote(note)
                    }
                )
            }
            .fullScreenCover(isPresented: $showingMonitor) {
                MonitorView()
                    .environmentObject(viewModel)
            }
        }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    HomeView()
        .environmentObject(HomeViewModel(context: PersistenceController.preview.container.viewContext))
}
