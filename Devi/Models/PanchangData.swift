// MARK: - Models/PanchangData.swift
// Core data structures for panchang information

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Tithi (Lunar Day)

enum Paksha: String, Codable {
    case shukla = "Shukla"  // Waxing moon (bright half)
    case krishna = "Krishna" // Waning moon (dark half)
}

struct Tithi: Codable {
    let number: Int          // 1-15 within each paksha
    let name: String         // "Pratipada", "Dwitiya", etc.
    let paksha: Paksha
    let endTime: Date        // When this tithi ends
    
    var displayName: String {
        "\(paksha.rawValue) \(name)"
    }
    
    var isFastingDay: Bool {
        // Ekadashi (11th), Pradosh (13th), Purnima (15th Shukla), Amavasya (15th Krishna)
        number == 11 || number == 13 || number == 15
    }
    
    var fastingType: String? {
        switch number {
        case 11: return "Ekadashi"
        case 13: return "Pradosh Vrat"
        case 15 where paksha == .shukla: return "Purnima"
        case 15 where paksha == .krishna: return "Amavasya"
        default: return nil
        }
    }
}

// MARK: - Nakshatra (Lunar Mansion)

struct Nakshatra: Codable {
    let number: Int          // 1-27
    let name: String         // "Ashwini", "Bharani", etc.
    let ruler: String        // Ruling planet
    let deity: String        // Presiding deity
    let endTime: Date
}

// MARK: - Yoga & Karana (minor panchang elements)

struct Yoga: Codable {
    let number: Int
    let name: String
    let endTime: Date
}

struct Karana: Codable {
    let number: Int
    let name: String
    let endTime: Date
}

// MARK: - Time Windows

struct TimeWindow: Codable, Identifiable {
    var id: String { type.rawValue }
    let type: WindowType
    let start: Date
    let end: Date
    
    enum WindowType: String, Codable {
        case abhijitMuhurta = "Abhijit Muhurta"
        case rahuKalam = "Rahu Kalam"
        case gulikaKalam = "Gulika Kalam"
        case yamaganda = "Yamaganda"
        case brahmaMuhurta = "Brahma Muhurta"
    }
    
    var isAuspicious: Bool {
        type == .abhijitMuhurta || type == .brahmaMuhurta
    }
    
    var isActive: Bool { isActive(at: Date()) }

    func isActive(at date: Date) -> Bool {
        date >= start && date <= end
    }
    
    var statusColor: WindowColor {
        switch type {
        case .abhijitMuhurta, .brahmaMuhurta: return .auspicious
        case .rahuKalam: return .inauspicious
        case .gulikaKalam, .yamaganda: return .caution
        }
    }
    
    enum WindowColor {
        case auspicious   // Green
        case inauspicious // Red
        case caution      // Yellow/amber
    }
}

// MARK: - Hora (Planetary Hour)

struct Hora: Codable, Identifiable {
    var id: String { "\(sequenceIndex)-\(planetName)" }

    let planetName: String       // "Sun", "Moon", "Mars", etc.
    let planetSanskrit: String   // "Surya", "Chandra", "Mangala", etc.
    let startTime: Date
    let endTime: Date
    let isDaytime: Bool
    let sequenceIndex: Int       // 0-23 (0-11 day, 12-23 night)

    var isActive: Bool { isActive(at: Date()) }

    func isActive(at date: Date) -> Bool {
        date >= startTime && date < endTime
    }
}

// MARK: - Choghadiya (Auspicious Time Period)

enum ChoghadiyaQuality: String, Codable {
    case auspicious = "Auspicious"
    case inauspicious = "Inauspicious"
    case neutral = "Neutral"
}

struct Choghadiya: Codable, Identifiable {
    var id: String { "\(sequenceIndex)-\(name)" }

    let name: String             // "Amrit", "Shubh", "Labh", etc.
    let quality: ChoghadiyaQuality
    let startTime: Date
    let endTime: Date
    let isDaytime: Bool
    let sequenceIndex: Int       // 0-15 (0-7 day, 8-15 night)

    var isActive: Bool { isActive(at: Date()) }

    func isActive(at date: Date) -> Bool {
        date >= startTime && date < endTime
    }
}

// MARK: - Daily Mantra (Weekday-Based)

