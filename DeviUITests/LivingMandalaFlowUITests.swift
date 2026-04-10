import XCTest

final class LivingMandalaFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "UITests.SkipOnboarding",
            "UITests.ResetSessionState",
            "UITests.SkipSplash"
        ]
        return app
    }

    private func waitForHome(in app: XCUIApplication, timeout: TimeInterval = 20) {
        XCTAssertTrue(app.staticTexts["Live Sky"].waitForExistence(timeout: timeout))
    }

    func testHomeLoadsOnSmallerPhone() throws {
        let app = makeApp()
        app.launch()

        waitForHome(in: app)
        XCTAssertTrue(app.staticTexts["Sunrise"].exists)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "home.openRitual").firstMatch.exists)
    }

    func testResourcesCardShowsQuickExplainers() throws {
        let app = makeApp()
        app.launch()

        waitForHome(in: app)
        XCTAssertTrue(app.staticTexts["NEW TO THESE TERMS?"].waitForExistence(timeout: 10))
        XCTAssertTrue(
            app.staticTexts["Quick explainers for the concepts that show up throughout Devi."].waitForExistence(timeout: 5)
        )
    }

    func testCaptureHomeScreen() throws {
        let app = makeApp()
        app.launch()

        waitForHome(in: app)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "home-iphone"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
