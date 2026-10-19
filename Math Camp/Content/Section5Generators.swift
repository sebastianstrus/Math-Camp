//
//  Section5Generators.swift
//  Math Camp
//
//  Section V – Fraction Falls (fractions and decimals).
//

import Foundation

nonisolated enum Section5 {

    private static func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }

    // MARK: 1. Fractions in Pictures

    static func fractionPictures(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let denominator: Int
        let shape: FractionShape
        switch c.tier {
        case .easy:
            denominator = rng.int(2...5)
            shape = rng.chance(0.5) ? .bar : .circle
        case .medium:
            denominator = rng.int(2...8)
            shape = rng.pick([.circle, .bar, .grid])
        case .hard:
            denominator = rng.pick([6, 8, 9, 10, 12])
            shape = rng.pick([.grid, .bar])
        }
        let numerator = rng.int(1...(denominator - 1))
        return .make(.fractionPicture(Fraction(numerator: numerator, denominator: denominator), shape: shape))
    }

    // MARK: 2. Compare Fractions

    static func compareFractions(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // Same denominator.
            let d = rng.int(3...10)
            let a = rng.int(1...(d - 1))
            let b = c.wantsEqual ? a : rng.int(1...(d - 1))
            guard c.wantsEqual || a != b else { return nil }
            return .make(.fractionComparison(Fraction(numerator: a, denominator: d), Fraction(numerator: b, denominator: d)))
        case .medium:
            if rng.chance(0.5) {
                // Same numerator: the larger denominator means the smaller part.
                let n = rng.int(1...3)
                let d1 = rng.int((n + 1)...10)
                let d2 = c.wantsEqual ? d1 : rng.int((n + 1)...10)
                guard c.wantsEqual || d1 != d2 else { return nil }
                return .make(.fractionComparison(Fraction(numerator: n, denominator: d1), Fraction(numerator: n, denominator: d2)))
            }
            // Against one half.
            let d = rng.pick([4, 6, 8, 10])
            let n = c.wantsEqual ? d / 2 : rng.int(1...(d - 1))
            guard c.wantsEqual || n * 2 != d else { return nil }
            let half = Fraction(numerator: 1, denominator: 2)
            let other = Fraction(numerator: n, denominator: d)
            return .make(rng.chance(0.5) ? .fractionComparison(other, half) : .fractionComparison(half, other))
        case .hard:
            // One denominator is a multiple of the other: `2/3 ☐ 5/6`.
            let b = rng.int(2...5)
            let k = rng.int(2...3)
            let n1 = rng.int(1...(b - 1))
            let n2 = c.wantsEqual ? n1 * k : rng.int(1...(b * k - 1))
            guard c.wantsEqual || n2 != n1 * k else { return nil }
            let first = Fraction(numerator: n1, denominator: b)
            let second = Fraction(numerator: n2, denominator: b * k)
            return .make(rng.chance(0.5) ? .fractionComparison(first, second) : .fractionComparison(second, first))
        }
    }

    // MARK: 3. Fractions on a Number Line

    static func fractionLine(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let denominator: Int
        let mode: NumberLineMode
        switch c.tier {
        case .easy:
            denominator = rng.pick([2, 4])
            mode = .place
        case .medium:
            denominator = rng.int(2...6)
            mode = rng.chance(0.5) ? .place : .read
        case .hard:
            denominator = rng.int(5...10)
            mode = rng.chance(0.5) ? .place : .read
        }
        return .make(.fractionNumberLine(denominator: denominator, numerator: rng.int(1...(denominator - 1)), mode: mode))
    }

    // MARK: 4. Fraction of a Number

    static func fractionOfNumber(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `1/4 of 20`
            let d = rng.pick([2, 3, 4, 5, 10])
            return .make(.fractionOf(Fraction(numerator: 1, denominator: d), whole: d * rng.int(2...10)))
        case .medium:
            let d = rng.int(2...10)
            return .make(.fractionOf(Fraction(numerator: 1, denominator: d), whole: d * rng.int(2...(100 / d))))
        case .hard:
            // `3/4 of 20`
            let d = rng.int(3...10)
            let n = rng.int(2...(d - 1))
            return .make(.fractionOf(Fraction(numerator: n, denominator: d), whole: d * rng.int(2...(100 / d))))
        }
    }

    // MARK: 5. Adding Fractions

    static func addFractions(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // Same denominator, the sum stays within one whole.
            let d = rng.int(3...10)
            let a = rng.int(1...(d - 2))
            let b = rng.int(1...(d - a))
            return .make(.fractionArithmetic(Fraction(numerator: a, denominator: d),
                                             Fraction(numerator: b, denominator: d), operation: .add, resultDenominator: d))
        case .medium:
            // Same denominator, addition may pass one whole; subtraction.
            let d = rng.int(3...10)
            if rng.chance(0.5) {
                let a = rng.int(1...(d - 1))
                let b = rng.int(1...(d - 1))
                return .make(.fractionArithmetic(Fraction(numerator: a, denominator: d),
                                                 Fraction(numerator: b, denominator: d), operation: .add, resultDenominator: d))
            }
            let a = rng.int(2...(d - 1))
            let b = rng.int(1...(a - 1))
            return .make(.fractionArithmetic(Fraction(numerator: a, denominator: d),
                                             Fraction(numerator: b, denominator: d), operation: .subtract, resultDenominator: d))
        case .hard:
            // `1/2 + 1/4 = ?/4`
            let small = rng.int(2...5)
            let big = small * rng.int(2...3)
            let a = rng.int(1...(small - 1))
            let b = rng.int(1...(big - 1))
            let add = rng.chance(0.6)
            let first = Fraction(numerator: a, denominator: small)
            let second = Fraction(numerator: b, denominator: big)
            if !add && a * (big / small) < b { return nil }
            return .make(.fractionArithmetic(first, second, operation: add ? .add : .subtract, resultDenominator: big))
        }
    }

    // MARK: 6. Equivalent Fractions

    static func equivalentFractions(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `1/2 = ?/6`
            let d = rng.int(2...4)
            let k = rng.int(2...4)
            let base = Fraction(numerator: 1, denominator: d)
            return .make(.equivalentFraction(base: base, other: Fraction(numerator: k, denominator: d * k), hidden: .numerator))
        case .medium:
            let d = rng.int(2...6)
            let n = rng.int(1...(d - 1))
            guard gcd(n, d) == 1 else { return nil }
            let k = rng.int(2...5)
            return .make(.equivalentFraction(base: Fraction(numerator: n, denominator: d),
                                             other: Fraction(numerator: n * k, denominator: d * k),
                                             hidden: rng.chance(0.5) ? .numerator : .denominator))
        case .hard:
            // Simplifying: `6/8 = ?/4`
            let d = rng.int(2...6)
            let n = rng.int(1...(d - 1))
            guard gcd(n, d) == 1 else { return nil }
            let k = rng.int(2...4)
            return .make(.equivalentFraction(base: Fraction(numerator: n * k, denominator: d * k),
                                             other: Fraction(numerator: n, denominator: d),
                                             hidden: rng.chance(0.5) ? .numerator : .denominator))
        }
    }

    // MARK: 7. Compare Decimals

    static func compareDecimals(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            let a = rng.int(1...9)
            let b = c.wantsEqual ? a : rng.int(1...9)
            guard c.wantsEqual || a != b else { return nil }
            return .make(.decimalComparison(ScaledDecimal(value: a, scale: 1), ScaledDecimal(value: b, scale: 1)))
        case .medium:
            // `2.5 ☐ 2.7`, `1.9 ☐ 2.1`
            let a = rng.int(11...99)
            let b = c.wantsEqual ? a : min(max(a + rng.pick([-12, -8, -3, -2, -1, 1, 2, 3, 8, 12]), 10), 99)
            guard c.wantsEqual || a != b else { return nil }
            return .make(.decimalComparison(ScaledDecimal(value: a, scale: 1), ScaledDecimal(value: b, scale: 1)))
        case .hard:
            // Different lengths: `0.5 ☐ 0.45`, and equal ones such as `0.3 ☐ 0.30`.
            let tenths = rng.int(1...9)
            let hundredths = rng.int(1...99)
            if c.wantsEqual {
                return .make(.decimalComparison(ScaledDecimal(value: tenths, scale: 1), ScaledDecimal(value: tenths * 10, scale: 2)))
            }
            guard hundredths != tenths * 10 else { return nil }
            let first = ScaledDecimal(value: tenths, scale: 1)
            let second = ScaledDecimal(value: hundredths, scale: 2)
            return .make(rng.chance(0.5) ? .decimalComparison(first, second) : .decimalComparison(second, first))
        }
    }

    // MARK: 8. Decimals on a Number Line

    static func decimalLine(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let mode: NumberLineMode = rng.chance(0.5) ? .place : .read
        let config: DecimalLineConfig
        let target: Int
        switch c.tier {
        case .easy:
            config = DecimalLineConfig(lower: 0, upper: 10, tickStep: 1, labelStep: 5, scale: 1)
            target = rng.int(1...9)
        case .medium:
            config = DecimalLineConfig(lower: 0, upper: 20, tickStep: 1, labelStep: 5, scale: 1)
            target = rng.int(1...19)
            if mode == .read && target % 5 == 0 { return nil }
        case .hard:
            // Hundredths between two tenths, for example 0.3 to 0.4.
            let lower = rng.int(0...8) * 10
            config = DecimalLineConfig(lower: lower, upper: lower + 10, tickStep: 1, labelStep: 5, scale: 2)
            target = lower + rng.pick([1, 2, 3, 4, 6, 7, 8, 9])
        }
        return .make(.decimalNumberLine(config, mode: mode, target: target))
    }

    // MARK: 9. Adding Decimals

    static func addDecimals(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `0.3 + 0.4`
            let a = rng.int(1...8)
            let b = rng.int(1...(10 - a))
            return .make(.decimalArithmetic(ScaledDecimal(value: a, scale: 1), ScaledDecimal(value: b, scale: 1), operation: .add))
        case .medium:
            // `2.4 + 3.5`, `7.2 − 3.1`
            let a = rng.int(11...99)
            let b = rng.int(11...99)
            if rng.chance(0.5) {
                guard a + b <= 100 else { return nil }
                return .make(.decimalArithmetic(ScaledDecimal(value: a, scale: 1), ScaledDecimal(value: b, scale: 1), operation: .add))
            }
            guard a > b else { return nil }
            return .make(.decimalArithmetic(ScaledDecimal(value: a, scale: 1), ScaledDecimal(value: b, scale: 1), operation: .subtract))
        case .hard:
            // Hundredths: `0.45 + 0.30`, `1.25 − 0.75`
            let a = rng.int(11...399)
            let b = rng.int(11...399)
            guard a % 10 != 0 || b % 10 != 0 else { return nil }
            if rng.chance(0.5) {
                guard a + b <= 500 else { return nil }
                return .make(.decimalArithmetic(ScaledDecimal(value: a, scale: 2), ScaledDecimal(value: b, scale: 2), operation: .add))
            }
            guard a > b else { return nil }
            return .make(.decimalArithmetic(ScaledDecimal(value: a, scale: 2), ScaledDecimal(value: b, scale: 2), operation: .subtract))
        }
    }

    // MARK: 10. Simple Percentages

    static func percentages(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let percent: Int
        let maxWhole: Int
        switch c.tier {
        case .easy:
            percent = rng.pick([50, 10])
            maxWhole = 100
        case .medium:
            percent = rng.pick([50, 10, 25, 20])
            maxWhole = 200
        case .hard:
            percent = rng.pick([75, 30, 40, 5, 60, 25, 20])
            maxWhole = 400
        }
        let step = 100 / gcd(percent, 100)
        let whole = step * rng.int(2...max(2, maxWhole / step))
        return .make(.percentOf(percent: percent, whole: whole))
    }
}
