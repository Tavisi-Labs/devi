// MARK: - DeviTests/VedicCalculatorTests.swift
// Tests for VedicCalculator: Julian Day roundtrip, sunrise/sunset for Delhi, sidereal longitude sanity.

import XCTest
@testable import Devi

final class VedicCalculatorTests: XCTestCase {

    private let calc = VedicCalculator.shared

    // MARK: - Julian Day Roundtrip

    func testJulianDayRoundtrip() {
        // Known epoch: J2000.0 = Jan 1.5, 2000 (noon UT) = JD 2451545.0
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let j2000 = cal.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: 12, minute: 0, second: 0))!

        let jd = calc.julianDay(from: j2000)
        XCTAssertEqual(jd, 2451545.0, accuracy: 0.001, "J2000.0 epoch should be JD 2451545.0")

        // Roundtrip: JD → Date → JD
        let roundtripped = calc.date(from: jd)
        let jdAgain = calc.julianDay(from: roundtripped)
        XCTAssertEqual(jd, jdAgain, accuracy: 0.001, "Julian Day roundtrip should preserve value within ~1 minute")
    }

    func testJulianDayForKnownDate() {
        // March 20, 2026 at noon UTC
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 12, minute: 0, second: 0))!

        let jd = calc.julianDay(from: date)
        // JD for 2026-03-20 12:00 UTC should be approximately 2461095.0
        XCTAssertGreaterThan(jd, 2461000, "JD for 2026 should be > 2461000")
        XCTAssertLessThan(jd, 2462000, "JD for 2026 should be < 2462000")
    }

    // MARK: - Sunrise/Sunset (Delhi)

    func testDelhiSunriseSunset() {
        // Delhi: 28.7041N, 77.1025E
        // On equinox (~March 20), sunrise should be around 6:00-6:30 IST (0:30-1:00 UTC)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let midnight = cal.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 0, minute: 0, second: 0))!
        let jdMidnight = calc.julianDay(from: midnight)

        let sunriseJD = calc.sunrise(on: jdMidnight, lat: 28.7041, lon: 77.1025)
        let sunsetJD = calc.sunset(on: jdMidnight, lat: 28.7041, lon: 77.1025)

        // Sunrise should be after midnight and before noon (UTC)
        XCTAssertGreaterThan(sunriseJD, jdMidnight, "Sunrise should be after midnight")
        XCTAssertLessThan(sunriseJD, jdMidnight + 0.5, "Sunrise should be before noon UTC")

        // Sunset should be after sunrise
        XCTAssertGreaterThan(sunsetJD, sunriseJD, "Sunset should be after sunrise")

        // Day length on equinox should be approximately 12 hours
        let dayLengthHours = (sunsetJD - sunriseJD) * 24.0
        XCTAssertEqual(dayLengthHours, 12.0, accuracy: 1.0, "Day length on equinox should be ~12 hours")
    }

    // MARK: - Sidereal Longitude Sanity

    func testSunSiderealLongitude() {
        // Near vernal equinox (March 20, 2026), Sun's sidereal longitude should be near 336° (Pisces)
        // due to ~24° ayanamsa offset from tropical 0°
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 12))!
        let jd = calc.julianDay(from: date)

        let sunLon = calc.sunSiderealLongitude(at: jd)
        XCTAssertGreaterThanOrEqual(sunLon, 0, "Sun longitude should be >= 0")
        XCTAssertLessThan(sunLon, 360, "Sun longitude should be < 360")
        // At tropical equinox, sidereal should be ~336° (360 - 24 ayanamsa)
        XCTAssertEqual(sunLon, 336, accuracy: 5, "Sun sidereal near equinox should be ~336° (Pisces)")
    }

    func testMoonSiderealLongitude() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 12))!
        let jd = calc.julianDay(from: date)

        let moonLon = calc.moonSiderealLongitude(at: jd)
        XCTAssertGreaterThanOrEqual(moonLon, 0, "Moon longitude should be >= 0")
        XCTAssertLessThan(moonLon, 360, "Moon longitude should be < 360")
    }

    func testMoonMovesSignificantly() {
        // Moon moves ~13° per day — verify it's not static
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date1 = cal.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 12))!
        let date2 = cal.date(from: DateComponents(year: 2026, month: 3, day: 21, hour: 12))!

        let jd1 = calc.julianDay(from: date1)
        let jd2 = calc.julianDay(from: date2)

        let moon1 = calc.moonSiderealLongitude(at: jd1)
        let moon2 = calc.moonSiderealLongitude(at: jd2)

        var diff = moon2 - moon1
        if diff < 0 { diff += 360 }  // Handle wraparound
        XCTAssertEqual(diff, 13, accuracy: 3, "Moon should move ~13° per day")
    }
}
