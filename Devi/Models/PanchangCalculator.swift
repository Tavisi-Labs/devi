// MARK: - Models/PanchangCalculator.swift
// Dynamic panchang computation engine — replaces the static PanchangDataStore.
// Ports all logic from scripts/generate_panchang.py to on-device Swift using Swiss Ephemeris.
//
// Every value is computed live for any city, any date. No pre-generated JSON needed.

import Foundation

/// Computes all panchang elements dynamically using Swiss Ephemeris via VedicCalculator.
/// This is a pure computation layer — no state, no UI, no persistence.
enum PanchangCalculator {

    // MARK: - Panchang Element Tables
    // Direct port from generate_panchang.py lines 20-76

    private static let tithiNames = [
        "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
        "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
        "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima",  // Shukla 1-15
        "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
        "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
        "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Amavasya",  // Krishna 1-15
    ]

    private static let nakshatraNames = [
        "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira",
        "Ardra", "Punarvasu", "Pushya", "Ashlesha", "Magha",
        "Purva Phalguni", "Uttara Phalguni", "Hasta", "Chitra", "Swati",
        "Vishakha", "Anuradha", "Jyeshtha", "Mula", "Purva Ashadha",
        "Uttara Ashadha", "Shravana", "Dhanishta", "Shatabhisha",
        "Purva Bhadrapada", "Uttara Bhadrapada", "Revati",
    ]

    private static let nakshatraRulers = [
        "Ketu", "Venus", "Sun", "Moon", "Mars",
        "Rahu", "Jupiter", "Saturn", "Mercury", "Ketu",
        "Venus", "Sun", "Moon", "Mars", "Rahu",
        "Jupiter", "Saturn", "Mercury", "Ketu", "Venus",
        "Sun", "Moon", "Mars", "Rahu", "Jupiter",
        "Saturn", "Mercury",
    ]

    private static let nakshatraDeities = [
        "Ashwini Kumaras", "Yama", "Agni", "Brahma", "Soma",
        "Rudra", "Aditi", "Brihaspati", "Nagas", "Pitrs",
        "Bhaga", "Aryaman", "Savitar", "Vishvakarma", "Vayu",
        "Indra-Agni", "Mitra", "Indra", "Nirriti", "Apah",
        "Vishvadevas", "Vishnu", "Vasu", "Varuna",
        "Aja Ekapada", "Ahir Budhnya", "Pushan",
    ]

    private static let yogaNames = [
        "Vishkambha", "Priti", "Ayushman", "Saubhagya", "Shobhana",
        "Atiganda", "Sukarma", "Dhriti", "Shula", "Ganda",
        "Vriddhi", "Dhruva", "Vyaghata", "Harshana", "Vajra",
        "Siddhi", "Vyatipata", "Variyan", "Parigha", "Shiva",
        "Siddha", "Sadhya", "Shubha", "Shukla", "Brahma",
        "Indra", "Vaidhriti",
    ]

    // Karana names: 7 repeating (Bava..Vishti) + 4 fixed at cycle boundaries
    private static let repeatingKaranas = [
        "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti"
    ]

    private static let lunarMonths = [
        "Chaitra", "Vaishakha", "Jyeshtha", "Ashadha",
        "Shravana", "Bhadrapada", "Ashwin", "Kartik",
        "Margashirsha", "Pausha", "Magha", "Phalguna",
    ]

    // MARK: - Time Window Segment Tables
    // Each table maps Calendar weekday (1=Sun, 2=Mon, ... 7=Sat) to the 0-based segment index.
    // Day is divided into 8 equal parts from sunrise to sunset.
    // Mnemonic for Rahu: "Mother Saw Father Wearing The Turban on Sunday" → Mon=1, Sat=2, Fri=3, Wed=4, Thu=5, Tue=6, Sun=7

    //                                 [unused, Sun, Mon, Tue, Wed, Thu, Fri, Sat]
    private static let rahuSegments   = [0,     7,   1,   6,   4,   5,   3,   2]
    private static let yamaSegments   = [0,     4,   3,   2,   1,   0,   6,   5]
    private static let gulikaSegments = [0,     6,   5,   4,   3,   2,   1,   0]

    // MARK: - Core Index Functions
    // These return just the integer index — used by findEndTime for bisection search.

