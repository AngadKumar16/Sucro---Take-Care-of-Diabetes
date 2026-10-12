//
//  GrowthFlowUITests.swift
//  DiabetesCare UITests
//
//  "Grows with you": the setup screen, the kid's Today, the grown-up
//  passcode, quiz skills that open features, the family preview, and a
//  caregiver's phone. Stages are set with `-stage kid|teen`; the test
//  passcode is 1234.
//

import XCTest

final class GrowthFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetData"]
    }

    private func enter(_ code: String) {
        for digit in code {
            app.buttons[String(digit)].tap()
        }
    }

    private func openTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(name) tab should exist")
        tab.tap()
    }

    private func scrollTo(_ element: XCUIElement, attempts: Int = 6) {
        for _ in 0..<attempts where !element.isHittable { app.swipeUp() }
    }

    func testSetupAsKidSetsPasscodeAndSimplifiesToday() {
        app.launchArguments.append("-resetSetup")
        app.launch()

        XCTAssertTrue(app.staticTexts["Who's Using DiabetesCare?"].waitForExistence(timeout: 5))
        app.buttons["setup.kid"].tap()

        XCTAssertTrue(app.staticTexts["Grown-Up Passcode"].waitForExistence(timeout: 5))
        enter("1234")
        XCTAssertTrue(app.staticTexts["Type It Again"].waitForExistence(timeout: 5))
        enter("1234")

        XCTAssertTrue(app.staticTexts["Feeling off?"].waitForExistence(timeout: 5), "A kid's Today offers help first")
        XCTAssertFalse(app.buttons["Quick Bolus"].exists, "Kids don't get the bolus key")
    }

    func testKidNeedsGrownUpToChangeRanges() {
        app.launchArguments += ["-stage", "kid"]
        app.launch()
        openTab("Settings")

        let unlock = app.buttons["unlockThresholds"]
        scrollTo(unlock)
        XCTAssertTrue(unlock.waitForExistence(timeout: 5))
        unlock.tap()

        XCTAssertTrue(app.staticTexts["Ask a Grown-Up"].waitForExistence(timeout: 5))
        enter("0000")
        XCTAssertTrue(app.staticTexts["That's not the passcode."].waitForExistence(timeout: 5))
        enter("1234")

        let reset = app.buttons["Reset to Common Defaults"]
        XCTAssertTrue(reset.waitForExistence(timeout: 5), "The right passcode unlocks the ranges")
    }

    func testQuizSkillsOpenInsulinLoggingForKid() {
        app.launchArguments += ["-stage", "kid"]
        app.launch()

        // Before: logging insulin asks for a grown-up.
        openTab("Log")
        app.buttons["addEntryMenu"].tap()
        app.buttons["Add Insulin"].tap()
        XCTAssertTrue(app.staticTexts["Ask a Grown-Up"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()

        openTab("Learn")
        let path = app.buttons["learnYourPath"]
        XCTAssertTrue(path.waitForExistence(timeout: 5))
        path.tap()

        pass(.init(id: "skill.ranges", answers: [1, 0, 0]))
        pass(.init(id: "skill.treatingLows", answers: [1, 1, 2]))

        // After: it opens straight away.
        openTab("Log")
        app.buttons["addEntryMenu"].tap()
        app.buttons["Add Insulin"].tap()
        XCTAssertTrue(app.navigationBars["Add Insulin"].waitForExistence(timeout: 5), "Two skills open insulin logging without a passcode")
    }

    private struct Quiz {
        let id: String
        let answers: [Int]
    }

    private func pass(_ quiz: Quiz) {
        let row = app.buttons[quiz.id]
        scrollTo(row)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "\(quiz.id) should be listed")
        row.tap()
        for (index, answer) in quiz.answers.enumerated() {
            let option = app.buttons["quiz.option.\(answer)"]
            XCTAssertTrue(option.waitForExistence(timeout: 5))
            option.tap()
            let next = app.buttons[index + 1 < quiz.answers.count ? "Next Question" : "See How You Did"]
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            next.tap()
        }
        XCTAssertTrue(app.staticTexts["Skill Learned!"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
    }

    func testFamilyPreviewShowsWhatFamilySees() {
        app.launchArguments += ["-stage", "teen", "-demoData"]
        app.launch()
        openTab("Settings")

        let family = app.buttons["familySettings"]
        XCTAssertTrue(family.waitForExistence(timeout: 5))
        family.tap()

        let preview = app.buttons["familyPreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        preview.tap()

        XCTAssertTrue(app.staticTexts["This is what your family sees on their phone."].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Last 12 Hours"].waitForExistence(timeout: 5), "Shared readings reach the preview")
    }

    func testCaregiverPhoneShowsFamilyTab() {
        app.launchArguments.append("-resetSetup")
        app.launch()

        let caregiver = app.buttons["setup.caregiver"]
        scrollTo(caregiver)
        XCTAssertTrue(caregiver.waitForExistence(timeout: 5))
        caregiver.tap()

        XCTAssertTrue(app.tabBars.buttons["Family"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Nobody to Follow Yet"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.buttons["Log"].exists, "A caregiver's phone doesn't log for itself")
    }
}
