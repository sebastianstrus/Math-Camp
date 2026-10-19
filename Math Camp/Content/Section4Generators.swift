//
//  Section4Generators.swift
//  Math Camp
//
//  Section IV – The Summit (big numbers).
//

import Foundation

nonisolated enum Section4 {

    // MARK: 1. Hundreds, Tens and Ones

    static func hundredsTensOnes(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `347 = ? hundreds + ? tens + ? ones`
            let h = rng.int(1...9), t = rng.int(0...9), o = rng.int(0...9)
            return .make(.placeValueHTO(hundreds: h, tens: t, ones: o, ask: .parts))
        case .medium:
            // `3 hundreds + 4 tens + 7 ones = ?`
            let h = rng.int(1...9), t = rng.int(0...9), o = rng.int(0...9)
            return .make(.placeValueHTO(hundreds: h, tens: t, ones: o, ask: .total))
        case .hard:
            // More than nine of a place: `5 hundreds + 14 tens + 3 ones = ?`
            if rng.chance(0.5) {
                return .make(.placeValueHTO(hundreds: rng.int(1...7), tens: rng.int(10...19),
                                            ones: rng.int(0...9), ask: .total))
            }
            return .make(.placeValueHTO(hundreds: rng.int(1...8), tens: rng.int(0...9),
                                        ones: rng.int(10...19), ask: .total))
        }
    }

    // MARK: 2. Compare Big Numbers

    static func compare(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let a: Int
        var b: Int
        switch c.tier {
        case .easy:
            a = rng.int(100...999)
            b = rng.int(100...999)
            if abs(a / 100 - b / 100) < 2 { b = a }
        case .medium:
            a = rng.int(1_000...9_999)
            b = rng.int(1_000...9_999)
            if abs(a / 1_000 - b / 1_000) < 1 { b = a }
        case .hard:
            // Neighbours: swapped digits or a difference only in the last two digits.
            a = rng.int(1_000...9_999)
            if rng.chance(0.5) {
                let digits = Array(String(a))
                var swapped = digits
                swapped.swapAt(rng.int(0...2), 3)
                b = Int(String(swapped)) ?? a
            } else {
                b = a / 100 * 100 + rng.int(0...99)
            }
        }
        if c.wantsEqual { b = a }
        guard c.wantsEqual || a != b else { return nil }
        return .comparison(.n(a), .n(b))
    }

    // MARK: 3. Rounding

    static func rounding(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let value: Int
        let place: Int
        switch c.tier {
        case .easy:
            value = rng.int(11...99)
            place = 10
        case .medium:
            value = rng.int(101...999)
            place = rng.pick([10, 100])
        case .hard:
            value = rng.int(1_001...9_999)
            place = rng.pick([100, 1_000])
        }
        guard value % place != 0 else { return nil }
        return .make(.rounding(value: value, to: place))
    }

    // MARK: 4. 3-Digit Addition and Subtraction

    static func threeDigit(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `340 + 200`, `560 − 300`
            let a = rng.int(1...9) * 100 + rng.int(0...9) * 10
            let b = rng.pick([100, 200, 300, 400, 10, 20, 30, 40, 50])
            if rng.chance(0.5) {
                guard a + b <= 999 else { return nil }
                return .equation(.sum(a, b), .n(a + b), blank: .right)
            }
            guard a - b >= 100 else { return nil }
            return .equation(.diff(a, b), .n(a - b), blank: .right)
        case .medium:
            // `347 + 125`, `582 − 241`
            let a = rng.int(101...899)
            let b = rng.int(101...899)
            if rng.chance(0.5) {
                guard a + b <= 999 else { return nil }
                return .equation(.sum(a, b), .n(a + b), blank: .right)
            }
            guard a > b else { return nil }
            return .equation(.diff(a, b), .n(a - b), blank: .right)
        case .hard:
            // Gaps: `347 + ? = 612`, `? − 218 = 405`
            let a = rng.int(101...899)
            let b = rng.int(101...899)
            switch rng.int(0...3) {
            case 0:
                guard a + b <= 999 else { return nil }
                return .equation(.sum(a, b), .n(a + b), blank: .leaf(1))
            case 1:
                guard a + b <= 999 else { return nil }
                return .equation(.sum(a, b), .n(a + b), blank: .leaf(0))
            case 2:
                guard a > b else { return nil }
                return .equation(.diff(a, b), .n(a - b), blank: .leaf(0))
            default:
                guard a > b else { return nil }
                return .equation(.diff(a, b), .n(a - b), blank: .leaf(1))
            }
        }
    }

    // MARK: 5. Column Addition and Subtraction

    static func columnAddSub(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let add = rng.chance(0.5)
        switch c.tier {
        case .easy:
            // Three digits, no carrying or borrowing.
            let (a, b) = noCarryPair(add: add, &rng)
            return .make(.column(a: a, b: b, operation: add ? .add : .subtract))
        case .medium:
            let a = rng.int(101...899)
            let b = rng.int(101...899)
            if add { guard a + b <= 999 else { return nil } } else { guard a > b else { return nil } }
            return .make(.column(a: a, b: b, operation: add ? .add : .subtract))
        case .hard:
            let a = rng.int(1_001...9_899)
            let b = rng.int(1_001...8_999)
            if add { guard a + b <= 9_999 else { return nil } } else { guard a > b else { return nil } }
            return .make(.column(a: a, b: b, operation: add ? .add : .subtract))
        }
    }

    private static func noCarryPair(add: Bool, _ rng: inout SeededRandomNumberGenerator) -> (Int, Int) {
        var top = 0
        var bottom = 0
        for position in 0..<3 {
            let leading = position == 0
            if add {
                let x = rng.int(leading ? 1...8 : 0...8)
                top = top * 10 + x
                bottom = bottom * 10 + rng.int((leading ? 1 : 0)...(9 - x))
            } else {
                let x = rng.int(leading ? 2...9 : 0...9)
                top = top * 10 + x
                bottom = bottom * 10 + rng.int((leading ? 1 : 0)...(leading ? x - 1 : x))
            }
        }
        return (top, bottom)
    }

    // MARK: 6. Column Multiplication

    static func columnMultiplication(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // No carrying: `32 × 3`
            let m = rng.int(2...4)
            let a = rng.int(1...(9 / m)) * 10 + rng.int(1...(9 / m))
            return .make(.column(a: a, b: m, operation: .multiply))
        case .medium:
            return .make(.column(a: rng.int(11...99), b: rng.int(2...9), operation: .multiply))
        case .hard:
            if rng.chance(0.5) {
                return .make(.column(a: rng.int(101...999), b: rng.int(2...9), operation: .multiply))
            }
            return .make(.column(a: rng.int(11...49), b: rng.int(11...49), operation: .multiply))
        }
    }

    // MARK: 7. Long Division

    static func longDivision(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let divisor: Int
        let dividend: Int
        switch c.tier {
        case .easy:
            divisor = rng.int(2...9)
            dividend = divisor * rng.int(11...(99 / divisor))
        case .medium:
            divisor = rng.int(2...9)
            dividend = rng.int(100...999)
            if dividend % divisor != 0 && !rng.chance(0.3) { return nil }
        case .hard:
            divisor = rng.int(2...12)
            dividend = rng.int(100...999)
            if dividend % divisor == 0 && !rng.chance(0.1) { return nil }
        }
        return .make(.divisionWithRemainder(dividend: dividend, divisor: divisor))
    }

    // MARK: 8. Number Line to 1000

    static func numberLine(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let mode: NumberLineMode = rng.chance(0.5) ? .place : .read
        let config: NumberLineConfig
        let target: Int
        switch c.tier {
        case .easy:
            config = NumberLineConfig(lower: 0, upper: 1_000, tickStep: 100, labelStep: 100)
            target = rng.int(1...9) * 100
        case .medium:
            config = NumberLineConfig(lower: 0, upper: 1_000, tickStep: 50, labelStep: 100)
            target = rng.int(1...19) * 50
        case .hard:
            // A zoomed segment: 300–400 with a tick every 10.
            let lower = rng.int(0...9) * 100
            config = NumberLineConfig(lower: lower, upper: lower + 100, tickStep: 10, labelStep: 50)
            target = lower + rng.pick([10, 20, 30, 40, 60, 70, 80, 90])
        }
        return .make(.numberLine(config, mode: mode, target: target))
    }

    // MARK: 9. Estimation

    static func estimation(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `38 + 52` → round to tens
            return .make(.estimation(a: rng.int(12...88), b: rng.int(12...88), operation: .add, roundTo: 10))
        case .medium:
            let a = rng.int(112...898)
            let b = rng.int(112...898)
            if rng.chance(0.5) { return .make(.estimation(a: a, b: b, operation: .add, roundTo: 10)) }
            guard a > b else { return nil }
            return .make(.estimation(a: a, b: b, operation: .subtract, roundTo: 10))
        case .hard:
            if rng.chance(0.4) {
                // `38 × 21` → 40 × 20
                return .make(.estimation(a: rng.int(12...48), b: rng.int(12...48), operation: .multiply, roundTo: 10))
            }
            let a = rng.int(1_120...8_980)
            let b = rng.int(1_120...8_980)
            if rng.chance(0.5) {
                guard a + b <= 9_900 else { return nil }
                return .make(.estimation(a: a, b: b, operation: .add, roundTo: 100))
            }
            guard a > b else { return nil }
            return .make(.estimation(a: a, b: b, operation: .subtract, roundTo: 100))
        }
    }

    // MARK: 10. Multi-Step Expressions

    static func multiStep(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let expression: Expression
        switch c.tier {
        case .easy:
            // `250 + 4 × 30`
            let sum = Expression.add(.n(rng.int(10...50) * 10), .prod(rng.int(2...9), rng.int(2...9) * 10))
            expression = sum
        case .medium:
            switch rng.int(0...2) {
            case 0:
                // `(45 + 35) × 6`
                expression = .multiply(.parenthesized(.sum(rng.int(10...60), rng.int(10...40))), .n(rng.int(2...9)))
            case 1:
                // `500 − 6 × 40`
                let product = Expression.prod(rng.int(2...9), rng.int(2...9) * 10)
                expression = .subtract(.n(rng.int(10...99) * 10), product)
            default:
                // `12 × 5 + 80`
                expression = .add(.prod(rng.int(11...30), rng.int(2...9)), .n(rng.int(2...9) * 10))
            }
        case .hard:
            switch rng.int(0...3) {
            case 0: // `(48 + 52) × 7 − 90`
                let inner = Expression.parenthesized(.sum(rng.int(20...60), rng.int(20...60)))
                expression = .subtract(.multiply(inner, .n(rng.int(2...9))), .n(rng.int(2...9) * 10))
            case 1: // `12 × 5 + 8 × 6`
                expression = .add(.prod(rng.int(11...40), rng.int(2...9)), .prod(rng.int(2...9), rng.int(2...9)))
            case 2: // `(95 − 35) × (3 + 4)`
                let b = rng.int(10...40)
                let left = Expression.parenthesized(.diff(b + rng.int(10...60), b))
                expression = .multiply(left, .parenthesized(.sum(rng.int(2...5), rng.int(2...5))))
            default: // `600 − 25 × 4 + 70`
                let product = Expression.prod(rng.int(11...40), rng.int(2...6))
                expression = .add(.subtract(.n(rng.int(40...99) * 10), product), .n(rng.int(2...9) * 10))
            }
            guard expression.valueIgnoringParentheses != expression.evaluate() || !expression.hasParentheses else { return nil }
        }
        guard expression.isWellFormed, let value = expression.evaluate(), value <= 10_000 else { return nil }
        return .equation(expression, .n(value), blank: .right)
    }
}

nonisolated extension Expression {
    var hasParentheses: Bool { tokens.contains(.openParen) }
}
