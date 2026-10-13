//
//  ScreenshotUITests.swift
//  DiabetesCare UITests
//
//  App Store screenshots from demo data. Skipped in normal test runs; run
//  with scripts/screenshots.sh, which sets SCREENSHOTS=1, cleans up the
//  status bar and exports the images to docs/screenshots/.
//

import XCTest

final class ScreenshotUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["SCREENSHOTS"] == "1", "Screenshots only run from scripts/screenshots.sh")
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-demoData"]
    }

    private func snap(_ name: String) {
        // Let charts and transitions settle.
        sleep(1)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// iPhone has a tab bar; iPad shows the tabs at the top instead.
    private func tab(_ name: String) {
        let barButton = app.tabBars.buttons[name]
        let button = barButton.waitForExistence(timeout: 3) ? barButton : app.buttons[name].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10), "\(name) tab")
        button.tap()
    }

    func testTeen() {
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))
        snap("01-Today")

        tab("Learn")
        let path = app.buttons["learnYourPath"]
        XCTAssertTrue(path.waitForExistence(timeout: 5))
        path.tap()
        XCTAssertTrue(app.navigationBars["Your Path"].waitForExistence(timeout: 5))
        snap("02-YourPath")

        let quiz = app.buttons["skill.timeInRange"]
        for _ in 0..<5 where !quiz.isHittable { app.swipeUp() }
        quiz.tap()
        let option = app.buttons["quiz.option.2"]
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
        snap("03-Quiz")
        app.buttons["Close"].tap()

        tab("Trends")
        snap("05-Trends")

        tab("Settings")
        let family = app.buttons["familySettings"]
        XCTAssertTrue(family.waitForExistence(timeout: 5))
        family.tap()
        let preview = app.buttons["familyPreview"]
        for _ in 0..<4 where !preview.isHittable { app.swipeUp() }
        preview.tap()
        XCTAssertTrue(app.staticTexts["Last 12 Hours"].waitForExistence(timeout: 10))
        snap("06-FamilySees")
    }

    func testKid() {
        app.launchArguments += ["-stage", "kid"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Feeling off?"].waitForExistence(timeout: 10))
        snap("04-KidToday")
        app.buttons["kidGetHelp"].tap()
        XCTAssertTrue(app.navigationBars["Get Help"].waitForExistence(timeout: 5))
        snap("04b-KidGetHelp")
    }

    func testParent() {
        app.launchArguments = ["-uiTesting", "-demoFamily"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Last 12 Hours"].waitForExistence(timeout: 15))
        snap("07-ParentPhone")
    }
}
