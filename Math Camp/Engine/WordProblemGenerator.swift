//
//  WordProblemGenerator.swift
//  Math Camp
//

import Foundation

/// What a word problem asks. The kind decides how the numbers `a`, `b`, `c` are drawn and
/// how the answer is computed, so the maths always lives in code and never in the text.
///
/// Meaning of the values per kind:
/// - `addJoin`: a start, b added → a + b
/// - `subtractAway`: a start, b removed → a − b
/// - `compare`: a (first person, larger), b (second person) → a − b
/// - `moreThan`: a (second person), first person has b more → a + b
/// - `lessThan`: a (second person), first person has b fewer → a − b
/// - `missingPart`: a needed, b already there → a − b
/// - `twoStepAddSub`: a + b − c, `twoStepSubSub`: a − b − c, `twoStepAddAdd`: a + b + c
/// - `equalGroups`: a groups of b → a × b
/// - `shareEqually`: a split into b groups → a ÷ b
/// - `divideGroups`: a split into groups of b → a ÷ b
/// - `timesMore`: a, first person has b times as many → a × b
/// - `remainder`: a in groups of b → a mod b
/// - `roundUp`: a in groups of at most b → ⌈a ÷ b⌉
/// - `mulAdd`: a groups of b, plus c → a × b + c, `mulSub`: a groups of b, minus c → a × b − c
nonisolated enum WordProblemKind: Hashable, Sendable {
    case addJoin, subtractAway, compare, moreThan, lessThan, missingPart
    case twoStepAddSub, twoStepSubSub, twoStepAddAdd
    case equalGroups, shareEqually, divideGroups, timesMore, remainder, roundUp, mulAdd, mulSub
    /// `a` split into `d` equal parts, the story asks for one part ("half of", "a quarter of").
    case shareFraction(Int)
    /// Like `shareFraction`, but the story asks for what is left after that part is taken away.
    case fractionRest(Int)
    /// `p` percent of `a`.
    case percentOf(Int)

    static let twoStep: [WordProblemKind] = [.twoStepAddSub, .twoStepSubSub, .twoStepAddAdd]

    func answer(a: Int, b: Int, c: Int) -> Int {
        switch self {
        case .addJoin, .moreThan: a + b
        case .subtractAway, .compare, .lessThan, .missingPart: a - b
        case .twoStepAddSub: a + b - c
        case .twoStepSubSub: a - b - c
        case .twoStepAddAdd: a + b + c
        case .equalGroups, .timesMore: a * b
        case .shareEqually, .divideGroups: a / b
        case .remainder: a % b
        case .roundUp: (a + b - 1) / b
        case .mulAdd: a * b + c
        case .mulSub: a * b - c
        case .shareFraction(let d): a / d
        case .fractionRest(let d): a - a / d
        case .percentOf(let p): a * p / 100
        }
    }
}

/// One story. The text lives in the String Catalog under `wp.<id>`.
///
/// `args` lists, in order, what the text uses: `p` first name, `q` second name, `a`, `b`, `c` numbers.
/// The catalog string numbers them densely (`%1$@`, `%2$lld`, …), so `"pab"` means
/// `%1$@` = first name, `%2$lld` = a, `%3$lld` = b. Translators may reorder the positions freely.
nonisolated struct WordProblemTemplate: Hashable, Sendable {
    let id: String
    let kind: WordProblemKind
    let args: String

    var catalogKey: String { "wp.\(id)" }
}

/// Number ranges of a word-problem tier.
nonisolated struct WordProblemNumbers: Sendable {
    /// Largest number in add/subtract style problems (also the largest result).
    var limit: Int = 20
    /// Smallest number shown. Keep it at 2 or more: every shown number is plural in English,
    /// so "1 pine cones" can never appear.
    var minOperand: Int = 2
    /// Allowed factors for multiplication style problems.
    var factors: [Int] = Array(2...10)
}

nonisolated struct WordProblemTierRule: Sendable {
    let numbers: WordProblemNumbers
    /// One entry per exercise: the kinds that exercise may use. The entries are shuffled,
    /// so the order of kinds differs from task to task.
    let plan: [[WordProblemKind]]
}

