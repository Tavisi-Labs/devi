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
    @Published var samvathsaraName: String = ""
    @Published var todayFestivals: [String] = []

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
    private var lastCacheCity: String = ""

    // MARK: - Computed

    var sunProgress: Double {
        todayPanchang?.solar.sunProgress ?? 0.5
    }

    var isDaytime: Bool {
        todayPanchang?.solar.isDaytime ?? true
    }

    var activeTimeWindows: [TimeWindow] {
        todayPanchang?.timeWindows ?? []
    }

    var isNavratriActive: Bool {
        currentNavratriDay != nil
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
                theme = DeviTheme.forPeriod(newPeriod)
            }
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
        let todayString = dateFormatter.string(from: Date())

        // Compute today's panchang dynamically via Swiss Ephemeris
        todayPanchang = cachedPanchang(for: Date(), dateString: todayString)

        // Compute tomorrow's sunrise for after-sunset countdown
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
            let tomorrowString = dateFormatter.string(from: tomorrow)
            tomorrowSunrise = cachedPanchang(for: tomorrow, dateString: tomorrowString).solar.sunrise
        }

        // Check Navratri
        checkNavratri(dateString: todayString)

        // Load eclipse data (still from mock data store)
        loadEclipseData(todayString: todayString)

        // Load upcoming events
        loadUpcomingEvents(from: todayString)

        // Samvathsara year name (60-year Jupiter cycle)
        samvathsaraName = PanchangCalculator.samvathsaraName(for: Date())

        // Today's festivals (for banner display)
        todayFestivals = PanchangCalculator.festivals(for: todayString)
        // Also check if today is Purnima for Satya Narayana Pooja
        if todayPanchang?.tithi.name == "Purnima" && !todayFestivals.contains("Satya Narayana Pooja") {
            todayFestivals.append("Satya Narayana Pooja")
        }

        // Set initial theme
        if let solar = todayPanchang?.solar {
            timePeriod = TimePeriod.current(sunrise: solar.sunrise, sunset: solar.sunset)
            theme = DeviTheme.forPeriod(timePeriod)
        }
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
        let periods = [NavratriPeriod.chaitraNavratri2026, NavratriPeriod.sharadNavratri2026]
        for period in periods {
            if let dayNum = period.dayNumber(for: dateString) {
                currentNavratriDay = NavratriDay.chaitraNavratri2026[dayNum - 1]
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
    }

    func selectCity(_ city: UserCity) {
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
        let periods = [NavratriPeriod.chaitraNavratri2026, NavratriPeriod.sharadNavratri2026]
        for day in days {
            for period in periods {
                if let dayNum = period.dayNumber(for: day.dateString) {
                    navratriDays[day.dateString] = NavratriDay.chaitraNavratri2026[dayNum - 1]
                    break
                }
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
            minutesBefore: notifMinutesBefore
        )

        await notificationService.reschedule(input)
    }

    /// Checks current notification authorization status (call on each foreground).
    func checkNotificationAuthorization() async {
        notificationsAuthorized = await notificationService.isAuthorized()
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