struct DailyMantra: Codable, Identifiable {
    var id: String { deity }

    let deity: String            // "Surya", "Shiva", etc.
    let devanagari: String       // "ॐ सूर्याय नमः"
    let transliteration: String  // "Om Suryaya Namah"
    let meaning: String
    let significance: String
    let bestTimeToChant: String
    let repetitions: Int
    let weekday: Int             // Calendar weekday 1=Sun ... 7=Sat
}

// MARK: - Solar Data

struct SolarData: Codable {
    let sunrise: Date
    let sunset: Date
    let moonrise: Date?
    let moonset: Date?
    
    /// 0.0 at sunrise, 0.5 at solar noon, 1.0 at sunset
    var sunProgress: Double { sunProgress(at: Date()) }

    func sunProgress(at date: Date) -> Double {
        guard date >= sunrise && date <= sunset else {
            return date < sunrise ? 0.0 : 1.0
        }
        let total = sunset.timeIntervalSince(sunrise)
        let elapsed = date.timeIntervalSince(sunrise)
        return elapsed / total
    }

    var isDaytime: Bool { isDaytime(at: Date()) }

    func isDaytime(at date: Date) -> Bool {
        date >= sunrise && date <= sunset
    }
    
    /// Seconds until next sunrise or sunset
    var nextTransitionCountdown: TimeInterval {
        let now = Date()
        if isDaytime {
            return sunset.timeIntervalSince(now)
        } else {
            // Find next sunrise (could be today's if before sunrise, or tomorrow's)
            if now < sunrise {
                return sunrise.timeIntervalSince(now)
            } else {
                // After sunset — next sunrise is tomorrow, handled by data layer
                return 0 // Will be recalculated with tomorrow's data
            }
        }
    }
    
    var nextTransitionLabel: String {
        isDaytime ? "SUNSET IN" : "SUNRISE IN"
    }
}

// MARK: - Daily Panchang (the main model)

struct DailyPanchang: Codable, Identifiable {
    var id: String { dateString }

    let dateString: String   // "2026-03-20" ISO format
    let tithi: Tithi
    let nakshatra: Nakshatra
    let yoga: Yoga
    let karanas: [Karana]    // 2-3 karanas per day with transition times
    let solar: SolarData
    let timeWindows: [TimeWindow]
    let horas: [Hora]            // 24 entries: 12 day + 12 night
    let choghadiyas: [Choghadiya] // 16 entries: 8 day + 8 night
    let lunarMonth: String   // "Chaitra", "Vaishakha", etc.
    let festivals: [String]  // Any festivals on this day

    /// Backwards-compatible accessor for the primary (sunrise) karana.
    var karana: Karana { karanas.first! }
    
    /// The Hindu weekday lord
    var varaDeity: String {
        let calendar = Calendar.current
        guard let date = ISO8601DateFormatter().date(from: dateString + "T00:00:00Z") else { return "" }
        let weekday = calendar.component(.weekday, from: date)
        switch weekday {
        case 1: return "Surya (Sun)"
        case 2: return "Chandra (Moon)"
        case 3: return "Mangala (Mars)"
        case 4: return "Budha (Mercury)"
        case 5: return "Guru (Jupiter)"
        case 6: return "Shukra (Venus)"
        case 7: return "Shani (Saturn)"
        default: return ""
        }
    }
}

// MARK: - Navratri

struct NavratriDay: Identifiable {
    var id: Int { dayNumber }
    
    let dayNumber: Int       // 1-9
    let goddessName: String
    let goddessEpithet: String
    let colorName: String
    let colorHex: String
    let offering: String
    let mantra: String       // In Devanagari
    let mantraTranslit: String
    
