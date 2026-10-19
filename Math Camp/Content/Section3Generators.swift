//
//  Section3Generators.swift
//  Math Camp
//
//  Section III – Rocky Ridge (multiplication and division).
//

import Foundation

nonisolated enum Section3 {

    // MARK: 1. Equal Groups

    static func equalGroups(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // Pictures: 3 groups of 4 = ?
            let groups = rng.int(2...5)
            let perGroup = rng.pick([2, 3, 4, 5, 10])
            return Draft(prompt: .groups(symbol: rng.pick(Section1.objectSymbols), groups: groups, perGroup: perGroup),
                         answer: .number(groups * perGroup))
        case .medium:
            // `4 + 4 + 4 = ? × 4`
            let groups = rng.int(2...6)
            let perGroup = rng.int(2...10)
            let repeated = Expression.sum([Int](repeating: perGroup, count: groups))
            return .equation(repeated, .prod(groups, perGroup), blank: .leaf(groups))
        case .hard:
            // `5 × 3 = ? + ? + ?`
            let factor = rng.int(2...10)
            let times = rng.int(2...5)
            let repeated = Expression.sum([Int](repeating: factor, count: times))
            return .equation(.prod(factor, times), repeated, blank: .rightLeaves)
        }
    }

    // MARK: 2–5. Times tables

    /// Which factors a times-table category practises in each tier.
    nonisolated struct TableSet: Sendable {
        let easy: [Int]
        let medium: [Int]
        let hard: [Int]
        /// The other factor is drawn from this range.
        let other: ClosedRange<Int> = 2...10
    }

    static let tables2510 = TableSet(easy: [2, 10], medium: [2, 5, 10], hard: [2, 5, 10])
    static let tables34 = TableSet(easy: [3], medium: [3, 4], hard: [3, 4])
    static let tables69 = TableSet(easy: [6], medium: [6, 7, 8, 9], hard: [6, 7, 8, 9])
    static let tablesMixed = TableSet(easy: [2, 3, 4, 5], medium: Array(2...9), hard: Array(2...10))

    static func timesTables(_ set: TableSet) -> DraftMaker {
        { c, rng in
            let factors: [Int]
            switch c.tier {
            case .easy: factors = set.easy
            case .medium: factors = set.medium
            case .hard: factors = set.hard
            }
            let f = rng.pick(factors)
            let other = rng.int(set.other)
            let (x, y) = Gen.shuffledPair(f, other, rng: &rng)
            let product = f * other
            // Peak hides one factor (or, now and then, the product).
            let blank: BlankPosition = (c.tier == .hard && rng.chance(0.8)) ? .leaf(rng.int(0...1)) : .right
            return .equation(.prod(x, y), .n(product), blank: blank)
        }
    }

    // MARK: 6. Division Facts

    static func divisionFacts(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let divisor: Int
        switch c.tier {
        case .easy: divisor = rng.pick([2, 10])
        case .medium, .hard: divisor = rng.int(2...9)
        }
        let quotient = rng.int(2...10)
        let dividend = divisor * quotient
        let blank: BlankPosition
        if c.tier == .hard {
            // `? ÷ 6 = 4`, `42 ÷ ? = 7`, or the plain result.
            blank = rng.pick([.leaf(0), .leaf(0), .leaf(1), .leaf(1), .right])
        } else {
            blank = .right
        }
        return .equation(.quot(dividend, divisor), .n(quotient), blank: blank)
    }

    // MARK: 7. Missing Factor

    static func missingFactor(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `2 × ? = 8`
            let f = rng.int(2...5)
            let n = rng.int(2...10)
            return .equation(.prod(f, n), .n(f * n), blank: .leaf(1))
        case .medium:
            // `7 × ? = 56`
            let f = rng.int(2...9)
            let n = rng.int(2...10)
            if rng.chance(0.3) { return .equation(.prod(n, f), .n(f * n), blank: .leaf(0)) }
            return .equation(.prod(f, n), .n(f * n), blank: .leaf(1))
        case .hard:
            // Multiplication and division mixed.
            let f = rng.int(2...9)
            let n = rng.int(2...10)
            switch rng.int(0...3) {
            case 0: return .equation(.prod(f, n), .n(f * n), blank: .leaf(1))        // `7 × ? = 56`
            case 1: return .equation(.prod(n, f), .n(f * n), blank: .leaf(0))        // `? × 7 = 56`
            case 2: return .equation(.quot(f * n, f), .n(n), blank: .leaf(1))        // `56 ÷ ? = 8`
            default: return .equation(.quot(f * n, f), .n(n), blank: .leaf(0))       // `? ÷ 7 = 8`
            }
        }
    }

    // MARK: 8. Division with Remainder

    static func remainder(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let divisor: Int
        let dividend: Int
        switch c.tier {
        case .easy:
            divisor = rng.int(2...3)
            dividend = rng.int(5...20)
        case .medium:
            divisor = rng.int(2...9)
            dividend = rng.int(10...50)
        case .hard:
            divisor = rng.int(2...9)
            dividend = rng.int(20...99)
        }
        let rest = dividend % divisor
        // Exact divisions ("R 0") are allowed, but only now and then.
        if rest == 0 && !rng.chance(0.15) { return nil }
        return Draft(prompt: .divisionWithRemainder(dividend: dividend, divisor: divisor),
                     answer: .quotientRemainder(dividend / divisor, rest))
    }

    // MARK: 9. Order of Operations

    static func orderOfOperations(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let expression: Expression
        switch c.tier {
        case .easy:
            // `3 + 4 × 2`
            let a = rng.int(2...9)
            let product = Expression.prod(rng.int(2...9), rng.int(2...5))
            expression = rng.chance(0.6) ? .add(.n(a), product) : .add(product, .n(a))
        case .medium:
            switch rng.int(0...2) {
            case 0:
                // `20 − 3 × 4`
                let p = Expression.prod(rng.int(2...9), rng.int(2...5))
                guard let value = p.evaluate() else { return nil }
                expression = .subtract(.n(value + rng.int(1...20)), p)
            case 1:
                // `18 ÷ 3 + 5`
                let divisor = rng.int(2...9)
                expression = .add(.quot(divisor * rng.int(2...10), divisor), .n(rng.int(2...9)))
            default:
                // `5 + 18 ÷ 3`
                let divisor = rng.int(2...9)
                expression = .add(.n(rng.int(2...9)), .quot(divisor * rng.int(2...10), divisor))
            }
        case .hard:
            // Brackets change the result: `(3 + 4) × 2`
            switch rng.int(0...4) {
            case 0: expression = .multiply(.parenthesized(.sum(rng.int(2...9), rng.int(2...9))), .n(rng.int(2...9)))
            case 1:
                let b = rng.int(2...9)
                expression = .multiply(.parenthesized(.diff(b + rng.int(2...9), b)), .n(rng.int(2...9)))
            case 2: expression = .multiply(.n(rng.int(2...9)), .parenthesized(.sum(rng.int(2...9), rng.int(2...9))))
            case 3:
                let divisor = rng.int(2...9)
                let total = divisor * rng.int(2...9)
                let a = rng.int(1...(total - 1))
                expression = .divide(.parenthesized(.sum(a, total - a)), .n(divisor))
            default:
                let a = rng.int(2...9)
                expression = .subtract(.n(a * rng.int(2...9)), .parenthesized(.sum(rng.int(2...9), rng.int(2...9))))
            }
            // The brackets must matter: reading the sentence without them gives another value.
            guard expression.valueIgnoringParentheses != expression.evaluate() else { return nil }
        }
        guard expression.isWellFormed, let value = expression.evaluate(), value <= 100 else { return nil }
        return .equation(expression, .n(value), blank: .right)
    }

    // MARK: 10. Multiply by 10 and 100

    static func multiplyBy10And100(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `7 × 10`
            let a = rng.int(2...9)
            let (x, y) = Gen.shuffledPair(a, 10, rng: &rng)
            return .equation(.prod(x, y), .n(a * 10), blank: .right)
        case .medium:
            // `34 × 10`, `6 × 100`
            let tens = rng.chance(0.5)
            let a = tens ? rng.int(11...99) : rng.int(2...20)
            let m = tens ? 10 : 100
            let (x, y) = Gen.shuffledPair(a, m, rng: &rng)
            return .equation(.prod(x, y), .n(a * m), blank: .right)
        case .hard:
            let tens = rng.chance(0.5)
            let a = tens ? rng.int(11...99) : rng.int(2...20)
            let m = tens ? 10 : 100
            let product = a * m
            switch rng.int(0...4) {
            case 0: return .equation(.quot(product, m), .n(a), blank: .right)        // `340 ÷ 10 = ?`
            case 1: return .equation(.prod(a, m), .n(product), blank: .leaf(0))      // `? × 10 = 340`
            case 2: return .equation(.prod(a, m), .n(product), blank: .leaf(1))      // `34 × ? = 3400`
            case 3: return .equation(.quot(product, m), .n(a), blank: .leaf(1))      // `720 ÷ ? = 72`
            default: return .equation(.quot(product, m), .n(a), blank: .leaf(0))     // `? ÷ 100 = 6`
            }
        }
    }

    // MARK: 11. 2-Digit × 1-Digit

    static func twoDigitTimesOne(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let a: Int
        let m: Int
        switch c.tier {
        case .easy:
            // No carrying: `12 × 3`
            m = rng.int(2...4)
            a = rng.int(1...(9 / m)) * 10 + rng.int(1...(9 / m))
        case .medium:
            // `23 × 4`
            m = rng.int(2...5)
            a = rng.int(11...60)
            guard a % 10 != 0 else { return nil }
        case .hard:
            // `48 × 7`
            m = rng.int(3...9)
            a = rng.int(21...99)
            guard a % 10 != 0 else { return nil }
        }
        let (x, y) = Gen.shuffledPair(a, m, rng: &rng)
        return .equation(.prod(x, y), .n(a * m), blank: .right)
    }

    // MARK: 12. True or False

    static func trueOrFalse(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let expression: Expression
        switch c.tier {
        case .easy:
            let (x, y) = Gen.shuffledPair(rng.pick([2, 5, 10]), rng.int(2...10), rng: &rng)
            expression = .prod(x, y)
        case .medium:
            expression = .prod(rng.int(2...10), rng.int(2...10))
        case .hard:
            switch rng.int(0...3) {
            case 0:
                let divisor = rng.int(2...9)
                expression = .quot(divisor * rng.int(2...10), divisor)
            case 1: expression = .add(.n(rng.int(2...9)), .prod(rng.int(2...9), rng.int(2...9)))
            case 2:
                let p = Expression.prod(rng.int(2...9), rng.int(2...9))
                expression = .subtract(.n((p.evaluate() ?? 0) + rng.int(1...15)), p)
            default:
                let divisor = rng.int(2...9)
                expression = .add(.quot(divisor * rng.int(2...9), divisor), .n(rng.int(2...9)))
            }
        }
        guard expression.isWellFormed, let value = expression.evaluate() else { return nil }
        if c.wantsEqual { return .trueFalse(expression, shownResult: value) }
        // A wrong result that looks plausible: off by one factor, by a few, or by ten.
        let shown = value + rng.pick([-10, -5, -3, -2, -1, 1, 2, 3, 5, 10])
        guard (0...100).contains(shown), shown != value else { return nil }
        return .trueFalse(expression, shownResult: shown)
    }
}
