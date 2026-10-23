//
//  Theme.swift
//  Math Camp
//
//  Every colour, font and card style lives here.
//

import SwiftUI

extension Color {
    /// `Color(hex: 0xFF7A2F)`
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Theme {
    // MARK: Palette (from the app icon)

    static let navyDeep = Color(hex: 0x0E1E40)
    static let navy = Color(hex: 0x0B2A5B)
    static let blue = Color(hex: 0x2F6FE0)
    static let purple = Color(hex: 0x6B4DE6)
    static let orange = Color(hex: 0xFF7A2F)
    static let yellow = Color(hex: 0xFFD12E)

    static let correct = Color(hex: 0x3DDC84)
    static let wrong = Color(hex: 0xFF6B6B)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)

    static func accent(for section: CampSection) -> Color { Color(hex: section.accentHex) }

    // MARK: Gradients

    static let background = LinearGradient(
        colors: [navyDeep, navy, Color(hex: 0x1B2A6B)], startPoint: .top, endPoint: .bottom)

    static let sunset = LinearGradient(colors: [orange, yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let mountain = LinearGradient(colors: [blue, purple], startPoint: .topLeading, endPoint: .bottomTrailing)

    // MARK: Fonts (rounded, bold, scale with Dynamic Type)

    static func font(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    /// Big numbers inside exercises.
    static let equationFont = font(.largeTitle)

    // MARK: Layout

    static let cardRadius: CGFloat = 24
    /// Minimum touch target.
    static let minTouch: CGFloat = 44
    /// Content never gets wider than this, so iPad layouts stay readable.
    static let readableWidth: CGFloat = 720
}

// MARK: - Card

extension View {
    /// Rounded, softly shadowed card with a gradient fill.
    func themeCard(accent: Color? = nil, radius: CGFloat = Theme.cardRadius) -> some View {
        background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.06)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder((accent ?? .white).opacity(accent == nil ? 0.14 : 0.5), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.28), radius: 12, y: 6)
        }
    }

    /// Centers content and caps its width on large screens.
    func readableContent() -> some View {
        frame(maxWidth: Theme.readableWidth).frame(maxWidth: .infinity)
    }
}

// MARK: - Buttons

/// Big warm call-to-action button.
struct PrimaryButtonStyle: ButtonStyle {
    var minHeight: CGFloat = 56

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(.title3))
            .foregroundStyle(Theme.navyDeep)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background {
                Capsule().fill(Theme.sunset)
                    .shadow(color: Theme.orange.opacity(0.4), radius: 10, y: 4)
            }
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

/// Quiet button on a translucent capsule.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(.headline))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Capsule().fill(Color.white.opacity(configuration.isPressed ? 0.25 : 0.16)))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Background

/// Navy sky with a faint sun and mountains, in the spirit of the icon.
struct TrailBackground: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background
            Circle()
                .fill(Theme.sunset)
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .opacity(0.35)
                .offset(x: 90, y: -40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            MountainRange()
                .fill(Theme.mountain)
                .opacity(0.22)
                .frame(height: 180)
        }
        .ignoresSafeArea()
    }
}

/// Two overlapping peaks.
struct MountainRange: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.22, y: rect.height * 0.35))
        path.addLine(to: CGPoint(x: rect.width * 0.42, y: rect.height * 0.7))
        path.addLine(to: CGPoint(x: rect.width * 0.65, y: rect.height * 0.05))
        path.addLine(to: CGPoint(x: rect.width * 0.9, y: rect.height * 0.62))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.45))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
