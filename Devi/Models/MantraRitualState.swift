// MARK: - Models/MantraRitualState.swift
// Pure ritual state + policy for the Living Mandala cycle.

import Foundation

struct MantraRitualState: Codable, Equatable {
    static let cycleLength = 21
    static let archiveThresholdDays = 7

    var cycleStartDate: String?
    var completedDates: Set<String> = []
    var lastCompletionTimestamp: Date?
    var shownShareMilestones: Set<Int> = []

    static let empty = MantraRitualState()
}

enum MantraRitualStatus: String, Equatable {
    case seed
    case active
    case paused
    case completedToday
    case ceremonialCompletion
    case archived
}

enum MantraRitualMilestone: Int, Codable, CaseIterable, Sendable {
    case firstBloom = 7
    case ceremonialCompletion = 21

    var title: String {
        switch self {
        case .firstBloom:
            return "First bloom"
        case .ceremonialCompletion:
            return "Ceremonial completion"
        }
    }
}

enum MantraRitualShareStyle: Equatable {
    case subdued
    case invited
}

enum MantraRitualReminderTone: String, Codable, Equatable, Sendable {
    case open
    case waiting
    case beginAgain
}

struct MantraRitualSnapshot: Equatable {
    let status: MantraRitualStatus
    let completedCount: Int
    let displayDay: Int?
    let completedToday: Bool
    let missedDays: Int
    let milestone: MantraRitualMilestone?
    let shareStyle: MantraRitualShareStyle
    let shouldElevateSharePrompt: Bool
    let reminderTone: MantraRitualReminderTone?
    let canCompleteToday: Bool
    let canShareManually: Bool
    let isCycleComplete: Bool
}

struct MantraRitualCompletionResult: Equatable {
    let state: MantraRitualState
    let snapshot: MantraRitualSnapshot
    let completedNewDay: Bool
    let startedFreshCycle: Bool
    let milestone: MantraRitualMilestone?
}

extension MantraRitualSnapshot {
    var dayLabel: String? {
        guard let displayDay else { return nil }
        return "Day \(displayDay)"
    }

    var continuityText: String {
        switch status {
        case .seed:
            return "Begin today's practice"
        case .active:
            return "Practice is alive"
        case .paused:
            return "Waiting for today's chant"
        case .completedToday:
            return "Today's practice is complete"
        case .ceremonialCompletion:
            return "Ceremonial completion"
        case .archived:
            return "Begin again"
        }
    }

    var actionTitle: String {
        switch status {
        case .completedToday:
            return "Today's practice is complete"
        case .archived, .ceremonialCompletion:
            return "Hold to begin again"
        case .seed, .active, .paused:
            return "Hold to seal today's practice"
        }
    }

    var accessibilitySummary: String {
        let dayText = dayLabel ?? "Seed"
        switch status {
        case .paused:
            return "Living mandala, \(dayText) of \(MantraRitualState.cycleLength), waiting for today's chant"
        case .completedToday:
            return "Living mandala, \(dayText) of \(MantraRitualState.cycleLength), today's practice is complete"
        case .ceremonialCompletion:
            return "Living mandala, ceremonial completion, ready to begin again"
        case .archived:
            return "Living mandala, seed state, ready to begin again"
        case .seed, .active:
            return "Living mandala, \(dayText) of \(MantraRitualState.cycleLength), ready for today's practice"
        }
    }
}

