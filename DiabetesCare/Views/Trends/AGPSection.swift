//
//  AGPSection.swift
//  DiabetesCare
//
//  The ambulatory glucose profile and what meals did, on Trends.
//

import Charts
import SwiftUI

struct AGPSection: View {
    @Environment(SettingsStore.self) private var settings
    let buckets: [AGP.Bucket]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader("Your Typical Day")
            VStack(alignment: .leading, spacing: 10) {
                if buckets.isEmpty {
                    Text("Once you have readings on 5 or more days, your days stack into one, showing what a typical day looks like hour by hour.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.soft)
                } else {
                    AGPChart(buckets: buckets)
                        .frame(height: 220)
                    legend
                    if let extremes = AGP.extremes(buckets) {
                        Text("Usually highest around \(time(extremes.highest.minute)) (\(settings.formattedGlucose(extremes.highest.median))) and lowest around \(time(extremes.lowest.minute)) (\(settings.formattedGlucose(extremes.lowest.median))).")
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .card()
        }
        .accessibilityIdentifier("agpSection")
    }

    private var legend: some View {
        HStack(spacing: 14) {
            swatch(Theme.green, "Middle")
            swatch(Theme.green.opacity(0.35), "Half of days")
            swatch(Theme.green.opacity(0.12), "9 in 10 days")
        }
        .font(.caption)
        .foregroundStyle(Theme.soft)
    }

    private func swatch(_ color: Color, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 14, height: 8)
            Text(title)
        }
    }

    private func time(_ minute: Int) -> String {
        let date = Calendar.current.startOfDay(for: .now).addingTimeInterval(Double(minute) * 60)
        return date.formatted(date: .omitted, time: .shortened)
    }
}

struct AGPChart: View {
    @Environment(SettingsStore.self) private var settings
    let buckets: [AGP.Bucket]

    var body: some View {
        let base = Calendar.current.startOfDay(for: .now)
        Chart {
            RectangleMark(
                xStart: .value("Start", base),
                xEnd: .value("End", base.addingTimeInterval(86_400)),
                yStart: .value("Target low", settings.displayGlucose(settings.targetLow)),
                yEnd: .value("Target high", settings.displayGlucose(settings.targetHigh))
            )
            .foregroundStyle(Theme.green.opacity(0.06))

            ForEach(buckets) { bucket in
                let x = base.addingTimeInterval(Double(bucket.minute) * 60)
                AreaMark(
                    x: .value("Time", x),
                    yStart: .value("5th", settings.displayGlucose(bucket.p5)),
                    yEnd: .value("95th", settings.displayGlucose(bucket.p95)),
                    series: .value("Band", "outer")
                )
                .foregroundStyle(Theme.green.opacity(0.12))
                .interpolationMethod(.monotone)
            }
            ForEach(buckets) { bucket in
                let x = base.addingTimeInterval(Double(bucket.minute) * 60)
                AreaMark(
                    x: .value("Time", x),
                    yStart: .value("25th", settings.displayGlucose(bucket.p25)),
                    yEnd: .value("75th", settings.displayGlucose(bucket.p75)),
                    series: .value("Band", "inner")
                )
                .foregroundStyle(Theme.green.opacity(0.35))
                .interpolationMethod(.monotone)
            }
            ForEach(buckets) { bucket in
                LineMark(
                    x: .value("Time", base.addingTimeInterval(Double(bucket.minute) * 60)),
                    y: .value("Median", settings.displayGlucose(bucket.median)),
                    series: .value("Band", "median")
                )
                .foregroundStyle(Theme.green)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.monotone)
                .accessibilityLabel(base.addingTimeInterval(Double(bucket.minute) * 60).formatted(date: .omitted, time: .shortened))
                .accessibilityValue("Typically \(settings.formattedGlucose(bucket.median)), most days \(settings.glucoseValueString(bucket.p25)) to \(settings.formattedGlucose(bucket.p75))")
            }
        }
        .chartXScale(domain: base...base.addingTimeInterval(86_400))
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}

/// What meals did: the rise after each recent meal, and foods eaten more
/// than once compared.
struct MealImpactSection: View {
    @Environment(SettingsStore.self) private var settings
    let meals: [MealImpact.Meal]

    private var foods: [MealImpact.Food] { MealImpact.foods(meals) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader("After Meals")
            VStack(alignment: .leading, spacing: 12) {
                if meals.isEmpty {
                    Text("Log meals with a glucose reading before and a couple in the 3 hours after, and you'll see how much each one raised your glucose.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.soft)
                } else {
                    if !foods.isEmpty {
                        Text("By food")
                            .friendlyLabel()
                        ForEach(foods.prefix(5)) { food in
                            riseRow(name: food.name, detail: String(localized: "\(food.meals) times, about \(Int(food.averageCarbs)) g carbs"), rise: food.averageRise)
                        }
                        Divider()
                    }
                    Text("Recent meals")
                        .friendlyLabel()
                    ForEach(meals.prefix(5)) { meal in
                        riseRow(
                            name: meal.name,
                            detail: "\(meal.time.formatted(.dateTime.weekday(.abbreviated).hour().minute())) · \(Int(meal.carbs)) g · \(settings.glucoseValueString(meal.before)) → \(settings.formattedGlucose(meal.peak))",
                            rise: meal.rise
                        )
                    }
                    Text("The rise is from the reading before the meal to the highest in the 3 hours after. Ask your care team what's right for you.")
                        .font(.caption)
                        .foregroundStyle(Theme.soft)
                }
            }
            .card()
        }
        .accessibilityIdentifier("mealImpact")
    }

    private func riseRow(name: String, detail: String, rise: Double) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.soft)
            }
            Spacer()
            Text("+\(settings.glucoseValueString(max(0, rise)))")
                .font(.headline.monospacedDigit())
                .foregroundStyle(rise >= 100 ? Theme.amber : Theme.green)
        }
        .accessibilityElement(children: .combine)
    }
}
