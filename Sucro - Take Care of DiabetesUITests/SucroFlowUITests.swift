//
//  SucroFlowUITests.swift
//  Sucro - Take Care of Diabetes UITests
//
//  Drives the real app on the simulator to exercise the backend that was
//  wired up: Settings persistence, Clear All Data, Reports, and Insights.
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

    /// Opens the "More" sheet and selects one of its tabs.
    private func openSecondaryTab(_ name: String) {
        let more = app.buttons["moreButton"]
        XCTAssertTrue(more.waitForExistence(timeout: 5), "More button should exist on Home")
        more.tap()

        let tab = app.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(name) tab should appear in the More sheet")
        tab.tap()
    }

    // MARK: - Tests

    func testHomeScreenLoads() {
        // Tab bar with the three primary tabs should be present.
        XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Log"].exists)
        XCTAssertTrue(app.buttons["Monitor"].exists)
        // A primary quick action from HomeView.
        XCTAssertTrue(app.staticTexts["Sucro"].exists || app.buttons["Log Meal"].exists)
    }

    func testDarkModeToggledPersistsAcrossSheetReopen() {
        openSecondaryTab("Settings")

        let darkMode = app.switches["Dark Mode"]
        XCTAssertTrue(darkMode.waitForExistence(timeout: 5), "Dark Mode toggle should exist")

        let originalValue = darkMode.value as? String
        darkMode.tap()
        let toggledValue = darkMode.value as? String
        XCTAssertNotEqual(originalValue, toggledValue, "Toggling should flip the switch value")

        // Close the sheet and reopen Settings — the value must persist.
        app.buttons["Done"].tap()
        openSecondaryTab("Settings")

        let darkModeAgain = app.switches["Dark Mode"]
        XCTAssertTrue(darkModeAgain.waitForExistence(timeout: 5))
        XCTAssertEqual(darkModeAgain.value as? String, toggledValue, "Dark Mode should persist after reopening")

        // Restore original state to avoid side effects on later runs.
        darkModeAgain.tap()
    }

    func testClearAllDataShowsConfirmationAlert() {
        openSecondaryTab("Settings")

        let clearButton = app.buttons["Clear All Data"]
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
        openSecondaryTab("Settings")

        let exportButton = app.buttons["Export Data"]
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
        openSecondaryTab("Reports")

        XCTAssertTrue(app.staticTexts["Summary Statistics"].waitForExistence(timeout: 5))

        // Switch the reporting period via the segmented control.
        let monthly = app.buttons["Monthly"]
        if monthly.waitForExistence(timeout: 3) { monthly.tap() }

        // Tapping an export action should respond (no-data alert on fresh install).
        let pdfButton = app.buttons["Export as PDF"]
        XCTAssertTrue(pdfButton.waitForExistence(timeout: 5))
        pdfButton.tap()

        let alert = app.alerts.firstMatch
        let shareSheet = app.otherElements["ActivityListView"]
        let appeared = alert.waitForExistence(timeout: 5) || shareSheet.waitForExistence(timeout: 5)
        XCTAssertTrue(appeared, "Export as PDF should respond")
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

        // Long-press surfaces the Quick Presets menu.
        logMeal.press(forDuration: 1.0)

        let presetAlert = app.alerts["Quick Presets"]
        XCTAssertTrue(presetAlert.waitForExistence(timeout: 5), "Long-press should show presets")
        XCTAssertTrue(presetAlert.buttons["Breakfast (40g carbs)"].exists)

        // Logging a preset should dismiss the menu (carb entry written in the background).
        presetAlert.buttons["Breakfast (40g carbs)"].tap()
        XCTAssertFalse(presetAlert.exists)
    }

    func testInsightsLoadsAndTimeRangeSwitches() {
        openSecondaryTab("Insights")

        XCTAssertTrue(app.staticTexts["AI-Powered Insights"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Weekly Patterns"].exists)

        // The time-range segmented control should switch without crashing.
        let month = app.buttons["1 Month"]
        if month.waitForExistence(timeout: 3) {
            month.tap()
            XCTAssertTrue(app.staticTexts["AI-Powered Insights"].exists)
        }
    }
}
