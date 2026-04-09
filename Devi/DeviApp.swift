// MARK: - DeviApp.swift
// App entry point — routes between onboarding and main view

import SwiftUI
import UserNotifications

@main
struct DeviApp: App {
    @StateObject private var vm = PanchangViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var splashFinished = false
    @State private var notificationDelegate = DeviNotificationDelegate()
    @State private var ritualColorSchemeActive = false

    init() {
        configureUITestState()

        // Initialize Swiss Ephemeris singleton — sets Lahiri ayanamsa and ephemeris path.
        // Must happen before any panchang computation. The singleton is lazy, so
        // accessing .shared triggers init() which calls swe_set_sid_mode().
        _ = VedicCalculator.shared
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Real content loads immediately behind splash
                Group {
                    if vm.hasCompletedOnboarding {
                        TabView(selection: $vm.activeTab) {
                            HomeView(vm: vm)
                                .tag(0)
                            MantraRitualView(vm: vm)
                                .tag(1)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    } else {
                        OnboardingView(vm: vm)
                    }
                }
                .environment(\.deviFontScale, vm.fontScale)
                .preferredColorScheme(ritualColorSchemeActive ? .dark : (vm.isLightMode ? .light : .dark))

                // Splash overlay — always dark, dissolves after ~1.8s
                if !splashFinished {
                    SplashView(isFinished: $splashFinished)
                        .ignoresSafeArea()
                        .zIndex(999)
                }
            }
            .task {
                // One-time setup on first appearance
                notificationDelegate.vm = vm
                UNUserNotificationCenter.current().delegate = notificationDelegate
                vm.notificationService.registerCategories()
                vm.startTimer()
                vm.loadData()
                await vm.checkNotificationAuthorization()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    vm.startTimer()
                    vm.loadData()
                    vm.recordUsageDay()
                    Task {
                        await vm.checkNotificationAuthorization()
                        await vm.rescheduleNotifications()
                    }
                } else if newPhase == .background {
                    vm.stopTimer()
                }
            }
            .onChange(of: vm.activeTab) { _, newTab in
                ritualColorSchemeActive = newTab == 1
            }
        }
    }

    private func configureUITestState() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let defaults = UserDefaults.standard

        if arguments.contains("UITests.SkipOnboarding") {
            defaults.set(true, forKey: "hasCompletedOnboarding")
            let city = UserCity.popularCities[0]
            defaults.set(city.name, forKey: "city.name")
            defaults.set(city.country, forKey: "city.country")
            defaults.set(city.latitude, forKey: "city.latitude")
            defaults.set(city.longitude, forKey: "city.longitude")
            defaults.set(city.timezoneIdentifier, forKey: "city.timezoneIdentifier")
        }

        if arguments.contains("UITests.ResetRitualState") {
            defaults.removeObject(forKey: "mantraRitual.state")
        }
        #endif
    }
}
