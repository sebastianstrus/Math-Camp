//
//  Exercise.swift
//  Math Camp
//

import Foundation

// MARK: - Supporting types

/// Which part of an equation the child has to fill in.
nonisolated enum BlankPosition: Hashable, Sendable {
    /// The whole left side is hidden: `? = 7 + 3`.
    case left
    /// The whole right side is hidden: `47 + 32 = ?`.
    case right
    /// One number, counted left to right across the whole equation: `15 + ? = 20`.
    case leaf(Int)
    /// Every number on the right side is hidden: `5 × 3 = ? + ? + ?`.
    case rightLeaves
}

nonisolated enum ComparisonSign: String, Hashable, Sendable {
    case less = "<"
    case equal = "="
    case greater = ">"

    static func compare(_ lhs: Int, _ rhs: Int) -> ComparisonSign {
        lhs < rhs ? .less : (lhs > rhs ? .greater : .equal)
    }
}

nonisolated enum NumberLineMode: Hashable, Sendable {
    /// The child puts the marker on a number.
    case place
    /// The marker is shown and the child types its number.
    case read
}

nonisolated struct NumberLineConfig: Hashable, Sendable {
    let lower: Int
    let upper: Int
    /// Distance between two ticks.
    let tickStep: Int
    /// Distance between two labelled ticks (counted from `lower`).
    let labelStep: Int
}

nonisolated enum ObjectGrouping: Hashable, Sendable {
    case none
    case fives
    case tenFrame
}

nonisolated enum PlaceValueAsk: Hashable, Sendable {
    /// `47 = ? tens + ? ones`
    case parts
    /// `4 tens + 7 ones = ?`
    case total
}

// MARK: - Prompt

/// What an exercise shows. Pure data: formatting happens in the view layer.
nonisolated enum ExercisePrompt: Hashable, Sendable {
    // Sections I–III
    case equation(lhs: Expression, rhs: Expression, blank: BlankPosition)
    case comparison(lhs: Expression, rhs: Expression)
    case numberLine(NumberLineConfig, mode: NumberLineMode, target: Int)
    case countObjects(symbol: String, count: Int, grouping: ObjectGrouping)
    case groups(symbol: String, groups: Int, perGroup: Int)
    /// `nil` marks a gap.
    case sequence([Int?])
    case trueFalse(Expression, shownResult: Int)
    case placeValue(tens: Int, ones: Int, ask: PlaceValueAsk)
    case divisionWithRemainder(dividend: Int, divisor: Int)
    case wordProblem(templateID: String, values: [String: Int], names: [String: String])

    // Section IV – big numbers
    case placeValueHTO(hundreds: Int, tens: Int, ones: Int, ask: PlaceValueAsk)
    case rounding(value: Int, to: Int)
    case column(a: Int, b: Int, operation: ArithmeticOp)
    case estimation(a: Int, b: Int, operation: ArithmeticOp, roundTo: Int)

    // Section V – fractions and decimals
    case fractionPicture(Fraction, shape: FractionShape)
    case fractionComparison(Fraction, Fraction)
    case fractionNumberLine(denominator: Int, numerator: Int, mode: NumberLineMode)
    case fractionOf(Fraction, whole: Int)
    case fractionArithmetic(Fraction, Fraction, operation: ArithmeticOp, resultDenominator: Int)
    /// `base = other`, with one part of `other` hidden.
    case equivalentFraction(base: Fraction, other: Fraction, hidden: FractionPart)
    case decimalComparison(ScaledDecimal, ScaledDecimal)
    case decimalArithmetic(ScaledDecimal, ScaledDecimal, operation: ArithmeticOp)
    case decimalNumberLine(DecimalLineConfig, mode: NumberLineMode, target: Int)
    case percentOf(percent: Int, whole: Int)

    // Section VI – time and measures
    case clock(hour: Int, minute: Int)
    /// Times are minutes after 0:00 and are shown on a 12-hour clock.
    case timeInterval(fromMinutes: Int, toMinutes: Int)
    case conversion(value: Int, from: MeasureUnit, to: MeasureUnit)
    case measureComparison(Int, MeasureUnit, Int, MeasureUnit)
    case calendar(CalendarQuestion)

    // Section VII – logic and puzzles
    case rulePattern(start: Int, length: Int, rule: PatternRule, gaps: [Int])
    /// A scale with weights on both sides; exactly one weight is `nil` (unknown).
    case balance(left: [Int?], right: [Int?])
    case solveForX(lhs: Expression, rhs: Expression, unknownLeaf: Int)
    case magicSquare(cells: [Int?], sum: Int)
    case trueFalseComparison(lhs: Expression, sign: ComparisonSign, rhs: Expression)
    /// Arithmetic that may use negative numbers. Only `.add` and `.subtract`.
    case signed(lhs: Int, operation: ArithmeticOp, rhs: Int)
    case signedComparison(Int, Int)
}

