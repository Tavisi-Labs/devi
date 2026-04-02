// MARK: - Models/PanchangViewModel.swift
// The single ViewModel that drives the entire app

import SwiftUI
import CoreLocation
import Combine

@MainActor
class PanchangViewModel: ObservableObject {

    // MARK: - Published State

    @Published var currentCity: UserCity = UserCity.popularCities[0]
    @Published var todayPanchang: DailyPanchang?
    @Published var theme: DeviTheme = DeviTheme.forPeriod(.morning)
    @Published var timePeriod: TimePeriod = .morning
    @Published var currentNavratriDay: NavratriDay?
    @Published var eclipseEvents: [EclipseEvent] = []
    @Published var todayEclipse: EclipseEvent?
    @Published var imminentEclipse: EclipseEvent?    // Within 7 days
    @Published var upcomingEvents: [UpcomingEvent] = []
    @Published var countdownText: String = "0.00.00"
    @Published var countdownLabel: String = "SUNRISE IN"
    @Published var currentTimeText: String = "6:00 PM"
    private var tomorrowSunrise: Date?
    @Published var isLocationAuthorized: Bool = false
    @Published var isResolvingLocation: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var notificationsAuthorized: Bool = false
    @Published var fontScale: DeviFontScale = .standard {
        didSet { UserDefaults.standard.set(fontScale.rawValue, forKey: "fontScale") }
    }
    @Published var themeStyle: DeviThemeStyle = .classic {
        didSet { UserDefaults.standard.set(themeStyle.rawValue, forKey: "themeStyle") }
    }
    @Published var appearanceMode: DeviAppearanceMode = .auto {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode") }
    }
    @Published var samvathsaraName: String = ""
    @Published var todayFestivals: [String] = []

    // MARK: - Horoscope
    @Published var dailyHoroscope: DailyHoroscope?
    @Published var birthData: BirthData?
    @Published var natalChart: NatalChart?
    @Published var showBirthDataInput: Bool = false
    @Published var notifHoroscope: Bool = true {
        didSet { UserDefaults.standard.set(notifHoroscope, forKey: "notif.horoscope"); scheduleNotificationReschedule() }
    }

    // MARK: - Cosmic Signature (AI)
    @Published var cosmicSignature: String?
    @Published var isLoadingSignature = false
    @Published var cosmicSignatureError: Bool = false
    private let cosmicService = CosmicSignatureService()
    private var signatureTask: Task<Void, Never>?
    private var fetchGeneration: Int = 0  // Prevents stale Task results from overwriting fresh state

    // MARK: - Haptic Triggers
    /// Incremented when countdown hits 0:00:00 — triggers heavy haptic
    @Published var countdownZeroTrigger: Int = 0
    /// Virtual time offset for sun arc scrubbing (nil = live)
    @Published var virtualTimeOffset: TimeInterval? = nil

    // MARK: - Gesture Discovery Hints
    /// Number of app launches recorded — used to show gesture hints on first 3 launches
    @Published var hintLaunchCount: Int = 0
    /// True when the user should see gesture discovery hints (first 3 launches)
    var shouldShowHints: Bool { hintLaunchCount < 3 }

    // MARK: - Transition Pill ("What Changed")
    /// Set when the tithi has changed since the user last opened the app
    @Published var tithiChangedMessage: String?

    // MARK: - Location Error
    /// Set when geocoding fails and nearest-city fallback is used
    @Published var locationError: String?

    /// The effective "now" — either real time or scrubbed virtual time
    var effectiveNow: Date {
        virtualTimeOffset.map { Date().addingTimeInterval($0) } ?? Date()
    }

    // MARK: - Day Navigation
    @Published var dayOffset: Int = 0  // -1 yesterday, 0 today, +1 tomorrow

