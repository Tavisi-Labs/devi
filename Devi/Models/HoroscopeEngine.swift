// MARK: - Models/HoroscopeEngine.swift
// Stateless rules engine that produces a DailyHoroscope from a NatalChart + transit data.
//
// The engine is deterministic: given the same NatalChart, GrahaSnapshot, date, and timezone,
// it always produces the same reading. Variant selection uses a stable hash of day-of-year
// plus birth rashi, so the reading changes daily but is consistent across app launches.
//
// All astronomical positions come from Swiss Ephemeris via VedicCalculator/PanchangCalculator.
// Content comes from HoroscopeContentLibrary (themes, category readings, mantras, colors).

import Foundation

// MARK: - Horoscope Engine

/// Pure computation layer for daily horoscope generation.
/// No state, no UI, no persistence — just rules.
enum HoroscopeEngine {

    // MARK: - Nakshatra Reference Tables

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

    // MARK: - Public API

    /// Generate a complete daily horoscope reading.
    ///
    /// - Parameters:
    ///   - natalChart: The user's birth chart (Moon rashi, nakshatra, graha positions)
    ///   - todaySnapshot: Current transit positions of all 9 grahas
    ///   - panchang: The day's panchang — tithi, nakshatra, and yoga feed the
    ///     variant seed so the reading rotates daily through the content library.
    ///   - date: The date for this reading (used for variant selection)
    ///   - timezoneIdentifier: User's timezone for consistent day boundary
    /// - Returns: A fully populated `DailyHoroscope`
    static func generateReading(
        natalChart: NatalChart,
        todaySnapshot: GrahaSnapshot,
        panchang: DailyPanchang,
        date: Date,
        timezoneIdentifier: String
    ) -> DailyHoroscope {

        // --- 1. Moon house (transit Moon relative to birth Moon rashi) ---
        let transitMoonLon = todaySnapshot.longitude(of: .moon)
        let transitMoonRashi = Rashi.from(siderealLongitude: transitMoonLon)
        let moonHouse = Rashi.moonHouse(birthRashi: natalChart.birthRashi, transitRashi: transitMoonRashi)

        // --- 2. Transit nakshatra of the Moon ---
        let transitNakshatraIdx = nakshatraIndexFromLongitude(transitMoonLon) // 0-based
        let transitNakshatra = nakshatraNames[transitNakshatraIdx]
        let transitNakshatraRuler = nakshatraRulers[transitNakshatraIdx]

        // --- 3. Jupiter and Saturn houses (whole-sign from birth Moon) ---
        let jupiterLon = todaySnapshot.longitude(of: .jupiter)
        let jupiterRashi = Rashi.from(siderealLongitude: jupiterLon)
        let jupiterHouse = Rashi.moonHouse(birthRashi: natalChart.birthRashi, transitRashi: jupiterRashi)

        let saturnLon = todaySnapshot.longitude(of: .saturn)
        let saturnRashi = Rashi.from(siderealLongitude: saturnLon)
        let saturnHouse = Rashi.moonHouse(birthRashi: natalChart.birthRashi, transitRashi: saturnRashi)

        // --- 4. Variant selection (enriched daily hash) ---
        //
        // The seed mixes day-of-year, birth rashi, and the day's panchang signals
        // (tithi number, nakshatra index, yoga number) so adjacent days in the
        // same Moon house diverge, and the large content library is sampled broadly.
        // Coprime multipliers (31, 73, 137) spread the hash across variant counts.
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: timezoneIdentifier) ?? .current
        let dayOfYear: Int = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let rashiSeed: Int = natalChart.birthRashi.rawValue
        let tithiSeed: Int = panchang.tithi.number * 31
        let nakshatraSeed: Int = transitNakshatraIdx * 73
        let yogaSeed: Int = panchang.yoga.number * 137
        let variantSeed: Int = dayOfYear + rashiSeed + tithiSeed + nakshatraSeed + yogaSeed

