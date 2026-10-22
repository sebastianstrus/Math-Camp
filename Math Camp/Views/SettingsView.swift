//
//  SettingsView.swift
//  Math Camp
//

import SwiftUI

/// Sound, language and a way to the statistics.
struct SettingsView: View {
    /// Only stored for now. There is no sound playback yet.
    @AppStorage("soundEnabled") private var soundEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                NavigationLink(value: Route.statistics) {
                    row(icon: "chart.bar.fill", titleKey: "settings.statistics", tint: Theme.blue) {
                        Image(systemName: "chevron.right")
                            .font(Theme.font(.subheadline))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                row(icon: "speaker.wave.2.fill", titleKey: "settings.sound", tint: Theme.orange) {
                    Toggle("settings.sound", isOn: $soundEnabled)
                        .labelsHidden()
                        .tint(Theme.correct)
                }

                // Placeholder until more languages are supported.
                row(icon: "globe", titleKey: "settings.language", tint: Theme.purple) {
                    Text("common.comingSoon")
                        .font(Theme.font(.footnote))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.14), in: Capsule())
                }
                .opacity(0.65)
                .accessibilityElement(children: .combine)
            }
            .padding(20)
            .readableContent()
        }
        .background(TrailBackground())
        .navigationTitle(Text("settings.title"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func row<Trailing: View>(icon: String, titleKey: LocalizedStringKey, tint: Color,
                                     @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.navyDeep)
                .frame(width: 44, height: 44)
                .background(tint, in: Circle())
                .accessibilityHidden(true)
            Text(titleKey)
                .font(Theme.font(.headline))
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 8)
            trailing()
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .themeCard()
        .contentShape(Rectangle())
    }
}