// MARK: - Answer

nonisolated enum InputKind: Hashable, Sendable {
    case number
    /// A number that may be negative (the keypad gets a ± key).
    case signedNumber
    /// A number with a decimal point (the keypad gets a decimal key).
    case decimal
    case comparison
    case boolean

    /// `true` for every kind that is typed with the digit keys.
    var isNumeric: Bool {
        switch self {
        case .number, .signedNumber, .decimal: true
        case .comparison, .boolean: false
        }
    }
}

nonisolated enum ExpectedAnswer: Hashable, Sendable {
    case number(Int)
    case comparison(ComparisonSign)
    case bool(Bool)
    case quotientRemainder(Int, Int)
    case multiple([Int])
    /// `.decimal(value: 75, scale: 2)` is 0.75.
    case decimal(value: Int, scale: Int)

    /// Number of input fields the child has to fill.
    var slotCount: Int {
        switch self {
        case .number, .comparison, .bool, .decimal: 1
        case .quotientRemainder: 2
        case .multiple(let values): values.count
        }
    }

    var inputKind: InputKind {
        switch self {
        case .comparison: .comparison
        case .bool: .boolean
        case .decimal: .decimal
        case .number, .quotientRemainder, .multiple: .number
        }
    }

    /// Correct content of every slot, encoded the same way as the child's input:
    /// digits (with `-` and `.`), `<` `=` `>`, or `true` / `false`.
    var correctSlots: [String] {
        switch self {
        case .number(let value): [String(value)]
        case .comparison(let sign): [sign.rawValue]
        case .bool(let value): [value ? "true" : "false"]
        case .quotientRemainder(let q, let r): [String(q), String(r)]
        case .multiple(let values): values.map(String.init)
        case .decimal(let value, let scale): [Self.decimalText(value, scale: scale)]
        }
    }

    func isCorrect(slots: [String]) -> Bool {
        if case .decimal(let value, let scale) = self {
            guard slots.count == 1, let typed = Self.scaledValue(of: slots[0], scale: scale) else { return false }
            return typed == value
        }
        return slots == correctSlots
    }

    /// Numbers contained in the answer (for range checks).
    var numbers: [Int] {
        switch self {
        case .number(let value): [value]
        case .quotientRemainder(let q, let r): [q, r]
        case .multiple(let values): values
        case .decimal(let value, let scale): [value / Int(pow(10, Double(scale)))]
        case .comparison, .bool: []
        }
    }

    // MARK: Decimal text

    /// `75, scale 2` → `"0.75"`; `7, scale 1` → `"0.7"`; `20, scale 1` → `"2"`.
    static func decimalText(_ value: Int, scale: Int) -> String {
        let divisor = Int(pow(10, Double(scale)))
        let whole = value / divisor
        var fraction = String(value % divisor)
        fraction = String(repeating: "0", count: scale - fraction.count) + fraction
        while fraction.hasSuffix("0") { fraction.removeLast() }
        return fraction.isEmpty ? String(whole) : "\(whole).\(fraction)"
    }

    /// Parses what the child typed (`"0.7"`, `"0.70"`, `"2."`) into an integer with `scale` decimals.
    /// `nil` if there are more decimals than `scale` (unless they are zeros) or the text is not a number.
    static func scaledValue(of text: String, scale: Int) -> Int? {
        let parts = text.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard let wholePart = parts.first, let whole = Int(wholePart.isEmpty ? "0" : String(wholePart)) else { return nil }
        var fraction = parts.count > 1 ? String(parts[1]) : ""
        while fraction.count > scale, fraction.hasSuffix("0") { fraction.removeLast() }
        guard fraction.count <= scale, fraction.allSatisfy(\.isNumber) else { return nil }
        fraction += String(repeating: "0", count: scale - fraction.count)
        return whole * Int(pow(10, Double(scale))) + (Int(fraction) ?? 0)
    }
}

