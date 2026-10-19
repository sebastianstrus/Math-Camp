//
//  WordProblemText.swift
//  Math Camp
//

import Foundation

/// Fills a word-problem template from the String Catalog.
///
/// Catalog key: `wp.<templateID>`. The arguments are positional and numbered densely in the
/// order given by `WordProblemTemplate.args` (names are `%@`, numbers `%lld`).
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
        return String(format: L10n.string("wp.\(templateID)"), locale: .current, arguments: arguments)
    }
}
