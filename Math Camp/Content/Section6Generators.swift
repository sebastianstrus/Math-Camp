//
//  Section6Generators.swift
//  Math Camp
//
//  Section VI – Ranger Station (time and measures).
//

import Foundation

nonisolated enum Section6 {

    // MARK: 1. Telling Time

    static func tellingTime(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let minute: Int
        switch c.tier {
        case .easy: minute = rng.pick([0, 30])
        case .medium: minute = rng.pick([0, 15, 30, 45])
        case .hard: minute = rng.int(0...11) * 5
        }
        return .make(.clock(hour: rng.int(1...12), minute: minute))
    }

    // MARK: 2. Time Intervals

    static func timeIntervals(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let from: Int
        let length: Int
        switch c.tier {
        case .easy:
            // Whole and half hours: `2:00 → 3:30`
            from = rng.int(1...9) * 60 + rng.pick([0, 30])
            length = rng.pick([30, 60, 90, 120])
        case .medium:
            // Within about an hour, in five-minute steps.
            from = rng.int(1...10) * 60 + rng.int(0...11) * 5
            length = rng.int(1...12) * 5
        case .hard:
            // Any minute, crossing the hour: `1:50 → 3:15`
            from = rng.int(1...9) * 60 + rng.int(0...59)
            length = rng.int(40...179)
        }
        guard from + length < 12 * 60 else { return nil }
        return .make(.timeInterval(fromMinutes: from, toMinutes: from + length))
    }

    // MARK: 3. Length

    static func length(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        switch c.tier {
        case .easy:
            // `3 m = ? cm`, `5 cm = ? mm`, `2 km = ? m`
            let pair = rng.pick([(MeasureUnit.m, MeasureUnit.cm), (.cm, .mm), (.km, .m)])
            return .make(.conversion(value: rng.int(2...9), from: pair.0, to: pair.1))
        case .medium:
            if rng.chance(0.5) {
                // Backwards: `300 cm = ? m`
                let pair = rng.pick([(MeasureUnit.cm, MeasureUnit.m, 100), (.mm, .cm, 10), (.m, .km, 1_000)])
                return .make(.conversion(value: rng.int(2...9) * pair.2, from: pair.0, to: pair.1))
            }
            let pair = rng.pick([(MeasureUnit.m, MeasureUnit.cm), (.cm, .mm), (.km, .m)])
            return .make(.conversion(value: rng.int(11...30), from: pair.0, to: pair.1))
        case .hard:
            if rng.chance(0.5) {
                // `3 m ☐ 250 cm`
                let pair = rng.pick([(MeasureUnit.m, MeasureUnit.cm, 100), (.km, .m, 1_000), (.cm, .mm, 10)])
                let big = rng.int(2...9)
                let small = big * pair.2 + rng.pick([-pair.2 / 2, -pair.2 / 10, 0, pair.2 / 10, pair.2 / 2])
                return .make(.measureComparison(big, pair.0, small, pair.1))
            }
            let pair = rng.pick([(MeasureUnit.m, MeasureUnit.cm), (.m, .mm), (.km, .m)])
            return .make(.conversion(value: rng.int(11...99), from: pair.0, to: pair.1))
        }
    }

    // MARK: 4. Mass and Volume

    static func massAndVolume(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let pair = rng.chance(0.5) ? (MeasureUnit.kg, MeasureUnit.g) : (.l, .ml)
        switch c.tier {
        case .easy:
            return .make(.conversion(value: rng.int(2...9), from: pair.0, to: pair.1))
        case .medium:
            if rng.chance(0.5) {
                return .make(.conversion(value: rng.int(2...9) * 1_000, from: pair.1, to: pair.0))
            }
            return .make(.conversion(value: rng.int(11...30), from: pair.0, to: pair.1))
        case .hard:
            if rng.chance(0.5) {
                let big = rng.int(2...9)
                let small = big * 1_000 + rng.pick([-500, -100, 0, 100, 500])
                return .make(.measureComparison(big, pair.0, small, pair.1))
            }
            return .make(.conversion(value: rng.int(31...99), from: pair.0, to: pair.1))
        }
    }

    // MARK: 5. Calendar

    static func calendar(_ c: GenContext, _ rng: inout SeededRandomNumberGenerator) -> Draft? {
        let question: CalendarQuestion
        switch c.tier {
        case .easy:
            question = rng.pick([.daysInWeeks(rng.int(2...4)), .monthNumber(rng.int(1...12)), .hoursInDays(2)])
        case .medium:
            question = rng.pick([.monthsInYears(rng.int(2...5)), .hoursInDays(rng.int(2...5)),
                                 .daysInMonth(rng.int(1...12)), .daysInWeeks(rng.int(5...9))])
        case .hard:
            question = rng.pick([.minutesInHours(rng.int(2...5)), .weeksInDays(rng.int(2...10) * 7),
                                 .daysInMonth(rng.int(1...12)), .hoursInDays(rng.int(5...9)),
                                 .monthsInYears(rng.int(5...9))])
        }
        return .make(.calendar(question))
    }
}
