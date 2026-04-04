// MARK: - DeviTests/MantraRitualStateTests.swift

import XCTest
@testable import Devi

final class MantraRitualStateTests: XCTestCase {

    func testSameDayGuardPreventsDuplicateCompletion() {
        let state = MantraRitualState(
            cycleStartDate: "2026-04-01",
            completedDates: ["2026-04-01"],
            lastCompletionTimestamp: date("2026-04-01T12:00:00Z")
        )

        let result = MantraRitualPolicy.complete(
            state: state,
            on: "2026-04-01",
            completedAt: date("2026-04-01T12:10:00Z")
        )

        XCTAssertFalse(result.completedNewDay)
        XCTAssertEqual(result.state, state)
        XCTAssertEqual(result.snapshot.status, .completedToday)
    }

    func testGracefulPauseThenArchiveAfterSevenMissedDays() {
        let state = MantraRitualState(
            cycleStartDate: "2026-04-01",
            completedDates: ["2026-04-01", "2026-04-02", "2026-04-03", "2026-04-04"],
            lastCompletionTimestamp: date("2026-04-04T11:00:00Z")
        )

        let paused = MantraRitualPolicy.snapshot(state: state, currentDay: "2026-04-06")
        XCTAssertEqual(paused.status, .paused)
        XCTAssertEqual(paused.displayDay, 5)
        XCTAssertEqual(paused.missedDays, 1)
        XCTAssertEqual(paused.reminderTone, .waiting)

        let archived = MantraRitualPolicy.snapshot(state: state, currentDay: "2026-04-12")
        XCTAssertEqual(archived.status, .archived)
        XCTAssertEqual(archived.missedDays, 7)
        XCTAssertEqual(archived.reminderTone, .beginAgain)
    }

    func testFirstBloomElevatesSharePromptAtDaySeven() {
        let completed = Set((1...6).map { String(format: "2026-04-%02d", $0) })
        let state = MantraRitualState(
            cycleStartDate: "2026-04-01",
            completedDates: completed,
            lastCompletionTimestamp: date("2026-04-06T11:00:00Z")
        )

        let result = MantraRitualPolicy.complete(
            state: state,
            on: "2026-04-07",
            completedAt: date("2026-04-07T11:00:00Z")
        )

        XCTAssertTrue(result.completedNewDay)
        XCTAssertEqual(result.snapshot.completedCount, 7)
        XCTAssertEqual(result.snapshot.milestone, .firstBloom)
        XCTAssertEqual(result.snapshot.shareStyle, .invited)
        XCTAssertTrue(result.snapshot.shouldElevateSharePrompt)
        XCTAssertEqual(result.milestone, .firstBloom)
    }

    func testCeremonialCompletionStartsFreshCycleOnNextCompletion() {
        let completed = Set((1...21).map { String(format: "2026-04-%02d", $0) })
        let state = MantraRitualState(
            cycleStartDate: "2026-04-01",
            completedDates: completed,
            lastCompletionTimestamp: date("2026-04-21T11:00:00Z")
        )

        let beforeRestart = MantraRitualPolicy.snapshot(state: state, currentDay: "2026-04-22")
        XCTAssertEqual(beforeRestart.status, .ceremonialCompletion)
        XCTAssertTrue(beforeRestart.canCompleteToday)

        let restarted = MantraRitualPolicy.complete(
            state: state,
            on: "2026-04-22",
            completedAt: date("2026-04-22T11:00:00Z")
        )

        XCTAssertTrue(restarted.completedNewDay)
        XCTAssertTrue(restarted.startedFreshCycle)
        XCTAssertEqual(restarted.state.cycleStartDate, "2026-04-22")
        XCTAssertEqual(restarted.state.completedDates, Set(["2026-04-22"]))
        XCTAssertEqual(restarted.snapshot.completedCount, 1)
        XCTAssertEqual(restarted.snapshot.status, .completedToday)
    }

    private func date(_ isoString: String) -> Date {
        ISO8601DateFormatter().date(from: isoString) ?? Date.distantPast
    }
}
