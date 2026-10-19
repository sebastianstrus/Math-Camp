//
//  Section2Generators.swift
//  Math Camp
//
//  Section II – Forest Trail (numbers to 100). One static function per category.
//

import Foundation

nonisolated enum Section2 {

    // MARK: 1. Tens and Ones

    static func tensAndOnes(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `47 = ? tens + ? ones`
            let n = rng.int(11...99)
            return Draft(prompt: .placeValue(tens: n / 10, ones: n % 10, ask: .parts),
                         answer: .multiple([n / 10, n % 10]))
        case .medium:
            // `4 tens + 7 ones = ?`
            let tens = rng.int(1...9)
            let ones = rng.int(0...9)
            return Draft(prompt: .placeValue(tens: tens, ones: ones, ask: .total),
                         answer: .number(tens * 10 + ones))
        case .hard:
            // `3 tens + 15 ones = ?`
            let tens = rng.int(1...8)
            let ones = rng.int(10...19)
            return Draft(prompt: .placeValue(tens: tens, ones: ones, ask: .total),
                         answer: .number(tens * 10 + ones))
        }
    }

    // MARK: 2. Compare to 100

    static func compare(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // Numbers that differ in the tens.
            let a = rng.int(10...99)
            let b = c.wantsEqual ? a : rng.int(10...99)
            guard c.wantsEqual || abs(a / 10 - b / 10) >= 2 else { return nil }
            return .comparison(.n(a), .n(b))
        case .medium:
            // Similar numbers: `58 ☐ 85`, `67 ☐ 76`.
            let a: Int
            let b: Int
            if c.wantsEqual {
                a = rng.int(10...99)
                b = a
            } else if rng.chance(0.5) {
                let tens = rng.int(1...9)
                let ones = rng.int(1...9)
                guard tens != ones else { return nil }
                a = tens * 10 + ones
                b = ones * 10 + tens
            } else {
                let tens = rng.int(1...9)
                let ones1 = rng.int(0...9)
                let ones2 = rng.int(0...9)
                guard ones1 != ones2 else { return nil }
                a = tens * 10 + ones1
                b = tens * 10 + ones2
            }
            return .comparison(.n(a), .n(b))
        case .hard:
            // Operations on both sides: `40 + 9 ☐ 50 − 2`.
            let left = rng.int(21...98)
            let right = c.wantsEqual ? left : left + rng.pick([-9, -5, -3, -2, -1, 1, 2, 3, 5, 9])
            guard (11...99).contains(right),
                  let lhs = Gen.tensAndOnes(left, rng: &rng),
                  let rhs = Gen.tensAndOnes(right, rng: &rng),
                  lhs != rhs else { return nil }
            return .comparison(lhs, rhs)
        }
    }

    // MARK: 3. Adding Tens

    static func addTens(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `40 + 30`
            let a = rng.int(1...9) * 10
            let b = rng.int(1...(10 - a / 10)) * 10
            return .equation(.sum(a, b), .n(a + b), blank: .right)
        case .medium:
            // `34 + 20`
            let a = rng.int(11...89)
            guard a % 10 != 0 else { return nil }
            let b = rng.int(1...((100 - a) / 10)) * 10
            let (x, y) = Gen.shuffledPair(a, b, rng: &rng)
            return .equation(.sum(x, y), .n(a + b), blank: .right)
        case .hard:
            if rng.chance(0.5) {
                // `40 + ? = 90`
                let a = rng.int(1...8) * 10
                let b = rng.int(1...(9 - a / 10)) * 10
                return .equation(.sum(a, b), .n(a + b), blank: .leaf(1))
            }
            // `? + 30 = 75`
            let b = rng.int(1...8) * 10
            let x = rng.int(11...(99 - b))
            guard x % 10 != 0 else { return nil }
            return .equation(.sum(x, b), .n(x + b), blank: .leaf(0))
        }
    }

    // MARK: 4. Addition (no regrouping)

    static func addNoRegroup(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `23 + 4`
            let tens = rng.int(1...9)
            let ones = rng.int(1...8)
            let b = rng.int(1...(9 - ones))
            let a = tens * 10 + ones
            let (x, y) = Gen.shuffledPair(a, b, rng: &rng)
            return .equation(.sum(x, y), .n(a + b), blank: .right)
        case .medium, .hard:
            // `47 + 32`, and for Peak with a gap.
            let t1 = rng.int(1...8)
            let t2 = rng.int(1...(9 - t1))
            let o1 = rng.int(1...8)
            let o2 = rng.int(1...(9 - o1))
            let a = t1 * 10 + o1
            let b = t2 * 10 + o2
            let blank: BlankPosition = c.tier == .medium ? .right : .leaf(rng.int(0...1))
            return .equation(.sum(a, b), .n(a + b), blank: blank)
        }
    }

    // MARK: 5. Addition with Regrouping

    static func addRegroup(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `38 + 5`
            let tens = rng.int(1...8)
            let ones = rng.int(2...9)
            let b = rng.int((10 - ones)...9)
            let a = tens * 10 + ones
            return .equation(.sum(a, b), .n(a + b), blank: .right)
        case .medium:
            // `38 + 47`
            guard let (a, b) = carryPair(&rng), a + b <= 100 else { return nil }
            return .equation(.sum(a, b), .n(a + b), blank: .right)
        case .hard:
            if rng.chance(0.5) {
                // Gap: `38 + ? = 85`
                guard let (a, b) = carryPair(&rng), a + b <= 100 else { return nil }
                return .equation(.sum(a, b), .n(a + b), blank: .leaf(rng.int(0...1)))
            }
            // Three addends: `28 + 15 + 9`
            let a = rng.int(11...60)
            let b = rng.int(11...30)
            let d = rng.int(2...9)
            guard a + b + d <= 100 else { return nil }
            return .equation(.sum(a, b, d), .n(a + b + d), blank: .right)
        }
    }

    /// Two two-digit numbers whose ones digits add up to 10 or more.
    private static func carryPair(_ rng: inout SeededRandomNumberGenerator) -> (Int, Int)? {
        let o1 = rng.int(2...9)
        let o2 = rng.int((10 - o1)...9)
        let t1 = rng.int(1...8)
        let t2 = rng.int(1...8)
        return (t1 * 10 + o1, t2 * 10 + o2)
    }

    // MARK: 6. Subtraction (no regrouping)

    static func subNoRegroup(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `47 − 5`
            let tens = rng.int(1...9)
            let ones = rng.int(2...9)
            let b = rng.int(1...ones)
            let a = tens * 10 + ones
            return .equation(.diff(a, b), .n(a - b), blank: .right)
        case .medium, .hard:
            // `76 − 34`, and for Peak with a gap.
            let t1 = rng.int(2...9)
            let t2 = rng.int(1...(t1 - 1))
            let o1 = rng.int(1...9)
            let o2 = rng.int(1...o1)
            let a = t1 * 10 + o1
            let b = t2 * 10 + o2
            let blank: BlankPosition = c.tier == .medium ? .right : .leaf(rng.int(0...1))
            return .equation(.diff(a, b), .n(a - b), blank: blank)
        }
    }

    // MARK: 7. Subtraction with Regrouping

    static func subRegroup(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `62 − 7`
            let tens = rng.int(2...9)
            let ones = rng.int(0...8)
            let b = rng.int((ones + 1)...9)
            let a = tens * 10 + ones
            return .equation(.diff(a, b), .n(a - b), blank: .right)
        case .medium:
            // `62 − 27`
            let (a, b) = borrowPair(&rng)
            return .equation(.diff(a, b), .n(a - b), blank: .right)
        case .hard:
            if rng.chance(0.4) {
                // `100 − 37`
                let b = rng.int(11...99)
                guard b % 10 != 0 else { return nil }
                return .equation(.diff(100, b), .n(100 - b), blank: .right)
            }
            let (a, b) = borrowPair(&rng)
            return .equation(.diff(a, b), .n(a - b), blank: .leaf(rng.int(0...1)))
        }
    }

    /// Two two-digit numbers where the subtraction needs a borrow from the tens.
    private static func borrowPair(_ rng: inout SeededRandomNumberGenerator) -> (Int, Int) {
        let o1 = rng.int(0...8)
        let o2 = rng.int((o1 + 1)...9)
        let t1 = rng.int(2...9)
        let t2 = rng.int(1...(t1 - 1))
        return (t1 * 10 + o1, t2 * 10 + o2)
    }

    // MARK: 8. Missing Number to 100

    static func missingNumber(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `35 + ? = 40`
            let a = rng.int(11...98)
            guard a % 10 != 0 else { return nil }
            let target = (a / 10 + 1) * 10
            return .equation(.sum(a, target - a), .n(target), blank: .leaf(1))
        case .medium:
            // `35 + ? = 80`
            let target = rng.int(3...10) * 10
            let a = rng.int(2...(target - 10))
            guard a % 10 != 0 else { return nil }
            if rng.chance(0.3) {
                return .equation(.sum(target - a, a), .n(target), blank: .leaf(0))
            }
            return .equation(.sum(a, target - a), .n(target), blank: .leaf(1))
        case .hard:
            let b = rng.int(11...50)
            let result = rng.int(11...(99 - b))
            let total = b + result
            switch rng.int(0...2) {
            case 0: return .equation(.diff(total, b), .n(result), blank: .leaf(0))   // `? − 26 = 48`
            case 1: return .equation(.sum(result, b), .n(total), blank: .leaf(0))    // `? + 26 = 74`
            default: return .equation(.diff(total, b), .n(result), blank: .leaf(1))  // `74 − ? = 48`
            }
        }
    }

    // MARK: 9. Number Line to 100

    static func numberLine(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let config: NumberLineConfig
        let target: Int
        let mode: NumberLineMode = rng.chance(0.5) ? .place : .read
        switch c.tier {
        case .easy:
            config = NumberLineConfig(lower: 0, upper: 100, tickStep: 10, labelStep: 10)
            target = rng.int(1...9) * 10
        case .medium:
            config = NumberLineConfig(lower: 0, upper: 100, tickStep: 5, labelStep: 10)
            target = rng.int(1...19) * 5
        case .hard:
            // A zoomed segment, for example 40–60 with a tick every 2.
            let lower = rng.int(0...8) * 10
            config = NumberLineConfig(lower: lower, upper: lower + 20, tickStep: 2, labelStep: 10)
            let offset = rng.pick([2, 4, 6, 8, 12, 14, 16, 18])
            target = lower + offset
        }
        return Draft(prompt: .numberLine(config, mode: mode, target: target), answer: .number(target))
    }

    // MARK: 10. Brackets

    static func brackets(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let expression: Expression
        switch c.tier {
        case .easy:
            // `20 + (5 + 3)`
            let a = rng.int(1...6) * 10
            let inner = Expression.parenthesized(.sum(rng.int(2...9), rng.int(2...9)))
            expression = rng.chance(0.7) ? .add(.n(a), inner) : .add(inner, .n(a))
        case .medium:
            let a = rng.int(2...10) * 10
            if rng.chance(0.5) {
                // `30 − (7 + 2)`
                expression = .subtract(.n(a), .parenthesized(.sum(rng.int(2...9), rng.int(2...9))))
            } else {
                // `30 − (9 − 4)`
                let b = rng.int(5...9)
                expression = .subtract(.n(a), .parenthesized(.diff(b, rng.int(2...(b - 1)))))
            }
        case .hard:
            // `(25 + 15) − (12 + 8)`
            let left = Expression.parenthesized(.sum(rng.int(10...50), rng.int(10...49)))
            let right = Expression.parenthesized(.sum(rng.int(5...40), rng.int(5...40)))
            expression = .subtract(left, right)
        }
        guard let value = expression.evaluate(), expression.isWellFormed else { return nil }
        return .equation(expression, .n(value), blank: .right)
    }

    // MARK: 11. Skip Counting

    static func skipCounting(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            let start = rng.chance(0.6) ? rng.int(0...6) * 10 : rng.int(0...60)
            return Gen.sequence(start: start, step: 10, length: 5, gaps: [rng.int(1...4)])
        case .medium:
            let step = rng.pick([2, 5, 10])
            var start = rng.int(Gen.startRange(step: step, length: 5, limit: 100))
            if step != 2 { start -= start % step }
            return Gen.sequence(start: start, step: step, length: 5, gaps: [rng.int(1...4)])
        case .hard:
            let step = rng.pick([3, 4, 3, 4, -3, -4, -5, -10])
            let start = rng.int(Gen.startRange(step: step, length: 5, limit: 100))
            // The gap is at the start or in the middle, never at the end.
            return Gen.sequence(start: start, step: step, length: 5, gaps: [rng.int(0...3)])
        }
    }
}
