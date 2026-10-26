//
//  DemoReelUITests.swift
//  DiabetesCare UITests
//
//  Footage for the CAC demo video: each test walks one of the app's most
//  distinctive flows at a human pace while scripts/record-demo.sh records the
//  simulator, and saves stills along the way. Skipped in normal test runs.
//

import XCTest

final class DemoReelUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["DEMO_REEL"] == "1", "Demo footage only runs from scripts/record-demo.sh")
        // A clip that misses one beat should still record the rest.
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
    }

    // MARK: - Pacing and helpers

    /// Holds the frame so a viewer can read it.
    private func hold(_ seconds: Double) { usleep(useconds_t(seconds * 1_000_000)) }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func tab(_ name: String) {
        let button = app.tabBars.buttons[name]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "\(name) tab")
        button.tap()
    }

    private func scrollTo(_ element: XCUIElement, attempts: Int = 8) {
        for _ in 0..<attempts where !(element.exists && element.isHittable) {
            app.swipeUp(velocity: .slow)
        }
    }

    private func tapWhenReady(_ element: XCUIElement, timeout: TimeInterval = 8) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(element)")
        if element.exists { element.tap() }
    }

    /// Types the grown-up passcode one digit at a time, so the dots fill on camera.
    private func enterPasscode(_ code: String = "1234") {
        for digit in code {
            tapWhenReady(app.buttons[String(digit)])
            hold(0.35)
        }
    }

    private func passQuiz(_ id: String, answers: [Int]) {
        let row = app.buttons[id]
        scrollTo(row)
        tapWhenReady(row)
        hold(1.2)
        for (index, answer) in answers.enumerated() {
            tapWhenReady(app.buttons["quiz.option.\(answer)"])
            hold(1.8) // the reason appears under the answer
            tapWhenReady(app.buttons[index + 1 < answers.count ? "Next Question" : "See How You Did"])
            hold(0.8)
        }
    }

    // MARK: - Clips

    /// Setup: "Who's using DiabetesCare?" → Kid → the grown-up makes a passcode → the kid's Today.
    func test01Setup() {
        app.launchArguments += ["-resetSetup", "-resetData"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Who's Using DiabetesCare?"].waitForExistence(timeout: 10))
        hold(2.5)
        snap("setup")
        tapWhenReady(app.buttons["setup.kid"])
        hold(1.2)
        snap("setup-passcode")
        enterPasscode()
        hold(0.8)
        enterPasscode()
        XCTAssertTrue(app.staticTexts["Feeling off?"].waitForExistence(timeout: 10))
        hold(3)
        snap("setup-kid-today")
    }

    /// A kid's day: the plant on Today, Get Help, 15 g of sugar, and the recheck in the Dynamic Island.
    func test02KidHelpAndLiveActivity() {
        app.launchArguments += ["-demoData", "-stage", "kid"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Feeling off?"].waitForExistence(timeout: 10))
        hold(2.5)
        snap("kid-today")
        let plant = app.descendants(matching: .any)["todayPlant"].firstMatch
        if plant.exists { scrollTo(plant, attempts: 3); hold(2); snap("kid-plant") }
        app.swipeDown(velocity: .slow)
        tapWhenReady(app.buttons["kidGetHelp"])
        hold(2.5)
        snap("kid-help")
        let sugar = app.buttons["I Had 15 g of Sugar"]
        if sugar.waitForExistence(timeout: 5) { sugar.tap() }
        hold(2.5)
        snap("kid-help-logged")
        // Out to the Home Screen: the 15-minute recheck keeps counting in the Dynamic Island.
        XCUIDevice.shared.press(.home)
        hold(4)
        snap("live-activity")
        app.activate()
        hold(1.5)
    }

    /// The grown-up passcode on a kid's phone (ranges are always a grown-up's call), then the
    /// insulin pen dial, which Maya's two skills have already opened for her.
    func test03PasscodeAndInsulinPen() {
        app.launchArguments += ["-demoData", "-stage", "kid"]
        app.launch()
        tab("Settings")
        let unlock = app.buttons["unlockThresholds"]
        scrollTo(unlock)
        hold(1)
        tapWhenReady(unlock)
        XCTAssertTrue(app.staticTexts["Ask a Grown-Up"].waitForExistence(timeout: 5))
        hold(2)
        snap("passcode")
        enterPasscode()
        hold(2.5)
        snap("ranges-unlocked")
        tab("Log")
        tapWhenReady(app.buttons["addEntryMenu"])
        hold(0.8)
        tapWhenReady(app.buttons["Add Insulin"])
        XCTAssertTrue(app.navigationBars["Add Insulin"].waitForExistence(timeout: 8))
        hold(2)
        snap("insulin-pen")
        let stepper = app.steppers["bolusStepper"]
        if stepper.waitForExistence(timeout: 3) {
            for _ in 0..<4 { stepper.buttons.element(boundBy: 1).tap(); hold(0.6) }
            hold(1.5)
            snap("insulin-pen-dialed")
        }
    }

    /// Your Path: pass the last quiz, then move up from Kid to Teen.
    func test04EarnAndMoveUp() {
        app.launchArguments += ["-demoData", "-stage", "kid", "-toasts"]
        app.launch()
        tab("Learn")
        tapWhenReady(app.buttons["learnYourPath"])
        XCTAssertTrue(app.navigationBars["Your Path"].waitForExistence(timeout: 8))
        hold(2.5)
        snap("path-kid")
        passQuiz("skill.timeInRange", answers: [2, 0, 1])
        XCTAssertTrue(app.staticTexts["Skill Learned!"].waitForExistence(timeout: 5))
        hold(2.5)
        snap("skill-learned")
        tapWhenReady(app.buttons["Done"])
        hold(1)
        // The Move Up card sits at the top of Your Path; scroll back so it's clear of the bar.
        for _ in 0..<3 { app.swipeDown(velocity: .slow) }
        let moveUp = app.buttons["moveUpStage"]
        hold(1.5)
        snap("ready-to-move-up")
        tapWhenReady(moveUp)
        XCTAssertTrue(app.staticTexts["Ask a Grown-Up"].waitForExistence(timeout: 5))
        hold(1.5)
        enterPasscode()
        // The sheet closes first, then the stage changes and the ladder fills Teen.
        XCTAssertTrue(app.staticTexts["Next: Adult"].waitForExistence(timeout: 10))
        hold(3.5)
        snap("moved-up-teen")
    }

    /// The body map: where the next site goes, and which spots are resting.
    func test05SiteBodyMap() {
        app.launchArguments += ["-demoData"]
        app.launch()
        let change = app.buttons["Change Site"]
        scrollTo(change)
        tapWhenReady(change)
        XCTAssertTrue(app.navigationBars["Change Site"].waitForExistence(timeout: 5))
        hold(3)
        snap("body-map")
        app.swipeUp(velocity: .slow)
        hold(2)
        snap("body-map-more")
    }

    /// Carb lookup: search the USDA foods, pick an apple, see the carbs fill in.
    func test06CarbLookup() {
        app.launchArguments += ["-demoData"]
        app.launch()
        tab("Log")
        tapWhenReady(app.buttons["addEntryMenu"])
        hold(0.6)
        tapWhenReady(app.buttons["Add Carbs"])
        hold(1.5)
        snap("add-carbs")
        tapWhenReady(app.buttons["lookUpCarbs"])
        let search = app.searchFields.firstMatch
        tapWhenReady(search)
        for character in "apple raw" { search.typeText(String(character)); usleep(120_000) }
        hold(1.5)
        snap("carb-search")
        tapWhenReady(app.buttons["food.usda.2709215"], timeout: 10)
        hold(1.5)
        tapWhenReady(app.buttons["addFoodToMeal"])
        hold(2.5)
        snap("carbs-filled")
    }

    /// Trends: time in range as test tubes, the typical day, after meals.
    func test07Trends() {
        app.launchArguments += ["-demoData"]
        app.launch()
        tab("Trends")
        hold(2.5)
        snap("trends")
        for index in 1...3 {
            app.swipeUp(velocity: .slow)
            hold(2)
            snap("trends-\(index)")
        }
    }

    /// The weekly recap: the week in sentences, made to share.
    func test08WeeklyRecap() {
        app.launchArguments += ["-demoData", "-stage", "teen"]
        app.launch()
        let recap = app.buttons["openWeeklyRecap"]
        scrollTo(recap)
        hold(1.5)
        snap("today-story")
        tapWhenReady(recap)
        hold(3)
        snap("weekly-recap")
        app.swipeUp(velocity: .slow)
        hold(2)
        snap("weekly-recap-days")
    }

    /// Sick day: tag the day, get the checklist with the latest ketone check.
    func test09SickDay() {
        app.launchArguments += ["-demoData"]
        app.launch()
        let sick = app.buttons["dayTag.sick"]
        scrollTo(sick)
        hold(1.5)
        snap("day-tags")
        tapWhenReady(sick)
        let checklist = app.buttons["sickDayLogKetones"]
        for _ in 0..<4 where !checklist.exists { app.swipeDown(velocity: .slow) }
        hold(2.5)
        snap("sick-day")
    }

    /// See What Family Sees: exactly what's shared, from the teen's own phone.
    func test10FamilySees() {
        app.launchArguments += ["-demoData", "-stage", "teen"]
        app.launch()
        tab("Settings")
        tapWhenReady(app.buttons["familySettings"])
        hold(2)
        snap("family-settings")
        let preview = app.buttons["familyPreview"]
        scrollTo(preview)
        tapWhenReady(preview)
        XCTAssertTrue(app.staticTexts["Last 12 Hours"].waitForExistence(timeout: 10))
        hold(3)
        snap("family-sees")
    }

    /// Mom's phone: Maya's help request, the urgent-low alert, a one-tap reply.
    func test11ParentPhone() {
        app.launchArguments += ["-demoFamily"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Maya"].waitForExistence(timeout: 15))
        hold(3)
        snap("parent-help-request")
        // The sample "Maya: Urgent Low" notification fires 10 s after launch.
        hold(8)
        snap("parent-urgent-low")
        hold(2)
        tapWhenReady(app.buttons["reply.onMyWay"])
        XCTAssertTrue(app.staticTexts["Sent: On my way!"].waitForExistence(timeout: 5))
        hold(2.5)
        snap("parent-replied")
    }

    /// The school and sitter card: low signs, the rule of 15, who to call.
    func test12SchoolCard() {
        app.launchArguments += ["-demoData", "-stage", "kid"]
        app.launch()
        tab("Settings")
        let card = app.buttons["School & Sitter Card"]
        scrollTo(card, attempts: 12)
        tapWhenReady(card)
        hold(3)
        snap("school-card")
        app.swipeUp(velocity: .slow)
        hold(2)
        snap("school-card-more")
    }

    /// Siri and Shortcuts: the app's shortcuts, then "Check My Glucose" answers with the latest
    /// reading (the same snippet Siri shows; Siri itself doesn't draw in the simulator).
    func test13Siri() {
        app.launchArguments += ["-demoData"]
        app.launch()
        hold(2)
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.launch()
        hold(2)
        snap("shortcuts-step1")
        let continueButton = shortcuts.buttons["Continue"]
        if continueButton.exists { continueButton.tap(); hold(1) }
        let app = shortcuts.staticTexts["DiabetesCare"].firstMatch
        for _ in 0..<6 where !app.exists { shortcuts.swipeUp(velocity: .slow) }
        if app.exists { app.tap(); hold(2) }
        snap("shortcuts-app")
        let check = shortcuts.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Check'")).firstMatch
        if check.waitForExistence(timeout: 3) { check.tap() }
        hold(4)
        snap("siri-glucose")
    }

    /// The glucose widget on the Home Screen, added the way a person would.
    func test14Widgets() {
        app.launchArguments += ["-demoData", "-stage", "kid"]
        app.launch()
        hold(2)
        XCUIDevice.shared.press(.home)
        hold(1)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).press(forDuration: 1.6)
        hold(1)
        snap("widgets-step1")
        let edit = springboard.buttons["Edit"]
        if edit.waitForExistence(timeout: 3) { edit.tap(); hold(0.8) }
        let add = springboard.buttons["Add Widget"]
        if add.waitForExistence(timeout: 3) { add.tap(); hold(1.5) }
        snap("widgets-step2")
        let search = springboard.searchFields.firstMatch
        if search.waitForExistence(timeout: 3) {
            search.tap()
            search.typeText("DiabetesCare")
            hold(1.5)
        }
        snap("widgets-step3")
        let result = springboard.cells.containing(.staticText, identifier: "DiabetesCare").firstMatch
        if result.waitForExistence(timeout: 3) { result.tap() } else { springboard.staticTexts["DiabetesCare"].firstMatch.tap() }
        hold(2)
        snap("widgets-gallery")
        // Swipe to the medium size, which has the 3-hour sparkline.
        springboard.swipeLeft()
        hold(1.5)
        snap("widgets-gallery-medium")
        let addWidget = springboard.buttons["Add Widget"]
        if addWidget.waitForExistence(timeout: 3) { addWidget.tap() }
        hold(2)
        snap("widgets-placed")
        let done = springboard.buttons["Done"]
        if done.waitForExistence(timeout: 3) { done.tap() }
        hold(3)
        snap("widgets-home")
    }
}
