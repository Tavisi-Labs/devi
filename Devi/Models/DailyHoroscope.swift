// MARK: - Models/DailyHoroscope.swift
// Daily horoscope reading data model

import Foundation

struct DailyHoroscope {
    let date: Date
    let themeStatement: String        // Bold, large type (1-2 lines)
    let supportingText: String        // 2-3 sentence paragraph
    let doList: [String]              // 3 items
    let dontList: [String]            // 3 items
    let categories: [CategoryReading] // love, work, spirituality, health
    let mantra: MantraReading         // Sanskrit mantra + translation
    let auspiciousColor: AuspiciousColor // name + hex
    let transitContext: TransitContext  // For "Why?" sheet
}

enum HoroscopeCategory: String, CaseIterable {
    case love, work, spirituality, health

    var displayName: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .love: return "heart.fill"
        case .work: return "briefcase.fill"
        case .spirituality: return "sparkles"
        case .health: return "leaf.fill"
        }
    }
}

struct CategoryReading {
    let category: HoroscopeCategory
    let summary: String              // 2-3 sentences
    let intensity: Int               // 1-5 scale
}

struct MantraReading {
    let sanskrit: String             // e.g. "Om Somaya Namaha"
    let translation: String          // e.g. "Salutations to the Moon"
    let deity: String                // e.g. "Chandra"
}

struct AuspiciousColor {
    let name: String                 // e.g. "Silver"
    let hex: String                  // e.g. "#C0C0C0"
}

struct TransitContext {
    let moonHouse: Int               // 1-12 from birth Moon
    let moonHouseVedicName: String   // "Kalatra" for 7th
    let moonNakshatra: String        // Current nakshatra name
    let significantAspects: [String] // "Jupiter transits your 7th house"
    let birthRashi: Rashi
    let birthTimeKnown: Bool

    static let houseVedicNames: [Int: String] = [
        1: "Janma", 2: "Dhana", 3: "Sahaja", 4: "Sukha",
        5: "Putra", 6: "Ripu", 7: "Kalatra", 8: "Randhra",
        9: "Dharma", 10: "Karma", 11: "Labha", 12: "Vyaya"
    ]

    static let houseThemes: [Int: String] = [
        1: "Self-focus, new beginnings",
        2: "Wealth, family matters",
        3: "Courage, communication",
        4: "Comfort, home, mother",
        5: "Creativity, romance, children",
        6: "Challenges, service, health",
        7: "Partnerships, relationships",
        8: "Transformation, hidden matters",
        9: "Fortune, higher learning",
        10: "Career, public life, duty",
        11: "Gains, friendships, wishes",
        12: "Release, expenses, solitude"
    ]
}
