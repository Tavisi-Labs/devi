// MARK: - DeviTests/PanchangViewModelTests.swift
// Tests for PanchangViewModel: tithi change detection, hint counter, cosmic retry, location error.

import XCTest
import CoreLocation
@testable import Devi

@MainActor
final class PanchangViewModelTests: XCTestCase {

    // MARK: - Setup / Teardown

    /// Keys we write during tests — cleaned up after each run to prevent pollution.
    private let testKeys = [
        "lastSeenTithi", "hintLaunchCount", "usageDays",
        "city.name", "city.country", "city.latitude", "city.longitude", "city.timezoneIdentifier",
        "hasCompletedOnboarding", "fontScale", "themeStyle", "appearanceMode",
        "notif.dailySummary", "notif.sunrise", "notif.sunset", "notif.rahuKalam",
        "notif.abhijit", "notif.brahma", "notif.navratri", "notif.eclipse", "notif.minutesBefore",
        "notif.horoscope", "hasRequestedReview", "hasDiscoveredPageNavigation",
        DaySnapshotStore.daySnapshotStoreKey
    ]

    override func tearDown() {
        super.tearDown()
        let ud = UserDefaults.standard
        for key in testKeys {
            ud.removeObject(forKey: key)
        }
    }

    // MARK: - Tithi Changed Message

    func testTithiChangedMessage_detectsPakshaTransition() {
        // Simulate last-seen tithi stored from a previous session
        UserDefaults.standard.set("Shukla Panchami", forKey: "lastSeenTithi")

        let vm = PanchangViewModel()

        // The VM loads data in init() which sets todayPanchang.
        // If the current tithi differs from "Shukla Panchami", a message should appear.
        guard let currentTithi = vm.todayPanchang?.tithi.displayName else {
            // No panchang loaded (shouldn't happen with VedicCalculator initialized)
            return
        }

        if currentTithi != "Shukla Panchami" {
            XCTAssertNotNil(vm.tithiChangedMessage, "Should detect tithi change")
            XCTAssertTrue(vm.tithiChangedMessage?.contains(currentTithi) == true,
                          "Message should mention the new tithi displayName")
        } else {
            XCTAssertNil(vm.tithiChangedMessage, "No change = no message")
        }
    }

    func testTithiChangedMessage_usesDisplayNameNotBareName() {
        // Store a bare name that matches the current tithi name but not the displayName
        // This tests that displayName (with paksha) is used for comparison
        let vm = makeVM()
        guard let tithi = vm.todayPanchang?.tithi else { return }

        // If we store just the bare name without paksha, it should NOT match displayName
        let bareNameOnly = tithi.name  // e.g., "Panchami"
        let displayName = tithi.displayName  // e.g., "Shukla Panchami"

        // They should differ (displayName includes paksha prefix)
        XCTAssertNotEqual(bareNameOnly, displayName,
                          "displayName should include paksha prefix")
    }

    func testTithiChangedMessage_nilWhenSameTithi() {
        let vm = makeVM()
        guard let currentDisplay = vm.todayPanchang?.tithi.displayName else { return }

        // Store the same tithi that's current
        UserDefaults.standard.set(currentDisplay, forKey: "lastSeenTithi")

        // Reload — should detect no change
        vm.loadData()
        XCTAssertNil(vm.tithiChangedMessage, "Same tithi should produce no message")
    }

    func testTithiChangedMessage_nilWhenNoLastSeen() {
        // First launch — no "lastSeenTithi" stored
        UserDefaults.standard.removeObject(forKey: "lastSeenTithi")

        let vm = PanchangViewModel()
        XCTAssertNil(vm.tithiChangedMessage, "First launch should not show change message")
    }

    // MARK: - Hint Launch Count

    func testHintLaunchCount_incrementsOncePerDay() {
        UserDefaults.standard.set(0, forKey: "hintLaunchCount")
        UserDefaults.standard.removeObject(forKey: "usageDays")

        let vm = PanchangViewModel()
        let initialCount = vm.hintLaunchCount

        // First call today — should increment
        vm.recordUsageDay()
        XCTAssertEqual(vm.hintLaunchCount, initialCount + 1,
                       "First recordUsageDay of the day should increment")

        // Second call same day — should NOT increment
        vm.recordUsageDay()
        XCTAssertEqual(vm.hintLaunchCount, initialCount + 1,
                       "Repeated recordUsageDay same day should not increment again")
    }

