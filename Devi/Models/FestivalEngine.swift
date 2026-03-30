// MARK: - Models/FestivalEngine.swift
// Dynamic festival computation engine — replaces hardcoded festival dates.
// Scans Jan 1 → Dec 31 for a given year using tithi, lunar month, and solar position
// to algorithmically determine Hindu festival dates.
//
// Reference city: Delhi (28.7041N, 77.1025E, Asia/Kolkata) — standard for Hindu calendar apps.
// All festival dates are computed at Delhi sunrise, matching drikpanchang.com conventions.

import Foundation

enum FestivalEngine {

    // MARK: - Reference City (Delhi IST)

    private static let delhiLat = 28.7041
    private static let delhiLon = 77.1025
    private static let delhiTZ = "Asia/Kolkata"

    // MARK: - Caches

    private static var festivalCache: [Int: [String: [String]]] = [:]
    private static var navratriCache: [Int: [NavratriPeriod]] = [:]

    // MARK: - Public API

    /// Returns all festivals for a given year as a dictionary: dateString → [festival names].
    /// Results are cached per year.
    static func festivals(forYear year: Int) -> [String: [String]] {
        if let cached = festivalCache[year] { return cached }
        let result = computeFestivals(forYear: year)
        festivalCache[year] = result
        return result
    }

    /// Returns Navratri periods (Chaitra + Sharad) for a given year.
    /// Each period has name, startDate, endDate.
    static func navratriPeriods(forYear year: Int) -> [NavratriPeriod] {
        if let cached = navratriCache[year] { return cached }
        let festivals = Self.festivals(forYear: year)
        var periods: [NavratriPeriod] = []

        // Find Chaitra Navratri start
        if let chaitraStart = findDateString(withFestival: "Chaitra Navratri Begins", in: festivals) {
            if let endDate = offsetDateString(chaitraStart, by: 8) {
                periods.append(NavratriPeriod(
                    name: "Chaitra Navratri",
                    startDate: chaitraStart,
                    endDate: endDate
                ))
            }
        }

        // Find Sharad Navratri start
        if let sharadStart = findDateString(withFestival: "Sharad Navratri Begins", in: festivals) {
            if let endDate = offsetDateString(sharadStart, by: 8) {
                periods.append(NavratriPeriod(
                    name: "Sharad Navratri",
                    startDate: sharadStart,
                    endDate: endDate
                ))
            }
        }

        navratriCache[year] = periods
        return periods
    }

    // MARK: - Core Computation

