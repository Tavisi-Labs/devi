// MARK: - Models/VedicCalculator.swift
// Thin Swift wrapper around Swiss Ephemeris C library for Vedic astronomical calculations.
// Uses Lahiri ayanamsa (Chitrapaksha) for sidereal (nirayana) positions.
//
// IMPORTANT: The Swiss Ephemeris C library uses global state and is NOT thread-safe.
// All calls must be serialized on the same thread/actor. Since PanchangViewModel is
// @MainActor, this is satisfied in normal app usage.

import Foundation
import CSwissEphemeris

// MARK: - Swiss Ephemeris Constants
// Defined explicitly because C #define macros may not always import into Swift.

private let kSESun: Int32 = 0           // SE_SUN
private let kSEMoon: Int32 = 1          // SE_MOON
private let kSEGregCal: Int32 = 1       // SE_GREG_CAL
private let kSEFlagSidereal: Int32 = 64 * 1024  // SEFLG_SIDEREAL (65536)
private let kSESidmLahiri: Int32 = 1    // SE_SIDM_LAHIRI
private let kSECalcRise: Int32 = 1      // SE_CALC_RISE
private let kSECalcSet: Int32 = 2       // SE_CALC_SET

/// Low-level Swiss Ephemeris wrapper for Vedic astronomical calculations.
/// Provides sidereal planetary longitudes, sunrise/sunset, and Julian Day conversions.
final class VedicCalculator {

    static let shared = VedicCalculator()

    private init() {
        // Use built-in Moshier ephemeris (no external data files needed).
        // Moshier is accurate to ~1 arc-second for Sun/Moon — more than sufficient
        // for panchang element boundaries (tithi = 12 degrees, nakshatra = 13.33 degrees).
        swe_set_ephe_path(nil)

        // Lahiri ayanamsa — the standard for Hindu/Vedic (nirayana) astrology.
        // This shifts tropical longitudes by ~24 degrees to get sidereal positions.
        swe_set_sid_mode(kSESidmLahiri, 0, 0)
    }

    // MARK: - Julian Day Conversions

    /// Convert a Foundation Date to Julian Day (Universal Time).
    /// Julian Day is the continuous day count used by astronomers since 4713 BCE.
    func julianDay(from date: Date) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let hour = Double(comps.hour ?? 0)
            + Double(comps.minute ?? 0) / 60.0
            + Double(comps.second ?? 0) / 3600.0
        return swe_julday(
            Int32(comps.year ?? 2026),
            Int32(comps.month ?? 1),
            Int32(comps.day ?? 1),
            hour,
            kSEGregCal
        )
    }

    /// Convert Julian Day (UT) back to a Foundation Date.
    func date(from jd: Double) -> Date {
        var year: Int32 = 0
        var month: Int32 = 0
        var day: Int32 = 0
        var hour: Double = 0
        swe_revjul(jd, kSEGregCal, &year, &month, &day, &hour)

        let hours = Int(hour)
        let minutesFrac = (hour - Double(hours)) * 60.0
        let minutes = Int(minutesFrac)
        let seconds = Int((minutesFrac - Double(minutes)) * 60.0)

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = DateComponents(
            year: Int(year), month: Int(month), day: Int(day),
            hour: hours, minute: minutes, second: seconds
        )
        return cal.date(from: comps) ?? Date()
    }

    // MARK: - Sidereal Planetary Longitudes

    /// Sun's sidereal (nirayana) longitude in degrees [0, 360).
    /// Uses Lahiri ayanamsa set at init.
    func sunSiderealLongitude(at jd: Double) -> Double {
        var xx = [Double](repeating: 0, count: 6)
        var serr = [CChar](repeating: 0, count: 256)
        swe_calc_ut(jd, kSESun, kSEFlagSidereal, &xx, &serr)
        return xx[0]
    }

    /// Moon's sidereal (nirayana) longitude in degrees [0, 360).
    func moonSiderealLongitude(at jd: Double) -> Double {
        var xx = [Double](repeating: 0, count: 6)
        var serr = [CChar](repeating: 0, count: 256)
        swe_calc_ut(jd, kSEMoon, kSEFlagSidereal, &xx, &serr)
        return xx[0]
    }

    // MARK: - Rise/Set Times

    /// Compute sunrise Julian Day for a location.
    /// Searches forward from the given JD to find the next sunrise.
    /// Uses upper-limb with atmospheric refraction (standard astronomical sunrise).
    func sunrise(on jd: Double, lat: Double, lon: Double) -> Double {
        var geopos: [Double] = [lon, lat, 0.0]
        var tret: Double = 0
        var serr = [CChar](repeating: 0, count: 256)
        let ret = swe_rise_trans(
            jd, kSESun, nil,
            0,              // epheflag: default ephemeris
            kSECalcRise,    // find next rise
            &geopos,
            0, 0,           // atpress, attemp: use defaults
            &tret, &serr
        )
        // Fallback: if rise_trans fails, estimate sunrise at 6:00 local
        if ret < 0 || tret <= 0 {
            return jd + 0.25 // ~6:00 AM UT offset from midnight
        }
        return tret
    }

    /// Compute sunset Julian Day for a location.
    func sunset(on jd: Double, lat: Double, lon: Double) -> Double {
        var geopos: [Double] = [lon, lat, 0.0]
        var tret: Double = 0
        var serr = [CChar](repeating: 0, count: 256)
        let ret = swe_rise_trans(
            jd, kSESun, nil,
            0,
            kSECalcSet,
            &geopos,
            0, 0,
            &tret, &serr
        )
        if ret < 0 || tret <= 0 {
            return jd + 0.75 // ~6:00 PM UT offset from midnight
        }
        return tret
    }

    /// Compute moonrise Julian Day. Returns nil if moon doesn't rise that day
    /// (circumpolar conditions at extreme latitudes).
    func moonrise(on jd: Double, lat: Double, lon: Double) -> Double? {
        var geopos: [Double] = [lon, lat, 0.0]
        var tret: Double = 0
        var serr = [CChar](repeating: 0, count: 256)
        let ret = swe_rise_trans(
            jd, kSEMoon, nil,
            0,
            kSECalcRise,
            &geopos,
            0, 0,
            &tret, &serr
        )
        guard ret >= 0 && tret > 0 else { return nil }
        // Only return if within ~30 hours of search start (same local day)
        guard tret - jd < 1.25 else { return nil }
        return tret
    }

    /// Compute moonset Julian Day. Returns nil if moon doesn't set that day.
    func moonset(on jd: Double, lat: Double, lon: Double) -> Double? {
        var geopos: [Double] = [lon, lat, 0.0]
        var tret: Double = 0
        var serr = [CChar](repeating: 0, count: 256)
        let ret = swe_rise_trans(
            jd, kSEMoon, nil,
            0,
            kSECalcSet,
            &geopos,
            0, 0,
            &tret, &serr
        )
        guard ret >= 0 && tret > 0 else { return nil }
        guard tret - jd < 1.25 else { return nil }
        return tret
    }
}
