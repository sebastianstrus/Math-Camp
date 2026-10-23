//
//  PromptFormatter.swift
//  Math Camp
//

import Foundation

/// A number or an input slot inside a stacked fraction.
nonisolated enum FractionField: Hashable, Sendable {
    case number(Int)
    case slot(Int)
}

/// A piece of a drill row: fixed text, an input slot, or a stacked fraction.
nonisolated enum PromptPart: Hashable, Sendable {
    case text(String, spoken: String)
    case slot(Int)
    case fraction(numerator: FractionField, denominator: FractionField)
}

/// Turns the structured prompt into text. This is the only place where numbers and symbols become
/// strings, so changing the language or the notation never touches a generator.
nonisolated struct PromptFormatter: Sendable {
    let notation: MathNotation
    let locale: Locale

    // MARK: Parts of a drill row

    /// Parts for every prompt that is shown as one line of text, fractions and slots.
    /// Prompts with their own picture (number line, objects, clock face, …) return `[]`,
    /// except where the answer line below the picture is also built from parts.
    func parts(for prompt: ExercisePrompt) -> [PromptPart] {
        switch prompt {
        case .equation(let lhs, let rhs, let blank):
            return equationParts(lhs: lhs, rhs: rhs, blank: blank)

        case .comparison(let lhs, let rhs):
            return textParts(lhs.tokens) + [.slot(0)] + textParts(rhs.tokens)

        case .trueFalse(let expression, let shown):
            return textParts(expression.tokens + [.equals, .number(shown)]) + [.slot(0)]

        case .trueFalseComparison(let lhs, let sign, let rhs):
            let signToken: MathToken = sign == .less ? .less : (sign == .greater ? .greater : .equals)
            return textParts(lhs.tokens + [signToken] + rhs.tokens) + [.slot(0)]

        case .placeValue(let tens, let ones, let ask):
            switch ask {
            case .parts:
                // 47 = ? × 10 + ? × 1 (symbols instead of words, so it reads the same in every language)
                return textParts([.number(tens * 10 + ones), .equals]) + [
                    .slot(0), timesPart(10), token(.plus),
                    .slot(1), timesPart(1),
                ]
            case .total:
                // 4 × 10 + 7 × 1 = ?
                return [
                    number(tens), timesPart(10), token(.plus),
                    number(ones), timesPart(1), token(.equals), .slot(0),
                ]
            }

        case .placeValueHTO(let hundreds, let tens, let ones, let ask):
            switch ask {
            case .parts:
                return textParts([.number(hundreds * 100 + tens * 10 + ones), .equals]) + [
                    .slot(0), unit("placevalue.hundreds.unit"), token(.plus),
                    .slot(1), unit("placevalue.tens.unit"), token(.plus),
                    .slot(2), unit("placevalue.ones.unit"),
                ]
            case .total:
                return [
                    unit("placevalue.hundreds.count", hundreds), token(.plus),
                    unit("placevalue.tens.count", tens), token(.plus),
                    unit("placevalue.ones.count", ones), token(.equals), .slot(0),
                ]
            }

        case .divisionWithRemainder(let dividend, let divisor):
            let remainder = L10n.string("math.spoken.remainder")
            return textParts([.number(dividend), .divide, .number(divisor), .equals]) + [
                .slot(0), .text(notation.remainder, spoken: remainder), .slot(1),
            ]

        case .rounding(let value, let place):
            let label = L10n.format("round.to", place)
            return [.text(label, spoken: label), number(value),
                    .text("→", spoken: L10n.string("math.spoken.roundsTo")), .slot(0)]

        case .estimation(let a, let b, let operation, let place):
            let label = L10n.format("estimate.prefix", place)
            return [.text(label, spoken: label)]
                + textParts([.number(a), operation.token, .number(b)])
                + [.text("≈", spoken: L10n.string("math.spoken.approx")), .slot(0)]

        case .fractionPicture:
            return [.fraction(numerator: .slot(0), denominator: .slot(1))]

        case .fractionComparison(let a, let b):
            return [fraction(a), .slot(0), fraction(b)]

        case .fractionNumberLine(let denominator, _, .read):
            return [.fraction(numerator: .slot(0), denominator: .number(denominator))]
        case .fractionNumberLine:
            return []

        case .fractionOf(let f, let whole):
            return [fraction(f), word("math.of"), number(whole), token(.equals), .slot(0)]

        case .fractionArithmetic(let a, let b, let operation, let common):
            return [fraction(a), token(operation.token), fraction(b), token(.equals),
                    .fraction(numerator: .slot(0), denominator: .number(common))]

        case .equivalentFraction(let base, let other, let hidden):
            let shown: PromptPart = hidden == .numerator
                ? .fraction(numerator: .slot(0), denominator: .number(other.denominator))
                : .fraction(numerator: .number(other.numerator), denominator: .slot(0))
            return [fraction(base), token(.equals), shown]

        case .decimalComparison(let a, let b):
            return [decimal(a), .slot(0), decimal(b)]

        case .decimalArithmetic(let a, let b, let operation):
            return [decimal(a), token(operation.token), decimal(b), token(.equals), .slot(0)]

        case .percentOf(let percent, let whole):
            let text = (Double(percent) / 100).formatted(.percent.locale(locale))
            let spoken = L10n.format("math.spoken.percent", text)
            return [.text(text, spoken: spoken), word("math.of"), number(whole), token(.equals), .slot(0)]

        case .clock:
            return [.slot(0), .text(":", spoken: ""), .slot(1)]

        case .timeInterval(let from, let to):
            return [time(from), .text("→", spoken: L10n.string("math.spoken.to")), time(to), token(.equals),
                    .slot(0), unit("unit.min")]

        case .conversion(let value, let from, let to):
            return [number(value), unit(from.symbolKey), token(.equals), .slot(0), unit(to.symbolKey)]

        case .measureComparison(let a, let unitA, let b, let unitB):
            return [number(a), unit(unitA.symbolKey), .slot(0), number(b), unit(unitB.symbolKey)]

        case .solveForX(let lhs, let rhs, let target):
            var left: [MathToken] = []
            var right: [MathToken] = []
            var index = 0
            lhs.appendTokens(to: &left, leafIndex: &index, blank: { $0 == target })
            rhs.appendTokens(to: &right, leafIndex: &index, blank: { $0 == target })
            let tokens = (left + [.equals] + right).map { $0 == .blank ? MathToken.variable : $0 }
            return textParts(tokens) + [.text(",", spoken: ""), token(.variable), token(.equals), .slot(0)]

        case .signed(let lhs, let operation, let rhs):
            let right = rhs < 0 ? "(\(signedText(rhs)))" : signedText(rhs)
            return [signedPart(lhs, display: signedText(lhs)), token(operation.token),
                    signedPart(rhs, display: right), token(.equals), .slot(0)]

        case .signedComparison(let a, let b):
            return [signedPart(a, display: signedText(a)), .slot(0), signedPart(b, display: signedText(b))]

        case .numberLine, .countObjects, .groups, .sequence, .wordProblem, .column, .decimalNumberLine,
             .calendar, .rulePattern, .balance, .magicSquare:
            return []
        }
    }

    private func equationParts(lhs: Expression, rhs: Expression, blank: BlankPosition) -> [PromptPart] {
        let lhsLeaves = lhs.numberLeaves.count
        var left: [MathToken] = []
        var right: [MathToken] = []
        var index = 0

        switch blank {
        case .left:
            left = [.blank]
            index = lhsLeaves
            rhs.appendTokens(to: &right, leafIndex: &index, blank: { _ in false })
        case .right:
            lhs.appendTokens(to: &left, leafIndex: &index, blank: { _ in false })
            right = [.blank]
        case .leaf(let target):
            lhs.appendTokens(to: &left, leafIndex: &index, blank: { $0 == target })
            rhs.appendTokens(to: &right, leafIndex: &index, blank: { $0 == target })
        case .rightLeaves:
            lhs.appendTokens(to: &left, leafIndex: &index, blank: { _ in false })
            rhs.appendTokens(to: &right, leafIndex: &index, blank: { _ in true })
        }
        return textParts(left + [.equals] + right)
    }

    /// Tokens → parts. Every `.blank` token becomes the next slot.
    private func textParts(_ tokens: [MathToken]) -> [PromptPart] {
        var slot = 0
        return tokens.map { token in
            if token == .blank {
                defer { slot += 1 }
                return .slot(slot)
            }
            return self.token(token)
        }
    }

    // MARK: Small part builders

    private func token(_ token: MathToken) -> PromptPart {
        .text(notation.symbol(for: token, locale: locale), spoken: notation.spoken(for: token, locale: locale))
    }

    private func number(_ value: Int) -> PromptPart {
        let text = value.formatted(.number.locale(locale))
        return .text(text, spoken: text)
    }

    private func fraction(_ value: Fraction) -> PromptPart {
        .fraction(numerator: .number(value.numerator), denominator: .number(value.denominator))
    }

    func decimalText(_ value: ScaledDecimal) -> String {
        value.doubleValue.formatted(.number.precision(.fractionLength(value.scale)).locale(locale))
    }

    private func decimal(_ value: ScaledDecimal) -> PromptPart {
        let text = decimalText(value)
        return .text(text, spoken: text)
    }

    private func time(_ minutes: Int) -> PromptPart {
        let hour = (minutes / 60) % 12 == 0 ? 12 : (minutes / 60) % 12
        let text = String(format: "%d:%02d", hour, minutes % 60)
        return .text(text, spoken: text)
    }

    private func signedText(_ value: Int) -> String {
        value < 0 ? notation.subtraction + abs(value).formatted(.number.locale(locale))
                  : value.formatted(.number.locale(locale))
    }

    private func signedPart(_ value: Int, display: String) -> PromptPart {
        let spoken = value < 0 ? L10n.format("math.spoken.negative", abs(value)) : display
        return .text(display, spoken: spoken)
    }

    private func word(_ key: String) -> PromptPart {
        let text = L10n.string(key)
        return .text(text, spoken: text)
    }

    /// `× 10` or `× 1`, the place value that follows a slot or a count.
    private func timesPart(_ factor: Int) -> PromptPart {
        let number = factor.formatted(.number.locale(locale))
        return .text("\(notation.symbol(for: .times, locale: locale)) \(number)",
                     spoken: "\(notation.spoken(for: .times, locale: locale)) \(number)")
    }

    private func unit(_ key: String) -> PromptPart {
        let text = L10n.string(key)
        return .text(text, spoken: text)
    }

    private func unit(_ key: String, _ count: Int) -> PromptPart {
        let text = L10n.format(key, count)
        return .text(text, spoken: text)
    }

    // MARK: Calendar

    /// Month name in the current language ("March").
    func monthName(_ month: Int) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar.standaloneMonthSymbols[month - 1]
    }

    func calendarText(_ question: CalendarQuestion) -> String {
        switch question {
        case .daysInWeeks(let n): L10n.format("calendar.q.daysInWeeks", n)
        case .weeksInDays(let n): L10n.format("calendar.q.weeksInDays", n)
        case .monthsInYears(let n): L10n.format("calendar.q.monthsInYears", n)
        case .hoursInDays(let n): L10n.format("calendar.q.hoursInDays", n)
        case .minutesInHours(let n): L10n.format("calendar.q.minutesInHours", n)
        case .daysInMonth(let month): L10n.format("calendar.q.daysInMonth", monthName(month))
        case .monthNumber(let month): L10n.format("calendar.q.monthNumber", monthName(month))
        }
    }

    // MARK: Slot content

    /// ✔ with U+FE0E, which asks for the plain text glyph; without it the checkmark can be drawn
    /// as a dark emoji that ignores the text color.
    static let checkmark = "✔\u{FE0E}"

    /// What a filled slot shows: digits (with the locale's minus sign and decimal separator),
    /// `<` `=` `>`, or ✔ / ✘.
    func display(slot value: String) -> String {
        switch value {
        case "<", "=", ">": return value
        case "true": return Self.checkmark
        case "false": return "✘"
        default:
            return String(value.map { character -> String in
                switch character {
                case "-": notation.subtraction
                case ".": locale.decimalSeparator ?? "."
                default: String(character)
                }
            }.joined())
        }
    }

    /// What VoiceOver says for a filled slot.
    func spoken(slot value: String) -> String {
        switch value {
        case "<": notation.spoken(for: .less)
        case "=": notation.spoken(for: .equal)
        case ">": notation.spoken(for: .greater)
        case "true": L10n.string("answer.true")
        case "false": L10n.string("answer.false")
        default:
            value.hasPrefix("-") ? L10n.format("math.spoken.negative", Int(value.dropFirst()) ?? 0) : display(slot: value)
        }
    }

    private func spokenField(_ field: FractionField, slots: [String]) -> String {
        switch field {
        case .number(let value): value.formatted(.number.locale(locale))
        case .slot(let index):
            slots.indices.contains(index) && !slots[index].isEmpty
                ? spoken(slot: slots[index]) : L10n.string("math.spoken.blank")
        }
    }

    /// The whole row as a sentence, for example "47 plus 32 equals blank".
    func spokenSentence(_ parts: [PromptPart], slots: [String]) -> String {
        parts.map { part in
            switch part {
            case .text(_, let spoken):
                spoken
            case .slot(let index):
                slots.indices.contains(index) && !slots[index].isEmpty
                    ? spoken(slot: slots[index])
                    : L10n.string("math.spoken.blank")
            case .fraction(let numerator, let denominator):
                L10n.format("math.spoken.fraction", spokenField(numerator, slots: slots), spokenField(denominator, slots: slots))
            }
        }
        .joined(separator: " ")
    }

    /// The correct answer as text, shown after checking ("79", "<", "✔", "7 R 2", "0.7").
    func display(answer: ExpectedAnswer) -> String {
        switch answer {
        case .number(let value): signedText(value)
        case .comparison(let sign): notation.symbol(for: sign)
        case .bool(let value): value ? Self.checkmark : "✘"
        case .quotientRemainder(let q, let r): "\(q) \(notation.remainder) \(r)"
        case .multiple(let values): values.map { $0.formatted(.number.locale(locale)) }.joined(separator: ", ")
        case .decimal(let value, let scale): decimalText(ScaledDecimal(value: value, scale: scale))
        }
    }
}
