// MARK: - Models/DaySnapshot.swift
// Persistent daily snapshot — captures the horoscope, panchang fingerprint,
// cosmic signature, and ritual completion state for a given (city, date) pair.
//
// Snapshots are recorded once per day when the user opens the app, then browsed
// from the "Your Day Archive" sheet. Storage is UserDefaults-backed through
// `DaySnapshotStore`, which caps the archive at the 90 most recent days.

import Foundation

struct DaySnapshot: Codable, Identifiable, Equatable {

    // MARK: - Identity

    /// Day key in "yyyy-MM-dd" form (local timezone of the city when recorded).
    let dateString: String

    /// City the snapshot belongs to — the archive is scoped per city.
    let cityName: String

    // MARK: - Horoscope (optional — only present if birth data was set that day)

    let themeStatement: String?
    let supportingText: String?

    /// Category summaries keyed by `HoroscopeCategory.rawValue` so the model
    /// stays Codable without forcing `HoroscopeCategory` itself to adopt Codable.
    let categorySummaries: [String: String]

    let mantraSanskrit: String?
    let mantraTranslation: String?

    // MARK: - Panchang fingerprint (always populated)

    let tithiDisplayName: String
    let nakshatraName: String
    let yogaName: String
    let festivals: [String]

    // MARK: - Cross-feature signals

    /// Cosmic signature prose (from CosmicSignatureService) if available at save time.
    let cosmicSignature: String?

    /// Whether the Living Mandala ritual was completed on this day.
    let ritualCompleted: Bool

    // MARK: - Identifiable

    /// Stable identifier across record/upsert calls — `city-date`.
    var id: String { "\(cityName)-\(dateString)" }
}
