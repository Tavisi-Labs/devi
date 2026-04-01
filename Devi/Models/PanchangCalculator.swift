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
    /// In Hindu calendar, Chaitra corresponds to Sun in Mina (Pisces, 330-360°), not Aries.
    /// The lunar month is named after the nakshatra where the full moon falls,
    /// which places the Sun one sign behind the month index.
    static func computeLunarMonth(at jd: Double) -> String {
        let sun = VedicCalculator.shared.sunSiderealLongitude(at: jd)
        var lon = sun.truncatingRemainder(dividingBy: 360.0)
        if lon < 0 { lon += 360.0 }
        let signIndex = Int(lon / 30.0)
        let idx = (signIndex + 1) % 12
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

    // MARK: - Hora (Planetary Hours)

    // Planet names in Chaldean sequence order (index 0-6)
    private static let horaPlanetNames = ["Sun", "Venus", "Mercury", "Moon", "Saturn", "Jupiter", "Mars"]
    private static let horaPlanetSanskrit = ["Surya", "Chandra", "Mangala", "Budha", "Guru", "Shukra", "Shani"]

    // Corrected Sanskrit names aligned with Chaldean order: Sun, Venus, Mercury, Moon, Saturn, Jupiter, Mars
    private static let horaSanskritByChaldean = ["Surya", "Shukra", "Budha", "Chandra", "Shani", "Guru", "Mangala"]

    // First daytime hora planet index (in Chaldean sequence) by weekday (1=Sun ... 7=Sat)
    // Sunday=Sun(0), Monday=Moon(3), Tuesday=Mars(6), Wednesday=Mercury(2),
    // Thursday=Jupiter(5), Friday=Venus(1), Saturday=Saturn(4)
    private static let horaStartIndex = [0, 0, 3, 6, 2, 5, 1, 4]

    /// Compute 24 hora periods (12 day + 12 night) for the given sunrise/sunset/nextSunrise.
    static func computeHoras(sunriseJD: Double, sunsetJD: Double, nextSunriseJD: Double, weekday: Int) -> [Hora] {
        let calc = VedicCalculator.shared
        let dayDuration = (sunsetJD - sunriseJD) / 12.0
        let nightDuration = (nextSunriseJD - sunsetJD) / 12.0
        let startIdx = horaStartIndex[weekday]

        var horas: [Hora] = []

        for i in 0..<24 {
            let isDaytime = i < 12
            let planetIdx = (startIdx + i) % 7
            let segStart: Double
            let segEnd: Double

            if isDaytime {
                segStart = sunriseJD + Double(i) * dayDuration
                segEnd = segStart + dayDuration
            } else {
                let nightIdx = i - 12
                segStart = sunsetJD + Double(nightIdx) * nightDuration
                segEnd = segStart + nightDuration
            }

            horas.append(Hora(
                planetName: horaPlanetNames[planetIdx],
                planetSanskrit: horaSanskritByChaldean[planetIdx],
                startTime: calc.date(from: segStart),
                endTime: calc.date(from: segEnd),
                isDaytime: isDaytime,
                sequenceIndex: i
            ))
        }

        return horas
    }

    // MARK: - Choghadiya

    // 7 named choghadiya types in rotation order
    private static let choghadiyaNames = ["Udveg", "Chal", "Labh", "Amrit", "Kaal", "Shubh", "Rog"]

    private static let choghadiyaQualities: [ChoghadiyaQuality] = [
        .inauspicious,  // Udveg
        .neutral,       // Chal
        .auspicious,    // Labh
        .auspicious,    // Amrit
        .inauspicious,  // Kaal
        .auspicious,    // Shubh
        .inauspicious   // Rog
    ]

    // Day start index by weekday (1=Sun ... 7=Sat)
    private static let choghadiyaDayStart   = [0, 0, 3, 6, 2, 5, 1, 4]
    // Night start index by weekday (1=Sun ... 7=Sat)
    private static let choghadiyaNightStart = [0, 5, 1, 4, 0, 3, 6, 2]

    /// Compute 16 choghadiya periods (8 day + 8 night).
    static func computeChoghadiyas(sunriseJD: Double, sunsetJD: Double, nextSunriseJD: Double, weekday: Int) -> [Choghadiya] {
        let calc = VedicCalculator.shared
        let dayDuration = (sunsetJD - sunriseJD) / 8.0
        let nightDuration = (nextSunriseJD - sunsetJD) / 8.0
        let dayStart = choghadiyaDayStart[weekday]
        let nightStart = choghadiyaNightStart[weekday]

        var choghadiyas: [Choghadiya] = []

        // 8 daytime choghadiyas
        for i in 0..<8 {
            let typeIdx = (dayStart + i) % 7
            let segStart = sunriseJD + Double(i) * dayDuration
            let segEnd = segStart + dayDuration

            choghadiyas.append(Choghadiya(
                name: choghadiyaNames[typeIdx],
                quality: choghadiyaQualities[typeIdx],
                startTime: calc.date(from: segStart),
                endTime: calc.date(from: segEnd),
                isDaytime: true,
                sequenceIndex: i
            ))
        }

        // 8 nighttime choghadiyas
        for i in 0..<8 {
            let typeIdx = (nightStart + i) % 7
            let segStart = sunsetJD + Double(i) * nightDuration
            let segEnd = segStart + nightDuration

            choghadiyas.append(Choghadiya(
                name: choghadiyaNames[typeIdx],
                quality: choghadiyaQualities[typeIdx],
                startTime: calc.date(from: segStart),
                endTime: calc.date(from: segEnd),
                isDaytime: false,
                sequenceIndex: 8 + i
            ))
        }

        return choghadiyas
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

        // Hora and Choghadiya (reuse sunrise/sunset/nextSunrise and weekday)
        let horas = computeHoras(sunriseJD: sunriseJD, sunsetJD: sunsetJD, nextSunriseJD: nextSunriseJD, weekday: weekday)
        let choghadiyas = computeChoghadiyas(sunriseJD: sunriseJD, sunsetJD: sunsetJD, nextSunriseJD: nextSunriseJD, weekday: weekday)

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
            horas: horas,
            choghadiyas: choghadiyas,
            lunarMonth: lunarMonth,
            festivals: festivals
        )
    }

    // MARK: - Festivals (Dynamic via FestivalEngine)

    /// Returns festival names for a given date string.
    /// Delegates to FestivalEngine which computes dates algorithmically for any year.
    static func festivals(for dateString: String) -> [String] {
        guard let year = Int(dateString.prefix(4)) else { return [] }
        return FestivalEngine.festivals(forYear: year)[dateString] ?? []
    }

    // MARK: - Graha Snapshot (All 9 Vedic Planets)

    /// Compute sidereal longitudes for all 9 grahas at a given Julian Day.
    /// Ketu = (Rahu longitude + 180) mod 360 — it has no independent SE body.
    static func computeGrahaSnapshot(julianDay jd: Double) -> GrahaSnapshot {
        let calc = VedicCalculator.shared
        var positions: [GrahaSnapshot.Position] = []
        var rahuLon: Double = 0

        for graha in Graha.allCases {
            let lon: Double
            if graha == .ketu {
                // Ketu is the south lunar node — always diametrically opposite Rahu
                lon = (rahuLon + 180.0).truncatingRemainder(dividingBy: 360.0)
            } else {
                lon = calc.siderealLongitude(planet: graha.planetId, at: jd)
                if graha == .rahu { rahuLon = lon }
            }
            positions.append(GrahaSnapshot.Position(graha: graha, longitude: lon))
        }

        return GrahaSnapshot(positions: positions, computedAt: calc.date(from: jd))
    }

    // MARK: - Samvathsara (60-Year Jupiter Cycle)

    /// The 60 samvathsara names in order. Index 0 = Prabhava (year 1 of cycle).
    private static let samvathsaraNames = [
        "Prabhava", "Vibhava", "Shukla", "Pramodoota", "Prajothpatti",
        "Āngirasa", "Shrīmukha", "Bhāva", "Yuva", "Dhātri",
        "Īshvara", "Bahudhānya", "Pramāthi", "Vikrama", "Vṛṣa",
        "Chitrabhānu", "Svabhānu", "Tāraṇa", "Pārthiva", "Vyaya",
        "Sarvajit", "Sarvadhāri", "Virodhi", "Vikṛti", "Khara",
        "Nandana", "Vijaya", "Jaya", "Manmatha", "Durmukhi",
        "Hevilambi", "Vilambi", "Vikāri", "Shārvari", "Plava",
        "Shubhakṛt", "Shobhakṛt", "Krodhi", "Vishvāvasu", "Parābhava",
        "Plavanga", "Kīlaka", "Saumya", "Sādhāraṇa", "Virodhikṛt",
        "Paridhāvi", "Pramādi", "Ānanda", "Rākshasa", "Nala",
        "Pingala", "Kālayukti", "Siddhārthi", "Raudri", "Durmati",
        "Dundubhi", "Rudhirodgāri", "Raktākshi", "Krodhana", "Akshaya",
    ]

    /// Returns the samvathsara name for a given date.
    /// The Vedic year starts at Chaitra Shukla Pratipada (typically mid-March to mid-April).
    /// Epoch: 2000-2001 = Vikṛti (index 23). So offset = year - 2000 + 23.
    static func samvathsaraName(for date: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        var year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        // Before approximately mid-March, still in previous Vedic year
        if month < 3 || (month == 3 && cal.component(.day, from: date) < 14) {
            year -= 1
        }
        let idx = ((year - 2000 + 23) % 60 + 60) % 60
        return samvathsaraNames[idx]
    }
}
