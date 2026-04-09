// MARK: - Models/DaySnapshotStore.swift
// UserDefaults-backed store for DaySnapshot records. Mirrors the persistence
// pattern used by MantraRitualState / BirthData: Codable encode → UserDefaults → decode.
//
// Semantics:
//   - Upsert by `id` — writing the same (city, date) overwrites the existing entry.
//   - Bounded cap — keeps only the `maxSnapshots` most recent entries; oldest pruned
//     on each write. Prevents UserDefaults from ballooning over years of use.
//   - `all()` returns newest → oldest for direct use by the archive UI.
//   - Single key namespace (`daySnapshotStoreKey`) so migrations can be handled
//     by bumping the suffix (e.g. `.v2`) without orphaning reads.
//
// Not @MainActor — callers should hop to the main actor for UI updates themselves.

import Foundation

final class DaySnapshotStore {

    // MARK: - Storage

    /// UserDefaults key. Bump the suffix to force a fresh archive on schema changes.
    static let daySnapshotStoreKey = "daySnapshots.v1"

    /// Maximum number of snapshots retained. Older entries are pruned on every write.
    static let maxSnapshots = 90

    private let defaults: UserDefaults
    private let storageKey: String

    init(defaults: UserDefaults = .standard, storageKey: String = DaySnapshotStore.daySnapshotStoreKey) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    // MARK: - Public API

    /// Upsert a snapshot. If an entry with the same `id` exists it is replaced,
    /// then the collection is pruned to the most recent `maxSnapshots` days.
    func record(_ snapshot: DaySnapshot) {
        var current = loadAll()
        if let existingIndex = current.firstIndex(where: { $0.id == snapshot.id }) {
            current[existingIndex] = snapshot
        } else {
            current.append(snapshot)
        }

        // Sort newest → oldest by dateString (ISO "yyyy-MM-dd" is lexicographic-safe).
        current.sort { $0.dateString > $1.dateString }

        // Prune to the cap.
        if current.count > Self.maxSnapshots {
            current = Array(current.prefix(Self.maxSnapshots))
        }

        saveAll(current)
    }

    /// Look up a snapshot by its identifier (`"<cityName>-<dateString>"`).
    func snapshot(for id: String) -> DaySnapshot? {
        loadAll().first { $0.id == id }
    }

    /// Return all snapshots, newest → oldest.
    func all() -> [DaySnapshot] {
        loadAll().sorted { $0.dateString > $1.dateString }
    }

    /// Remove every snapshot. Intended for Settings → "Clear archive" actions.
    func clear() {
        defaults.removeObject(forKey: storageKey)
    }

    // MARK: - Private

    private func loadAll() -> [DaySnapshot] {
        guard let data = defaults.data(forKey: storageKey) else { return [] }
        do {
            return try JSONDecoder().decode([DaySnapshot].self, from: data)
        } catch {
            // Corrupt archive — drop it rather than crash the app.
            defaults.removeObject(forKey: storageKey)
            return []
        }
    }

    private func saveAll(_ snapshots: [DaySnapshot]) {
        do {
            let data = try JSONEncoder().encode(snapshots)
            defaults.set(data, forKey: storageKey)
        } catch {
            // Encoding failure is non-recoverable — drop the write silently.
            // Swift Codable failures on value types with primitive fields are
            // effectively impossible, so this is a defensive no-op.
        }
    }
}
