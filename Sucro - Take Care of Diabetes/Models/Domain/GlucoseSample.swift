//
//  GlucoseSample.swift
//  Sucro - Take Care of Diabetes
//

import Foundation

/// A single glucose value in mg/dL at a point in time.
nonisolated struct GlucoseSample: Equatable, Sendable {
    let date: Date
    let mgdl: Double
}

extension GlucoseReading {
    var sample: GlucoseSample? {
        guard let timestamp else { return nil }
        return GlucoseSample(date: timestamp, mgdl: value)
    }
}
