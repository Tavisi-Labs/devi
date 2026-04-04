// MARK: - DeviTests/PanchangRitualViewModelTests.swift

import XCTest
@testable import Devi

@MainActor
final class PanchangRitualViewModelTests: XCTestCase {
    private let testKeys = [
        "mantraRitual.state",
        "city.name", "city.country", "city.latitude", "city.longitude", "city.timezoneIdentifier",
        "hasCompletedOnboarding"
    ]

    override func tearDown() {
        super.tearDown()
        let defaults = UserDefaults.standard
        for key in testKeys {
            defaults.removeObject(forKey: key)
        }
    }

    func testRitualDayHelperUsesSelectedTimezone() {
        let instant = isoDate("2026-04-03T00:30:00Z")

        XCTAssertEqual(
            PanchangViewModel.ritualDayString(for: instant, timezoneIdentifier: "America/Los_Angeles"),
            "2026-04-02"
        )
        XCTAssertEqual(
            PanchangViewModel.ritualDayString(for: instant, timezoneIdentifier: "Asia/Tokyo"),
            "2026-04-03"
        )

        let laMantra = PanchangViewModel.ritualMantra(
            for: instant,
            timezoneIdentifier: "America/Los_Angeles"
        )
        let tokyoMantra = PanchangViewModel.ritualMantra(
            for: instant,
            timezoneIdentifier: "Asia/Tokyo"
        )

        XCTAssertEqual(laMantra?.weekday, 5)
        XCTAssertEqual(tokyoMantra?.weekday, 6)
    }

    func testRitualHelperMatchesPanchangSunriseForShareAndReminderPaths() {
        let city = UserCity.popularCities[0]
        let panchang = PanchangCalculator.panchang(for: isoDate("2026-04-03T12:00:00Z"), city: city)

        let fromPanchang = PanchangViewModel.ritualMantra(
            for: panchang,
            timezoneIdentifier: city.timezoneIdentifier
        )
        let fromSunrise = PanchangViewModel.ritualMantra(
            for: panchang.solar.sunrise,
            timezoneIdentifier: city.timezoneIdentifier
        )

        XCTAssertEqual(fromPanchang?.weekday, fromSunrise?.weekday)
        XCTAssertEqual(fromPanchang?.deity, fromSunrise?.deity)
    }

    func testCompleteTodayRitualPersistsAcrossViewModelInstances() {
        UserDefaults.standard.removeObject(forKey: "mantraRitual.state")

        let vm = PanchangViewModel()
        let currentDay = vm.currentRitualDay

        let result = vm.completeTodayRitual()
        XCTAssertTrue(result.completedNewDay)
        XCTAssertTrue(vm.mantraRitualState.completedDates.contains(currentDay))
        XCTAssertTrue(vm.ritualSnapshot.completedToday)

        let reloaded = PanchangViewModel()
        XCTAssertTrue(reloaded.mantraRitualState.completedDates.contains(currentDay))
        XCTAssertEqual(reloaded.ritualSnapshot.completedCount, 1)
        XCTAssertTrue(reloaded.ritualSnapshot.completedToday)
    }

    private func isoDate(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value) ?? Date.distantPast
    }
}