// MARK: - Exercise

/// A generated exercise before it gets its position in the task.
nonisolated struct Draft: Sendable {
    let prompt: ExercisePrompt
    let answer: ExpectedAnswer
}

nonisolated struct Exercise: Identifiable, Hashable, Sendable {
    /// Zero-based position in the task.
    let id: Int
    let prompt: ExercisePrompt
    let answer: ExpectedAnswer

    var slotCount: Int { answer.slotCount }

    var inputKind: InputKind {
        switch prompt {
        case .signed: return .signedNumber
        case .numberLine(let config, _, _) where config.lower < 0: return .signedNumber
        default: return answer.inputKind
        }
    }

    /// `false` where the child drags a marker instead of typing.
    var needsKeypad: Bool {
        switch prompt {
        case .numberLine(_, .place, _), .fractionNumberLine(_, _, .place), .decimalNumberLine(_, .place, _): false
        default: true
        }
    }
}

// MARK: - Draft builders

nonisolated extension Draft {
    /// A true equation `lhs = rhs` with one part hidden. Returns `nil` if the equation is not
    /// true, produces negative numbers or needs an inexact division.
    static func equation(_ lhs: Expression, _ rhs: Expression, blank: BlankPosition) -> Draft? {
        make(.equation(lhs: lhs, rhs: rhs, blank: blank))
    }

    static func comparison(_ lhs: Expression, _ rhs: Expression) -> Draft? {
        make(.comparison(lhs: lhs, rhs: rhs))
    }

    static func trueFalse(_ expression: Expression, shownResult: Int) -> Draft? {
        make(.trueFalse(expression, shownResult: shownResult))
    }

    /// Builds the draft of any prompt whose answer can be derived from the prompt itself.
    static func make(_ prompt: ExercisePrompt) -> Draft? {
        prompt.computedAnswer.map { Draft(prompt: prompt, answer: $0) }
    }
}

// MARK: - Answers derived from prompts

