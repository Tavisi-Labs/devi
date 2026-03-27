// MARK: - DeviTests/FestivalEngineTests.swift
// Tests for FestivalEngine: known 2026 dates, multi-year smoke test, navratri periods.

import XCTest
@testable import Devi

final class FestivalEngineTests: XCTestCase {

    // MARK: - Known 2026 Festival Dates (ground truth from drikpanchang.com)

    func testLohri2026() {
        let festivals = FestivalEngine.festivals(forYear: 2026)
        XCTAssertTrue(festivals["2026-01-13"]?.contains("Lohri") == true,
                      "Lohri should be on Jan 13 (fixed Gregorian)")
    }

    func testMakarSankranti2026() {
        let festivals = FestivalEngine.festivals(forYear: 2026)
        // Makar Sankranti: Sun enters sidereal Capricorn — typically Jan 14-15
        let jan14 = festivals["2026-01-14"] ?? []
        let jan15 = festivals["2026-01-15"] ?? []
        let hasSankranti = jan14.contains("Makar Sankranti") || jan15.contains("Makar Sankranti")
        XCTAssertTrue(hasSankranti,
                      "Makar Sankranti should be around Jan 14-15, 2026")
    }

    func testHoli2026() {
        let festivals = FestivalEngine.festivals(forYear: 2026)
        // Holi is the day after Holika Dahan (Phalguna Purnima)
        // Expected: Holi around March 3-5, 2026
        let holi = festivals.first { $0.value.contains("Holi") }
        XCTAssertNotNil(holi, "Holi should exist in 2026 festivals")

        if let holiDate = holi?.key {
            XCTAssertTrue(holiDate.hasPrefix("2026-03"),
                          "Holi should be in March 2026, got: \(holiDate)")
        }
    }

    func testChaitraNavratri2026() {
        let festivals = FestivalEngine.festivals(forYear: 2026)
        // Chaitra Navratri Begins: Chaitra Shukla 1 — expected around March 19-22, 2026
        let navratriStart = festivals.first { $0.value.contains("Chaitra Navratri Begins") }
        XCTAssertNotNil(navratriStart, "Chaitra Navratri should exist in 2026")

        if let startDate = navratriStart?.key {
            XCTAssertTrue(startDate.hasPrefix("2026-03"),
                          "Chaitra Navratri should start in March 2026, got: \(startDate)")
        }
    }

    func testSharadNavratri2026() {
        let festivals = FestivalEngine.festivals(forYear: 2026)
        let navratriStart = festivals.first { $0.value.contains("Sharad Navratri Begins") }
        XCTAssertNotNil(navratriStart, "Sharad Navratri should exist in 2026")

        if let startDate = navratriStart?.key {
            XCTAssertTrue(startDate.hasPrefix("2026-10"),
                          "Sharad Navratri should start in October 2026, got: \(startDate)")
        }
    }

    func testDiwali2026() {
        let festivals = FestivalEngine.festivals(forYear: 2026)
        // Diwali: Kartik Krishna Amavasya — expected around Nov 8, 2026
        let diwali = festivals.first { $0.value.contains("Diwali") }
        XCTAssertNotNil(diwali, "Diwali should exist in 2026")

        if let diwaliDate = diwali?.key {
            XCTAssertTrue(diwaliDate.hasPrefix("2026-11") || diwaliDate.hasPrefix("2026-10"),
                          "Diwali should be in Oct-Nov 2026, got: \(diwaliDate)")
        }
    }

    func testDussehra2026() {
        let festivals = FestivalEngine.festivals(forYear: 2026)
        let dussehra = festivals.first { $0.value.contains("Dussehra") }
        XCTAssertNotNil(dussehra, "Dussehra should exist in 2026")
    }

    func testKrishnaJanmashtami2026() {
        let festivals = FestivalEngine.festivals(forYear: 2026)
        let janmashtami = festivals.first { $0.value.contains("Krishna Janmashtami") }
        XCTAssertNotNil(janmashtami, "Krishna Janmashtami should exist in 2026")

        if let date = janmashtami?.key {
            // Should be Aug-Sep
            let month = String(date.dropFirst(5).prefix(2))
            XCTAssertTrue(["08", "09"].contains(month),
                          "Janmashtami should be in Aug-Sep, got month: \(month)")
        }
    }

