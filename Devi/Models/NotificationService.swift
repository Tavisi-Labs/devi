// MARK: - Models/NotificationService.swift
// Owns all UNUserNotificationCenter interaction — permission, categories, scheduling.
// Standalone Sendable class (not ObservableObject) — the ViewModel gathers data on @MainActor,
// then hands it off via Task { await notificationService.reschedule(...) }.

import UserNotifications

final class NotificationService: Sendable {

    // MARK: - Category Identifiers

    static let dailySummaryCategory = "DEVI_DAILY_SUMMARY"
    static let eventAlertCategory = "DEVI_EVENT_ALERT"
    static let eclipseAlertCategory = "DEVI_ECLIPSE_ALERT"
    static let ritualReminderCategory = "DEVI_RITUAL_REMINDER"

    // MARK: - Permission

    /// Prompts the user for notification permission. Returns true if granted.
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    /// Checks current authorization without prompting.
    func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let status = settings.authorizationStatus
        return status == .authorized || status == .provisional
    }

    // MARK: - Categories

    /// Registers notification categories with a "View Details" foreground action.
    func registerCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_DETAILS",
            title: "View Details",
            options: .foreground
        )

        let categories: Set<UNNotificationCategory> = [
            UNNotificationCategory(identifier: Self.dailySummaryCategory, actions: [viewAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: Self.eventAlertCategory, actions: [viewAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: Self.eclipseAlertCategory, actions: [viewAction], intentIdentifiers: []),
            UNNotificationCategory(identifier: Self.ritualReminderCategory, actions: [viewAction], intentIdentifiers: []),
        ]

        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }

    // MARK: - Schedule Input

    /// All the data needed to compute the next 7 days of notifications.
    struct ScheduleInput {
        struct RitualReminder: Sendable {
            let tone: MantraRitualReminderTone
        }

        let days: [DailyPanchang]
        let navratriDays: [String: NavratriDay]   // dateString → NavratriDay
        let eclipses: [EclipseEvent]
        let city: UserCity
        // Preferences
        let dailySummary: Bool
        let sunrise: Bool
        let sunset: Bool
        let rahuKalam: Bool
        let abhijitMuhurta: Bool
        let brahmaMuhurta: Bool
        let navratri: Bool
        let eclipse: Bool
        let minutesBefore: Int
        let horoscope: Bool
        let horoscopeThemes: [String: String]  // dateString → theme statement
        let ritualReminders: [String: RitualReminder]  // dateString → reminder tone
    }

    // MARK: - Scheduling

    /// Removes all pending notifications, then schedules up to 64 new ones.
    func reschedule(_ input: ScheduleInput) async {
        let center = UNUserNotificationCenter.current()

        // 1. Remove all pending Devi notifications
        center.removeAllPendingNotificationRequests()

        // 2. Check authorization — bail if denied
        guard await isAuthorized() else { return }

        let now = Date()
        let tz = TimeZone(identifier: input.city.timezoneIdentifier) ?? .current
        var pending: [(id: String, content: UNMutableNotificationContent, fireDate: Date)] = []

        // 3. For each day of panchang data
        for day in input.days {
            let dateStr = day.dateString

            // -- Daily summary (30 min before sunrise) --
            if input.dailySummary {
                let fire = day.solar.sunrise.addingTimeInterval(-30 * 60)
                if fire > now {
                    pending.append((
                        "devi.summary.\(dateStr)",
                        Self.dailySummaryContent(day: day, navratri: input.navratriDays[dateStr], timezone: tz),
                        fire
                    ))
                }
            }

            // -- Sunrise --
            if input.sunrise {
                let fire = day.solar.sunrise.addingTimeInterval(Double(-input.minutesBefore * 60))
                if fire > now {
                    pending.append((
                        "devi.sunrise.\(dateStr)",
                        Self.sunriseContent(day: day, city: input.city, timezone: tz),
                        fire
                    ))
                }
            }

            // -- Sunset --
            if input.sunset {
                let fire = day.solar.sunset.addingTimeInterval(Double(-input.minutesBefore * 60))
                if fire > now {
                    pending.append((
                        "devi.sunset.\(dateStr)",
                        Self.sunsetContent(day: day, city: input.city, timezone: tz),
                        fire
                    ))
                }
            }

            // -- Time windows (rahu kalam, abhijit muhurta, brahma muhurta) --
            for window in day.timeWindows {
                let (shouldNotify, idKey): (Bool, String) = {
                    switch window.type {
                    case .rahuKalam:     return (input.rahuKalam, "rahuKalam")
                    case .abhijitMuhurta: return (input.abhijitMuhurta, "abhijit")
                    case .brahmaMuhurta: return (input.brahmaMuhurta, "brahma")
                    case .gulikaKalam, .yamaganda: return (false, window.type.rawValue)
                    }
                }()

                guard shouldNotify else { continue }
                let fire = window.start.addingTimeInterval(Double(-input.minutesBefore * 60))
                if fire > now {
                    pending.append((
                        "devi.\(idKey).\(dateStr)",
                        Self.timeWindowContent(window: window, timezone: tz),
                        fire
                    ))
                }
            }

            // -- Navratri (fires at sunrise with goddess info) --
            if input.navratri, let navDay = input.navratriDays[dateStr] {
                let fire = day.solar.sunrise
                if fire > now {
                    pending.append((
                        "devi.navratri.\(dateStr)",
                        Self.navratriContent(navDay: navDay),
                        fire
                    ))
                }
            }

            // -- Ritual reminder (gentle morning invitation) --
            if let reminder = input.ritualReminders[dateStr],
               let fire = Self.ritualReminderFireDate(for: day, timezone: tz),
               fire > now {
                pending.append((
                    "devi.ritual.\(dateStr)",
                    Self.ritualReminderContent(reminder: reminder),
                    fire
                ))
            }
        }

        // 4. Daily horoscope (7 AM local)
        if input.horoscope {
            for day in input.days {
                let dateStr = day.dateString
                guard let themeStatement = input.horoscopeThemes[dateStr] else { continue }

                if let fire = Self.dateFromString(dateStr, hour: 7, minute: 0, timezone: tz), fire > now {
                    let content = UNMutableNotificationContent()
                    content.title = "Your Day at a Glance"
                    content.body = themeStatement
                    content.sound = .default
                    content.categoryIdentifier = Self.dailySummaryCategory

                    pending.append(("devi.horoscope.\(dateStr)", content, fire))
                }
            }
        }

        // 5. Eclipse alerts (renumbered after horoscope insertion)
        if input.eclipse {
            for eclipse in input.eclipses {
                let eclipseId = eclipse.id

                // 7-day advance warning at 8 AM local
                if let baseDate = Self.dateFromString(eclipse.dateString, hour: 8, minute: 0, timezone: tz) {
                    let fire = baseDate.addingTimeInterval(-7 * 24 * 3600)
                    if fire > now {
                        pending.append((
                            "devi.eclipse.7day.\(eclipseId)",
                            Self.eclipseAdvanceContent(eclipse: eclipse, daysAway: 7),
                            fire
                        ))
                    }
                }

                // 1-day advance warning at 8 AM local
                if let baseDate = Self.dateFromString(eclipse.dateString, hour: 8, minute: 0, timezone: tz) {
                    let fire = baseDate.addingTimeInterval(-24 * 3600)
                    if fire > now {
                        pending.append((
                            "devi.eclipse.1day.\(eclipseId)",
                            Self.eclipseAdvanceContent(eclipse: eclipse, daysAway: 1),
                            fire
                        ))
                    }
                }

                // Event start — minutesBefore before first contact time
                let firstContact = eclipse.contactTimeline.first?.time ?? eclipse.maxEclipseTime
                let fire = firstContact.addingTimeInterval(Double(-input.minutesBefore * 60))
                if fire > now {
                    pending.append((
                        "devi.eclipse.start.\(eclipseId)",
                        Self.eclipseStartContent(eclipse: eclipse, timezone: tz),
                        fire
                    ))
                }
            }
        }

        // 6. Sort by fire date ascending, truncate to 64 (iOS limit)
        pending.sort { $0.fireDate < $1.fireDate }
        let final64 = pending.prefix(64)

        // 7. Schedule all
        for item in final64 {
            let interval = item.fireDate.timeIntervalSinceNow
            guard interval > 0 else { continue }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: item.id, content: item.content, trigger: trigger)
            try? await center.add(request)
        }

        #if DEBUG
        print("[Devi] Scheduled \(final64.count) notifications")
        #endif
    }

    // MARK: - Content Builders

    private static func dailySummaryContent(day: DailyPanchang, navratri: NavratriDay?, timezone: TimeZone) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Today's Panchang"

        var body = "\(day.tithi.displayName) · \(day.nakshatra.name)"
        body += "\nSunrise \(formatTime(day.solar.sunrise, timezone: timezone)) · Sunset \(formatTime(day.solar.sunset, timezone: timezone))"

        if day.tithi.isFastingDay, let fastType = day.tithi.fastingType {
            body += "\n\(fastType) — fasting day"
        }
        if let nav = navratri {
            body += "\nNavratri Day \(nav.dayNumber): \(nav.goddessName)"
        }

        content.body = body
        content.sound = .default
        content.categoryIdentifier = dailySummaryCategory
        return content
    }

    private static func sunriseContent(day: DailyPanchang, city: UserCity, timezone: TimeZone) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Sunrise"
        content.body = "Sunrise at \(formatTime(day.solar.sunrise, timezone: timezone)) in \(city.name)"
        content.sound = .default
        content.categoryIdentifier = eventAlertCategory
        return content
    }

    private static func sunsetContent(day: DailyPanchang, city: UserCity, timezone: TimeZone) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Sunset — Sandhya Vandana"
        content.body = "Sunset at \(formatTime(day.solar.sunset, timezone: timezone)) in \(city.name)"
        content.sound = .default
        content.categoryIdentifier = eventAlertCategory
        return content
    }

    private static func timeWindowContent(window: TimeWindow, timezone: TimeZone) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        switch window.type {
        case .rahuKalam:
            content.title = "Rahu Kalam Approaching"
            content.body = "Rahu Kalam begins at \(formatTime(window.start, timezone: timezone)) — avoid starting new activities"
        case .abhijitMuhurta:
            content.title = "Abhijit Muhurta"
            content.body = "The most auspicious time begins at \(formatTime(window.start, timezone: timezone))"
        case .brahmaMuhurta:
            content.title = "Brahma Muhurta"
            content.body = "The creator's hour begins at \(formatTime(window.start, timezone: timezone)) — ideal for meditation"
        default:
            content.title = window.type.rawValue
            content.body = "Begins at \(formatTime(window.start, timezone: timezone))"
        }

        content.sound = .default
        content.categoryIdentifier = eventAlertCategory
        return content
    }

    private static func navratriContent(navDay: NavratriDay) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Navratri Day \(navDay.dayNumber)"
        content.body = "\(navDay.goddessName) — \(navDay.goddessEpithet)\nWear \(navDay.colorName) · Offer \(navDay.offering)"
        content.sound = .default
        content.categoryIdentifier = eventAlertCategory
        return content
    }

    private static func ritualReminderContent(reminder: ScheduleInput.RitualReminder) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        switch reminder.tone {
        case .open:
            content.title = "Your mandala is waiting"
            content.body = "A new segment can bloom today."
        case .waiting:
            content.title = "Keep the morning practice alive"
            content.body = "Your mandala is waiting for today's chant."
        case .beginAgain:
            content.title = "Begin again when you're ready"
            content.body = "A new mandala can bloom today."
        }

        content.sound = .default
        content.categoryIdentifier = ritualReminderCategory
        return content
    }

    private static func eclipseAdvanceContent(eclipse: EclipseEvent, daysAway: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let timeLabel: String
        if daysAway == 1 {
            timeLabel = "Tomorrow"
        } else {
            let parser = DateFormatter()
            parser.dateFormat = "yyyy-MM-dd"
            if let date = parser.date(from: eclipse.dateString) {
                let display = DateFormatter()
                display.dateFormat = "MMMM d"
                timeLabel = display.string(from: date)
            } else {
                timeLabel = eclipse.dateString
            }
        }
        content.title = "\(eclipse.body.sanskritName) — \(timeLabel)"
        content.body = "\(eclipse.displayName) on \(eclipse.dateString). Prepare for spiritual observances."
        content.sound = .default
        content.categoryIdentifier = eclipseAlertCategory
        return content
    }

    private static func eclipseStartContent(eclipse: EclipseEvent, timezone: TimeZone) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(eclipse.body.sanskritName) Beginning"
        if let firstTime = eclipse.contactTimeline.first?.time {
            content.body = "\(eclipse.displayName) begins at \(formatTime(firstTime, timezone: timezone))"
        } else {
            content.body = "\(eclipse.displayName) is starting now"
        }
        content.sound = .default
        content.categoryIdentifier = eclipseAlertCategory
        return content
    }

    // MARK: - Helpers

    private static func formatTime(_ date: Date, timezone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }

    private static func dateFromString(_ dateString: String, hour: Int, minute: Int, timezone: TimeZone) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = timezone
        guard let date = formatter.date(from: dateString) else { return nil }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
    }

    private static func ritualReminderFireDate(for day: DailyPanchang, timezone: TimeZone) -> Date? {
        guard let morningAnchor = dateFromString(day.dateString, hour: 8, minute: 30, timezone: timezone) else {
            return day.solar.sunrise.addingTimeInterval(45 * 60)
        }
        return max(morningAnchor, day.solar.sunrise.addingTimeInterval(45 * 60))
    }
}
