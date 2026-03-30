// MARK: - DeviApp.swift
// App entry point — routes between onboarding and main view

import SwiftUI

@main
struct DeviApp: App {
    @StateObject private var vm = PanchangViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var splashFinished = false

    init() {
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
                        HomeView(vm: vm)
                    } else {
                        OnboardingView(vm: vm)
                    }
                }
                .environment(\.deviFontScale, vm.fontScale)
                .preferredColorScheme(vm.isLightMode ? .light : .dark)

                // Splash overlay — always dark, dissolves after ~1.8s
                if !splashFinished {
                    SplashView(isFinished: $splashFinished)
                        .ignoresSafeArea()
                        .zIndex(999)
                }
            }
            .task {
                // One-time setup on first appearance
                vm.notificationService.registerCategories()
                await vm.checkNotificationAuthorization()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    vm.loadData()
                    Task {
                        await vm.checkNotificationAuthorization()
                        await vm.rescheduleNotifications()
                    }
                }
            }
        }
    }
}