    private static func computeFestivals(forYear year: Int) -> [String: [String]] {
        var result: [String: [String]] = [:]
        let calc = VedicCalculator.shared

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: delhiTZ)!

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: delhiTZ)

        // Start: Jan 1 of the year
        guard let startDate = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endDate = cal.date(from: DateComponents(year: year, month: 12, day: 31)) else {
            return result
        }

        // -- Fixed Gregorian festivals --
        addFestival(&result, date: "\(year)-01-13", names: ["Lohri"])

        // -- Scan each day for tithi-based and solar festivals --
        var prevSunLonSign: Int = -1
        var holikaDahanDate: String?
        var chaitraNavratriStart: String?
        var sharadNavratriStart: String?

        var currentDate = startDate
        while currentDate <= endDate {
            let dateString = dateFormatter.string(from: currentDate)
            let jdMidnight = calc.julianDay(from: cal.startOfDay(for: currentDate))
            let sunriseJD = calc.sunrise(on: jdMidnight, lat: delhiLat, lon: delhiLon)
            let sunsetJD = calc.sunset(on: jdMidnight, lat: delhiLat, lon: delhiLon)

            // Compute panchang elements at Delhi sunrise
            let tIdx = PanchangCalculator.tithiIndex(at: sunriseJD)
            let paksha: Paksha = tIdx <= 15 ? .shukla : .krishna
            let tithiNum = tIdx <= 15 ? tIdx : tIdx - 15
            let lunarMonth = PanchangCalculator.computeLunarMonth(at: sunriseJD)

            // Also check tithi at sunset to catch kshaya (depleted) tithis —
            // tithis that start after sunrise and end before the next sunrise.
            // Traditional panchangs observe festivals on the day the tithi occurs,
            // even if it's not present at sunrise.
            let tIdxSunset = PanchangCalculator.tithiIndex(at: sunsetJD)
            let pakshaSunset: Paksha = tIdxSunset <= 15 ? .shukla : .krishna
            let tithiNumSunset = tIdxSunset <= 15 ? tIdxSunset : tIdxSunset - 15

            // -- Solar ingress festivals --
            let sunLon = calc.sunSiderealLongitude(at: sunriseJD)
            var normalizedSunLon = sunLon.truncatingRemainder(dividingBy: 360.0)
            if normalizedSunLon < 0 { normalizedSunLon += 360.0 }
            let sunSign = Int(normalizedSunLon / 30.0)

            if prevSunLonSign >= 0 && sunSign != prevSunLonSign {
                // Sun changed sign overnight
                if sunSign == 9 { // Capricorn = sign index 9 (270°)
                    addFestival(&result, date: dateString, names: [
                        "Makar Sankranti", "Pongal", "Uttarayan", "Magh Bihu"
                    ])
                }
                if sunSign == 0 { // Aries = sign index 0 (0°)
                    addFestival(&result, date: dateString, names: [
                        "Baisakhi", "Tamil New Year", "Vishu",
                        "Bohag Bihu", "Rongali Bihu", "Poila Boishakh"
                    ])
                }
                if sunSign == 2 { // Gemini = sign index 2 (60°)
                    addFestival(&result, date: dateString, names: ["Raja Parba"])
                }
                if sunSign == 4 { // Leo = sign index 4 (120°)
                    addFestival(&result, date: dateString, names: ["Kati Bihu", "Kongali Bihu"])
                }
            }
            prevSunLonSign = sunSign

            // -- Tithi-based festivals (check both sunrise and sunset for kshaya coverage) --
            matchTithiFestivals(
                &result,
                dateString: dateString,
                lunarMonth: lunarMonth,
                paksha: paksha,
                tithiNum: tithiNum,
                holikaDahanDate: &holikaDahanDate,
                chaitraNavratriStart: &chaitraNavratriStart,
                sharadNavratriStart: &sharadNavratriStart
            )
            // Second pass at sunset for kshaya tithis
            matchTithiFestivals(
                &result,
                dateString: dateString,
                lunarMonth: lunarMonth,
                paksha: pakshaSunset,
                tithiNum: tithiNumSunset,
                holikaDahanDate: &holikaDahanDate,
                chaitraNavratriStart: &chaitraNavratriStart,
                sharadNavratriStart: &sharadNavratriStart
            )

            // -- Nakshatra-based festivals --
            matchNakshatraFestivals(
                &result,
                dateString: dateString,
                sunriseJD: sunriseJD,
                lunarMonth: lunarMonth,
                paksha: paksha,
                tithiNum: tithiNum
            )

            currentDate = cal.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // -- Post-scan: Holi is day after Holika Dahan --
        if let holikaDate = holikaDahanDate, let holiDate = offsetDateString(holikaDate, by: 1) {
            addFestival(&result, date: holiDate, names: ["Holi"])
        }

        // -- Post-scan: Navratri day sequence --
        if let start = chaitraNavratriStart {
            addNavratriDays(&result, startDate: start, prefix: "Chaitra")
        }
        if let start = sharadNavratriStart {
            addNavratriDays(&result, startDate: start, prefix: "Sharad")
        }

        return result
    }

    // MARK: - Tithi Matching

    private static func matchTithiFestivals(
        _ result: inout [String: [String]],
        dateString: String,
        lunarMonth: String,
        paksha: Paksha,
        tithiNum: Int,
        holikaDahanDate: inout String?,
        chaitraNavratriStart: inout String?,
        sharadNavratriStart: inout String?
    ) {
        // Vasant Panchami / Saraswati Puja: Magha Shukla 5
        if lunarMonth == "Magha" && paksha == .shukla && tithiNum == 5 {
            addFestival(&result, date: dateString, names: ["Vasant Panchami", "Saraswati Puja"])
        }

        // Maha Shivaratri: Phalguna/Magha Krishna 14
        // (month can vary due to lunar month approximation — check both)
        if (lunarMonth == "Phalguna" || lunarMonth == "Magha") && paksha == .krishna && tithiNum == 14 {
            addFestival(&result, date: dateString, names: ["Maha Shivaratri"])
        }

        // Holika Dahan: Phalguna Shukla 15 (Purnima)
        if lunarMonth == "Phalguna" && paksha == .shukla && tithiNum == 15 {
            holikaDahanDate = dateString
            addFestival(&result, date: dateString, names: ["Holika Dahan"])
        }

        // Chaitra Navratri Begins / Ugadi / Gudi Padwa: Chaitra Shukla 1
        if lunarMonth == "Chaitra" && paksha == .shukla && tithiNum == 1 {
            if chaitraNavratriStart == nil {
                chaitraNavratriStart = dateString
                addFestival(&result, date: dateString, names: ["Chaitra Navratri Begins", "Ugadi", "Gudi Padwa"])
            }
        }

        // Ram Navami: Chaitra Shukla 9
        if lunarMonth == "Chaitra" && paksha == .shukla && tithiNum == 9 {
            addFestival(&result, date: dateString, names: ["Ram Navami"])
        }

        // Hanuman Jayanti / Chaitra Purnima: Chaitra Shukla 15
        if lunarMonth == "Chaitra" && paksha == .shukla && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Hanuman Jayanti", "Chaitra Purnima"])
        }

        // Akshaya Tritiya: Vaishakha Shukla 3
        if lunarMonth == "Vaishakha" && paksha == .shukla && tithiNum == 3 {
            addFestival(&result, date: dateString, names: ["Akshaya Tritiya"])
        }

        // Buddha Purnima: Vaishakha Shukla 15
        if lunarMonth == "Vaishakha" && paksha == .shukla && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Buddha Purnima"])
        }

        // Guru Purnima: Ashadha Shukla 15
        if lunarMonth == "Ashadha" && paksha == .shukla && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Guru Purnima"])
        }

        // Raksha Bandhan: Shravana Shukla 15
        if lunarMonth == "Shravana" && paksha == .shukla && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Raksha Bandhan"])
        }

        // Krishna Janmashtami: Bhadrapada Krishna 8
        if lunarMonth == "Bhadrapada" && paksha == .krishna && tithiNum == 8 {
            addFestival(&result, date: dateString, names: ["Krishna Janmashtami"])
        }

        // Ganesh Chaturthi: Bhadrapada Shukla 4
        if lunarMonth == "Bhadrapada" && paksha == .shukla && tithiNum == 4 {
            addFestival(&result, date: dateString, names: ["Ganesh Chaturthi"])
        }

        // Sharad Navratri Begins: Ashwin Shukla 1
        if lunarMonth == "Ashwin" && paksha == .shukla && tithiNum == 1 {
            if sharadNavratriStart == nil {
                sharadNavratriStart = dateString
                addFestival(&result, date: dateString, names: ["Sharad Navratri Begins"])
            }
        }

        // Dussehra / Vijayadashami: Ashwin Shukla 10
        if lunarMonth == "Ashwin" && paksha == .shukla && tithiNum == 10 {
            addFestival(&result, date: dateString, names: ["Dussehra", "Vijayadashami"])
        }

        // Karva Chauth: Kartik Krishna 4
        if lunarMonth == "Kartik" && paksha == .krishna && tithiNum == 4 {
            addFestival(&result, date: dateString, names: ["Karva Chauth"])
        }

        // Dhanteras: Kartik Krishna 13
        if lunarMonth == "Kartik" && paksha == .krishna && tithiNum == 13 {
            addFestival(&result, date: dateString, names: ["Dhanteras"])
        }

        // Naraka Chaturdashi: Kartik Krishna 14
        if lunarMonth == "Kartik" && paksha == .krishna && tithiNum == 14 {
            addFestival(&result, date: dateString, names: ["Naraka Chaturdashi"])
        }

        // Diwali / Lakshmi Puja / Kali Puja: Kartik Krishna 15 (Amavasya)
        if lunarMonth == "Kartik" && paksha == .krishna && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Diwali", "Lakshmi Puja", "Kali Puja"])
        }

        // Govardhan Puja / Annakut / Bestu Varas: Kartik Shukla 1
        if lunarMonth == "Kartik" && paksha == .shukla && tithiNum == 1 {
            addFestival(&result, date: dateString, names: ["Govardhan Puja", "Annakut", "Bestu Varas"])
        }

        // Bhai Dooj: Kartik Shukla 2
        if lunarMonth == "Kartik" && paksha == .shukla && tithiNum == 2 {
            addFestival(&result, date: dateString, names: ["Bhai Dooj"])
        }

        // Chhath Puja: Kartik Shukla 6
        if lunarMonth == "Kartik" && paksha == .shukla && tithiNum == 6 {
            addFestival(&result, date: dateString, names: ["Chhath Puja"])
        }

        // Kartik Purnima / Dev Diwali: Kartik Shukla 15
        if lunarMonth == "Kartik" && paksha == .shukla && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Kartik Purnima", "Dev Diwali"])
        }

        // ── Pan-Indian ──

        // Nag Panchami: Shravana Shukla 5
        if lunarMonth == "Shravana" && paksha == .shukla && tithiNum == 5 {
            addFestival(&result, date: dateString, names: ["Nag Panchami"])
        }

        // Anant Chaturdashi: Bhadrapada Shukla 14
        if lunarMonth == "Bhadrapada" && paksha == .shukla && tithiNum == 14 {
            addFestival(&result, date: dateString, names: ["Anant Chaturdashi"])
        }

        // Sharad Purnima / Kojagari Purnima: Ashwin Shukla 15
        if lunarMonth == "Ashwin" && paksha == .shukla && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Sharad Purnima", "Kojagari Purnima"])
        }

        // Mahalaya Amavasya: Ashwin Krishna 15
        if lunarMonth == "Ashwin" && paksha == .krishna && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Mahalaya Amavasya"])
        }

        // ── North Indian ──

        // Hariyali Teej: Shravana Shukla 3
        if lunarMonth == "Shravana" && paksha == .shukla && tithiNum == 3 {
            addFestival(&result, date: dateString, names: ["Hariyali Teej"])
        }

        // Hartalika Teej: Bhadrapada Shukla 3
        if lunarMonth == "Bhadrapada" && paksha == .shukla && tithiNum == 3 {
            addFestival(&result, date: dateString, names: ["Hartalika Teej"])
        }

        // Tulsi Vivah: Kartik Shukla 11
        if lunarMonth == "Kartik" && paksha == .shukla && tithiNum == 11 {
            addFestival(&result, date: dateString, names: ["Tulsi Vivah"])
        }

        // Ganga Dussehra: Jyeshtha Shukla 10
        if lunarMonth == "Jyeshtha" && paksha == .shukla && tithiNum == 10 {
            addFestival(&result, date: dateString, names: ["Ganga Dussehra"])
        }

        // Nirjala Ekadashi: Jyeshtha Shukla 11
        if lunarMonth == "Jyeshtha" && paksha == .shukla && tithiNum == 11 {
            addFestival(&result, date: dateString, names: ["Nirjala Ekadashi"])
        }

        // Ahoi Ashtami: Kartik Krishna 8
        if lunarMonth == "Kartik" && paksha == .krishna && tithiNum == 8 {
            addFestival(&result, date: dateString, names: ["Ahoi Ashtami"])
        }

        // ── Bengali ──

        // Durga Puja Saptami: Ashwin Shukla 7
        if lunarMonth == "Ashwin" && paksha == .shukla && tithiNum == 7 {
            addFestival(&result, date: dateString, names: ["Durga Puja Saptami"])
        }

        // Durga Puja Ashtami: Ashwin Shukla 8
        if lunarMonth == "Ashwin" && paksha == .shukla && tithiNum == 8 {
            addFestival(&result, date: dateString, names: ["Durga Puja Ashtami"])
        }

        // Jamai Shashti: Jyeshtha Shukla 6
        if lunarMonth == "Jyeshtha" && paksha == .shukla && tithiNum == 6 {
            addFestival(&result, date: dateString, names: ["Jamai Shashti"])
        }

        // Poush Parbon: Pausha Shukla 15 (Pausha Purnima)
        if lunarMonth == "Pausha" && paksha == .shukla && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Poush Parbon"])
        }

        // ── Telugu/Andhra ──

        // Bathukamma (Finale): Ashwin Krishna 15
        if lunarMonth == "Ashwin" && paksha == .krishna && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Bathukamma"])
        }

        // Bonalu: Ashadha Shukla 1
        if lunarMonth == "Ashadha" && paksha == .shukla && tithiNum == 1 {
            addFestival(&result, date: dateString, names: ["Bonalu"])
        }

        // ── Maharashtrian ──

        // Vat Savitri / Vat Purnima: Jyeshtha Shukla 15
        if lunarMonth == "Jyeshtha" && paksha == .shukla && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Vat Savitri", "Vat Purnima"])
        }

        // Bail Pola: Shravana Krishna 15 (Shravana Amavasya)
        if lunarMonth == "Shravana" && paksha == .krishna && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Bail Pola"])
        }

        // ── Odia ──

        // Jagannath Rath Yatra: Ashadha Shukla 2
        if lunarMonth == "Ashadha" && paksha == .shukla && tithiNum == 2 {
            addFestival(&result, date: dateString, names: ["Jagannath Rath Yatra"])
        }

        // Nuakhai: Bhadrapada Shukla 5
        if lunarMonth == "Bhadrapada" && paksha == .shukla && tithiNum == 5 {
            addFestival(&result, date: dateString, names: ["Nuakhai"])
        }

        // ── Tamil/South Indian ──

        // Skanda Sashti: Kartik Shukla 6
        if lunarMonth == "Kartik" && paksha == .shukla && tithiNum == 6 {
            addFestival(&result, date: dateString, names: ["Skanda Sashti"])
        }

        // Aadi Amavasai: Shravana Krishna 15
        if lunarMonth == "Shravana" && paksha == .krishna && tithiNum == 15 {
            addFestival(&result, date: dateString, names: ["Aadi Amavasai"])
        }
    }

    // MARK: - Nakshatra-based Festivals

    private static func matchNakshatraFestivals(
        _ result: inout [String: [String]],
        dateString: String,
        sunriseJD: Double,
        lunarMonth: String,
        paksha: Paksha,
        tithiNum: Int
    ) {
        let nakIdx = PanchangCalculator.nakshatraIndex(at: sunriseJD)

        // Onam: Shravana month, Thiruvonam nakshatra (22 = Shravana)
        if lunarMonth == "Shravana" && nakIdx == 22 {
            // Only add if not already added for this year (first occurrence)
            if result[dateString]?.contains("Onam") != true {
                addFestival(&result, date: dateString, names: ["Onam"])
            }
        }

        // Panguni Uttram: Uttara Phalguni nakshatra (12) near Phalguna Purnima
        if (lunarMonth == "Phalguna" || lunarMonth == "Chaitra")
            && paksha == .shukla && tithiNum == 15 && nakIdx == 12 {
            addFestival(&result, date: dateString, names: ["Panguni Uttram"])
        }

        // Thaipusam: Pushya nakshatra (8) during Magha month, Shukla paksha
        if lunarMonth == "Magha" && paksha == .shukla && nakIdx == 8 {
            if result[dateString]?.contains("Thaipusam") != true {
                addFestival(&result, date: dateString, names: ["Thaipusam"])
            }
        }

        // Karthigai Deepam: Krittika nakshatra (3) during Kartik month, near Purnima (tithi >= 13)
        if lunarMonth == "Kartik" && nakIdx == 3 && paksha == .shukla && tithiNum >= 13 {
            if result[dateString]?.contains("Karthigai Deepam") != true {
                addFestival(&result, date: dateString, names: ["Karthigai Deepam"])
            }
        }
    }

    // MARK: - Navratri Day Sequence

    private static func addNavratriDays(_ result: inout [String: [String]], startDate: String, prefix: String) {
        for dayOffset in 1...8 {
            guard let dateString = offsetDateString(startDate, by: dayOffset) else { continue }
            let dayNum = dayOffset + 1

            var names = ["\(prefix) Navratri Day \(dayNum)"]

            // Special names for key days
            if dayNum == 8 {
                if prefix == "Sharad" {
                    names.append("Maha Ashtami")
                } else {
                    names.append("Durga Ashtami")
                }
            }
            if dayNum == 9 {
                if prefix == "Sharad" {
                    names.append("Maha Navami")
                }
            }

            addFestival(&result, date: dateString, names: names)
        }
    }

    // MARK: - Helpers

    private static func addFestival(_ result: inout [String: [String]], date: String, names: [String]) {
        var existing = result[date] ?? []
        for name in names {
            if !existing.contains(name) {
                existing.append(name)
            }
        }
        result[date] = existing
    }

    private static func findDateString(withFestival name: String, in festivals: [String: [String]]) -> String? {
        for (dateString, names) in festivals {
            if names.contains(name) {
                return dateString
            }
        }
        return nil
    }

    private static func offsetDateString(_ dateString: String, by days: Int) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: delhiTZ)
        guard let date = formatter.date(from: dateString) else { return nil }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: delhiTZ)!
        guard let newDate = cal.date(byAdding: .day, value: days, to: date) else { return nil }
        return formatter.string(from: newDate)
    }
}