    var displayDate: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
    }

    var isViewingToday: Bool { dayOffset == 0 }

    // MARK: - Notification Preferences (persisted via UserDefaults)

    @Published var notifDailySummary: Bool = true {
        didSet { UserDefaults.standard.set(notifDailySummary, forKey: "notif.dailySummary"); scheduleNotificationReschedule() }
    }
    @Published var notifSunrise: Bool = true {
        didSet { UserDefaults.standard.set(notifSunrise, forKey: "notif.sunrise"); scheduleNotificationReschedule() }
    }
    @Published var notifSunset: Bool = true {
        didSet { UserDefaults.standard.set(notifSunset, forKey: "notif.sunset"); scheduleNotificationReschedule() }
    }
    @Published var notifRahuKalamWarning: Bool = true {
        didSet { UserDefaults.standard.set(notifRahuKalamWarning, forKey: "notif.rahuKalam"); scheduleNotificationReschedule() }
    }
    @Published var notifAbhijitMuhurta: Bool = false {
        didSet { UserDefaults.standard.set(notifAbhijitMuhurta, forKey: "notif.abhijit"); scheduleNotificationReschedule() }
    }
    @Published var notifBrahmaMuhurta: Bool = false {
        didSet { UserDefaults.standard.set(notifBrahmaMuhurta, forKey: "notif.brahma"); scheduleNotificationReschedule() }
    }
    @Published var notifNavratriMorning: Bool = true {
        didSet { UserDefaults.standard.set(notifNavratriMorning, forKey: "notif.navratri"); scheduleNotificationReschedule() }
    }
    @Published var notifEclipseAlert: Bool = true {
        didSet { UserDefaults.standard.set(notifEclipseAlert, forKey: "notif.eclipse"); scheduleNotificationReschedule() }
    }
    @Published var notifMinutesBefore: Int = 10 {
        didSet { UserDefaults.standard.set(notifMinutesBefore, forKey: "notif.minutesBefore"); scheduleNotificationReschedule() }
    }

    // MARK: - Notifications

    let notificationService = NotificationService()
    private var notificationRescheduleTask: Task<Void, Never>?
    private var didFinishInit = false

    // MARK: - Private

    private let locationManager = LocationManager()
    private var locationResolutionTimeoutTask: Task<Void, Never>?
    private var timerCancellable: AnyCancellable?
    private let dataStore = PanchangDataStore() // Kept for eclipse data (separate concern)
    private var panchangCache: [String: DailyPanchang] = [:]  // city+date → panchang
    private var horoscopeCache: [String: DailyHoroscope] = [:]  // date-rashi → horoscope
    private var lastCacheCity: String = ""

    // MARK: - Computed

    var sunProgress: Double {
        todayPanchang?.solar.sunProgress(at: effectiveNow) ?? 0.5
    }

    var isDaytime: Bool {
        todayPanchang?.solar.isDaytime(at: effectiveNow) ?? true
    }

    var isLightMode: Bool {
        appearanceMode.isLight(for: timePeriod)
    }

    var activeTimeWindows: [TimeWindow] {
        todayPanchang?.timeWindows ?? []
    }

    var isNavratriActive: Bool {
        currentNavratriDay != nil
    }

    // MARK: - Right Now Items (aggregates active hora + choghadiya + time windows)

    struct RightNowItem: Identifiable {
        let id: String
        let label: String
        let statusColor: Color
        let endTime: Date
        let isActive: Bool    // true = NOW, false = NEXT
        let element: PanchangElement
    }

    var rightNowItems: [RightNowItem] {
        guard let panchang = todayPanchang else { return [] }
        let now = effectiveNow
        var items: [RightNowItem] = []

        // Current hora
        if let hora = panchang.horas.first(where: { $0.isActive(at: now) }) {
            items.append(RightNowItem(
                id: "hora-now", label: "\(hora.planetSanskrit) Hora",
                statusColor: horaColor(hora.planetName), endTime: hora.endTime,
                isActive: true, element: .hora(hora)
            ))
        } else if let next = panchang.horas.first(where: { now < $0.startTime }) {
            items.append(RightNowItem(
                id: "hora-next", label: "\(next.planetSanskrit) Hora",
                statusColor: horaColor(next.planetName), endTime: next.startTime,
                isActive: false, element: .hora(next)
            ))
        }

        // Current choghadiya
        if let chog = panchang.choghadiyas.first(where: { $0.isActive(at: now) }) {
            items.append(RightNowItem(
                id: "chog-now", label: "\(chog.name) Choghadiya",
                statusColor: choghadiyaColor(chog.quality), endTime: chog.endTime,
                isActive: true, element: .choghadiya(chog)
            ))
        } else if let next = panchang.choghadiyas.first(where: { now < $0.startTime }) {
            items.append(RightNowItem(
                id: "chog-next", label: "\(next.name) Choghadiya",
                statusColor: choghadiyaColor(next.quality), endTime: next.startTime,
                isActive: false, element: .choghadiya(next)
            ))
        }

        // Active time windows (multiple can be active simultaneously)
        for window in panchang.timeWindows {
            if window.isActive(at: now) {
                items.append(RightNowItem(
                    id: "tw-\(window.type.rawValue)", label: window.type.rawValue,
                    statusColor: windowColor(window.statusColor), endTime: window.end,
                    isActive: true, element: .timeWindow(window)
                ))
            }
        }

        // If no windows active, show the next upcoming one
        if !panchang.timeWindows.contains(where: { $0.isActive(at: now) }),
           let next = panchang.timeWindows.filter({ now < $0.start }).sorted(by: { $0.start < $1.start }).first {
            items.append(RightNowItem(
                id: "tw-\(next.type.rawValue)", label: next.type.rawValue,
                statusColor: windowColor(next.statusColor), endTime: next.start,
                isActive: false, element: .timeWindow(next)
            ))
        }

        return items
    }

    // MARK: - Capped Upcoming Events

    var cappedUpcomingEvents: [UpcomingEvent] {
        Array(upcomingEvents.prefix(5))
    }

    var upcomingEventsByMonth: [(month: String, events: [UpcomingEvent])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"

        var grouped: [(month: String, events: [UpcomingEvent])] = []
        var currentMonth = ""
        var currentEvents: [UpcomingEvent] = []

        for event in upcomingEvents {
            guard let date = formatter.date(from: event.dateString) else { continue }
            let month = monthFormatter.string(from: date).uppercased()
            if month != currentMonth {
                if !currentEvents.isEmpty {
                    grouped.append((month: currentMonth, events: currentEvents))
                }
                currentMonth = month
                currentEvents = [event]
            } else {
                currentEvents.append(event)
            }
        }
        if !currentEvents.isEmpty {
            grouped.append((month: currentMonth, events: currentEvents))
        }
        return grouped
    }

    // MARK: - Color Helpers (for RightNowItems)

    private func horaColor(_ planetName: String) -> Color {
        Graha.named(planetName)?.color ?? Color(hex: "888888")
    }

    private func choghadiyaColor(_ quality: ChoghadiyaQuality) -> Color {
        switch quality {
        case .auspicious:   return Color(hex: "3DA66A")
        case .inauspicious: return Color(hex: "C45050")
        case .neutral:      return Color(hex: "D4A040")
        }
    }

    private func windowColor(_ status: TimeWindow.WindowColor) -> Color {
        switch status {
        case .auspicious:   return Color(hex: "3DA66A")
        case .inauspicious: return Color(hex: "C45050")
        case .caution:      return Color(hex: "D4A040")
        }
    }

    // MARK: - Init

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        // Load persisted notification preferences
        let ud = UserDefaults.standard
        if ud.object(forKey: "notif.dailySummary") != nil { notifDailySummary = ud.bool(forKey: "notif.dailySummary") }
        if ud.object(forKey: "notif.sunrise") != nil { notifSunrise = ud.bool(forKey: "notif.sunrise") }
        if ud.object(forKey: "notif.sunset") != nil { notifSunset = ud.bool(forKey: "notif.sunset") }
        if ud.object(forKey: "notif.rahuKalam") != nil { notifRahuKalamWarning = ud.bool(forKey: "notif.rahuKalam") }
        if ud.object(forKey: "notif.abhijit") != nil { notifAbhijitMuhurta = ud.bool(forKey: "notif.abhijit") }
        if ud.object(forKey: "notif.brahma") != nil { notifBrahmaMuhurta = ud.bool(forKey: "notif.brahma") }
        if ud.object(forKey: "notif.navratri") != nil { notifNavratriMorning = ud.bool(forKey: "notif.navratri") }
        if ud.object(forKey: "notif.eclipse") != nil { notifEclipseAlert = ud.bool(forKey: "notif.eclipse") }
        if ud.object(forKey: "notif.minutesBefore") != nil { notifMinutesBefore = ud.integer(forKey: "notif.minutesBefore") }

        // Load persisted font scale
        if let scaleStr = ud.string(forKey: "fontScale"),
           let scale = DeviFontScale(rawValue: scaleStr) {
            fontScale = scale
        }

        // Load persisted theme style
        if let styleStr = ud.string(forKey: "themeStyle"),
           let style = DeviThemeStyle(rawValue: styleStr) {
            themeStyle = style
        }

        // Load persisted appearance mode
        if let appearStr = ud.string(forKey: "appearanceMode"),
           let mode = DeviAppearanceMode(rawValue: appearStr) {
            appearanceMode = mode
        }

        // Load persisted horoscope notification preference
        if ud.object(forKey: "notif.horoscope") != nil { notifHoroscope = ud.bool(forKey: "notif.horoscope") }

        // Load persisted birth data and compute natal chart
        birthData = BirthData.load()
        if let bd = birthData {
            natalChart = NatalChart.compute(from: bd)
        }

        // Load hint launch counter for gesture discovery
        hintLaunchCount = ud.integer(forKey: "hintLaunchCount")

        // Load persisted city (if user previously selected one)
        if let cityName = ud.string(forKey: "city.name"),
           let country = ud.string(forKey: "city.country"),
           let tz = ud.string(forKey: "city.timezoneIdentifier") {
            currentCity = UserCity(
                name: cityName, country: country,
                latitude: ud.double(forKey: "city.latitude"),
                longitude: ud.double(forKey: "city.longitude"),
                timezoneIdentifier: tz
            )
        }

        didFinishInit = true

        // Load data eagerly so todayPanchang is non-nil on the first render.
        // VedicCalculator is already initialized in DeviApp.init() and currentCity
        // is loaded from UserDefaults above, so this is safe and synchronous.
        loadData()
    }

    // MARK: - Timer (updates every second)

    func startTimer() {
        guard timerCancellable == nil else { return }
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func tick() {
        updateCurrentTime()
        updateCountdown()
        updateThemeIfNeeded()
    }

    private func updateCurrentTime() {
        currentTimeText = deviFormatTime(Date(), timezoneIdentifier: currentCity.timezoneIdentifier)
    }

    private func updateCountdown() {
        guard let solar = todayPanchang?.solar else { return }

        let now = Date()
        let target: Date
        let label: String

        if solar.isDaytime {
            target = solar.sunset
            label = "SUNSET IN"
        } else if now < solar.sunrise {
            target = solar.sunrise
            label = "SUNRISE IN"
        } else if let nextSunrise = tomorrowSunrise {
            target = nextSunrise
            label = "SUNRISE IN"
        } else {
            countdownLabel = "NEXT SUNRISE"
            countdownText = "--.--.--"
            return
        }

        let remaining = target.timeIntervalSince(now)
        guard remaining > 0 else {
            if countdownText != "0.00.00" {
                countdownZeroTrigger += 1
            }
            countdownText = "0.00.00"
            countdownLabel = label
            return
        }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60

        countdownText = String(format: "%d.%02d.%02d", hours, minutes, seconds)
        countdownLabel = label
    }

    private func updateThemeIfNeeded() {
        guard let solar = todayPanchang?.solar else { return }
        let newPeriod = TimePeriod.current(sunrise: solar.sunrise, sunset: solar.sunset)
        if newPeriod != timePeriod {
            withAnimation(.easeInOut(duration: 8)) { // 8s gradient transition
                timePeriod = newPeriod
                theme = DeviTheme.forPeriod(newPeriod, style: themeStyle, appearance: appearanceMode)
            }
        }
    }

    /// Call this from UI to switch theme style — avoids re-entrant @Published issues
    func setThemeStyle(_ style: DeviThemeStyle) {
        themeStyle = style
        withAnimation(.easeInOut(duration: 0.5)) {
            theme = DeviTheme.forPeriod(timePeriod, style: style, appearance: appearanceMode)
        }
    }

    /// Call this from UI to switch appearance mode
    func setAppearanceMode(_ mode: DeviAppearanceMode) {
        appearanceMode = mode
        withAnimation(.easeInOut(duration: 0.5)) {
            theme = DeviTheme.forPeriod(timePeriod, style: themeStyle, appearance: mode)
        }
    }

    // MARK: - Data Loading

    func loadData() {
        // Invalidate cache on city change
        if lastCacheCity != currentCity.id {
            panchangCache.removeAll()
            lastCacheCity = currentCity.id
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Use displayDate (accounts for day navigation offset)
        let targetDate = displayDate
        let targetString = dateFormatter.string(from: targetDate)

        // Compute panchang dynamically via Swiss Ephemeris
        todayPanchang = cachedPanchang(for: targetDate, dateString: targetString)

        // Compute next day's sunrise for after-sunset countdown
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: targetDate) {
            let nextDayString = dateFormatter.string(from: nextDay)
            tomorrowSunrise = cachedPanchang(for: nextDay, dateString: nextDayString).solar.sunrise
        }

        // Check Navratri
        checkNavratri(dateString: targetString)

        // Load eclipse data (still from mock data store)
        let todayString = dateFormatter.string(from: Date())
        loadEclipseData(todayString: todayString)

        // Load upcoming events (always from actual today)
        loadUpcomingEvents(from: todayString)

        // Samvathsara year name (60-year Jupiter cycle)
        samvathsaraName = PanchangCalculator.samvathsaraName(for: targetDate)

        // Festivals for the displayed day
        todayFestivals = PanchangCalculator.festivals(for: targetString)
        if todayPanchang?.tithi.name == "Purnima" && !todayFestivals.contains("Satya Narayana Pooja") {
            todayFestivals.append("Satya Narayana Pooja")
        }

        // Detect tithi change since last app open (only for today view)
        // Uses displayName ("Shukla Panchami") not bare name ("Panchami") to catch paksha transitions
        if isViewingToday, let currentTithi = todayPanchang?.tithi.displayName {
            let ud = UserDefaults.standard
            let lastSeenTithi = ud.string(forKey: "lastSeenTithi")
            if let last = lastSeenTithi, last != currentTithi {
                tithiChangedMessage = "Tithi changed to \(currentTithi)"
                // Don't update lastSeenTithi yet — let the pill persist until dismissed
            } else if tithiChangedMessage == nil {
                // Only update when there's no active message being shown
                ud.set(currentTithi, forKey: "lastSeenTithi")
            }
        } else {
            tithiChangedMessage = nil
            // When navigating away from today, update lastSeenTithi so pill dismisses on return
            if let currentTithi = todayPanchang?.tithi.displayName {
                UserDefaults.standard.set(currentTithi, forKey: "lastSeenTithi")
            }
        }

        // Set initial theme (always based on real time, not day offset)
        if let solar = todayPanchang?.solar, isViewingToday {
            timePeriod = TimePeriod.current(sunrise: solar.sunrise, sunset: solar.sunset)
            theme = DeviTheme.forPeriod(timePeriod, style: themeStyle, appearance: appearanceMode)
        }

        // Load daily horoscope (if birth data is set)
        loadHoroscope()

        // Fetch cosmic signature (async, non-blocking)
        if let panchang = todayPanchang {
            fetchCosmicSignature(panchang: panchang)
        }
    }

    private func fetchCosmicSignature(panchang: DailyPanchang, forceRefresh: Bool = false) {
        signatureTask?.cancel()
        fetchGeneration += 1
        let myGeneration = fetchGeneration
        isLoadingSignature = true
        cosmicSignatureError = false
        signatureTask = Task {
            let result = await cosmicService.fetchSignature(
                panchang: panchang,
                city: currentCity.name,
                forceRefresh: forceRefresh
            )
            // Only apply results if this is still the latest fetch (prevents race from rapid retries)
            guard !Task.isCancelled, myGeneration == fetchGeneration else { return }
            cosmicSignature = result
            isLoadingSignature = false
            if cosmicService.lastFetchAPIFailed {
                cosmicSignatureError = true
            }
        }
    }

    /// Retry cosmic signature fetch after an error
    func retryCosmicSignature() {
        cosmicSignatureError = false
        if let panchang = todayPanchang {
            fetchCosmicSignature(panchang: panchang, forceRefresh: true)
        }
    }

    // MARK: - Day Navigation

    func navigateDay(by offset: Int) {
        let newOffset = max(-7, min(7, dayOffset + offset))
        guard newOffset != dayOffset else { return }
        dayOffset = newOffset
        virtualTimeOffset = nil  // Reset any scrub state
        loadData()
    }

    func returnToToday() {
        guard dayOffset != 0 else { return }
        dayOffset = 0
        virtualTimeOffset = nil
        loadData()
    }

    /// Returns panchang from cache or computes it fresh via PanchangCalculator.
    private func cachedPanchang(for date: Date, dateString: String) -> DailyPanchang {
        let key = "\(currentCity.id)-\(dateString)"
        if let cached = panchangCache[key] { return cached }
        let result = PanchangCalculator.panchang(for: date, city: currentCity)
        panchangCache[key] = result
        return result
    }

    private func checkNavratri(dateString: String) {
        guard let year = Int(dateString.prefix(4)) else {
            currentNavratriDay = nil
            return
        }
        let periods = FestivalEngine.navratriPeriods(forYear: year)
        for period in periods {
            if let dayNum = period.dayNumber(for: dateString) {
                currentNavratriDay = NavratriDay.goddesses[dayNum - 1]
                return
            }
        }
        currentNavratriDay = nil
    }

    private func loadEclipseData(todayString: String) {
        // Eclipse data suppressed until real ephemeris-based calculations are implemented.
        // Mock data from PanchangDataStore erodes trust — keep all eclipse UI code intact.
        eclipseEvents = []
        todayEclipse = nil
        imminentEclipse = nil
    }

    private func loadUpcomingEvents(from todayString: String) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let today = dateFormatter.date(from: todayString) else { return }

        var events: [UpcomingEvent] = []
        var seenNames: Set<String> = []  // Deduplicate across days

        // Scan next 60 days for festivals and fasting days
        for offset in 1...60 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let ds = dateFormatter.string(from: date)

            // Festivals from the static festival data
            let festivals = PanchangCalculator.festivals(for: ds)
            for fest in festivals {
                guard !seenNames.contains(fest) else { continue }
                seenNames.insert(fest)
                events.append(UpcomingEvent(
                    name: fest, dateString: ds, daysAway: offset, type: .festival
                ))
            }

            // Fasting days from tithi calculation
            let panchang = cachedPanchang(for: date, dateString: ds)
            if let fastType = panchang.tithi.fastingType {
                let label = fastType
                guard !seenNames.contains("\(label)-\(ds)") else { continue }
                seenNames.insert("\(label)-\(ds)")
                events.append(UpcomingEvent(
                    name: label, dateString: ds, daysAway: offset, type: .fasting
                ))

                // Satya Narayana Pooja on every Purnima
                if panchang.tithi.name == "Purnima" {
                    let snKey = "Satya Narayana Pooja-\(ds)"
                    if !seenNames.contains(snKey) {
                        seenNames.insert(snKey)
                        events.append(UpcomingEvent(
                            name: "Satya Narayana Pooja", dateString: ds, daysAway: offset, type: .festival
                        ))
                    }
                }
            }

            // Monthly recurring observances (every lunar month)
            let tithiPaksha = panchang.tithi.paksha
            let tithiNumber = panchang.tithi.number

            // Sankashti Chaturthi: Every Krishna paksha, tithi 4 — Ganesha fasting
            // Skip if an annual festival (e.g., Karva Chauth) already covers this day
            if tithiPaksha == .krishna && tithiNumber == 4 && !festivals.contains("Karva Chauth") {
                let key = "Sankashti Chaturthi-\(ds)"
                if !seenNames.contains(key) {
                    seenNames.insert(key)
                    events.append(UpcomingEvent(
                        name: "Sankashti Chaturthi", dateString: ds, daysAway: offset, type: .fasting
                    ))
                }
            }

            // Vinayaka Chaturthi: Every Shukla paksha, tithi 4 — Ganesha worship
            // Skip if Ganesh Chaturthi (annual) already covers this day
            if tithiPaksha == .shukla && tithiNumber == 4 && !festivals.contains("Ganesh Chaturthi") {
                let key = "Vinayaka Chaturthi-\(ds)"
                if !seenNames.contains(key) {
                    seenNames.insert(key)
                    events.append(UpcomingEvent(
                        name: "Vinayaka Chaturthi", dateString: ds, daysAway: offset, type: .festival
                    ))
                }
            }

            // Masik Shivaratri: Every Krishna paksha, tithi 14 (Chaturdashi) — Shiva fasting
            // Skip if Maha Shivaratri (annual) already covers this day
            if tithiPaksha == .krishna && tithiNumber == 14 && !festivals.contains("Maha Shivaratri") {
                let key = "Masik Shivaratri-\(ds)"
                if !seenNames.contains(key) {
                    seenNames.insert(key)
                    events.append(UpcomingEvent(
                        name: "Masik Shivaratri", dateString: ds, daysAway: offset, type: .fasting
                    ))
                }
            }
        }

        // Merge eclipse events (if any)
        for eclipse in eclipseEvents {
            let days = eclipse.daysFrom(todayString)
            if days > 0 && days <= 60 {
                events.append(UpcomingEvent(
                    name: eclipse.displayName,
                    dateString: eclipse.dateString,
                    daysAway: days,
                    type: .eclipse
                ))
            }
        }

        upcomingEvents = events.sorted { $0.daysAway < $1.daysAway }
    }

    // MARK: - Horoscope

    /// Compute today's horoscope from birth data + current transits.
    private func loadHoroscope() {
        guard let natal = natalChart else {
            dailyHoroscope = nil
            return
        }

        let targetDate = displayDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: targetDate)

        // Check in-memory cache (same day + same rashi = same reading)
        let cacheKey = "\(dateString)-\(natal.birthRashi.rawValue)"
        if let cached = horoscopeCache[cacheKey] {
            dailyHoroscope = cached
            return
        }

        // Compute today's graha snapshot
        let jd = VedicCalculator.shared.julianDay(from: targetDate)
        let todaySnapshot = PanchangCalculator.computeGrahaSnapshot(julianDay: jd)

        // Generate reading
        let horoscope = HoroscopeEngine.generateReading(
            natalChart: natal,
            todaySnapshot: todaySnapshot,
            date: targetDate,
            timezoneIdentifier: currentCity.timezoneIdentifier
        )

        dailyHoroscope = horoscope
        horoscopeCache[cacheKey] = horoscope
    }

    /// Save birth data, recompute natal chart and horoscope, reschedule notifications.
    func saveBirthData(_ data: BirthData) {
        data.save()
        birthData = data
        natalChart = NatalChart.compute(from: data)
        horoscopeCache.removeAll()
        loadHoroscope()
        scheduleNotificationReschedule()
    }

    /// Clear birth data and remove horoscope.
    func clearBirthData() {
        BirthData.clear()
        birthData = nil
        natalChart = nil
        dailyHoroscope = nil
        horoscopeCache.removeAll()
        scheduleNotificationReschedule()
    }

    // MARK: - Location

    func requestLocation() {
        guard !isResolvingLocation else { return }
        isResolvingLocation = true

        locationResolutionTimeoutTask?.cancel()
        locationResolutionTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard let self, !Task.isCancelled, self.isResolvingLocation else { return }
            self.selectCity(UserCity.popularCities[0])
        }

        locationManager.requestPermission { [weak self] authorized in
            Task { @MainActor in
                guard let self else { return }
                self.isLocationAuthorized = authorized
                guard authorized else {
                    self.finishLocationResolution()
                    return
                }

                self.locationManager.getCurrentLocation { location in
                    Task { @MainActor in
                        await self.resolveLocationToCity(location)
                    }
                }
            }
        }
    }

    /// Reverse-geocode a GPS location to a real city name.
    /// Falls back to nearest popular city if geocoding fails (e.g. offline).
    private func resolveLocationToCity(_ location: CLLocation) async {
        guard isResolvingLocation else { return }

        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let name = placemark.locality
                    ?? placemark.name
                    ?? placemark.administrativeArea
                    ?? "Unknown"
                let country = placemark.isoCountryCode ?? "??"
                let tz = placemark.timeZone ?? TimeZone.current

                let city = UserCity(
                    name: name,
                    country: country,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    timezoneIdentifier: tz.identifier
                )
                selectCity(city)
                return
            }
        } catch {
            // Geocoding failed (no network, etc.) — fall through to nearest popular city
        }

        // Offline fallback: snap to nearest popular city
        let nearest = UserCity.nearest(to: location)
        selectCity(nearest)
        // Set error after selectCity (which clears locationError) so the message persists
        locationError = "Could not determine exact location. Using nearest city."
    }

    func selectCity(_ city: UserCity) {
        locationError = nil
        currentCity = city
        persistCity(city)
        loadData()
        tick() // Immediately refresh time displays for new timezone
        scheduleNotificationReschedule()
        finishLocationResolution()
    }

    private func finishLocationResolution() {
        isResolvingLocation = false
        locationResolutionTimeoutTask?.cancel()
        locationResolutionTimeoutTask = nil
    }

    private func persistCity(_ city: UserCity) {
        let ud = UserDefaults.standard
        ud.set(city.name, forKey: "city.name")
        ud.set(city.country, forKey: "city.country")
        ud.set(city.latitude, forKey: "city.latitude")
        ud.set(city.longitude, forKey: "city.longitude")
        ud.set(city.timezoneIdentifier, forKey: "city.timezoneIdentifier")
    }

    // MARK: - Onboarding

    func saveOnboardingNotificationPreferences(
        sunrise: Bool, sunset: Bool, rahuKalam: Bool, abhijit: Bool, brahma: Bool
    ) {
        notifSunrise = sunrise
        notifSunset = sunset
        notifRahuKalamWarning = rahuKalam
        notifAbhijitMuhurta = abhijit
        notifBrahmaMuhurta = brahma
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        let ud = UserDefaults.standard
        ud.set(false, forKey: "hasCompletedOnboarding")
        ud.removeObject(forKey: "city.name")
        ud.removeObject(forKey: "city.country")
        ud.removeObject(forKey: "city.latitude")
        ud.removeObject(forKey: "city.longitude")
        ud.removeObject(forKey: "city.timezoneIdentifier")

        currentCity = UserCity.popularCities[0]
        loadData()
        tick()
        finishLocationResolution()
    }

    // MARK: - Notification Scheduling

    /// Debounced reschedule — cancels any pending reschedule and waits 500ms.
    /// Prevents N reschedule calls when the user rapidly toggles preferences.
    func scheduleNotificationReschedule() {
        guard didFinishInit else { return }
        notificationRescheduleTask?.cancel()
        notificationRescheduleTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await rescheduleNotifications()
        }
    }

    /// Collects 7 days of panchang data + preferences and calls the notification service.
    func rescheduleNotifications() async {
        // Compute 7 days of panchang dynamically
        let calendar = Calendar.current
        let days: [DailyPanchang] = (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: Date()) else { return nil }
            return PanchangCalculator.panchang(for: date, city: currentCity)
        }

        // Collect navratri data for each day
        var navratriDays: [String: NavratriDay] = [:]
        let year = Calendar.current.component(.year, from: Date())
        let periods = FestivalEngine.navratriPeriods(forYear: year)
        for day in days {
            for period in periods {
                if let dayNum = period.dayNumber(for: day.dateString) {
                    navratriDays[day.dateString] = NavratriDay.goddesses[dayNum - 1]
                    break
                }
            }
        }

        // Pre-compute 7 days of horoscope theme statements for notifications
        var horoscopeThemes: [String: String] = [:]
        if let natal = natalChart, notifHoroscope {
            for day in days {
                let jd = VedicCalculator.shared.julianDay(from: day.solar.sunrise)
                let snapshot = PanchangCalculator.computeGrahaSnapshot(julianDay: jd)
                let reading = HoroscopeEngine.generateReading(
                    natalChart: natal,
                    todaySnapshot: snapshot,
                    date: day.solar.sunrise,
                    timezoneIdentifier: currentCity.timezoneIdentifier
                )
                horoscopeThemes[day.dateString] = reading.themeStatement
            }
        }

        let input = NotificationService.ScheduleInput(
            days: days,
            navratriDays: navratriDays,
            eclipses: eclipseEvents,
            city: currentCity,
            dailySummary: notifDailySummary,
            sunrise: notifSunrise,
            sunset: notifSunset,
            rahuKalam: notifRahuKalamWarning,
            abhijitMuhurta: notifAbhijitMuhurta,
            brahmaMuhurta: notifBrahmaMuhurta,
            navratri: notifNavratriMorning,
            eclipse: notifEclipseAlert,
            minutesBefore: notifMinutesBefore,
            horoscope: notifHoroscope && natalChart != nil,
            horoscopeThemes: horoscopeThemes
        )

        await notificationService.reschedule(input)
    }

    /// Checks current notification authorization status (call on each foreground).
    func checkNotificationAuthorization() async {
        notificationsAuthorized = await notificationService.isAuthorized()
    }

    // MARK: - Tithi Change Pill

    /// Dismiss the tithi change pill and update UserDefaults so it won't reappear.
    func dismissTithiChange() {
        tithiChangedMessage = nil
        if let currentTithi = todayPanchang?.tithi.displayName {
            UserDefaults.standard.set(currentTithi, forKey: "lastSeenTithi")
        }
    }

    // MARK: - App Usage Tracking

    /// Records today as a usage day for milestone-based review prompting.
    func recordUsageDay() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        let ud = UserDefaults.standard
        var days = Set(ud.stringArray(forKey: "usageDays") ?? [])
        let isNewDay = !days.contains(today)
        days.insert(today)
        ud.set(Array(days), forKey: "usageDays")

        // Only increment hint counter once per calendar day (not every foreground)
        if isNewDay {
            hintLaunchCount += 1
            ud.set(hintLaunchCount, forKey: "hintLaunchCount")
        }
    }

    /// True when user has used the app on 7+ distinct days and hasn't been prompted yet.
    var shouldRequestReview: Bool {
        let ud = UserDefaults.standard
        let days = ud.stringArray(forKey: "usageDays") ?? []
        return days.count >= 7 && !ud.bool(forKey: "hasRequestedReview")
    }

    /// Marks that the StoreKit review prompt has been shown.
    func markReviewRequested() {
        UserDefaults.standard.set(true, forKey: "hasRequestedReview")
    }
}

