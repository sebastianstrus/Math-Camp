//
//  MathNotation.swift
//  Math Camp
//

import Foundation
import SwiftUI

/// The symbols used to write maths. They depend on the language: English uses `×` and `÷`,
/// other languages may prefer `·` or `:`.
nonisolated struct MathNotation: Sendable, Equatable {
    var multiplication = "×"
    var division = "÷"
    var addition = "+"
    var subtraction = "−"      // U+2212 minus sign, as wide as the plus
    var equality = "="
    var lessThan = "<"
    var greaterThan = ">"
    var blank = "?"
    var remainder = L10n.string("math.remainder.short")

    /// Picks the symbols for a locale. Add a `case` here when a language needs different symbols,
    /// for example Polish and German will use `·` / `×` and `:`.
    init(locale: Locale = .current) {
        switch locale.language.languageCode?.identifier {
        default:
            break
        }
    }

    /// Display text of a token. Numbers follow the locale (grouping and digits).
    func symbol(for token: MathToken, locale: Locale) -> String {
        switch token {
        case .number(let value): value.formatted(.number.locale(locale))
        case .plus: addition
        case .minus: subtraction
        case .times: multiplication
        case .divide: division
        case .equals: equality
        case .less: lessThan
        case .greater: greaterThan
        case .openParen: "("
        case .closeParen: ")"
        case .blank: blank
        case .variable: "x"
        }
    }

    /// The decimal separator of the current language, shown on the decimal key.
    var decimalSeparatorSymbol: String { Locale.current.decimalSeparator ?? "." }

    func symbol(for sign: ComparisonSign) -> String {
        switch sign {
        case .less: lessThan
        case .equal: equality
        case .greater: greaterThan
        }
    }

    /// What VoiceOver says for a token ("plus", "times", "blank", …).
    func spoken(for token: MathToken, locale: Locale) -> String {
        switch token {
        case .number(let value): value.formatted(.number.locale(locale))
        case .plus: L10n.string("math.spoken.plus")
        case .minus: L10n.string("math.spoken.minus")
        case .times: L10n.string("math.spoken.times")
        case .divide: L10n.string("math.spoken.divide")
        case .equals: L10n.string("math.spoken.equals")
        case .less: L10n.string("math.spoken.less")
        case .greater: L10n.string("math.spoken.greater")
        case .openParen: L10n.string("math.spoken.openParen")
        case .closeParen: L10n.string("math.spoken.closeParen")
        case .blank: L10n.string("math.spoken.blank")
        case .variable: "x"
        }
    }

    func spoken(for sign: ComparisonSign) -> String {
        switch sign {
        case .less: L10n.string("math.spoken.less")
        case .equal: L10n.string("math.spoken.equals")
        case .greater: L10n.string("math.spoken.greater")
        }
    }
}

extension EnvironmentValues {
    /// Override this to force other symbols; by default they follow the device language.
    @Entry var mathNotation = MathNotation()
}
