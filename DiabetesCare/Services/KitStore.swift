//
//  KitStore.swift
//  DiabetesCare
//
//  The practical stuff around the log: how many sensors, pods and strips
//  are left, when an open pen or vial expires, and questions saved for the
//  next doctor visit. Kept in UserDefaults like settings, and carried in
//  backups.
//

import Foundation
import Observation

nonisolated enum SupplyKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case sensor, infusionSet, pod, reservoir, pen, vial, penNeedle, testStrip, lancet, ketoneStrip

    var id: String { rawValue }

    var name: String {
        switch self {
        case .sensor: String(localized: "CGM sensors")
        case .infusionSet: String(localized: "Infusion sets")
        case .pod: String(localized: "Pods")
        case .reservoir: String(localized: "Reservoirs / cartridges")
        case .pen: String(localized: "Insulin pens")
        case .vial: String(localized: "Insulin vials")
        case .penNeedle: String(localized: "Pen needles")
        case .testStrip: String(localized: "Test strips")
        case .lancet: String(localized: "Lancets")
        case .ketoneStrip: String(localized: "Ketone strips")
        }
    }

    var symbol: String {
        switch self {
        case .sensor: "sensor.tag.radiowaves.forward"
        case .infusionSet, .pod: "bandage"
        case .reservoir: "cylinder"
        case .pen, .penNeedle: "syringe"
        case .vial: "testtube.2"
        case .testStrip, .ketoneStrip: "rectangle.portrait"
        case .lancet: "pin"
        }
    }

    /// When to say "time to reorder".
    var defaultLowAt: Int {
        switch self {
        case .sensor, .pod, .infusionSet, .reservoir, .pen, .vial: 3
        case .penNeedle, .lancet: 20
        case .testStrip, .ketoneStrip: 25
        }
    }

    /// Supplies one site change uses up.
    var usedPerSiteChange: Int {
        switch self {
        case .infusionSet, .pod, .reservoir: 1
        default: 0
        }
    }
}

nonisolated struct Supply: Codable, Equatable, Identifiable, Sendable {
    var kind: SupplyKind
    var count: Int
    var lowAt: Int
    var id: SupplyKind { kind }
    var isLow: Bool { count <= lowAt }
}

/// An insulin pen or vial in use. Most last 28 days once opened.
nonisolated struct OpenedInsulin: Codable, Equatable, Identifiable, Sendable {
    var id = UUID()
    var name: String
    var openedAt: Date
    var lastsDays: Int = 28

    var expiresAt: Date {
        Calendar.current.date(byAdding: .day, value: lastsDays, to: openedAt) ?? openedAt
    }

    func daysLeft(now: Date = Date()) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: expiresAt)).day ?? 0
    }
}

nonisolated struct DoctorQuestion: Codable, Equatable, Identifiable, Sendable {
    var id = UUID()
    var text: String
    var createdAt = Date()
    var asked = false
}

/// What a backup carries for the kit.
nonisolated struct KitArchive: Codable, Equatable, Sendable {
    var supplies: [Supply] = []
    var opened: [OpenedInsulin] = []
    var questions: [DoctorQuestion] = []
}

@MainActor
@Observable
final class KitStore {
    static let shared = KitStore()

    @ObservationIgnored private let defaults: UserDefaults
    private static let key = "kit.archive"

