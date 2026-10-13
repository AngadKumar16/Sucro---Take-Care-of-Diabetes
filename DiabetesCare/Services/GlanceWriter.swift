//
//  GlanceWriter.swift
//  DiabetesCare
//
//  Keeps everything outside the app current: after any change to the
//  store it writes the glance snapshot for widgets, reloads them, moves
//  the low-treatment Live Activity along, and sends the snapshot to the
//  watch. Debounced, so a CGM import is one update.
//

import CoreData
import Foundation
import WidgetKit

@MainActor
final class GlanceWriter {
    static let shared = GlanceWriter()

    private var container: NSPersistentContainer?
    private var observer: NSObjectProtocol?
    private var pending: Task<Void, Never>?

    func start(container: NSPersistentContainer) {
        self.container = container
        guard observer == nil else { return }
        let coordinator = container.persistentStoreCoordinator
        observer = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: .main) { [weak self] note in
            guard let context = note.object as? NSManagedObjectContext,
                  context.persistentStoreCoordinator === coordinator else { return }
            MainActor.assumeIsolated { self?.scheduleUpdate() }
        }
        scheduleUpdate()
    }

    func scheduleUpdate() {
        pending?.cancel()
        pending = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self?.update()
        }
    }

    func update(now: Date = Date()) {
        guard let context = container?.viewContext else { return }
        let snapshot = Self.snapshot(context: context, settings: .shared, now: now)
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
        LowTreatmentActivity.update(latest: snapshot.latest.map { GlucoseSample(date: $0.date, mgdl: $0.mgdl) }, now: now)
        WatchBridge.shared.send(snapshot)
    }

    static func snapshot(context: NSManagedObjectContext, settings: SettingsStore, now: Date) -> GlanceSnapshot {
        let data = DataService.shared
        let latest = data.fetchLatestGlucoseReading(context: context)
        let recent = data.fetchGlucoseReadings(context: context, in: DateInterval(start: now.addingTimeInterval(-3 * 3600), end: now))
        return GlanceSnapshot(
            updatedAt: now,
            latest: latest?.sample.map { GlanceSnapshot.Point(date: $0.date, mgdl: $0.mgdl) },
            trend: GlucoseTrend(stored: latest?.trend)?.rawValue,
            recent: recent.compactMap(\.sample).map { GlanceSnapshot.Point(date: $0.date, mgdl: $0.mgdl) },
            insulinOnBoard: data.calculateIOB(context: context, at: now),
            carbsToday: data.fetchTodayTotals(context: context).carbs,
            unit: settings.glucoseUnit,
            urgentLow: settings.urgentLow,
            targetLow: settings.targetLow,
            targetHigh: settings.targetHigh,
            urgentHigh: settings.urgentHigh,
            stage: settings.stage.rawValue,
            name: settings.userName,
            loggingStreak: StoryService.streaks(context: context, settings: settings, now: now).logging,
            lowRecheckAt: LowTreatmentService.pendingRecheck
        )
    }
}
