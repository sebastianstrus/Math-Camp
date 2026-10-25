//
//  L10n.swift
//  Math Camp
//

import Foundation

/// Lookup of strings whose keys are built at run time (word-problem templates, category titles).
/// Static UI strings use `Text("key")` / `String(localized:)` directly.
///
/// Plurals: strings that contain a number are formatted with `String(format:locale:)`, so a
/// translator can add "Vary by Plural" variations in the String Catalog without any code change.
nonisolated enum L10n {
    /// The localized string for `key` (the key itself if the catalog has no entry).
    static func string(_ key: String) -> String {
        LanguageManager.bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// The localized format string for `key`, filled with `arguments`
    /// (`%lld` for integers, `%@` for strings; positional `%1$lld` works too).
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: LanguageManager.activeLocale, arguments: arguments)
    }

    /// `true` when the catalog contains a translation for `key`.
    static func hasString(_ key: String) -> Bool {
        let marker = "\u{0}missing"
        return LanguageManager.bundle.localizedString(forKey: key, value: marker, table: nil) != marker
    }
}
