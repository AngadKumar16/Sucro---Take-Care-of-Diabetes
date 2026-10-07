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

    private func openSecondaryTab(_ name: String) {
        let more = app.buttons["moreButton"]
        XCTAssertTrue(more.waitForExistence(timeout: 5), "More button should exist on Home")
        more.tap()

        let tab = app.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(name) tab should appear in the More sheet")
        tab.tap()
    }

    func testSafetyNoticeMustBeAcceptedBeforeUse() {
        app.launchArguments.append("-resetDisclaimer")
        app.launch()

        XCTAssertTrue(app.staticTexts["Before You Start"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["moreButton"].exists, "The app shouldn't be usable before accepting")

        app.buttons["I Understand"].tap()
        XCTAssertTrue(app.buttons["moreButton"].waitForExistence(timeout: 5), "Home should appear after accepting")
    }

    func testSafetyInformationIsReachableFromHelp() {
        app.launch()
        openSecondaryTab("Help")

        let link = app.buttons["Safety Information"]
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()

        let notice = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'not a medical device'")).firstMatch
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
    }

    func testThresholdsAndInsulinActionTimeAreAdjustable() {
        app.launch()
        openSecondaryTab("Settings")

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

        let slider = app.sliders.firstMatch
        XCTAssertTrue(slider.waitForExistence(timeout: 5))
        slider.adjust(toNormalizedSliderPosition: 0.8)   // about 16 units

        app.buttons["Log Bolus"].tap()

        let confirm = app.alerts.firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "A dose over 10 units should ask for confirmation")
        XCTAssertTrue(confirm.buttons["Log Dose"].exists)

        // Don't log anything.
        confirm.buttons["Cancel"].tap()
        app.buttons["Cancel"].tap()
    }
}
