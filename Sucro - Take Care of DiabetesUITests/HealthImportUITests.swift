//
//  HealthImportUITests.swift
//  Sucro - Take Care of Diabetes UITests
//
//  End to end: a glucose sample added in the Health app (as another app
//  would) shows up in DiabetesCare, marked as from Apple Health.
//

import XCTest

final class HealthImportUITests: XCTestCase {

    private var app: XCUIApplication!
    private let health = XCUIApplication(bundleIdentifier: "com.apple.Health")

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetData", "-healthImport"]
        app.launch()
        allowHealthAccessIfAsked()
    }

    /// The Health permission sheet appears once per simulator, shortly
    /// after launch. It's drawn by HealthPrivacyService, not the app.
    private func allowHealthAccessIfAsked(timeout: TimeInterval = 15) {
        let sheet = XCUIApplication(bundleIdentifier: "com.apple.HealthPrivacyService")
        let allow = sheet.buttons["Allow"]
        guard allow.waitForExistence(timeout: timeout) else { return }
        let turnOnAll = sheet.descendants(matching: .any).matching(NSPredicate(format: "label == 'Turn On All'")).firstMatch
        for _ in 0..<5 where !allow.isEnabled {
            if turnOnAll.exists { turnOnAll.tap() }
            _ = allow.waitForExistence(timeout: 1)
        }
        XCTAssertTrue(allow.isEnabled, "Turn On All should enable Allow")
        allow.tap()
        XCTAssertTrue(allow.waitForNonExistence(timeout: 10), "Health access should be granted")
    }

    private func tapIfExists(_ element: XCUIElement, timeout: TimeInterval = 2) {
        if element.waitForExistence(timeout: timeout) { element.tap() }
    }

    /// Health reopens where a previous run left it, which can be a modal
    /// or a page pushed under Search (the tab can't be tapped from there).
    private func backOutOfHealthPages() {
        let close = health.buttons["UIA.Health.ModalNavigationItem.Done"]
        if close.waitForExistence(timeout: 1) { close.tap() }
        let back = health.navigationBars.buttons["BackButton"]
        for _ in 0..<4 where back.waitForExistence(timeout: 1) && back.isHittable { back.tap() }
    }

    /// Adds a Blood Glucose sample through the Health app's Add Data form.
    private func addGlucoseInHealth(_ value: String) {
        health.launch()
        clickThroughOnboarding()
        backOutOfHealthPages()
        let field = health.searchFields.firstMatch
        if !field.waitForExistence(timeout: 2) {
            let search = health.buttons["UIA.Health.Tab.Search"]
            XCTAssertTrue(search.waitForExistence(timeout: 10), "Health tab bar should show")
            search.tap()
        }
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        // The result row's element type varies between Health versions.
        let result = health.descendants(matching: .any).matching(NSPredicate(
            format: "label == 'Blood Glucose' AND elementType != %d", XCUIElement.ElementType.searchField.rawValue
        )).firstMatch
        // A fresh simulator builds Health's search index in the background,
        // so the first searches can come back empty.
        for attempt in 0..<6 {
            field.tap()
            let clear = health.buttons["UIA.Health.Search.SearchBar.ClearButton"].firstMatch
            if clear.exists { clear.tap() }
            // First keyboard use on a fresh simulator shows a tip over the results.
            tapIfExists(health.buttons["Continue"], timeout: attempt == 0 ? 2 : 0.5)
            field.typeText("Blood Glucose")
            tapIfExists(health.buttons["Continue"], timeout: 1)
            field.typeText("\n")
            if result.waitForExistence(timeout: 5) { break }
        }
        XCTAssertTrue(result.exists, "Blood Glucose should be found")
        result.tap()

        let addData = health.buttons["Add Data"]
        XCTAssertTrue(addData.waitForExistence(timeout: 5), "Add Data should show")
        addData.tap()

        XCTAssertTrue(health.buttons["UIA.Health.AddData.Add"].waitForExistence(timeout: 5))
        let valueField = health.textFields.matching(NSPredicate(format: "label BEGINSWITH 'Blood Glucose'")).firstMatch
        XCTAssertTrue(valueField.waitForExistence(timeout: 5), "The value field should show")
        valueField.tap()
        valueField.typeText(value)
        health.buttons["UIA.Health.AddData.Add"].tap()
    }

    /// Clicks through Health's first-run screens and system prompts. Works
    /// from snapshots and coordinates because the screens animate away
    /// mid-query, which makes element taps fail the test.
    private func clickThroughOnboarding() {
        let labels: Set<String> = ["Continue", "Next", "Not Now", "Skip", "OK", "Allow"]
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        var idle = 0
        var taps = 0
        let searchTab = health.buttons["UIA.Health.Tab.Search"]
        while idle < 3, taps < 20 {
            // Onboarding covers the tab bar; once the tab can be tapped, the
            // app is ready. (Buttons on the Summary screen must not be hit.)
            if !springboard.alerts.firstMatch.exists, searchTab.exists, searchTab.isHittable { return }
            // Health asks to send notifications partway through; allowing
            // avoids a follow-up "notifications are off" alert.
            let alert = springboard.alerts.firstMatch
            let roots: [(XCUIApplication, XCUIElement)] = alert.exists ? [(springboard, alert)] : [(health, health)]
            let target = roots.lazy.compactMap { owner, root in
                (try? root.snapshot()).flatMap { Self.firstButton(in: $0, labels: labels) }.map { (owner, $0) }
            }.first
            guard let (owner, frame) = target else {
                idle += 1
                _ = health.buttons["UIA.Health.Tab.Search"].waitForExistence(timeout: 1)
                continue
            }
            idle = 0
            taps += 1
            owner.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: frame.midX, dy: frame.midY))
                .tap()
        }
    }

    private static func firstButton(in snapshot: XCUIElementSnapshot, labels: Set<String>) -> CGRect? {
        // Read the label from the dictionary: some of Health's buttons have
        // none, and `snapshot.label` traps on nil.
        if snapshot.elementType == .button, snapshot.isEnabled,
           let label = snapshot.dictionaryRepresentation[.label] as? String, labels.contains(label),
           !snapshot.frame.isEmpty, snapshot.frame.midX.isFinite {
            return snapshot.frame
        }
        for child in snapshot.children {
            if let frame = firstButton(in: child, labels: labels) { return frame }
        }
        return nil
    }

    /// The Log row for an imported reading.
    private func importedRow(_ value: String) -> XCUIElement {
        app.buttons.containing(NSPredicate(
            format: "label BEGINSWITH %@ AND label CONTAINS 'Apple Health'", value
        )).firstMatch
    }

    /// Returns to the app and waits for `value` to show in the Log.
    private func waitForImport(_ value: String) {
        app.activate()
        allowHealthAccessIfAsked(timeout: 2)
        app.tabBars.buttons["Log"].tap()
        let row = importedRow(value)
        // Background delivery can lag a little; switching filters refetches.
        if !row.waitForExistence(timeout: 10) {
            app.buttons["Glucose"].tap()
        }
        XCTAssertTrue(row.waitForExistence(timeout: 20), "The Health reading should be imported")
    }

    /// Deletes the Blood Glucose sample with `value` in the Health app.
    /// Starts from the Blood Glucose page `addGlucoseInHealth` leaves open.
    private func deleteGlucoseInHealth(_ value: String) {
        health.activate()
        // Not "Show More Blood Glucose Data" near the top: that's a chart.
        let showAll = health.descendants(matching: .any).matching(NSPredicate(format: "label == 'Show All Data'")).firstMatch
        for _ in 0..<8 where !(showAll.exists && showAll.isHittable) { health.swipeUp() }
        XCTAssertTrue(showAll.exists, "Blood Glucose should offer Show All Data")
        showAll.tap()

        // Rows read "134, Oct 8 at 8:36 PM, Health".
        let sample = health.cells.matching(NSPredicate(format: "label BEGINSWITH %@", "\(value), ")).firstMatch
        XCTAssertTrue(sample.waitForExistence(timeout: 5), "The added sample should be listed in Health")
        sample.swipeLeft()
        let delete = health.buttons["Delete"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()
        // Health asks to confirm deleting data.
        let confirm = health.buttons["Delete"].firstMatch
        if confirm.waitForExistence(timeout: 3) { confirm.tap() }
        XCTAssertTrue(sample.waitForNonExistence(timeout: 5), "Health should delete the sample")
    }

    /// A value earlier runs are unlikely to have left in Health, so a
    /// leftover can't pass for this run's reading. Kept in range so no
    /// high/low alert covers the screen.
    private func uniqueValue() -> String {
        String(Int.random(in: 101...169))
    }

    func testGlucoseAddedInHealthIsImported() {
        let value = uniqueValue()
        addGlucoseInHealth(value)
        waitForImport(value)

        app.tabBars.buttons["Settings"].tap()
        let devices = app.buttons["Devices & Apple Health"]
        for _ in 0..<4 where !devices.isHittable { app.swipeUp() }
        devices.tap()
        let receiving = app.staticTexts["Receiving"]
        XCTAssertTrue(receiving.waitForExistence(timeout: 5), "Devices should show readings arriving")

        deleteGlucoseInHealth(value)
    }

    func testGlucoseDeletedInHealthIsRemoved() {
        let value = uniqueValue()
        addGlucoseInHealth(value)
        waitForImport(value)

        deleteGlucoseInHealth(value)

        app.activate()
        let row = importedRow(value)
        // Coming to the foreground syncs; switching filters refetches.
        if !row.waitForNonExistence(timeout: 10) {
            app.buttons["All"].tap()
            app.buttons["Glucose"].tap()
        }
        XCTAssertTrue(row.waitForNonExistence(timeout: 20), "A reading deleted in Health should leave the Log")
    }
}
