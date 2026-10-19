//
//  SeededRandomNumberGenerator.swift
//  Math Camp
//

import Foundation

/// SplitMix64: tiny, fast and fully deterministic on every device and OS version.
///
/// All helpers below (`int`, `chance`, `pick`, `shuffled`) are implemented here on purpose
/// instead of relying on `Int.random(in:using:)` / `shuffled(using:)`. Their algorithms belong to
/// the standard library and could change in a future release, which would silently change
/// every generated task. Here the output depends on nothing but this file.
nonisolated struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform integer in a closed range (rejection sampling, no modulo bias).
    mutating func int(_ range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound) + 1
        let limit = UInt64.max - UInt64.max % span
        var value = next()
        while value >= limit { value = next() }
        return range.lowerBound + Int(value % span)
    }

    /// `true` with the given probability (0...1).
    mutating func chance(_ probability: Double) -> Bool {
        Double(next() >> 11) / Double(1 << 53) < probability
    }

    /// Random element. The array must not be empty.
    mutating func pick<T>(_ items: [T]) -> T {
        items[int(0...(items.count - 1))]
    }

    /// Fisher–Yates shuffle.
    mutating func shuffled<T>(_ items: [T]) -> [T] {
        var result = items
        guard result.count > 1 else { return result }
        for i in stride(from: result.count - 1, to: 0, by: -1) {
            result.swapAt(i, int(0...i))
        }
        return result
    }
}
