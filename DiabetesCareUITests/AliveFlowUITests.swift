//
//  AliveFlowUITests.swift
//  DiabetesCare UITests
//
//  The features that make the app feel alive and do more: carb lookup,
//  ketones and sick days, undo, supplies, the school card, the weekly
//  recap, the new Trends sections, stickers, and a parent's reply to a
//  help request.
//

import XCTest

final class AliveFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetData"]
    }

    private func openTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(name) tab should exist")
        tab.tap()
    }

    private func scrollTo(_ element: XCUIElement, attempts: Int = 8) {
        for _ in 0..<attempts where !(element.exists && element.isHittable) { app.swipeUp() }
    }

    func testLookUpCarbsFillsTheMeal() {
        app.launch()
        openTab("Log")
        app.buttons["addEntryMenu"].tap()
        app.buttons["Add Carbs"].tap()

        let lookUp = app.buttons["lookUpCarbs"]
        XCTAssertTrue(lookUp.waitForExistence(timeout: 5))
        lookUp.tap()

        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("apple raw")

        let apple = app.buttons["food.usda.2709215"]
        XCTAssertTrue(apple.waitForExistence(timeout: 10), "Apple, raw comes from the bundled USDA foods")
        apple.tap()

        let add = app.buttons["addFoodToMeal"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()

        let grams = app.textFields["Carbs"]
        XCTAssertTrue(grams.waitForExistence(timeout: 5))
        XCTAssertEqual(grams.value as? String, "30", "One medium apple is about 30 g")
        app.navigationBars["Add Carbs"].buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["30g carbs"].waitForExistence(timeout: 5))
    }

    func testKetonesAreLoggedAndFiltered() {
        app.launch()
        openTab("Log")
        app.buttons["addEntryMenu"].tap()
        app.buttons["Add Ketones"].tap()

        let field = app.textFields["ketoneValue"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("1.2")
        XCTAssertTrue(app.staticTexts["Raised. Drink water and check again in 1–2 hours."].waitForExistence(timeout: 5),
                      "The level is explained before saving")
        app.navigationBars["Add Ketones"].buttons["Save"].tap()

        app.buttons["Ketones"].tap()
        XCTAssertTrue(app.staticTexts["1.2 mmol/L"].waitForExistence(timeout: 5))
    }

    func testSickDayTagShowsTheChecklist() {
        app.launch()
        let sick = app.buttons["dayTag.sick"]
        scrollTo(sick)
        XCTAssertTrue(sick.waitForExistence(timeout: 5))
        sick.tap()

        let logKetones = app.buttons["sickDayLogKetones"]
        for _ in 0..<4 where !logKetones.exists { app.swipeDown() }
        XCTAssertTrue(logKetones.waitForExistence(timeout: 5), "Tagging the day Sick shows the checklist")
        logKetones.tap()
        XCTAssertTrue(app.navigationBars["Add Ketones"].waitForExistence(timeout: 5))
    }

    func testUndoRemovesWhatWasJustLogged() {
        app.launchArguments.append("-toasts")
        app.launch()
        openTab("Log")
        app.buttons["addEntryMenu"].tap()
        app.buttons["Add Carbs"].tap()
        let grams = app.textFields["Carbs"]
        XCTAssertTrue(grams.waitForExistence(timeout: 5))
        grams.typeText("42")
        app.navigationBars["Add Carbs"].buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["42g carbs"].waitForExistence(timeout: 5))
        let undo = app.buttons["toastUndo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3))
        undo.tap()
        XCTAssertTrue(app.staticTexts["42g carbs"].waitForNonExistence(timeout: 5), "Undo deletes the entry again")
    }

    func testSuppliesCountsAndSchoolCard() {
        app.launch()
        openTab("Settings")
        let supplies = app.buttons["Supplies"]
        scrollTo(supplies)
        XCTAssertTrue(supplies.waitForExistence(timeout: 5))
        supplies.tap()

        app.buttons["trackSupply"].tap()
        let sensors = app.buttons["CGM sensors"]
        XCTAssertTrue(sensors.waitForExistence(timeout: 5))
        sensors.tap()
        XCTAssertTrue(app.staticTexts["10 left"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let card = app.buttons["School & Sitter Card"]
        scrollTo(card)
        card.tap()
        XCTAssertTrue(app.staticTexts["Signs of a low"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["shareSchoolCard"].waitForExistence(timeout: 5), "The card renders as a PDF to share")
    }

    func testWeeklyRecapAndTrendsSectionsWithDemoData() {
        app.launchArguments += ["-stage", "teen", "-demoData"]
        app.launch()

        let recap = app.buttons["openWeeklyRecap"]
        scrollTo(recap)
        XCTAssertTrue(recap.waitForExistence(timeout: 5), "Today tells the story of the day")
        recap.tap()
        XCTAssertTrue(app.otherElements["recapCard"].waitForExistence(timeout: 5) || app.staticTexts["in range"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["shareWeek"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        openTab("Trends")
        app.buttons["Week"].tap()
        let typicalDay = app.staticTexts["Your Typical Day"]
        scrollTo(typicalDay)
        XCTAssertTrue(typicalDay.exists)
        let afterMeals = app.staticTexts["After Meals"]
        scrollTo(afterMeals)
        XCTAssertTrue(afterMeals.exists)
        let sportsDays = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Sports days'")).firstMatch
        scrollTo(sportsDays)
        XCTAssertTrue(sportsDays.exists, "Day tags are compared on Trends")
    }

    func testGuideStickerGrowsThePath() {
        app.launchArguments += ["-stage", "teen"]
        app.launch()
        openTab("Learn")
        let guide = app.buttons["guide.ranges"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        guide.tap()
        let collect = app.buttons["collectSticker"]
        scrollTo(collect, attempts: 15)
        XCTAssertTrue(collect.waitForExistence(timeout: 5))
        collect.tap()
        XCTAssertTrue(app.staticTexts["Sticker collected"].waitForExistence(timeout: 5))
    }

    func testParentRepliesToAHelpRequest() {
        app.launchArguments.append("-demoFamily")
        app.launch()
        XCTAssertTrue(app.navigationBars["Maya"].waitForExistence(timeout: 15))
        let reply = app.buttons["reply.onMyWay"]
        XCTAssertTrue(reply.waitForExistence(timeout: 10), "A waiting help request offers one-tap replies")
        reply.tap()
        XCTAssertTrue(app.staticTexts["Sent: On my way!"].waitForExistence(timeout: 5))
    }
}
