//
//  DemoData.swift
//  Sucro - Take Care of Diabetes
//
//  Debug builds only: launch with `-demoData` to replace the store with two
//  weeks of made-up CGM readings, meals and doses, for design work and
//  screenshots. Never written to Apple Health.
//

#if DEBUG
import CoreData

enum DemoData {
    static func install(context: NSManagedObjectContext, days: Int = 14, now: Date = Date()) {
        _ = DataService.shared.clearAllData(context: context)

        // Seeded so every launch draws the same days.
        var random = SeededGenerator(seed: 7)
        let start = Calendar.current.startOfDay(for: now.addingTimeInterval(-Double(days) * 86_400))
        let meals: [(hour: Double, grams: Double, type: MealType)] = [
            (7.5, 45, .breakfast), (12.5, 60, .lunch), (18.75, 70, .dinner)
        ]

        var glucose = 120.0
        var time = start
        while time <= now {
            let hour = time.timeIntervalSince(Calendar.current.startOfDay(for: time)) / 3600
            // A rise after each meal, a dawn bump, and slow drift with noise.
            var target = 115.0
            for meal in meals {
                let since = hour - meal.hour
                if since > 0, since < 3 { target += meal.grams * 1.6 * sin(.pi * since / 3) }
            }
            if hour > 4, hour < 7 { target += 25 }
            if hour > 2, hour < 3.5, Double.random(in: 0...1, using: &random) < 0.08 { target = 58 }
            glucose += (target - glucose) * 0.12 + Double.random(in: -6...6, using: &random)
            glucose = min(max(glucose, 45), 340)

            let reading = GlucoseReading(context: context)
            reading.id = UUID()
            reading.value = glucose.rounded()
            reading.unit = "mg/dL"
            reading.timestamp = time
            time = time.addingTimeInterval(5 * 60)
        }

        var day = start
        while day <= now {
            for meal in meals {
                let mealTime = day.addingTimeInterval(meal.hour * 3600 + Double.random(in: -1800...1800, using: &random))
                guard mealTime <= now else { continue }
                let carbs = CarbEntry(context: context)
                carbs.id = UUID()
                carbs.grams = (meal.grams + Double.random(in: -15...15, using: &random)).rounded()
                carbs.mealType = meal.type.rawValue
                carbs.timestamp = mealTime

                let dose = InsulinEntry(context: context)
                dose.id = UUID()
                dose.units = (carbs.grams / 10 * 2).rounded() / 2
                dose.type = InsulinType.bolus.rawValue
                dose.timestamp = mealTime.addingTimeInterval(-10 * 60)
            }
            day = day.addingTimeInterval(86_400)
        }

        let site = SiteChange(context: context)
        site.id = UUID()
        site.timestamp = now.addingTimeInterval(-30 * 3600)
        site.location = SiteLocation.abdomenLeft.rawValue

        try? context.save()
    }
}

/// A tiny deterministic generator (SplitMix64).
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
#endif
