// MARK: - DeviTests/PanchangCalculatorTests.swift
// Tests for PanchangCalculator: tithiIndex, nakshatraIndex, yogaIndex, karanaIndex,
// karanaName, computeLunarMonth, computeTimeWindows.

import XCTest
@testable import Devi

final class PanchangCalculatorTests: XCTestCase {

    // MARK: - Helper: Create JD for a date at Delhi sunrise (~6:00 IST = 00:30 UTC)

    private func delhiSunriseJD(year: Int, month: Int, day: Int) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        // Approximate Delhi sunrise at 00:30 UTC (6:00 IST)
        let date = cal.date(from: DateComponents(year: year, month: month, day: day, hour: 0, minute: 30))!
        return VedicCalculator.shared.julianDay(from: date)
    }

    // MARK: - Tithi Index

    func testTithiIndexRange() {
        // Tithi index should always be 1-30
        let jd = delhiSunriseJD(year: 2026, month: 3, day: 20)
        let idx = PanchangCalculator.tithiIndex(at: jd)
        XCTAssertGreaterThanOrEqual(idx, 1, "Tithi index should be >= 1")
        XCTAssertLessThanOrEqual(idx, 30, "Tithi index should be <= 30")
    }

    func testTithiChangesOverMonth() {
        // Over 30 days, we should see multiple different tithi values
        var seen = Set<Int>()
        for day in 1...30 {
            let jd = delhiSunriseJD(year: 2026, month: 3, day: day)
            seen.insert(PanchangCalculator.tithiIndex(at: jd))
        }
        // Should see at least 20 distinct tithis in 30 days (some might repeat at boundaries)
        XCTAssertGreaterThan(seen.count, 20, "Should see many distinct tithis over 30 days")
    }

    // MARK: - Nakshatra Index

    func testNakshatraIndexRange() {
        let jd = delhiSunriseJD(year: 2026, month: 3, day: 20)
        let idx = PanchangCalculator.nakshatraIndex(at: jd)
        XCTAssertGreaterThanOrEqual(idx, 1, "Nakshatra index should be >= 1")
        XCTAssertLessThanOrEqual(idx, 27, "Nakshatra index should be <= 27")
    }

    func testNakshatraChangesOverMonth() {
        var seen = Set<Int>()
        for day in 1...30 {
            let jd = delhiSunriseJD(year: 2026, month: 3, day: day)
            seen.insert(PanchangCalculator.nakshatraIndex(at: jd))
        }
        // Moon traverses all 27 nakshatras in ~27 days
        XCTAssertGreaterThan(seen.count, 20, "Should see many distinct nakshatras over 30 days")
    }

    // MARK: - Yoga Index

    func testYogaIndexRange() {
        let jd = delhiSunriseJD(year: 2026, month: 3, day: 20)
        let idx = PanchangCalculator.yogaIndex(at: jd)
        XCTAssertGreaterThanOrEqual(idx, 1, "Yoga index should be >= 1")
        XCTAssertLessThanOrEqual(idx, 27, "Yoga index should be <= 27")
    }

    // MARK: - Karana Index and Name

    func testKaranaIndexRange() {
        let jd = delhiSunriseJD(year: 2026, month: 3, day: 20)
        let idx = PanchangCalculator.karanaIndex(at: jd)
        XCTAssertGreaterThanOrEqual(idx, 1, "Karana index should be >= 1")
        XCTAssertLessThanOrEqual(idx, 60, "Karana index should be <= 60")
    }

    func testKaranaNameForFixedKaranas() {
        // Karana 1 = Kimstughna (fixed)
        XCTAssertEqual(PanchangCalculator.karanaName(for: 1), "Kimstughna")

        // Karanas 58-60 are fixed
        XCTAssertEqual(PanchangCalculator.karanaName(for: 58), "Shakuni")
        XCTAssertEqual(PanchangCalculator.karanaName(for: 59), "Chatushpada")
        XCTAssertEqual(PanchangCalculator.karanaName(for: 60), "Nagava")
    }

    func testKaranaNameForRepeatingKaranas() {
        // Karanas 2-57 repeat cycle: Bava, Balava, Kaulava, Taitila, Garaja, Vanija, Vishti
        XCTAssertEqual(PanchangCalculator.karanaName(for: 2), "Bava")
        XCTAssertEqual(PanchangCalculator.karanaName(for: 3), "Balava")
        XCTAssertEqual(PanchangCalculator.karanaName(for: 8), "Vishti")
        XCTAssertEqual(PanchangCalculator.karanaName(for: 9), "Bava")  // Cycle repeats
    }

    // MARK: - Lunar Month

    func testComputeLunarMonth() {
        // At equinox (Sun near 0° sidereal Aries), lunar month should be Chaitra
        let jd = delhiSunriseJD(year: 2026, month: 4, day: 1)
        let month = PanchangCalculator.computeLunarMonth(at: jd)
        // Sun should be in early Aries (0-30°) → Chaitra
        let validMonths = ["Chaitra", "Vaishakha", "Phalguna"]
        XCTAssertTrue(validMonths.contains(month),
                      "Lunar month near April should be Chaitra or adjacent, got: \(month)")
    }

    func testAllLunarMonthsAppearInYear() {
        // Over a full year, all 12 lunar months should appear
        var seen = Set<String>()
        for month in 1...12 {
            let jd = delhiSunriseJD(year: 2026, month: month, day: 15)
            seen.insert(PanchangCalculator.computeLunarMonth(at: jd))
        }
        XCTAssertGreaterThanOrEqual(seen.count, 10, "Should see at least 10 distinct lunar months")
    }

    // MARK: - Time Windows

    func testComputeTimeWindows() {
        let calc = VedicCalculator.shared
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 0))!
        let jdMidnight = calc.julianDay(from: date)

        let sunriseJD = calc.sunrise(on: jdMidnight, lat: 28.7041, lon: 77.1025)
        let sunsetJD = calc.sunset(on: jdMidnight, lat: 28.7041, lon: 77.1025)

        // Weekday for March 20, 2026 = Friday = 6
        let windows = PanchangCalculator.computeTimeWindows(sunriseJD: sunriseJD, sunsetJD: sunsetJD, weekday: 6)

        XCTAssertEqual(windows.count, 5, "Should produce 5 time windows")

        // Check all expected window types present
        let types = Set(windows.map { $0.type })
        XCTAssertTrue(types.contains(.brahmaMuhurta), "Should include Brahma Muhurta")
        XCTAssertTrue(types.contains(.abhijitMuhurta), "Should include Abhijit Muhurta")
        XCTAssertTrue(types.contains(.rahuKalam), "Should include Rahu Kalam")
        XCTAssertTrue(types.contains(.yamaganda), "Should include Yamaganda")
        XCTAssertTrue(types.contains(.gulikaKalam), "Should include Gulika Kalam")

        // All windows should have start before end
        for window in windows {
            XCTAssertLessThan(window.start, window.end,
                              "\(window.type.rawValue) should have start < end")
        }

        // Brahma Muhurta should be before sunrise
        if let brahma = windows.first(where: { $0.type == .brahmaMuhurta }) {
            let sunriseDate = calc.date(from: sunriseJD)
            XCTAssertLessThan(brahma.end, sunriseDate,
                              "Brahma Muhurta should end before sunrise")
        }
    }

    // MARK: - Full Panchang Computation

    func testFullPanchangComputation() {
        let delhi = UserCity(
            name: "Delhi", country: "IN",
            latitude: 28.7041, longitude: 77.1025,
            timezoneIdentifier: "Asia/Kolkata"
        )

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let date = cal.date(from: DateComponents(year: 2026, month: 3, day: 20))!

        let panchang = PanchangCalculator.panchang(for: date, city: delhi)

        // Basic sanity
        XCTAssertFalse(panchang.tithi.name.isEmpty, "Tithi name should not be empty")
        XCTAssertFalse(panchang.nakshatra.name.isEmpty, "Nakshatra name should not be empty")
        XCTAssertFalse(panchang.yoga.name.isEmpty, "Yoga name should not be empty")
        XCTAssertFalse(panchang.karanas.isEmpty, "Should have at least one karana")
        XCTAssertFalse(panchang.lunarMonth.isEmpty, "Lunar month should not be empty")

        // Solar times should be reasonable
        XCTAssertLessThan(panchang.solar.sunrise, panchang.solar.sunset, "Sunrise should be before sunset")
    }
}