    private(set) var supplies: [Supply] = []
    private(set) var opened: [OpenedInsulin] = []
    private(set) var questions: [DoctorQuestion] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key), let archive = try? JSONDecoder().decode(KitArchive.self, from: data) {
            apply(archive, save: false)
        }
    }

    var archive: KitArchive { KitArchive(supplies: supplies, opened: opened, questions: questions) }

    func apply(_ archive: KitArchive, save: Bool = true) {
        supplies = archive.supplies
        opened = archive.opened
        questions = archive.questions
        if save { persist() }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(archive) { defaults.set(data, forKey: Self.key) }
    }

    // MARK: - Supplies

    var lowSupplies: [Supply] { supplies.filter(\.isLow) }

    func supply(_ kind: SupplyKind) -> Supply? { supplies.first { $0.kind == kind } }

    /// Starts tracking a kind, or sets how many are on hand.
    func setCount(_ count: Int, for kind: SupplyKind) {
        let count = max(0, count)
        if let index = supplies.firstIndex(where: { $0.kind == kind }) {
            let wasLow = supplies[index].isLow
            supplies[index].count = count
            if !wasLow { notifyIfLow(supplies[index]) }
        } else {
            supplies.append(Supply(kind: kind, count: count, lowAt: kind.defaultLowAt))
        }
        persist()
    }

    func setLowAt(_ lowAt: Int, for kind: SupplyKind) {
        guard let index = supplies.firstIndex(where: { $0.kind == kind }) else { return }
        supplies[index].lowAt = max(0, lowAt)
        persist()
    }

    func stopTracking(_ kind: SupplyKind) {
        supplies.removeAll { $0.kind == kind }
        persist()
    }

    /// One of `kind` used up.
    func use(_ kind: SupplyKind, count: Int = 1) {
        guard let current = supply(kind) else { return }
        setCount(current.count - count, for: kind)
    }

    /// A site change uses a set or pod and a reservoir, if they're tracked.
    func recordSiteChange() {
        for supply in supplies where supply.kind.usedPerSiteChange > 0 {
            use(supply.kind, count: supply.kind.usedPerSiteChange)
        }
    }

    private func notifyIfLow(_ supply: Supply) {
        guard supply.isLow else { return }
        NotificationService.shared.schedule(
            id: NotificationService.Identifier.suppliesLow + "." + supply.kind.rawValue,
            title: String(localized: "Running Low: \(supply.kind.name)"),
            body: String(localized: "\(supply.count) left. Time to reorder."),
            at: Date().addingTimeInterval(2),
            route: .supplies
        )
    }

    // MARK: - Opened insulin

    func open(name: String, openedAt: Date = Date(), lastsDays: Int = 28) {
        let item = OpenedInsulin(name: name, openedAt: openedAt, lastsDays: lastsDays)
        opened.append(item)
        opened.sort { $0.expiresAt < $1.expiresAt }
        scheduleExpiry(item)
        persist()
    }

    func remove(_ item: OpenedInsulin) {
        opened.removeAll { $0.id == item.id }
        NotificationService.shared.cancel(id: NotificationService.Identifier.expiryPrefix + item.id.uuidString)
        persist()
    }

    /// The morning the item expires, at 9 a.m.
    private func scheduleExpiry(_ item: OpenedInsulin) {
        var morning = Calendar.current.dateComponents([.year, .month, .day], from: item.expiresAt)
        morning.hour = 9
        let date = Calendar.current.date(from: morning) ?? item.expiresAt
        NotificationService.shared.schedule(
            id: NotificationService.Identifier.expiryPrefix + item.id.uuidString,
            title: String(localized: "\(item.name) Expires Today"),
            body: String(localized: "It was opened \(item.lastsDays) days ago. Start a fresh one."),
            at: date,
            route: .supplies
        )
    }

    // MARK: - Doctor questions

    func addQuestion(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        questions.insert(DoctorQuestion(text: text), at: 0)
        persist()
    }

    func toggleAsked(_ question: DoctorQuestion) {
        guard let index = questions.firstIndex(where: { $0.id == question.id }) else { return }
        questions[index].asked.toggle()
        persist()
    }

    func removeQuestions(at offsets: IndexSet, in list: [DoctorQuestion]) {
        let ids = Set(offsets.map { list[$0].id })
        questions.removeAll { ids.contains($0.id) }
        persist()
    }

    var openQuestions: [DoctorQuestion] { questions.filter { !$0.asked } }
}
