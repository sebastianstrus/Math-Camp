//
//  Section1Generators.swift
//  Math Camp
//
//  Section I – Base Camp (numbers to 20). One static function per category.
//

import Foundation

nonisolated enum Section1 {
    /// Camp-themed emoji used for counting. Emoji are pictures, so they need no localisation.
    static let objectSymbols = ["🌲", "⛺️", "🐦", "🐟", "🌸", "🐚", "🍎", "⭐️"]

    // MARK: 1. Counting Objects

    static func counting(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let count: Int
        var grouping = ObjectGrouping.none
        switch c.tier {
        case .easy: count = rng.int(1...5)
        case .medium: count = rng.int(1...10)
        case .hard:
            count = rng.int(6...20)
            grouping = rng.chance(0.5) ? .fives : .tenFrame
        }
        return Draft(prompt: .countObjects(symbol: rng.pick(objectSymbols), count: count, grouping: grouping),
                     answer: .number(count))
    }

    // MARK: 2. Compare Numbers

    static func compare(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy, .medium:
            let top = c.tier == .easy ? 10 : 20
            let a = rng.int(0...top)
            let b = c.wantsEqual ? a : rng.int(0...top)
            guard c.wantsEqual || a != b else { return nil }
            return .comparison(.n(a), .n(b))
        case .hard:
            // An operation against a number: `8 + 5 ☐ 12`.
            let value = rng.int(4...18)
            guard let expression = Gen.expression(valued: value, limit: 20, rng: &rng) else { return nil }
            var other = value
            if !c.wantsEqual {
                other = value + rng.pick([-3, -2, -1, 1, 2, 3])
                guard (0...20).contains(other) else { return nil }
            }
            return rng.chance(0.5) ? .comparison(expression, .n(other)) : .comparison(.n(other), expression)
        }
    }

    // MARK: 3. Addition to 10

    static func addTo10(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            let sum = rng.int(2...5)
            let a = rng.int(1...(sum - 1))
            return .equation(.sum(a, sum - a), .n(sum), blank: .right)
        case .medium:
            let sum = rng.int(2...10)
            let a = rng.int(1...(sum - 1))
            return .equation(.sum(a, sum - a), .n(sum), blank: .right)
        case .hard:
            let total = rng.int(3...10)
            let a = rng.int(1...(total - 2))
            let b = rng.int(1...(total - a - 1))
            return .equation(.sum(a, b, total - a - b), .n(total), blank: .right)
        }
    }

    // MARK: 4. Subtraction to 10

    static func subTo10(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            let a = rng.int(2...5)
            let b = rng.int(1...(a - 1))
            return .equation(.diff(a, b), .n(a - b), blank: .right)
        case .medium:
            let a = rng.int(3...10)
            let b = rng.int(1...(a - 1))
            return .equation(.diff(a, b), .n(a - b), blank: .right)
        case .hard:
            let form = rng.int(0...9)
            if form < 3 {
                // Result 0: `7 − 7`.
                let a = rng.int(1...10)
                return .equation(.diff(a, a), .n(0), blank: .right)
            } else if form < 7 {
                // `a + b − c`
                let a = rng.int(2...8)
                let b = rng.int(1...(10 - a))
                let c = rng.int(1...(a + b))
                let expression = Expression.subtract(.sum(a, b), .n(c))
                return .equation(expression, .n(a + b - c), blank: .right)
            } else {
                // `a − b + c`
                let a = rng.int(3...10)
                let b = rng.int(1...a)
                let c = rng.int(1...(10 - (a - b)))
                let expression = Expression.add(.diff(a, b), .n(c))
                return .equation(expression, .n(a - b + c), blank: .right)
            }
        }
    }

    // MARK: 5. Make 10

    static func make10(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `10 = 7 + ?`
            let a = rng.int(1...9)
            return .equation(.n(10), .sum(a, 10 - a), blank: .leaf(2))
        case .medium:
            if rng.chance(0.5) {
                // `? + 4 = 10`
                let a = rng.int(1...9)
                return .equation(.sum(10 - a, a), .n(10), blank: .leaf(0))
            }
            // Other numbers up to 10: `8 = 5 + ?`
            let n = rng.int(3...10)
            let a = rng.int(1...(n - 1))
            return .equation(.n(n), .sum(a, n - a), blank: .leaf(2))
        case .hard:
            let n = rng.chance(0.6) ? 10 : rng.int(4...10)
            let a = rng.int(1...(n - 1))
            if rng.chance(0.5) {
                return .equation(.sum(a, n - a), .n(n), blank: .leaf(rng.int(0...2)))
            }
            return .equation(.n(n), .sum(a, n - a), blank: .leaf(rng.int(0...2)))
        }
    }

    // MARK: 6. Addition to 20

    static func addTo20(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `10 + 4`
            let a = rng.int(1...9)
            let (x, y) = Gen.shuffledPair(10, a, rng: &rng)
            return .equation(.sum(x, y), .n(10 + a), blank: .right)
        case .medium:
            // No crossing of the tens: `12 + 5`
            let first = rng.int(11...18)
            let b = rng.int(1...(9 - first % 10))
            return .equation(.sum(first, b), .n(first + b), blank: .right)
        case .hard:
            if rng.chance(0.5) {
                // Small number first: `5 + 12`
                let small = rng.int(2...9)
                let big = rng.int(11...(20 - small))
                return .equation(.sum(small, big), .n(small + big), blank: .right)
            }
            let total = rng.int(10...20)
            let a = rng.int(1...(total - 2))
            let b = rng.int(1...(total - a - 1))
            return .equation(.sum(a, b, total - a - b), .n(total), blank: .right)
        }
    }

    // MARK: 7. Adding Across 10

    static func addAcross10(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            let x = rng.int(2...9)
            let (p, q) = Gen.shuffledPair(9, x, rng: &rng)
            return .equation(.sum(p, q), .n(9 + x), blank: .right)
        case .medium:
            let a = rng.pick([7, 8])
            let x = rng.int((11 - a)...9)
            let (p, q) = Gen.shuffledPair(a, x, rng: &rng)
            return .equation(.sum(p, q), .n(a + x), blank: .right)
        case .hard:
            let a = rng.int(2...9)
            let x = rng.int(max(2, 11 - a)...9)
            let blank: BlankPosition = rng.chance(0.5) ? .right : .leaf(rng.int(0...1))
            return .equation(.sum(a, x), .n(a + x), blank: blank)
        }
    }

    // MARK: 8. Subtracting Across 10

    static func subAcross10(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `1x − 9`
            let minuend = 10 + rng.int(1...8)
            return .equation(.diff(minuend, 9), .n(minuend - 9), blank: .right)
        case .medium:
            let minuend = rng.int(11...18)
            let sub = rng.int((minuend % 10 + 1)...9)
            return .equation(.diff(minuend, sub), .n(minuend - sub), blank: .right)
        case .hard:
            let minuend = rng.int(11...18)
            let sub = rng.int((minuend % 10 + 1)...9)
            // `15 − ? = 7`
            let blank: BlankPosition = rng.chance(0.5) ? .right : .leaf(1)
            return .equation(.diff(minuend, sub), .n(minuend - sub), blank: blank)
        }
    }

    // MARK: 9. Missing Number

    static func missingNumber(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy, .medium:
            let top = c.tier == .easy ? 10 : 20
            if rng.chance(0.7) {
                // `a + ? = sum`
                let sum = rng.int(3...top)
                let a = rng.int(1...(sum - 1))
                return .equation(.sum(a, sum - a), .n(sum), blank: .leaf(1))
            }
            // `a − ? = result`
            let a = rng.int(3...top)
            let b = rng.int(1...(a - 1))
            return .equation(.diff(a, b), .n(a - b), blank: .leaf(1))
        case .hard:
            switch rng.int(0...2) {
            case 0:
                // `? + 6 = 14`
                let sum = rng.int(4...20)
                let b = rng.int(1...(sum - 1))
                return .equation(.sum(sum - b, b), .n(sum), blank: .leaf(0))
            case 1:
                // `? − 4 = 9`
                let a = rng.int(5...20)
                let b = rng.int(1...(a - 1))
                return .equation(.diff(a, b), .n(a - b), blank: .leaf(0))
            default:
                // `13 − ? = 5`
                let a = rng.int(5...20)
                let b = rng.int(1...(a - 1))
                return .equation(.diff(a, b), .n(a - b), blank: .leaf(1))
            }
        }
    }

    // MARK: 10. Number Line to 20

    static func numberLine(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let config: NumberLineConfig
        let mode: NumberLineMode
        let target: Int
        switch c.tier {
        case .easy:
            config = NumberLineConfig(lower: 0, upper: 10, tickStep: 1, labelStep: 1)
            mode = .place
            target = rng.int(0...10)
        case .medium:
            config = NumberLineConfig(lower: 0, upper: 20, tickStep: 1, labelStep: 5)
            mode = rng.chance(0.5) ? .place : .read
            target = rng.int(1...19)
            if mode == .read && target % 5 == 0 { return nil }
        case .hard:
            config = NumberLineConfig(lower: 0, upper: 20, tickStep: 1, labelStep: 10)
            mode = rng.chance(0.5) ? .place : .read
            target = rng.int(1...19)
            if target == 10 { return nil }
        }
        return Draft(prompt: .numberLine(config, mode: mode, target: target), answer: .number(target))
    }

    // MARK: 11. Number Patterns

    static func patterns(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            let step = rng.pick([1, 2])
            let start = rng.int(Gen.startRange(step: step, length: 5, limit: 10))
            return Gen.sequence(start: start, step: step, length: 5, gaps: [rng.int(1...4)])
        case .medium:
            let step = rng.pick([2, 5, -1])
            let length = abs(step) >= 5 ? 4 : 5
            let start = rng.int(Gen.startRange(step: step, length: length, limit: 20))
            return Gen.sequence(start: start, step: step, length: length, gaps: [rng.int(1...(length - 1))])
        case .hard:
            let step = rng.pick([-2, 3])
            let start = rng.int(Gen.startRange(step: step, length: 5, limit: 20))
            // The gap is at the start or in the middle, never at the end.
            return Gen.sequence(start: start, step: step, length: 5, gaps: [rng.int(0...3)])
        }
    }
}
