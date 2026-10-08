//
//  GlucoseSource.swift
//  Sucro - Take Care of Diabetes
//
//  Where a glucose reading came from. Stored in `GlucoseReading.source`.
//  Older builds left it empty, which means the user logged it.
//

import Foundation

nonisolated enum GlucoseSource: String, Sendable {
    case manual
    /// Imported from Apple Health. The reading's `id` is the Health sample's UUID.
    case health

    init(stored: String?) {
        self = stored.flatMap(GlucoseSource.init(rawValue:)) ?? .manual
    }
}

extension GlucoseReading {
    var glucoseSource: GlucoseSource { GlucoseSource(stored: source) }
    var isFromHealth: Bool { glucoseSource == .health }
}