    func testShouldShowHints_trueForFirstThreeLaunches() {
        UserDefaults.standard.set(0, forKey: "hintLaunchCount")
        let vm = PanchangViewModel()

        vm.hintLaunchCount = 0
        XCTAssertTrue(vm.shouldShowHints, "Should show hints at launch 0")

        vm.hintLaunchCount = 2
        XCTAssertTrue(vm.shouldShowHints, "Should show hints at launch 2")

        vm.hintLaunchCount = 3
        XCTAssertFalse(vm.shouldShowHints, "Should NOT show hints at launch 3 (first 3 = 0,1,2)")
    }

    // MARK: - Cosmic Signature Retry

    func testRetryCosmicSignature_clearsErrorAndStartsLoading() {
        let vm = makeVM()

        // Simulate an error state
        vm.cosmicSignatureError = true
        vm.isLoadingSignature = false

        // Retry should clear error and start loading
        vm.retryCosmicSignature()

        XCTAssertFalse(vm.cosmicSignatureError, "Retry should clear error flag")
        XCTAssertTrue(vm.isLoadingSignature, "Retry should set loading state")
    }

    // MARK: - Location Error

    func testSelectCity_clearsLocationError() {
        let vm = makeVM()

        // Simulate a location error
        vm.locationError = "Could not determine exact location."
        XCTAssertNotNil(vm.locationError)

        // Selecting a city should clear it
        let mumbai = UserCity.popularCities.first(where: { $0.name == "Mumbai" })!
        vm.selectCity(mumbai)

        XCTAssertNil(vm.locationError, "selectCity should clear locationError")
        XCTAssertEqual(vm.currentCity.name, "Mumbai")
    }

    func testRequestLocation_permissionDeniedShowsManualFallbackError() async {
        let vm = makeVM(
            locationManager: LocationManagerStub(permissionGranted: false, locationResult: nil)
        )

        vm.requestLocation()
        await waitUntil {
            !vm.isResolvingLocation && vm.locationError != nil
        }

        XCTAssertFalse(vm.isResolvingLocation)
        XCTAssertFalse(vm.locationResolutionSucceeded)
        XCTAssertTrue(vm.locationError?.contains("Location access is turned off") == true)
    }

    func testRequestLocation_timeoutDoesNotSilentlySnapToNewYork() async {
        let originalCity = UserCity(name: "Chicago", country: "US", latitude: 41.8781, longitude: -87.6298, timezoneIdentifier: "America/Chicago")
        let vm = makeVM(
            locationManager: LocationManagerStub(permissionGranted: true, locationResult: nil),
            locationResolutionTimeout: .milliseconds(10)
        )
        vm.selectCity(originalCity)

        vm.requestLocation()
        await waitUntil {
            !vm.isResolvingLocation && vm.locationError != nil
        }

        XCTAssertEqual(vm.currentCity.name, "Chicago")
        XCTAssertFalse(vm.locationResolutionSucceeded)
        XCTAssertTrue(vm.locationError?.contains("couldn’t determine your location") == true)
    }

    func testRequestLocation_reverseGeocodeFailureFallsBackToNearestSupportedCity() async {
        let dc = CLLocation(latitude: 38.9072, longitude: -77.0369)
        let vm = makeVM(
            locationManager: LocationManagerStub(permissionGranted: true, locationResult: .success(dc)),
            reverseGeocode: { _ in throw CLError(.geocodeFoundNoResult) }
        )

        vm.requestLocation()
        await waitUntil {
            vm.locationResolutionSucceeded && vm.locationResolutionMessage != nil
        }

        XCTAssertEqual(vm.currentCity.name, "Washington")
        XCTAssertTrue(vm.locationResolutionSucceeded)
        XCTAssertTrue(vm.isUsingApproximateLocation)
        XCTAssertEqual(vm.locationResolutionMessage, "Using nearest supported city: Washington.")
        XCTAssertNil(vm.locationError)
    }

    func testRequestLocation_dcCoordinateResolvesToWashingtonInsteadOfNewYork() async {
        let dc = CLLocation(latitude: 38.9072, longitude: -77.0369)
        let vm = makeVM(
            locationManager: LocationManagerStub(permissionGranted: true, locationResult: .success(dc)),
            reverseGeocode: { _ in
                ReverseGeocodedLocation(
                    name: "Washington",
                    country: "US",
                    timezoneIdentifier: "America/New_York"
                )
            }
        )

        vm.requestLocation()
        await waitUntil {
            vm.locationResolutionSucceeded && vm.locationResolutionMessage != nil
        }

        XCTAssertEqual(vm.currentCity.name, "Washington")
        XCTAssertNotEqual(vm.currentCity.name, "New York")
        XCTAssertTrue(vm.locationResolutionSucceeded)
        XCTAssertEqual(vm.locationResolutionMessage, "Detected from your device.")
        XCTAssertFalse(vm.isUsingApproximateLocation)
    }

