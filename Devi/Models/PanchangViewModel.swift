// MARK: - Models/PanchangViewModel.swift
// The single ViewModel that drives the entire app

import SwiftUI
import CoreLocation
import Combine

@MainActor
class PanchangViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var currentCity: UserCity = UserCity.defaults[0]
    @Published var todayPanchang: DailyPanchang?
    @Published var theme: DeviTheme = DeviTheme.forPeriod(.morning)
    @Published var timePeriod: TimePeriod = .morning
    @Published var currentNavratriDay: NavratriDay?
    @Published var upcomingEvents: [UpcomingEvent] = []
    @Published var countdownText: String = "00:00:00"
    @Published var countdownLabel: String = "SUNRISE IN"
    @Published var currentTimeText: String = "6:00 PM"
    @Published var isLocationAuthorized: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    
    // MARK: - Private
    
    private let locationManager = LocationManager()
    private var timerCancellable: AnyCancellable?
    private let dataStore = PanchangDataStore()
    
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
        startTimer()
    }
    
    // MARK: - Timer (updates every second)
    
    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func tick() {
        updateCurrentTime()
        updateCountdown()
        updateThemeIfNeeded()
    }
    
    private func updateCurrentTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        currentTimeText = formatter.string(from: Date())
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
        } else {
            // After sunset — would need tomorrow's sunrise
            // For v1, show time until midnight or load next day
            label = "NEXT SUNRISE"
            countdownLabel = label
            countdownText = "--:--:--"
            return
        }
        
        let remaining = target.timeIntervalSince(now)
        guard remaining > 0 else {
            countdownText = "00:00:00"
            countdownLabel = label
            return
        }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        
        countdownText = String(format: "%d:%02d:%02d", hours, minutes, seconds)
        countdownLabel = label
    }
    
    private func updateThemeIfNeeded() {
        guard let solar = todayPanchang?.solar else { return }
        let newPeriod = TimePeriod.current(sunrise: solar.sunrise, sunset: solar.sunset)
        if newPeriod != timePeriod {
            withAnimation(.easeInOut(duration: 30)) { // 30s gradient transition
                timePeriod = newPeriod
                theme = DeviTheme.forPeriod(newPeriod)
            }
        }
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        // Load panchang for today from bundled data
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        todayPanchang = dataStore.panchang(for: todayString, city: currentCity)
        
        // Check Navratri
        checkNavratri(dateString: todayString)
        
        // Load upcoming events
        loadUpcomingEvents(from: todayString)
        
        // Set initial theme
        if let solar = todayPanchang?.solar {
            timePeriod = TimePeriod.current(sunrise: solar.sunrise, sunset: solar.sunset)
            theme = DeviTheme.forPeriod(timePeriod)
        }
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
    
    private func loadUpcomingEvents(from dateString: String) {
        // Simplified — in real app, scan next 30 days of bundled data
        upcomingEvents = [
            UpcomingEvent(name: "Ekadashi", dateString: "2026-03-25", daysAway: 6, type: .fasting),
            UpcomingEvent(name: "Purnima", dateString: "2026-03-29", daysAway: 10, type: .fasting),
            UpcomingEvent(name: "Ram Navami", dateString: "2026-03-27", daysAway: 8, type: .festival),
        ]
    }
    
    // MARK: - Location
    
    func requestLocation() {
        locationManager.requestPermission { [weak self] authorized in
            self?.isLocationAuthorized = authorized
            if authorized {
                self?.locationManager.getCurrentLocation { location in
                    let nearest = UserCity.nearest(to: location)
                    self?.currentCity = nearest
                    self?.loadData()
                }
            }
        }
    }
    
    func selectCity(_ city: UserCity) {
        currentCity = city
        loadData()
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
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
        // Fallback to default city
        locationCallback?(CLLocation(latitude: 40.7128, longitude: -74.0060))
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
    func panchang(for dateString: String, city: UserCity) -> DailyPanchang {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // Mock sunrise/sunset (replace with real bundled data)
        let sunrise = calendar.date(bySettingHour: 6, minute: 18, second: 0, of: today)!
        let sunset = calendar.date(bySettingHour: 18, minute: 42, second: 0, of: today)!
        
        return DailyPanchang(
            dateString: dateString,
            tithi: Tithi(
                number: 5,
                name: "Panchami",
                paksha: .shukla,
                endTime: calendar.date(bySettingHour: 22, minute: 15, second: 0, of: today)!
            ),
            nakshatra: Nakshatra(
                number: 3,
                name: "Krittika",
                ruler: "Sun",
                deity: "Agni",
                endTime: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: today)!
            ),
            yoga: Yoga(
                number: 22,
                name: "Shubha",
                endTime: calendar.date(bySettingHour: 16, minute: 45, second: 0, of: today)!
            ),
            karana: Karana(
                number: 9,
                name: "Bava",
                endTime: calendar.date(bySettingHour: 11, minute: 20, second: 0, of: today)!
            ),
            solar: SolarData(
                sunrise: sunrise,
                sunset: sunset,
                moonrise: calendar.date(bySettingHour: 22, minute: 42, second: 0, of: today),
                moonset: calendar.date(bySettingHour: 8, minute: 15, second: 0, of: today)
            ),
            timeWindows: [
                TimeWindow(type: .brahmaMuhurta, 
                          start: calendar.date(bySettingHour: 4, minute: 42, second: 0, of: today)!,
                          end: calendar.date(bySettingHour: 5, minute: 30, second: 0, of: today)!),
                TimeWindow(type: .abhijitMuhurta,
                          start: calendar.date(bySettingHour: 11, minute: 42, second: 0, of: today)!,
                          end: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today)!),
                TimeWindow(type: .rahuKalam,
                          start: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: today)!,
                          end: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!),
                TimeWindow(type: .gulikaKalam,
                          start: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!,
                          end: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: today)!),
            ],
            lunarMonth: "Phalguna",
            festivals: []
        )
    }
}
