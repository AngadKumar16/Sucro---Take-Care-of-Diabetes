//
//  HomeView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import Charts

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var showingMonitor = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
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
                            // Handle event tap - could show detail modal
                            print("Tapped event: \(event.title)")
                        }
                    )
                    
                    // Quick Action Buttons
                    QuickActionButtonsView(
                        onLogMeal: {
                            // Navigate to meal logging
                            print("Log meal tapped")
                        },
                        onQuickBolus: {
                            // Show quick bolus dialog
                            print("Quick bolus tapped")
                        },
                        onChangeSite: {
                            // Navigate to site change
                            print("Change site tapped")
                        }
                    )
                    
                    // Recent Timeline Cards
                    RecentTimelineCardsView(
                        events: viewModel.timelineEvents,
                        onEventTap: { event in
                            print("Timeline event tapped: \(event.title)")
                        },
                        onEventEdit: { event in
                            print("Edit event: \(event.title)")
                        },
                        onEventDelete: { event in
                            print("Delete event: \(event.title)")
                        },
                        onAddNote: { event in
                            print("Add note to event: \(event.title)")
                        }
                    )
                    
                    // Site Snapshot
                    SiteSnapshotView(
                        lastSiteChange: viewModel.lastSiteChange,
                        onChangeSite: {
                            print("Change site from snapshot")
                        }
                    )
                    
                    // Reminders & Suggestions
                    RemindersView(
                        reminders: viewModel.upcomingReminders,
                        suggestion: viewModel.smartSuggestion,
                        onSnooze: { reminder in
                            print("Snooze reminder: \(reminder.title)")
                        },
                        onComplete: { reminder in
                            print("Complete reminder: \(reminder.title)")
                        }
                    )
                    
                    // Today's Summary (keep existing for now)
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
            .fullScreenCover(isPresented: $showingMonitor) {
                // This would navigate to the Monitor page
                Text("Monitor View - Full Implementation Coming Soon")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .padding()
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
