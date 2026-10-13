//
//  AppRouter.swift
//  DiabetesCare
//
//  One place that turns "open this" from outside the app (a widget, a
//  control, Siri, Spotlight, a notification, the watch) into navigation.
//  Callers set `pending`; the tab view acts on it and clears it.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()

    enum Route: Equatable, Hashable {
        case logGlucose
        case logCarbs
        case getHelp
        case trends
        case weeklyRecap
        case glossaryTerm(String)
        case guide(String)
        case supplies
        case schoolCard
    }

    var pending: Route?

    /// URLs widgets and notifications use: `diabetescare://<route>[/<id>]`.
    static let scheme = "diabetescare"

    static func url(for route: Route) -> URL {
        let path = switch route {
        case .logGlucose: "log-glucose"
        case .logCarbs: "log-carbs"
        case .getHelp: "get-help"
        case .trends: "trends"
        case .weeklyRecap: "weekly-recap"
        case .glossaryTerm(let id): "term/\(id)"
        case .guide(let id): "guide/\(id)"
        case .supplies: "supplies"
        case .schoolCard: "school-card"
        }
        return URL(string: "\(scheme)://\(path)")!
    }

    static func route(for url: URL) -> Route? {
        guard url.scheme == scheme, let host = url.host() else { return nil }
        switch host {
        case "log-glucose": return .logGlucose
        case "log-carbs": return .logCarbs
        case "get-help": return .getHelp
        case "trends": return .trends
        case "weekly-recap": return .weeklyRecap
        case "supplies": return .supplies
        case "school-card": return .schoolCard
        case "term":
            let id = url.pathComponents.dropFirst().first
            return id.map(Route.glossaryTerm)
        case "guide":
            let id = url.pathComponents.dropFirst().first
            return id.map(Route.guide)
        default: return nil
        }
    }

    @discardableResult
    func open(_ url: URL) -> Bool {
        guard let route = Self.route(for: url) else { return false }
        pending = route
        return true
    }
}
