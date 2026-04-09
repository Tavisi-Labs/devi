// MARK: - DeviTests/DaySnapshotStoreTests.swift
// Tests for DaySnapshotStore — the persistent "Your Day Archive" backing store.
// Uses an isolated UserDefaults suite per test so real app state is never touched.

import XCTest
@testable import Devi

final class DaySnapshotStoreTests: XCTestCase {

    // Each test gets its own suite to guarantee isolation.
    private var suite: UserDefaults!
    private var suiteName: String!
    private let key = "daySnapshots.test"

    override func setUp() {
        super.setUp()
        suiteName = "com.devi.tests.\(UUID().uuidString)"
        suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        suite.removePersistentDomain(forName: suiteName)
        suite = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeStore() -> DaySnapshotStore {
        DaySnapshotStore(defaults: suite, storageKey: key)
    }

    private func makeSnapshot(
        dateString: String,
        city: String = "Delhi",
        theme: String? = nil
    ) -> DaySnapshot {
        DaySnapshot(
            dateString: dateString,
            cityName: city,
            themeStatement: theme,
            supportingText: nil,
            categorySummaries: [:],
            mantraSanskrit: nil,
            mantraTranslation: nil,
            tithiDisplayName: "Shukla Pratipada",
            nakshatraName: "Ashwini",
            yogaName: "Vishkambha",
            festivals: [],
            cosmicSignature: nil,
            ritualCompleted: false
        )
    }

    // MARK: - Basic Round-Trip

    func testRecordAndRetrieveSingleSnapshot() {
        let store = makeStore()
        let snapshot = makeSnapshot(dateString: "2026-04-07")

        store.record(snapshot)

        let fetched = store.snapshot(for: snapshot.id)
        XCTAssertEqual(fetched, snapshot)
    }

    func testAllReturnsEmptyArrayInitially() {
        let store = makeStore()
        XCTAssertTrue(store.all().isEmpty)
    }

    // MARK: - Upsert Semantics

    func testUpsertByIDOverwritesExistingEntry() {
        let store = makeStore()
        let first = makeSnapshot(dateString: "2026-04-07", theme: "Original")
        let second = makeSnapshot(dateString: "2026-04-07", theme: "Updated")

        store.record(first)
        store.record(second)

        let all = store.all()
        XCTAssertEqual(all.count, 1, "Same (city, date) must upsert, not duplicate")
        XCTAssertEqual(all.first?.themeStatement, "Updated")
    }

    func testDifferentCitySameDateAreSeparateEntries() {
        let store = makeStore()
        store.record(makeSnapshot(dateString: "2026-04-07", city: "Delhi"))
        store.record(makeSnapshot(dateString: "2026-04-07", city: "Mumbai"))

        XCTAssertEqual(store.all().count, 2)
    }

    // MARK: - Ordering

    func testAllReturnsNewestToOldest() {
        let store = makeStore()
        store.record(makeSnapshot(dateString: "2026-04-05"))
        store.record(makeSnapshot(dateString: "2026-04-07"))
        store.record(makeSnapshot(dateString: "2026-04-06"))

        let dates = store.all().map(\.dateString)
        XCTAssertEqual(dates, ["2026-04-07", "2026-04-06", "2026-04-05"])
    }

    // MARK: - Pruning at Cap

    func testPruneToCapKeepsNewestNinety() {
        let store = makeStore()

        // Write 100 synthetic days — "2026-01-01" through "2026-04-10"
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!

        for offset in 0..<100 {
            let date = calendar.date(byAdding: .day, value: offset, to: start)!
            let dateString = formatter.string(from: date)
            store.record(makeSnapshot(dateString: dateString))
        }

        let all = store.all()
        XCTAssertEqual(all.count, DaySnapshotStore.maxSnapshots, "Expected cap of \(DaySnapshotStore.maxSnapshots)")

        // Newest retained should be offset 99 — 100th day from Jan 1
        let newestDate = calendar.date(byAdding: .day, value: 99, to: start)!
        XCTAssertEqual(all.first?.dateString, formatter.string(from: newestDate))

        // Oldest retained is (100 - 90) = offset 10
        let oldestDate = calendar.date(byAdding: .day, value: 10, to: start)!
        XCTAssertEqual(all.last?.dateString, formatter.string(from: oldestDate))
    }

    // MARK: - Clear

    func testClearRemovesAllEntries() {
        let store = makeStore()
        store.record(makeSnapshot(dateString: "2026-04-07"))
        store.record(makeSnapshot(dateString: "2026-04-06"))

        store.clear()

        XCTAssertTrue(store.all().isEmpty)
    }

    // MARK: - Corrupt Data Recovery

    func testCorruptDataDoesNotCrash() {
        // Write garbage bytes to the storage key.
        suite.set(Data([0xFF, 0xFE, 0xFD]), forKey: key)

        let store = makeStore()

        // loadAll() should silently recover to an empty array.
        XCTAssertTrue(store.all().isEmpty)

        // The store should still be writable after corruption.
        store.record(makeSnapshot(dateString: "2026-04-07"))
        XCTAssertEqual(store.all().count, 1)
    }
}