    // MARK: - Day Archive Pre-Onboarding Leak (regression for duplicate-date rows)
    //
    // Before the fix, init() defaulted currentCity to popularCities[0] (New York)
    // and immediately called loadData() → recordDaySnapshot(), writing a snapshot
    // under "New York" before the user had picked any city. When the user then
    // selected (e.g.) Mumbai, a second snapshot for the same date was written.
    // The archive sheet rendered both rows with the same date label (city is
    // hidden in the header) — visible as "duplicate dates."
    //
    // The three tests below pin the gate behavior:
    //  1. Pre-onboarding writes are no-ops.
    //  2. completeOnboarding() clears any pre-existing leaked snapshots.
    //  3. Returning users (hasCompletedOnboarding already true) keep recording.

    func testRecordDaySnapshot_isNoOpBeforePreOnboarding() {
        // Fresh state — testKeys cleanup ran in tearDown. No persisted city,
        // hasCompletedOnboarding == false. Construct VM, which runs init → loadData.
        let vm = makeVM()

        XCTAssertFalse(vm.hasCompletedOnboarding,
                       "Test fixture invariant: VM should start pre-onboarding.")
        XCTAssertEqual(vm.allDaySnapshots().count, 0,
                       "Pre-onboarding loadData() must not record any snapshots — " +
                       "doing so leaks a stray entry under the fallback city the " +
                       "user never explicitly chose.")

        // Force a second loadData() to confirm the gate also holds on subsequent calls.
        vm.loadData()
        XCTAssertEqual(vm.allDaySnapshots().count, 0,
                       "Repeated pre-onboarding loadData() calls must remain no-ops.")
    }

    func testCompleteOnboarding_clearsPreOnboardingSnapshots() {
        // Construct the VM first. makeVM() wipes UserDefaults (including the
        // snapshot store key), so any leftover snapshots from a prior test
        // suite are gone. The VM's init runs loadData(), which under the new
        // gate is a no-op pre-onboarding — so the store starts truly empty.
        let vm = makeVM()
        XCTAssertEqual(vm.allDaySnapshots().count, 0,
                       "Test fixture invariant: VM should see an empty store " +
                       "after construction (gate prevents init writes pre-onboarding).")

        // Now seed two stray snapshots directly via a peer DaySnapshotStore.
        // Both stores read/write the same UserDefaults key, so the VM's
        // private store sees the seeded data on next access.
        let peerStore = DaySnapshotStore()
        let strayA = DaySnapshot(
            dateString: "2026-04-26", cityName: "New York",
            themeStatement: nil, supportingText: nil, categorySummaries: [:],
            mantraSanskrit: nil, mantraTranslation: nil,
            tithiDisplayName: "Shukla Dashami", nakshatraName: "Magha",
            yogaName: "Vyatipata", festivals: [],
            cosmicSignature: nil, ritualCompleted: false
        )
        let strayB = DaySnapshot(
            dateString: "2026-04-27", cityName: "New York",
            themeStatement: nil, supportingText: nil, categorySummaries: [:],
            mantraSanskrit: nil, mantraTranslation: nil,
            tithiDisplayName: "Shukla Ekadashi", nakshatraName: "Purva Phalguni",
            yogaName: "Variyana", festivals: [],
            cosmicSignature: nil, ritualCompleted: false
        )
        peerStore.record(strayA)
        peerStore.record(strayB)
        XCTAssertEqual(vm.allDaySnapshots().count, 2,
                       "VM must see the seeded stray snapshots before completion.")

        // Completing onboarding should wipe the stray snapshots.
        vm.completeOnboarding()
        XCTAssertEqual(vm.allDaySnapshots().count, 0,
                       "completeOnboarding must clear pre-onboarding stray snapshots.")
        XCTAssertTrue(vm.hasCompletedOnboarding)
    }