    /// The 9 goddesses of Navratri — same cycle for both Chaitra and Sharad, every year.
    static let goddesses: [NavratriDay] = [
        NavratriDay(
            dayNumber: 1,
            goddessName: "Shailputri",
            goddessEpithet: "Daughter of the Mountain",
            colorName: "Yellow",
            colorHex: "#f0c040",
            offering: "Ghee",
            mantra: "ॐ देवी शैलपुत्र्यै नमः",
            mantraTranslit: "Om Devi Shailaputryai Namah"
        ),
        NavratriDay(
            dayNumber: 2,
            goddessName: "Brahmacharini",
            goddessEpithet: "The Ascetic Goddess",
            colorName: "Green",
            colorHex: "#2d8a4e",
            offering: "Sugar",
            mantra: "ॐ देवी ब्रह्मचारिण्यै नमः",
            mantraTranslit: "Om Devi Brahmacharinyai Namah"
        ),
        NavratriDay(
            dayNumber: 3,
            goddessName: "Chandraghanta",
            goddessEpithet: "The Moon-Bell Goddess",
            colorName: "Grey",
            colorHex: "#8a8a8a",
            offering: "Milk",
            mantra: "ॐ देवी चन्द्रघण्टायै नमः",
            mantraTranslit: "Om Devi Chandraghantayai Namah"
        ),
        NavratriDay(
            dayNumber: 4,
            goddessName: "Kushmanda",
            goddessEpithet: "Creator of the Universe",
            colorName: "Orange",
            colorHex: "#d4742a",
            offering: "Malpua",
            mantra: "ॐ देवी कूष्माण्डायै नमः",
            mantraTranslit: "Om Devi Kushmandayai Namah"
        ),
        NavratriDay(
            dayNumber: 5,
            goddessName: "Skandamata",
            goddessEpithet: "Mother of Skanda",
            colorName: "White",
            colorHex: "#f0f0f0",
            offering: "Banana",
            mantra: "ॐ देवी स्कन्दमातायै नमः",
            mantraTranslit: "Om Devi Skandamatayai Namah"
        ),
        NavratriDay(
            dayNumber: 6,
            goddessName: "Katyayani",
            goddessEpithet: "The Warrior Goddess",
            colorName: "Red",
            colorHex: "#c42a2a",
            offering: "Honey",
            mantra: "ॐ देवी कात्यायन्यै नमः",
            mantraTranslit: "Om Devi Katyayanyai Namah"
        ),
        NavratriDay(
            dayNumber: 7,
            goddessName: "Kalaratri",
            goddessEpithet: "Destroyer of Darkness",
            colorName: "Royal Blue",
            colorHex: "#1a3a8a",
            offering: "Jaggery",
            mantra: "ॐ देवी कालरात्र्यै नमः",
            mantraTranslit: "Om Devi Kalaratryai Namah"
        ),
        NavratriDay(
            dayNumber: 8,
            goddessName: "Mahagauri",
            goddessEpithet: "The Brilliantly White",
            colorName: "Pink",
            colorHex: "#d42a6b",
            offering: "Coconut",
            mantra: "ॐ देवी महागौर्यै नमः",
            mantraTranslit: "Om Devi Mahagauryai Namah"
        ),
        NavratriDay(
            dayNumber: 9,
            goddessName: "Siddhidatri",
            goddessEpithet: "Bestower of Supernatural Powers",
            colorName: "Purple",
            colorHex: "#6b2a8a",
            offering: "Sesame Seeds",
            mantra: "ॐ देवी सिद्धिदात्र्यै नमः",
            mantraTranslit: "Om Devi Siddhidatryai Namah"
        )
    ]
}

// MARK: - Navratri Period

struct NavratriPeriod {
    let name: String          // "Chaitra Navratri 2026"
    let startDate: String     // ISO date
    let endDate: String       // ISO date
    
    func dayNumber(for dateString: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let start = formatter.date(from: startDate),
              let current = formatter.date(from: dateString) else { return nil }
        let days = Calendar.current.dateComponents([.day], from: start, to: current).day ?? -1
        guard days >= 0 && days < 9 else { return nil }
        return days + 1
    }
    
    // NavratriPeriod instances are now computed dynamically by FestivalEngine.navratriPeriods(forYear:)
}

// MARK: - Eclipse Data

enum EclipseBody: String, Codable {
    case lunar = "Lunar"
    case solar = "Solar"

    var sanskritName: String {
        switch self {
        case .lunar: return "Chandra Grahan"
        case .solar: return "Surya Grahan"
        }
    }

    var devanagari: String {
        switch self {
        case .lunar: return "चन्द्र ग्रहण"
        case .solar: return "सूर्य ग्रहण"
        }
    }
}

enum EclipseType: String, Codable {
    case total = "Total"
    case partial = "Partial"
    case annular = "Annular"
    case penumbral = "Penumbral"
}

