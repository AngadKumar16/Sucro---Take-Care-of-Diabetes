//
//  SafetyFlowUITests.swift
//  Sucro - Take Care of Diabetes UITests
//
//  The safety notice, thresholds settings, and the large-dose confirmation.
//

import XCTest

final class SafetyFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
    }

    private func openSettings() {
        let tab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Settings tab should exist")
        tab.tap()
    }

    func testSafetyNoticeMustBeAcceptedBeforeUse() {
        app.launchArguments.append("-resetDisclaimer")
        app.launch()

        XCTAssertTrue(app.staticTexts["Before You Start"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.exists, "The app shouldn't be usable before accepting")

        app.buttons["I Understand"].tap()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5), "Today should appear after accepting")
    }

    func testSafetyInformationIsReachableFromHelp() {
        app.launch()
        openSettings()

        let link = app.buttons["Safety Information"]
        for _ in 0..<4 where !link.isHittable { app.swipeUp() }
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()

        let notice = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'not a medical device'")).firstMatch
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
    }

    func testThresholdsAndInsulinActionTimeAreAdjustable() {
        app.launch()
        openSettings()

        // The four rulers run down the Glucose section, past the first
        // screen, so nudge the list up a little until each one shows.
        for title in ["Urgent High", "High", "Low", "Urgent Low"] {
            let slider = app.sliders["threshold.\(title)"]
            for _ in 0..<4 where !slider.waitForExistence(timeout: 2) {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                    .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
            }
            XCTAssertTrue(slider.exists, "\(title) slider should exist")
        }

        // Each threshold is a ruler tape. Dragging the scale left moves
        // higher values under the needle; the value reads in the user's unit.
        let low = app.sliders["threshold.Low"]
        // Bring it clear of the floating tab bar before dragging.
        if low.frame.maxY > app.frame.maxY - 140 { app.swipeUp() }
        let before = low.value as? String
        low.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: low.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.5)))
        XCTAssertNotEqual(low.value as? String, before, "Dragging the tape should change the Low threshold")

        // Put the lines back so later tests see the defaults.
        let reset = app.buttons["Reset to Common Defaults"]
        if !reset.isHittable { app.swipeUp() }
        XCTAssertTrue(reset.waitForExistence(timeout: 5))
        reset.tap()

        let actionTime = app.steppers["insulinActionTime"]
        if !actionTime.exists { app.swipeUp() }
        XCTAssertTrue(actionTime.waitForExistence(timeout: 5))
    }

    func testLargeBolusAsksForConfirmation() {
        app.launch()

        let quickBolus = app.buttons["Quick Bolus"]
        XCTAssertTrue(quickBolus.waitForExistence(timeout: 5))
        quickBolus.tap()

        // Large preset (6 U), then ten steps of 0.5 U: 11 units.
        let large = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Large'")).firstMatch
        XCTAssertTrue(large.waitForExistence(timeout: 5))
        large.tap()
        let increment = app.buttons["bolusStepper-Increment"]
        XCTAssertTrue(increment.waitForExistence(timeout: 5))
        for _ in 0..<10 { increment.tap() }

        app.buttons["Log Bolus"].tap()

        let confirm = app.alerts.firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "A dose over 10 units should ask for confirmation")
        XCTAssertTrue(confirm.buttons["Log Dose"].exists)

        // Don't log anything.
        confirm.buttons["Cancel"].tap()
        app.buttons["Cancel"].tap()

        // There's an unsaved dose, so Cancel checks before throwing it away.
        let discard = app.buttons["Discard Changes"]
        XCTAssertTrue(discard.waitForExistence(timeout: 5), "Cancelling an unsaved dose should ask first")
        discard.tap()
    }
}
