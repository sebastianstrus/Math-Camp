//
//  PromptTypes.swift
//  Math Camp
//
//  Value types used by the prompts of Sections IV–VII.
//

import Foundation

nonisolated struct Fraction: Hashable, Sendable {
    let numerator: Int
    let denominator: Int

    var value: Double { Double(numerator) / Double(denominator) }
}

/// A decimal number stored as an integer: `ScaledDecimal(value: 75, scale: 2)` is 0.75.
nonisolated struct ScaledDecimal: Hashable, Sendable {
    let value: Int
    let scale: Int

    var doubleValue: Double { Double(value) / pow(10, Double(scale)) }

    /// The value as an integer with `scale` decimals (`ScaledDecimal(value: 7, scale: 1)` at 2 → 70).
    func value(atScale target: Int) -> Int {
        value * Int(pow(10, Double(max(0, target - scale))))
    }
}

nonisolated enum ArithmeticOp: Hashable, Sendable {
    case add, subtract, multiply, divide

    /// `nil` for inexact division.
    func apply(_ a: Int, _ b: Int) -> Int? {
        switch self {
        case .add: a + b
        case .subtract: a - b
        case .multiply: a * b
        case .divide: (b != 0 && a % b == 0) ? a / b : nil
        }
    }

    var token: MathToken {
        switch self {
        case .add: .plus
        case .subtract: .minus
        case .multiply: .times
        case .divide: .divide
        }
    }
}

nonisolated enum FractionShape: Hashable, Sendable {
    case bar, circle, grid
}

nonisolated enum FractionPart: Hashable, Sendable {
    case numerator, denominator
}

nonisolated enum MeasureUnit: String, Hashable, Sendable {
    case mm, cm, m, km, g, kg, ml, l

    /// Size in the smallest unit of its family (mm, g, ml).
    var baseFactor: Int {
        switch self {
        case .mm, .g, .ml: 1
        case .cm: 10
        case .m, .kg, .l: 1000
        case .km: 1_000_000
        }
    }

    enum Family { case length, mass, volume }

    var family: Family {
        switch self {
        case .mm, .cm, .m, .km: .length
        case .g, .kg: .mass
        case .ml, .l: .volume
        }
    }

    var symbolKey: String { "unit.\(rawValue)" }
}

nonisolated enum CalendarQuestion: Hashable, Sendable {
    case daysInWeeks(Int)
    case weeksInDays(Int)
    case monthsInYears(Int)
    case hoursInDays(Int)
    case minutesInHours(Int)
    /// Month 1...12 in a year that is not a leap year.
    case daysInMonth(Int)
    case monthNumber(Int)

    var answer: Int {
        switch self {
        case .daysInWeeks(let n): n * 7
        case .weeksInDays(let n): n / 7
        case .monthsInYears(let n): n * 12
        case .hoursInDays(let n): n * 24
        case .minutesInHours(let n): n * 60
        case .daysInMonth(let month): [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
        case .monthNumber(let month): month
        }
    }
}

/// How a number pattern continues.
nonisolated enum PatternRule: Hashable, Sendable {
    case arithmetic(step: Int)
    /// Adds `first`, then `second`, then `first`, …
    case alternating(first: Int, second: Int)
    /// The step grows: +firstStep, +(firstStep + delta), …
    case growing(firstStep: Int, delta: Int)
    case doubling

    func terms(start: Int, length: Int) -> [Int] {
        var result = [start]
        for index in 1..<max(length, 1) {
            let previous = result[index - 1]
            switch self {
            case .arithmetic(let step): result.append(previous + step)
            case .alternating(let first, let second): result.append(previous + (index % 2 == 1 ? first : second))
            case .growing(let firstStep, let delta): result.append(previous + firstStep + delta * (index - 1))
            case .doubling: result.append(previous * 2)
            }
        }
        return result
    }
}

/// A number line with decimal positions, all values multiplied by 10^scale.
nonisolated struct DecimalLineConfig: Hashable, Sendable {
    let lower: Int
    let upper: Int
    let tickStep: Int
    let labelStep: Int
    let scale: Int
}

nonisolated enum MagicSquare {
    /// Fills the blanks of a 3×3 magic square by completing lines that have exactly one blank.
    /// Returns the complete square, or `nil` if the blanks cannot be found this way.
    static func solve(_ cells: [Int?], sum: Int) -> [Int]? {
        guard cells.count == 9 else { return nil }
        let lines = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
        var grid = cells
        var progress = true
        while progress {
            progress = false
            for line in lines {
                let blanks = line.filter { grid[$0] == nil }
                if blanks.count == 1 {
                    grid[blanks[0]] = sum - line.compactMap { grid[$0] }.reduce(0, +)
                    progress = true
                }
            }
        }
        guard grid.allSatisfy({ $0 != nil }) else { return nil }
        let full = grid.compactMap { $0 }
        return lines.allSatisfy { line in line.map { full[$0] }.reduce(0, +) == sum } ? full : nil
    }
}
