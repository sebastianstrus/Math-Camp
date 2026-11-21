//
//  WordProblemText.swift
//  Math Camp
//

import Foundation

/// Fills a word-problem template from the String Catalog.
///
/// Catalog key: `wp.<templateID>`. The arguments are positional and numbered densely in the
/// order given by `WordProblemTemplate.args` (names are `%@`, numbers `%lld`).
///
/// Slavic languages inflect the noun after a number (1 klejnot, 3 klejnoty, 5 klejnotów).
/// A translator writes `{2|klejnot|klejnoty|klejnotów}` – number argument 2 followed by the
/// forms for one | few | many. It expands to the number plus the right form ("3 klejnoty").
/// With two forms (`{2|one|other}`) the second is used for every other number.
nonisolated enum WordProblemText {
    static func string(templateID: String, values: [String: Int], names: [String: String]) -> String {
        let args = WordProblems.template(id: templateID)?.args ?? ""
        let arguments: [CVarArg] = args.map { letter -> CVarArg in
            switch letter {
            case "p": names["p"] ?? ""
            case "q": names["q"] ?? ""
            default: values[String(letter)] ?? 0
            }
        }
        let numbers = args.map { values[String($0)] }
        let format = expandPlurals(in: L10n.string("wp.\(templateID)"), numbers: numbers)
        return String(format: format, locale: LanguageManager.activeLocale, arguments: arguments)
    }

    /// Replaces every `{N|one|few|many}` with the number and its noun form.
    static func expandPlurals(in format: String, numbers: [Int?]) -> String {
        guard format.contains("{") else { return format }
        var result = ""
        var rest = Substring(format)
        while let open = rest.firstIndex(of: "{") {
            result += rest[..<open]
            guard let close = rest[open...].firstIndex(of: "}") else { break }
            let parts = rest[rest.index(after: open)..<close].split(separator: "|", omittingEmptySubsequences: false)
            let index = parts.first.flatMap { Int($0) }.map { $0 - 1 }
            if parts.count >= 3, let index, numbers.indices.contains(index), let number = numbers[index] {
                result += "\(number) \(form(number, parts.dropFirst()))"
            } else {
                result += rest[open...close]
            }
            rest = rest[rest.index(after: close)...]
        }
        return result + rest
    }

    private static func form(_ n: Int, _ forms: ArraySlice<Substring>) -> Substring {
        let tens = n % 100, units = n % 10
        if forms.count == 2 { return n == 1 ? forms[forms.startIndex] : forms[forms.startIndex + 1] }
        // Polish only uses the singular for exactly 1; Ukrainian also for 21, 31, ...
        let isOne = LanguageManager.activeLocale.language.languageCode?.identifier == "pl" ? n == 1 : (units == 1 && tens != 11)
        if isOne { return forms[forms.startIndex] }
        if (2...4).contains(units) && !(12...14).contains(tens) { return forms[forms.startIndex + 1] }
        return forms[forms.startIndex + 2]
    }
}
