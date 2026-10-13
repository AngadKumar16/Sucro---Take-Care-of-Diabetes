//
//  BackupService.swift
//  DiabetesCare
//
//  Daily backups and restore. When Daily Backup is on, a full JSON archive
//  (`BackupArchive`) is written to Documents/Backups at most once a day, on
//  launch. The folder shows up in the Files app, so backups can be moved to
//  iCloud Drive or another device. Only the newest few are kept.
//

import Foundation
import CoreData
import OSLog

@MainActor
final class BackupService {
    static let shared = BackupService()

    private let settings: SettingsStore
    private let fileManager = FileManager.default
    private let directoryOverride: URL?

    /// Minimum time between automatic backups.
    private let minimumInterval: TimeInterval = 24 * 60 * 60
    /// Automatic backups kept on the phone; older ones are deleted.
    static let keptBackups = 7

    init(settings: SettingsStore? = nil, directory: URL? = nil) {
        self.settings = settings ?? .shared
        self.directoryOverride = directory
    }

    /// Directory where backups are stored: Documents/Backups.
    var backupDirectory: URL? {
        if let directoryOverride { return directoryOverride }
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documents.appendingPathComponent("Backups", isDirectory: true)
    }

    /// Runs a backup if auto-backup is enabled and the daily throttle has elapsed.
    /// Safe to call on every launch. Returns the backup file URL when one is written.
    @discardableResult
    func performBackupIfNeeded(container: NSPersistentContainer) async -> URL? {
        guard settings.autoBackupEnabled else { return nil }

        if let last = settings.lastBackupDate,
           Date().timeIntervalSince(last) < minimumInterval {
            return nil
        }

        return await performBackup(container: container)
    }

    /// Writes a full archive to the backup directory, records the time for
    /// the daily throttle, and prunes old backups. Returns the file URL.
    @discardableResult
    func performBackup(container: NSPersistentContainer, now: Date = Date()) async -> URL? {
        guard let directory = backupDirectory else { return nil }
        do {
            let archive = try await makeArchive(container: container, now: now)
            // Nothing to back up yet: don't create an empty file or stamp the
            // date, so the first real data still triggers a backup.
            guard archive.entryCount > 0 else { return nil }
            let data = try archive.encoded()
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent(Self.fileName(for: now))
            try data.write(to: fileURL, options: .atomic)
            settings.lastBackupDate = now
            prune(directory)
            return fileURL
        } catch {
            Log.backup.error("Automatic backup failed: \(error, privacy: .public)")
            return nil
        }
    }

    /// The whole store as an archive, read on a background context.
    func makeArchive(container: NSPersistentContainer, now: Date = Date()) async throws -> BackupArchive {
        let backupSettings = settings.backupSettings
        let appVersion = AppInfo.version
        let kit = KitStore.shared.archive
        let context = container.newBackgroundContext()
        var archive = try await context.perform {
            try BackupStore.makeArchive(in: context, settings: backupSettings, appVersion: appVersion, now: now)
        }
        archive.kit = kit
        return archive
    }

    /// Adds the archive's entries to the store (or replaces everything) and
    /// brings the view context, reminders and alerts up to date.
    func restore(_ archive: BackupArchive, mode: BackupStore.Mode, container: NSPersistentContainer) async throws -> BackupStore.Result {
        let context = container.newBackgroundContext()
        let result = try await context.perform {
            try BackupStore.restore(archive, mode: mode, in: context)
        }
        let viewContext = container.viewContext
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: [NSInsertedObjectsKey: result.inserted, NSDeletedObjectsKey: result.deleted],
            into: [viewContext]
        )
        if mode == .replace, let backupSettings = archive.settings {
            settings.apply(backupSettings)
        }
        if mode == .replace, let kit = archive.kit {
            KitStore.shared.apply(kit)
        }
        if mode == .replace {
            AlertService.shared.reset()
        }
        ReminderService.shared.refresh(context: viewContext)
        AlertService.shared.evaluate(context: viewContext)
        return result
    }

    static func fileName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(AppInfo.name)-Backup-\(formatter.string(from: date)).json"
    }

    /// Keeps the newest `keptBackups` automatic backups. Names sort by date.
    private func prune(_ directory: URL) {
        let prefix = "\(AppInfo.name)-Backup-"
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        let backups = files
            .filter { $0.lastPathComponent.hasPrefix(prefix) && $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        for old in backups.dropFirst(Self.keptBackups) {
            try? fileManager.removeItem(at: old)
        }
    }
}
