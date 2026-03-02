// MARK: - Models/ShareTextBuilder.swift
// Pure static text formatting for sharing panchang info via WhatsApp, Messages, etc.
// Same pattern as PanchangDescriptions — stateless enum namespace, no instances.

import Foundation

enum ShareTextBuilder {

    // MARK: - Daily Summary

    /// Full day's panchang info — the "priest's daily WhatsApp message" replacement.
    static func dailySummary(panchang: DailyPanchang, city: UserCity, navratriDay: NavratriDay?) -> String {
        var lines: [String] = []

        lines.append("Devi — Daily Panchang")
        lines.append("\(formattedDate(from: panchang.dateString, timezoneIdentifier: city.timezoneIdentifier)) · \(city.name)")
        lines.append("")

        // Lunar month + paksha
        lines.append("\(panchang.lunarMonth), \(panchang.tithi.paksha.rawValue) Paksha")

        // Core five elements
        lines.append("Tithi: \(panchang.tithi.name) (until \(formatTime(panchang.tithi.endTime, timezoneIdentifier: city.timezoneIdentifier)))")
        lines.append("Nakshatra: \(panchang.nakshatra.name) (until \(formatTime(panchang.nakshatra.endTime, timezoneIdentifier: city.timezoneIdentifier)))")
        let karanaText = panchang.karanas.map { k in
            "\(k.name) (until \(formatTime(k.endTime, timezoneIdentifier: city.timezoneIdentifier)))"
        }.joined(separator: " → ")
        lines.append("Yoga: \(panchang.yoga.name)")
        lines.append("Karana: \(karanaText)")
        lines.append("Vara: \(panchang.varaDeity)")
        lines.append("")

        // Solar data
        lines.append("☀️ Sunrise: \(formatTime(panchang.solar.sunrise, timezoneIdentifier: city.timezoneIdentifier)) · Sunset: \(formatTime(panchang.solar.sunset, timezoneIdentifier: city.timezoneIdentifier))")
        if let moonrise = panchang.solar.moonrise {
            lines.append("🌙 Moonrise: \(formatTime(moonrise, timezoneIdentifier: city.timezoneIdentifier))")
        }

        // Time windows
        if !panchang.timeWindows.isEmpty {
            lines.append("")
            lines.append("Time Windows:")
            for window in panchang.timeWindows {
                let emoji = windowEmoji(window.type)
                let start = formatTime(window.start, timezoneIdentifier: city.timezoneIdentifier)
                let end = formatTime(window.end, timezoneIdentifier: city.timezoneIdentifier)
                lines.append("\(emoji) \(window.type.rawValue): \(start) – \(end)")
            }
        }

        // Fasting day
        if let fastType = panchang.tithi.fastingType {
            lines.append("")
            lines.append("🔥 Today is \(fastType)")
        }

        // Navratri
        if let navDay = navratriDay {
            lines.append("")
            lines.append("🪷 Navratri Day \(navDay.dayNumber) — \(navDay.goddessName)")
            lines.append("Wear: \(navDay.colorName) · Offering: \(navDay.offering)")
        }

        lines.append(footer)
        return lines.joined(separator: "\n")
    }

    // MARK: - Eclipse Alert

    /// Mimics the WhatsApp eclipse alert format — Devanagari header, city-localized contact times.
    static func eclipseAlert(eclipse: EclipseEvent, cityName: String, timezoneIdentifier: String) -> String {
        var lines: [String] = []

        lines.append("\(eclipse.body.devanagari) — \(eclipse.displayName)")
        lines.append(formattedDate(from: eclipse.dateString, timezoneIdentifier: timezoneIdentifier))
        lines.append("")
        lines.append("Eclipse timings for \(cityName):")
        lines.append("")

        for contact in eclipse.contactTimeline {
            lines.append("\(contact.label): \(formatTime(contact.time, timezoneIdentifier: timezoneIdentifier))")
        }

        lines.append("")
        lines.append("Magnitude: \(String(format: "%.3f", eclipse.magnitude))")

        if let note = eclipse.mythologyNote {
            lines.append("")
            lines.append("\"\(note)\"")
        }

        lines.append(footer)
        return lines.joined(separator: "\n")
    }

    // MARK: - Navratri Day

    /// Compact navratri day card — goddess, color, offering, mantra in Devanagari + transliteration.
    static func navratriDay(_ day: NavratriDay) -> String {
        var lines: [String] = []

        lines.append("Navratri Day \(day.dayNumber) — \(day.goddessName)")
        lines.append("\"\(day.goddessEpithet)\"")
        lines.append("")
        lines.append("Wear: \(day.colorName)")
        lines.append("Offering: \(day.offering)")
        lines.append("")
        lines.append(day.mantra)
        lines.append(day.mantraTranslit)

        lines.append(footer)
        return lines.joined(separator: "\n")
    }

    // MARK: - Panchang Element