    /// Tithi index (1-30) from lunar elongation.
    /// Formula: floor((moonLon - sunLon) mod 360 / 12) + 1
    static func tithiIndex(at jd: Double) -> Int {
        let calc = VedicCalculator.shared
        let sun = calc.sunSiderealLongitude(at: jd)
        let moon = calc.moonSiderealLongitude(at: jd)
        var diff = (moon - sun).truncatingRemainder(dividingBy: 360.0)
        if diff < 0 { diff += 360.0 }
        return min(Int(diff / 12.0) + 1, 30)
    }

    /// Nakshatra index (1-27) from Moon's sidereal longitude.
    /// Formula: floor(moonLon / (360/27)) + 1
    static func nakshatraIndex(at jd: Double) -> Int {
        let moon = VedicCalculator.shared.moonSiderealLongitude(at: jd)
        var lon = moon.truncatingRemainder(dividingBy: 360.0)
        if lon < 0 { lon += 360.0 }
        return min(Int(lon / (360.0 / 27.0)) + 1, 27)
    }

    /// Yoga index (1-27) from combined Sun+Moon longitude.
    /// Formula: floor((sunLon + moonLon) mod 360 / (360/27)) + 1
    static func yogaIndex(at jd: Double) -> Int {
        let calc = VedicCalculator.shared
        let sun = calc.sunSiderealLongitude(at: jd)
        let moon = calc.moonSiderealLongitude(at: jd)
        var total = (sun + moon).truncatingRemainder(dividingBy: 360.0)
        if total < 0 { total += 360.0 }
        return min(Int(total / (360.0 / 27.0)) + 1, 27)
    }

    /// Karana index (1-60) — half-tithi. Each tithi contains 2 karanas.
    /// Formula: floor((moonLon - sunLon) mod 360 / 6) + 1
    static func karanaIndex(at jd: Double) -> Int {
        let calc = VedicCalculator.shared
        let sun = calc.sunSiderealLongitude(at: jd)
        let moon = calc.moonSiderealLongitude(at: jd)
        var diff = (moon - sun).truncatingRemainder(dividingBy: 360.0)
        if diff < 0 { diff += 360.0 }
        return min(Int(diff / 6.0) + 1, 60)
    }

    // MARK: - Name Lookups

    /// Map karana index (1-60) to name.
    /// Karana 1 = Kimstughna (fixed), 2-57 = repeating cycle of 7, 58-60 = fixed (Shakuni, Chatushpada, Nagava).
    static func karanaName(for idx: Int) -> String {
        if idx == 1 { return "Kimstughna" }
        if idx >= 58 {
            let fixedNames = ["Shakuni", "Chatushpada", "Nagava"]
            return fixedNames[idx - 58]
        }
        return repeatingKaranas[(idx - 2) % 7]
    }

    /// Approximate lunar month from Sun's sidereal longitude.
    /// Each month spans ~30 degrees. Chaitra starts when Sun is near 0 degrees sidereal (Aries).
    static func computeLunarMonth(at jd: Double) -> String {
        let sun = VedicCalculator.shared.sunSiderealLongitude(at: jd)
        var lon = sun.truncatingRemainder(dividingBy: 360.0)
        if lon < 0 { lon += 360.0 }
        let idx = Int(lon / 30.0) % 12
        return lunarMonths[idx]
    }

    // MARK: - End Time Search (Bisection)
    // Direct port of generate_panchang.py find_end_time() (lines 236-272)

    /// Find the Julian Day when a panchang element transitions from its current value.
    /// Strategy: coarse scan forward in 30-min steps, then 10-iteration binary refinement (~2s precision).
    static func findEndTime(
        from startJD: Double,
        compute: (Double) -> Int,
        currentValue: Int,
        maxHours: Double = 30
    ) -> Double {
        let step = 0.5 / 24.0  // 30 minutes in Julian Day units

        // Phase 1: Coarse scan — find the 30-min window where the value changes
        var jd = startJD
        for _ in 0..<Int(maxHours * 2) {
            jd += step
            if compute(jd) != currentValue {
                // Phase 2: Bisection — refine to ~2 second precision
                var lo = jd - step
                var hi = jd
                for _ in 0..<10 {
                    let mid = (lo + hi) / 2.0
                    if compute(mid) == currentValue {
                        lo = mid
                    } else {
                        hi = mid
                    }
                }
                return hi
            }
        }

        // Fallback: element didn't change within search window
        return startJD + maxHours / 24.0
    }

    // MARK: - Multiple Karanas Per Day

