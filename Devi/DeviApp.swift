// MARK: - DeviApp.swift
// App entry point — routes between onboarding and main view

import SwiftUI

@main
struct DeviApp: App {
    @StateObject private var vm = PanchangViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if vm.hasCompletedOnboarding {
                    HomeView(vm: vm)
                } else {
                    OnboardingView(vm: vm)
                }
            }
            .preferredColorScheme(.dark) // Always dark — the gradients ARE the theme
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
