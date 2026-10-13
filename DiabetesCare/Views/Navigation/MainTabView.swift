//
//  MainTabView.swift
//  DiabetesCare
//
//  Created by Angad Kumar on 3/11/26.
//

import SwiftUI
import CoreData

struct MainTabView: View {
    @State private var selection: MainTab = .today
    // Creating these is cheap (they load data when their screen appears),
    // so it's fine that SwiftUI may evaluate this more than once.
    @State private var homeViewModel = HomeViewModel(context: PersistenceController.shared.container.viewContext)
    @State private var logViewModel = LogViewModel(context: PersistenceController.shared.container.viewContext)
    @State private var insightsViewModel = InsightsViewModel(context: PersistenceController.shared.container.viewContext)
    @State private var reportsViewModel = ReportsViewModel(context: PersistenceController.shared.container.viewContext)
    @State private var router = AppRouter.shared
    /// A sheet opened from outside the app (a widget, Siri, a notification).
    @State private var routedSheet: RoutedSheet?

    enum RoutedSheet: Identifiable {
        case weeklyRecap
        case term(GlossaryTerm)
        case guide(Guide)
        case supplies
        case schoolCard

        var id: String {
            switch self {
            case .weeklyRecap: "recap"
            case .term(let term): "term." + term.id
            case .guide(let guide): "guide." + guide.rawValue
            case .supplies: "supplies"
            case .schoolCard: "schoolCard"
            }
        }
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Today", systemImage: "house", value: .today) {
                NavigationStack {
                    HomeView(onShowAllActivity: showLog, onShowTrends: showTrends)
                        .environment(homeViewModel)
                        .growthDestinations()
                        .kitDestinations()
                }
            }

            Tab("Log", systemImage: "list.bullet.clipboard", value: .log) {
                NavigationStack {
                    LogView()
                        .environment(logViewModel)
                }
            }

            Tab("Trends", systemImage: "chart.xyaxis.line", value: .trends) {
                NavigationStack {
                    TrendsView()
                        .environment(insightsViewModel)
                        .environment(reportsViewModel)
                }
            }

            Tab("Learn", systemImage: "book", value: .learn) {
                NavigationStack {
                    LearnView()
                }
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onChange(of: router.pending, initial: true) { _, route in
            if let route { handle(route) }
        }
        .sheet(item: $routedSheet) { sheet in
            switch sheet {
            case .weeklyRecap:
                NavigationStack { WeeklyRecapView().doneButton() }
            case .term(let term):
                GlossaryTermSheet(term: term)
            case .guide(let guide):
                GuideSheet(guide: guide)
            case .supplies:
                NavigationStack { SuppliesView().doneButton() }
            case .schoolCard:
                NavigationStack { SchoolCardView().doneButton() }
            }
        }
    }

    /// Acts on a route from outside the app, then clears it.
    private func handle(_ route: AppRouter.Route) {
        router.pending = nil
        routedSheet = nil
        switch route {
        case .logGlucose:
            selection = .today
            homeViewModel.showAddGlucoseSheet = true
        case .logCarbs:
            selection = .today
            homeViewModel.showAddCarbSheet = true
        case .getHelp:
            selection = .today
            homeViewModel.showKidHelp = true
        case .trends:
            selection = .trends
        case .weeklyRecap:
            routedSheet = .weeklyRecap
        case .glossaryTerm(let id):
            if let term = Glossary.shared.term(id) { routedSheet = .term(term) }
        case .guide(let id):
            if let guide = Guide(rawValue: id) { routedSheet = .guide(guide) }
        case .supplies:
            routedSheet = .supplies
        case .schoolCard:
            routedSheet = .schoolCard
        }
    }

    private func showLog() {
        logViewModel.selectedDate = Date()
        logViewModel.fetchEntriesForDate(logViewModel.selectedDate)
        selection = .log
    }

    private func showTrends() {
        selection = .trends
    }
}

/// The tabs on a parent's or caregiver's phone: the people they follow,
/// Learn and Settings.
struct CaregiverTabView: View {
    var body: some View {
        TabView {
            Tab("Family", systemImage: "person.2.fill") {
                NavigationStack {
                    FamilyHomeView()
                }
            }
            Tab("Learn", systemImage: "book") {
                NavigationStack {
                    LearnView()
                }
            }
            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    MainTabView()
        .environment(\.managedObjectContext, context)
        .environment(MonitorViewModel(context: context))
        .environment(SettingsStore())
        .environment(HealthGlucoseImporter())
}
