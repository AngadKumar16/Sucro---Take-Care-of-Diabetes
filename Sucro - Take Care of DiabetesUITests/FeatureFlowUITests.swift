//
//  FeatureFlowUITests.swift
//  Sucro - Take Care of Diabetes UITests
//
//  One pass over every entry type and the Today, Log and Settings features
//  that act on them, each starting from an empty store.
//

import XCTest

final class FeatureFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetData"]
        app.launch()
    }

    // MARK: - Helpers

    private func openTab(_ name: String) {
        app.tabBars.buttons[name].tap()
        XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5), "\(name) should open")
    }

    private func addFromLog(_ item: String) {
        openTab("Log")
        let menu = app.buttons["addEntryMenu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        let button = app.buttons[item]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(item) should be in the + menu")
        button.tap()
    }

    private func type(_ text: String, into field: String) {
        let element = app.textFields[field]
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(field) field should exist")
        if !element.hasFocus { element.tap() }
        element.typeText(text)
    }

    /// Replaces the number in a text field.
    private func replace(_ field: String, with text: String) {
        let element = app.textFields[field]
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        // Double-tap selects the whole number so typing replaces it.
        element.doubleTap()
        element.typeText(text)
    }

    private func save() {
        let save = app.navigationBars.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(save.isEnabled, "Save should be enabled")
        save.tap()
    }

    private func logRow(_ prefix: String) -> XCUIElement {
        app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    private func scrollTo(_ element: XCUIElement) {
        for _ in 0..<8 {
            if element.waitForExistence(timeout: 1), element.isHittable { return }
            app.swipeUp()
        }
    }

    // MARK: - Entries

    func testCarbsCanBeAddedEditedAndDeleted() {
        addFromLog("Add Carbs")
        type("37", into: "Carbs")
        save()

        let row = logRow("37g carbs")
        XCTAssertTrue(row.waitForExistence(timeout: 5), "New carbs should be listed")
        row.tap()
        XCTAssertTrue(app.navigationBars["Edit Carbs"].waitForExistence(timeout: 5))
        replace("Carbs", with: "42")
        save()

        let edited = logRow("42g carbs")
        XCTAssertTrue(edited.waitForExistence(timeout: 5), "Edit should be saved")
        XCTAssertFalse(logRow("37g carbs").exists)

        edited.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        let confirm = app.buttons["Delete"].firstMatch
        if confirm.waitForExistence(timeout: 3) { confirm.tap() }
        XCTAssertTrue(edited.waitForNonExistence(timeout: 5), "Deleted entry should disappear")
    }

    func testInsulinShowsInLogAndAsActiveOnToday() {
        addFromLog("Add Insulin")
        type("2.5", into: "Dose")
        save()
        XCTAssertTrue(logRow("2.5 U").waitForExistence(timeout: 5), "Dose should be listed")

        openTab("Today")
        let iob = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH 'Estimated insulin on board: 2'")).firstMatch
        XCTAssertTrue(iob.waitForExistence(timeout: 5), "Today should show insulin on board")
    }

    func testActivityIsLogged() {
        addFromLog("Add Activity")
        type("23", into: "Duration")
        save()
        let row = app.buttons.containing(NSPredicate(format: "label CONTAINS '23 min'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Activity should be listed")
    }

    func testGlucoseReadingIsEditable() {
        addFromLog("Add Glucose")
        type("111", into: "Glucose")
        save()
        let row = logRow("111")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.navigationBars["Edit Glucose"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Log"].waitForExistence(timeout: 5))
    }

    func testEditedReadingUpdatesTodayAndTrends() {
        addFromLog("Add Glucose")
        type("150", into: "Glucose")
        save()
        openTab("Today")
        XCTAssertTrue(logRow("150").waitForExistence(timeout: 5), "Today shows the reading")

        openTab("Log")
        logRow("150").tap()
        XCTAssertTrue(app.navigationBars["Edit Glucose"].waitForExistence(timeout: 5))
        replace("Glucose", with: "165")
        save()
        XCTAssertTrue(logRow("165").waitForExistence(timeout: 5))

        openTab("Today")
        XCTAssertTrue(logRow("165").waitForExistence(timeout: 5), "Today should show the edited value")

        openTab("Trends")
        let average = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS '165'")).firstMatch
        XCTAssertTrue(average.waitForExistence(timeout: 5), "Trends should use the edited value")
    }

    func testLogFiltersAndDayNavigation() {
        addFromLog("Add Carbs")
        type("51", into: "Carbs")
        save()
        XCTAssertTrue(logRow("51g carbs").waitForExistence(timeout: 5))

        app.buttons["Insulin"].tap()
        XCTAssertFalse(logRow("51g carbs").waitForExistence(timeout: 2), "Insulin filter hides carbs")
        app.buttons["Carbs"].tap()
        XCTAssertTrue(logRow("51g carbs").waitForExistence(timeout: 5))
        app.buttons["All"].tap()

        app.buttons["Previous Day"].tap()
        XCTAssertFalse(logRow("51g carbs").waitForExistence(timeout: 2), "Yesterday has no entries")
        app.buttons["Next Day"].tap()
        XCTAssertTrue(logRow("51g carbs").waitForExistence(timeout: 5), "Back to today")
    }

    // MARK: - Today

    func testQuickBolusLogsADose() {
        openTab("Today")
        app.buttons["Quick Bolus"].tap()
        XCTAssertTrue(app.navigationBars["Quick Bolus"].waitForExistence(timeout: 5))
        let stepper = app.steppers["bolusStepper"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        stepper.buttons.element(boundBy: 1).tap()
        stepper.buttons.element(boundBy: 1).tap()
        app.buttons["Log Bolus"].tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))

        openTab("Log")
        XCTAssertTrue(logRow("1 U").waitForExistence(timeout: 5), "Bolus should be listed")
    }

    func testSiteChangeShowsOnToday() {
        openTab("Today")
        let change = app.buttons["Change Site"]
        scrollTo(change)
        change.tap()
        XCTAssertTrue(app.navigationBars["Change Site"].waitForExistence(timeout: 5))
        save()
        let inserted = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Inserted'")).firstMatch
        scrollTo(inserted)
        XCTAssertTrue(inserted.exists, "Today should show the new site")
    }

    /// Picks the first photo in the system photo picker. The picker runs out
    /// of process but its grid shows up in the app's tree. Relies on the
    /// sample photos every simulator ships with.
    private func pickFirstPhoto() {
        let photo = app.images.matching(identifier: "PXGGridLayout-Info").firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 10), "The photo library should show photos")
        // The cells report themselves as not hittable, so tap by position.
        photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    func testSitePhotoCanBeAddedSeenAndRemoved() {
        openTab("Today")
        let change = app.buttons["Change Site"]
        scrollTo(change)
        change.tap()
        XCTAssertTrue(app.navigationBars["Change Site"].waitForExistence(timeout: 5))

        let add = app.buttons["Add Photo"]
        scrollTo(add)
        add.tap()
        pickFirstPhoto()
        let preview = app.images["sitePhoto"]
        XCTAssertTrue(preview.waitForExistence(timeout: 10), "The picked photo should show in the form")
        XCTAssertTrue(app.buttons["Change Photo"].exists)
        save()

        // The photo is kept with the site change and shows when editing it.
        let card = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Site Change'")).firstMatch
        openEdit(card)
        scrollTo(preview)
        XCTAssertTrue(preview.exists, "The saved photo should show when editing")

        let remove = app.buttons["Remove Photo"]
        scrollTo(remove)
        remove.tap()
        XCTAssertTrue(preview.waitForNonExistence(timeout: 5))
        save()

        openEdit(card)
        let addAgain = app.buttons["Add Photo"]
        scrollTo(addAgain)
        XCTAssertTrue(addAgain.exists, "The photo should be gone after removing it")
        XCTAssertFalse(preview.exists)
    }

    /// Opens a Recent Activity card on Today, then Edit in its details.
    private func openEdit(_ card: XCUIElement) {
        openTab("Today")
        scrollTo(card)
        card.tap()
        XCTAssertTrue(app.navigationBars["Details"].waitForExistence(timeout: 5))
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.navigationBars["Edit Site Change"].waitForExistence(timeout: 5))
    }

    func testRecentEntryOpensDetailsAndTakesANote() {
        addFromLog("Add Carbs")
        type("44", into: "Carbs")
        save()

        openTab("Today")
        let card = app.buttons.containing(NSPredicate(format: "label CONTAINS '44g'")).firstMatch
        scrollTo(card)
        card.tap()
        XCTAssertTrue(app.navigationBars["Details"].waitForExistence(timeout: 5))
        app.buttons["Add Note"].tap()
        let note = app.textFields["Note"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.typeText("after walk")
        save()

        openTab("Log")
        let noted = app.buttons.containing(NSPredicate(format: "label CONTAINS 'after walk'")).firstMatch
        XCTAssertTrue(noted.waitForExistence(timeout: 5), "The note should be saved")
    }

    func testLowReadingShowsBannerWithCarbAction() {
        addFromLog("Add Glucose")
        type("62", into: "Glucose")
        save()

        openTab("Today")
        XCTAssertTrue(app.staticTexts["LOW GLUCOSE"].waitForExistence(timeout: 5), "A low should show the banner")
        app.buttons.containing(NSPredicate(format: "label CONTAINS 'Log Carbs'")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Add Carbs"].waitForExistence(timeout: 5), "Banner action opens carbs")
    }

    func testHighReadingShowsBanner() {
        addFromLog("Add Glucose")
        type("320", into: "Glucose")
        save()

        openTab("Today")
        XCTAssertTrue(app.staticTexts["HIGH GLUCOSE"].waitForExistence(timeout: 5))
    }

    func testHighBannerOpensKetoneAdvice() {
        addFromLog("Add Glucose")
        type("330", into: "Glucose")
        save()

        openTab("Today")
        XCTAssertTrue(app.staticTexts["HIGH GLUCOSE"].waitForExistence(timeout: 5))
        app.buttons.containing(NSPredicate(format: "label CONTAINS 'Check Ketones'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["When to Check Ketones"].waitForExistence(timeout: 5), "Ketone advice should open")
    }

    func testDoseAddsGlucoseCheckThatCanBeMarkedDone() {
        openTab("Today")
        app.buttons["Quick Bolus"].tap()
        let stepper = app.steppers["bolusStepper"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        stepper.buttons.element(boundBy: 1).tap()
        app.buttons["Log Bolus"].tap()

        let done = app.buttons["Mark Check Glucose done"]
        scrollTo(done)
        XCTAssertTrue(done.exists, "A dose should plan a glucose check")
        done.tap()
        XCTAssertTrue(done.waitForNonExistence(timeout: 5), "Done reminders leave Today's Plan")
    }

    // MARK: - Settings

    func testDailyBackupRunsWhenTurnedOn() {
        addFromLog("Add Glucose")
        type("120", into: "Glucose")
        save()

        openTab("Settings")
        let toggle = app.switches["Auto Backup"]
        scrollTo(toggle)
        if (toggle.value as? String) == "1" {
            toggle.switches.firstMatch.tap()
        }
        toggle.switches.firstMatch.tap()
        let last = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Last backup'")).firstMatch
        scrollTo(last)
        XCTAssertTrue(last.exists, "Turning backup on should run one")
    }

    func testMmolUnitChangesDisplay() {
        addFromLog("Add Glucose")
        type("180", into: "Glucose")
        save()

        openTab("Settings")
        let unit = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Unit'")).firstMatch
        scrollTo(unit)
        unit.tap()
        let mmol = app.buttons.matching(NSPredicate(format: "label == 'mmol/L'")).firstMatch
        XCTAssertTrue(mmol.waitForExistence(timeout: 5))
        mmol.tap()

        openTab("Log")
        XCTAssertTrue(logRow("10").waitForExistence(timeout: 5), "180 mg/dL should read as 10.0 mmol/L")
    }
}
