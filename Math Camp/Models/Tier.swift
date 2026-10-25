//
//  Tier.swift
//  Math Camp
//

import Foundation

/// Difficulty band inside a category: tasks 1–16, 17–32, 33–48.
nonisolated enum Tier: Int, CaseIterable, Identifiable, Hashable, Sendable {
    case easy, medium, hard

    static let tasksPerTier = 16

    var id: Int { rawValue }

    static func tier(forTask taskNumber: Int) -> Tier {
        switch taskNumber {
        case ...16: .easy
        case 17...32: .medium
        default: .hard
        }
    }

    /// 0 for the first task of a tier, 1 for the last one. Used to make difficulty creep up slowly.
    static func difficulty(forTask taskNumber: Int) -> Double {
        Double((taskNumber - 1) % tasksPerTier) / Double(tasksPerTier - 1)
    }

    var taskNumbers: ClosedRange<Int> {
        let first = rawValue * Tier.tasksPerTier + 1
        return first...(first + Tier.tasksPerTier - 1)
    }

    var titleKey: String {
        switch self {
        case .easy: "tier.easy.title"
        case .medium: "tier.medium.title"
        case .hard: "tier.hard.title"
        }
    }

    var subtitleKey: String {
        switch self {
        case .easy: "tier.easy.subtitle"
        case .medium: "tier.medium.subtitle"
        case .hard: "tier.hard.subtitle"
        }
    }

    var symbolName: String {
        switch self {
        case .easy: "sun.max.fill"
        case .medium: "figure.hiking"
        case .hard: "mountain.2.fill"
        }
    }
}