struct LunarEclipseContactTimes: Codable {
    let penumbralBegin: Date?
    let partialBegin: Date?
    let totalBegin: Date?
    let maximum: Date
    let totalEnd: Date?
    let partialEnd: Date?
    let penumbralEnd: Date?

    /// All non-nil contact times in chronological order with labels
    var timeline: [(label: String, time: Date)] {
        var pairs: [(String, Date)] = []
        if let t = penumbralBegin { pairs.append(("Penumbral Begins", t)) }
        if let t = partialBegin { pairs.append(("Partial Begins", t)) }
        if let t = totalBegin { pairs.append(("Total Begins", t)) }
        pairs.append(("Maximum", maximum))
        if let t = totalEnd { pairs.append(("Total Ends", t)) }
        if let t = partialEnd { pairs.append(("Partial Ends", t)) }
        if let t = penumbralEnd { pairs.append(("Penumbral Ends", t)) }
        return pairs
    }
}

struct SolarEclipseContactTimes: Codable {
    let firstContact: Date?      // Partial begins
    let secondContact: Date?     // Total/annular begins
    let maximum: Date
    let thirdContact: Date?      // Total/annular ends
    let fourthContact: Date?     // Partial ends

    var timeline: [(label: String, time: Date)] {
        var pairs: [(String, Date)] = []
        if let t = firstContact { pairs.append(("Partial Begins", t)) }
        if let t = secondContact { pairs.append(("Totality Begins", t)) }
        pairs.append(("Maximum", maximum))
        if let t = thirdContact { pairs.append(("Totality Ends", t)) }
        if let t = fourthContact { pairs.append(("Partial Ends", t)) }
        return pairs
    }
}

struct EclipseEvent: Identifiable, Codable {
    var id: String { "\(body.rawValue)-\(dateString)" }

    let body: EclipseBody
    let type: EclipseType
    let dateString: String                       // "2026-03-03" ISO format
    let maxEclipseTime: Date
    let magnitude: Double                        // 0.0 - 1.0+ (> 1.0 for total)
    let lunarContactTimes: LunarEclipseContactTimes?
    let solarContactTimes: SolarEclipseContactTimes?
    let moonBelowHorizon: Bool                   // True if eclipse not visible (moon below horizon)
    let mythologyNote: String?

    var displayName: String {
        "\(type.rawValue) \(body.rawValue) Eclipse"
    }

    /// Contact times timeline, regardless of body type
    var contactTimeline: [(label: String, time: Date)] {
        if let lunar = lunarContactTimes {
            return lunar.timeline
        } else if let solar = solarContactTimes {
            return solar.timeline
        }
        return [("Maximum", maxEclipseTime)]
    }

    /// Days from a reference date to this eclipse
    func daysFrom(_ dateString: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let from = formatter.date(from: dateString),
              let to = formatter.date(from: self.dateString) else { return 0 }
        return Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
    }

    /// Human-readable proximity label
    func proximityLabel(from dateString: String) -> String {
        let days = daysFrom(dateString)
        switch days {
        case 0: return "TODAY"
        case 1: return "TOMORROW"
        case 2...30:
            let parser = DateFormatter()
            parser.dateFormat = "yyyy-MM-dd"
            guard let date = parser.date(from: self.dateString) else { return "" }
            let display = DateFormatter()
            display.dateFormat = "MMM d"
            return display.string(from: date).uppercased()
        default: return ""
        }
    }
}

// MARK: - Upcoming Event

struct UpcomingEvent: Identifiable {
    var id: String { name + dateString }
    let name: String
    let dateString: String
    let daysAway: Int
    let type: EventType

    enum EventType {
        case festival
        case fasting
        case eclipse
    }

    /// Converts dateString ("yyyy-MM-dd") → display label.
    /// Returns "Tomorrow" for daysAway == 1, otherwise "MMM d" (e.g., "Mar 20").
    var formattedDate: String {
        if daysAway == 1 { return "Tomorrow" }
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dateString) else { return dateString }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return display.string(from: date)
    }
}

// MARK: - User Location

struct UserCity: Codable, Identifiable, Hashable {
    var id: String { "\(name)-\(country)" }
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    let timezoneIdentifier: String
    
