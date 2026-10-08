//
//  SucroFlowUITests.swift
//  Sucro - Take Care of Diabetes UITests
//
//  Drives the real app on the simulator to exercise the backend that was
//  wired up: Settings persistence, Clear All Data, Reports, and Trends.
//

import XCTest

final class SucroFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
        dismissNotificationPromptIfPresent()
    }

    // MARK: - Helpers

    /// The notification permission dialog is a SpringBoard system alert that
    /// covers the UI on first launch; dismiss it so tests can proceed.
    private func dismissNotificationPromptIfPresent() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Allow", "Don’t Allow", "Don't Allow"] {
            let button = springboard.buttons[label]
            if button.waitForExistence(timeout: 2) {
                button.tap()
                return
            }
        }
    }

    private func openTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(name) tab should exist")
        tab.tap()
    }

    /// Scrolls the current screen until the element can be tapped.
    private func scrollTo(_ element: XCUIElement) {
        for _ in 0..<5 where !element.isHittable { app.swipeUp() }
    }

    // MARK: - Tests

    func testTodayScreenLoads() {
        for tab in ["Today", "Log", "Trends", "Reports", "Settings"] {
            XCTAssertTrue(app.tabBars.buttons[tab].waitForExistence(timeout: 5), "\(tab) tab should exist")
        }
        XCTAssertTrue(app.navigationBars["Today"].exists)
        XCTAssertTrue(app.buttons["Log Meal"].exists)
    }

    func testAppearanceChoicePersistsAcrossTabs() {
        openTab("Settings")

        let picker = app.buttons["appearancePicker"]
        scrollTo(picker)
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Appearance picker should exist")
        picker.tap()
        let dark = app.buttons["Dark"]
        XCTAssertTrue(dark.waitForExistence(timeout: 5))
        dark.tap()

        // Leave Settings and come back — the choice must stick.
        openTab("Today")
        openTab("Settings")
        let pickerAgain = app.buttons["appearancePicker"]
        scrollTo(pickerAgain)
        XCTAssertTrue(pickerAgain.waitForExistence(timeout: 5))
        XCTAssertTrue(pickerAgain.label.contains("Dark") || (pickerAgain.value as? String)?.contains("Dark") == true,
                      "Appearance should still be Dark")

        // Restore the default so later runs start from System.
        pickerAgain.tap()
        app.buttons["System"].tap()
    }

    func testClearAllDataShowsConfirmationAlert() {
        openTab("Settings")

        let clearButton = app.buttons["Clear All Data"]
        scrollTo(clearButton)
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
        clearButton.tap()

        let alert = app.alerts["Clear All Data?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Confirmation alert should appear")
        XCTAssertTrue(alert.buttons["Delete Everything"].exists)

        // Cancel — don't actually wipe.
        alert.buttons["Cancel"].tap()
        XCTAssertFalse(alert.exists)
    }

    func testExportWithNoDataShowsAlert() {
        openTab("Settings")

        let exportButton = app.buttons["Export Data"]
        scrollTo(exportButton)
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5))
        exportButton.tap()

        // Fresh install has no readings, so the "no data" alert is expected.
        // If data exists, a share sheet appears instead — accept either.
        let noDataAlert = app.alerts.firstMatch
        let shareSheet = app.otherElements["ActivityListView"]
        let appeared = noDataAlert.waitForExistence(timeout: 5) || shareSheet.waitForExistence(timeout: 5)
        XCTAssertTrue(appeared, "Export should produce an alert or a share sheet")

        if noDataAlert.exists { noDataAlert.buttons.firstMatch.tap() }
    }

    func testReportsPeriodSwitchAndExport() {
        openTab("Reports")

        XCTAssertTrue(app.staticTexts["Summary Statistics"].waitForExistence(timeout: 5))

        // Switch the reporting period via the segmented control.
        let month = app.buttons["Month"]
        if month.waitForExistence(timeout: 3) { month.tap() }

        // Tapping an export action should respond (no-data alert on fresh install).
        let pdfButton = app.buttons["Share PDF Report"]
        XCTAssertTrue(pdfButton.waitForExistence(timeout: 5))
        pdfButton.tap()

        let alert = app.alerts.firstMatch
        let shareSheet = app.otherElements["ActivityListView"]
        let appeared = alert.waitForExistence(timeout: 5) || shareSheet.waitForExistence(timeout: 5)
        XCTAssertTrue(appeared, "Share PDF Report should respond")
        if alert.exists { alert.buttons.firstMatch.tap() }
    }

    func testLogMealFromHomeOpensCarbForm() {
        // Regression: Home injected the wrong VM type into AddCarbView, which
        // crashed on tap. The form should now open without crashing.
        let logMeal = app.buttons["Log Meal"]
        XCTAssertTrue(logMeal.waitForExistence(timeout: 5))
        logMeal.tap()

        XCTAssertTrue(app.navigationBars["Add Carbs"].waitForExistence(timeout: 5),
                      "Tapping Log Meal should open the Add Carbs form")
        // Dismiss the form.
        app.buttons["Cancel"].tap()
    }

    func testMealPresetLogsInstantly() {
        let logMeal = app.buttons["Log Meal"]
        XCTAssertTrue(logMeal.waitForExistence(timeout: 5))

        // Touch and hold shows the saved-meal menu.
        logMeal.press(forDuration: 1.0)

        let preset = app.buttons["Breakfast (40g carbs)"]
        XCTAssertTrue(preset.waitForExistence(timeout: 5), "Touch and hold should show saved meals")

        // Logging a preset closes the menu and writes the entry right away.
        preset.tap()
        XCTAssertFalse(preset.waitForExistence(timeout: 1))
        XCTAssertFalse(app.navigationBars["Add Carbs"].exists, "A preset shouldn't open the form")
    }

    func testTrendsLoadsAndTimeRangeSwitches() {
        openTab("Trends")

        XCTAssertTrue(app.staticTexts["What Stands Out"].waitForExistence(timeout: 5))
        let weekly = app.staticTexts["Weekly Patterns"]
        scrollTo(weekly)
        XCTAssertTrue(weekly.exists)

        // The time-range segmented control should switch without crashing.
        let month = app.buttons["Month"]
        if month.waitForExistence(timeout: 3) {
            month.tap()
            XCTAssertTrue(app.staticTexts["What Stands Out"].exists)
        }
    }
}
