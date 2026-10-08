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

    /// Adds a Blood Glucose sample through the Health app's Add Data form.
    private func addGlucoseInHealth(_ value: String) {
        health.launch()
        clickThroughOnboarding()
        let search = health.buttons["UIA.Health.Tab.Search"]
        XCTAssertTrue(search.waitForExistence(timeout: 10), "Health tab bar should show")
        search.tap()

        let field = health.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        // First keyboard use on a fresh simulator shows a tip over the results.
        tapIfExists(health.buttons["Continue"], timeout: 2)
        field.typeText("Blood Glucose")
        tapIfExists(health.buttons["Continue"], timeout: 1)
        field.typeText("\n")
        // The result row's element type varies between Health versions.
        let result = health.descendants(matching: .any).matching(NSPredicate(
            format: "label == 'Blood Glucose' AND elementType != %d", XCUIElement.ElementType.searchField.rawValue
        )).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5), "Blood Glucose should be found")
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
        if snapshot.elementType == .button, snapshot.isEnabled, labels.contains(snapshot.label),
           !snapshot.frame.isEmpty, snapshot.frame.midX.isFinite {
            return snapshot.frame
        }
        for child in snapshot.children {
            if let frame = firstButton(in: child, labels: labels) { return frame }
        }
        return nil
    }

    func testGlucoseAddedInHealthIsImported() {
        addGlucoseInHealth("137")

        app.activate()
        allowHealthAccessIfAsked(timeout: 2)
        app.tabBars.buttons["Log"].tap()
        let row = app.buttons.containing(NSPredicate(format: "label BEGINSWITH '137' AND label CONTAINS 'Apple Health'")).firstMatch
        // Background delivery can lag a little; pull to refresh checks now.
        if !row.waitForExistence(timeout: 10) {
            app.buttons["Glucose"].tap()
        }
        XCTAssertTrue(row.waitForExistence(timeout: 20), "The Health reading should be imported")

        app.tabBars.buttons["Settings"].tap()
        let devices = app.buttons["Devices & Apple Health"]
        for _ in 0..<4 where !devices.isHittable { app.swipeUp() }
        devices.tap()
        let receiving = app.staticTexts["Receiving"]
        XCTAssertTrue(receiving.waitForExistence(timeout: 5), "Devices should show readings arriving")
    }
}
