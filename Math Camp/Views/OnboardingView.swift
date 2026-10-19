//
//  OnboardingView.swift
//  Math Camp
//

import SwiftUI

/// The intro slides, shown once on first launch and again from the Home screen.
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Slide {
        let titleKey: LocalizedStringKey
        let textKey: LocalizedStringKey
        let accent: Color
    }

    private let slides = [
        Slide(titleKey: "onboarding.1.title", textKey: "onboarding.1.text", accent: Theme.orange),
        Slide(titleKey: "onboarding.2.title", textKey: "onboarding.2.text", accent: Theme.blue),
        Slide(titleKey: "onboarding.3.title", textKey: "onboarding.3.text", accent: Theme.purple),
        Slide(titleKey: "onboarding.4.title", textKey: "onboarding.4.text", accent: Theme.yellow),
        Slide(titleKey: "onboarding.5.title", textKey: "onboarding.5.text", accent: Theme.orange),
    ]

    private var isLast: Bool { page == slides.count - 1 }

    var body: some View {
        ZStack {
            TrailBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("onboarding.skip", action: onFinish)
                        .font(Theme.font(.body, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(minWidth: Theme.minTouch, minHeight: Theme.minTouch)
                        .opacity(isLast ? 0 : 1)
                        .disabled(isLast)
                }
                .padding(.horizontal, 20)

                TabView(selection: $page) {
                    ForEach(slides.indices, id: \.self) { index in
                        slide(index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: 18) {
                    HStack(spacing: 8) {
                        ForEach(slides.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == page ? Theme.yellow : Color.white.opacity(0.3))
                                .frame(width: index == page ? 26 : 8, height: 8)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("onboarding.page \(page + 1) \(slides.count)"))

                    Button {
                        if isLast {
                            onFinish()
                        } else {
                            withAnimation(reduceMotion ? nil : .snappy) { page += 1 }
                        }
                    } label: {
                        Text(isLast ? "onboarding.start" : "onboarding.next")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: 420)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: Slides

    private func slide(_ index: Int) -> some View {
        let slide = slides[index]
        return VStack(spacing: 28) {
            Spacer(minLength: 0)
            illustration(index, accent: slide.accent)
                .frame(height: 200)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text(slide.titleKey)
                    .font(Theme.font(.largeTitle))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(slide.textKey)
                    .font(Theme.font(.title3, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 520)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func illustration(_ index: Int, accent: Color) -> some View {
        switch index {
        case 0:
            badge("mountain.2.fill", accent: accent)
        case 1:
            badge("map.fill", accent: accent)
        case 2:
            // The three levels of every category.
            HStack(spacing: 14) {
                ForEach(Tier.allCases) { tier in
                    VStack(spacing: 8) {
                        Image(systemName: tier.symbolName)
                            .font(.system(size: 38))
                            .foregroundStyle(Theme.yellow)
                        Text(LocalizedStringKey(tier.titleKey))
                            .font(Theme.font(.subheadline))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .frame(width: 96, height: 110)
                    .themeCard(radius: 22)
                }
            }
        case 3:
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Theme.yellow)
                        .shadow(color: Theme.orange.opacity(0.6), radius: 12)
                }
            }
        default:
            badge("lock.open.fill", accent: accent)
        }
    }

    private func badge(_ symbol: String, accent: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 84))
            .foregroundStyle(Theme.navyDeep)
            .frame(width: 180, height: 180)
            .background(Theme.sunset, in: Circle())
            .shadow(color: accent.opacity(0.5), radius: 24, y: 8)
    }
}

#Preview {
    OnboardingView {}
}
