// MARK: - Models/BirthChart.swift
// Birth data persistence and natal chart computation

import Foundation

// MARK: - BirthData (persisted to UserDefaults)

struct BirthData: Codable {
    let birthDate: Date
    let birthTime: Date?          // nil = unknown (defaults to noon)
    let birthPlace: String        // City name
    let latitude: Double
    let longitude: Double
    let timezoneIdentifier: String
    let birthTimeKnown: Bool

    // Persistence
    private static let key = "birthData"

    static func load() -> BirthData? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(BirthData.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        // Clear horoscope cache entries
        let ud = UserDefaults.standard
        let allKeys = ud.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix("horoscope_cache_") {
            ud.removeObject(forKey: key)
        }
    }

    /// Combine birthDate and birthTime into a single Date for ephemeris computation.
    /// If birthTime is unknown, defaults to noon in the birth timezone.
    var effectiveBirthDateTime: Date {
        let tz = TimeZone(identifier: timezoneIdentifier) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        let dateComponents = cal.dateComponents([.year, .month, .day], from: birthDate)

        if let time = birthTime, birthTimeKnown {
            let timeComponents = cal.dateComponents([.hour, .minute], from: time)
            var combined = DateComponents()
            combined.year = dateComponents.year
            combined.month = dateComponents.month
            combined.day = dateComponents.day
            combined.hour = timeComponents.hour
            combined.minute = timeComponents.minute
            combined.second = 0
            return cal.date(from: combined) ?? birthDate
        } else {
            // Default to noon — minimizes maximum Moon longitude error to ~6.5 degrees
            var noonComponents = dateComponents
            noonComponents.hour = 12
            noonComponents.minute = 0
            noonComponents.second = 0
            return cal.date(from: noonComponents) ?? birthDate
        }
    }
}

// MARK: - NatalChart (computed from BirthData)

struct NatalChart {
    let birthRashi: Rashi
    let moonLongitude: Double
    let birthNakshatra: String
    let grahaSnapshot: GrahaSnapshot
    let birthTimeKnown: Bool

    /// True if the Moon is within 6.5 degrees of a rashi boundary at birth,
    /// AND the user's birth time is unknown. Rashi assignment may be inaccurate.
    var isRashiBoundary: Bool {
        guard !birthTimeKnown else { return false }
        let positionInRashi = moonLongitude.truncatingRemainder(dividingBy: 30.0)
        return positionInRashi < 6.5 || positionInRashi > 23.5
    }

    /// The adjacent rashi if near boundary (for disclaimer text)
    var adjacentRashi: Rashi? {
        guard isRashiBoundary else { return nil }
        let positionInRashi = moonLongitude.truncatingRemainder(dividingBy: 30.0)
        if positionInRashi < 6.5 {
            return Rashi(rawValue: (birthRashi.rawValue + 11) % 12)
        } else {
            return Rashi(rawValue: (birthRashi.rawValue + 1) % 12)
        }
    }

    /// Compute a NatalChart from BirthData using Swiss Ephemeris.
    /// Returns nil if the computation fails (date out of ephemeris range).
    static func compute(from birthData: BirthData) -> NatalChart? {
        let calc = VedicCalculator.shared
        let birthDateTime = birthData.effectiveBirthDateTime
        let jd = calc.julianDay(from: birthDateTime)

        // Compute Moon's sidereal longitude at birth
        guard let moonLon = calc.siderealLongitude(planet: 1, at: jd), moonLon != 0.0 else {
            return nil
        }

        let birthRashi = Rashi.from(siderealLongitude: moonLon)
        let grahaSnapshot = PanchangCalculator.computeGrahaSnapshot(julianDay: jd)

        // Compute nakshatra (1-based index)
        let nakshatraIdx = PanchangCalculator.nakshatraIndex(at: jd)
        let nakshatraNames = [
            "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira",
            "Ardra", "Punarvasu", "Pushya", "Ashlesha", "Magha",
            "Purva Phalguni", "Uttara Phalguni", "Hasta", "Chitra", "Swati",
            "Vishakha", "Anuradha", "Jyeshtha", "Mula", "Purva Ashadha",
            "Uttara Ashadha", "Shravana", "Dhanishta", "Shatabhisha",
            "Purva Bhadrapada", "Uttara Bhadrapada", "Revati",
        ]
        let nakshatraName = nakshatraNames[max(0, min(nakshatraIdx - 1, 26))]

        return NatalChart(
            birthRashi: birthRashi,
            moonLongitude: moonLon,
            birthNakshatra: nakshatraName,
            grahaSnapshot: grahaSnapshot,
            birthTimeKnown: birthData.birthTimeKnown
        )
    }
}