    func testGaneshChaturthi2026() {
        let festivals = FestivalEngine.festivals(forYear: 2026)
        let ganesh = festivals.first { $0.value.contains("Ganesh Chaturthi") }
        XCTAssertNotNil(ganesh, "Ganesh Chaturthi should exist in 2026")
    }

    func testRakshaBandhan2026() {
        let festivals = FestivalEngine.festivals(forYear: 2026)
        let raksha = festivals.first { $0.value.contains("Raksha Bandhan") }
        XCTAssertNotNil(raksha, "Raksha Bandhan should exist in 2026")
    }

    // MARK: - Navratri Periods

    func testNavratriPeriods2026() {
        let periods = FestivalEngine.navratriPeriods(forYear: 2026)
        XCTAssertEqual(periods.count, 2, "Should have 2 Navratri periods (Chaitra + Sharad)")

        // Both should have 9-day span
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for period in periods {
            guard let start = formatter.date(from: period.startDate),
                  let end = formatter.date(from: period.endDate) else {
                XCTFail("Invalid date in navratri period: \(period)")
                continue
            }
            let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
            XCTAssertEqual(days, 8, "Navratri should span 9 days (8 day difference)")
        }
    }

    func testNavratriDayNumber() {
        let periods = FestivalEngine.navratriPeriods(forYear: 2026)
        guard let chaitra = periods.first(where: { $0.name == "Chaitra Navratri" }) else {
            XCTFail("Chaitra Navratri period not found")
            return
        }

        // Day 1 should work
        XCTAssertEqual(chaitra.dayNumber(for: chaitra.startDate), 1)

        // Day before start should be nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let start = formatter.date(from: chaitra.startDate),
           let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: start) {
            let dayBeforeStr = formatter.string(from: dayBefore)
            XCTAssertNil(chaitra.dayNumber(for: dayBeforeStr), "Day before Navratri should return nil")
        }
    }

    // MARK: - Multi-Year Smoke Test

    func testFestivalsExistForMultipleYears() {
        for year in [2025, 2026, 2027, 2028] {
            let festivals = FestivalEngine.festivals(forYear: year)
            XCTAssertGreaterThan(festivals.count, 20,
                                 "Year \(year) should have at least 20 festival days")

            // Core festivals should exist every year
            let allNames = festivals.values.flatMap { $0 }
            XCTAssertTrue(allNames.contains("Diwali"), "Year \(year) should have Diwali")
            XCTAssertTrue(allNames.contains("Holi"), "Year \(year) should have Holi")
            XCTAssertTrue(allNames.contains("Dussehra"), "Year \(year) should have Dussehra")
            XCTAssertTrue(allNames.contains("Lohri"), "Year \(year) should have Lohri")
        }
    }

    func testNavratriPeriodsForMultipleYears() {
        for year in [2025, 2026, 2027] {
            let periods = FestivalEngine.navratriPeriods(forYear: year)
            XCTAssertEqual(periods.count, 2,
                           "Year \(year) should have 2 Navratri periods")
        }
    }

    // MARK: - Festival Uniqueness

    func testNoFestivalDuplication() {
        let festivals = FestivalEngine.festivals(forYear: 2026)
        for (dateString, names) in festivals {
            let uniqueNames = Set(names)
            XCTAssertEqual(uniqueNames.count, names.count,
                           "Duplicate festival names on \(dateString): \(names)")
        }
    }

    // MARK: - Navratri Day Sequence

    func testNavratriDaySequenceComplete() {
        let festivals = FestivalEngine.festivals(forYear: 2026)
        let allNames = festivals.values.flatMap { $0 }

        // Check Chaitra Navratri days 2-9 exist
        for day in 2...9 {
            XCTAssertTrue(allNames.contains("Chaitra Navratri Day \(day)"),
                          "Chaitra Navratri Day \(day) should exist")
        }

        // Check Sharad Navratri days 2-9 exist
        for day in 2...9 {
            XCTAssertTrue(allNames.contains("Sharad Navratri Day \(day)"),
                          "Sharad Navratri Day \(day) should exist")
        }
    }
}