// MARK: - TimePeriod Equatable
extension TimePeriod: Equatable {}

// MARK: - Placeholder Location Manager

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var permissionCallback: ((Bool) -> Void)?
    private var locationCallback: ((CLLocation) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        permissionCallback = completion
        manager.requestWhenInUseAuthorization()
    }

    func getCurrentLocation(completion: @escaping (CLLocation) -> Void) {
        locationCallback = completion
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationCallback?(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Fallback: use first popular city's coordinates (no hardcoded values)
        let fallback = UserCity.popularCities[0]
        locationCallback?(CLLocation(latitude: fallback.latitude, longitude: fallback.longitude))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorized = manager.authorizationStatus == .authorizedWhenInUse ||
                         manager.authorizationStatus == .authorizedAlways
        permissionCallback?(authorized)
    }
}

// MARK: - Placeholder Data Store

class PanchangDataStore {
    /// In the real app, this reads from bundled JSON files
    /// For now, returns mock data to enable UI development

    func eclipses(for city: UserCity) -> [EclipseEvent] {
        // Mock eclipse data — March 3, 2026 Total Lunar Eclipse
        // Real data will come from bundled JSON generated by Python scripts
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: city.timezoneIdentifier)

        // March 3, 2026 Total Lunar Eclipse — times approximate for East Coast US
        let eclipseDate = "2026-03-03"
        let baseDateStr = "\(eclipseDate) "

