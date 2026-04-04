import XCTest

final class LivingMandalaFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeCardOpensRitualAndCompletesTodayPractice() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITests.SkipOnboarding", "UITests.ResetRitualState"]
        app.launch()

        let mantraCard = app.buttons["home.mantraCard"]
        XCTAssertTrue(mantraCard.waitForExistence(timeout: 20))
        mantraCard.tap()

        let closeButton = app.buttons["ritual.close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 10))

        let completionWell = app.descendants(matching: .any).matching(identifier: "ritual.completionWell").firstMatch
        XCTAssertTrue(completionWell.waitForExistence(timeout: 10))
        completionWell.press(forDuration: 1.1)

        XCTAssertTrue(app.staticTexts["Today's practice is complete"].waitForExistence(timeout: 5))
    }
}
