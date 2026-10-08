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

        for title in ["Urgent Low", "Low", "High", "Urgent High"] {
            XCTAssertTrue(app.steppers["threshold.\(title)"].waitForExistence(timeout: 5), "\(title) stepper should exist")
        }

        // Each stepper button's label includes the current value.
        let increment = app.buttons["threshold.Low-Increment"]
        let decrement = app.buttons["threshold.Low-Decrement"]
        let before = increment.label
        increment.tap()
        XCTAssertNotEqual(increment.label, before, "Incrementing should change the Low threshold")
        decrement.tap()
        XCTAssertEqual(increment.label, before)

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
