//
//  Section7Generators.swift
//  Math Camp
//
//  Section VII – The Expedition (logic and puzzles).
//

import Foundation

nonisolated enum Section7 {

    // MARK: 1. Patterns

    static func patterns(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let rule: PatternRule
        let start: Int
        let length: Int
        switch c.tier {
        case .easy:
            let step = rng.pick([3, 4, 5, 6, 10, -3, -4, -5])
            rule = .arithmetic(step: step)
            length = 5
            start = step > 0 ? rng.int(0...30) : rng.int((abs(step) * 4)...60)
        case .medium:
            length = 6
            switch rng.int(0...2) {
            case 0:
                let (first, second) = rng.pick([(2, 3), (1, 4), (5, 10), (3, 6), (10, 5)])
                rule = .alternating(first: first, second: second)
                start = rng.int(0...20)
            case 1:
                rule = .doubling
                start = rng.int(1...6)
            default:
                let step = rng.pick([7, 8, 9, 12, 15, -6, -7])
                rule = .arithmetic(step: step)
                start = step > 0 ? rng.int(0...20) : rng.int((abs(step) * 5)...80)
            }
        case .hard:
            length = 6
            switch rng.int(0...2) {
            case 0:
                rule = .growing(firstStep: rng.int(1...3), delta: rng.int(1...2))
                start = rng.int(0...10)
            case 1:
                rule = .doubling
                start = rng.int(1...5)
            default:
                let (first, second) = rng.pick([(3, -1), (5, -2), (10, -4), (6, -3)])
                rule = .alternating(first: first, second: second)
                start = rng.int(5...30)
            }
        }
        let terms = rule.terms(start: start, length: length)
        guard terms.allSatisfy({ (0...200).contains($0) }) else { return nil }
        // Easy and Climb: a gap inside; Peak: the gap may also be the first number.
        let gap = c.tier == .hard ? rng.int(0...(length - 2)) : rng.int(1...(length - 1))
        return .make(.rulePattern(start: start, length: length, rule: rule, gaps: [gap]))
    }

    // MARK: 2. Balance Scales

    static func balance(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let leftCount: Int
        let rightCount: Int
        let top: Int
        switch c.tier {
        case .easy: (leftCount, rightCount, top) = (1, 2, 12)
        case .medium: (leftCount, rightCount, top) = (rng.chance(0.5) ? 2 : 1, 2, 30)
        case .hard: (leftCount, rightCount, top) = (rng.int(2...3), rng.int(2...3), 50)
        }
        let total = rng.int((leftCount + rightCount + 2)...top)
        guard let left = split(total, into: leftCount, &rng), let right = split(total, into: rightCount, &rng) else { return nil }
        // The unknown weight is on either side (always on the right in Warm-up).
        if c.tier != .easy && rng.chance(0.5) {
            var shown: [Int?] = left
            shown[rng.int(0...(leftCount - 1))] = nil
            return .make(.balance(left: shown, right: right))
        }
        var shown: [Int?] = right
        shown[rng.int(0...(rightCount - 1))] = nil
        return .make(.balance(left: left, right: shown))
    }

    /// Splits `total` into `count` positive parts.
    private static func split(_ total: Int, into count: Int, _ rng: inout SeededRandomNumberGenerator) -> [Int]? {
        guard total >= count else { return nil }
        var remaining = total
        var parts: [Int] = []
        for index in 0..<count {
            let left = count - index - 1
            let part = left == 0 ? remaining : rng.int(1...(remaining - left))
            parts.append(part)
            remaining -= part
        }
        return parts
    }

    // MARK: 3. Equations

    static func equations(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let lhs: Expression
        let rhs: Expression
        let unknown: Int
        switch c.tier {
        case .easy:
            let x = rng.int(2...15)
            switch rng.int(0...2) {
            case 0: // `x + 7 = 15`
                let b = rng.int(2...15)
                (lhs, rhs, unknown) = (.sum(x, b), .n(x + b), 0)
            case 1: // `x − 4 = 6`
                let b = rng.int(2...15)
                (lhs, rhs, unknown) = (.diff(x + b, b), .n(x), 0)
            default: // `15 − x = 9`
                let b = rng.int(1...15)
                (lhs, rhs, unknown) = (.diff(x + b, x), .n(b), 1)
            }
        case .medium:
            let x = rng.int(2...12)
            let b = rng.int(2...10)
            switch rng.int(0...2) {
            case 0: (lhs, rhs, unknown) = (.prod(b, x), .n(b * x), 1)       // `3 × x = 21`
            case 1: (lhs, rhs, unknown) = (.quot(b * x, b), .n(x), 0)        // `x ÷ 4 = 5` (x is the dividend)
            default: (lhs, rhs, unknown) = (.sum(x, b), .n(x + b), 0)       // `x + 38 = 57`
            }
        case .hard:
            // Two steps: `2 × x + 3 = 15`
            let x = rng.int(2...12)
            let b = rng.int(2...9)
            let d = rng.int(2...20)
            switch rng.int(0...2) {
            case 0: (lhs, rhs, unknown) = (.add(.prod(b, x), .n(d)), .n(b * x + d), 1)
            case 1: (lhs, rhs, unknown) = (.subtract(.prod(b, x), .n(d)), .n(b * x - d), 1)
            default: (lhs, rhs, unknown) = (.multiply(.parenthesized(.sum(x, d)), .n(b)), .n((x + d) * b), 0)
            }
        }
        // The unknown must be the leaf the generator meant: for `x ÷ 4 = 5` that is the dividend.
        guard lhs.isWellFormed, rhs.isWellFormed else { return nil }
        let leaves = lhs.numberLeaves + rhs.numberLeaves
        guard leaves.indices.contains(unknown), leaves[unknown] >= 2 || c.tier == .hard else { return nil }
        return .make(.solveForX(lhs: lhs, rhs: rhs, unknownLeaf: unknown))
    }

    // MARK: 4. Magic Squares

    /// The classic 3×3 square; every generated square is a shifted, scaled, rotated or mirrored copy.
    private static let base = [2, 7, 6, 9, 5, 1, 4, 3, 8]

    static func magicSquares(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let scale: Int
        let offset: Int
        let blanks: Int
        switch c.tier {
        case .easy: (scale, offset, blanks) = (1, rng.int(0...5), rng.int(2...3))
        case .medium: (scale, offset, blanks) = (rng.int(1...3), rng.int(0...10), 4)
        case .hard: (scale, offset, blanks) = (rng.int(1...4), rng.int(0...20), rng.int(5...6))
        }
        var values = base.map { $0 * scale + offset }
        // Mirror and rotate.
        if rng.chance(0.5) { values = [2, 1, 0, 5, 4, 3, 8, 7, 6].map { values[$0] } }
        for _ in 0..<rng.int(0...3) { values = [6, 3, 0, 7, 4, 1, 8, 5, 2].map { values[$0] } }
        let sum = 15 * scale + 3 * offset
        let hidden = Set(rng.shuffled(Array(0..<9)).prefix(blanks))
        let cells: [Int?] = values.indices.map { hidden.contains($0) ? nil : values[$0] }
        return .make(.magicSquare(cells: cells, sum: sum))
    }

    // MARK: 5. True or False Mix

    static func trueFalseMix(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        // A statement about a result, or a comparison between two expressions.
        if rng.chance(0.5) {
            let expression: Expression
            switch c.tier {
            case .easy:
                let a = rng.int(2...15), b = rng.int(2...15)
                expression = rng.chance(0.5) ? .sum(a, b) : .diff(a + b, b)
            case .medium:
                switch rng.int(0...2) {
                case 0: expression = .prod(rng.int(2...10), rng.int(2...10))
                case 1: let d = rng.int(2...9); expression = .quot(d * rng.int(2...10), d)
                default: expression = .sum(rng.int(10...60), rng.int(10...39))
                }
            case .hard:
                expression = .add(.n(rng.int(2...20)), .prod(rng.int(2...9), rng.int(2...9)))
            }
            guard expression.isWellFormed, let value = expression.evaluate() else { return nil }
            if c.wantsEqual { return .trueFalse(expression, shownResult: value) }
            let shown = value + rng.pick([-10, -2, -1, 1, 2, 10])
            guard (0...100).contains(shown) else { return nil }
            return .trueFalse(expression, shownResult: shown)
        }

        let left = rng.int(5...40)
        let lhs = Gen.expression(valued: left, limit: 100, rng: &rng) ?? .n(left)
        let right = c.tier == .easy ? rng.int(5...40) : rng.int(5...60)
        let rhs: Expression = c.tier == .hard ? (Gen.expression(valued: right, limit: 100, rng: &rng) ?? .n(right)) : .n(right)
        guard let lv = lhs.evaluate(), let rv = rhs.evaluate() else { return nil }
        let truth = ComparisonSign.compare(lv, rv)
        if c.wantsEqual { return .make(.trueFalseComparison(lhs: lhs, sign: truth, rhs: rhs)) }
        let wrong = [ComparisonSign.less, .equal, .greater].filter { $0 != truth }
        return .make(.trueFalseComparison(lhs: lhs, sign: rng.pick(wrong), rhs: rhs))
    }

    // MARK: 6. Negative Numbers

    static func negatives(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            if rng.chance(0.4) {
                let a = rng.int(-10...10), b = rng.int(-10...10)
                guard a != b else { return nil }
                return .make(.signedComparison(a, b))
            }
            // `3 − 8`
            let a = rng.int(1...9)
            let b = rng.int((a + 1)...10)
            return .make(.signed(lhs: a, operation: .subtract, rhs: b))
        case .medium:
            // `−3 + 7`, `−4 − 2`
            let a = rng.int(-10...10)
            let b = rng.int(1...10)
            guard a != 0 else { return nil }
            return .make(.signed(lhs: a, operation: rng.chance(0.5) ? .add : .subtract, rhs: b))
        case .hard:
            if rng.chance(0.25) {
                let a = rng.int(-20...20), b = rng.int(-20...20)
                guard a != b else { return nil }
                return .make(.signedComparison(a, b))
            }
            // `5 − (−3)`, `−6 + (−4)`
            let a = rng.int(-15...15)
            let b = rng.int(-10...(-1))
            guard a != 0 else { return nil }
            return .make(.signed(lhs: a, operation: rng.chance(0.5) ? .add : .subtract, rhs: b))
        }
    }
}
