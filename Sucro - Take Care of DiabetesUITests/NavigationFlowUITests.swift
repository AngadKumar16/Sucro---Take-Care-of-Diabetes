//
//  NavigationFlowUITests.swift
//  Sucro - Take Care of Diabetes UITests
//
//  Each tab has its own navigation stack: the More button, pushing Help
//  articles, and the full-screen Monitor opened from Home.
//

import XCTest

final class NavigationFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    func testEveryMainTabHasTheMoreButton() {
        for tab in ["Home", "Log", "Monitor"] {
            app.buttons[tab].tap()
            XCTAssertTrue(app.buttons["moreButton"].waitForExistence(timeout: 5), "\(tab) should show More")
        }
    }

    func testLoggedReadingAppearsOnHomeAndOpensMonitor() {
        app.buttons["Log"].tap()

        let add = app.buttons["Add Glucose"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()

        let field = app.textFields["Enter value"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("123")
        app.buttons["Save"].tap()

        app.buttons["Home"].tap()
        let hero = app.buttons.containing(NSPredicate(format: "label BEGINSWITH '123'")).firstMatch
        XCTAssertTrue(hero.waitForExistence(timeout: 5), "Home should show the new reading")

        hero.tap()
        XCTAssertTrue(app.navigationBars["Monitor"].waitForExistence(timeout: 5), "Tapping the reading should open Monitor")

        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["moreButton"].waitForExistence(timeout: 5), "Done should return to Home")
    }

    func testHelpArticleOpensAndGoesBack() {
        app.buttons["moreButton"].tap()
        let helpTab = app.buttons["Help"]
        XCTAssertTrue(helpTab.waitForExistence(timeout: 5))
        helpTab.tap()

        let question = app.buttons["How do I export data?"]
        if !question.waitForExistence(timeout: 3) { app.swipeUp() }
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        question.tap()

        XCTAssertTrue(app.navigationBars["FAQ"].waitForExistence(timeout: 5))
        app.navigationBars["FAQ"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Help & Tutorials"].waitForExistence(timeout: 5))
    }
}
