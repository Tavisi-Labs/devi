// MARK: - DeviTests/HoroscopeEngineVariantTests.swift
// Validates the enriched variant seed in `HoroscopeEngine.generateReading`.
// Before the seed enrichment, two adjacent days in the same Moon house
// produced identical readings because the seed only mixed `dayOfYear`
// and `birthRashi`. The enriched seed mixes in tithi / nakshatra / yoga
// signals so neighbouring days diverge.
//
// Strategy: pick two real dates whose panchangs differ (tithi rolls over
// every ~24 hours, nakshatra every ~1 day, yoga every ~1 day) and feed
// them to the engine with the *same* NatalChart + the *same* GrahaSnapshot
// so the Moon house is constant. Any difference in the output then comes
// solely from the enriched seed.

import XCTest
@testable import Devi

final class HoroscopeEngineVariantTests: XCTestCase {

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

    /// Fixture NatalChart — a stable Mesha (Aries) Moon with a dummy graha snapshot.
    /// The graha snapshot is irrelevant for the engine path we're testing because
    /// the test calls `generateReading` with an explicit `todaySnapshot` each time.
    private func makeNatalChart(rashi: Rashi = .mesha) -> NatalChart {
        let positions: [GrahaSnapshot.Position] = Graha.allCases.map {
            GrahaSnapshot.Position(graha: $0, longitude: 0)
        }
        return NatalChart(
            birthRashi: rashi,
            moonLongitude: 10.0,
            birthNakshatra: "Ashwini",
            grahaSnapshot: GrahaSnapshot(positions: positions, computedAt: Date()),
            birthTimeKnown: true
        )
    }

    /// Build a GrahaSnapshot that places the transit Moon at the given longitude
    /// (so Moon house relative to birth rashi is deterministic). All other
    /// grahas stay at 0° which is fine — the engine only reads Moon / Jupiter /
    /// Saturn for house calculation, and fixed positions keep the test stable.
    private func makeGrahaSnapshot(moonLongitude: Double) -> GrahaSnapshot {
        let positions: [GrahaSnapshot.Position] = Graha.allCases.map { graha in
            if graha == .moon {
                return GrahaSnapshot.Position(graha: .moon, longitude: moonLongitude)
            }
            return GrahaSnapshot.Position(graha: graha, longitude: 0)
        }
        return GrahaSnapshot(positions: positions, computedAt: Date())
    }

    // MARK: - Seed Enrichment Test

    func testAdjacentDaysWithDifferentPanchangProduceDifferentReadings() {
        // Pick two real consecutive days — their tithi, nakshatra, or yoga
        // will differ because those signals change every ~24h, but we'll
        // pin the transit Moon to the same longitude so the Moon house
        // stays constant.
        let day1Date = date(year: 2026, month: 4, day: 7)
        let day2Date = date(year: 2026, month: 4, day: 8)

        let day1Panchang = PanchangCalculator.panchang(for: day1Date, city: delhi)
        let day2Panchang = PanchangCalculator.panchang(for: day2Date, city: delhi)

        // If by bad luck both days have identical panchang seeds, the test
        // can't prove anything — guard against that explicitly.
        let day1Seed = (day1Panchang.tithi.number, day1Panchang.nakshatra.number, day1Panchang.yoga.number)
        let day2Seed = (day2Panchang.tithi.number, day2Panchang.nakshatra.number, day2Panchang.yoga.number)
        XCTAssertNotEqual(
            "\(day1Seed.0)-\(day1Seed.1)-\(day1Seed.2)",
            "\(day2Seed.0)-\(day2Seed.1)-\(day2Seed.2)",
            "Test fixture failed: picked two days with identical panchang seeds. Pick different dates."
        )

        // Pin transit Moon longitude to keep Moon house stable.
        let snapshot = makeGrahaSnapshot(moonLongitude: 15.0)
        let natal = makeNatalChart()

        let reading1 = HoroscopeEngine.generateReading(
            natalChart: natal,
            todaySnapshot: snapshot,
            panchang: day1Panchang,
            date: day1Date,
            timezoneIdentifier: delhi.timezoneIdentifier
        )
        let reading2 = HoroscopeEngine.generateReading(
            natalChart: natal,
            todaySnapshot: snapshot,
            panchang: day2Panchang,
            date: day2Date,
            timezoneIdentifier: delhi.timezoneIdentifier
        )

        // Moon house must be the same because we pinned the longitude.
        XCTAssertEqual(
            reading1.transitContext.moonHouse,
            reading2.transitContext.moonHouse,
            "Test invariant violated — fixture forces Moon house to match"
        )

        // The enriched seed should produce different variant indices when
        // the theme pool has multiple variants. We can't assert strict
        // inequality of every field (the seed collision space is small
        // at 3 variants per house in the seed JSON), but we *can* assert
        // the reading objects are not byte-identical, because variant
        // selection feeds from the seed and at least one pool should
        // resolve differently.
        let sameTheme = reading1.themeStatement == reading2.themeStatement
        let sameCategories = reading1.categories.map(\.summary) == reading2.categories.map(\.summary)
        XCTAssertFalse(
            sameTheme && sameCategories,
            "Enriched seed failed: both days produced identical theme AND categories. " +
            "This was the core repetition bug — the seed must mix in tithi/nakshatra/yoga."
        )
    }

    // MARK: - Out-of-Bounds Safety

    func testVariantIndexStaysInBoundsForLargeSeed() {
        // The enriched seed can become large (tithi*31 + nakshatra*73 + yoga*137
        // + dayOfYear + rashi). `abs(variantSeed) % count` must never crash or
        // produce negative indices. We drive the engine with a realistic
        // panchang on the last day of the year (maximum dayOfYear) and assert
        // the reading is well-formed.
        let endOfYear = date(year: 2026, month: 12, day: 31)
        let panchang = PanchangCalculator.panchang(for: endOfYear, city: delhi)

        let snapshot = makeGrahaSnapshot(moonLongitude: 180.0) // Libra
        let natal = makeNatalChart(rashi: .mesha)

        let reading = HoroscopeEngine.generateReading(
            natalChart: natal,
            todaySnapshot: snapshot,
            panchang: panchang,
            date: endOfYear,
            timezoneIdentifier: delhi.timezoneIdentifier
        )

        XCTAssertFalse(reading.themeStatement.isEmpty)
        XCTAssertFalse(reading.supportingText.isEmpty)
        XCTAssertEqual(reading.categories.count, HoroscopeCategory.allCases.count)
        for category in reading.categories {
            XCTAssertFalse(category.summary.isEmpty)
            XCTAssertGreaterThanOrEqual(category.intensity, 1)
            XCTAssertLessThanOrEqual(category.intensity, 5)
        }
    }
}