    /// Compute all karanas active between sunrise and next sunrise.
    /// Typically produces 2-3 karanas per day since each karana spans ~6 hours.
    static func computeAllKaranas(from sunriseJD: Double, to nextSunriseJD: Double) -> [Karana] {
        let calc = VedicCalculator.shared
        var karanas: [Karana] = []
        var jd = sunriseJD

        while jd < nextSunriseJD {
            let idx = karanaIndex(at: jd)
            let name = karanaName(for: idx)
            let endJD = findEndTime(from: jd, compute: karanaIndex, currentValue: idx)
            let clampedEndJD = min(endJD, nextSunriseJD + 1.0 / 24.0) // Allow 1 hour past next sunrise
            let endDate = calc.date(from: clampedEndJD)

            karanas.append(Karana(number: idx, name: name, endTime: endDate))

            if endJD >= nextSunriseJD { break }
            jd = endJD + 0.001 / 24.0  // ~3.6 seconds past the transition
        }

        return karanas.isEmpty
            ? [Karana(number: 1, name: "Kimstughna", endTime: calc.date(from: nextSunriseJD))]
            : karanas
    }

    // MARK: - Time Windows

    /// Compute all daily time windows for the given sunrise/sunset and weekday.
    /// Returns windows sorted by start time: Brahma Muhurta, Abhijit Muhurta,
    /// Rahu Kalam, Yamaganda, Gulika Kalam.
    static func computeTimeWindows(sunriseJD: Double, sunsetJD: Double, weekday: Int) -> [TimeWindow] {
        let calc = VedicCalculator.shared
        let ucha = (sunsetJD - sunriseJD) / 8.0  // Each of 8 equal day segments
        var windows: [TimeWindow] = []

        // Brahma Muhurta: 96 to 48 minutes before sunrise
        // Traditionally the 14th muhurta of the night — the most spiritually potent time.
        let brahmaStart = sunriseJD - 96.0 / 1440.0
        let brahmaEnd = sunriseJD - 48.0 / 1440.0
        windows.append(TimeWindow(
            type: .brahmaMuhurta,
            start: calc.date(from: brahmaStart),
            end: calc.date(from: brahmaEnd)
        ))

        // Abhijit Muhurta: 8th of 15 day-muhurtas (0-indexed: 7th)
        // The "unconquered moment" around solar noon — overrides other doshas.
        let dayMuhurta = (sunsetJD - sunriseJD) / 15.0
        let abhijitStart = sunriseJD + 7.0 * dayMuhurta
        let abhijitEnd = abhijitStart + dayMuhurta
        windows.append(TimeWindow(
            type: .abhijitMuhurta,
            start: calc.date(from: abhijitStart),
            end: calc.date(from: abhijitEnd)
        ))

        // Rahu Kalam — inauspicious period, segment varies by weekday
        let rahuSeg = rahuSegments[weekday]
        let rahuStart = sunriseJD + Double(rahuSeg) * ucha
        let rahuEnd = rahuStart + ucha
        windows.append(TimeWindow(
            type: .rahuKalam,
            start: calc.date(from: rahuStart),
            end: calc.date(from: rahuEnd)
        ))

        // Yamaganda — inauspicious period (Yama's block)
        let yamaSeg = yamaSegments[weekday]
        let yamaStart = sunriseJD + Double(yamaSeg) * ucha
        let yamaEnd = yamaStart + ucha
        windows.append(TimeWindow(
            type: .yamaganda,
            start: calc.date(from: yamaStart),
            end: calc.date(from: yamaEnd)
        ))

        // Gulika Kalam — inauspicious period (Saturn's son)
        let gulikaSeg = gulikaSegments[weekday]
        let gulikaStart = sunriseJD + Double(gulikaSeg) * ucha
        let gulikaEnd = gulikaStart + ucha
        windows.append(TimeWindow(
            type: .gulikaKalam,
            start: calc.date(from: gulikaStart),
            end: calc.date(from: gulikaEnd)
        ))

        // Sort by start time for chronological display
        windows.sort { $0.start < $1.start }

        return windows
    }

    // MARK: - Full Day Computation

