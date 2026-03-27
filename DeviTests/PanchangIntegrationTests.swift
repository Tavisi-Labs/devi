// MARK: - DeviTests/PanchangIntegrationTests.swift
// Integration tests: full panchang computation for known dates across seasons.

import XCTest
@testable import Devi

final class PanchangIntegrationTests: XCTestCase {

    private let delhi = UserCity(
        name: "Delhi", country: "IN",
        latitude: 28.7041, longitude: 77.1025,
        timezoneIdentifier: "Asia/Kolkata"
    )

    private func date(year: Int, month: Int, day: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - Seasonal Sanity (Delhi)

    func testWinterSolstice() {
        // Dec 21, 2026 — short day in Delhi (~10.3 hours daylight)
        let panchang = PanchangCalculator.panchang(for: date(year: 2026, month: 12, day: 21), city: delhi)
        let dayLength = panchang.solar.sunset.timeIntervalSince(panchang.solar.sunrise) / 3600.0
        XCTAssertLessThan(dayLength, 11, "Winter solstice day should be < 11 hours at Delhi")
        XCTAssertGreaterThan(dayLength, 9, "Day should be at least 9 hours even in winter")
    }

    func testSummerSolstice() {
        // June 21, 2026 — long day in Delhi (~13.8 hours daylight)
        let panchang = PanchangCalculator.panchang(for: date(year: 2026, month: 6, day: 21), city: delhi)
        let dayLength = panchang.solar.sunset.timeIntervalSince(panchang.solar.sunrise) / 3600.0
        XCTAssertGreaterThan(dayLength, 13, "Summer solstice day should be > 13 hours at Delhi")
        XCTAssertLessThan(dayLength, 15, "Day should be < 15 hours at Delhi latitude")
    }

    func testEquinox() {
        // March 20, 2026 — ~12 hour day
        let panchang = PanchangCalculator.panchang(for: date(year: 2026, month: 3, day: 20), city: delhi)
        let dayLength = panchang.solar.sunset.timeIntervalSince(panchang.solar.sunrise) / 3600.0
        XCTAssertEqual(dayLength, 12, accuracy: 0.5, "Equinox day should be ~12 hours")
    }

    // MARK: - Cross-Timezone Consistency

    func testNewYorkPanchang() {
        let newYork = UserCity(
            name: "New York", country: "US",
            latitude: 40.7128, longitude: -74.0060,
            timezoneIdentifier: "America/New_York"
        )

        let panchang = PanchangCalculator.panchang(for: date(year: 2026, month: 6, day: 15), city: newYork)

        // Basic sanity — should produce valid output
        XCTAssertFalse(panchang.tithi.name.isEmpty)
        XCTAssertLessThan(panchang.solar.sunrise, panchang.solar.sunset)
        XCTAssertEqual(panchang.timeWindows.count, 5)
    }

    func testLondonPanchang() {
        let london = UserCity(
            name: "London", country: "UK",
            latitude: 51.5074, longitude: -0.1278,
            timezoneIdentifier: "Europe/London"
        )

        let panchang = PanchangCalculator.panchang(for: date(year: 2026, month: 12, day: 21), city: london)

        // London winter solstice: very short day (~8 hours)
        let dayLength = panchang.solar.sunset.timeIntervalSince(panchang.solar.sunrise) / 3600.0
        XCTAssertLessThan(dayLength, 9, "London winter day should be < 9 hours")
        XCTAssertGreaterThan(dayLength, 7, "London winter day should be > 7 hours")
    }

    // MARK: - Hora and Choghadiya

    func testHoraCount() {
        let panchang = PanchangCalculator.panchang(for: date(year: 2026, month: 3, day: 20), city: delhi)
        XCTAssertEqual(panchang.horas.count, 24, "Should have 24 horas (12 day + 12 night)")

        // First 12 should be daytime
        for i in 0..<12 {
            XCTAssertTrue(panchang.horas[i].isDaytime, "Hora \(i) should be daytime")
        }
        // Last 12 should be nighttime
        for i in 12..<24 {
            XCTAssertFalse(panchang.horas[i].isDaytime, "Hora \(i) should be nighttime")
        }
    }

    func testChoghadiyaCount() {
        let panchang = PanchangCalculator.panchang(for: date(year: 2026, month: 3, day: 20), city: delhi)
        XCTAssertEqual(panchang.choghadiyas.count, 16, "Should have 16 choghadiyas (8 day + 8 night)")
    }

    // MARK: - Multiple Karanas

    func testMultipleKaranas() {
        let panchang = PanchangCalculator.panchang(for: date(year: 2026, month: 3, day: 20), city: delhi)
        XCTAssertGreaterThanOrEqual(panchang.karanas.count, 2,
                                   "Should typically have 2+ karanas per day (~6 hours each)")
        XCTAssertLessThanOrEqual(panchang.karanas.count, 5,
                                "Should not exceed ~5 karanas per day")

        // Each karana should have a valid name
        for karana in panchang.karanas {
            XCTAssertFalse(karana.name.isEmpty, "Karana name should not be empty")
        }
    }

    // MARK: - Festival Integration

    func testFestivalsAppearInPanchang() {
        // Diwali 2026 — festivals should be populated
        // Note: exact date depends on FestivalEngine computation
        let festivals = FestivalEngine.festivals(forYear: 2026)
        guard let diwaliDate = festivals.first(where: { $0.value.contains("Diwali") })?.key else {
            XCTFail("Diwali not found in 2026 festivals")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        guard let diwaliNSDate = formatter.date(from: diwaliDate) else {
            XCTFail("Could not parse Diwali date")
            return
        }

        let panchang = PanchangCalculator.panchang(for: diwaliNSDate, city: delhi)
        XCTAssertTrue(panchang.festivals.contains("Diwali"),
                      "Panchang for Diwali date should include 'Diwali' festival")
    }

    // MARK: - Date String Format

    func testDateStringFormat() {
        let panchang = PanchangCalculator.panchang(for: date(year: 2026, month: 3, day: 20), city: delhi)
        XCTAssertEqual(panchang.dateString, "2026-03-20", "Date string should be ISO format")
    }
}