    static let popularCities: [UserCity] = [
        // US cities
        UserCity(name: "New York", country: "US", latitude: 40.7128, longitude: -74.0060, timezoneIdentifier: "America/New_York"),
        UserCity(name: "Los Angeles", country: "US", latitude: 34.0522, longitude: -118.2437, timezoneIdentifier: "America/Los_Angeles"),
        UserCity(name: "Chicago", country: "US", latitude: 41.8781, longitude: -87.6298, timezoneIdentifier: "America/Chicago"),
        UserCity(name: "Houston", country: "US", latitude: 29.7604, longitude: -95.3698, timezoneIdentifier: "America/Chicago"),
        UserCity(name: "San Francisco", country: "US", latitude: 37.7749, longitude: -122.4194, timezoneIdentifier: "America/Los_Angeles"),
        UserCity(name: "Dallas", country: "US", latitude: 32.7767, longitude: -96.7970, timezoneIdentifier: "America/Chicago"),
        UserCity(name: "Edison", country: "US", latitude: 40.5187, longitude: -74.4121, timezoneIdentifier: "America/New_York"),
        // India cities
        UserCity(name: "Mumbai", country: "IN", latitude: 19.0760, longitude: 72.8777, timezoneIdentifier: "Asia/Kolkata"),
        UserCity(name: "Delhi", country: "IN", latitude: 28.7041, longitude: 77.1025, timezoneIdentifier: "Asia/Kolkata"),
        UserCity(name: "Bangalore", country: "IN", latitude: 12.9716, longitude: 77.5946, timezoneIdentifier: "Asia/Kolkata"),
        UserCity(name: "Chennai", country: "IN", latitude: 13.0827, longitude: 80.2707, timezoneIdentifier: "Asia/Kolkata"),
        UserCity(name: "Hyderabad", country: "IN", latitude: 17.3850, longitude: 78.4867, timezoneIdentifier: "Asia/Kolkata"),
        UserCity(name: "Kolkata", country: "IN", latitude: 22.5726, longitude: 88.3639, timezoneIdentifier: "Asia/Kolkata"),
        UserCity(name: "Kochi", country: "IN", latitude: 9.9312, longitude: 76.2673, timezoneIdentifier: "Asia/Kolkata"),
        UserCity(name: "Thiruvananthapuram", country: "IN", latitude: 8.5241, longitude: 76.9366, timezoneIdentifier: "Asia/Kolkata"),
        UserCity(name: "Kozhikode", country: "IN", latitude: 11.2588, longitude: 75.7804, timezoneIdentifier: "Asia/Kolkata"),
        UserCity(name: "Thrissur", country: "IN", latitude: 10.5276, longitude: 76.2144, timezoneIdentifier: "Asia/Kolkata"),
        // UK
        UserCity(name: "London", country: "UK", latitude: 51.5074, longitude: -0.1278, timezoneIdentifier: "Europe/London"),
        // Canada
        UserCity(name: "Toronto", country: "CA", latitude: 43.6532, longitude: -79.3832, timezoneIdentifier: "America/Toronto"),
        // Singapore
        UserCity(name: "Singapore", country: "SG", latitude: 1.3521, longitude: 103.8198, timezoneIdentifier: "Asia/Singapore"),
    ]
    
    /// Find nearest city to a coordinate
    static func nearest(to location: CLLocation) -> UserCity {
        popularCities.min(by: { cityA, cityB in
            let locA = CLLocation(latitude: cityA.latitude, longitude: cityA.longitude)
            let locB = CLLocation(latitude: cityB.latitude, longitude: cityB.longitude)
            return location.distance(from: locA) < location.distance(from: locB)
        }) ?? popularCities[0]
    }
}

// MARK: - Graha (Vedic Planets)

enum Graha: String, CaseIterable, Identifiable {
    case sun = "Sun"
    case moon = "Moon"
    case mars = "Mars"
    case mercury = "Mercury"
    case jupiter = "Jupiter"
    case venus = "Venus"
    case saturn = "Saturn"
    case rahu = "Rahu"
    case ketu = "Ketu"

    var id: String { rawValue }

    var sanskritName: String {
        switch self {
        case .sun: return "Surya"
        case .moon: return "Chandra"
        case .mars: return "Mangala"
        case .mercury: return "Budha"
        case .jupiter: return "Guru"
        case .venus: return "Shukra"
        case .saturn: return "Shani"
        case .rahu: return "Rahu"
        case .ketu: return "Ketu"
        }
    }

