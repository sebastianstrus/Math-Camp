//
//  RootView.swift
//  Math Camp
//

import SwiftUI

/// Splash first, then the intro slides on the very first launch, then the Trail Map.
struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if hasSeenOnboarding {
                HomeView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.4)) { hasSeenOnboarding = true }
                }
                .transition(.opacity)
            }

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.8 : 2.0))
            withAnimation(.easeOut(duration: 0.5)) { showSplash = false }
        }
    }
}
