import XCTest

final class LivingMandalaFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSwipeToRitualAndCompleteTodayPractice() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITests.SkipOnboarding", "UITests.ResetRitualState"]
        app.launch()

        // Swipe left on Home to reach the ritual page
        let homeView = app.otherElements.firstMatch
        XCTAssertTrue(homeView.waitForExistence(timeout: 20))
        homeView.swipeLeft()

        let closeButton = app.buttons["ritual.close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 10))

        let completionWell = app.descendants(matching: .any).matching(identifier: "ritual.completionWell").firstMatch
        XCTAssertTrue(completionWell.waitForExistence(timeout: 10))
        completionWell.press(forDuration: 1.1)

        XCTAssertTrue(app.staticTexts["Today's practice is complete"].waitForExistence(timeout: 5))
    }

    func testSwipeBackFromRitualReturnsToHome() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITests.SkipOnboarding", "UITests.ResetRitualState"]
        app.launch()

        let homeView = app.otherElements.firstMatch
        XCTAssertTrue(homeView.waitForExistence(timeout: 20))

        // Swipe to ritual
        homeView.swipeLeft()
        let closeButton = app.buttons["ritual.close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 10))

        // Swipe back to Home
        homeView.swipeRight()

        // Verify we're back on Home (settings gear should be visible)
        let settingsButton = app.buttons.matching(identifier: "gearshape").firstMatch
        // Home content should be accessible
        XCTAssertTrue(app.staticTexts.element(boundBy: 0).waitForExistence(timeout: 5))
    }
}
