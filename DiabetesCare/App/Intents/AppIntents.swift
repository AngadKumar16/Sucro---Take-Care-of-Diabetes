//
//  AppIntents.swift
//  DiabetesCare
//
//  Siri and Shortcuts: "Check my glucose", "Log carbs", "I need help".
//  Logging insulin follows the same stage rules as the app, so a kid's
//  phone asks for a grown-up instead of logging.
//

import AppIntents
import CoreData
import SwiftUI

struct CheckGlucoseIntent: AppIntent {
    static let title: LocalizedStringResource = "Check My Glucose"
    static let description = IntentDescription("Says your latest glucose, its trend and how old it is.")

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let sentence = await IntentActions.glucoseSentence()
        let snapshot = await GlanceWriter.snapshot(context: PersistenceController.shared.container.viewContext, settings: .shared, now: .now)
        return .result(dialog: "\(sentence)") {
            GlanceSnippet(snapshot: snapshot)
        }
    }
}

struct LogCarbsIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Carbs"
    static let description = IntentDescription("Logs grams of carbs for a meal or snack.")

    @Parameter(title: "Grams of carbs", inclusiveRange: (1, 500))
    var grams: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$grams) g of carbs")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await IntentActions.logCarbs(grams: Double(grams))
        return .result(dialog: "Logged \(grams) grams of carbs.")
    }
}

struct LogGlucoseIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Glucose"
    static let description = IntentDescription("Logs a glucose reading in your unit (mg/dL or mmol/L).")

    @Parameter(title: "Glucose")
    var value: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Log glucose \(\.$value)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let settings = await SettingsStore.shared
        let mgdl = await settings.mgdl(fromDisplay: value)
        guard await MainActor.run(body: { SettingsStore.plausibleGlucose.contains(mgdl) }) else {
            throw $value.needsValueError("That doesn't look like a glucose reading. What was the number?")
        }
        await IntentActions.logGlucose(mgdl: mgdl)
        let text = await settings.formattedGlucose(mgdl)
        let zone = await settings.zone(for: mgdl)
        if zone.isLow {
            return .result(dialog: "Logged \(text). That's low: have 15 grams of fast sugar and check again in 15 minutes.")
        }
        return .result(dialog: "Logged \(text).")
    }
}

struct LogInsulinIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Insulin"
    static let description = IntentDescription("Logs a rapid-acting insulin dose you already took. It doesn't suggest doses.")

    @Parameter(title: "Units", inclusiveRange: (0.05, 100))
    var units: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$units) units of insulin")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Same rule as the app: a kid needs a grown-up for insulin.
        guard await SettingsStore.shared.access(to: .logInsulin) == .open else {
            return .result(dialog: "Logging insulin needs a grown-up. Open DiabetesCare together to log it.")
        }
        try await requestConfirmation(dialog: "Log \(units.formatted()) units of insulin you already took?")
        await IntentActions.logInsulin(units: units)
        return .result(dialog: "Logged \(units.formatted()) units.")
    }
}

struct GetHelpIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Help With a Low"
    static let description = IntentDescription("Opens the steps for treating a low and who to call.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await IntentActions.open(.getHelp)
        return .result()
    }
}

struct OpenWeeklyRecapIntent: AppIntent {
    static let title: LocalizedStringResource = "Show My Week"
    static let description = IntentDescription("Opens your weekly recap.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run { AppRouter.shared.pending = .weeklyRecap }
        return .result()
    }
}

// MARK: - Glossary terms

struct GlossaryTermEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Diabetes Term"
    static let defaultQuery = GlossaryTermQuery()

    let id: String
    let name: String
    let summary: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(summary)", image: .init(systemName: "book"))
    }

    init(_ term: GlossaryTerm) {
        id = term.id
        name = term.name
        summary = term.summary
    }
}

struct GlossaryTermQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [GlossaryTermEntity] {
        identifiers.compactMap { Glossary.shared.term($0).map(GlossaryTermEntity.init) }
    }

    func entities(matching string: String) async throws -> [GlossaryTermEntity] {
        Glossary.shared.search(string).prefix(20).map(GlossaryTermEntity.init)
    }

    func suggestedEntities() async throws -> [GlossaryTermEntity] {
        Glossary.startHereIDs.compactMap { Glossary.shared.term($0).map(GlossaryTermEntity.init) }
    }
}

struct OpenGlossaryTermIntent: OpenIntent {
    static let title: LocalizedStringResource = "Explain a Diabetes Term"

    @Parameter(title: "Term")
    var target: GlossaryTermEntity

    func perform() async throws -> some IntentResult {
        let id = target.id
        await MainActor.run { AppRouter.shared.pending = .glossaryTerm(id) }
        return .result()
    }
}

// MARK: - Siri phrases

struct DiabetesCareShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckGlucoseIntent(),
            phrases: [
                "Check my glucose in \(.applicationName)",
                "What's my glucose in \(.applicationName)",
                "How's my sugar in \(.applicationName)",
            ],
            shortTitle: "Check Glucose",
            systemImageName: "drop"
        )
        AppShortcut(
            intent: LogFastSugarIntent(),
            phrases: [
                "Log fast sugar in \(.applicationName)",
                "I'm treating a low in \(.applicationName)",
            ],
            shortTitle: "Treating a Low",
            systemImageName: "cube"
        )
        AppShortcut(
            intent: GetHelpIntent(),
            phrases: [
                "I need help in \(.applicationName)",
                "Get help with \(.applicationName)",
            ],
            shortTitle: "Get Help",
            systemImageName: "hand.raised"
        )
        AppShortcut(
            intent: LogCarbsIntent(),
            phrases: ["Log carbs in \(.applicationName)", "Add carbs to \(.applicationName)"],
            shortTitle: "Log Carbs",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: LogGlucoseIntent(),
            phrases: ["Log glucose in \(.applicationName)", "Log a reading in \(.applicationName)"],
            shortTitle: "Log Glucose",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: OpenGlossaryTermIntent(),
            phrases: ["Explain \(\.$target) in \(.applicationName)", "What is \(\.$target) in \(.applicationName)"],
            shortTitle: "Explain a Term",
            systemImageName: "book"
        )
        AppShortcut(
            intent: OpenWeeklyRecapIntent(),
            phrases: ["Show my week in \(.applicationName)"],
            shortTitle: "My Week",
            systemImageName: "calendar"
        )
    }
}

/// What Siri shows with "Check my glucose".
struct GlanceSnippet: View {
    let snapshot: GlanceSnapshot

    var body: some View {
        HStack(spacing: 14) {
            if let latest = snapshot.latest {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(snapshot.value(latest.mgdl))
                            .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(snapshot.zone(latest.mgdl).color)
                        if let symbol = snapshot.trendSymbol {
                            Image(systemName: symbol).font(.title2.weight(.bold))
                        }
                    }
                    Text("\(snapshot.unit) · \(latest.date, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if snapshot.insulinOnBoard > 0 {
                VStack(alignment: .trailing) {
                    Text("\(snapshot.insulinOnBoard.formatted(.number.precision(.fractionLength(1)))) U")
                        .font(.headline)
                    Text("active (estimate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
