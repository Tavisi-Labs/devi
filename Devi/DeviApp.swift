// MARK: - DeviApp.swift
// App entry point — routes between onboarding and main view

import SwiftUI

@main
struct DeviApp: App {
    @StateObject private var vm = PanchangViewModel()
    
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
        }
    }
}