        // Compute whether this city can see the eclipse (rough check: moon above horizon)
        // For East Coast US, moon sets around 6:40 AM — eclipse starts around 3:30 AM
        let isEastCoast = city.timezoneIdentifier.contains("New_York") || city.timezoneIdentifier.contains("Toronto")
        let isIndian = city.timezoneIdentifier.contains("Kolkata")

        let penumbralBegin = formatter.date(from: baseDateStr + "03:30")
        let partialBegin = formatter.date(from: baseDateStr + (isIndian ? "14:02" : "04:32"))
        let totalBegin = formatter.date(from: baseDateStr + (isIndian ? "15:04" : "05:04"))
        let maximum = formatter.date(from: baseDateStr + (isIndian ? "15:34" : "05:34"))!
        let totalEnd = formatter.date(from: baseDateStr + (isIndian ? "16:04" : "06:04"))
        let partialEnd = formatter.date(from: baseDateStr + (isIndian ? "17:17" : "07:17"))
        let penumbralEnd = formatter.date(from: baseDateStr + (isIndian ? "18:17" : "08:17"))

        let lunarEclipse = EclipseEvent(
            body: .lunar,
            type: .total,
            dateString: eclipseDate,
            maxEclipseTime: maximum,
            magnitude: 1.151,
            lunarContactTimes: LunarEclipseContactTimes(
                penumbralBegin: penumbralBegin,
                partialBegin: partialBegin,
                totalBegin: totalBegin,
                maximum: maximum,
                totalEnd: totalEnd,
                partialEnd: partialEnd,
                penumbralEnd: penumbralEnd
            ),
            solarContactTimes: nil,
            moonBelowHorizon: isEastCoast,  // Moon sets during eclipse for East Coast
            mythologyNote: "Rahu swallows Chandra — the shadow of the Earth envelops the Moon, turning it a deep blood red. This is a powerful time for mantra japa and meditation."
        )

        // September 21, 2026 — Partial Solar Eclipse
        let solarDate = "2026-09-21"
        let solarBaseDateStr = "\(solarDate) "
        let solarMax = formatter.date(from: solarBaseDateStr + "12:00")!

        let solarEclipse = EclipseEvent(
            body: .solar,
            type: .partial,
            dateString: solarDate,
            maxEclipseTime: solarMax,
            magnitude: 0.326,
            lunarContactTimes: nil,
            solarContactTimes: SolarEclipseContactTimes(
                firstContact: formatter.date(from: solarBaseDateStr + "11:00"),
                secondContact: nil,
                maximum: solarMax,
                thirdContact: nil,
                fourthContact: formatter.date(from: solarBaseDateStr + "13:00")
            ),
            moonBelowHorizon: false,
            mythologyNote: "Rahu swallows Surya — the Moon's shadow crosses the face of the Sun. Chant the Gayatri Mantra and Surya mantras for protection."
        )

        return [lunarEclipse, solarEclipse]
    }

    // Mock panchang methods removed — PanchangCalculator now computes everything dynamically.
}