    /// Shadow planets (chaya graha) have no physical body — computed from lunar nodes.
    var isShadow: Bool {
        self == .rahu || self == .ketu
    }

    /// Swiss Ephemeris planet ID for swe_calc_ut. Ketu has no SE body — derived from Rahu.
    /// Returns nil for Ketu; callers must compute Ketu as (Rahu + 180) mod 360.
    var planetId: Int32? {
        switch self {
        case .sun: return 0       // SE_SUN
        case .moon: return 1      // SE_MOON
        case .mercury: return 2   // SE_MERCURY
        case .venus: return 3     // SE_VENUS
        case .mars: return 4      // SE_MARS
        case .jupiter: return 5   // SE_JUPITER
        case .saturn: return 6    // SE_SATURN
        case .rahu: return 11     // SE_TRUE_NODE
        case .ketu: return nil    // Derived: (rahu + 180) mod 360
        }
    }
}

// MARK: - Graha Extensions

extension Graha {
    /// Canonical planet color for all UI surfaces.
    var color: Color {
        switch self {
        case .sun:     return Color(hex: "D4A040")
        case .moon:    return Color(hex: "B8C4D8")
        case .mars:    return Color(hex: "C45050")
        case .mercury: return Color(hex: "4AAD6E")
        case .jupiter: return Color(hex: "C9A96E")
        case .venus:   return Color(hex: "D47AAD")
        case .saturn:  return Color(hex: "7B8EC4")
        case .rahu:    return Color(hex: "5A6A8A")
        case .ketu:    return Color(hex: "8A5A5A")
        }
    }

    /// The 3 nakshatras ruled by this graha (name, 1-based index).
    /// Each planet rules exactly 3 nakshatras spaced 9 apart in the 27-cycle (Vimshottari Dasha lords).
    var ruledNakshatras: [(name: String, index: Int)] {
        switch self {
        case .ketu:    return [("Ashwini", 1), ("Magha", 10), ("Mula", 19)]
        case .venus:   return [("Bharani", 2), ("Purva Phalguni", 11), ("Purva Ashadha", 20)]
        case .sun:     return [("Krittika", 3), ("Uttara Phalguni", 12), ("Uttara Ashadha", 21)]
        case .moon:    return [("Rohini", 4), ("Hasta", 13), ("Shravana", 22)]
        case .mars:    return [("Mrigashira", 5), ("Chitra", 14), ("Dhanishta", 23)]
        case .rahu:    return [("Ardra", 6), ("Swati", 15), ("Shatabhisha", 24)]
        case .jupiter: return [("Punarvasu", 7), ("Vishakha", 16), ("Purva Bhadrapada", 25)]
        case .saturn:  return [("Pushya", 8), ("Anuradha", 17), ("Uttara Bhadrapada", 26)]
        case .mercury: return [("Ashlesha", 9), ("Jyeshtha", 18), ("Revati", 27)]
        }
    }
}

/// Snapshot of all 9 graha positions at a given moment.
struct GrahaSnapshot {
    struct Position {
        let graha: Graha
        let longitude: Double  // Sidereal longitude in degrees [0, 360)
    }

    let positions: [Position]  // Always 9 entries, one per Graha
    let computedAt: Date

    /// Find the position for a specific graha.
    func longitude(of graha: Graha) -> Double {
        positions.first(where: { $0.graha == graha })?.longitude ?? 0
    }
}

// MARK: - Notification Preferences

struct NotificationPreferences: Codable {
    var brahmaMuhurta: Bool = false
    var sunrise: Bool = true
    var abhijitMuhurta: Bool = false
    var rahuKalamWarning: Bool = true
    var sunset: Bool = true
    var navratriMorning: Bool = true    // Auto-enabled during Navratri
    var minutesBefore: Int = 10         // How early to fire the notification
}

// MARK: - GrahaSnapshot Helpers

extension GrahaSnapshot {
    /// Zero-based nakshatra index (0-26) for a given sidereal longitude.
    /// Distinct from `PanchangCalculator.nakshatraIndex(at:)` which is 1-based (1-27).
    static func nakshatraIndex(forLongitude lon: Double) -> Int {
        max(0, min(Int(lon / (360.0 / 27.0)), 26))
    }
}