nonisolated struct WordProblemGenerator: ExerciseGenerator {
    static let girlNames = ["Anna", "Emma", "Mia", "Lena", "Nora", "Ella", "Eva", "Sara"]
    static let boyNames = ["Leo", "Max", "Tom", "Ben", "Adam", "Noah", "Hugo", "Felix"]

    let templates: [WordProblemTemplate]
    let easy: WordProblemTierRule
    let medium: WordProblemTierRule
    let hard: WordProblemTierRule

    func generate(tier: Tier, taskNumber: Int, count: Int,
                  using rng: inout SeededRandomNumberGenerator) -> [Exercise] {
        let rule = switch tier {
        case .easy: easy
        case .medium: medium
        case .hard: hard
        }

        var slots = rule.plan
        while slots.count < count { slots += rule.plan }
        slots = Array(rng.shuffled(slots).prefix(count))
        let allowedKinds = Set(rule.plan.flatMap { $0 })

        var usedTemplates = Set<String>()
        var usedNames = Set<String>()
        var exercises: [Exercise] = []

        for kinds in slots {
            // Never the same story twice in one task.
            var pool = templates.filter { kinds.contains($0.kind) && !usedTemplates.contains($0.id) }
            if pool.isEmpty { pool = templates.filter { allowedKinds.contains($0.kind) && !usedTemplates.contains($0.id) } }
            if pool.isEmpty { pool = templates.filter { !usedTemplates.contains($0.id) } }
            guard !pool.isEmpty else { continue }

            let template = rng.pick(pool)
            guard let (a, b, c) = Self.makeValues(kind: template.kind, numbers: rule.numbers, rng: &rng) else { continue }
            usedTemplates.insert(template.id)

            // Two different people; prefer names that did not appear earlier in this task.
            let allNames = Self.girlNames + Self.boyNames
            let fresh = allNames.filter { !usedNames.contains($0) }
            let first = rng.pick(fresh.isEmpty ? allNames : fresh)
            let second = rng.pick(allNames.filter { $0 != first })
            usedNames.insert(first)

            exercises.append(Exercise(
                id: exercises.count,
                prompt: .wordProblem(templateID: template.id,
                                     values: ["a": a, "b": b, "c": c],
                                     names: ["p": first, "q": second]),
                answer: .number(template.kind.answer(a: a, b: b, c: c))))
        }
        return exercises
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }

    /// Draws `a`, `b`, `c` so that every shown number is at least `minOperand`,
    /// the answer is at least 1 and everything stays inside the tier's range.
    static func makeValues(kind: WordProblemKind, numbers: WordProblemNumbers,
                           rng: inout SeededRandomNumberGenerator) -> (Int, Int, Int)? {
        let limit = numbers.limit
        let m = numbers.minOperand
        switch kind {
        case .addJoin, .moreThan:
            let total = rng.int(max(2 * m, 5)...limit)
            let a = rng.int(m...(total - m))
            return (a, total - a, 0)
        case .subtractAway, .compare, .lessThan, .missingPart:
            let a = rng.int((m + 2)...limit)
            return (a, rng.int(m...(a - 2)), 0)
        case .twoStepAddSub:
            let total = rng.int(max(2 * m, 6)...limit)
            let a = rng.int(m...(total - m))
            return (a, total - a, rng.int(m...(total - 2)))
        case .twoStepSubSub:
            let a = rng.int((2 * m + 2)...limit)
            let b = rng.int(m...(a - m - 2))
            return (a, b, rng.int(m...(a - b - 2)))
        case .twoStepAddAdd:
            let total = rng.int((3 * m)...limit)
            let a = rng.int(m...(total - 2 * m))
            let b = rng.int(m...(total - a - m))
            return (a, b, total - a - b)
        case .equalGroups:
            return (rng.int(2...10), rng.pick(numbers.factors), 0)
        case .shareEqually:
            let groups = rng.pick(numbers.factors)
            return (groups * rng.int(2...10), groups, 0)
        case .divideGroups:
            let each = rng.pick(numbers.factors)
            return (each * rng.int(2...10), each, 0)
        case .timesMore:
            let a = rng.int(2...10)
            let times = rng.pick(numbers.factors)
            return a * times <= 100 ? (a, times, 0) : nil
        case .remainder, .roundUp:
            let size = rng.int(3...9)
            let q = rng.int(2...((99 - (size - 1)) / size))
            return (size * q + rng.int(1...(size - 1)), size, 0)
        case .mulAdd:
            let a = rng.int(2...9)
            let b = rng.int(2...9)
            return (a, b, rng.int(2...min(19, 100 - a * b)))
        case .mulSub:
            let a = rng.int(2...9)
            let b = rng.int(2...9)
            return (a, b, rng.int(2...min(30, a * b - 2)))
        case .shareFraction(let d), .fractionRest(let d):
            return (d * rng.int(2...max(2, limit / d)), 0, 0)
        case .percentOf(let p):
            let step = 100 / gcd(p, 100)
            return (step * rng.int(2...max(2, limit / step)), 0, 0)
        }
    }
}