    func testReturningUser_recordsSnapshotsImmediately() {
        // Pre-set onboarding-complete state plus a persisted city so init() takes
        // the returning-user branch.
        let ud = UserDefaults.standard
        ud.set(true, forKey: "hasCompletedOnboarding")
        ud.set("Delhi", forKey: "city.name")
        ud.set("IN", forKey: "city.country")
        ud.set(28.7041, forKey: "city.latitude")
        ud.set(77.1025, forKey: "city.longitude")
        ud.set("Asia/Kolkata", forKey: "city.timezoneIdentifier")

        // Construct VM directly (bypass makeVM, which would clear the UserDefaults
        // we just set as part of its testKeys reset).
        let vm = PanchangViewModel()

        XCTAssertTrue(vm.hasCompletedOnboarding,
                      "Returning user fixture: flag should be loaded from UserDefaults.")
        XCTAssertEqual(vm.currentCity.name, "Delhi",
                       "Returning user fixture: persisted city should be loaded.")

        // init's loadData() should have recorded today's snapshot for Delhi.
        let snapshots = vm.allDaySnapshots()
        XCTAssertGreaterThanOrEqual(snapshots.count, 1,
                                    "Returning user must record at least today's snapshot on init.")
        XCTAssertTrue(snapshots.allSatisfy { $0.cityName == "Delhi" },
                      "All recorded snapshots must be under the user's actual city.")
    }

    func testMarkPageNavigationDiscovered_persistsAndHidesHint() {
        let vm = makeVM()

        XCTAssertTrue(vm.shouldShowPageNavigationHint)
        vm.markPageNavigationDiscovered()

        XCTAssertFalse(vm.shouldShowPageNavigationHint)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasDiscoveredPageNavigation"))
    }

    // MARK: - Graha Named Lookup

    func testGrahaNamed_englishName() {
        XCTAssertEqual(Graha.named("Sun")?.color, Graha.sun.color)
        XCTAssertEqual(Graha.named("Moon")?.color, Graha.moon.color)
        XCTAssertEqual(Graha.named("Saturn")?.color, Graha.saturn.color)
    }

    func testGrahaNamed_sanskritName() {
        XCTAssertEqual(Graha.named("Surya"), .sun)
        XCTAssertEqual(Graha.named("Chandra"), .moon)
        XCTAssertEqual(Graha.named("Mangala"), .mars)
        XCTAssertEqual(Graha.named("Budha"), .mercury)
        XCTAssertEqual(Graha.named("Guru"), .jupiter)
        XCTAssertEqual(Graha.named("Shukra"), .venus)
        XCTAssertEqual(Graha.named("Shani"), .saturn)
    }

    func testGrahaNamed_caseInsensitive() {
        XCTAssertEqual(Graha.named("sun"), .sun)
        XCTAssertEqual(Graha.named("MOON"), .moon)
        XCTAssertEqual(Graha.named("surya"), .sun)
        XCTAssertEqual(Graha.named("chandra"), .moon)
    }

    func testGrahaNamed_unknownReturnsNil() {
        XCTAssertNil(Graha.named("Pluto"))
        XCTAssertNil(Graha.named(""))
    }

    // MARK: - Helpers

    /// Creates a fresh VM with clean UserDefaults state.
    private func makeVM(
        locationManager: any LocationManaging = LocationManagerStub(permissionGranted: true, locationResult: nil),
        reverseGeocode: @escaping (CLLocation) async throws -> ReverseGeocodedLocation = { _ in
            ReverseGeocodedLocation(name: "New York", country: "US", timezoneIdentifier: "America/New_York")
        },
        locationResolutionTimeout: Duration = .seconds(10)
    ) -> PanchangViewModel {
        let ud = UserDefaults.standard
        for key in testKeys {
            ud.removeObject(forKey: key)
        }
        return PanchangViewModel(
            locationManager: locationManager,
            reverseGeocode: reverseGeocode,
            locationResolutionTimeout: locationResolutionTimeout
        )
    }

    private func waitUntil(
        timeout: Duration = .seconds(2),
        pollInterval: Duration = .milliseconds(25),
        condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if await condition() {
                return
            }
            try? await Task.sleep(for: pollInterval)
        }
    }
}

private struct LocationManagerStub: LocationManaging {
    let permissionGranted: Bool
    let locationResult: Result<CLLocation, Error>?

    func requestPermission(completion: @escaping (Bool) -> Void) {
        completion(permissionGranted)
    }

    func getCurrentLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        if let locationResult {
            completion(locationResult)
        }
    }
}