nonisolated extension ExercisePrompt {
    /// The correct answer, computed from the prompt alone. `nil` when the prompt is invalid
    /// (for example a false equation) or needs outside knowledge (`sequence`, `wordProblem`).
    var computedAnswer: ExpectedAnswer? {
        switch self {
        case .equation(let lhs, let rhs, let blank):
            guard lhs.isWellFormed, rhs.isWellFormed,
                  let left = lhs.evaluate(), let right = rhs.evaluate(), left == right else { return nil }
            let leaves = lhs.numberLeaves + rhs.numberLeaves
            switch blank {
            case .left: return .number(left)
            case .right: return .number(right)
            case .leaf(let index): return leaves.indices.contains(index) ? .number(leaves[index]) : nil
            case .rightLeaves: return .multiple(rhs.numberLeaves)
            }

        case .comparison(let lhs, let rhs):
            guard lhs.isWellFormed, rhs.isWellFormed,
                  let left = lhs.evaluate(), let right = rhs.evaluate() else { return nil }
            return .comparison(.compare(left, right))

        case .trueFalse(let expression, let shown):
            guard expression.isWellFormed, let value = expression.evaluate(), shown >= 0 else { return nil }
            return .bool(value == shown)

        case .placeValue(let tens, let ones, let ask):
            return ask == .total ? .number(tens * 10 + ones) : .multiple([tens, ones])

        case .divisionWithRemainder(let dividend, let divisor):
            return divisor > 0 ? .quotientRemainder(dividend / divisor, dividend % divisor) : nil

        case .numberLine(_, _, let target):
            return .number(target)

        case .countObjects(_, let count, _):
            return .number(count)

        case .groups(_, let groups, let perGroup):
            return .number(groups * perGroup)

        case .sequence, .wordProblem:
            return nil

        case .placeValueHTO(let hundreds, let tens, let ones, let ask):
            return ask == .total ? .number(hundreds * 100 + tens * 10 + ones) : .multiple([hundreds, tens, ones])

        case .rounding(let value, let place):
            return place > 0 ? .number(Self.round(value, to: place)) : nil

        case .column(let a, let b, let operation):
            guard let result = operation.apply(a, b), result >= 0 else { return nil }
            return .number(result)

        case .estimation(let a, let b, let operation, let place):
            guard let result = operation.apply(Self.round(a, to: place), Self.round(b, to: place)), result >= 0 else { return nil }
            return .number(result)

        case .fractionPicture(let fraction, _):
            return .multiple([fraction.numerator, fraction.denominator])

        case .fractionComparison(let a, let b):
            return .comparison(.compare(a.numerator * b.denominator, b.numerator * a.denominator))

        case .fractionNumberLine(_, let numerator, _):
            return .number(numerator)

        case .fractionOf(let fraction, let whole):
            guard whole % fraction.denominator == 0 else { return nil }
            return .number(whole / fraction.denominator * fraction.numerator)

        case .fractionArithmetic(let a, let b, let operation, let common):
            guard common % a.denominator == 0, common % b.denominator == 0 else { return nil }
            let left = a.numerator * (common / a.denominator)
            let right = b.numerator * (common / b.denominator)
            switch operation {
            case .add: return .number(left + right)
            case .subtract: return left >= right ? .number(left - right) : nil
            default: return nil
            }

        case .equivalentFraction(let base, let other, let hidden):
            guard base.numerator * other.denominator == other.numerator * base.denominator else { return nil }
            return .number(hidden == .numerator ? other.numerator : other.denominator)

        case .decimalComparison(let a, let b):
            let scale = max(a.scale, b.scale)
            return .comparison(.compare(a.value(atScale: scale), b.value(atScale: scale)))

        case .decimalArithmetic(let a, let b, let operation):
            guard a.scale == b.scale else { return nil }
            switch operation {
            case .add: return .decimal(value: a.value + b.value, scale: a.scale)
            case .subtract: return a.value >= b.value ? .decimal(value: a.value - b.value, scale: a.scale) : nil
            default: return nil
            }

        case .decimalNumberLine(let config, _, let target):
            return .decimal(value: target, scale: config.scale)

        case .percentOf(let percent, let whole):
            guard (whole * percent) % 100 == 0 else { return nil }
            return .number(whole * percent / 100)

        case .clock(let hour, let minute):
            return .multiple([hour, minute])

        case .timeInterval(let from, let to):
            return to > from ? .number(to - from) : nil

        case .conversion(let value, let from, let to):
            guard from.family == to.family else { return nil }
            let total = value * from.baseFactor
            return total % to.baseFactor == 0 ? .number(total / to.baseFactor) : nil

        case .measureComparison(let a, let unitA, let b, let unitB):
            guard unitA.family == unitB.family else { return nil }
            return .comparison(.compare(a * unitA.baseFactor, b * unitB.baseFactor))

        case .calendar(let question):
            return .number(question.answer)

        case .rulePattern(let start, let length, let rule, let gaps):
            let terms = rule.terms(start: start, length: length)
            guard !gaps.isEmpty, gaps.allSatisfy({ terms.indices.contains($0) }) else { return nil }
            return .multiple(gaps.sorted().map { terms[$0] })

        case .balance(let left, let right):
            let unknowns = left.filter { $0 == nil }.count + right.filter { $0 == nil }.count
            guard unknowns == 1 else { return nil }
            let leftSum = left.compactMap { $0 }.reduce(0, +)
            let rightSum = right.compactMap { $0 }.reduce(0, +)
            let missing = left.contains(where: { $0 == nil }) ? rightSum - leftSum : leftSum - rightSum
            return missing >= 1 ? .number(missing) : nil

        case .solveForX(let lhs, let rhs, let unknownLeaf):
            guard lhs.isWellFormed, rhs.isWellFormed,
                  let left = lhs.evaluate(), let right = rhs.evaluate(), left == right else { return nil }
            let leaves = lhs.numberLeaves + rhs.numberLeaves
            return leaves.indices.contains(unknownLeaf) ? .number(leaves[unknownLeaf]) : nil

        case .magicSquare(let cells, let sum):
            guard let solved = MagicSquare.solve(cells, sum: sum) else { return nil }
            return .multiple(cells.indices.filter { cells[$0] == nil }.map { solved[$0] })

        case .trueFalseComparison(let lhs, let sign, let rhs):
            guard lhs.isWellFormed, rhs.isWellFormed,
                  let left = lhs.evaluate(), let right = rhs.evaluate() else { return nil }
            return .bool(ComparisonSign.compare(left, right) == sign)

        case .signed(let lhs, let operation, let rhs):
            switch operation {
            case .add: return .number(lhs + rhs)
            case .subtract: return .number(lhs - rhs)
            default: return nil
            }

        case .signedComparison(let a, let b):
            return .comparison(.compare(a, b))
        }
    }

    /// Rounds half up to the nearest multiple of `place`.
    static func round(_ value: Int, to place: Int) -> Int {
        (value + place / 2) / place * place
    }
}

