//
//  NavigationFlowUITests.swift
//  Sucro - Take Care of Diabetes UITests
//
//  The five tabs, logging from the Log tab, and pushing Help articles from
//  Settings.
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

    func testEveryTabOpensItsScreen() {
        for tab in ["Today", "Log", "Trends", "Learn", "Settings"] {
            app.tabBars.buttons[tab].tap()
            XCTAssertTrue(app.navigationBars[tab].waitForExistence(timeout: 5), "\(tab) tab should show its screen")
        }
    }

    func testLoggedReadingAppearsOnTodayAndOpensTrends() {
        app.tabBars.buttons["Log"].tap()

        let addMenu = app.buttons["addEntryMenu"]
        XCTAssertTrue(addMenu.waitForExistence(timeout: 5))
        addMenu.tap()
        let add = app.buttons["Add Glucose"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()

        let field = app.textFields["Glucose"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("123")
        app.buttons["Save"].tap()

        app.tabBars.buttons["Today"].tap()
        let hero = app.buttons.containing(NSPredicate(format: "label BEGINSWITH '123'")).firstMatch
        XCTAssertTrue(hero.waitForExistence(timeout: 5), "Today should show the new reading")

        hero.tap()
        XCTAssertTrue(app.navigationBars["Trends"].waitForExistence(timeout: 5), "Tapping the reading should open Trends")
    }

    func testGlossarySearchOpensATermAndSavesIt() {
        app.tabBars.buttons["Learn"].tap()
        XCTAssertTrue(app.navigationBars["Learn"].waitForExistence(timeout: 5))

        let search = app.searchFields.firstMatch
        if !search.waitForExistence(timeout: 2) { app.swipeDown() }
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("IOB")

        let result = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Insulin on Board'")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5), "Searching an abbreviation should find the term")
        result.tap()

        let inApp = app.staticTexts["In DiabetesCare"]
        XCTAssertTrue(inApp.waitForExistence(timeout: 5), "The term page should open")

        let save = app.buttons["saveTerm"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()
        XCTAssertEqual(save.label, "Unsave")
        save.tap()   // leave nothing saved for later runs
    }

    func testHelpArticleOpensAndGoesBack() {
        app.tabBars.buttons["Settings"].tap()
        let help = app.buttons["Help"]
        for _ in 0..<4 where !help.isHittable { app.swipeUp() }
        XCTAssertTrue(help.waitForExistence(timeout: 5))
        help.tap()

        let question = app.buttons["How do I export data?"]
        if !question.waitForExistence(timeout: 3) { app.swipeUp() }
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        question.tap()

        let answer = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Share PDF Report'")).firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "The article should open")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Help & Tutorials"].waitForExistence(timeout: 5))
    }
}
