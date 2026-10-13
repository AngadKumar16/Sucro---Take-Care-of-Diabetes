//
//  SharedIntents.swift
//  DiabetesCare (shared with the widgets)
//
//  Intents that widgets and controls trigger. They're compiled into both
//  the app and the widget extension so the widget can name them, but they
//  always run in the app: `LiveActivityIntent` runs in the app's process,
//  and the "open" intents launch the app. The work itself lives in the app
//  target, behind `#if !WIDGET_EXTENSION`.
//

#if os(iOS)
import AppIntents
import Foundation

/// Logs 15 g of fast-acting carbs for a low and starts the 15-minute
/// recheck countdown, right from a widget.
struct LogFastSugarIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Log Fast Sugar"
    static let description = IntentDescription("Logs 15 g of fast-acting carbs for a low and starts the 15-minute recheck.")

    @Parameter(title: "Grams", default: 15, inclusiveRange: (5, 60))
    var grams: Int

    init() {}
    init(grams: Int) { self.grams = grams }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        #if !WIDGET_EXTENSION
        await IntentActions.logFastSugar(grams: Double(grams))
        #endif
        return .result(dialog: "Logged \(grams) g. Check again in 15 minutes.")
    }
}

/// Opens the app on a screen. Used by controls and widget buttons.
struct OpenRouteIntent: AppIntent {
    static let title: LocalizedStringResource = "Open DiabetesCare"
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @Parameter(title: "Screen")
    var screen: AppScreen

    init() {}
    init(screen: AppScreen) { self.screen = screen }

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await IntentActions.open(screen)
        #endif
        return .result()
    }
}

enum AppScreen: String, AppEnum {
    case logCarbs
    case logGlucose
    case getHelp
    case trends

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Screen"
    static let caseDisplayRepresentations: [AppScreen: DisplayRepresentation] = [
        .logCarbs: DisplayRepresentation(title: "Log Carbs", image: .init(systemName: "fork.knife")),
        .logGlucose: DisplayRepresentation(title: "Log Glucose", image: .init(systemName: "drop")),
        .getHelp: DisplayRepresentation(title: "Get Help", image: .init(systemName: "hand.raised")),
        .trends: DisplayRepresentation(title: "Trends", image: .init(systemName: "chart.xyaxis.line")),
    ]
}
#endif
