//
//  BackupService.swift
//  Sucro - Take Care of Diabetes
//
//  Makes the "Auto Backup" setting do real work. When enabled, glucose data is
//  written to a CSV snapshot in the app's Documents/Backups folder. Backups are
//  throttled to once per day and triggered on app launch.
//

import Foundation
import CoreData

final class BackupService {
    static let shared = BackupService()

    private let settings: SettingsStore
    private let dataService = DataService.shared
    private let fileManager = FileManager.default

    /// Minimum time between automatic backups.
    private let minimumInterval: TimeInterval = 24 * 60 * 60

    init(settings: SettingsStore = .shared) {
        self.settings = settings
    }

    /// Directory where backups are stored: Documents/Backups.
    var backupDirectory: URL? {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documents.appendingPathComponent("Backups", isDirectory: true)
    }

    /// Runs a backup if auto-backup is enabled and the daily throttle has elapsed.
    /// Safe to call on every launch. Returns the backup file URL when one is written.
    @discardableResult
    func performBackupIfNeeded(context: NSManagedObjectContext) -> URL? {
        guard settings.autoBackupEnabled else { return nil }

        if let last = settings.lastBackupDate,
           Date().timeIntervalSince(last) < minimumInterval {
            return nil
        }

        return performBackup(context: context)
    }

    /// Writes a CSV snapshot of all glucose readings to the backup directory.
    /// Records the timestamp so the daily throttle can apply. Returns the file URL.
    @discardableResult
    func performBackup(context: NSManagedObjectContext) -> URL? {
        guard let directory = backupDirectory else { return nil }

        let range = DateInterval(start: .distantPast, end: Date())
        let readings = dataService.fetchGlucoseReadings(context: context, in: range)

        // Nothing to back up yet — don't create an empty file or stamp the date,
        // so the first real data still triggers a backup.
        guard !readings.isEmpty else { return nil }

        var csv = "Timestamp,Value,Unit,Trend,Notes\n"
        let isoFormatter = ISO8601DateFormatter()
        for reading in readings {
            let timestamp = reading.timestamp.map { isoFormatter.string(from: $0) } ?? ""
            let unit = escape(reading.unit ?? "mg/dL")
            let trend = escape(reading.trend ?? "")
            let notes = escape(reading.notes ?? "")
            csv.append("\(timestamp),\(reading.value),\(unit),\(trend),\(notes)\n")
        }

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent("Sucro_Backup_\(fileDateString()).csv")
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            settings.lastBackupDate = Date()
            return fileURL
        } catch {
            print("Auto backup failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Helpers

    private func escape(_ string: String) -> String {
        var escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") {
            escaped = "\"\(escaped)\""
        }
        return escaped
    }

    private func fileDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