        // --- 5. Theme statement and supporting text ---
        let themes = HoroscopeContentLibrary.themes
        // themes is indexed by house (index 0 = house 1)
        let houseThemes = themes[moonHouse - 1]
        let themeVariantIndex = houseThemes.isEmpty ? 0 : abs(variantSeed) % houseThemes.count
        let selectedTheme = houseThemes.isEmpty
            ? fallbackTheme()
            : houseThemes[themeVariantIndex]

        // Supporting text is the theme blurb on its own. Jupiter and Saturn
        // house transits are still surfaced through TransitContext.significantAspects
        // (built below) and through the public jupiterModifierText / saturnModifierText
        // helpers, which the "Why?" detail panel may consume. They are intentionally
        // not concatenated into the body prose because the slow planet houses change
        // on month-to-year cadence, which made the daily reading visibly repeat.
        let supportingText = selectedTheme.supportingText

        // --- 6. Category readings ---
        let categoryReadings = buildCategoryReadings(
            moonHouse: moonHouse,
            variantSeed: variantSeed
        )

        // --- 7. Mantra (based on transit Moon's nakshatra) ---
        let mantra = HoroscopeContentLibrary.nakshatraMantra[transitNakshatra]
            ?? MantraReading(
                sanskrit: "Om Chandraya Namaha",
                translation: "Salutations to the Moon",
                deity: "Chandra"
            )

        // --- 8. Auspicious color (based on transit Moon's nakshatra ruler) ---
        let auspiciousColor = HoroscopeContentLibrary.planetColor[transitNakshatraRuler]
            ?? AuspiciousColor(name: "White", hex: "#FFFFFF")

        // --- 9. Significant aspects ---
        let aspects = buildSignificantAspects(
            jupiterHouse: jupiterHouse,
            saturnHouse: saturnHouse,
            moonHouse: moonHouse,
            transitNakshatra: transitNakshatra,
            birthRashi: natalChart.birthRashi
        )

        // --- 10. Transit context ---
        let transitContext = TransitContext(
            moonHouse: moonHouse,
            moonHouseVedicName: TransitContext.houseVedicNames[moonHouse] ?? "Unknown",
            moonNakshatra: transitNakshatra,
            significantAspects: aspects,
            birthRashi: natalChart.birthRashi,
            birthTimeKnown: natalChart.birthTimeKnown
        )

