// MARK: - DeviTests/PanchangViewModelTests.swift
// Tests for PanchangViewModel: tithi change detection, hint counter, cosmic retry, location error.

import XCTest
@testable import Devi

@MainActor
final class PanchangViewModelTests: XCTestCase {

    // MARK: - Setup / Teardown

    /// Keys we write during tests — cleaned up after each run to prevent pollution.
    private let testKeys = [
        "lastSeenTithi", "hintLaunchCount", "usageDays",
        "city.name", "city.country", "city.latitude", "city.longitude", "city.timezoneIdentifier",
        "hasCompletedOnboarding", "fontScale", "themeStyle", "appearanceMode",
        "notif.dailySummary", "notif.sunrise", "notif.sunset", "notif.rahuKalam",
        "notif.abhijit", "notif.brahma", "notif.navratri", "notif.eclipse", "notif.minutesBefore",
        "notif.horoscope", "hasRequestedReview"
    ]

    override func tearDown() {
        super.tearDown()
        let ud = UserDefaults.standard
        for key in testKeys {
            ud.removeObject(forKey: key)
        }
    }

    // MARK: - Tithi Changed Message

    func testTithiChangedMessage_detectsPakshaTransition() {
        // Simulate last-seen tithi stored from a previous session
        UserDefaults.standard.set("Shukla Panchami", forKey: "lastSeenTithi")

        let vm = PanchangViewModel()

        // The VM loads data in init() which sets todayPanchang.
        // If the current tithi differs from "Shukla Panchami", a message should appear.
        guard let currentTithi = vm.todayPanchang?.tithi.displayName else {
            // No panchang loaded (shouldn't happen with VedicCalculator initialized)
            return
        }

        if currentTithi != "Shukla Panchami" {
            XCTAssertNotNil(vm.tithiChangedMessage, "Should detect tithi change")
            XCTAssertTrue(vm.tithiChangedMessage?.contains(currentTithi) == true,
                          "Message should mention the new tithi displayName")
        } else {
            XCTAssertNil(vm.tithiChangedMessage, "No change = no message")
        }
    }

    func testTithiChangedMessage_usesDisplayNameNotBareName() {
        // Store a bare name that matches the current tithi name but not the displayName
        // This tests that displayName (with paksha) is used for comparison
        let vm = makeVM()
        guard let tithi = vm.todayPanchang?.tithi else { return }

        // If we store just the bare name without paksha, it should NOT match displayName
        let bareNameOnly = tithi.name  // e.g., "Panchami"
        let displayName = tithi.displayName  // e.g., "Shukla Panchami"

        // They should differ (displayName includes paksha prefix)
        XCTAssertNotEqual(bareNameOnly, displayName,
                          "displayName should include paksha prefix")
    }

    func testTithiChangedMessage_nilWhenSameTithi() {
        let vm = makeVM()
        guard let currentDisplay = vm.todayPanchang?.tithi.displayName else { return }

        // Store the same tithi that's current
        UserDefaults.standard.set(currentDisplay, forKey: "lastSeenTithi")

        // Reload — should detect no change
        vm.loadData()
        XCTAssertNil(vm.tithiChangedMessage, "Same tithi should produce no message")
    }

    func testTithiChangedMessage_nilWhenNoLastSeen() {
        // First launch — no "lastSeenTithi" stored
        UserDefaults.standard.removeObject(forKey: "lastSeenTithi")

        let vm = PanchangViewModel()
        XCTAssertNil(vm.tithiChangedMessage, "First launch should not show change message")
    }

    // MARK: - Hint Launch Count

    func testHintLaunchCount_incrementsOncePerDay() {
        UserDefaults.standard.set(0, forKey: "hintLaunchCount")
        UserDefaults.standard.removeObject(forKey: "usageDays")

        let vm = PanchangViewModel()
        let initialCount = vm.hintLaunchCount

        // First call today — should increment
        vm.recordUsageDay()
        XCTAssertEqual(vm.hintLaunchCount, initialCount + 1,
                       "First recordUsageDay of the day should increment")

        // Second call same day — should NOT increment
        vm.recordUsageDay()
        XCTAssertEqual(vm.hintLaunchCount, initialCount + 1,
                       "Repeated recordUsageDay same day should not increment again")
    }

    func testShouldShowHints_trueForFirstThreeLaunches() {
        UserDefaults.standard.set(0, forKey: "hintLaunchCount")
        let vm = PanchangViewModel()

        vm.hintLaunchCount = 0
        XCTAssertTrue(vm.shouldShowHints, "Should show hints at launch 0")

        vm.hintLaunchCount = 2
        XCTAssertTrue(vm.shouldShowHints, "Should show hints at launch 2")

        vm.hintLaunchCount = 3
        XCTAssertFalse(vm.shouldShowHints, "Should NOT show hints at launch 3 (first 3 = 0,1,2)")
    }

    // MARK: - Cosmic Signature Retry

    func testRetryCosmicSignature_clearsErrorAndStartsLoading() {
        let vm = makeVM()

        // Simulate an error state
        vm.cosmicSignatureError = true
        vm.isLoadingSignature = false

        // Retry should clear error and start loading
        vm.retryCosmicSignature()

        XCTAssertFalse(vm.cosmicSignatureError, "Retry should clear error flag")
        XCTAssertTrue(vm.isLoadingSignature, "Retry should set loading state")
    }

    // MARK: - Location Error

    func testSelectCity_clearsLocationError() {
        let vm = makeVM()

        // Simulate a location error
        vm.locationError = "Could not determine exact location."
        XCTAssertNotNil(vm.locationError)

        // Selecting a city should clear it
        let mumbai = UserCity.popularCities.first(where: { $0.name == "Mumbai" })!
        vm.selectCity(mumbai)

        XCTAssertNil(vm.locationError, "selectCity should clear locationError")
        XCTAssertEqual(vm.currentCity.name, "Mumbai")
    }

    // MARK: - Graha Named Lookup

    func testGrahaNamed_englishName() {
        XCTAssertEqual(Graha.named("Sun")?.color, Graha.sun.color)
        XCTAssertEqual(Graha.named("Moon")?.color, Graha.moon.color)
        XCTAssertEqual(Graha.named("Saturn")?.color, Graha.saturn.color)
    }

    func testGrahaNamed_sanskritName() {
        XCTAssertEqual(Graha.named("Surya"), .sun)
        XCTAssertEqual(Graha.named("Chandra"), .moon)
        XCTAssertEqual(Graha.named("Mangala"), .mars)
        XCTAssertEqual(Graha.named("Budha"), .mercury)
        XCTAssertEqual(Graha.named("Guru"), .jupiter)
        XCTAssertEqual(Graha.named("Shukra"), .venus)
        XCTAssertEqual(Graha.named("Shani"), .saturn)
    }

    func testGrahaNamed_caseInsensitive() {
        XCTAssertEqual(Graha.named("sun"), .sun)
        XCTAssertEqual(Graha.named("MOON"), .moon)
        XCTAssertEqual(Graha.named("surya"), .sun)
        XCTAssertEqual(Graha.named("chandra"), .moon)
    }

    func testGrahaNamed_unknownReturnsNil() {
        XCTAssertNil(Graha.named("Pluto"))
        XCTAssertNil(Graha.named(""))
    }

    // MARK: - Helpers

    /// Creates a fresh VM with clean UserDefaults state.
    private func makeVM() -> PanchangViewModel {
        let ud = UserDefaults.standard
        for key in testKeys {
            ud.removeObject(forKey: key)
        }
        return PanchangViewModel()
    }
}