    /// Adapts output per element type — name, meaning, timing, top activities. ~8 lines.
    static func panchangElement(_ element: PanchangElement, timezoneIdentifier: String) -> String {
        var lines: [String] = []

        switch element {
        case .tithi(let t):
            let info = PanchangDescriptions.tithiInfo(for: t.name)
            lines.append("Tithi: \(t.name) (\(t.paksha.rawValue) Paksha)")
            if let meaning = info?.meaning { lines.append(meaning) }
            lines.append("Until \(formatTime(t.endTime, timezoneIdentifier: timezoneIdentifier))")
            if let activities = info?.auspiciousActivities {
                lines.append("")
                lines.append(contentsOf: activities.prefix(3).map { "• \($0)" })
            }

        case .nakshatra(let n):
            let info = PanchangDescriptions.nakshatraInfo(for: n.name)
            lines.append("Nakshatra: \(n.name)")
            if let meaning = info?.meaning { lines.append(meaning) }
            lines.append("Ruler: \(n.ruler) · Deity: \(n.deity)")
            lines.append("Until \(formatTime(n.endTime, timezoneIdentifier: timezoneIdentifier))")
            if let activities = info?.auspiciousActivities {
                lines.append("")
                lines.append(contentsOf: activities.prefix(3).map { "• \($0)" })
            }

        case .yoga(let y):
            let info = PanchangDescriptions.yogaInfo(for: y.number)
            lines.append("Yoga: \(y.name)")
            if let meaning = info?.meaning { lines.append(meaning) }
            if let quality = info?.quality { lines.append("Quality: \(quality)") }
            lines.append("Until \(formatTime(y.endTime, timezoneIdentifier: timezoneIdentifier))")

        case .karana(let ks):
            lines.append("Karanas:")
            for k in ks {
                let info = PanchangDescriptions.karanaInfo(for: k.name)
                let typeStr = info.map { " (\($0.type))" } ?? ""
                lines.append("  \(k.name)\(typeStr) — until \(formatTime(k.endTime, timezoneIdentifier: timezoneIdentifier))")
            }

        case .vara(let v):
            let weekday = varaWeekday(from: v)
            let info = PanchangDescriptions.varaInfo(for: weekday)
            lines.append("Vara: \(v)")
            if let info = info {
                lines.append(info.weekday)
                if !info.auspiciousActivities.isEmpty {
                    lines.append("")
                    lines.append(contentsOf: info.auspiciousActivities.prefix(3).map { "• \($0)" })
                }
            }

        case .timeWindow(let tw):
            let info = PanchangDescriptions.timeWindowInfo(for: timeWindowKey(tw.type))
            lines.append("\(windowEmoji(tw.type)) \(tw.type.rawValue)")
            if let meaning = info?.meaning { lines.append(meaning) }
            lines.append("\(formatTime(tw.start, timezoneIdentifier: timezoneIdentifier)) – \(formatTime(tw.end, timezoneIdentifier: timezoneIdentifier))")
            if let rec = info?.recommendation {
                lines.append("")
                let firstSentence = rec.components(separatedBy: ". ").first ?? rec
                lines.append(firstSentence + ".")
            }

        case .eclipse(let e):
            lines.append("\(e.body.devanagari) — \(e.displayName)")
            lines.append("Magnitude: \(String(format: "%.3f", e.magnitude))")
            for contact in e.contactTimeline {
                lines.append("\(contact.label): \(formatTime(contact.time, timezoneIdentifier: timezoneIdentifier))")
            }
        }

        lines.append(footer)
        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    /// Parses ISO date string → "Friday, March 20, 2026"
    private static func formattedDate(from dateString: String, timezoneIdentifier: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.timeZone = TimeZone(identifier: timezoneIdentifier) ?? .current

        guard let date = inputFormatter.date(from: dateString) else { return dateString }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        outputFormatter.timeZone = TimeZone(identifier: timezoneIdentifier) ?? .current
        return outputFormatter.string(from: date)
    }

    /// Delegates to the global deviFormatTime() from Theme.swift
    private static func formatTime(_ date: Date, timezoneIdentifier: String) -> String {
        deviFormatTime(date, timezoneIdentifier: timezoneIdentifier)
    }

    /// ✅ for auspicious, ⛔ for inauspicious, ⚠️ for caution
    private static func windowEmoji(_ type: TimeWindow.WindowType) -> String {
        switch type {
        case .abhijitMuhurta, .brahmaMuhurta: return "✅"
        case .rahuKalam: return "⛔"
        case .gulikaKalam, .yamaganda: return "⚠️"
        }
    }

    /// Extracts weekday name from vara string like "Surya (Sun)"
    private static func varaWeekday(from varaDeity: String) -> String {
        let deityName = varaDeity.components(separatedBy: " (").first ?? varaDeity
        switch deityName {
        case "Surya": return "Sunday"
        case "Chandra": return "Monday"
        case "Mangala": return "Tuesday"
        case "Budha": return "Wednesday"
        case "Guru": return "Thursday"
        case "Shukra": return "Friday"
        case "Shani": return "Saturday"
        default: return deityName
        }
    }

    /// Converts WindowType to lookup key for PanchangDescriptions
    private static func timeWindowKey(_ type: TimeWindow.WindowType) -> String {
        switch type {
        case .brahmaMuhurta: return "brahmaMuhurta"
        case .abhijitMuhurta: return "abhijitMuhurta"
        case .rahuKalam: return "rahuKalam"
        case .gulikaKalam: return "gulikaKalam"
        case .yamaganda: return "yamaganda"
        }
    }

    private static var footer: String {
        "\n— Shared via Devi"
    }
}