enum MantraRitualPolicy {
    static func snapshot(state: MantraRitualState, currentDay: String) -> MantraRitualSnapshot {
        let completedToday = state.completedDates.contains(currentDay)
        let completedCount = min(state.completedDates.count, MantraRitualState.cycleLength)
        let missedDays = missedDaysSinceLastCompletion(state: state, currentDay: currentDay)
        let isArchived = completedCount > 0 && missedDays >= MantraRitualState.archiveThresholdDays
        let isCycleComplete = completedCount >= MantraRitualState.cycleLength

        let status: MantraRitualStatus = {
            if completedCount == 0 {
                return .seed
            }
            if isArchived {
                return .archived
            }
            if completedToday {
                return .completedToday
            }
            if isCycleComplete {
                return .ceremonialCompletion
            }
            if missedDays > 0 {
                return .paused
            }
            return .active
        }()

        let milestone: MantraRitualMilestone? = {
            if completedCount >= MantraRitualMilestone.ceremonialCompletion.rawValue {
                return .ceremonialCompletion
            }
            if completedCount == MantraRitualMilestone.firstBloom.rawValue {
                return .firstBloom
            }
            return nil
        }()

        let shareStyle: MantraRitualShareStyle = {
            switch completedCount {
            case MantraRitualMilestone.firstBloom.rawValue, MantraRitualMilestone.ceremonialCompletion.rawValue...:
                return .invited
            default:
                return .subdued
            }
        }()

        let shouldElevateSharePrompt =
            completedToday &&
            state.shownShareMilestones.contains(milestone?.rawValue ?? -1) == false &&
            (milestone == .firstBloom || milestone == .ceremonialCompletion)

        let reminderTone: MantraRitualReminderTone? = {
            if completedToday {
                return nil
            }
            switch status {
            case .archived:
                return .beginAgain
            case .paused:
                return .waiting
            case .seed, .active, .ceremonialCompletion:
                return .open
            case .completedToday:
                return nil
            }
        }()

        let displayDay: Int? = {
            guard completedCount > 0 else { return nil }
            if completedToday || isCycleComplete {
                return min(completedCount, MantraRitualState.cycleLength)
            }
            return min(completedCount + 1, MantraRitualState.cycleLength)
        }()

        return MantraRitualSnapshot(
            status: status,
            completedCount: completedCount,
            displayDay: displayDay,
            completedToday: completedToday,
            missedDays: missedDays,
            milestone: milestone,
            shareStyle: shareStyle,
            shouldElevateSharePrompt: shouldElevateSharePrompt,
            reminderTone: reminderTone,
            canCompleteToday: !completedToday,
            canShareManually: true,
            isCycleComplete: isCycleComplete
        )
    }

    static func complete(state: MantraRitualState, on day: String, completedAt: Date) -> MantraRitualCompletionResult {
        let currentSnapshot = snapshot(state: state, currentDay: day)
        guard currentSnapshot.canCompleteToday else {
            return MantraRitualCompletionResult(
                state: state,
                snapshot: currentSnapshot,
                completedNewDay: false,
                startedFreshCycle: false,
                milestone: nil
            )
        }

        var nextState = state
        var startedFreshCycle = false

        if currentSnapshot.status == .archived || currentSnapshot.isCycleComplete {
            nextState = .empty
            startedFreshCycle = true
        }

        if nextState.completedDates.isEmpty {
            nextState.cycleStartDate = day
        }

        let inserted = nextState.completedDates.insert(day).inserted
        nextState.lastCompletionTimestamp = completedAt

        let nextSnapshot = snapshot(state: nextState, currentDay: day)
        return MantraRitualCompletionResult(
            state: nextState,
            snapshot: nextSnapshot,
            completedNewDay: inserted,
            startedFreshCycle: startedFreshCycle,
            milestone: nextSnapshot.shouldElevateSharePrompt ? nextSnapshot.milestone : nil
        )
    }

    static func markMilestoneSeen(state: MantraRitualState, milestone: MantraRitualMilestone) -> MantraRitualState {
        var nextState = state
        nextState.shownShareMilestones.insert(milestone.rawValue)
        return nextState
    }

    private static func missedDaysSinceLastCompletion(state: MantraRitualState, currentDay: String) -> Int {
        guard let lastDay = state.completedDates.max(),
              let lastDate = ritualDate(from: lastDay),
              let currentDate = ritualDate(from: currentDay) else {
            return 0
        }

        let delta = ritualCalendar.dateComponents([.day], from: lastDate, to: currentDate).day ?? 0
        return max(0, delta - 1)
    }

    private static func ritualDate(from day: String) -> Date? {
        ritualFormatter.date(from: day)
    }

    private static let ritualCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    private static let ritualFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = ritualCalendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = ritualCalendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