        return DailyHoroscope(
            date: date,
            themeStatement: selectedTheme.themeStatement,
            supportingText: supportingText,
            doList: selectedTheme.doList,
            dontList: selectedTheme.dontList,
            categories: categoryReadings,
            mantra: mantra,
            auspiciousColor: auspiciousColor,
            transitContext: transitContext
        )
    }

    // MARK: - Jupiter Modifier

    /// Returns optional flavor text when Jupiter occupies a notable house.
    /// Jupiter is the great benefic (Guru) -- its transit through certain houses
    /// amplifies fortune, wisdom, or expansion in that life domain.
    static func jupiterModifierText(house: Int) -> String? {
        return HoroscopeContentLibrary.jupiterModifiers[house]
    }

    // MARK: - Saturn Modifier

    /// Returns optional flavor text when Saturn occupies a notable house.
    /// Includes Sade Sati detection: Saturn in houses 12, 1, or 2 from birth Moon
    /// triggers a 7.5-year period of karmic lessons and restructuring.
    static func saturnModifierText(house: Int, birthRashi: Rashi) -> String? {
        // Sade Sati: Saturn transiting houses 12, 1, or 2 from birth Moon rashi
        let isSadeSati = house == 12 || house == 1 || house == 2
        if isSadeSati {
            let phase: String
            switch house {
            case 12: phase = "rising (approaching)"
            case 1:  phase = "peak (over birth Moon)"
            case 2:  phase = "setting (departing)"
            default: phase = ""
            }
            let baseMod = HoroscopeContentLibrary.saturnModifiers[house] ?? ""
            return "Sade Sati is active (\(phase)). \(baseMod)".trimmingCharacters(in: .whitespaces)
        }

        return HoroscopeContentLibrary.saturnModifiers[house]
    }

    // MARK: - Private Helpers

    /// Convert sidereal longitude to 0-based nakshatra index (0-26).
    private static func nakshatraIndexFromLongitude(_ longitude: Double) -> Int {
        var lon = longitude.truncatingRemainder(dividingBy: 360.0)
        if lon < 0 { lon += 360.0 }
        return max(0, min(Int(lon / (360.0 / 27.0)), 26))
    }

    /// Build the four category readings (love, work, spirituality, health)
    /// by sampling a variant from the content library's array for each slot.
    /// The variant seed comes from the enriched daily hash in `generateReading`,
    /// so adjacent days with different panchang signals pick different variants
    /// even when the Moon stays in the same house.
    private static func buildCategoryReadings(
        moonHouse: Int,
        variantSeed: Int
    ) -> [CategoryReading] {
        return HoroscopeCategory.allCases.map { category in
            if let houseReadings = HoroscopeContentLibrary.categoryReadings[moonHouse],
               let variants = houseReadings[category],
               !variants.isEmpty {
                // `abs()` guards against negative seeds after multiplicative mixing.
                let idx = abs(variantSeed) % variants.count
                let reading = variants[idx]
                return CategoryReading(
                    category: category,
                    summary: reading.summary,
                    intensity: reading.intensity
                )
            }
            // Fallback: neutral reading if content library has no entry
            return CategoryReading(
                category: category,
                summary: "A day of steady progress. Stay mindful and present.",
                intensity: 3
            )
        }
    }

    /// Neutral theme used only when the content library returns an empty
    /// variant array for the current Moon house (shouldn't happen in practice,
    /// but keeps the engine total).
    private static func fallbackTheme() -> HoroscopeContentLibrary.HouseTheme {
        HoroscopeContentLibrary.HouseTheme(
            themeStatement: "A steady, grounded day awaits.",
            supportingText: "Honor what is in front of you with presence. Small actions, done with care, matter more than you know.",
            doList: ["Be kind to yourself", "Move your body gently", "Pause before reacting"],
            dontList: ["Force outcomes", "Ignore your needs", "Compare yourself to others"]
        )
    }

    /// Build the significant aspects array for the TransitContext "Why?" sheet.
    /// These are human-readable sentences explaining what's astronomically happening.
    private static func buildSignificantAspects(
        jupiterHouse: Int,
        saturnHouse: Int,
        moonHouse: Int,
        transitNakshatra: String,
        birthRashi: Rashi
    ) -> [String] {
        var aspects: [String] = []

        // Moon transit
        let moonVedicName = TransitContext.houseVedicNames[moonHouse] ?? ""
        aspects.append(
            "Moon transits your \(ordinal(moonHouse)) house (\(moonVedicName)) in \(transitNakshatra) nakshatra"
        )

        // Jupiter transit
        let jupiterVedicName = TransitContext.houseVedicNames[jupiterHouse] ?? ""
        aspects.append(
            "Jupiter transits your \(ordinal(jupiterHouse)) house (\(jupiterVedicName))"
        )

        // Saturn transit
        let saturnVedicName = TransitContext.houseVedicNames[saturnHouse] ?? ""
        let sadeSatiNote = (saturnHouse == 12 || saturnHouse == 1 || saturnHouse == 2)
            ? " — Sade Sati active"
            : ""
        aspects.append(
            "Saturn transits your \(ordinal(saturnHouse)) house (\(saturnVedicName))\(sadeSatiNote)"
        )

        return aspects
    }

    /// Format an integer as an ordinal string (1st, 2nd, 3rd, ..., 12th).
    private static func ordinal(_ n: Int) -> String {
        let suffix: String
        switch n {
        case 1: suffix = "st"
        case 2: suffix = "nd"
        case 3: suffix = "rd"
        default: suffix = "th"
        }
        return "\(n)\(suffix)"
    }
}
