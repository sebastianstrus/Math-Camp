//
//  SettingsView.swift
//  Math Camp
//

import SwiftUI

/// Legal pages required by the App Store.
enum LegalLinks {
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula")!
    static let privacy = URL(string: "https://sebastianstrus.com/documents/math-camp/privacy-policy.html")!
}

/// Sound, language and a way to the statistics.
struct SettingsView: View {
    /// Read by `SoundManager` before every sound.
    @AppStorage(SoundManager.enabledKey) private var soundEnabled = true
    @Environment(PremiumAccess.self) private var premium
    @Environment(LanguageManager.self) private var language
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                premiumRow

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
                        // A small preview, so the child hears that sound is on.
                        .onChange(of: soundEnabled) { _, isOn in
                            if isOn { SoundManager.shared.play(.keyTap) }
                        }
                }

                row(icon: "globe", titleKey: "settings.language", tint: Theme.purple) {
                    languageMenu
                }

                linkRow(icon: "doc.text.fill", titleKey: "legal.terms", tint: Theme.blue, url: LegalLinks.terms)
                linkRow(icon: "hand.raised.fill", titleKey: "legal.privacy", tint: Theme.correct, url: LegalLinks.privacy)

                Text(verbatim: appVersion)
                    .font(Theme.font(.footnote))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
            }
            .padding(20)
            .readableContent()
        }
        .background(TrailBackground())
        .navigationTitle(Text("settings.title"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
    }

    /// Marketing version and build number, e.g. "1.0 (3)".
    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    /// Switches the app language on the spot; the whole UI re-renders, nothing restarts.
    private var languageMenu: some View {
        @Bindable var language = language
        return Menu {
            Picker("settings.language", selection: $language.selection) {
                ForEach(AppLanguage.allCases) { option in
                    if let name = option.nativeName {
                        Text(verbatim: name).tag(option)
                    } else {
                        Text("settings.language.system").tag(option)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                if let name = language.selection.nativeName {
                    Text(verbatim: name)
                } else {
                    Text("settings.language.system")
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(Theme.font(.caption))
            }
            .font(Theme.font(.footnote))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.14), in: Capsule())
        }
    }

    /// Shows whether Premium is active. When it is not, the row opens the paywall.
    @ViewBuilder
    private var premiumRow: some View {
        if premium.isPremium {
            row(icon: "checkmark.seal.fill", titleKey: "premium.status.active", tint: Theme.correct) {
                EmptyView()
            }
            .accessibilityElement(children: .combine)
        } else {
            Button { showPaywall = true } label: {
                row(icon: "lock.open.fill", titleKey: "premium.status.get", tint: Theme.yellow) {
                    Image(systemName: "chevron.right")
                        .font(Theme.font(.subheadline))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    /// A row that opens a web page in the browser.
    private func linkRow(icon: String, titleKey: LocalizedStringKey, tint: Color, url: URL) -> some View {
        Link(destination: url) {
            row(icon: icon, titleKey: titleKey, tint: tint) {
                Image(systemName: "arrow.up.right")
                    .font(Theme.font(.subheadline))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
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
