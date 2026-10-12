//
//  SiteRotationTests.swift
//  DiabetesCare Tests
//
//  Covers site rotation history: last use per site, how long each change
//  was worn, and rest order.
//

import Testing
import Foundation
@testable import DiabetesCare

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)
private func day(_ d: Double) -> Date { t0.addingTimeInterval(d * 86_400) }

struct SiteRotationTests {
    let changes = [
        SiteRotation.Change(location: .abdomenLeft, date: day(0)),
        SiteRotation.Change(location: .thighLeft, date: day(2)),
        SiteRotation.Change(location: .abdomenLeft, date: day(6)),
    ]

    @Test func lastUsedKeepsTheNewestDate() {
        let lastUsed = SiteRotation.lastUsed(changes)
        #expect(lastUsed[.abdomenLeft] == day(6))
        #expect(lastUsed[.thighLeft] == day(2))
        #expect(lastUsed[.armLeft] == nil)
    }

    @Test func wearEndsAtTheNextChange() {
        let wear = SiteRotation.wear(changes.shuffled())
        #expect(wear.map(\.change.date) == [day(6), day(2), day(0)])
        #expect(wear[0].endedAt == nil)
        #expect(wear[0].wornDays(now: day(7)) == 1)
        #expect(wear[1].wornDays(now: day(7)) == 4)
        #expect(wear[2].wornDays(now: day(7)) == 2)
    }

    @Test func overdueWhenWornWellPastRotationDays() {
        let wear = SiteRotation.wear(changes)
        // Thigh rotates every 3 days and was worn 4.
        #expect(wear[1].wasOverdue(now: day(7)))
        // Abdomen rotates every 2 days and was worn exactly 2.
        #expect(!wear[2].wasOverdue(now: day(7)))
    }

    @Test func restOrderPutsUnusedThenOldestFirst() {
        let order = SiteRotation.restOrder(SiteRotation.lastUsed(changes))
        #expect(!order.contains(.other))
        #expect(order.suffix(2) == [.thighLeft, .abdomenLeft])
    }
}