// MARK: - Range checks

nonisolated extension Exercise {
    /// Every number a child can see or has to type. Used to check that an exercise stays in its range.
    var allNumbers: [Int] {
        var numbers = answer.numbers
        switch prompt {
        case .equation(let lhs, let rhs, _), .comparison(let lhs, let rhs):
            numbers += lhs.allValues + rhs.allValues
        case .trueFalse(let expression, let shown):
            numbers += expression.allValues + [shown]
        case .trueFalseComparison(let lhs, _, let rhs):
            numbers += lhs.allValues + rhs.allValues
        case .solveForX(let lhs, let rhs, _):
            numbers += lhs.allValues + rhs.allValues
        case .numberLine(let config, _, let target):
            numbers += [config.lower, config.upper, target]
        case .countObjects(_, let count, _):
            numbers.append(count)
        case .groups(_, let groups, let perGroup):
            numbers += [groups, perGroup]
        case .sequence(let terms):
            numbers += terms.compactMap { $0 }
        case .rulePattern(let start, let length, let rule, _):
            numbers += rule.terms(start: start, length: length)
        case .placeValue(let tens, let ones, _):
            numbers += [tens, ones]
        case .placeValueHTO(let hundreds, let tens, let ones, _):
            numbers += [hundreds, tens, ones]
        case .divisionWithRemainder(let dividend, let divisor):
            numbers += [dividend, divisor]
        case .wordProblem(_, let values, _):
            numbers += Array(values.values)
        case .rounding(let value, _):
            numbers.append(value)
        case .column(let a, let b, _), .estimation(let a, let b, _, _):
            numbers += [a, b]
        case .fractionPicture(let fraction, _):
            numbers += [fraction.numerator, fraction.denominator]
        case .fractionComparison(let a, let b), .fractionArithmetic(let a, let b, _, _):
            numbers += [a.numerator, a.denominator, b.numerator, b.denominator]
        case .fractionNumberLine(let denominator, let numerator, _):
            numbers += [denominator, numerator]
        case .fractionOf(let fraction, let whole):
            numbers += [fraction.numerator, fraction.denominator, whole]
        case .equivalentFraction(let base, let other, _):
            numbers += [base.numerator, base.denominator, other.numerator, other.denominator]
        case .decimalComparison, .decimalArithmetic, .decimalNumberLine:
            break
        case .percentOf(let percent, let whole):
            numbers += [percent, whole]
        case .clock(let hour, let minute):
            numbers += [hour, minute]
        case .timeInterval(let from, let to):
            numbers += [from, to]
        case .conversion(let value, _, _):
            numbers.append(value)
        case .measureComparison(let a, _, let b, _):
            numbers += [a, b]
        case .calendar(let question):
            numbers.append(question.answer)
        case .balance(let left, let right):
            numbers += (left + right).compactMap { $0 }
        case .magicSquare(let cells, let sum):
            numbers += cells.compactMap { $0 } + [sum]
        case .signed(let lhs, _, let rhs):
            numbers += [lhs, rhs]
        case .signedComparison(let a, let b):
            numbers += [a, b]
        }
        return numbers
    }
}
