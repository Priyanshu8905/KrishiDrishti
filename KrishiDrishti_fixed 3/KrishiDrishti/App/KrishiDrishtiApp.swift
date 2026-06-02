// App/KrishiDrishtiApp.swift
// KrishiDrishti — Swift Student Challenge 2026
// Main entry point

import SwiftUI

@main
struct KrishiDrishtiApp: App {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                HomeView()
                    .preferredColorScheme(.light)
            } else {
                OnboardingView()
                    .preferredColorScheme(.light)
            }
        }
    }
}
