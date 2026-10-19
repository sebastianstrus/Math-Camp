//
//  SplashView.swift
//  Math Camp
//

import SwiftUI

/// The first screen after the system launch screen: the sun rises behind the mountains.
/// It uses the same navy as the launch screen, so the hand-over is seamless.
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            GeometryReader { proxy in
                let height = proxy.size.height

                // Sun
                Circle()
                    .fill(Theme.sunset)
                    .frame(width: 190, height: 190)
                    .shadow(color: Theme.orange.opacity(0.6), radius: 40)
                    .position(x: proxy.size.width / 2, y: appeared ? height * 0.52 : height * 0.82)

                // Mountains
                MountainRange()
                    .fill(Theme.mountain)
                    .frame(height: height * 0.38)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .offset(y: appeared ? 0 : 60)
                    .opacity(appeared ? 1 : 0.4)
            }
            .ignoresSafeArea()

            VStack(spacing: 10) {
                Text("home.name")
                    .font(Theme.font(.largeTitle))
                    .foregroundStyle(Theme.textPrimary)
                    .scaleEffect(appeared ? 1 : 0.9)
                Text("splash.tagline")
                    .font(Theme.font(.title3, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 120)
            .opacity(appeared ? 1 : 0)
        }
        .accessibilityElement(children: .combine)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 1.1)) { appeared = true }
            }
        }
    }
}

#Preview {
    SplashView()
}
