//
//  ExerciseGenerator.swift
//  Math Camp
//

import Foundation

/// Produces the exercises of one task. Implementations must be pure functions of their arguments:
/// the same tier, task number and RNG state must always give the same exercises.
nonisolated protocol ExerciseGenerator: Sendable {
    func generate(tier: Tier, taskNumber: Int, count: Int,
                  using rng: inout SeededRandomNumberGenerator) -> [Exercise]
}

/// Everything a draft maker needs to know about the exercise it is asked for.
nonisolated struct GenContext: Sendable {
    let tier: Tier
    /// 0...1 position of the task inside its tier (grows from the first to the last task of a tier).
    let difficulty: Double
    /// Zero-based position of the exercise in the task.
    let index: Int
    let count: Int
    /// The builder pre-plans which exercises must be special so that the share is exact:
    /// "=" in comparisons (about 17.5 %), "true" in true/false (50 %).
    let wantsEqual: Bool
}

/// Creates one candidate exercise, or `nil` if the random numbers did not fit the rules.
typealias DraftMaker = @Sendable (GenContext, inout SeededRandomNumberGenerator) -> Draft?

/// Generator for every category whose exercises are independent of each other.
/// It repeatedly asks `makeDraft` for candidates and enforces the quality rules:
/// - no duplicates when the pool allows it,
/// - never the same exercise twice in a row,
/// - exact share of "special" exercises (`equalFraction`).
nonisolated struct DraftGenerator: ExerciseGenerator {
    /// Share of exercises with `wantsEqual == true`.
    var equalFraction: Double = 0
    let makeDraft: DraftMaker

    private static let attemptsPerPass = 150

    func generate(tier: Tier, taskNumber: Int, count: Int,
                  using rng: inout SeededRandomNumberGenerator) -> [Exercise] {
        let difficulty = Tier.difficulty(forTask: taskNumber)

        var flags = [Bool](repeating: false, count: count)
        if equalFraction > 0 {
            let equalCount = max(1, Int((Double(count) * equalFraction).rounded()))
            for i in 0..<min(equalCount, count) { flags[i] = true }
            flags = rng.shuffled(flags)
        }

        var drafts: [Draft] = []
        var used = Set<ExercisePrompt>()

        for index in 0..<count {
            let context = GenContext(tier: tier, difficulty: difficulty, index: index,
                                     count: count, wantsEqual: flags[index])
            let previous = drafts.last?.prompt

            // Pass 1: unique and different from the previous one.
            // Pass 2 (small pools): only different from the previous one.
            // Pass 3: anything valid.
            var chosen: Draft?
            for pass in 1...3 where chosen == nil {
                for _ in 0..<Self.attemptsPerPass {
                    guard let draft = makeDraft(context, &rng) else { continue }
                    if pass <= 2, draft.prompt == previous { continue }
                    if pass == 1, used.contains(draft.prompt) { continue }
                    chosen = draft
                    break
                }
            }
            guard let draft = chosen else { continue }
            used.insert(draft.prompt)
            drafts.append(draft)
        }

        return drafts.enumerated().map { Exercise(id: $0.offset, prompt: $0.element.prompt, answer: $0.element.answer) }
    }

    /// Number of different exercises the maker can produce (estimated by sampling).
    /// Used by `ContentValidator` to decide whether duplicates are allowed.
    func estimatedPoolSize(tier: Tier, taskNumber: Int, count: Int, samples: Int = 1500) -> Int {
        var rng = SeededRandomNumberGenerator(seed: StableHash.fnv1a64("pool#\(taskNumber)"))
        let difficulty = Tier.difficulty(forTask: taskNumber)
        var seen = Set<ExercisePrompt>()
        for i in 0..<samples {
            let context = GenContext(tier: tier, difficulty: difficulty, index: i % count, count: count,
                                     wantsEqual: equalFraction > 0 && rng.chance(equalFraction))
            if let draft = makeDraft(context, &rng) { seen.insert(draft.prompt) }
        }
        return seen.count
    }
}

/// Entry point used by the UI: the exercises of task `taskNumber` in `category`.
nonisolated enum ExerciseFactory {
    static func exercises(for category: Category, taskNumber: Int) -> [Exercise] {
        guard let generator = category.generator else { return [] }
        var rng = SeededRandomNumberGenerator(seed: StableHash.seed(categoryID: category.id, taskNumber: taskNumber))
        return generator.generate(tier: Tier.tier(forTask: taskNumber), taskNumber: taskNumber,
                                  count: category.exercisesPerTask, using: &rng)
    }
}

// MARK: - Small helpers shared by the generators

nonisolated enum Gen {
    /// Randomly swaps two operands (for commutative operations).
    static func shuffledPair(_ a: Int, _ b: Int, rng: inout SeededRandomNumberGenerator) -> (Int, Int) {
        rng.chance(0.5) ? (a, b) : (b, a)
    }

    /// An expression with value `value`: mostly `a + b`, sometimes `(value + b) − b`, all numbers ≤ `limit`.
    static func expression(valued value: Int, limit: Int, rng: inout SeededRandomNumberGenerator) -> Expression? {
        let canSubtract = limit - value >= 1
        let canAdd = value >= 2
        guard canSubtract || canAdd else { return nil }
        if canSubtract && (!canAdd || rng.chance(0.35)) {
            let b = rng.int(1...min(limit - value, max(1, value + 2)))
            return .diff(value + b, b)
        }
        let a = rng.int(1...(value - 1))
        return .sum(a, value - a)
    }

    /// `40 + 9` or `50 − 1` style expression for a two-digit value.
    static func tensAndOnes(_ value: Int, rng: inout SeededRandomNumberGenerator) -> Expression? {
        let tens = value / 10 * 10
        let ones = value % 10
        guard ones > 0, tens > 0 else { return nil }
        if rng.chance(0.65) { return .sum(tens, ones) }
        guard tens + 10 <= 100 else { return .sum(tens, ones) }
        return .diff(tens + 10, 10 - ones)
    }

    /// Arithmetic sequence with one or more gaps.
    static func sequence(start: Int, step: Int, length: Int, gaps: [Int]) -> Draft? {
        let terms = (0..<length).map { start + $0 * step }
        guard terms.allSatisfy({ $0 >= 0 }), !gaps.isEmpty else { return nil }
        var shown: [Int?] = terms
        for gap in gaps { shown[gap] = nil }
        return Draft(prompt: .sequence(shown), answer: .multiple(gaps.sorted().map { terms[$0] }))
    }

    /// Valid start values so that every term of a sequence stays inside `0...limit`.
    static func startRange(step: Int, length: Int, limit: Int) -> ClosedRange<Int> {
        let span = abs(step) * (length - 1)
        return step > 0 ? 0...(limit - span) : span...limit
    }
}
