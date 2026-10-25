//
//  LanguageManager.swift
//  Math Camp
//

import SwiftUI
import os

/// The languages the app ships in. `system` follows the device setting.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case en, de, es, fr, it, ja, nb, pl
    case ptBR = "pt-BR"
    case sv, uk

    var id: String { rawValue }

    /// Each language is shown in its own name, so a child can always find theirs.
    var nativeName: String? {
        switch self {
        case .system: nil
        case .en: "English"
        case .de: "Deutsch"
        case .es: "Español"
        case .fr: "Français"
        case .it: "Italiano"
        case .ja: "日本語"
        case .nb: "Norsk bokmål"
        case .pl: "Polski"
        case .ptBR: "Português (Brasil)"
        case .sv: "Svenska"
        case .uk: "Українська"
        }
    }
}

/// Holds the language chosen in Settings and applies it immediately, with no restart.
///
/// SwiftUI views follow `locale` through the environment. Code outside views (`L10n`,
/// `String(localized:)` call sites) reads `LanguageManager.bundle` / `LanguageManager.activeLocale`.
@Observable
final class LanguageManager {
    static let shared = LanguageManager()
    static let storageKey = "appLanguage"

    /// Read from any thread by `L10n`.
    nonisolated private static let active = OSAllocatedUnfairLock(initialState: (bundle: Bundle.main, locale: Locale.autoupdatingCurrent))

    nonisolated static var bundle: Bundle { active.withLock { $0.bundle } }
    nonisolated static var activeLocale: Locale { active.withLock { $0.locale } }

    var selection: AppLanguage {
        didSet {
            guard selection != oldValue else { return }
            UserDefaults.standard.set(selection.rawValue, forKey: Self.storageKey)
            apply()
        }
    }

    /// The locale for the SwiftUI environment.
    private(set) var locale: Locale = .autoupdatingCurrent

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        selection = stored.flatMap(AppLanguage.init(rawValue:)) ?? .system
        apply()
    }

    private func apply() {
        let bundle: Bundle
        let locale: Locale
        if selection == .system {
            bundle = .main
            locale = .autoupdatingCurrent
        } else {
            let path = Bundle.main.path(forResource: selection.rawValue, ofType: "lproj")
            bundle = path.flatMap(Bundle.init(path:)) ?? .main
            locale = Locale(identifier: selection.rawValue)
        }
        Self.active.withLock { $0 = (bundle, locale) }
        self.locale = locale
    }
}
