// MARK: - Models/HoroscopeContentLibraryData.swift
// Codable wire format for the bundled horoscope content library JSON.
//
// The JSON is generated offline by scripts/generate_horoscope_content.py and
// bundled as `Devi/Resources/horoscope_library.json`. At runtime,
// `HoroscopeContentLibrary` lazy-loads this file once and exposes the content
// through its legacy public API (themes, categoryReadings, etc.).
//
// Schema versioning: `version` is bumped whenever the on-disk shape changes.
// Current version: 1.

import Foundation

// MARK: - Root Horoscope Library

/// Top-level horoscope library, matching `horoscope_library.json`.
struct HoroscopeLibraryData: Codable {
    let version: Int
    let generatedAt: String
    let model: String
    let houseThemes: [String: [HouseThemeEntry]]          // "1".."12" → [themes]
    let categoryReadings: [String: CategoryReadingBucket] // "1".."12" → categories

    // MARK: - Indexed accessors

    /// Translate the JSON dictionary into the `[[HouseTheme]]` shape the engine expects.
    /// Index 0 == House 1, Index 11 == House 12. Houses missing from the JSON fall
    /// back to an empty variant list (the engine will substitute neutral text).
    var themesIndexed: [[HoroscopeContentLibrary.HouseTheme]] {
        (1...12).map { houseNumber in
            let key = String(houseNumber)
            let entries = houseThemes[key] ?? []
            return entries.map { $0.asHouseTheme }
        }
    }

    /// Category readings as a nested dictionary keyed by house number (Int) and
    /// category (`HoroscopeCategory`). Each slot holds an ARRAY of variants, which
    /// the engine samples via the enriched variant seed.
    var categoriesIndexed: [Int: [HoroscopeCategory: [CategoryReadingEntry]]] {
        var result: [Int: [HoroscopeCategory: [CategoryReadingEntry]]] = [:]
        for (houseKey, bucket) in categoryReadings {
            guard let houseNumber = Int(houseKey) else { continue }
            var byCategory: [HoroscopeCategory: [CategoryReadingEntry]] = [:]
            for category in HoroscopeCategory.allCases {
                byCategory[category] = bucket.entries(for: category)
            }
            result[houseNumber] = byCategory
        }
        return result
    }
}

// MARK: - House Theme

/// One themed variant for a given Moon house — mirrors HouseTheme but is Codable.
struct HouseThemeEntry: Codable {
    let themeStatement: String
    let supportingText: String
    let doList: [String]
    let dontList: [String]

    var asHouseTheme: HoroscopeContentLibrary.HouseTheme {
        HoroscopeContentLibrary.HouseTheme(
            themeStatement: themeStatement,
            supportingText: supportingText,
            doList: doList,
            dontList: dontList
        )
    }
}

// MARK: - Category Reading

/// One entry in the category readings list — a single (summary, intensity) pair.
/// Codable-friendly replacement for the old tuple shape.
struct CategoryReadingEntry: Codable {
    let summary: String
    let intensity: Int
}

/// Bucket of category readings for a single house, keyed by category raw value.
/// The JSON uses lowercase category names ("love", "work", "spirituality", "health")
/// matching `HoroscopeCategory.rawValue`.
struct CategoryReadingBucket: Codable {
    let love: [CategoryReadingEntry]?
    let work: [CategoryReadingEntry]?
    let spirituality: [CategoryReadingEntry]?
    let health: [CategoryReadingEntry]?

    func entries(for category: HoroscopeCategory) -> [CategoryReadingEntry] {
        switch category {
        case .love:         return love ?? []
        case .work:         return work ?? []
        case .spirituality: return spirituality ?? []
        case .health:       return health ?? []
        }
    }
}

// MARK: - Cosmic Signature Library

/// Top-level cosmic signature library, matching `cosmic_signature_library.json`.
/// Each pool maps a Vedic name (e.g. "Shukla Pratipada") to a list of sentence
/// fragments. The runtime composes a signature by picking one fragment from
/// each pool using a date-derived hash.
struct CosmicSignatureLibraryData: Codable {
    let version: Int
    let generatedAt: String
    let model: String
    let tithiFragments: [String: [String]]     // e.g. "Shukla Pratipada" → fragments
    let nakshatraFragments: [String: [String]] // e.g. "Ashwini" → fragments
    let yogaFragments: [String: [String]]      // e.g. "Vishkambha" → fragments
}