    /// Compute complete panchang for a date and city.
    /// This is the primary entry point — replaces PanchangDataStore.panchang(for:city:).
    static func panchang(for date: Date, city: UserCity) -> DailyPanchang {
        let calc = VedicCalculator.shared
        let tz = TimeZone(identifier: city.timezoneIdentifier) ?? .current

        // Compute local midnight as the search starting point for rise/set
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let dayStart = cal.startOfDay(for: date)
        let jdDayStart = calc.julianDay(from: dayStart)

        // Sunrise and sunset for this day and city
        let sunriseJD = calc.sunrise(on: jdDayStart, lat: city.latitude, lon: city.longitude)
        let sunsetJD = calc.sunset(on: jdDayStart, lat: city.latitude, lon: city.longitude)

        // Use sunrise as the reference time (traditional: panchang elements are given at sunrise)
        let refJD = sunriseJD

        // Core five limbs with end times (bisection search from sunrise)
        let tIdx = tithiIndex(at: refJD)
        let tithiEndJD = findEndTime(from: refJD, compute: tithiIndex, currentValue: tIdx)
        let paksha: Paksha = tIdx <= 15 ? .shukla : .krishna
        let pakshaNum = tIdx <= 15 ? tIdx : tIdx - 15

        let nIdx = nakshatraIndex(at: refJD)
        let nakEndJD = findEndTime(from: refJD, compute: nakshatraIndex, currentValue: nIdx)

        let yIdx = yogaIndex(at: refJD)
        let yogaEndJD = findEndTime(from: refJD, compute: yogaIndex, currentValue: yIdx)

        // Multiple karanas: scan from sunrise to next sunrise
        let nextDayStart = cal.date(byAdding: .day, value: 1, to: dayStart)!
        let nextSunriseJD = calc.sunrise(on: calc.julianDay(from: nextDayStart), lat: city.latitude, lon: city.longitude)
        let allKaranas = computeAllKaranas(from: sunriseJD, to: nextSunriseJD)

        // Moonrise / moonset
        let moonriseJD = calc.moonrise(on: jdDayStart, lat: city.latitude, lon: city.longitude)
        let moonsetJD = calc.moonset(on: jdDayStart, lat: city.latitude, lon: city.longitude)

        // Time windows (requires weekday)
        let weekday = cal.component(.weekday, from: date) // 1=Sun ... 7=Sat
        let timeWindows = computeTimeWindows(sunriseJD: sunriseJD, sunsetJD: sunsetJD, weekday: weekday)

        // Lunar month
        let lunarMonth = computeLunarMonth(at: refJD)

        // Date string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = tz
        let dateString = dateFormatter.string(from: date)

        // Festivals (hardcoded for 2026)
        let festivals = Self.festivals(for: dateString)

        return DailyPanchang(
            dateString: dateString,
            tithi: Tithi(
                number: pakshaNum,
                name: tithiNames[tIdx - 1],
                paksha: paksha,
                endTime: calc.date(from: tithiEndJD)
            ),
            nakshatra: Nakshatra(
                number: nIdx,
                name: nakshatraNames[nIdx - 1],
                ruler: nakshatraRulers[nIdx - 1],
                deity: nakshatraDeities[nIdx - 1],
                endTime: calc.date(from: nakEndJD)
            ),
            yoga: Yoga(
                number: yIdx,
                name: yogaNames[yIdx - 1],
                endTime: calc.date(from: yogaEndJD)
            ),
            karanas: allKaranas,
            solar: SolarData(
                sunrise: calc.date(from: sunriseJD),
                sunset: calc.date(from: sunsetJD),
                moonrise: moonriseJD.map { calc.date(from: $0) },
                moonset: moonsetJD.map { calc.date(from: $0) }
            ),
            timeWindows: timeWindows,
            lunarMonth: lunarMonth,
            festivals: festivals
        )
    }

    // MARK: - Festivals (Hardcoded for 2026)

    private static let festivalData: [String: [String]] = [
        "2026-03-13": ["Maha Shivaratri"],
        "2026-03-14": ["Amavasya"],
        "2026-03-19": ["Chaitra Navratri Begins"],
        "2026-03-20": ["Chaitra Navratri Day 2"],
        "2026-03-21": ["Chaitra Navratri Day 3"],
        "2026-03-22": ["Chaitra Navratri Day 4"],
        "2026-03-23": ["Chaitra Navratri Day 5"],
        "2026-03-24": ["Chaitra Navratri Day 6"],
        "2026-03-25": ["Chaitra Navratri Day 7"],
        "2026-03-26": ["Chaitra Navratri Day 8", "Durga Ashtami"],
        "2026-03-27": ["Chaitra Navratri Day 9", "Ram Navami"],
        "2026-03-28": ["Ekadashi"],
        "2026-03-29": ["Hanuman Jayanti"],
        "2026-04-01": ["Chaitra Purnima"],
        "2026-04-12": ["Amavasya"],
        "2026-04-13": ["Baisakhi"],
        "2026-04-14": ["Tamil New Year"],
    ]

    static func festivals(for dateString: String) -> [String] {
        festivalData[dateString] ?? []
    }
}
